class IgnindicesController < ApplicationController
  before_action :set_ignindex, only: [:show, :edit, :update, :destroy]

  before_filter :authenticate_user!

  respond_to :html, :xml, :json
  
  def show
    respond_to do |format|
      format.html {render nothing: true}
      format.json {render json: Ignindex.find_by_user_id(current_user.id)}
    end
  end

  def index
    @ignindex = Ignindex.find_by_user_id(current_user.id)
  end

  def update
    @ignindexes = Ignindex.all
    if params[:commit] == "Update Summoner Name" or params[:commit] == "Add Summoner Name"
      @ignindex.update(ignindex_params)
      # flash[:notice] = "Updated summoner name!"
      @ignindex.refresh_summoner
      @ignindex.refresh_validation
    else #if params[:commit] == "New validation code"
        # if @ignindexes.where("validation_timer > ?", 0).count < 6
          # flash[:notice] = "New validation code!"
        @ignindex.refresh_validation
        # else
        #   flash[:alert] = "The validation hamster is overloaded with other validations! Try back in a few minutes, he needs a little rest"
        #   redirect_to :action => :index
        # end
    # else
    #   flash[:alert] = "Something messed up. It was probably Ashe mid. Yolo."
    end
    
    if current_user.setup_progress == 0
      redirect_to :root
    else
      redirect_to :action => :index
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