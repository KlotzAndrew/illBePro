class Achievement < ActiveRecord::Base
	belongs_to :ignindex
	belongs_to :challenge
	has_many :statuses

	validates :challenge_id, presence: true

	#achievement.kind 1 == "Cora Pizza"
	# cora_postals = ["M6G", "M6J", "M5R", "M5S", "M5T", "M5G"]
	# cora_regions = [43871, 43873, 43859, 43860, 43861, 43851]

	# cora_regions.each do |x|
	# Region.find(x).update(
	# :prize_id_tier1 => "[1]")
	# end

end
