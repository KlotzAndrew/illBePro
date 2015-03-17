class GeodeliversController < ApplicationController

	
	def update
		@geodeliver = Geodeliver.find(params[:id])
		if params[:commit] == "Postal Code"
			@geodeliver.update(params[:geodeliver].permit(:postal_code, :country_code))
			@geodeliver.valid_location
			redirect_to :action => :index
			flash[:notice] = "Updated Your Prizing Zone!"
		end

	end

	def index
		@geodeliver = Geodeliver.find_by_user_id(current_user.id)

			@tier1_description = ""
			@tier1_vendor = ""
			
			@tier2_description = ""
			@tier2_vendor = ""
		
			@tier3_description = ""
			@tier3_vendor = ""
		
		if @geodeliver.region_id != nil
			region = Region.find(@geodeliver.region_id)
			@region_city = region.city
			@region_country = region.country
			
			if region.prize_id_tier1 == nil or region.prize_id_tier1 == "[]"
				#catch errors so json doens't derp
			else
				tier1 = Prize.find(JSON.parse(region.prize_id_tier1).first)
				@tier1_description << tier1.description
				@tier1_vendor << tier1.vendor
			end
			
			if region.prize_id_tier2 == nil or region.prize_id_tier2 == "[]"
				#catch errors so json doens't derp
			else
				tier2 = Prize.find(JSON.parse(region.prize_id_tier2).first)
				@tier2_description << tier2.description
				@tier2_vendor << tier2.vendor
			end
			
			if region.prize_id_tier3 == nil or region.prize_id_tier3 == "[]"
				#catch errors so json doens't derp
			else
				tier3 = Prize.find(JSON.parse(region.prize_id_tier3).first)
				@tier3_description << tier3.description
				@tier3_vendor << tier3.vendor
			end	
		end


	end	

  private

    def geodeliver_params
      params.require(:geodeliver).permit(:postal_code)
    end

end
