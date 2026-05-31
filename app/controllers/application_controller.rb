class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  # Distinct issuer from the admin token ("blog-admin") so a reader token can
  # never be accepted by the admin decoder, and vice versa.
  READER_TOKEN_ISSUER = "blog-reader".freeze

  before_action :set_locale
  before_action :ensure_reader_session

  helper_method :current_reader, :reader_signed_in?, :reader_id, :reader_sign_in_buttons

  # Sign-in buttons to show, in order — only for providers actually configured
  # (computed at boot in config/initializers/omniauth.rb).
  PROVIDER_BUTTONS = {
    google_oauth2: { path: "/auth/google_oauth2", label_key: "auth.sign_in_google" },
    entra_id:      { path: "/auth/entra_id",      label_key: "auth.sign_in_microsoft" },
    facebook:      { path: "/auth/facebook",      label_key: "auth.sign_in_facebook" },
    twitter:       { path: "/auth/twitter",       label_key: "auth.sign_in_x" },
    developer:     { path: "/auth/developer",     label_key: "auth.sign_in_developer" }
  }.freeze

  private

  def reader_sign_in_buttons
    providers = Rails.application.config.x.reader_oauth_providers || []
    providers.filter_map { |key| PROVIDER_BUTTONS[key] }
  end

  def set_locale
    locale = cookies[:locale].presence&.to_sym
    I18n.locale = I18n.available_locales.include?(locale) ? locale : I18n.default_locale
  end

  # Durable anonymous identity for reactions/likes. A signed permanent cookie
  # survives browser restarts (unlike the session cookie), so a visitor's likes
  # persist and they can't trivially re-like by starting a new session.
  def ensure_reader_session
    cookies.signed.permanent[:reader_id] ||= SecureRandom.uuid
  end

  def reader_id
    cookies.signed[:reader_id]
  end

  def current_reader
    @current_reader ||= begin
      payload = JsonWebToken.decode(cookies.encrypted[:reader_token], issuer: READER_TOKEN_ISSUER)
      Reader.find_by(id: payload[:sub]) if payload.present?
    end
  end

  def reader_signed_in?
    current_reader.present?
  end

  def require_reader!
    return if reader_signed_in?

    redirect_to post_path(@post, anchor: "comment-form"), alert: t("auth.sign_in_required")
  end
end
