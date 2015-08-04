class Ignindex < ActiveRecord::Base

	# belongs_to :user // ignindex now floats for 'temporary' users w/o user_id
	has_many :statuses
	belongs_to :region
	has_many :achievements
	has_many :prizes


	def refresh_summoner
		# self.update(summoner_validated: false)
		# self.update(summoner_id: nil)
		self.update(validation_string: nil)
		self.update(validation_timer: nil)
	end

	def refresh_validation
		self.update(validation_timer: "#{Time.now.to_i}")
		self.update(validation_string: "#{"pizza" + "-" + ('a'..'z').to_a.shuffle.first(4).join}")
	end

	#flagged for removal
	# def self.prize_objects(ignindex_id)
	# 	prize_2 = Ignindex.find(ignindex_id).summoner_name		
	# end

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


	def clear_duplcates #unresolved bug fixer (manually run)
		Rails.logger.info "DUPLICATE SUMMONER ISSUE"
		Ignindex.find(dont_run) #dont run
		#finds duplicate summoner names (idk where bug is being created)
		dup1 = []
		Ignindex.all.each do |x|
		dup1 << x.summoner_id
		end; nil
		dup2 = dup1.select{|item| dup1.count(item) > 1}.uniq

		#resets all duplicate values (user should re-validate w/o issue)
		dup2.each do |x|
		  Ignindex.where("summoner_id = ?", x).each do |y|
		    y.update(
		      :summoner_id => nil,
		      :summoner_name_ref => nil,
		      :summoner_validated => nil)
		  end
		end; nil
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