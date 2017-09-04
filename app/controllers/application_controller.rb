class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :current_user
  before_action :instrument

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def instrument
    NewRelic::Agent.add_custom_attributes({ api_key: params[:api_key] }) if params[:api_key]
  end
end