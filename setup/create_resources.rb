require 'bundler/setup'
require 'aws-sdk'
require 'optparse'
require 'erb'

app_protocol = 'match-viewer'
app_location = region = nil
bucket_name = nil
opts = OptionParser.new do |opts|
  opts.on('--region REGION') {|value| region = value}
  opts.on('--app-location APP_URL') {|value| app_location = value}
  opts.on('--app-protocol APP_PROTOCOL') {|value| app_protocol = value}
  opts.on('--bucket-name BUCKET_NAME') {|value| bucket_name = value}
end
opts.parse!
cloudfront = Aws::CloudFront::Client.new region: region


resp = cloudfront.create_cloud_front_origin_access_identity(
  cloud_front_origin_access_identity_config:{
      caller_reference: 'cloudfront-demo-origin-identity',
      comment: "For cloudfront demo"
    })

cloudfront_identity = resp.cloud_front_origin_access_identity.id


cf = Aws::CloudFormation::Client.new region: region
# create the stack

cf.create_stack(stack_name: 'cloudfront-demo-stack',
                template_body: File.read(File.join(File.dirname(__FILE__), 'template.json')),
                parameters: [
                  {
                    parameter_key: "AppLocation",
                    parameter_value: URI.parse(app_location).host,
                    use_previous_value: true
                  },
                  {
                    parameter_key: "AppProtocol",
                    parameter_value: app_protocol,
                    use_previous_value: true
                  },
                  {
                    parameter_key: "BucketName",
                    parameter_value: bucket_name,
                    use_previous_value: true
                  },
                  {
                    parameter_key: "OriginAccessIdentity",
                    parameter_value: cloudfront_identity,
                    use_previous_value: true
                  }
                ])

begin
  puts "Waiting for stack to create..."
  sleep 30
  stack = cf.describe_stacks(stack_name: 'cloudfront-demo-stack').stacks.first
end while stack.stack_status == "CREATE_IN_PROGRESS"

if stack.stack_status != "CREATE_COMPLETE"
  puts "stack failed to create"
  exit 1
end

puts "creating s3 content"
distribution_id = stack.outputs.detect { |output| output.output_key = 'Distribution'}.output_value


distribution = cloudfront.get_distribution(id: distribution_id).distribution

# upload the 403.html file

s3 = Aws::S3::Client.new region: region

cloudfront_endpoint = distribution.domain_name

s3.put_object(acl: 'public-read',
              bucket: bucket_name,
              key: 'errors/403.html',
              content_type: 'text/html',
              cache_control: 'max-age=300',
              body: ERB.new(File.read(File.join(File.dirname(__FILE__), '403.html.erb'))).result(binding))

s3.put_object(bucket: bucket_name,
              key: 'index.html',
              content_type: 'text/html',
              cache_control: 'max-age=300',
              body: File.new(File.join(File.dirname(__FILE__), 'index.html')))

puts "Setup compete: distribution url is https://#{cloudfront_endpoint}"

