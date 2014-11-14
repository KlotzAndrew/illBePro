class IgnindicesController < ApplicationController
  before_action :set_ignindex, only: [:show, :edit, :update, :destroy]

  before_filter :authenticate_user!
  
  def index
    @ignindex = Ignindex.find_by_user_id(current_user.id)
  end

  def update
    @ignindex.update(ignindex_params)
    if params[:commit] == "Update Summoner Name"
      redirect_to :action => :index
      @ignindex.refresh_summoner
      flash[:notice] = "Updated summoner name!"
    elsif params[:commit] == "Generate validation code"
      redirect_to :action => :index
      @ignindex.refresh_validation
      flash[:notice] = "New validation code!"
    else
      flash[:notice] = "Something messed up. It was probably Ashe mid. Yolo."
    end
  
  end

  private
    def set_ignindex
      @ignindex = Ignindex.find(params[:id])
    end

    def ignindex_params
      params.require(:ignindex).permit(:user_id, :summoner_name, :summoner_id, :summoner_validated, :validation_string, :validation_timer) if params[:ignindex]
    end
end