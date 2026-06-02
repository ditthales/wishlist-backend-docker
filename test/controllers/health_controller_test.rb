require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "should get health show and return success" do
    get health_check_url
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal "ONLINE", json_response["status"]
    assert_equal true, json_response.dig("database", "connected")
    assert_not_nil json_response.dig("database", "result")
    assert_equal 1, json_response.dig("database", "result", "alive").to_i
  end
end
