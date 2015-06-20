class StaticpagesController < ApplicationController

	def homepage
	end

  def dash #this should be moved to an vendor controller
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
        @prize_remaining = 100 #all_prize - @prize_sent
        @view_count = 4085
      end
    end
  end

  def landing_page
    @ignindex = Ignindex.new
  end

  def current_achievement
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

	def teaser_summoner

    @ignindex = Ignindex.new(
      :summoner_name => nil)
	end

	def teaser_challenges
	
    @score = Score.new(
    	:challenge_points => 17)

    @geodeliver = Geodeliver.new(
    	:region_id => 3688)

        # @current_game = Status.where("win_value IS ?", nil).find_by_user_id(current_user.id)
        
        # if @current_game != nil
        #   if ((Time.now.to_i - @current_game.created_at.to_i - @current_game.value) > -120)
        #     @update_trigger = "cg-update-true"
        #   else
        #     if @current_game.trigger_timer.nil?
        #       @update_trigger = ""
        #     else
        #       if ((Time.now.to_i - @current_game.trigger_timer) < 300)
        #         @update_trigger = "cg-update-true"
        #       else
        #         @update_trigger = ""
        #       end
        #     end
        #   end
        # end

        # @ignindex = Ignindex.find_by_user_id(current_user.id)
        # @score = Score.find_by_user_id(current_user.id)
        if @score.prize_id != nil
          prize = Prize.find(@score.prize_id)
          @prize_description = prize.description
          @prize_vendor = prize.vendor
        end

        #prize region logic
        # @geodeliver = Geodeliver.find_by_user_id(current_user.id)

        @all_prize_desc = []
        @all_prize_vendor = []

        if @geodeliver.region_id != nil #skip if there is no region
          region = Region.find(@geodeliver.region_id)
          @region_city = region.city
          @region_country = region.country
          
          #get country prizes
          prize_1 = Prize.all.where("country_zone = ?", region.country).where("assignment = ? OR assignment = ?", 0,1).where("tier = ?", "1").first
          prize_2 = Prize.all.where("country_zone = ?", region.country).where("assignment = ? OR assignment = ?", 0,1).where("tier = ?", "2").first
          if prize_1 != nil
            @all_prize_desc << prize_1.description
            @all_prize_vendor << prize_1.vendor 
          end     
          if prize_2 != nil
            @all_prize_desc << prize_2.description
            @all_prize_vendor << prize_2.vendor 
          end   

          #get postal prizes
          if region.prize_id_tier1 == nil or region.prize_id_tier1 == "[]"
            #catch errors so json doens't derp
          else
            tier1 = Prize.find(JSON.parse(region.prize_id_tier1).first)
            @all_prize_desc << tier1.description
            @all_prize_vendor << tier1.vendor
          end
          
          if region.prize_id_tier2 == nil or region.prize_id_tier2 == "[]"
            #catch errors so json doens't derp
          else
            tier2 = Prize.find(JSON.parse(region.prize_id_tier2).first)
            @all_prize_desc << tier2.description
            @all_prize_vendor << tier2.vendor
          end
          
          if region.prize_id_tier3 == nil or region.prize_id_tier3 == "[]"
            #catch errors so json doens't derp
          else
            tier3 = Prize.find(JSON.parse(region.prize_id_tier3).first)
            @all_prize_desc << tier3.description
            @all_prize_vendor << tier3.vendor
          end 
        end #end prize pop logic
        #end prize region logic
   
      proc = rand(1..100)
      if proc < 17
        teaser_prize = @all_prize_desc.sample(1)[0]
        chal_kind = 6
      else 
        teaser_prize = ""
        chal_kind = 5
      end


    @current_game = Status.new(
    :created_at => Time.now,
    :value => 3900, 
    :kind => chal_kind,
    :challenge_description => teaser_prize,
    :content => @all_prize_vendor[0],
    :pause_timer => 0,
    :trigger_timer => 0,
    :proc_value => proc,
    :summoner_name => "TirelessPuppy")

	end # end challenge teaster cont

	def teaser_prize_zone
	end

end