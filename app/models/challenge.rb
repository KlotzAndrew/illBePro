class Challenge < ActiveRecord::Base
	has_many :achievements
	has_many :challenge_regions
	has_many :regions, :through => :challenge_regions
end