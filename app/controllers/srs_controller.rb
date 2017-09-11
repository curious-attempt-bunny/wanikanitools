class SrsController < ApplicationController
    def status
        srs_level_totals = [1, 2, 4, 8, 16, 32]
        status = {
            srs_level_totals: srs_level_totals,
            levels: {
                apprentice: {
                    srs_level_totals: srs_level_totals[0...4],
                    total: srs_level_totals[0] + srs_level_totals[1] + srs_level_totals[2] + srs_level_totals[3]
                },
                guru: {
                    srs_level_totals: srs_level_totals[4...6],
                    total: srs_level_totals[4] + srs_level_totals[5]
                }
            }
        }

        render json: status
    end
end