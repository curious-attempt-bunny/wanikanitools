class LeechesController < ApplicationController
    include ApiConsumer
    include LeechesConcern

    def index
        @leeches = leeches

        respond_to do |format|
            format.html
            format.json { render json: @leeches}
        end  
    end
end