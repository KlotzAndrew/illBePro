class StatusesController < ApplicationController
  before_action :set_status, only: [:show, :edit, :update, :destroy]

  before_filter :authenticate_user!

  # GET /statuses
  # GET /statuses.json
  def index
    @champion = Champion.all
    @statuses = Status.where("user_id = ?", current_user.id).order(created_at: :desc).limit(15)
    @current_game = Status.where("win_value IS ?", nil).find_by_user_id(current_user.id)
    @ignindex = Ignindex.find_by_user_id(current_user.id)
    @score = Score.find_by_user_id(current_user.id)
    if @score.prize_id != nil
      prize = Prize.find(@score.prize_id)
      @prize_description = prize.description
      @prize_vendor = prize.vendor
    end
  end

  # GET /statuses/1
  # GET /statuses/1.json

  # GET /statuses/new
  def new
    @status = Status.new

    geo_user = Geodeliver.find_by_user_id(current_user.id)
    @prize_vendor = ""
    if !geo_user.region_id.nil?
      reg_user = Region.find(geo_user.region_id)
      if !reg_user.vendor.nil?
        @prize_vendor = reg_user.vendor
      end
    end
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
          format.html { redirect_to statuses_url, notice: 'Checking game results...' }
          format.json { head :no_content }
        end
    end
    
  end

  # DELETE /statuses/1
  # DELETE /statuses/1.json
  def destroy
    if @status.kind == 6
      @status.update(
        :value => 0,
        :win_value => 0)
      Prize.where(assignment: 1).where(user_id: current_user.id).last.update( {
        :assignment => 0,
        :user_id => 0,
        })
      score = Score.find_by_user_id(current_user.id)
      score.update(challenge_points: score.challenge_points - 1) 
      respond_to do |format|
        format.html { redirect_to statuses_url, notice: 'Prized challenge was canceled' }
        format.json { head :no_content }
      end
    elsif @status.kind == 5
      @status.update(value: 0)
      @status.update(win_value: 3)
      score = Score.find_by_user_id(current_user.id)
      score.update(challenge_points: score.challenge_points - 1) 
      respond_to do |format|
        format.html { redirect_to statuses_url, notice: 'Non-Prized challenge was canceled' }
        format.json { head :no_content }
      end
    else
      @status.update(value: 0)
      @status.update(win_value: 3)      
      respond_to do |format|
        format.html { redirect_to statuses_url, notice: 'Something went wrong with your challenge kind' }
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
      params.require(:status).permit(:kind)
    end
end

#user name input, from _form.html.erb
#<%= f.input :user_id, collection: User.all, label_method: :full_name %>