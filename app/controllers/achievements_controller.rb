class AchievementsController < ApplicationController
	before_action :authenticate_user!

	def index
		if current_user.ignindex.nil?
			redirect_to setup_path, notice: "You need to validate your Summoner Name!"
		else
			@achievement = Achievement.new
			@ignindex = current_user.ignindex
			@all_challenges = @ignindex.available_challenges
		end
	end

	def create
		@achievement = Achievement.new
		@ignindex = current_user.ignindex

		if params["commit"] == "Select"
			@ignindex.add_achievement(params["achievement"]["challenge_id"], @achievement)
		elsif params["commit"] == "Activate"
			@ignindex.toggle_active_achievement(params["achievement"]["achievement_id"])
		end

	    respond_to do |format|
	      if @ignindex.save
	        format.html { redirect_to root_path }
	      else
	        format.html { redirect_to achievements_path, alert: 'Something went wrong with your Challenge selection!' }
	      end
	    end
	end

	def update
	end
end
