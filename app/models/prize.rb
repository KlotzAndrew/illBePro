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

	def self.assign_weekly_prizes(start_time)
		Achievement.all.includes(:challenge).where("created_at > ?", start_time).where(has_prizing: true).where(result: 2).each do |achievement|
			check_for_prizing(achievement)
		end
	end

	def self.check_for_prizing(achievement)
		if achievement.challenge.local_prizing == true
			prize = achievement.region.prizes.where(assignment: 0).sample(1).first
			give_user_prize(prize)
		elsif achievement.challenge.global_prizing == true
			prize = Prize.all.where(country_zone: achievement.challenge.country).where(vendor: achievement.merchant).where(assignment: 0).sample(1).first
			give_user_prize(prize)
		end
	end

	def self.give_user_prize(prize)
		if !prize.nil?
			ActiveRecord::Base.transaction do
				prize.update(
					:assignment => 1,
					:delivered_at => Time.now.to_i,
					:ignindex_id => achievement.ignindex_id)
				achievement.ignindex.update(
					:prize_id => prize_id)
			end
		end
	end
end
