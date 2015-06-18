class ScoresController < ApplicationController
  before_action :set_score, only: [:show, :edit, :update, :destroy]


  def scoreboard
    @achievements = []
    @ignindexes = []
    if user_signed_in?
      if current_user.email == "andrew.klotz@hotmail.com" or current_user.email == "aklotz@tangiblegameworks.com"
        cora_start = 1433781134
        @achievements = []
        Ignindex.all.includes(:achievements).where("updated_at > ?", Time.at(1433781134)).where.not("summoner_name IS ?", nil).where.not("active_achievement IS ?", nil).each do |x|
          an_ach = Achievement.find(x.active_achievement)
          number = an_ach.experience_earned/an_ach.experience_req.round(1) 
          progress = (number.round(2)*100).round(0)

          block = []
          block << x.ign_challenge_points
          block << x.summoner_name
          block << an_ach
          block << progress
          @achievements << block
          @achievements = @achievements.sort_by{|a,b,c,d| [a,d]}
        end
      end
    end
  end

  def index

    @prize_description = nil
    if user_signed_in?
      test_user = current_user.id
    else 
      test_user = Time.now.to_i
    end
    Rails.logger.info "TU(#{test_user}: getting started"
    
    if user_signed_in?
      Rails.logger.info "TU(#{test_user}: signed in"
      if !Ignindex.find_by_user_id(current_user.id).nil? #filter out nils, this needs fixing
        Rails.logger.info "TU(#{test_user}: user not nil"
        ignindex = Ignindex.find_by_user_id(current_user.id)
        Rails.logger.info "TU(#{test_user}: user #{ignindex.id}"
        if ignindex.summoner_validated == true
          @uu_summoner_validated = true
          Rails.logger.info "TU(#{test_user}: uu #{@uu_summoner_validated}"
          @history = Prize.all.where("ignindex_id = ?", ignindex.id).where("assignment = ?", 2).order(created_at: :desc)

          if ignindex.prize_id != nil #send me to a mehtod
            prize = Prize.find(ignindex.prize_id)
            @prize_description = prize.description
            @prize_vendor = prize.vendor
            @prize_code = prize.code
            @prize_reward_code = prize.reward_code
          end
        else
          @uu_summoner_validated = false
          Rails.logger.info "TU(#{test_user}: uu #{@uu_summoner_validated}"
        end   
      else
        Rails.logger.info "TU(#{test_user}: user nil"
      end
    elsif session[:ignindex_id] != nil
      Rails.logger.info "TU(#{test_user}: not signed in"
      ignindex = Ignindex.find(session[:ignindex_id])
      Rails.logger.info "TU(#{test_user}: user #{ignindex.id}"

      if (ignindex.summoner_validated == true) && (ignindex.last_validation == session[:last_validation])
        @uu_summoner_validated = true
        Rails.logger.info "TU(#{test_user}: uu #{@uu_summoner_validated}"
        @history = Prize.all.where("ignindex_id = ?", ignindex.id).where("assignment = ?", 2).order(created_at: :desc)

        if ignindex.prize_id != nil #send me to a mehtod
          prize = Prize.find(ignindex.prize_id)
          @prize_description = prize.description
          @prize_vendor = prize.vendor
          @prize_code = prize.code
          @prize_reward_code = prize.reward_code
        end
      else
        @uu_summoner_validated = false
        Rails.logger.info "TU(#{test_user}: uu #{@uu_summoner_validated}"
      end      
    else
      #nothing here
    end#this should really be in prizes... you got your controllers confused.
  end

  def update
    if @score.prize_id != nil
      @score.assign_prize(params[:commit])
      if params[:commit] == "Accept"
        respond_to do |format|
          format.html { redirect_to scores_url, notice: 'Prize accepted' }
          format.json { head :no_content }
        end
      elsif params[:commit] == "Keep Playing"
        respond_to do |format|
          format.html { redirect_to statuses_url, notice: 'Prize traded in, your chance to proc a prize is unchanged' }
          format.json { head :no_content }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to scores_url, notice: 'There is an issue with your prize :(' }
        format.json { head :no_content }
      end
    end#this is prize logic, not score stuff wth bro
  end

  def show
  end

  private
    def set_score
      @score = Score.find(params[:id])
    end

    def score_params
      params.require(:score).permit()
    end
end
