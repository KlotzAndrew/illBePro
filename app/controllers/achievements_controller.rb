class AchievementsController < ApplicationController
	before_action :authenticate_user!
	before_action :has_ignindex
	before_action :set_user_ignindex

	def index
		@all_challenges = @ignindex.available_challenges
	end

	def create
		if params["commit"] == "Select"
			@ignindex.add_achievement(params["achievement"]["challenge_id"], @achievement)
		elsif params["commit"] == "Activate"
			@ignindex.toggle_active_achievement(params["achievement"]["achievement_id"])
		end
		
		redirect_create_action
	end

private
	def has_ignindex
		if current_user.ignindex.nil?
			redirect_to setup_path, notice: "You need to validate your Summoner Name!"
		end
	end

	def set_user_ignindex
		@achievement = Achievement.new
		@ignindex = current_user.ignindex
	end

	def redirect_create_action
	    respond_to do |format|
	      if @ignindex.save
	        format.html { redirect_to root_path }
	      else
	        format.html { redirect_to achievements_path, alert: 'Something went wrong with your Challenge selection!' }
	      end
	    end		
	end
end
