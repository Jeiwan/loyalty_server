module Loyalty
  class GiftsController < ApplicationController
    skip_authorization_here
    before_action :set_gift

    def index
    end

    def edit
    end

    def update
      @gift = Gift.find(params[:id])
      if @gift.update(params[:gift])
        redirect_to gifts_path
      else
        render :edit
      end
    end

    private

    def set_gift
      @gift = Gift.preload(gift_positions: :product).first
    end
  end
end
