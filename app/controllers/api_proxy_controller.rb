class ApiProxyController < ApplicationController
    include ApiConsumer

    def get
        json = fetch(request.path)

        render json: json
    end

    def get_filtered
        raise request.path

        json = fetch(request.path)        
    end
end