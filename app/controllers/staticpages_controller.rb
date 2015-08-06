class StaticpagesController < ApplicationController

	def homepage
	end

  def dash #this should be moved to an vendor dashboard controller
    @display = 0
    if user_signed_in?
      if current_user.email == "andrew.klotz@hotmail.com" or current_user.email == "changtoy@yahoo.ca"
        @display = 1
        campaign_start_cora = 1433781134 #monday, june 8th 12:30pm
        @user_count = Ignindex.all.where("updated_at > ?", Time.at(campaign_start_cora)).where.not("summoner_name IS ?", nil).count
        @status_count = Status.all.where("updated_at > ?", Time.at(campaign_start_cora)).count
        all_prize = Prize.all.where("vendor = ?", "Cora Pizza").count
        assign_1 = Prize.all.where("vendor = ?", "Cora Pizza").where("assignment = ?", 1).count
        assign_2 = Prize.all.where("vendor = ?", "Cora Pizza").where("assignment = ?", 2).count
        @prize_sent = assign_1 + assign_2
        @prize_remaining = 100 - @prize_sent
        @view_count = 8323
      end
    end
  end

  def current_achievement
  end

  def papa_johns
  end

  def about
  end

  def contact
  end

  def faq
  end

  def privacy
  end

  def terms_of_service
  end

end