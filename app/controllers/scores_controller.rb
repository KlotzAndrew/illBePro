class ScoresController < ApplicationController
  before_action :authenticate_user!, only: [:update]
  before_action :set_score, only: [:update]

  def leaderboard
    cora_start = 1433781134
    @achievements = Score.open_achievments_since(cora_start)
    Rails.logger.info "@achievements: #{@achievements}"
  end

  def index
    @prize_description = nil
    if user_signed_in?
      set_ignindex_and_history
    end 
  end
  
  private

  def set_ignindex_and_history
    ignindex = current_user.ignindex
    if !ignindex.nil? && ignindex.summoner_validated == true
      @uu_summoner_validated = true
      @ignindex = ignindex
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
