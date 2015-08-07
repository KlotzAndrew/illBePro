class Prize < ActiveRecord::Base

	has_many :prize_regions
	has_many :regions, through: :prize_regions
	has_one :ignindex


	def self.show_current_prize(ignindex)
	    prize = Prize.where(id: ignindex.prize_id).first
		if !prize.nil?
			return {
				description: prize.description,
				vendor: prize.vendor,
			}
		end
	end

end
