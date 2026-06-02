class User < ApplicationRecord
	has_secure_password

	has_many :group_users
	has_many :groups, through: :group_users

	validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
	validates :name, presence: true
	validates :password, presence: true, length: { minimum: 6 }, on: :create

	# Increments token_version to invalidate all currently active JWTs for this user
	def invalidate_token!
		increment!(:token_version)
	end
end
