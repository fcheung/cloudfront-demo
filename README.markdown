# Cloudfront Demo App

This rails app illustrates the use of CloudFront signed cookies. Compared to the simplest approach of using CNAMEs and making the CloudFront distribution a subdomain of the domain hosting the rails app, this approach offers extra flexability. For more information see my [blog post](http://www.spacevatican.org/2015/5/1/using-cloudfront-signed-cookies)

## Setup

The app expects the following environment variables to be set:

- `SECRET_KEY_BASE`: random token used by rails to sign cookies
- `CLOUDFRONT_KEY_PAIR_ID`: A CloudFront keypair ID
- `CLOUDFRONT_PRIVATE_KEY`: The private key for the keypair ID.

Your CloudFront keypairs can be managed from the security credentials page of the AWS console (you need to login as the root user to have access to this).

You will need to deploy this app to a publicly accessible location (CloudFront needs to be able to make requests to it).

## AWS resources 

You can optionally use the cloudformation template to setup the required AWS resources:

- A private S3 bucket
- A CloudFront distribution configured to serve content from the S3 bucket, using your app to authenticate users

Unfortunately some of the configuration is not currently possible through CloudFront. The provided ruby script runs the cloudformation template and does a few bits of configuration not possible through CloudFormation. It takes as arguments the region, bucket name and location of the authorization app, for example

     ruby ./setup/create_resources.rb --region eu-west-1 --bucket-name 'fred-bucket-cloudfront' --app-location https://something.herokuapp.com/

This will take best part of half an hour to run - CloudFront distributions are slow to create / edit. The script also populates the S3 bucket with a sample index.html file, but you can obviously add any content you want to the bucket. If your app isn't accessible over https then you'll need to add the `--app-protocol http-only` option. It can also take a little while for the S3 bucket creation to propagate.

The script uses the aws ruby SDK so credentials can be provided either in ~/.aws/credentials file, or as environment variables (`ENV['AWS_ACCESS_KEY_ID']` and `ENV['AWS_SECRET_ACCESS_KEY']`) or from the instance metadata service (if running on an EC2 instance). The `setup/iam_policy.json` file has a sample IAM policy document with sufficient permissions to create the stack (this policy file is for reference only - it's not actually used).

The only chargeable part of this template / script is the S3 usage.

## Usage

The app is very simple. From the home page you can create an account, sign in or sign out.

Initially if you are signed out and visit any page in your CloudFront distribution you should be redirected to the signin page of the app. Upon signing in you should be redirected to the root of the CloudFront distribution. Subsequent visits to content hosted by the CloudFront distribution should not require reauthentication. Note that logout just logs you out of the rails app - it doesn't destroy the signed cookies used by CloudFront.

If you get temporary redirect errors from CloudFront, wait 10-15 minutes and try again - this only happens with a freshly created bucket.

The 403 page used to redirect people has a 5 second delay so that you can see what's happening - in the real world you'd omit the delay.