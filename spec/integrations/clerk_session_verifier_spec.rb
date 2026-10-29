require "rails_helper"
require "openssl"
require "base64"

RSpec.describe Clerk::SessionVerifier do
  it "accepts a valid session token and returns its Clerk subject" do
    key = OpenSSL::PKey::RSA.generate(2048)
    verifier = described_class.new(public_key: key.public_key.to_pem, issuer: "https://test.clerk.accounts.dev", authorized_parties: ["http://localhost:3003"], clock: -> { 1_800_000_000 })
    token = jwt(key, "sub" => "user_test", "iss" => "https://test.clerk.accounts.dev", "azp" => "http://localhost:3003", "exp" => 1_800_000_060)

    expect(verifier.user_id(token)).to eq("user_test")
  end

  it "rejects an expired token and a token signed by another key" do
    key = OpenSSL::PKey::RSA.generate(2048)
    other_key = OpenSSL::PKey::RSA.generate(2048)
    verifier = described_class.new(public_key: key.public_key.to_pem, issuer: "https://test.clerk.accounts.dev", authorized_parties: ["http://localhost:3003"], clock: -> { 1_800_000_000 })
    expired = jwt(key, "sub" => "user_test", "iss" => "https://test.clerk.accounts.dev", "azp" => "http://localhost:3003", "exp" => 1_799_999_999)
    invalid_signature = jwt(other_key, "sub" => "user_test", "iss" => "https://test.clerk.accounts.dev", "azp" => "http://localhost:3003", "exp" => 1_800_000_060)

    expect { verifier.user_id(expired) }.to raise_error(Clerk::SessionVerifier::InvalidToken)
    expect { verifier.user_id(invalid_signature) }.to raise_error(Clerk::SessionVerifier::InvalidToken)
  end

  def jwt(key, claims)
    header = Base64.urlsafe_encode64({ alg: "RS256" }.to_json, padding: false)
    payload = Base64.urlsafe_encode64(claims.to_json, padding: false)
    signing_input = "#{header}.#{payload}"
    signature = key.sign(OpenSSL::Digest::SHA256.new, signing_input)
    "#{signing_input}.#{Base64.urlsafe_encode64(signature, padding: false)}"
  end
end
