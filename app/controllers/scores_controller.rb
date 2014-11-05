class ScoresController < ApplicationController
  before_action :set_score, only: [:show, :edit, :update, :destroy]

  def index
    @scores = Score.all
  end

  def show
  end

  def new
    @score = Score.new
  end

  def edit
  end

  def create
    @score = Score.new(score_params)
    @score.save
  end

  def update
    @score.update(score_params)
  end

  def destroy
    @score.destroy
  end

  private
    def set_score
      @score = Score.find(params[:id])
    end

    def score_params
      params.require(:score).permit(:summoner_name, :week_1)
    end
end
