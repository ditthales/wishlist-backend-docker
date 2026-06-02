require "test_helper"

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    # We need to set a standard password since has_secure_password uses password_digest in fixture
    @user.password = "secret123"
    @user.save!
  end

  test "should signup successfully with valid parameters" do
    assert_difference "User.count", 1 do
      post auth_signup_url, params: {
        name: "New User",
        email: "new_user@example.com",
        password: "securepassword",
        password_confirmation: "securepassword"
      }
    end
    assert_response :created

    json_response = JSON.parse(response.body)
    assert_not_nil json_response["token"]
    assert_equal "New User", json_response.dig("user", "name")
    assert_equal "new_user@example.com", json_response.dig("user", "email")
  end

  test "should fail signup with invalid parameters" do
    assert_no_difference "User.count" do
      post auth_signup_url, params: {
        name: "",
        email: "invalid-email",
        password: "short",
        password_confirmation: "different"
      }
    end
    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_not_nil json_response["errors"]
  end

  test "should login successfully with correct credentials" do
    post auth_login_url, params: {
      email: @user.email,
      password: "secret123"
    }
    assert_response :ok

    json_response = JSON.parse(response.body)
    assert_not_nil json_response["token"]
    assert_equal @user.name, json_response.dig("user", "name")
    assert_equal @user.email, json_response.dig("user", "email")
  end

  test "should fail login with incorrect password" do
    post auth_login_url, params: {
      email: @user.email,
      password: "wrongpassword"
    }
    assert_response :unauthorized

    json_response = JSON.parse(response.body)
    assert_equal "Invalid email or password", json_response["error"]
  end

  test "should fail protected action (logout) without token" do
    post auth_logout_url
    assert_response :unauthorized
    assert_equal "Missing Token", JSON.parse(response.body)["error"]
  end

  test "should fail protected action (logout) with invalid token" do
    post auth_logout_url, headers: { "Authorization" => "Bearer invalidtoken" }
    assert_response :unauthorized
    assert_equal "Invalid or Expired Token", JSON.parse(response.body)["error"]
  end

  test "should logout successfully and invalidate token" do
    # 1. Login to get a valid token
    post auth_login_url, params: {
      email: @user.email,
      password: "secret123"
    }
    assert_response :ok
    token = JSON.parse(response.body)["token"]

    # 2. Perform logout using the valid token
    post auth_logout_url, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :ok
    assert_equal "Logged out successfully", JSON.parse(response.body)["message"]

    # 3. Try to use the same token again (should fail because version was incremented)
    post auth_logout_url, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :unauthorized
    assert_equal "Token has been revoked or is invalid", JSON.parse(response.body)["error"]
  end
end
