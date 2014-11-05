class IgnindicesController < ApplicationController
  before_action :set_ignindex, only: [:show, :edit, :update, :destroy]

  before_filter :authenticate_user!
  
  def index
    @ignindex = Ignindex.find_by_user_id(current_user.id)
  end

  def show
  end

  def new
    @ignindex = Ignindex.new
  end

  def edit

  end

  def create
    @ignindex = Ignindex.new(ignindex_params)

    respond_to do |format|
      if @ignindex.save
        format.html { redirect_to @ignindex, notice: 'ignindex was successfully created.' }
        format.json { render :show, ignindex: :created, location: @ignindex }
      else
        format.html { render :new }
        format.json { render json: @ignindex.errors, ignindex: :unprocessable_entity }
      end
    end
  end

  def update
    @ignindex.update(ignindex_params)
    if @ignindex.save
      redirect_to :action => :index
    else
    end
  end

  def destroy
    @ignindex.destroy
  end

  private
    def set_ignindex
      @ignindex = Ignindex.find(params[:id])
    end

    def ignindex_params
      params.require(:ignindex).permit(:user_id, :summoner_name, :summoner_id, :summoner_validated, :validation_string, :validation_timer)
    end
end