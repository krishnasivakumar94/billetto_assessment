require "base64"
require "json"
require "openssl"

module Clerk
  class SessionVerifier
    class InvalidToken < StandardError; end

    def initialize(public_key: ENV["CLERK_JWT_KEY"], issuer: ENV["CLERK_ISSUER"], authorized_parties: ENV.fetch("CLERK_AUTHORIZED_PARTIES", "").split(",").map(&:strip).reject(&:blank?), clock: -> { Time.current.to_i })
      @public_key = public_key&.gsub("\\n", "\n")
      @issuer = issuer
      @authorized_parties = authorized_parties
      @clock = clock
    end

    def user_id(token)
      raise InvalidToken, "Clerk verification is not configured" if @public_key.blank? || @issuer.blank? || @authorized_parties.empty?

      encoded_header, encoded_payload, encoded_signature = token.to_s.split(".", 3)
      raise InvalidToken, "Malformed JWT" if [encoded_header, encoded_payload, encoded_signature].any?(&:blank?)

      header = decode_json(encoded_header)
      claims = decode_json(encoded_payload)
      raise InvalidToken, "Unsupported JWT algorithm" unless header["alg"] == "RS256"

      signature = Base64.urlsafe_decode64(pad(encoded_signature))
      key = OpenSSL::PKey.read(@public_key)
      signing_input = "#{encoded_header}.#{encoded_payload}"
      raise InvalidToken, "Invalid signature" unless key.verify(OpenSSL::Digest::SHA256.new, signature, signing_input)

      validate_claims!(claims)
      claims.fetch("sub")
    rescue JSON::ParserError, ArgumentError, KeyError, OpenSSL::PKey::PKeyError, OpenSSL::OpenSSLError => error
      raise InvalidToken, "Invalid Clerk session token: #{error.message}"
    end

    private

    def validate_claims!(claims)
      raise InvalidToken, "Wrong token issuer" unless claims["iss"] == @issuer
      raise InvalidToken, "Token has expired" unless claims["exp"].to_i > @clock.call
      raise InvalidToken, "Token is not active yet" if claims["nbf"] && claims["nbf"].to_i > @clock.call
      raise InvalidToken, "Token has no user subject" if claims["sub"].blank?
      if !@authorized_parties.include?(claims["azp"])
        raise InvalidToken, "Token is from an unauthorized party"
      end
    end

    def decode_json(segment)
      parsed = JSON.parse(Base64.urlsafe_decode64(pad(segment)))
      raise InvalidToken, "Malformed JWT JSON" unless parsed.is_a?(Hash)

      parsed
    end

    def pad(segment)
      segment + ("=" * ((4 - segment.length % 4) % 4))
    end
  end
end
