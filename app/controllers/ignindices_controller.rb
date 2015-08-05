class IgnindicesController < ApplicationController
  before_action :authenticate_user!, except: [:landing_page]

  respond_to :html, :xml, :json
  
  #validatetes: summoner_name :unique

  def landing_page #GET as root
    @ignindex ||= Ignindex.new
  end

  def get_setup #GET as setup
    setup_session_variables
    find_ignindex

    if session[:setup_progress] == 1 #postal
    elsif session[:setup_progress] == 2 #challenge
      setup_step_2
    elsif session[:setup_progress] == 3 #validate
      setup_step_3
    end
  end  

  def zone #GET as zone
    user_ignindex
  end

  def index #GET as summoner
    user_ignindex
    is_summoner_valid_for_ignindex
  end

  def show #GET for ajax
    @ignindex = Ignindex.find(params["id"])
    is_summoner_valid_for_ignindex
    respond_to do |format|
      format.html {render nothing: true}
      format.json {render json: {
        :ignindex => @ignindex,
        :valid => @uu_summoner_validated }}
    end
  end

  def update #POST
    if params[:commit] == "Change Summoner Name" #step3a, unbind+reset setup OR typo
      if (params["ignindex"]["summoner_name"].length < 1) #valid entry?
        redirect_to setup_path, alert: 'Enter your summoner name to continue!'
      elsif !Ignindex.where("user_id = ?", current_user.id).first.nil? #unbind+reset
        Ignindex.where("user_id = ?", current_user.id).first.update(
            :user_id => nil)
        User.find(current_user.id).update(
          :ignindex_id => nil)

        session[:setup_progress] = 1
        redirect_to setup_path, notice: 'Successfully unbound that summoner from your account'
      else #typo treat it as #create
        session[:summoner_name_temp] = params["ignindex"]["summoner_name"]
        session[:summoner_name_ref_temp] = params["ignindex"]["summoner_name"].mb_chars.downcase.gsub(' ', '')          
        
        #Ignindex; get or create
        ignindex = Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first
        if ignindex.nil?
          Rails.logger.info "using a new ignindex"
          @ignindex = Ignindex.new(
            :region_id => session[:region_id_temp],
            :region_id_temp => session[:region_id_temp],          
            :summoner_name => session[:summoner_name_temp],
            :summoner_name_ref => session[:summoner_name_ref_temp])

          @ignindex.save
          session[:ignindex_id] = @ignindex.id
          @achievement = Achievement.new(
            :challenge_id => session[:challenge_id],
            :ignindex_id => @ignindex.id)
          createAch(@ignindex, @achievement)

        else #use existing object
          @ignindex = ignindex
          session[:ignindex_id] = @ignindex.id
          Rails.logger.info "using this ignindex.id: #{@ignindex.id}"

          @ignindex.update(
            :region_id_temp => session[:region_id_temp])

          if @ignindex.active_achievement.nil?
            Rails.logger.info "achievement_id is nil"
            @achievement = Achievement.new(
              :challenge_id => session[:challenge_id],
              :ignindex_id => @ignindex.id)
            createAch(@ignindex, @achievement)
          end
        end

        @ignindex.refresh_validation
        session[:last_validation] = @ignindex.validation_timer
        User.find(current_user.id).update(
            :summoner_id => @ignindex.validation_timer)
        redirect_to setup_path
      end     
    elsif params["commit"] == "Generate Validation Code" #step3b
      @ignindex = Ignindex.find(params[:id])
      @ignindex.refresh_validation
      session[:last_validation] = @ignindex.validation_timer  
      User.find(current_user.id).update(
        :summoner_id => @ignindex.validation_timer)
      
      redirect_to setup_path    
    elsif params["commit"] == "Add Postal/Zip Code" #step1
      @ignindex = Ignindex.find(params[:id])
      update_region_id(@ignindex, ignindex_params[:postal_code])
      @ignindex.update( 
        :region_id => @ignindex.region_id_temp,
        :postal_code => Region.find(@ignindex.region_id_temp).postal_code)
      redirect_to root_path, notice: 'Prizing zone changed'
    elsif params["commit"] == "Accept" || params["commit"] == "Upgrade" #prize accept logic here?
      if @ignindex.prize_id != nil
        @ignindex.assign_prize(params[:commit])
        if params[:commit] == "Accept"
          respond_to do |format|
            format.html { redirect_to scores_path, notice: 'Prize accepted' }
            format.json { head :no_content }
          end
        elsif params[:commit] == "Upgrade"
          respond_to do |format|
            format.html { redirect_to new_status_path, notice: 'Prize Tier Upgraded!' }
            format.json { head :no_content }
          end
        end
      else
        respond_to do |format|
          format.html { redirect_to challenges_url, alert: 'There is an issue with your prize :(' }
          format.json { head :no_content }
        end
      end        
    end
  end

  def create #POST
    if params["commit"] == "Add Postal/Zip Code" #step1
      @ignindex = Ignindex.new(
        :postal_code => ignindex_params[:postal_code])
      update_region_id(@ignindex, ignindex_params[:postal_code]) #gets region_id from postal code
      session[:region_id_temp] = @ignindex.region_id_temp
      session[:postal_code_temp] = ignindex_params[:postal_code]
      
      if @ignindex.region_id_temp.nil?
        redirect_to setup_path, alert: 'Sorry! That zip/postal code does not match anything on our map'
      else
        session[:setup_progress] = 2
        redirect_to setup_path
      end
    elsif params["commit"] == "Select" #step2
      session[:challenge_id] = params["ignindex"]["challenge_id"].to_i
      session[:setup_progress] = 3 #WIP no validation on this being accurate
      redirect_to setup_path
    elsif params["commit"] == "Add Summoner Name" #step3a
      if (params["ignindex"]["summoner_name"].length < 1)
        redirect_to setup_path, alert: 'Enter your summoner name to continue!'
      else
        session[:summoner_name_temp] = params["ignindex"]["summoner_name"]
        session[:summoner_name_ref_temp] = params["ignindex"]["summoner_name"].mb_chars.downcase.gsub(' ', '')          
        
        #Ignindex; get or create
        # ActiveRecord::Base.transaction do
          ignindex = Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first
          if ignindex.nil?
            Rails.logger.info "using a new ignindex"

            @ignindex = Ignindex.create(
              :region_id => session[:region_id_temp],
              :region_id_temp => session[:region_id_temp],          
              :summoner_name => session[:summoner_name_temp],
              :summoner_name_ref => session[:summoner_name_ref_temp])

            session[:ignindex_id] = @ignindex.id
            @achievement = Achievement.new(
              :challenge_id => session[:challenge_id],
              :ignindex_id => @ignindex.id)
            createAch(@ignindex, @achievement)

          else #use existing object
            @ignindex = ignindex
            session[:ignindex_id] = @ignindex.id
            Rails.logger.info "using this ignindex.id: #{@ignindex.id}"

            @ignindex.update(
              :region_id_temp => session[:region_id_temp])

            if @ignindex.active_achievement.nil?
              Rails.logger.info "achievement_id is nil"
              @achievement = Achievement.new(
                :challenge_id => session[:challenge_id],
                :ignindex_id => @ignindex.id)
              createAch(@ignindex, @achievement)
            end
          end
        # end

        @ignindex.refresh_validation
        session[:last_validation] = @ignindex.validation_timer
        if user_signed_in?
          User.find(current_user.id).update(
            :summoner_id => @ignindex.validation_timer)
        end
        redirect_to setup_path
      end
    elsif params["commit"] == "Continue" #step3c (if page not reloaded)
      redirect_to new_status_path #validation is on /statuses/new controller
    else
      redirect_to root_path
    end
  end  

  private

    def find_ignindex
      @ignindex = Ignindex.where("user_id = ?", current_user.id).first
      @ignindex ||= Ignindex.new
    end

    def user_ignindex
      if current_user.ignindex.nil?
        redirect_to setup_path
      else
        @ignindex = current_user.ignindex
      end      
    end

    def setup_session_variables
      @setup_progress ||= session[:setup_progress]
      session[:setup_progress] ||= 1
      session[:region_id_temp] ||= nil
      session[:ignindex_id] ||= nil
      session[:summoner_name_ref_temp] ||= nil
      session[:last_validation] ||= nil    
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

    def createAch(ignindex, achievement)
      Rails.logger.info "HITS createAch method"
      challenge = Challenge.where("id = ?", achievement.challenge_id)
      Rails.logger.info "challenge: #{challenge}"
      Rails.logger.info "empty?: #{challenge.empty?}"
      Rails.logger.info "first?: #{challenge.first}"
      Rails.logger.info "session[:challenge_id]: #{session[:challenge_id]}"
      if !challenge.empty? 
        challenge = challenge.first
        Rails.logger.info "challenge: #{challenge.id}"
        achievement.update(   #this creates a lot of duplicates in db...
          :ignindex_id => ignindex.id,
          :region_id => ignindex.region_id,
          :challenge_id => challenge.id,
          :expire => challenge.expiery,
          :name => challenge.name,
          :merchant => challenge.merchant,
          :has_prizing => challenge.local_prizing,
          :can_spell_name => challenge.can_spell_name,
          :can_spell_name_open => challenge.can_spell_name,
          :wins_required => challenge.wins_required,
          :wins_recorded => 0,
          :con_wins_recorded => 0)

        Rails.logger.info "@achievement.id: #{@achievement.id}"

        Ignindex.find(ignindex.id).update(
          :active_achievement => achievement.id)
        Rails.logger.info "@achievement.id: #{@achievement.id}"
      end
    end  

    def update_region_id(ignindex, dirty_postal)
      @ignindex = ignindex
      postal_search = dirty_postal.to_s

      #auto-detect where the postal code is from + format it for search
      if !/[0-9]/.match(postal_search[0]).nil? #this is a zip code
        if postal_search.length > 5
          postal_search = postal_search[0..4]
        end
        if !Region.where("postal_code = ?", postal_search).first.nil?
          @ignindex.region_id_temp = Region.where("postal_code = ?", postal_search).first.id
        end
      elsif !/[a-zA-Z]/.match(postal_search[0]).nil? #this is a postal code
        if postal_search.length >= 3
          postal_search = postal_search[0..2].upcase
        end 
        if !Region.where("postal_code = ?", postal_search).first.nil?
          @ignindex.region_id_temp = Region.where("postal_code = ?", postal_search).first.id
        end
      else
        Rails.logger.info "alkatraz"
      end
    end  

    def is_summoner_valid_for_ignindex
      if (@ignindex.user_id == current_user.id) && @ignindex.summoner_validated == true
        @uu_summoner_validated = true
      end 
      @uu_summoner_validated ||= false
    end


    def ignindex_params    
      params.require(:ignindex).permit(:user_id, :postal_code, :summoner_name, :summoner_id, :summoner_validated, :validation_string, :validation_timer) if params[:ignindex]
    end
end
