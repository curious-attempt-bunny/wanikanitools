class HomeController < ApplicationController
  def show
  end

  def ping
    render json: 'pong!'
  end
end
