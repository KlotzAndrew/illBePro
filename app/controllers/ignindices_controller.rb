class IgnindicesController < ApplicationController
  before_action :set_ignindex, only: [:show, :edit, :update, :destroy]

  helper_method :show_prizes

  # before_filter :authenticate_user!

  respond_to :html, :xml, :json
  
  def landing_page
    session[:setup_progress] ||= 0
    @ignindex = Ignindex.new
    
  end

  def zone
    if user_signed_in? && !current_user.ignindex_id.nil?
      @ignindex = Ignindex.find_by_user_id(current_user.id)
      if !Ignindex.find_by_user_id(current_user.id).postal_code.nil?
        @zone_pc = @ignindex.region.postal_code
      else
        @zone_pc = "?"
      end
    else
      redirect_to setup_path
    end
  end

  def show #for ajax requests only
    if user_signed_in? && !Ignindex.find_by_user_id(current_user.id).nil?
      respond_to do |format|
        format.html {render nothing: true}
        format.json {render json: {
          :ignindex => Ignindex.find_by_user_id(current_user.id),
          :valid => Ignindex.find_by_user_id(current_user.id).summoner_validated }}
      end
    else
      ign = Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first
      if ign.last_validation == session[:last_validation]
        valid = true
      else
        valid = false
      end

      respond_to do |format|
        format.html {render nothing: true}
        format.json {render json: {
          :ignindex => ign,
          :valid => valid }}

      end
    end
  end

  def get_setup

    #_1 step1
    @setup_navbar_toggle = true
    session[:setup_progress] ||= 0
    setup_progress_finder(session[:setup_progress])

    if session[:setup_progress] == 0 #set @ignindex, or reset_session_vars
      @setup_progress = session[:setup_progress]
      if user_signed_in? 
        step1_ign = Ignindex.find_by_user_id(current_user.id)
        if step1_ign.nil?
          step1_ign = Ignindex.new
        end

        if step1_ign.summoner_validated == true
          @ignindex = step1_ign #triggers 'update' action
        else
          reset_session_vars
          @ignindex = Ignindex.new #triggers 'new' action        
        end
      else
        reset_session_vars
        @ignindex = Ignindex.new #triggers 'new' action
      end
      #_1 end step1
    elsif session[:setup_progress] == 1 #set @ignindex, or reset_session_vars
      @setup_progress == session[:setup_progress]
      #this is a validation for having a region_id
      #*****may raise error for some users (use case?)
      @ignindex = Ignindex.new 
      if session[:region_id_temp].blank? or session[:region_id_temp] == nil
        redirect_to setup_path
        reset_session_vars
      else
        show_prizes(session[:region_id_temp])
        show_prizes_v2(session[:region_id_temp])
      end    
    elsif session[:setup_progress] == 2 or session[:setup_progress] == 3
      @setup_progress = 2

      session[:region_id_temp] ||= nil

      if user_signed_in? && !Ignindex.find_by_user_id(current_user.id).nil?
        using_ign = Ignindex.find_by_user_id(current_user.id)
      
        if using_ign.nil? #set @ignindex
          if session[:region_id_temp].blank?
            redirect_to new_ignindex_path #bad spot for redirect
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
        session[:region_id_temp] ||= nil
        if session[:region_id_temp].blank?
          reset_session_vars
          redirect_to setup_path
        elsif session[:summoner_name_ref_temp].blank?
          @ignindex = Ignindex.new(
            :region_id => session[:region_id_temp])          
        else
          if !Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first.nil?
            @ignindex = Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first
            session[:ignindex_id] = @ignindex.id
            #dont load in the full object -_-; fix me later
          else
            @ignindex = Ignindex.new(
              :region_id => session[:region_id_temp])
          end
          is_unauth_summoner_valid(@ignindex, session[:last_validation])
        end

      end #end of user in/out block

    else
    end
  end


  def get_unauth_ignindex #sets @ignindex to new or existing
    if !session[:summoner_name_ref_temp].blank? && !Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first.nil?
      @ignindex = Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first
      session[:ignindex_id] = @ignindex.id
      #dont load in the full object -_-; fix me later
    else
      @ignindex = Ignindex.new(
        :region_id => session[:region_id_temp])
    end
  end
  
  def is_summoner_valid(current_ignindex)
    if current_ignindex.summoner_validated == true
      @uu_summoner_validated = true
    else
      @uu_summoner_validated = false
    end
  end

  def is_unauth_summoner_valid(current_ignindex, session_validation) #checks is valid w/ session token
    if (current_ignindex.summoner_validated == true) && (current_ignindex.last_validation == session_validation)
      @uu_summoner_validated = true
    else
      @uu_summoner_validated = false
    end    
  end    

  def setup_progress_finder(setup_progress)
    @setup_progress = setup_progress
  end

  def reset_session_vars
      session[:setup_progress] = 0
      session[:postal_code_temp] = nil
      session[:region_id_temp] = nil
      session[:summoner_name_temp] = nil
      session[:summoner_name_ref_temp] = nil
      session[:ignindex_id] = nil    
      session[:last_validation] = nil
      session[:last_game] = 0
  end

  def reset_setup
    reset_session_vars
    redirect_to root_path

  end

  def new # step 2
    #user enters postal code. udpate action for existing user w/ ignindex, else create action
    #settings refresh redirects to here
    #no validations required for this page
    @setup_progress = 0

    if user_signed_in? 
      step2_ign = Ignindex.find_by_user_id(current_user.id)
      if step2_ign.nil?
        step2_ign = Ignindex.new
      end

      if step2_ign.summoner_validated == true
        @ignindex = step2_ign #triggers 'update' action
      else
        reset_session_vars
        @ignindex = Ignindex.new #triggers 'new' action        
      end
    else
      reset_session_vars
      @ignindex = Ignindex.new #triggers 'new' action
    end
  end


  def get_started # step 3
    #user just presses 'ok'
    @setup_progress = 1

    #this is a validation for having a region_id
    #*****will raise error for some users
    if session[:region_id_temp].blank?
      redirect_to new_ignindex_path
    else
      show_prizes(session[:region_id_temp])
    end

  end



  def show_prizes_v2(x)
    if [43867, 43869, 43855, 43856, 43857, 43847].include?(x) #[43871, 43873, 43859, 43860, 43861, 43851] is local server id's
      @tagged_for_prizing = true
    else
      @tagged_for_prizing = false
    end
  end

  def show_prizes(x) #prize region logic (duplicate in ignindeces/statuses controller)
    @all_prize_desc = []
    @all_prize_vendor = []

    region = Region.find(x)

    @region_city = region.city
    @region_country = region.country
    @region_postal = region.postal_code
        
    if !region.prizes.last.nil? #use local prize
      region.prizes.each do |y|
        @all_prize_desc << y.description
        @all_prize_vendor = y.vendor
      end
    else #use global prize
      y = Prize.all.where("country_zone = ?", region.country).where("assignment = ? OR assignment = ?", 0,1).where("tier = ?", "1").first
      if !y.nil?
        @all_prize_desc << y.description
        @all_prize_vendor = y.vendor
      end
    end  
  end

  def games #step 4
    #user just presses 'ok'
    @setup_progress = 2

    #this is a validation for having a region_id
    #*****will raise error for some users
    if session[:region_id_temp].blank?
      redirect_to new_ignindex_path
    end    
  end

  def index #step 5
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
      session[:region_id_temp] ||= nil
      if session[:region_id_temp].blank?
        redirect_to new_ignindex_path
      else
        get_unauth_ignindex #sets @ignindex to existing or new
        is_unauth_summoner_valid(@ignindex, session[:last_validation])
      end

    end #end of user in/out block
  end


  def update # used on step 2 and 4 (if using @ignindex.where("...").first.not.nil?)
    Rails.logger.info "triggering add/update on ignindex#update"
    if params[:commit] == "Add Summoner Name" or params[:commit] == "Update Summoner Name" 

      session[:summoner_name_temp] = params["ignindex"]["summoner_name"]
      session[:summoner_name_ref_temp] = params["ignindex"]["summoner_name"].mb_chars.downcase.gsub(' ', '')
      session[:last_validation] = nil

 
      #check if ignindex for summmoner aleady exists and assign
      if session[:summoner_name_ref_temp].blank? 
        Rails.logger.info "name entered was nil"
        Rails.logger.info "params.legth: #{params["ignindex"]["summoner_name"].length}"

      elsif !Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first.nil?

        #assign ignindex to current session
        @ignindex = Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first
        session[:ignindex_id] = @ignindex.id

        #set temp validator
        @ignindex.update(
          :region_id_temp => session[:region_id_temp])
      else #new ignindex required for summoner

        @ignindex = Ignindex.new(
          :region_id => session[:region_id_temp],
          :region_id_temp => session[:region_id_temp],
          :summoner_name => session[:summoner_name_temp],
          :summoner_name_ref => session[:summoner_name_ref_temp])
        @ignindex.save

        #assign it to current session
        session[:ignindex_id] = @ignindex.id
      end    

      #reset validation timer && assign match to session
      @ignindex.refresh_validation
      session[:last_validation] = @ignindex.validation_timer

      #assign validator to user
      if user_signed_in?
        Rails.logger.info "this should trigger user adding ignindex#update"
  
        if !Ignindex.find_by_user_id(current_user.id).nil? #remove user from any current ignindex
          Ignindex.find_by_user_id(current_user.id).update(
            :user_id => nil)
        end
        User.find(current_user.id).update(
          :summoner_id => @ignindex.validation_timer)

        Rails.logger.info "matching validation summoner_id: #{User.find(current_user.id).summoner_id}"
        Rails.logger.info "matching validation summoner_id: #{@ignindex.validation_timer}"
      end

      Rails.logger.info "session sum name: #{session[:summoner_name_ref_temp]}"

    elsif params["commit"] == "Continue"
      #this moves from step3 to step4
      session[:setup_progress] = 3
      respond_to do |format|
        format.html { redirect_to new_status_path }
        format.json { head :no_content } 
      end         

    elsif params["commit"] == "Add Postal/Zip Code" or params["commit"] == "Search Postal/Zip Code" or params["commit"] == "Search"
      reset_session_vars
      update_region_id(@ignindex, ignindex_params[:postal_code])

      if user_signed_in?
        if current_user.id == @ignindex.user_id && @ignindex.summoner_validated == true
          @ignindex.update( 
            :region_id => @ignindex.region_id_temp,
            :postal_code => Region.find(@ignindex.region_id_temp).postal_code)
        end
      end
        respond_to do |format|
          format.html { redirect_to new_status_path, notice: 'Prizing zone changed' }
          format.json { head :no_content }
        end
    elsif params[:commit] == "Accept" || params[:commit] == "Upgrade"
      Rails.logger.info "Doing stuff with prize: #{params[:commit]}"
      if user_signed_in?
        if @ignindex.prize_id != nil
          @ignindex.assign_prize(params[:commit])
          if params[:commit] == "Accept"
            respond_to do |format|
              format.html { redirect_to scores_path, notice: 'Prize accepted' }
              format.json { head :no_content }
            end
          elsif params[:commit] == "Upgrade"
            respond_to do |format|
              format.html { redirect_to new_status_path, notice: 'Prize not accepted! Keep playing for other prizes' }
              format.json { head :no_content }
            end
          end
        else
          respond_to do |format|
            format.html { redirect_to challenges_url, alert: 'There is an issue with your prize :(' }
            format.json { head :no_content }
          end
        end
      
      else
        respond_to do |format|
          format.html { redirect_to challenges_url, alert: 'You need to be signed in to recieve your prize' }
          format.json { head :no_content }
        end

      end
    elsif params["commit"] == "Generate Validation Code"
      Rails.logger.info "triggers update for: new 'gen validation code'"
      @ignindex.refresh_validation
      session[:last_validation] = @ignindex.validation_timer

      #assign validator to user
      if user_signed_in?
        Rails.logger.info "this should trigger user adding ignindex#update"
  
        if !Ignindex.find_by_user_id(current_user.id).nil? #remove user from any current ignindex
          Ignindex.find_by_user_id(current_user.id).update(
            :user_id => nil)
        end
        User.find(current_user.id).update(
          :summoner_id => @ignindex.validation_timer)

        Rails.logger.info "matching validation summoner_id: #{User.find(current_user.id).summoner_id}"
        Rails.logger.info "matching validation summoner_id: #{@ignindex.validation_timer}"
      end
    else
      #error?
    end
  end

  def create # runs on step 2 and 4 (if using @ignindex.new; runs on 'add' or 'update'
    Rails.logger.info "hit create controller"
    if params["commit"] == "Add Postal/Zip Code" or params["commit"] == "Search Postal/Zip Code" or params["commit"] == "Search"#no save action
      reset_session_vars

      Rails.logger.info "params_psotal_code: #{ignindex_params[:postal_code]}"
      @ignindex = Ignindex.new(
        :postal_code => ignindex_params[:postal_code])

      Rails.logger.info "self.postal_code: #{@ignindex.postal_code}"
      update_region_id(@ignindex, ignindex_params[:postal_code]) #gets region_id from postal code
      
      session[:region_id_temp] = @ignindex.region_id_temp
      session[:postal_code_temp] = ignindex_params[:postal_code]
      if @ignindex.region_id_temp.nil?
        respond_to do |format|
          format.html { redirect_to setup_path, alert: 'Sorry! That zip/postal code does not match anything on our map' }
          format.json { head :no_content }
        end 
      else
        session[:setup_progress] = 1
        respond_to do |format|
          format.html { redirect_to setup_path }
          format.json { head :no_content } 
        end 
      end
      # redirect_to get_started_path
    elsif params["commit"] == "Continue Anyway" or params["commit"] == "Select"
      session[:setup_progress] = 2
      respond_to do |format|
        format.html { redirect_to setup_path }
        format.json { head :no_content } 
      end      
    elsif params["commit"] == "Continue"
      #this moves from step3 to step4
      session[:setup_progress] = 3
      respond_to do |format|
        format.html { redirect_to new_status_path }
        format.json { head :no_content } 
      end        
    elsif params[:commit] == "Add Summoner Name" # save action for ign
      if params["ignindex"]["summoner_name"].length < 1 #filters nil entries
        Rails.logger.info "name entered was nil"
        Rails.logger.info "params.legth: #{params["ignindex"]["summoner_name"].length}"
      else
      
        session[:summoner_name_temp] = params["ignindex"]["summoner_name"]
        session[:summoner_name_ref_temp] = params["ignindex"]["summoner_name"].mb_chars.downcase.gsub(' ', '')

        #check for existing && valid ignindex
        if session[:summoner_name_ref_temp].blank?
          Rails.logger.info "name entered was blank"
          Rails.logger.info "params.legth: #{params["ignindex"]["summoner_name"].length}"
        elsif !Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first.nil?
          @ignindex = Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first
          session[:ignindex_id] = @ignindex.id
          Rails.logger.info "using this ignindex.id: #{@ignindex.id}"
          #dont load in the full object -_-; fix me later

          @ignindex.update(
            :region_id_temp => session[:region_id_temp])

        else
          Rails.logger.info "using a new ignindex"
          @ignindex = Ignindex.new(
            :region_id => session[:region_id_temp],
            :region_id_temp => session[:region_id_temp],          
            :summoner_name => session[:summoner_name_temp],
            :summoner_name_ref => session[:summoner_name_ref_temp])

          @ignindex.save
          session[:ignindex_id] = @ignindex.id
        end
        # @ignindex.refresh_validation
        # session[:last_validation] = @ignindex.validation_timer

        if user_signed_in?
          Rails.logger.info "this should trigger user adding ignindex#create"
          User.find(current_user.id).update(
            :summoner_id => @ignindex.validation_timer)
        end

        redirect_to summoner_path
      end

    else
      #error?
    end

  end

  def update_region_id(ignindex, dirty_postal) #line 17 & 26 are creating when not required
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
        # self.update(region_id_temp: Region.where("postal_code = ?", postal_search).first.id)
      end
      Rails.logger.info "US_postal: #{postal_search}"
      Rails.logger.info "US_region: #{ignindex.region_id_temp}"
    elsif !/[a-zA-Z]/.match(postal_search[0]).nil? #this is a postal code
      if postal_search.length >= 3
        postal_search = postal_search[0..2].upcase
      end 
      if !Region.where("postal_code = ?", postal_search).first.nil?
        @ignindex.region_id_temp = Region.where("postal_code = ?", postal_search).first.id
        # self.update(region_id_temp: Region.where("postal_code = ?", postal_search).first.id)
      end
      Rails.logger.info "CA_postal: #{postal_search}"
      Rails.logger.info "CA_region: #{ignindex.region_id_temp}"
    else

      Rails.logger.info "alkatraz"
      #error entering postal code!
    end
    Rails.logger.info "#postal_search: #{postal_search}"
    # Rails.logger.info "region_id: #{Region.where("postal_code = ?", postal_search).first.id}"
    # self.update(
    #   :region_id => Region.where("postal_code = ?", self.postal_code).first.id)
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
