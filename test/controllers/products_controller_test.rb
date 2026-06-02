require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @group_one = groups(:one) # created by user_one, and user_one is a member
    @group_two = groups(:two) # created by user_two, and user_two is a member

    # Make sure passwords are set up and valid for login
    @user_one.password = "secret123"
    @user_one.save!
    @user_two.password = "secret123"
    @user_two.save!

    # Create tokens and auth headers
    @token_one = JsonWebToken.encode(user_id: @user_one.id, token_version: @user_one.token_version)
    @token_two = JsonWebToken.encode(user_id: @user_two.id, token_version: @user_two.token_version)

    @headers_one = { "Authorization" => "Bearer #{@token_one}" }
    @headers_two = { "Authorization" => "Bearer #{@token_two}" }

    # Setup a product inside group_one (added by user_one)
    @product_one = products(:one)
  end

  test "should create product if current_user is a member" do
    assert_difference "Product.count", 1 do
      post group_products_url(@group_one), params: {
        name: "PlayStation 5",
        description: "Standard Edition",
        price: 499.99,
        store_link: "https://example.com/ps5",
        for_whom: "Me"
      }, headers: @headers_one
    end
    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal "PlayStation 5", json_response["name"]
    assert_equal @user_one.id, json_response["added_by_id"]
    assert_equal @group_one.id, json_response["group_id"]
  end

  test "should fail to create product if current_user is not a member" do
    assert_no_difference "Product.count" do
      post group_products_url(@group_one), params: { name: "Forbidden Item" }, headers: @headers_two
    end
    assert_response :forbidden
    assert_equal "You are not a member of this group", JSON.parse(response.body)["error"]
  end

  test "should fail to create product with invalid parameters" do
    assert_no_difference "Product.count" do
      post group_products_url(@group_one), params: { name: "", price: -10 }, headers: @headers_one
    end
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Name can't be blank"
    assert_includes json_response["errors"], "Price must be greater than or equal to 0"
  end

  test "should allow member to update product" do
    patch product_url(@product_one), params: { name: "Updated Product Name", price: 29.99 }, headers: @headers_one
    assert_response :success

    @product_one.reload
    assert_equal "Updated Product Name", @product_one.name
    assert_equal 29.99, @product_one.price.to_f
  end

  test "should forbid non-member from updating product" do
    patch product_url(@product_one), params: { name: "Illegal Hack" }, headers: @headers_two
    assert_response :forbidden
    assert_equal "You are not authorized to access this product", JSON.parse(response.body)["error"]
  end

  test "should allow member to delete product" do
    assert_difference "Product.count", -1 do
      delete product_url(@product_one), headers: @headers_one
    end
    assert_response :success
    assert_equal "Product deleted successfully", JSON.parse(response.body)["message"]
  end

  test "should forbid non-member from deleting product" do
    assert_no_difference "Product.count" do
      delete product_url(@product_one), headers: @headers_two
    end
    assert_response :forbidden
  end

  test "should list group products with pagination and filters" do
    # Add a couple of products to group_one to test pagination
    Product.create!(name: "Item A", group: @group_one, added_by: @user_one, bought: false)
    Product.create!(name: "Item B", group: @group_one, added_by: @user_one, bought: true)

    # 1. Test basic listing & pagination structure
    get group_products_url(@group_one), params: { page: 1, per_page: 2 }, headers: @headers_one
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_not_nil json_response["products"]
    assert_equal 2, json_response["products"].length
    assert_not_nil json_response["pagination"]
    assert_equal 1, json_response.dig("pagination", "current_page")
    assert_equal 2, json_response.dig("pagination", "per_page")

    # 2. Test filtering by bought
    get group_products_url(@group_one), params: { bought: "true" }, headers: @headers_one
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response["products"].length
    assert_equal true, json_response["products"].first["bought"]

    # 3. Test filtering by search query
    get group_products_url(@group_one), params: { query: "Item A" }, headers: @headers_one
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response["products"].length
    assert_equal "Item A", json_response["products"].first["name"]
  end

  test "should toggle product purchase successfully" do
    # Verify initially unbought
    assert_equal false, @product_one.bought
    assert_nil @product_one.bought_by_id

    # 1. Call buy -> should mark as bought
    post buy_product_url(@product_one), headers: @headers_one
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Product marked as bought successfully", json_response["message"]
    
    @product_one.reload
    assert_equal true, @product_one.bought
    assert_equal @user_one.id, @product_one.bought_by_id

    # 2. Call buy again -> should toggle to unbought
    post buy_product_url(@product_one), headers: @headers_one
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Product marked as unbought", json_response["message"]

    @product_one.reload
    assert_equal false, @product_one.bought
    assert_nil @product_one.bought_by_id
  end

  test "should forbid non-member from toggling product purchase" do
    post buy_product_url(@product_one), headers: @headers_two
    assert_response :forbidden
  end
end
