class User < ApplicationRecord
  devise :database_authenticatable, :trackable, :validatable, :token_authenticatable

  has_many :authentication_tokens, dependent: :destroy
end
