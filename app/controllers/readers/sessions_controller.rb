module Readers
  class SessionsController < ApplicationController
    TOKEN_TTL = 30.days

    # The dev-only OmniAuth "developer" strategy posts its form back to the
    # callback without a Rails CSRF token. Allow that in development only;
    # real providers redirect back via GET and are unaffected.
    skip_before_action :verify_authenticity_token, only: :create, raise: false if Rails.env.development?

    # OAuth provider callback (Google / Microsoft). OmniAuth has already
    # validated the response and populated request.env["omniauth.auth"].
    def create
      reader = Reader.from_omniauth(request.env["omniauth.auth"])
      sign_in(reader)
      # omniauth.origin is the page that launched the sign-in (the post the
      # reader was reading). Validated to a same-origin path below.
      redirect_to(safe_path(request.env["omniauth.origin"]) || root_path, notice: t("auth.signed_in"))
    rescue StandardError
      redirect_to root_path, alert: t("auth.sign_in_failed")
    end

    def destroy
      cookies.delete(:reader_token)
      redirect_to(safe_path(request.referer) || root_path, notice: t("auth.signed_out"))
    end

    def failure
      redirect_to root_path, alert: t("auth.sign_in_failed")
    end

    private

    def sign_in(reader)
      expires_at = TOKEN_TTL.from_now
      cookies.encrypted[:reader_token] = {
        value: JsonWebToken.encode({ sub: reader.id }, expires_at: expires_at, issuer: READER_TOKEN_ISSUER),
        expires: expires_at,
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production?
      }
    end

    # Reduce a URL/path to a safe same-origin relative path, or nil. Guards
    # against open redirects (absolute external URLs, protocol-relative "//").
    def safe_path(url)
      return if url.blank?

      uri = URI.parse(url)
      return if uri.host.present? && uri.host != request.host

      path = uri.path.presence || "/"
      return unless path.start_with?("/") && !path.start_with?("//")

      uri.query.present? ? "#{path}?#{uri.query}" : path
    rescue URI::InvalidURIError
      nil
    end
  end
end
