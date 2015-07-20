class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  # validates :profile_name, presence: true,
  #                   uniqueness: true,
  #                   length: { in: 4..15 },
  #                   format: { with: /\A[a-zA-Z]+\z/, message: "only allows letters" }

  has_one :ignindex

end
