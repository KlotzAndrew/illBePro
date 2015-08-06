class Ignindex < ActiveRecord::Base
	has_many :statuses
	belongs_to :region
	has_many :achievements
	has_many :prizes

  # validates :summoner_name, length: { minimum: 2, too_short: "the summoner name you entered is too short" }

	def refresh_summoner
		self.update(validation_string: nil)
		self.update(validation_timer: nil)
	end

	def refresh_validation
		self.update(validation_timer: "#{Time.now.to_i}")
		self.update(validation_string: "#{"pizza" + "-" + ('a'..'z').to_a.shuffle.first(4).join}")
	end

	def create_or_update_ignindex(region_id, summoner_name, summoner_name_ref, challenge_id)
		ActiveRecord::Base.transaction do
			if self.nil?
				@ignindex = Ignindex.create(
					:region_id => region_id,
					:region_id_temp => region_id,          
					:summoner_name => summoner_name,
					:summoner_name_ref => summoner_name_ref)
			else
				@ignindex.update(
					:region_id_temp => region_id)
			end

			@ignindex.add_user_achievement(challenge_id)
			@ignindex.refresh_validation
		end
	end

	def add_user_achievement(challenge_id)
	  if self.active_achievement.nil?
	    @achievement = Achievement.create(
			:ignindex_id => self.id,
			:region_id => self.region_id,
			:challenge_id => challenge.id,
			:expire => challenge.expiery,
			:name => challenge.name,
			:merchant => challenge.merchant,
			:has_prizing => challenge.local_prizing,
			:can_spell_name => challenge.can_spell_name,
			:can_spell_name_open => challenge.can_spell_name,
			:wins_required => challenge.wins_required,
			:wins_recorded => 0,
			:con_wins_recorded => 0)
		self.update(
			:active_achievement => achievement.id)
	  end
	end	

  	def assign_prize(choice)
  		prize = Prize.find(self.prize_id)
  		Rails.logger.info "self.id: #{self.id}"
  		Rails.logger.info "prize.ignindex_id: #{prize.ignindex_id}"
  		if self.id == prize.ignindex_id 
		  	if choice == "Accept"
		  		Rails.logger.info "accepted"
		  		self.accept_prize(prize)
		  	end
		end
  	end	

  	def accept_prize(prize)
		Rails.logger.info "choice is confirm accept"
		prize.update(
			:assignment => 2,
			:delivered_at => Time.now.to_i)
		Rails.logger.info "prize.assignment: #{prize.assignment}"
		self.update(
			:prize_id => nil,
			:last_prize_time => Time.now.to_i)
  	end

	def available_challenges
		active_achievment_ids = achievements.where("result IS ?", nil).map { |x| x.challenge_id }
		return {
			active: self.achievements.where(id: self.active_achievement),
			saved: self.achievements.where(result: nil).where.not(id: self.active_achievement),
			local: Challenge.where(global: true).where.not(id: active_achievment_ids).map { |x| x },
			country: region.challenges.where.not(id: active_achievment_ids).map { |x| x },
			global: Challenge.where("country = ?", self.region.country).where.not(id: active_achievment_ids).map { |x| x }
		}
	end

	def toggle_active_achievement(toggleId)
		match_toggleId = lambda {|x| if x.id == toggleId then x end }
		if self.achievements.where("result IS ?", nil).select(&match_toggleId).empty?
			self.update(
				:active_achievement => toggleId)
		end
	end

	def add_achievement(chalId, achievement)
		chalId = chalId.to_i
		active_ones = self.achievements.map { |x| x.challenge_id }
		challenges_global = Challenge.where("global = ?", true).where.not(id: active_ones)
		challenges_local = Region.find(self.region).challenges.where.not(id: active_ones)
		challenges_country = Challenge.where("country = ?", self.region.country).where.not(id: active_ones)
		all_challenges = challenges_global + challenges_local + challenges_country
		match_chals = lambda {|x| if x.id == chalId then x end}	#just fancy :p
		@challenge = all_challenges.select(&match_chals)		
		if !@challenge.empty? 
			ActiveRecord::Base.transaction do
				@challenge = @challenge.first
				achievement.update( 	#this creates a lot of duplicates in db...
					:ignindex_id => self.id,
					:region_id => self.region_id,
					:challenge_id => @challenge.id,
					:expire => @challenge.expiery,
					:name => @challenge.name,
					:merchant => @challenge.merchant,
					:has_prizing => @challenge.local_prizing,
					:can_spell_name => @challenge.can_spell_name,
					:can_spell_name_open => @challenge.can_spell_name,
					:wins_required => @challenge.wins_required,
					:wins_recorded => 0,
					:con_wins_recorded => 0)
				self.update(
					:active_achievement => achievement.id)
			end
		end
	end


end