require 'test_helper'

class CloudfrontSignerTest < ActiveSupport::TestCase

  test 'creates a valid policy' do
    data = CloudfrontSigner.cookie_data('http://docs.example.com/*')

    travel 0 do
      policy = JSON.parse(Base64.decode64(data['CloudFront-Policy'].tr('-_~', '+=/')))
      assert_equal policy, "Statement"=> [
        {
           "Resource" => 'http://docs.example.com/*',
           "Condition"=>{
              "DateLessThan" =>{"AWS:EpochTime"=> 12.hour.from_now.utc.to_i},
           }
        }
      ]
    end
  end

  test 'sets the key pair id' do
    data = CloudfrontSigner.cookie_data('http://docs.example.com/*')
    assert_equal('AKEXAMPLE123', data['CloudFront-Key-Pair-Id'])
  end

  test 'creates a valid signature' do
    data = CloudfrontSigner.cookie_data('http://docs.example.com/*')
    to_sign = Base64.decode64(data['CloudFront-Policy'].tr('-_~', '+=/'))

    public_key = OpenSSL::PKey::RSA.new( ENV['CLOUDFRONT_PRIVATE_KEY']).public_key
    digest = OpenSSL::Digest::SHA1.new
    signature = Base64.decode64(data['CloudFront-Signature'].tr('-_~', '+=/'))
    assert public_key.verify(digest, signature,to_sign)
  end
end
