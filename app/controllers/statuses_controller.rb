class StatusesController < ApplicationController
  before_action :set_status, only: [:show, :edit, :update, :destroy]

  before_filter :authenticate_user!

  # GET /statuses
  # GET /statuses.json
  def index
    @champion = Champion.all
    @statuses = Status.all
    @ignindex = Ignindex.find_by_user_id(current_user.id)
    @score = Score.find_by_user_id(current_user.id)
  end

  # GET /statuses/1
  # GET /statuses/1.json

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
        format.html { redirect_to statuses_url, notice: 'Challenge started!' }
        format.json { head :no_content }
      else
        format.html { render :new }
        format.json { render json: @status.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /statuses/1
  # PATCH/PUT /statuses/1.json
  def update
    if (Time.now.to_i - @status.created_at.to_i) < 1200
      if @status.pause_timer == 0
        @status.update(pause_timer: Time.now.to_i)
        respond_to do |format|
          format.html { redirect_to statuses_url, notice: 'Challenge Paused' }
          format.json { head :no_content }
        end
      else 
        @status.update(value: (@status.value + Time.now.to_i - @status.pause_timer))
        @status.update(pause_timer: 0)
        respond_to do |format|
          format.html { redirect_to statuses_url, notice: 'Challenge Unpaused' }
          format.json { head :no_content }
        end
      end
    else
      @status.update(trigger_timer: Time.now.to_i)
        respond_to do |format|
          format.html { redirect_to statuses_url, notice: 'Updating your game results...' }
          format.json { head :no_content }
        end
    end
  end

  # DELETE /statuses/1
  # DELETE /statuses/1.json
  def destroy
    if (Time.now.to_i - @status.created_at.to_i) < 1200 && @status.kind == 4
      @status.update(value: 0)
      @status.update(win_value: 3)
      Score.find_by_user_id(@status.user_id).update(week_5: Score.find_by_user_id(@status.user_id).week_5 - 1)
      Score.find_by_summoner_id(@status.summoner_id).update(week_5: Score.find_by_summoner_id(@status.summoner_id).week_5 - 1)
      respond_to do |format|
        format.html { redirect_to statuses_url, notice: 'Challenge was surrendered, 1 point lost' }
        format.json { head :no_content }
      end
    else 
      @status.update(value: 0)
      @status.update(win_value: 3)
      respond_to do |format|
        format.html { redirect_to statuses_url, notice: 'Challenge was canceled' }
        format.json { head :no_content }
      end
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