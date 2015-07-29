class Achievement < ActiveRecord::Base
	belongs_to :ignindex
	belongs_to :challenge
	has_many :statuses

	validates :challenge_id, presence: true

end
