class ScoresController < ApplicationController
  before_action :set_score, only: [:show, :edit, :update, :destroy]

  def index
    @score = Score.find_by_user_id(current_user.id)
    @history = Prize.all.where("user_id = ?", current_user.id).where("assignment = ?", 2)
    if @score.prize_id != nil
      prize = Prize.find(@score.prize_id)
      @prize_description = prize.description
      @prize_vendor = prize.vendor
      @prize_vode = prize.code
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
      elsif params[:commit] == "Upgrade"
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
