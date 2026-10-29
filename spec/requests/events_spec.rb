require "rails_helper"
require "openssl"
require "base64"

RSpec.describe "Event voting", type: :request do
  it "shows upcoming events and their vote counts on the public page" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Test event", "Clerk sign-in required")
  end

  it "rejects voting without a signed-in Clerk user" do
    post event_vote_path(events(:one)), params: { value: 1 }, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(Vote.count).to eq(0)
  end

  it "records the vote for the verified Clerk subject" do
    key = OpenSSL::PKey::RSA.generate(2048)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("CLERK_JWT_KEY").and_return(key.public_key.to_pem)
    allow(ENV).to receive(:[]).with("CLERK_ISSUER").and_return("https://test.clerk.accounts.dev")
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("CLERK_AUTHORIZED_PARTIES", "").and_return("http://localhost:3003")
    token = jwt(key, "sub" => "clerk_user", "iss" => "https://test.clerk.accounts.dev", "azp" => "http://localhost:3003", "exp" => Time.current.to_i + 60)

    post event_vote_path(events(:one)), params: { value: 1 }, headers: { "Authorization" => "Bearer #{token}" }, as: :json

    expect(response).to have_http_status(:ok)
    expect(Vote.find_by!(event: events(:one), user_id: "clerk_user").value).to eq(1)
    expect(response.parsed_body).to include("upvotes" => 1, "downvotes" => 0)
  end

  it "rejects an invalid vote value" do
    key = OpenSSL::PKey::RSA.generate(2048)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("CLERK_JWT_KEY").and_return(key.public_key.to_pem)
    allow(ENV).to receive(:[]).with("CLERK_ISSUER").and_return("https://test.clerk.accounts.dev")
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("CLERK_AUTHORIZED_PARTIES", "").and_return("http://localhost:3003")
    token = jwt(key, "sub" => "clerk_user", "iss" => "https://test.clerk.accounts.dev", "azp" => "http://localhost:3003", "exp" => Time.current.to_i + 60)

    post event_vote_path(events(:one)), params: { value: 0 }, headers: { "Authorization" => "Bearer #{token}" }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(Vote.count).to eq(0)
  end

  def jwt(key, claims)
    header = Base64.urlsafe_encode64({ alg: "RS256" }.to_json, padding: false)
    payload = Base64.urlsafe_encode64(claims.to_json, padding: false)
    signing_input = "#{header}.#{payload}"
    signature = key.sign(OpenSSL::Digest::SHA256.new, signing_input)
    "#{signing_input}.#{Base64.urlsafe_encode64(signature, padding: false)}"
  end
end
