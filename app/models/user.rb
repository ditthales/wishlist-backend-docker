class User < ApplicationRecord
	has_secure_password

	has_many :group_users
	has_many :groups, through: :group_users
end
