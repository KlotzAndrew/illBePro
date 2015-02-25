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
		@prize = Prize.where("geo == ?", @geodeliver.postal_code)
	end	

  private

    def geodeliver_params
      params.require(:geodeliver).permit(:postal_code)
    end

end
