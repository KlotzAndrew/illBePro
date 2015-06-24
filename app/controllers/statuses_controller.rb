 class StatusesController < ApplicationController
  before_action :set_status, only: [:show, :edit, :update, :destroy]

  # before_filter :authenticate_user!

  respond_to :html, :xml, :json

  # GET /statuses
  # GET /statuses.json
  def index

    #checks what ignindex we are using (redirect )
    if user_signed_in? #filter users for signed in
      if Ignindex.find_by_user_id(current_user.id).nil?
        redirect_to summoner_path, notice: "You need to validate your Summoner Name!"
      else
        active_ign_id = Ignindex.find_by_user_id(current_user.id).id
        @ignindex = Ignindex.find_by_user_id(current_user.id)
      end
    else #not signed-in users
      if session[:ignindex_id].nil?
        redirect_to summoner_path, notice: "You need to validate your Summoner Name!"
      else
        active_ign_id = session[:ignindex_id]
        @ignindex = Ignindex.find(session[:ignindex_id])
      end
    end

    #this block checks if there is a status running, if not it redirects you
    if Status.where("win_value IS ?", nil).where("ignindex_id = ?", active_ign_id).count > 0
      @status = Status.where("win_value IS ?", nil).where("ignindex_id = ?", active_ign_id).first
      
      if ((Time.now.to_i - @status.created_at.to_i - @status.value) > -120)
        @update_trigger = "cg-update-true"
      else

        if @status.trigger_timer.nil?
          @update_trigger = ""
        else

          if ((Time.now.to_i - @status.trigger_timer) < 300)
            @update_trigger = "cg-update-true"
          else
            @update_trigger = ""
          end
        end
      end

    else
      # if Ignindex.find_by_user_id(current_user.id).nil?
      #   redirect_to summoner_path, notice: "You need to validate your Summoner Name!"
      # else
      #   redirect_to new_status_path
      # end
      # @status = Status.new(
      #   :ignindex_id => active_ign_id)
      redirect_to new_status_path
    end
    
    Rails.logger.info "prize display 1/3"
    if @ignindex != nil
      Rails.logger.info "prize display 2/3"
      if @ignindex.prize_id != nil
        prize = Prize.find(@ignindex.prize_id)
        @prize_description = prize.description
        @prize_vendor = prize.vendor
         Rails.logger.info "prize display 3/3"
      else
        show_prizes_2(@ignindex.region_id)
      end
    end
  end

  # GET /statuses/1
  # GET /statuses/1.json

  # GET /statuses/new

  def show
    if user_signed_in?
      respond_to do |format|
        format.html { render nothing: true}
        format.json { render json: Status.where("ignindex_id = ?", Ignindex.find_by_user_id(current_user.id).id).last }
      end    
    else
     respond_to do |format|
        format.html { render nothing: true}
        format.json { render json: Status.where("ignindex_id = ?", session[:ignindex_id]).last }
      end 
    end
  end

  def show_prizes_2(x) #prize region logic (duplicate in ignindeces/statuses controller)
    @all_prize_desc = []
    @all_prize_vendor = []

    region = Region.find(x)

    @region_city = region.city
    @region_country = region.country
        
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

  def new
    Rails.logger.info "User sign-in status: #{user_signed_in?}"
    if !user_signed_in? #unauthenticate partial sign-in

      if session[:ignindex_id].nil? 
        redirect_to setup_path

      elsif Ignindex.find(session[:ignindex_id]).last_validation != session[:last_validation]
        
        session[:setup_progress] = 0
        redirect_to setup_path, notice: "redirected you, summoner not validated"

      else

        if session[:last_game] > (Time.now.to_i - 90.minutes.ago.to_i)
          @status_setup_display = false
        else
          @status_setup_display = true
          @setup_progress = 4
        end
        last_game = Status.where("ignindex_id = ?", session[:ignindex_id]).last
        if last_game.nil?
          last_game_created = Time.now.to_i
        else
          last_game_created = last_game.created_at.to_i
        end
        
        current_ign = Ignindex.find(session[:ignindex_id])

        if current_ign.last_validation.nil? #this is getting set to nil somewhere???
          current_ign.update(
            :last_validation => 0)
        end

        if current_ign.last_validation < 90.minutes.ago.to_i && last_game_created < 90.minutes.ago.to_i
          current_ign.update(
            :last_validation => 0)
          session[:setup_progress] = 0
          redirect_to setup_path, notice: "Your validation timed out! Re-validate to keep playing."

        else

          get_current_achievement(session[:ignindex_id])
          #status object is new or existing?
          if Status.where("win_value IS ?", nil).where("ignindex_id = ?", session[:ignindex_id]).count > 0
            @status = Status.where("win_value IS ?", nil).where("ignindex_id = ?", session[:ignindex_id]).first
            
            if ((Time.now.to_i - @status.created_at.to_i - @status.value) > -120)
              
              @update_trigger = "cg-update-true"
            else

              if @status.trigger_timer.nil?
                @update_trigger = ""
              else

                if ((Time.now.to_i - @status.trigger_timer) < 300)
                  @update_trigger = "cg-update-true"
                else
                  @update_trigger = ""
                end
              end
            end
          else
            @status = Status.new(
              :ignindex_id => session[:ignindex_id])
          end

          #is a prize pending user accept? (can probably move to method)
          @ignindex = Ignindex.find(session[:ignindex_id])
           Rails.logger.info "prize display 1/3"
          if @ignindex.prize_id != nil
            prize = Prize.find(@ignindex.prize_id)
            @prize_description = prize.description
            @prize_vendor = prize.vendor
            Rails.logger.info "prize display 2/3"
          else 
           show_prizes_2(@ignindex.region_id)
          end

          @game_history = @achievement.statuses.order(created_at: :desc)

        end

      end
    else #user signed-in; this can be refractored
 
      if Ignindex.find_by_user_id(current_user.id).nil? #redirect
        redirect_to setup_path
        session[:setup_progress] = 0
      elsif Ignindex.find_by_user_id(current_user.id).region_id.nil? #redirect
        redirect_to zone_url, alert: 'You need a valid Postal Code!'
      else
        #setup progress?
        if current_user.setup_progress != 0
          @status_setup_display = false
        else
          @status_setup_display = true
          @setup_progress = 4
        end

        #does user have valid ignindex, get achievement
        if Ignindex.find_by_user_id(current_user.id).nil? #does user have ignindex
          redirect_to new_ignindex_path, notice: "Need to enter your summoner name before starting!"
        elsif Ignindex.find_by_user_id(current_user.id).summoner_validated != true #is the ignindex valid?
          redirect_to new_ignindex_path, notice: "redirected you, summoner not validated"
        else #looks good, grab the achievement
          get_current_achievement(Ignindex.find_by_user_id(current_user.id).id)
        end

        #sets @ignindex
        if user_signed_in?
          @ignindex = Ignindex.find_by_user_id(current_user.id)
        else
          @ignindex = Ignindex.find(session[:ignindex_id])
        end

        #status object is new or existing?
        if Status.where("win_value IS ?", nil).where("ignindex_id = ?", session[:ignindex_id]).count > 0
          @status = Status.where("win_value IS ?", nil).where("ignindex_id = ?", session[:ignindex_id]).first
          
          if ((Time.now.to_i - @status.created_at.to_i - @status.value) > -120)
            
            @update_trigger = "cg-update-true"
          else

            if @status.trigger_timer.nil?
              @update_trigger = ""
            else

              if ((Time.now.to_i - @status.trigger_timer) < 300)
                @update_trigger = "cg-update-true"
              else
                @update_trigger = ""
              end
            end
          end
        else
          @status = Status.new(
            :ignindex_id => session[:ignindex_id])
        end

       
        if @ignindex.prize_id != nil 
          prize = Prize.find(@ignindex.prize_id)
          @prize_description = prize.description
          @prize_vendor = prize.vendor 
        else 
         show_prizes_2(@ignindex.region_id)
        end

        #get game history
        @game_history = @achievement.statuses.order(created_at: :desc)

      end
 
    end
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

  def show_prizes(x)   
      #prize region logic
      region = Region.find(x)

      @region_city = region.city
      @region_country = region.country
          
      @all_prize_desc = []
      @all_prize_vendor = []
    
      region.prizes.each do |y|
        Rails.logger.info "id: #{y.id}, desc: #{y.description}, vendor: #{y.vendor}"
        @all_prize_desc << y.description
        @all_prize_vendor <<  y.vendor
      end
      Rails.logger.info "apd: #{@all_prize_desc}, apv: #{@all_prize_vendor}"
      Rails.logger.info "apd: #{@all_prize_desc.class}, apv: #{@all_prize_vendor.class}"
  end


  # POST /statuses
  # POST /statuses.json
  def create # does not take any params

    if user_signed_in?
      @ignindex = Ignindex.find_by_user_id(current_user.id)
    else
      @ignindex = Ignindex.find(session[:ignindex_id])
    end

    @status = Status.new(
      :achievement_id => @ignindex.active_achievement )

    @status.summoner_id = @ignindex.summoner_id
    @status.summoner_name = @ignindex.summoner_name
    @status.ignindex_id = @ignindex.id
    
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
    if @status.roll_status == 1 #UPDATE (using AJAX for calls, redirect making no sense)
      @status.update(roll_status: 1)
         respond_to do |format|
            format.html { redirect_to challenges_url, notice: 'Challenge getting started' }
            format.json { head :no_content }
            format.js { render :nothing => true}
          end      
    else

      if (Time.now.to_i - @status.created_at.to_i) < 1200 #DELETE (pause buttin is being removed)
        if @status.pause_timer == 0
          @status.update(pause_timer: Time.now.to_i)
          respond_to do |format|
            format.html { redirect_to challenges_url }
            format.json { head :no_content }
            format.js { render :nothing => true}
          end
        else 
          @status.update(value: (@status.value + Time.now.to_i - @status.pause_timer))
          @status.update(pause_timer: 0)
          respond_to do |format|
            format.html { redirect_to challenges_url }
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
       Rails.logger.info "destroy controller triggered, kind 6"
      @status.update(
        :value => 0,
        :win_value => 0)
      Prize.where(assignment: 1).where(user_id: current_user.id).last.update( {
        :assignment => 0,
        :user_id => 0,
        })
      # score = Score.find_by_user_id(current_user.id)
      # if score.challenge_points > 0
      #   score.update(challenge_points: score.challenge_points - 1) 
      # end
      respond_to do |format|
        format.html { redirect_to new_status_path }
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
        format.html { redirect_to new_status_path }
        format.json { head :no_content }
      end
    else
      Rails.logger.info "destroy controller triggered, type nil"
      @status.update(value: 0)
      @status.update(win_value: 3)      
      respond_to do |format|
        format.html { redirect_to new_status_path, alert: 'Something went wrong with your challenge kind' }
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