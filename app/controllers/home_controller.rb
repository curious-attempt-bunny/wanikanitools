class HomeController < ApplicationController
  def show
  end

  def ping
    render json: {ping:'pong'}
  end
end
