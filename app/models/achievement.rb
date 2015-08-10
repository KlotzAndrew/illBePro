class Achievement < ActiveRecord::Base
	belongs_to :ignindex
	belongs_to :challenge
	belongs_to :region
	has_many :statuses

	validates :challenge_id, presence: true

end
