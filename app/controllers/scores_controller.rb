class ScoresController < ApplicationController
  before_action :set_score, only: [:show, :edit, :update, :destroy]

  def index
    @scores = Score.all
    @users = User.all
    @ignindex = Ignindex.all
    @status = Status.all
    @top_profiles = Score.all.where.not(user_id: nil).where("week_5 > ?", 0).order(week_5: :desc)
    @top_summoners = Score.all.where.not(summoner_id: nil).where("week_5 > ?", 0).order(week_5: :desc)

    @top_profiles_last = Score.all.where.not(user_id: nil).where("week_4 > ?", 0).order(week_4: :desc).limit(5)
    @top_summoners_last = Score.all.where.not(summoner_id: nil).where("week_4 > ?", 0).order(week_4: :desc).limit(5)
  end


  private
    def set_score
      @score = Score.find(params[:id])
    end

    def score_params
      params.require(:score).permit(:summoner_name, :week_1, :week_2, :week_3, :week_4)
    end
end
