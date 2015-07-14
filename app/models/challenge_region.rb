class ChallengeRegion < ActiveRecord::Base
	belongs_to :region 
	belongs_to :challenge 
end
