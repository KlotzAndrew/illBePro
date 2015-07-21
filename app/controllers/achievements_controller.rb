class AchievementsController < ApplicationController

	def index
		@achievement = Achievement.new
		findIgnindex
	end

	def findIgnindex
	    if user_signed_in? #filter users for signed in
	      if Ignindex.find_by_user_id(current_user.id).nil?
	        redirect_to summoner_path, notice: "You need to validate your Summoner Name!"
	      else
	        active_ign_id = Ignindex.find_by_user_id(current_user.id).id
	        @ignindex = Ignindex.find_by_user_id(current_user.id)
	        findChallenges(@ignindex)

	      end
	    else #not signed-in users
	      if session[:ignindex_id].nil?
	        redirect_to summoner_path, notice: "You need to validate your Summoner Name!"
	      else
	        active_ign_id = session[:ignindex_id]
	        @ignindex = Ignindex.find(session[:ignindex_id])
	        findChallenges(@ignindex)
	      end
	    end
	end

	def findChallenges(ignindex)
	    @active = ignindex.achievements.where(id: ignindex.active_achievement)
	    @achievements = ignindex.achievements.where("result IS ?", nil).where.not(id: ignindex.active_achievement)

		active_ones = ignindex.achievements.where("result IS ?", nil).map { |x| x.challenge_id }
		Rails.logger.info "active_ones: #{active_ones}"
		@challenges_global = Challenge.where("global = ?", true).where.not(id: active_ones).map { |x| x }
		Rails.logger.info "@challenges_global: #{@challenges_global}"
		@challenges_local = Region.find(ignindex.region).challenges.where.not(id: active_ones).map { |x| x }
		Rails.logger.info "@challenges_local: #{@challenges_local}"
		@challenges_country = Challenge.where("country = ?", ignindex.region.country).where.not(id: active_ones).map { |x| x }
		
	end

	def create
		@achievement = Achievement.new

		if params["commit"] == "Select"
			findIgnindex
			canAdd(@ignindex, params["achievement"]["challenge_id"], @achievement)
		elsif params["commit"] == "Activate"
			findIgnindex
			toggleActive(@ignindex, params["achievement"]["achievement_id"])
		else
		end

	    respond_to do |format|
	      if @achievement.save
	        format.html { redirect_to root_path }
	      elsif @ignindex.save
	      	format.html { redirect_to root_path }
	      else
	        format.html { redirect_to achievements_path, alert: 'Something went wrong with your Challenge selection!' }
	      end
	    end
	end

	def toggleActive(ignindex, toggleId)
		match_toggleId = lambda {|x| if x.id == toggleId then x end }
		if ignindex.achievements.where("result IS ?", nil).select(&match_toggleId).empty?
			ignindex.update(
				:active_achievement => toggleId)
		end
	end

	def canAdd(ignindex, chalId, achievement) #checks if selected chal params can be added for summoner
		chalId = chalId.to_i
		active_ones = ignindex.achievements.map { |x| x.challenge_id }
		challenges_global = Challenge.where("global = ?", true).where.not(id: active_ones)
		challenges_local = Region.find(ignindex.region).challenges.where.not(id: active_ones)
		all_challenges = challenges_global + challenges_local
		match_chals = lambda {|x| if x.id == chalId then x end}	#just fancy :p
		@challenge = all_challenges.select(&match_chals)		
		if !@challenge.empty? 
			@challenge = @challenge.first
			achievement.update( 	#this creates a lot of duplicates in db...
				:ignindex_id => ignindex.id,
				:region_id => ignindex.region_id,
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
			ignindex.update(
				:active_achievement => achievement.id)
		end
	end

	def update
		Rails.logger.info "achievment#update triggered"	
	end
end
