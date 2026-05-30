class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :set_locale
  before_action :ensure_reader_session

  private

  def set_locale
    locale = cookies[:locale].presence&.to_sym
    I18n.locale = I18n.available_locales.include?(locale) ? locale : I18n.default_locale
  end

  def ensure_reader_session
    session[:reader_id] ||= SecureRandom.uuid
  end
end
