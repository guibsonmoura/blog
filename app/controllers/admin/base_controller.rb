module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    helper_method :current_admin

    private

    def current_admin
      @current_admin ||= begin
        payload = JsonWebToken.decode(cookies.encrypted[:admin_token])
        User.find_by(id: payload[:sub]) if payload.present?
      end
    end

    def require_admin!
      return if current_admin&.admin?

      redirect_to new_admin_session_path, alert: "Sign in to continue."
    end
  end
end
