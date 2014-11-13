class ScoresController < ApplicationController
  before_action :set_score, only: [:show, :edit, :update, :destroy]

  def index
    @scores = Score.all
  end


  private
    def set_score
      @score = Score.find(params[:id])
    end

    def score_params
      params.require(:score).permit(:summoner_name, :week_1)
    end
end
