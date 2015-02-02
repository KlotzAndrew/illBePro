class PrizesController < ApplicationController
  before_action :set_prize, only: [:show, :edit, :update, :destroy]
  respond_to :html, :xml, :json

  def index
    @prizes = Prize.all
    respond_with(@prizes)
  end

  private
    def set_prize
      @prize = Prize.find(params[:id])
    end

    def prize_params
      params[:prize]
    end
end
