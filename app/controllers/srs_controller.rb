require 'new_relic/agent/method_tracer'
require 'thread'

class SrsController < ApplicationController
    def status
        id_maps = collect([
            '/api/v2/subjects',
            '/api/v2/review_statistics',
            '/api/v2/assignments'
        ])
        leeches = leeches(id_maps).select { |item| item[:worst_score] > 0.5 }

        srs_level_totals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        leech_totals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

        id_maps['/api/v2/assignments'].each do |id, item|
            srs_level_totals[item['data']['srs_stage']] += 1
        end

        leeches.each do |item|
            leech_totals[item[:srs_stage]] += 1
        end

        status = {
            leeches_total: leeches.size,
            srs_level_totals: srs_level_totals,
            srs_level_leeches_totals: leech_totals,
            levels: {
                unstarted: {
                    srs_level_totals: srs_level_totals[0...1],
                    total: srs_level_totals[0],
                    srs_level_leeches_totals: leech_totals[0...1],
                    leeches_total: leech_totals[0]
                },
                apprentice: {
                    srs_level_totals: srs_level_totals[1...5],
                    total: srs_level_totals[1] + srs_level_totals[2] + srs_level_totals[3] + srs_level_totals[4],
                    srs_level_leeches_totals: leech_totals[1...5],
                    leeches_total: leech_totals[1] + leech_totals[2] + leech_totals[3] + leech_totals[4]
                },
                guru: {
                    srs_level_totals: srs_level_totals[5...7],
                    total: srs_level_totals[5] + srs_level_totals[6],
                    srs_level_leeches_totals: leech_totals[5...7],
                    leeches_total: leech_totals[5] + leech_totals[6]
                },
                master: {
                    srs_level_totals: srs_level_totals[7...8],
                    total: srs_level_totals[7],  
                    srs_level_leeches_totals: leech_totals[7...8],
                    leeches_total: leech_totals[7]  
                },
                enlightened: {
                    srs_level_totals: srs_level_totals[8...9],
                    total: srs_level_totals[8],
                    srs_level_leeches_totals: leech_totals[8...9],
                    leeches_total: leech_totals[8]  
                },
                burned: {
                    srs_level_totals: srs_level_totals[9...10],
                    leeches_total: srs_level_totals[9],
                    srs_level_leeches_totals: [0],
                    leeches_total: 0
                },
                order: ['apprentice', 'guru', 'master', 'enlightened', 'burned']
            }
        }

        render json: status
    end

    def leeches(jsons)
        review_statistics = jsons['/api/v2/review_statistics']
        assignments = jsons['/api/v2/assignments']
        subjects = jsons['/api/v2/subjects']
    
        leeches = []

        review_statistics.values.each do |item|
            review_data = item['data']
            next if review_data['subject_type'] == 'radical'
            next if review_data['meaning_incorrect'] + review_data['meaning_correct'] == 0
            assignment = assignments[review_data['subject_id']]
            next unless assignment.present?
            next if assignment['data']['burned_at'].present?
            next if assignment['data']['passed'] == false
            
            meaning_score = (review_data['meaning_incorrect'] / ((review_data['meaning_current_streak'] || 0.5)**1.5)).round(1)
            reading_score = (review_data['reading_incorrect'] / ((review_data['reading_current_streak'] || 0.5)**1.5)).round(1)
            raise item.inspect if reading_score.nan?
            worst_score = meaning_score
            worst_type = 'meaning'
            worst_incorrect = review_data['meaning_incorrect']
            worst_current_streak = review_data['meaning_current_streak']
            if !reading_score.nan? && reading_score > meaning_score
                worst_score = reading_score 
                worst_type = 'reading'
                worst_incorrect = review_data['reading_incorrect']
                worst_current_streak = review_data['reading_current_streak']
            end

            primary_reading = nil
            if subjects[review_data['subject_id']]['data']['readings']
                primary_reading = subjects[review_data['subject_id']]['data']['readings'].find { |reading| reading['primary'] }['reading']
            end
            primary_meaning = nil
            if subjects[review_data['subject_id']]['data']['meanings']
                primary_meaning = subjects[review_data['subject_id']]['data']['meanings'].find { |meaning| meaning['primary'] }['meaning']
            end

            leech = {
                subject_id: review_data['subject_id'],
                subject_type: review_data['subject_type'],
                name: subjects[review_data['subject_id']]['data']['character'] || subjects[review_data['subject_id']]['data']['characters'],
                srs_stage: assignment['data']['srs_stage'],
                srs_stage_name: assignment['data']['srs_stage_name'],
                worst_score: worst_score,
                worst_type: worst_type,
                worst_incorrect: worst_incorrect,
                worst_current_streak: worst_current_streak,
                primary_meaning: primary_meaning
            }
            if (primary_reading)
                leech[:primary_reading] = primary_reading
            end

            leeches << leech if worst_score >= 1.0
        end

        leeches.sort_by! { |item| -item[:worst_score] }
        # leeches = leeches[0...50]

        leeches
    end

    def convert_to_map_by_id(json)
        map = Hash.new

        json['data'].each do |item|
            map[item['id']] = item
        end

        map
    end

    def convert_to_map_by_data_subject_id(json)
        map = Hash.new

        json['data'].each do |item|
            map[item['data']['subject_id']] = item
        end

        map
    end

    def filename_for(api_key, path)
        prefix = "#{api_key}_"
        prefix = '' if path == '/api/v2/subjects'        
        stem = ENV['CACHE_PATH'] || 'data'
        "#{stem}/#{prefix}#{path.gsub('/', '_')}" 
    end

    def api_key
        api_key = params[:api_key] || ENV['WANIKANI_V2_API_KEY']
    end    

    def collect(paths)
        hydra = Typhoeus::Hydra.hydra
        id_maps = {}
        paths.each do |path|
            filename = filename_for(api_key, path)
            
            if path == '/api/v2/subjects' && !File.exists?(filename)
                `cp data/#{path.gsub('/', '_')} #{filename}`
            end

            page_number = 1
            result = nil
            id_map = Hash.new
            id_maps[path] = id_map
            updated_after = nil
            puts "#{filename} exists? #{File.exists?(filename)}"
            if File.exists?(filename)
                begin
                    result = JSON.parse(File.read(filename))

                    result['data'].each do |item|
                        id_map[item['data'].has_key?('subject_id') ? item['data']['subject_id'] : item['id']] = item
                    end

                    updated_after = result['data_updated_at'] if result['object'] == 'collection'
                rescue JSON::ParserError => e
                    puts e.message
                end
            else
                # puts "Cache miss"
            end

            url = "https://www.wanikani.com#{path}#{updated_after ? "?updated_after=#{updated_after}" : ''}"

            request = Typhoeus::Request.new(
                url,
                method: :get,
                headers: { Authorization: "Token token=#{api_key}" }
            )
            on_complete_callback = nil
            on_complete_callback = Proc.new do |response|
                # puts "Complete -- #{url} with content length #{response.body.size} ??"
                raise "Non-200 response code for #{url}" if response.code != 200
                json = JSON.parse(response.body)
                puts "#{page_number}/#{json['pages']['last']} for #{path} (#{url})"
                if result.nil?
                    result = json
                    result['data'].each do |item|
                        id_map[item['data'].has_key?('subject_id') ? item['data']['subject_id'] : item['id']] = item
                    end
                else
                    json['data'].each do |item|
                        id_map[item['data'].has_key?('subject_id') ? item['data']['subject_id'] : item['id']] = item
                    end
                end
                if page_number == 1
                    result['data_updated_at'] = json['data_updated_at']
                end
                if page_number < json['pages']['last'].to_i
                    page_number += 1
                    url = "https://www.wanikani.com#{path}?page=#{page_number}#{updated_after ? "&updated_after=#{updated_after}" : ''}"

                    request = Typhoeus::Request.new(
                        url,
                        method: :get,
                        headers: { Authorization: "Token token=#{api_key}" }
                    )
                    request.on_complete do |response|
                        on_complete_callback.call(response)
                    end
                    hydra.queue(request)
                else
                    puts "Done: #{path}"
                    result['data'] = id_map.values
                    File.write(filename, JSON.generate(result))
                end
            end
            request.on_complete do |response|
                on_complete_callback.call(response)
            end
            hydra.queue(request)
        end

        start_time = Time.now
        hydra.run
        end_time = Time.now
        puts "Hydra.run time: #{(end_time - start_time)*1000}"

        # raise id_maps.to_a.map { |i| [i[0], i[1].size] }.inspect
        id_maps
    end

    add_method_tracer :collect
    add_method_tracer :leeches
    add_method_tracer :convert_to_map_by_id
    add_method_tracer :convert_to_map_by_data_subject_id    
end