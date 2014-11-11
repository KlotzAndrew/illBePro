class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  validates :profile_name, presence: true,
                    uniqueness: true,
                    length: { in: 4..14 },
                    format: { with: /\A[a-zA-Z]+\z/, message: "only allows letters" }

  after_create :index_me

  def index_me
    @ignindex = Ignindex.create!(:user_id => self.id)
    @ignindex.save
    @score = Score.create!(:user_id => self.id, :week_1 => 0)
    @score.save
  end

  def full_name
  	first_name + " " + last_name
  end

  has_many :statuses

end
