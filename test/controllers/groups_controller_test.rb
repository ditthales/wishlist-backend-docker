require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @group_one = groups(:one) # created by user_one, and user_one is a member
    @group_two = groups(:two) # created by user_two, and user_two is a member

    # Generate JWT tokens for test headers
    @token_one = JsonWebToken.encode(user_id: @user_one.id, token_version: @user_one.token_version)
    @token_two = JsonWebToken.encode(user_id: @user_two.id, token_version: @user_two.token_version)

    @headers_one = { "Authorization" => "Bearer #{@token_one}" }
    @headers_two = { "Authorization" => "Bearer #{@token_two}" }
  end

  test "should list groups the user belongs to" do
    get groups_url, headers: @headers_one
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response.length
    assert_equal @group_one.name, json_response.first["name"]
  end

  test "should create group and add creator as member" do
    assert_difference -> { Group.count } => 1, -> { GroupUser.count } => 1 do
      post groups_url, params: { name: "Family Wishlist", emoji: "🎄" }, headers: @headers_one
    end
    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal "Family Wishlist", json_response["name"]
    assert_equal "🎄", json_response["emoji"]
    assert_equal @user_one.id, json_response["created_by_id"]

    # Verify membership
    members = json_response["users"]
    assert_includes members.map { |m| m["id"] }, @user_one.id
  end

  test "should fail to create group with empty name" do
    assert_no_difference "Group.count" do
      post groups_url, params: { name: "" }, headers: @headers_one
    end
    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"], "Name can't be blank"
  end

  test "should allow creator to update group" do
    patch group_url(@group_one), params: { name: "Updated Group Name", emoji: "🎁" }, headers: @headers_one
    assert_response :success

    @group_one.reload
    assert_equal "Updated Group Name", @group_one.name
    assert_equal "🎁", @group_one.emoji
  end

  test "should forbid non-creator from updating group" do
    # Add user_two to group_one so they are a member but not the creator
    @group_one.users << @user_two

    patch group_url(@group_one), params: { name: "Intruder Name" }, headers: @headers_two
    assert_response :forbidden
    assert_equal "Only the group creator can edit it", JSON.parse(response.body)["error"]
  end

  test "should allow creator to delete group" do
    assert_difference "Group.count", -1 do
      delete group_url(@group_one), headers: @headers_one
    end
    assert_response :success
    assert_equal "Group deleted successfully", JSON.parse(response.body)["message"]
  end

  test "should forbid non-creator from deleting group" do
    # Add user_two to group_one so they are a member but not the creator
    @group_one.users << @user_two

    assert_no_difference "Group.count" do
      delete group_url(@group_one), headers: @headers_two
    end
    assert_response :forbidden
    assert_equal "Only the group creator can delete it", JSON.parse(response.body)["error"]
  end

  test "should allow member to add other user by email" do
    post add_user_group_url(@group_one), params: { email: @user_two.email }, headers: @headers_one
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal "User added successfully", json_response["message"]
    assert_equal @user_two.id, json_response.dig("user", "id")
    assert_includes @group_one.reload.users, @user_two
  end

  test "should allow member to add other user by id" do
    post add_user_group_url(@group_one), params: { user_id: @user_two.id }, headers: @headers_one
    assert_response :success
    assert_includes @group_one.reload.users, @user_two
  end

  test "should fail to add user if current_user is not a member" do
    post add_user_group_url(@group_one), params: { email: @user_two.email }, headers: @headers_two
    assert_response :forbidden
    assert_equal "You must be a member of this group to add other users", JSON.parse(response.body)["error"]
  end

  test "should fail to add user if already a member" do
    # Make user_two a member first
    @group_one.users << @user_two

    post add_user_group_url(@group_one), params: { email: @user_two.email }, headers: @headers_one
    assert_response :unprocessable_entity
    assert_equal "User is already a member of this group", JSON.parse(response.body)["error"]
  end

  test "should return 404 if user to add does not exist" do
    post add_user_group_url(@group_one), params: { email: "non_existent@example.com" }, headers: @headers_one
    assert_response :not_found
    assert_equal "User not found", JSON.parse(response.body)["error"]
  end
end
