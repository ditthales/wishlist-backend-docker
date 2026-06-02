class AuthenticationController < ApplicationController
  skip_before_action :authenticate_request, only: [:signup, :login]

  # POST /auth/signup
  def signup
    user = User.new(signup_params)

    if user.save
      token = JsonWebToken.encode(user_id: user.id, token_version: user.token_version)
      render json: {
        token: token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email
        }
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /auth/login
  def login
    user = User.find_by(email: login_params[:email])

    if user&.authenticate(login_params[:password])
      token = JsonWebToken.encode(user_id: user.id, token_version: user.token_version)
      render json: {
        token: token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email
        }
      }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  # POST /auth/logout
  def logout
    if current_user.invalidate_token!
      render json: { message: "Logged out successfully" }, status: :ok
    else
      render json: { error: "Failed to log out" }, status: :unprocessable_entity
    end
  end

  private

  def signup_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  def login_params
    params.permit(:email, :password)
  end
end
