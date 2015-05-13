module Loyalty
  class ApplicationController < ActionController::Base
    before_filter :base_authentication

    private

    def base_authentication
      return if params[:controller] =~ /loyalty\/api\//
      authenticate_or_request_with_http_basic("Welcome!") do |username, password|
        username == 'farmaimpex' && password == 'dfgcvbdfg'
      end
    end
  end
end
