class Product < ApplicationRecord
  belongs_to :group
  belongs_to :added_by, class_name: 'User'
  belongs_to :bought_by, class_name: 'User', optional: true

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
