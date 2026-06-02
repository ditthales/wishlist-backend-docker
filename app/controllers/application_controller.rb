class ApplicationController < ActionController::Base
  before_action :authenticate_request, unless: :devise_or_public_controller?

  attr_reader :current_user

  private

  def authenticate_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header.present?

    if token.blank?
      render json: { error: "Missing Token" }, status: :unauthorized
      return
    end

    decoded = JsonWebToken.decode(token)
    if decoded.blank?
      render json: { error: "Invalid or Expired Token" }, status: :unauthorized
      return
    end

    user = User.find_by(id: decoded[:user_id])
    if user.blank? || decoded[:token_version] != user.token_version
      render json: { error: "Token has been revoked or is invalid" }, status: :unauthorized
      return
    end

    @current_user = user
  end

  def devise_or_public_controller?
    # Extend this if you want to skip authentication in specific controllers globally,
    # or handle it individually per controller using `skip_before_action :authenticate_request`.
    false
  end
end
