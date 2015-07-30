class IgnindicesController < ApplicationController
  before_action :set_ignindex, only: [:show, :edit, :update, :destroy]

  # before_filter :authenticate_user!

  respond_to :html, :xml, :json
  
  def landing_page #GET as root
    @ignindex = Ignindex.new
  end

  def get_setup #GET as setup
    if user_signed_in?
      session[:setup_progress] ||= 1
      session[:region_id_temp] ||= nil
      session[:ignindex_id] ||= nil
      session[:summoner_name_ref_temp] ||= nil
      session[:last_validation] ||= nil

      @setup_progress = session[:setup_progress]

      @ignindex = Ignindex.where("user_id = ?", current_user.id).first
      if @ignindex.nil?
        @ignindex = Ignindex.new
      end

      if session[:setup_progress] == 1 #postal
      elsif session[:setup_progress] == 2 #challenge
        if session[:region_id_temp].nil? #redidrect to step1
          redirect_to setup_path
        else
          region = Region.where("id = ?", session[:region_id_temp]).first
          @region_postal = region.postal_code
          @challenges_global = Challenge.where("global = ?", true).map { |x| x }
          @challenges_local = region.challenges.map { |x| x }
          @challenges_country = Challenge.where("country = ?", region.country).map { |x| x }

        end
      elsif session[:setup_progress] == 3 #validate
        if @ignindex.id.nil? && (session[:region_id_temp].nil? or session[:challenge_id].nil?) #redidrect to step1
          rsession[:setup_progress] = 1
          redirect_to setup_path
        else
          if !Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first.nil?
            @ignindex = Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first
            session[:ignindex_id] = @ignindex.id
          end 
          if (@ignindex.user_id == current_user.id) && @ignindex.summoner_validated == true
            @uu_summoner_validated = true
          else 
             @uu_summoner_validated = false
          end
        end
        @league_api_ping = Staticpage.find(1).league_api_ping
      end
    else
      redirect_to new_user_session_path, flash: {alert: "You need to be logged in!"}
    end
  end  

  def zone #GET as zone
    if user_signed_in?
      if !current_user.ignindex_id.nil?
        @ignindex = Ignindex.where("user_id = ?", current_user.id).first
        if !@ignindex.region_id.nil?
          @zone_pc = @ignindex.region.postal_code
        else
          @zone_pc = "?"
        end
      else
        redirect_to setup_path
      end
    else
      redirect_to new_user_session_path, flash: {alert: "You need to be logged in!"}
    end
  end

  def index #GET as summoner
    @setup_progress = 3
    session[:region_id_temp] ||= nil

    if user_signed_in? && !Ignindex.find_by_user_id(current_user.id).nil?
      using_ign = Ignindex.find_by_user_id(current_user.id)
    
      if using_ign.nil?
        if session[:region_id_temp].blank?
          redirect_to new_ignindex_path
        end
        @uu_summoner_validated = false
        @ignindex = Ignindex.new(
          :region_id => session[:region_id_temp])
      else
        @ignindex = using_ign
        is_summoner_valid(using_ign)
        session[:ignindex_id] = @ignindex.id
      end

    else #user not signed in
      redirect_to new_user_session_path, flash: {alert: "You need to be logged in!"}
    end #end of user in/out block
  end

  def show #GET for ajax
    if user_signed_in? && !Ignindex.find_by_user_id(current_user.id).nil?

      respond_to do |format|
        format.html {render nothing: true}
        format.json {render json: {
          :ignindex => Ignindex.find_by_user_id(current_user.id),
          :valid => Ignindex.find_by_user_id(current_user.id).summoner_validated }}
      end
    else
      respond_to do |format|
        format.html {render nothing: true}
        format.json {render nothing: true}
      end
    end
  end

  def update #POST
    if user_signed_in?
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
        @ignindex.refresh_validation
        session[:last_validation] = @ignindex.validation_timer  
        User.find(current_user.id).update(
          :summoner_id => @ignindex.validation_timer)
        
        redirect_to setup_path    
      elsif params["commit"] == "Continue" #step3c
        session[:setup_progress] = 3
        redirect_to new_status_path #validation on status#new controller
      elsif params["commit"] == "Add Postal/Zip Code" #step1
        update_region_id(@ignindex, ignindex_params[:postal_code])
        @ignindex.update( 
          :region_id => @ignindex.region_id_temp,
          :postal_code => Region.find(@ignindex.region_id_temp).postal_code)
        redirect_to new_status_path, notice: 'Prizing zone changed'
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
    else
      redirect_to new_user_session_path, flash: {alert: "You need to be logged in!"}
    end    
  end

  def create #POST
    if user_signed_in?
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
          if user_signed_in?
            User.find(current_user.id).update(
              :summoner_id => @ignindex.validation_timer)
          end
          redirect_to setup_path
        end
      elsif params["commit"] == "Continue" #step3c (if page not reloaded)
        redirect_to new_status_path #validation is on /statuses/new controller
      end
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
    Rails.logger.info "method postal: #{ignindex.postal_code}, dity_postal: #{dirty_postal}"
    postal_search = dirty_postal.to_s

    #auto-detect where the postal code is from + format it for search
    Rails.logger.info "us?: #{!/[0-9]/.match(postal_search[0]).nil?}"
    Rails.logger.info "ca?: #{!/[a-zA-Z]/.match(postal_search[0]).nil?}"
    if !/[0-9]/.match(postal_search[0]).nil? #this is a zip code
      if postal_search.length > 5
        postal_search = postal_search[0..4]
      end
      if !Region.where("postal_code = ?", postal_search).first.nil?
        @ignindex.region_id_temp = Region.where("postal_code = ?", postal_search).first.id
      end
      Rails.logger.info "US_postal: #{postal_search}"
      Rails.logger.info "US_region: #{ignindex.region_id_temp}"
    elsif !/[a-zA-Z]/.match(postal_search[0]).nil? #this is a postal code
      if postal_search.length >= 3
        postal_search = postal_search[0..2].upcase
      end 
      if !Region.where("postal_code = ?", postal_search).first.nil?
        @ignindex.region_id_temp = Region.where("postal_code = ?", postal_search).first.id
      end
      Rails.logger.info "CA_postal: #{postal_search}"
      Rails.logger.info "CA_region: #{ignindex.region_id_temp}"
    else
      Rails.logger.info "alkatraz"
      #error entering postal code!
    end
    Rails.logger.info "#postal_search: #{postal_search}"
  end  
  
  def is_summoner_valid(current_ignindex)
    if current_ignindex.summoner_validated == true
      @uu_summoner_validated = true
    else
      @uu_summoner_validated = false
    end
  end

  private
    def set_ignindex
      @ignindex = Ignindex.find(params[:id])
    end

    def ignindex_params
      # this is dangerous! Fix me asap.
      params.require(:ignindex).permit(:user_id, :postal_code, :summoner_name, :summoner_id, :summoner_validated, :validation_string, :validation_timer) if params[:ignindex]
    end
end
