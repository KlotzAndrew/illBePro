 class StatusesController < ApplicationController
  before_action :set_status, only: [:show, :edit, :update, :destroy]

  # before_filter :authenticate_user!

  respond_to :html, :xml, :json

  # GET /statuses
  # GET /statuses.json
  def index
     respond_to do |format|
        format.html { redirect_to root_path}
        format.json { render json: current_user.ignindex.statuses.where("win_value IS ?", nil).last }
      end     
  end


  def show
    if user_signed_in?
      respond_to do |format|
        format.html { render nothing: true}
        format.json { render json: Status.find(params[:id]) }
      end    
    else
     respond_to do |format|
        format.html { render nothing: true}
        format.json { render json: Status.where("ignindex_id = ?", session[:ignindex_id]).last }
      end 
    end
  end

  def new
    if !user_signed_in?
      redirect_to new_user_session_path, flash: {alert: "You need to be logged in!"}      
    else #user signed-in; this can be refractored
    
    @status = Status.new(
      :value => 0,
      :created_at => Time.now)
    @ignindex = Ignindex.where("user_id = ?", current_user.id).first
      if @ignindex.nil? #redirect

        faker_values
        session[:setup_progress] = 1
      elsif @ignindex.region_id.nil? #redirect
        faker_values
        # redirect_to zone_url, alert: 'You need a valid Postal Code!'
      else

        if !@ignindex.statuses.last.nil? && @ignindex.statuses.last.win_value.nil?
          @status = @ignindex.statuses.last
          @gamerunning = true
          # if @status.trigger_timer > (Time.now.to_i - 300)
          #  @checkdata = true
          # end
        end

        @achievement = Achievement.where("id = ?", @ignindex.active_achievement).first
        if @achievement.nil?
          @achievement = Achievement.new
        end

        @last_game  = @achievement.statuses.order(created_at: :desc).select { |x| if !x.game_1.empty? then x end }.first
        # @last_game  = Status.order(created_at: :desc).select { |x| if !x.game_1.empty? then x end }.first
        # @game_history = @achievement.statuses.order(created_at: :desc)

      end
 
    end
  end

  def faker_values
    @ignindex = Ignindex.new
    @achievement = Achievement.new
    @ignindex.summoner_name = "No Summoner Name"
  end

  def get_current_achievement(session_ignindex_id) #input also takes current_user.ignindex_id
    Rails.logger.info "session_ignindex_id: #{session_ignindex_id}"
    gca_ign = Ignindex.where("id = ?", session_ignindex_id).first
    Rails.logger.info "gca_ign.id: #{gca_ign.id}"
    if gca_ign.active_achievement.nil?

      if Region.find(gca_ign.region_id).prize_id_tier1.nil? #fixes sloppy db default vars
        Region.find(gca_ign.region_id).update(
          :prize_id_tier1 => "[]")
      end

      if JSON.parse(Region.find(gca_ign.region_id).prize_id_tier1)[0] == 1
        prizing_here = 1
      else
        prizing_here = 0
      end
      gca_ach_search = Achievement.where("ignindex_id = ?", gca_ign.id).where("result IS ?", nil).where("kind = ?", prizing_here).first

      if gca_ach_search.nil?
        new_ach = Achievement.create(
          :ignindex_id => session_ignindex_id,
          :experience_req => 10,
          :can_spell_name => "CORA",
          :can_spell_name_open => "CORA",
          :description => "Earn 10 experience points to get an end of the week reward. Each win recoded is 1exp, winning game with a champion whose name starts with one of the letters CORA is 2exp.",
          :kind => prizing_here,
          :expire => 4.weeks.from_now.to_i )
        Ignindex.where("id = ?", session_ignindex_id).first.update(
          :active_achievement => new_ach.id)
      else        
        new_ach = gca_ach_search
        Ignindex.where("id = ?", session_ignindex_id).first.update(
          :active_achievement => new_ach.id)        
      end

      @achievement = new_ach
      number = @achievement.experience_earned/@achievement.experience_req
      @achievement_progress = number.round(2)
      
    else
      @achievement = Achievement.find(Ignindex.where("id = ?", session_ignindex_id).first.active_achievement)
    end
  end

  def create # does not take any params

    @ignindex = Ignindex.where("user_id = ?", current_user.id).first
    @status = Status.new(
      :achievement_id => @ignindex.active_achievement,
      :summoner_id => @ignindex.summoner_id,
      :summoner_name => @ignindex.summoner_name,
      :ignindex_id => @ignindex.id,
      :value => 5400,
      :points => 0,
      :kind => 5,
      :pause_timer => 0,
      :trigger_timer => 0,
      :pause_timer => 0,
      :trigger_timer => 0)

    @status.save
    
    respond_to do |format|
      if @status.save
        format.html { redirect_to root_path }
        format.json { head :no_content }
        format.js { redirect_to root_path}
      else
        format.html { redirect_to root_path, alert: 'illBePro engine is temporarily offline!' }
        format.json { render json: @status.errors, status: :unprocessable_entity }
        format.js { redirect_to root_path, alert: 'illBePro engine is temporarily offline!' }
      end
    end
  end

  def update
    
    if @status.roll_status == 1 #UPDATE (using AJAX for calls, redirect making no sense)
      @status.update(roll_status: 1)
         respond_to do |format|
            format.html { redirect_to root_path, notice: 'Challenge getting started' }
            format.json { head :no_content }
            format.js { render :nothing => true}
          end      
    else

      @status.update(trigger_timer: Time.now.to_i)
      respond_to do |format|
        format.html { redirect_to root_path, notice: 'Checking game results...' }
        format.json { head :no_content }
        format.js { render :nothing => true } 
      end

    end
  end

  def destroy
    if @status.kind == 6
       Rails.logger.info "destroy controller triggered, kind 6"
      @status.update(
        :value => 0,
        :win_value => 0)
      Prize.where(assignment: 1).where(user_id: current_user.id).last.update( {
        :assignment => 0,
        :user_id => 0,
        })
      respond_to do |format|
        format.html { redirect_to root_path }
        format.json { head :no_content }
      end
    elsif @status.kind == 5
      Rails.logger.info "destroy controller triggered, kind 5"
      @status.update(value: 0)
      @status.update(win_value: 3)
      # score = Score.find_by_user_id(current_user.id)
      # if score.challenge_points > 0
      #   score.update(challenge_points: score.challenge_points - 1) 
      # end
      respond_to do |format|
        format.html { redirect_to root_path }
        format.json { head :no_content }
      end
    else
      Rails.logger.info "destroy controller triggered, type nil"
      @status.update(value: 0)
      @status.update(win_value: 3)      
      respond_to do |format|
        format.html { redirect_to root_path, alert: 'Something went wrong with your challenge kind' }
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