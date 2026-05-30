module Admin
  class SessionsController < ApplicationController
    TOKEN_TTL = 12.hours

    def new
      redirect_to admin_root_path if current_admin&.admin?
    end

    def create
      user = User.find_by(email: params[:email].to_s.strip.downcase)

      if user&.admin? && user.authenticate(params[:password])
        sign_in(user)
        redirect_to admin_root_path, notice: "Signed in."
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      cookies.delete(:admin_token)
      redirect_to new_admin_session_path, notice: "Signed out."
    end

    private

    def current_admin
      payload = JsonWebToken.decode(cookies.encrypted[:admin_token])
      User.find_by(id: payload[:sub]) if payload.present?
    end

    def sign_in(user)
      expires_at = TOKEN_TTL.from_now
      cookies.encrypted[:admin_token] = {
        value: JsonWebToken.encode({ sub: user.id }, expires_at: expires_at),
        expires: expires_at,
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production?
      }
    end
  end
end
