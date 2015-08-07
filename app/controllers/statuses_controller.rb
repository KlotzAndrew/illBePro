 class StatusesController < ApplicationController
  before_action :set_status, only: [:show, :update, :destroy]
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
    @status.update(trigger_timer: Time.now.to_i)
    respond_to do |format|
      format.html { redirect_to root_path, notice: 'Checking game results...' }
    end
  end

  def destroy
    @status.update(
      :value => 0,
      :win_value => 3)
    redirect_to root_path
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