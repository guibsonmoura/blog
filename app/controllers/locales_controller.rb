class LocalesController < ApplicationController
  AVAILABLE = %w[en pt].freeze

  def update
    locale = params[:locale]
    cookies[:locale] = { value: locale, expires: 1.year.from_now } if AVAILABLE.include?(locale)
    redirect_back fallback_location: root_path
  end
end
