class IgnindicesController < ApplicationController
  before_action :set_ignindex, only: [:show, :edit, :update, :destroy]

  before_filter :authenticate_user!
  
  def index
    @ignindex = Ignindex.find_by_user_id(current_user.id)
  end

  def update
    @ignindexes = Ignindex.all
    @ignindex.update(ignindex_params)
    if params[:commit] == "Update Summoner Name"
      flash[:notice] = "Updated summoner name!"
      redirect_to :action => :index
      @ignindex.refresh_summoner
    elsif params[:commit] == "Generate validation code"
        if @ignindexes.where("validation_string > ?", 0).count < 6
          flash[:notice] = "New validation code!"
          redirect_to :action => :index
          @ignindex.refresh_validation
        else
          redirect_to :action => :index
          flash[:alert] = "The validation hampster is overloaded with other validations! Try back in a few minutes, he needs a little rest"
        end
    else
      redirect_to :action => :index
      flash[:alert] = "Something messed up. It was probably Ashe mid. Yolo."
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