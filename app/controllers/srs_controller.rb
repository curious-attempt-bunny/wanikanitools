class SrsController < ApplicationController
    def status
        status = {
            srs_level_counts: [1, 2, 4, 8, 16, 32]
        }

        render json: status
    end
end