class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :current_user
  before_action :instrument
  before_action :enable_cors

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def instrument
    NewRelic::Agent.add_custom_attributes({ api_key: params[:api_key] }) if params[:api_key]
  end

  def enable_cors
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end
end