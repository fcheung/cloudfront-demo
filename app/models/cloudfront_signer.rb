class CloudfrontSigner
  class << self
    def cookie_data(resource, expiry)
      raw_policy = policy(resource, expiry)
      policy_data = safe_base64(raw_policy)
      signature = sign(raw_policy)
      {
        'CloudFront-Policy' => policy_data,
        'CloudFront-Signature' => signature,
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
      Base64.encode64(data).tr('+=/', '-_~').gsub(/\s+/,'')
    end

    def sign(data)
      digest = OpenSSL::Digest::SHA1.new
      key    = OpenSSL::PKey::RSA.new ENV['CLOUDFRONT_PRIVATE_KEY']
      result = key.sign digest, data
      safe_base64(result)
    end
  end
end