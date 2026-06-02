class ProductsController < ApplicationController
  before_action :set_group, only: [:index, :create]
  before_action :set_product, only: [:update, :destroy, :buy]

  # GET /groups/:group_id/products
  def index
    products = @group.products

    # 1. Apply Filters
    if params[:bought].present?
      bought_val = ActiveModel::Type::Boolean.new.cast(params[:bought])
      products = products.where(bought: bought_val)
    end

    if params[:added_by_id].present?
      products = products.where(added_by_id: params[:added_by_id])
    end

    if params[:bought_by_id].present?
      products = products.where(bought_by_id: params[:bought_by_id])
    end

    if params[:query].present?
      q = "%#{params[:query]}%"
      products = products.where("name ILIKE ? OR description ILIKE ? OR for_whom ILIKE ?", q, q, q)
    end

    # 2. Apply Pagination
    page = [params[:page].to_i, 1].max
    per_page = [[params[:per_page].to_i, 1].max, 100].min # max 100 per page
    per_page = 10 if params[:per_page].blank?

    total_count = products.count
    total_pages = (total_count.to_f / per_page).ceil

    paginated_products = products.order(created_at: :desc).offset((page - 1) * per_page).limit(per_page)

    render json: {
      products: paginated_products.as_json(include: [
        { added_by: { only: [:id, :name, :email] } },
        { bought_by: { only: [:id, :name, :email] } }
      ]),
      pagination: {
        current_page: page,
        per_page: per_page,
        total_pages: total_pages,
        total_count: total_count,
        next_page: page < total_pages ? page + 1 : nil,
        prev_page: page > 1 ? page - 1 : nil
      }
    }, status: :ok
  end

  # POST /groups/:group_id/products
  def create
    @product = @group.products.new(product_params)
    @product.added_by = current_user

    if @product.save
      render json: @product.as_json(include: { added_by: { only: [:id, :name, :email] } }), status: :created
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /products/:id
  def update
    if @product.update(product_params)
      render json: @product, status: :ok
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /products/:id
  def destroy
    @product.destroy
    render json: { message: "Product deleted successfully" }, status: :ok
  end

  # POST /products/:id/buy
  def buy
    if @product.bought
      # Toggle to unbought
      if @product.update(bought: false, bought_by: nil)
        render json: { message: "Product marked as unbought", product: @product.as_json(include: :bought_by) }, status: :ok
      else
        render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
      end
    else
      # Toggle to bought
      if @product.update(bought: true, bought_by: current_user)
        render json: { message: "Product marked as bought successfully", product: @product.as_json(include: :bought_by) }, status: :ok
      else
        render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
    
    # Membership validation
    unless GroupUser.exists?(group_id: @group.id, user_id: current_user.id)
      render json: { error: "You are not a member of this group" }, status: :forbidden
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Group not found" }, status: :not_found
  end

  def set_product
    @product = Product.find(params[:id])

    # Membership validation (must belong to the product's group)
    unless GroupUser.exists?(group_id: @product.group_id, user_id: current_user.id)
      render json: { error: "You are not authorized to access this product" }, status: :forbidden
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Product not found" }, status: :not_found
  end

  def product_params
    params.permit(:name, :description, :store_link, :image_link, :price, :for_whom)
  end
end
