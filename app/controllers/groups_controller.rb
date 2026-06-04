class GroupsController < ApplicationController
  before_action :set_group, only: [:update, :destroy, :add_user]

  # GET /groups
  def index
    @groups = current_user.groups
    render json: @groups.as_json(include: { created_by: { only: [:id, :name, :email] } }), status: :ok
  end

  # POST /groups
  def create
    ActiveRecord::Base.transaction do
      @group = Group.new(group_params)
      @group.created_by = current_user

      if @group.save
        # Automatically add the creator as a member in the join table
        @group.users << current_user
        render json: @group.as_json(include: :users), status: :created
      else
        render json: { errors: @group.errors.full_messages }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  # PUT/PATCH /groups/:id
  def update
    if @group.created_by_id != current_user.id
      render json: { error: "Only the group creator can edit it" }, status: :forbidden
      return
    end

    if @group.update(group_params)
      render json: @group, status: :ok
    else
      render json: { errors: @group.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /groups/:id
  def destroy
    if @group.created_by_id != current_user.id
      render json: { error: "Only the group creator can delete it" }, status: :forbidden
      return
    end

    @group.destroy
    render json: { message: "Group deleted successfully" }, status: :ok
  end

  # POST /groups/:id/add_user
  def add_user
    # Authorization check: only current members of the group can add new members
    unless GroupUser.exists?(group_id: @group.id, user_id: current_user.id)
      render json: { error: "You must be a member of this group to add other users" }, status: :forbidden
      return
    end

    user_to_add = if params[:email].present?
                    User.find_by(email: params[:email])
                  elsif params[:user_id].present?
                    User.find_by(id: params[:user_id])
                  end

    if user_to_add.blank?
      render json: { error: "User not found" }, status: :not_found
      return
    end

    # Check if already a member
    if GroupUser.exists?(group_id: @group.id, user_id: user_to_add.id)
      render json: { error: "User is already a member of this group" }, status: :unprocessable_entity
      return
    end

    # Add to group
    @group.users << user_to_add
    render json: {
      message: "User added successfully",
      user: { id: user_to_add.id, name: user_to_add.name, email: user_to_add.email }
    }, status: :ok
  end

  private

  def set_group
    @group = Group.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Group not found" }, status: :not_found
  end

  def group_params
    params.permit(:name, :emoji)
  end
end
