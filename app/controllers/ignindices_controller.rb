class IgnindicesController < ApplicationController
  before_action :set_ignindex, only: [:show, :edit, :update, :destroy]

  before_filter :authenticate_user!
  
  def index
    @ignindex = Ignindex.find_by_user_id(current_user.id)
  end

  def update
    @ignindex = Ignindex.find_by_user_id(current_user.id)

    respond_to do |format|
      if @ignindex.update(ignindex_params)
        format.html { redirect_to update_url, notice: 'Summoner name was changed!' }
        format.json { render :show, status: :ok, location: @status }
      else
        format.html { redirect_to statuses_url }
        format.json { render json: @status.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_ignindex
      @ignindex = Ignindex.find(params[:id])
    end

    def ignindex_params
      params.require(:ignindex).permit(:user_id, :summoner_name, :summoner_id, :summoner_validated, :validation_string, :validation_timer)
    end
end