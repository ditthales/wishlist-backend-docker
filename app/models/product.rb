class Product < ApplicationRecord
  belongs_to :group
  belongs_to :added_by, class_name: 'User'
  belongs_to :bought_by, class_name: 'User', optional: true
end
