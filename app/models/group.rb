class Group < ApplicationRecord
  belongs_to :created_by, class_name: 'User'

  has_many :group_users, dependent: :destroy
  has_many :users, through: :group_users

  validates :name, presence: true
end
