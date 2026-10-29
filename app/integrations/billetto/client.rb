require "net/http"

module Billetto
  class Client
    class Error < StandardError; end

    DEFAULT_ENDPOINT = "https://billetto.dk/api/v3/public/events".freeze
    MAX_RESULTS = 100

    def initialize(endpoint: ENV.fetch("BILLETTO_PUBLIC_EVENTS_URL", DEFAULT_ENDPOINT), api_keypair: ENV["BILLETTO_API_KEYPAIR"], http: Net::HTTP)
      @endpoint = endpoint
      @api_keypair = api_keypair
      @http = http
    end

    def fetch_events
      raise Error, "Set BILLETTO_PUBLIC_EVENTS_URL to the documented public event endpoint" if @endpoint.blank?

      uri = URI(@endpoint)
      uri.query = URI.encode_www_form(URI.decode_www_form(uri.query.to_s).to_h.merge("limit" => MAX_RESULTS.to_s))
      headers = {}
      headers["Api-Keypair"] = @api_keypair if @api_keypair.present?
      response = @http.get_response(uri, headers)
      if response.code == "401" || response.code == "403"
        raise Error, "Billetto rejected the request (HTTP #{response.code}). Set BILLETTO_API_KEYPAIR to a valid API keypair; Clerk keys do not work for Billetto."
      end
      raise Error, "Billetto returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      rows = if payload.is_a?(Array)
        payload
      else
        payload["events"] || payload["data"] || payload.fetch("results")
      end
      raise Error, "Billetto event response must contain an array" unless rows.is_a?(Array)

      rows.filter_map do |row|
        next if row["state"].present? && row["state"] != "published"
        next if row["startdate"].blank? && row["start_time"].blank?

        normalize(row)
      end
    rescue JSON::ParserError, KeyError, TypeError, URI::InvalidURIError, URI::InvalidComponentError, Net::OpenTimeout, Net::ReadTimeout, SocketError, OpenSSL::SSL::SSLError => error
      raise Error, "Invalid Billetto event response: #{error.message}"
    end

    private

    def normalize(row)
      {
        billetto_id: row.fetch("id").to_s,
        title: row.fetch("title"),
        starts_at: Time.zone.parse(row["startdate"] || row.fetch("start_time")).iso8601,
        image_url: row["image_link"] || row["image_url"],
        description: row["description"],
        billetto_url: row["url"]
      }
    rescue ArgumentError, TypeError => error
      raise Error, "Invalid Billetto event fields: #{error.message}"
    end
  end
end
