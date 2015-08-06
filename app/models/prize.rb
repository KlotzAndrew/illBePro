class Prize < ActiveRecord::Base

	has_many :prize_regions
	has_many :regions, through: :prize_regions
	has_one :ignindex


	def show_current_prize(ignindex)
	    prize = ignindex.prize_id
		if !prize.nil?
			return {
				description: prize.description,
				vendor: prize.vendor,
				code: prize.code,
				reward_code: prize.reward_code
			}
		end
	end

end
