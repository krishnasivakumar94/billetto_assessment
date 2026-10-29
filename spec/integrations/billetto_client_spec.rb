require "rails_helper"

RSpec.describe Billetto::Client do
  Response = Struct.new(:code, :body) do
    def is_a?(type)
      type == Net::HTTPSuccess ? code.to_s.start_with?("2") : super
    end
  end
  FakeHttp = Struct.new(:response, :request_uri, :request_headers) do
    def get_response(uri, headers = {})
      self.request_uri = uri
      self.request_headers = headers
      response
    end
  end

  it "maps Billetto's public event fields and requests up to 100 results" do
    http = FakeHttp.new(Response.new("200", [{ id: "event-9", title: "Concert", startdate: "2026-11-02T18:00:00Z", image_link: "https://img.test/poster.jpg", description: "Live", url: "https://billetto.dk/e/9?utm_source=api" }].to_json))
    client = described_class.new(endpoint: "https://billetto.dk/api/v3/public/events", api_keypair: "test-keypair", http: http)

    event = client.fetch_events.first

    expect(event).to include(billetto_id: "event-9", title: "Concert", image_url: "https://img.test/poster.jpg", billetto_url: "https://billetto.dk/e/9?utm_source=api")
    expect(event.fetch(:starts_at)).to include("2026-11-02T18:00:00")
    expect(http.request_uri.query).to eq("limit=100")
    expect(http.request_headers["Api-Keypair"]).to eq("test-keypair")
  end

  it "raises a clear error for a failed response" do
    client = described_class.new(endpoint: "https://billetto.dk/api/v3/public/events", http: FakeHttp.new(Response.new("503", "unavailable")))

    expect { client.fetch_events }.to raise_error(Billetto::Client::Error, "Billetto returned HTTP 503")
  end

  it "omits canceled events and events without a start date" do
    http = FakeHttp.new(Response.new("200", [
      { id: "canceled", title: "Canceled", state: "canceled", startdate: "2026-11-02T18:00:00Z" },
      { id: "online-tbd", title: "Date to be announced", state: "published", startdate: nil }
    ].to_json))

    expect(described_class.new(endpoint: "https://billetto.dk/api/v3/public/events", http: http).fetch_events).to be_empty
  end
end
