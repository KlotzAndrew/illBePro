class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  validates :first_name, presence: true
  validates :last_name, presence: true

  after_create :index_me

  def index_me
    @ignindex = Ignindex.create!(:user_id => self.id)
    @ignindex.save
    @score = Score.create!(:user_id => self.id)
    @score.save
  end

  def full_name
  	first_name + " " + last_name
  end

  has_many :statuses

end
