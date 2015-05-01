class CloudfrontSigner
  class << self
    #
    # Returns a hash of cookie name / values to set.
    #
    # It expects as arguments the resource to protect and when the policy should expire
    # 
    # The policy method could be extended to support the other condtions Cloudfront supports (eg ip address)
    def cookie_data(resource, expiry)
      raw_policy = policy(resource, expiry)
      {
        'CloudFront-Policy' => safe_base64(raw_policy),
        'CloudFront-Signature' => sign(raw_policy),
        'CloudFront-Key-Pair-Id' => ENV['CLOUDFRONT_KEY_PAIR_ID']
      }
    end

    private

    def policy(url, expiry)
      {
         "Statement"=> [
            {
               "Resource" => url,
               "Condition"=>{
                  "DateLessThan" =>{"AWS:EpochTime"=> expiry.utc.to_i}
               }
            }
         ]
      }.to_json.gsub(/\s+/,'')
    end

    def safe_base64(data)
      Base64.strict_encode64(data).tr('+=/', '-_~')
    end

    def sign(data)
      digest = OpenSSL::Digest::SHA1.new
      key    = OpenSSL::PKey::RSA.new ENV['CLOUDFRONT_PRIVATE_KEY']
      result = key.sign digest, data
      safe_base64(result)
    end
  end
end