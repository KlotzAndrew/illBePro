class GeodeliversController < ApplicationController

	
	def update
		@geodeliver = Geodeliver.find(params[:id])
		if params[:commit] == "Update Postal/Zip Code"
			@geodeliver.update(params[:geodeliver].permit(:postal_code, :country_code))
			@geodeliver.valid_location2
			redirect_to :action => :index
			flash[:notice] = "Updated Your Prizing Zone!"
		end

	end

	def index
		@geodeliver = Geodeliver.find_by_user_id(current_user.id)

		@all_prize_desc = []
		@all_prize_vendor = []

		if @geodeliver.region_id != nil
			region = Region.find(@geodeliver.region_id)
			@region_city = region.city
			@region_country = region.country
			
			#get country prizes
			prize = Prize.all.where("country_zone = ?", region.country).where("assignment = ?", 0).first
			if prize != nil
				@all_prize_desc << prize.description
				@all_prize_vendor << prize.vendor	
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
		end


	end	

  private

    def geodeliver_params
      params.require(:geodeliver).permit(:postal_code)
    end

end
