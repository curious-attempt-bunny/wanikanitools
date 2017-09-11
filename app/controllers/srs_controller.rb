class SrsController < ApplicationController
    include ApiConsumer

    def status
        json = fetch('/api/v2/assignments')

        srs_level_totals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        
        json['data'].each do |item|
            srs_level_totals[item['data']['srs_stage']] += 1
        end

        status = {
            srs_level_totals: srs_level_totals,
            levels: {
                unstarted: {
                    srs_level_totals: srs_level_totals[0...1],
                    total: srs_level_totals[0]
                },
                apprentice: {
                    srs_level_totals: srs_level_totals[1...5],
                    total: srs_level_totals[1] + srs_level_totals[2] + srs_level_totals[3] + srs_level_totals[4]
                },
                guru: {
                    srs_level_totals: srs_level_totals[5...7],
                    total: srs_level_totals[5] + srs_level_totals[6]
                },
                master: {
                    srs_level_totals: srs_level_totals[7...8],
                    total: srs_level_totals[7]  
                },
                enlightened: {
                    srs_level_totals: srs_level_totals[8...9],
                    total: srs_level_totals[8]  
                },
                burned: {
                    srs_level_totals: srs_level_totals[9...10],
                    total: srs_level_totals[9]  
                },
                order: ['apprentice', 'guru', 'master', 'enlightened', 'burned']
            }
        }

        render json: status
    end
end