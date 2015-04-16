class StatusesController < ApplicationController
  before_action :set_status, only: [:show, :edit, :update, :destroy]

  before_filter :authenticate_user!

  respond_to :html, :xml, :json

  # GET /statuses
  # GET /statuses.json
  def index
    if current_user.setup_progress < 3
      redirect_to profiles_url
    else
      @status = Status.new
      # @champion = Champion.all
      # @statuses = Status.where("user_id = ?", current_user.id).order(created_at: :desc).limit(15)
      @current_game = Status.where("win_value IS ?", nil).find_by_user_id(current_user.id)
      
      if @current_game != nil
        if ((Time.now.to_i - @current_game.created_at.to_i - @current_game.value) > -120)
          @update_trigger = "cg-update-true"
        else
          if @current_game.trigger_timer.nil?
            @update_trigger = ""
          else
            if ((Time.now.to_i - @current_game.trigger_timer) < 300)
              @update_trigger = "cg-update-true"
            else
              @update_trigger = ""
            end
          end
        end
      end

      @ignindex = Ignindex.find_by_user_id(current_user.id)
      @score = Score.find_by_user_id(current_user.id)
      if @score.prize_id != nil
        prize = Prize.find(@score.prize_id)
        @prize_description = prize.description
        @prize_vendor = prize.vendor
      end

      #prize region logic
      @geodeliver = Geodeliver.find_by_user_id(current_user.id)

      @all_prize_desc = []
      @all_prize_vendor = []

      if @geodeliver.region_id != nil #skip if there is no region
        region = Region.find(@geodeliver.region_id)
        @region_city = region.city
        @region_country = region.country
        
        #get country prizes
        prize_1 = Prize.all.where("country_zone = ?", region.country).where("assignment = ? OR assignment = ?", 0,1).where("tier = ?", "1").first
        prize_2 = Prize.all.where("country_zone = ?", region.country).where("assignment = ? OR assignment = ?", 0,1).where("tier = ?", "2").first
        if prize_1 != nil
          @all_prize_desc << prize_1.description
          @all_prize_vendor << prize_1.vendor 
        end     
        if prize_2 != nil
          @all_prize_desc << prize_2.description
          @all_prize_vendor << prize_2.vendor 
        end   

        #get postal prizes
        if region.prize_id_tier1 == nil or region.prize_id_tier1 == "[]"
          #catch errors so json doens't derp
        else
          tier1 = Prize.find(JSON.parse(region.prize_id_tier1).first)
          @all_prize_desc << tier1.description
          @all_prize_vendor << tier1.vendor
        end
        
        if region.prize_id_tier2 == nil or region.prize_id_tier2 == "[]"
          #catch errors so json doens't derp
        else
          tier2 = Prize.find(JSON.parse(region.prize_id_tier2).first)
          @all_prize_desc << tier2.description
          @all_prize_vendor << tier2.vendor
        end
        
        if region.prize_id_tier3 == nil or region.prize_id_tier3 == "[]"
          #catch errors so json doens't derp
        else
          tier3 = Prize.find(JSON.parse(region.prize_id_tier3).first)
          @all_prize_desc << tier3.description
          @all_prize_vendor << tier3.vendor
        end 
      end #end prize pop logic
      #end prize region logic
    end
  end

  # GET /statuses/1
  # GET /statuses/1.json

  # GET /statuses/new

  def show
    respond_to do |format|
      format.html { render nothing: true}
      format.json { render json: Status.where("user_id = ?", current_user.id).last }
    end    
  end

  def new
    @status = Status.new

    geo_user = Geodeliver.find_by_user_id(current_user.id)
    @prize_vendor = ""
    if !geo_user.region_id.nil?
      reg_user = Region.find(geo_user.region_id)
      @prize_vendor = Prize.last.vendor
      if !reg_user.vendor.nil?
        #@prize_vendor = reg_user.vendor
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
        format.html { redirect_to challenges_url }
        format.json { head :no_content }
        format.js { redirect_to challenges_url}
      else
        format.html { redirect_to challenges_url, alert: 'illBePro engine is temporarily offline!' }
        format.json { render json: @status.errors, status: :unprocessable_entity }
        format.js { redirect_to challenges_url, alert: 'illBePro engine is temporarily offline!' }
      end
    end
  end

  # PATCH/PUT /statuses/1
  # PATCH/PUT /statuses/1.json
  def update
    
    Rails.logger.info "This is test log for proc #{@status.proc_value}"
    Rails.logger.info "This is test log for rolll #{@status.roll_status}"
    Rails.logger.info "This is test log for id #{@status.id}"
    if @status.roll_status == 1 # this is broken right now
      @status.update(roll_status: 1)
         respond_to do |format|
            format.html { redirect_to challenges_url, notice: 'Challenge getting started' }
            format.json { head :no_content }
            format.js { render :nothing => true}
          end      
    else

      if (Time.now.to_i - @status.created_at.to_i) < 1200
        if @status.pause_timer == 0
          @status.update(pause_timer: Time.now.to_i)
          respond_to do |format|
            format.html { redirect_to challenges_url, notice: 'Challenge Paused' }
            format.json { head :no_content }
            format.js { render :nothing => true}
          end
        else 
          @status.update(value: (@status.value + Time.now.to_i - @status.pause_timer))
          @status.update(pause_timer: 0)
          respond_to do |format|
            format.html { redirect_to challenges_url, notice: 'Challenge Unpaused' }
            format.json { head :no_content }
            format.js { render :nothing => true } 
          end
        end
      else
        @status.update(trigger_timer: Time.now.to_i)
          respond_to do |format|
            format.html { redirect_to challenges_url, notice: 'Checking game results...' }
            format.json { head :no_content }
            format.js { render :nothing => true } 
          end
      end

    end

  end

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
      if score.challenge_points > 0
        score.update(challenge_points: score.challenge_points - 1) 
      end
      respond_to do |format|
        format.html { redirect_to challenges_url, notice: 'Prized challenge was canceled' }
        format.json { head :no_content }
      end
    elsif @status.kind == 5
      @status.update(value: 0)
      @status.update(win_value: 3)
      score = Score.find_by_user_id(current_user.id)
      if score.challenge_points > 0
        score.update(challenge_points: score.challenge_points - 1) 
      end
      respond_to do |format|
        format.html { redirect_to challenges_url, notice: 'Non-Prized challenge was canceled' }
        format.json { head :no_content }
      end
    else
      @status.update(value: 0)
      @status.update(win_value: 3)      
      respond_to do |format|
        format.html { redirect_to challenges_url, alert: 'Something went wrong with your challenge kind' }
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