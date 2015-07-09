class AchievementsController < ApplicationController

	def index
	    if user_signed_in? #filter users for signed in
	      if Ignindex.find_by_user_id(current_user.id).nil?
	        redirect_to summoner_path, notice: "You need to validate your Summoner Name!"
	      else
	        active_ign_id = Ignindex.find_by_user_id(current_user.id).id
	        @ignindex = Ignindex.find_by_user_id(current_user.id)
	        @achievements = @ignindex.achievements
	      end
	    else #not signed-in users
	      if session[:ignindex_id].nil?
	        redirect_to summoner_path, notice: "You need to validate your Summoner Name!"
	      else
	        active_ign_id = session[:ignindex_id]
	        @ignindex = Ignindex.find(session[:ignindex_id])
	        @achievements = @ignindex.achievements
	      end
	    end

	end

	def create
	end

	def update
	end
end
