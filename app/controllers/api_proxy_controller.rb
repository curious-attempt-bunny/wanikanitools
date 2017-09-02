class ApiProxyController < ApplicationController
    include ApiConsumer

    def get
        json = fetch(request.path)

        render json: json
    end
end