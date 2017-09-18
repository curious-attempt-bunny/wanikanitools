class LeechesController < ApplicationController
    include ApiConsumer
    include LeechesConcern

    def index
        prefetched = prefetch([
            '/api/v2/subjects',
            '/api/v2/review_statistics',
            '/api/v2/assignments'
        ])

        @leeches = leeches(prefetched: prefetched)

        respond_to do |format|
            format.html
            format.json { render json: @leeches}
        end  
    end
end