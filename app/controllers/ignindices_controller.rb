class IgnindicesController < ApplicationController
  before_action :authenticate_user!, except: [:landing_page]
  before_action :user_ignindex, only: [:zone, :index]
  before_action :set_ignindex, only: [:show, :update]
  before_action :new_ignindex, only: [:landing_page, :get_setup]

  respond_to :html, :xml, :json
  
  def landing_page
  end

  def zone
  end

  def index #GET as summoner
    if !@ignindex.nil?
      is_summoner_valid_for_ignindex
    end
  end

  def show #GET for ajax
    is_summoner_valid_for_ignindex
    respond_to do |format|
      format.html {render nothing: true}
      format.json {render json: {
        :ignindex => @ignindex,
        :valid => @uu_summoner_validated }}
    end
  end  

  def get_setup #GET as setup
    setup_session_variables

    if session[:setup_progress] == 1 #postal
    elsif session[:setup_progress] == 2 #challenge
      setup_step_2
    elsif session[:setup_progress] == 3 #validate
      setup_step_3
    end
  end  

  def update
    if params[:commit] == "Change Summoner Name" #step3a, unbind+reset setup OR typo
      change_summoner_name  
    elsif params[:commit] == "Generate Validation Code" #step3b
      generate_validation_code
    elsif params[:commit] == "Add Postal/Zip Code" #step1
      update_postal_code
    elsif params[:commit] == "Accept" || params[:commit] == "Upgrade" #prize accept
      prize_accept_upgrade     
    end
  end

  def create
    if params[:commit] == "Add Postal/Zip Code" #step1
      add_postal_code
    elsif params[:commit] == "Select" #step2
      select_challenge
      redirect_to setup_path
    elsif params[:commit] == "Add Summoner Name" #step3a
      change_summoner_name
      redirect_to setup_path
    end

  end  

  private

  def set_ignindex
    @ignindex = Ignindex.find(params["id"])
  end

  def new_ignindex
    @ignindex ||= Ignindex.new
  end

  def prize_accept_upgrade
    if @ignindex.prize_id != nil
      if @ignindex.user == current_user
        @ignindex.assign_prize(params[:commit])
        if params[:commit] == "Accept"
          redirect_to scores_path, notice: 'Prize accepted'
        else params[:commit] == "Upgrade"
          redirect_to root_path, notice: 'Prize Tier Upgraded!'
        end
      else
        redirect_to root_path, alert: 'You are not allowed to do that!'  
      end
    else
      redirect_to root_path, alert: 'There is an issue with your prize :('
    end       
  end

  def generate_validation_code
    @ignindex.refresh_validation
    session[:last_validation] = @ignindex.validation_timer  
    current_user.update(
      :summoner_id => @ignindex.validation_timer)
    redirect_to setup_path, notice: 'New validation code generated'
  end

  def update_postal_code
    region = Region.postal_to_region(params[:ignindex][:postal_code])
    if region.nil?
      redirect_to zone_path, alert: 'Sorry! That zip/postal code does not match anything on our map'
    else
      if @ignindex.user == current_user
        @ignindex.update( 
          :region_id => region.id,
          :postal_code => region.postal_code)
        redirect_to root_path, notice: 'Prizing zone changed'
      else
        redirect_to root_path, alert: 'You are not allowed to do that!'
      end
    end
  end

  def add_postal_code
    region = Region.postal_to_region(params[:ignindex][:postal_code])
    
    if region.nil?
      session[:setup_progress] = 1
      redirect_to setup_path, alert: 'Sorry! That zip/postal code does not match anything on our map'
    else
      session[:region_id_temp] = region.id
      session[:postal_code_temp] = region.postal_code
      session[:setup_progress] = 2
      redirect_to setup_path
    end
  end

  def select_challenge
    session[:challenge_id] = params[:ignindex][:challenge_id].to_i
    session[:setup_progress] = 3
  end  

  def add_summoner_name
    session[:summoner_name_temp] = params[:ignindex][:summoner_name]
    session[:summoner_name_ref_temp] = params[:ignindex][:summoner_name].mb_chars.downcase.gsub(' ', '')    

    @ignindex = Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first
    @ignindex ||= Ignindex.new

    ActiveRecord::Base.transaction do
      @ignindex = @ignindex.create_or_update_ignindex(session[:region_id_temp], session[:summoner_name_temp], session[:summoner_name_ref_temp], session[:challenge_id])
      current_user.update(
        :summoner_id => @ignindex.validation_timer)
      session[:last_validation] = @ignindex.validation_timer
      session[:ignindex_id] = @ignindex.id
    end

  end

  def change_summoner_name #unbind or trigger add_summoner_name
    if !Ignindex.where("user_id = ?", current_user.id).first.nil? #unbind+reset
      Ignindex.where("user_id = ?", current_user.id).first.update(
          :user_id => nil)
      User.find(current_user.id).update(
        :ignindex_id => nil)

      session[:setup_progress] = 1
      redirect_to setup_path, notice: 'Successfully unbound that summoner from your account'
    else
      add_summoner_name
    end   
  end

  def user_ignindex
    @ignindex ||= current_user.ignindex      
    if current_user.ignindex.nil?
      redirect_to setup_path, notice: "let's set up your summoner name"
    end
  end

  def setup_session_variables
    session[:setup_progress] ||= 1
    @setup_progress ||= session[:setup_progress]
  end

  def setup_step_2
    if session[:region_id_temp].nil?
      reset_setup
    else
      temp_ignindex
      @all_challenges = @ignindex.available_challenges
    end      
  end 

  def temp_ignindex
    @ignindex = Ignindex.new(
      :region_id => session[:region_id_temp],
      :postal_code => Region.find(session[:region_id_temp]).postal_code)
  end

  def setup_step_3
    if session[:region_id_temp].nil? or session[:challenge_id].nil?
      reset_setup
    else
      find_unauth_ignindex(session[:summoner_name_ref_temp])
      is_summoner_valid_for_ignindex
      @league_api_ping = Staticpage.find(1).league_api_ping
    end      
  end  

  def reset_setup
    session[:setup_progress] = 1
    redirect_to setup_path      
  end

  def find_unauth_ignindex(summoner_name_ref_temp)
    ignindex = Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first
    if !ignindex.nil?
      @ignindex = ignindex
      session[:ignindex_id] = @ignindex.id
    end     
  end

  def is_summoner_valid_for_ignindex
    if (@ignindex.user_id == current_user.id) && @ignindex.summoner_validated == true
      @uu_summoner_validated = true
    end 
    @uu_summoner_validated ||= false
  end

  def ignindex_params    
    params.require(:ignindex).permit() if params[:ignindex]
  end
end