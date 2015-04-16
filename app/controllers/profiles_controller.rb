class ProfilesController < ApplicationController
  
  before_filter :authenticate_user!

def index
	@setup_progress = current_user.setup_progress
	
	# if current_user.setup_progress == 0
		@geodeliver = Geodeliver.find_by_user_id(current_user.id)

		@all_prize_desc = []
		@all_prize_vendor = []

		if @geodeliver.region_id != nil #skip if there is no region
			region = Region.find(@geodeliver.region_id)
			@region_city = region.city
			@region_country = region.country
			@region_postal = region.postal_code
			
			#get country prizes
			prize_1 = Prize.all.where("country_zone = ?", region.country).where("assignment = ?", 0).where("tier = ?", "1").first
			prize_2 = Prize.all.where("country_zone = ?", region.country).where("assignment = ?", 0).where("tier = ?", "2").first
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
	# elsif current_user.setup_progress == 1
		@ignindex = Ignindex.find_by_user_id(current_user.id)
	# elsif current_user.setup_progress == 2
		@status = Status.new
      # @champion = Champion.all
      # @statuses = Status.where("user_id = ?", current_user.id).order(created_at: :desc).limit(15)
      @current_game = Status.where("win_value IS ?", nil).find_by_user_id(current_user.id)


      if @current_game != nil
        if ((Time.now.to_i - @current_game.created_at.to_i - @current_game.value) > -120)
          @update_trigger = "cg-update-true"
        else
          if @current_game.trigger_timer.nil?
            @update_trigger = ""
          else
            if ((Time.now.to_i - @current_game.trigger_timer) < 300)
              @update_trigger = "cg-update-true"
            else
              @update_trigger = ""
            end
          end
        end
      end
            
      @ignindex = Ignindex.find_by_user_id(current_user.id)
      @score = Score.find_by_user_id(current_user.id)
      if @score.prize_id != nil
        prize = Prize.find(@score.prize_id)
        @prize_description = prize.description
        @prize_vendor = prize.vendor
      end

      #prize region logic
      @geodeliver = Geodeliver.find_by_user_id(current_user.id)

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
	# end
	
end

end
