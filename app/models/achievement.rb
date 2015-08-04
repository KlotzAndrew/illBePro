class Achievement < ActiveRecord::Base
	belongs_to :ignindex
	belongs_to :challenge
	has_many :statuses

	validates :challenge_id, presence: true


	def available_challenges
		active_achievment_ids = achievements.where("result IS ?", nil).map { |x| x.challenge_id }

		return {
			local: Challenge.where(global: true).where.not(id: active_achievment_ids).map { |x| x },
			country: region.challenges.where.not(id: active_achievment_ids).map { |x| x },
			global: Challenge.where("country = ?", ignindex.region.country).where.not(id: active_achievment_ids).map { |x| x }
		}
	end



end
