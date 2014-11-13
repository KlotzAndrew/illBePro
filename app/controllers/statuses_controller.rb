class StatusesController < ApplicationController
  before_action :set_status, only: [:show, :edit, :update, :destroy]

  before_filter :authenticate_user!

  # GET /statuses
  # GET /statuses.json
  def index
    @statuses = Status.all
    @ignindex = Ignindex.find_by_user_id(current_user.id)
    @score = Score.find_by_user_id(current_user.id)
  end

  # GET /statuses/1
  # GET /statuses/1.json
  def show
  end

  # GET /statuses/new
  def new
    @status = Status.new
  end

  # POST /statuses
  # POST /statuses.json
  def create
    @ignindex = Ignindex.find_by_user_id(current_user.id)
    @status = current_user.statuses.new(status_params)
    @status.summoner_id = @ignindex.summoner_id
    @status.summoner_name = @ignindex.summoner_name
    
    respond_to do |format|
      if @status.save
        format.html { redirect_to @status, notice: 'Challenge started!' }
        format.json { render :show, status: :created, location: @status }
      else
        format.html { render :new }
        format.json { render json: @status.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /statuses/1
  # PATCH/PUT /statuses/1.json
  def update
    @status = current_user.statuses.find(params[:id])
    if params[:status] && params[:status].has_key?(:user_id)
      params[:status].delete(:user_id) 
    end

    respond_to do |format|
      if @status.update(status_params)
        format.html { redirect_to @status, notice: 'Challenge was changed!' }
        format.json { render :show, status: :ok, location: @status }
      else
        format.html { render :edit }
        format.json { render json: @status.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /statuses/1
  # DELETE /statuses/1.json
  def destroy
    @status.destroy
    respond_to do |format|
      format.html { redirect_to statuses_url, notice: 'Challenge was canceled' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_status
      @status = Status.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def status_params
      params.require(:status).permit(:name, :content, :value, :user_id, :kind, :points, :api_ping, :win_value, :queue_number, :challenge_description, game_1: [:champion_id, :matchCreation, :win_loss, :matchDuration, :kills, :deaths, :assists], game_2: [:champion_id, :matchCreation, :win_loss, :matchDuration, :kills, :deaths, :assists], game_3: [:champion_id, :matchCreation, :win_loss, :matchDuration, :kills, :deaths, :assists], game_4: [:champion_id, :matchCreation, :win_loss, :matchDuration, :kills, :deaths, :assists], game_5: [:champion_id, :matchCreation, :win_loss, :matchDuration, :kills, :deaths, :assists])
    end
end

#user name input, from _form.html.erb
#<%= f.input :user_id, collection: User.all, label_method: :full_name %>