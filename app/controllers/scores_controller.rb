class ScoresController < ApplicationController
  before_action :set_score, only: [:show, :edit, :update, :destroy]


  def index

    @prize_description = nil
    
    if session[:ignindex_id] != nil
      ignindex = Ignindex.find(session[:ignindex_id])

      if (ignindex.summoner_validated == true) && (ignindex.last_validation == session[:last_validation])
        @uu_summoner_validated = true
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
      end      
    else
      #nothing here
    end

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
    end

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
