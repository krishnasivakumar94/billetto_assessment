class ApplicationController < ActionController::Base
  private

  def clerk_user_id
    token = request.authorization.to_s[/\ABearer\s+(.+)\z/i, 1] || request.cookies["__session"]
    return if token.blank?

    Clerk::SessionVerifier.new.user_id(token)
  rescue Clerk::SessionVerifier::InvalidToken
    nil
  end
end
