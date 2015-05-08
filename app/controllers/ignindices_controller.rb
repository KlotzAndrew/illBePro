class IgnindicesController < ApplicationController
  before_action :set_ignindex, only: [:show, :edit, :update, :destroy]

  helper_method :show_prizes

  # before_filter :authenticate_user!

  respond_to :html, :xml, :json
  
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
  end

  def new # step 2
    if user_signed_in? && !Ignindex.find_by_user_id(current_user.id).nil?
      @ignindex = Ignindex.find_by_user_id(current_user.id)
      @setup_progress = 0

    else
      @setup_progress = 0

      session[:postal_code_temp] = nil
      session[:region_id_temp] = nil
      session[:summoner_name_temp] = nil
      session[:summoner_name_ref_temp] = nil
      session[:ignindex_id] = nil    
      session[:last_validation] = nil
      session[:last_game] = 0

      @ignindex = Ignindex.new
      @postal_code_s = session[:postal_code_temp]
      @region_id_s = session[:region_id_temp]
    end

  end

  def get_started # step 3
    @setup_progress = 1

    if session[:region_id_temp].blank?
      redirect_to new_ignindex_path
    else
      show_prizes(session[:region_id_temp])
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
    @setup_progress = 2

    if session[:region_id_temp].blank?
      redirect_to new_ignindex_path
    end    
  end

  def index #step 5
    @setup_progress = 3

    if user_signed_in? && !Ignindex.find_by_user_id(current_user.id).nil?
      using_ign = Ignindex.find_by_user_id(current_user.id)
    
      if using_ign.nil?
        session[:region_id_temp] ||= nil
        if session[:region_id_temp].blank?
          redirect_to new_ignindex_path
        end
      else
        #can existing ignindex have nil region id?
        session[:region_id_temp] ||= nil
        if session[:region_id_temp].blank?
          redirect_to new_ignindex_path
        end        
      end

      #new @ignindex or existing entry
      if !using_ign.nil? 
        @ignindex = using_ign
        session[:ignindex_id] = @ignindex.id
        #dont load in the full object -_-; fix me later
      else
        @ignindex = Ignindex.new(
          :region_id => session[:region_id_temp])
      end

      if using_ign.nil?
        @uu_summoner_validated = false
      elsif using_ign.summoner_validated != true
        @uu_summoner_validated = false
      else
        @uu_summoner_validated = true
      end

    else #user not signed in
      session[:region_id_temp] ||= nil
      if session[:region_id_temp].blank?
        redirect_to new_ignindex_path
      end

      #new @ignindex or existing entry
      if !session[:summoner_name_ref_temp].blank? && !Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first.nil?
        @ignindex = Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first
        session[:ignindex_id] = @ignindex.id
        #dont load in the full object -_-; fix me later
      else
        @ignindex = Ignindex.new(
          :region_id => session[:region_id_temp])
      end

      if (@ignindex.summoner_validated == true) && (@ignindex.last_validation == session[:last_validation])
        @uu_summoner_validated = true
      else
        @uu_summoner_validated = false
      end

    end #end of user in/out block

  end

  def update # used on step 2 and 4 (if using @ignindex.where("...").first.not.nil?)
    if params[:commit] == "Add Summoner Name" #this will never be triggered (add is now create only)
      @ignindex.update(ignindex_params)
      # flash[:notice] = "Updated summoner name!"
      @ignindex.refresh_summoner
      @ignindex.refresh_validation
    elsif params[:commit] == "Update Summoner Name" #triggered on 'update, with a different name'
 
      session[:summoner_name_temp] = params["ignindex"]["summoner_name"]
      session[:summoner_name_ref_temp] = params["ignindex"]["summoner_name"].mb_chars.downcase.gsub(' ', '')
 
      if !session[:summoner_name_ref_temp].blank? && !Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first.nil?
        @ignindex = Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first
        session[:ignindex_id] = @ignindex.id

        @ignindex.update(
          :region_id_temp => session[:region_id_temp])

        #dont load in the full object -_-; fix me later
      else

        @ignindex = Ignindex.new(
          :region_id => session[:region_id_temp],
          :region_id_temp => session[:region_id_temp],
          :summoner_name => session[:summoner_name_temp],
          :summoner_name_ref => session[:summoner_name_ref_temp])
        @ignindex.save
        session[:ignindex_id] = @ignindex.id
      end    

      @ignindex.refresh_validation
      session[:last_validation] = @ignindex.validation_timer
      if user_signed_in?
        User.find(current_user.id).update(
          :summoner_id => @ignindex.validation_timer)
        Ignindex.where("user_id = ?", 10).each do |x| 
          x.update(
            :user_id => nil)
        end
      end
    elsif params["commit"] == "Add Postal/Zip Code"
      @ignindex.update(
        :postal_code => ignindex_params[:postal_code])
      @ignindex.update_region_id(ignindex_params[:postal_code])

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
              format.html { redirect_to new_status_path, notice: 'Prize accepted' }
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

    else #params for 'new validation code'
      @ignindex.refresh_validation
      session[:last_validation] = @ignindex.validation_timer
    end
  end

  def create # runs on step 2 and 4 (if using @ignindex.new; runs on 'add' or 'update'

    if params["commit"] == "Add Postal/Zip Code" #no save action
      @postal_code_s = session[:postal_code_temp]
      @region_id_s = session[:region_id_temp]
      Rails.logger.info "params_psotal_code: #{ignindex_params[:postal_code]}"
      @ignindex = Ignindex.new(
        :postal_code => ignindex_params[:postal_code])
      @ignindex.postal_code = session[:postal_code]
      Rails.logger.info "self.postal_code: #{@ignindex.postal_code}"
      @ignindex.update_region_id(ignindex_params[:postal_code])
      
      session[:region_id_temp] = @ignindex.region_id_temp
      session[:postal_code_temp] = ignindex_params[:postal_code]
      if @ignindex.region_id_temp.nil?
        respond_to do |format|
          format.html { redirect_to new_ignindex_path, alert: 'Sorry! That zip/postal code does not match anything on our map' }
          format.json { head :no_content }
        end 
      else
        respond_to do |format|
          format.html { redirect_to get_started_path }
          format.json { head :no_content } 
        end 
      end
      # redirect_to get_started_path
    else # save action for ign

      if params["ignindex"]["summoner_name"].length < 1
        Rails.logger.info "name entered was nil"
        Rails.logger.info "params.legth: #{params["ignindex"]["summoner_name"].length}"
      else
      
        session[:summoner_name_temp] = params["ignindex"]["summoner_name"]
        session[:summoner_name_ref_temp] = params["ignindex"]["summoner_name"].mb_chars.downcase.gsub(' ', '')

        if !session[:summoner_name_ref_temp].blank? && !Ignindex.where("summoner_name_ref = ?", session[:summoner_name_ref_temp]).first.nil?
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
        @ignindex.refresh_validation
        session[:last_validation] = @ignindex.validation_timer

        if user_signed_in?
          User.find(current_user.id).update(
            :summoner_id => @ignindex.validation_timer)
        end

        redirect_to summoner_path
      end

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