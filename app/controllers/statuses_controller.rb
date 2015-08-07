 class StatusesController < ApplicationController
  before_action :set_status, only: [:show]
  before_filter :authenticate_user!


  respond_to :html, :xml, :json

  def index
      respond_to do |format|
        format.html { redirect_to root_path}
        format.json { render json: current_user.ignindex.statuses.where("win_value IS ?", nil).last }
      end     
  end

  def show
    respond_to do |format|
      format.html { render nothing: true}
      format.json { render json: @status }
    end    
  end

  def new  
    set_profile_ignindex
    set_profile_status
    set_profile_achievement
    @last_game  = @achievement.statuses.order(created_at: :desc).select { |x| if !x.game_1.empty? then x end }.first
  end

  def create 
    set_profile_ignindex
    @status = Status.create(
      :achievement_id => ignindex.active_achievement,
      :summoner_id => ignindex.summoner_id,
      :summoner_name => ignindex.summoner_name,
      :ignindex_id => ignindex.id,
      :value => 5400,
      :points => 0,
      :kind => 5,
      :pause_timer => 0,
      :trigger_timer => 0,
      :pause_timer => 0,
      :trigger_timer => 0) #all these can be db defaults
    
    respond_to do |format|
      if @status.save
        format.html { redirect_to root_path }
      else
        format.html { redirect_to root_path, alert: 'illBePro engine is temporarily offline!' }
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


    def set_profile_ignindex
      @ignindex = current_user.ignindex
      @ignindex ||= Ignindex.new  
    end

    def set_profile_status
      @status = @ignindex.statuses.last
      @status ||= Status.new(
        :value => 0,
        :created_at => Time.now)
      game_running
    end

    def set_profile_achievement
      @achievement = Achievement.where("id = ?", @ignindex.active_achievement).first
      @achievement ||= Achievement.new
    end

    def game_running
      if !@status.id.nil? && @status.win_value.nil?
        @gamerunning = true
      end   
    end

    def set_status
      @status = Status.find(params[:id])
    end

    def status_params
      params.require(:status).permit(:kind)
    end
end