class SrsController < ApplicationController
    include ApiConsumer
    include LeechesConcern

    def status
        json = fetch('/api/v2/assignments')
        leeches = leeches({assignments: json}).select { |item| item[:worst_score] > 0.5 }

        srs_level_totals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        leech_totals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

        json['data'].each do |item|
            srs_level_totals[item['data']['srs_stage']] += 1
        end

        leeches.each do |item|
            leech_totals[item[:srs_stage]] += 1
        end

        status = {
            srs_level_totals: srs_level_totals,
            srs_level_leeches_totals: leech_totals,
            levels: {
                unstarted: {
                    srs_level_totals: srs_level_totals[0...1],
                    total: srs_level_totals[0],
                    srs_level_leeches_total: leech_totals[0...1],
                    leeches_total: leech_totals[0]
                },
                apprentice: {
                    srs_level_totals: srs_level_totals[1...5],
                    total: srs_level_totals[1] + srs_level_totals[2] + srs_level_totals[3] + srs_level_totals[4],
                    srs_level_leeches_total: leech_totals[1...5],
                    leeches_total: leech_totals[1] + leech_totals[2] + leech_totals[3] + leech_totals[4]
                },
                guru: {
                    srs_level_totals: srs_level_totals[5...7],
                    total: srs_level_totals[5] + srs_level_totals[6],
                    srs_level_leeches_total: leech_totals[5...7],
                    leeches_total: leech_totals[5] + leech_totals[6]
                },
                master: {
                    srs_level_totals: srs_level_totals[7...8],
                    total: srs_level_totals[7],  
                    srs_level_leeches_total: leech_totals[7...8],
                    leeches_total: leech_totals[7]  
                },
                enlightened: {
                    srs_level_totals: srs_level_totals[8...9],
                    total: srs_level_totals[8],
                    srs_level_leeches_total: leech_totals[8...9],
                    leeches_total: leech_totals[8]  
                },
                burned: {
                    srs_level_totals: srs_level_totals[9...10],
                    leeches_total: srs_level_totals[9],
                    srs_level_leeches_total: 0,
                    leeches_total: 0
                },
                order: ['apprentice', 'guru', 'master', 'enlightened', 'burned']
            }
        }

        render json: status
    end
end