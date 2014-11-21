class ScoresController < ApplicationController
  before_action :set_score, only: [:show, :edit, :update, :destroy]

  def index
    @scores = Score.all
    @users = User.all
    @top_profiles = Score.all.where.not(user_id: nil).where("week_2 > ?", 0).order(week_2: :desc).limit(5)
    @top_summoners = Score.all.where.not(summoner_id: nil).where("week_2 > ?", 0).order(week_2: :desc).limit(5)
  end


  private
    def set_score
      @score = Score.find(params[:id])
    end

    def score_params
      params.require(:score).permit(:summoner_name, :week_1)
    end
end
