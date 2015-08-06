class ScoresController < ApplicationController
  before_action :set_score, only: [:update]

  def leaderboard
    cora_start = 1433781134
    @achievements = Score.open_achievments_since(cora_start)
  end

  def index
    @prize_description = nil
    
    if user_signed_in?
      set_ignindex_and_history
    end 

  end

  def update
    if @score.prize_id != nil
      @score.assign_prize(params[:commit])
      if params[:commit] == "Accept"
        respond_to do |format|
          format.html { redirect_to scores_path, notice: 'Prize accepted' }
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

  private

  def set_ignindex_and_history
    ignindex = current_user.ignindex
    if !ignindex.nil? && ignindex.summoner_validated == true
      @ignindex = ignindex
      @uu_summoner_validated = true
      @history = Prize.all.where("ignindex_id = ?", ignindex.id).where("assignment = ?", 2).order(created_at: :desc)

      @prize = Prize.show_current_prize(ignindex)
    end
  end

    def set_score
      @score = Score.find(params[:id])
    end

    def score_params
      params.require(:score).permit()
    end
end
