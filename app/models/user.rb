class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  validates :profile_name, presence: true,
                    uniqueness: true,
                    length: { in: 4..15 },
                    format: { with: /\A[a-zA-Z]+\z/, message: "only allows letters" }

  after_create :index_me

  def index_me
    Ignindex.create!(:user_id => self.id) 
    Score.create!(:user_id => self.id, :week_1 => 0, :week_2 => 0, :week_3 => 0, :week_4 => 0, :week_5 => 0, :week_6 => 0,:week_7 => 0,:week_8 => 0,:week_9 => 0,:week_10 => 0,:week_11 => 0)
  end

  def full_name
  	first_name + " " + last_name
  end

  has_many :statuses

end
