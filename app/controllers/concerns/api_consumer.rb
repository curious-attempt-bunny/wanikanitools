module ApiConsumer
    def filename_for(api_key, path)
        prefix = "#{api_key}_"
        prefix = '' if path == '/api/v2/subjects'        
        stem = ENV['CACHE_PATH'] || 'data'
        "#{stem}/#{prefix}#{path.gsub('/', '_')}" 
    end

    def api_key
        api_key = params[:api_key] || ENV['WANIKANI_V2_API_KEY']
    end    

    def http_get(url, path, prefetched={})
        # puts ">>> prefetched.keys = #{prefetched.keys}"
        if prefetched.has_key?(url)
            NewRelic::Agent.add_custom_attributes({"prefetch/#{url}": 1})
            puts "*** PREFETCHED #{path} ***"
            return prefetched[url]
        else
            NewRelic::Agent.add_custom_attributes({"prefetch/#{url}": 0})
        end

        cmd = "curl -H 'Authorization: Token token=#{api_key}' '#{url}'"
        puts ">>> #{cmd}"
        
        Typhoeus::Config.user_agent = 'Wanikanitools/alpha (https://github.com/curious-attempt-bunny/wanikanitools/issues)'
        typhoeus_response = Typhoeus.get(url, headers: { Authorization: "Token token=#{api_key}" })
        raise typhoeus_response.code.to_s if typhoeus_response.code != 200

        typhoeus_response.body
    end

    def prefetch(paths)
        hydra = Typhoeus::Hydra.hydra
        
        cache = {}
        paths.each do |path|
            # TODO DRY
            filename = filename_for(api_key, path)
            
            if path == '/api/v2/subjects' && !File.exists?(filename)
                `cp data/#{path.gsub('/', '_')} #{filename}`
            end

            result = nil
            data = []
            updated_after = nil
            # puts "filename: #{filename}"
            if File.exists?(filename)
                # puts "Cache hit ?"
                begin
                    result = JSON.parse(File.read(filename))
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
            hydra.queue(request)
            cache[url] = request
        end

        hydra.run

        cache.keys.each do |url|
            response = cache[url].response
            NewRelic::Agent.add_custom_attributes({"prefetch_status_code/#{URI(url).path}": response.code})
            raise response.code.to_s if response.code != 200
            cache[url] = response.body
        end

        cache
    end

    def fetch(path, prefetched = {})
        filename = filename_for(api_key, path)

        if path == '/api/v2/subjects' && !File.exists?(filename)
            `cp data/#{path.gsub('/', '_')} #{filename}`
        end

        result = nil
        data = []
        updated_after = nil
        if File.exists?(filename)
            NewRelic::Agent.add_custom_attributes({"cache_hit/#{path}": 1})
            puts "Cache hit ?"
            begin
                result = JSON.parse(File.read(filename))
                updated_after = result['data_updated_at'] if result['object'] == 'collection'
                NewRelic::Agent.add_custom_attributes({"json_valid/#{path}": 1})
            rescue JSON::ParserError => e
                puts e.message
                NewRelic::Agent.add_custom_attributes({"json_valid/#{path}": 0})
            end
        else
            NewRelic::Agent.add_custom_attributes({"cache_hit/#{path}": 0})
            puts "Cache miss"
        end

        url = "https://www.wanikani.com#{path}#{updated_after ? "?updated_after=#{updated_after}" : ''}"
        
        response = http_get(url, path, prefetched)
        # puts response
        # File.write('/tmp/response.json', response)
        # exit(0)
        # puts response
        json = JSON.parse(response)

        if result && result['object'] == 'collection'
            result['data_updated_at'] = json['data_updated_at']
            puts "data_updated_at is #{json['data_updated_at']} vs #{updated_after} -- #{updated_after == result['data_updated_at'] ? 'same' : 'different'}"
            data.concat(json['data'])
        else    
            result = json
        end
    
        if json['pages']
            NewRelic::Agent.add_custom_attributes({"pages/#{path}": json['pages']['last'].to_i})
        
            if json['pages']['current'].to_i < json['pages']['last'].to_i
                ((json['pages']['current'].to_i+1)..json['pages']['last'].to_i).each do |page|
                    params = CGI::parse(URI(json['pages']['next_url']).query)
                    params['page'][0] = page
                    # print "Adjusted #{url} to "
                    url = URI(url).tap { |uri| uri.query = URI.encode_www_form(params) }.to_s
                    # puts url

                    cmd = "curl -H 'Authorization: Token token=#{api_key}' '#{url}'" # FIXME insecure
                    puts ">>> #{cmd}"
                    response = http_get(url, path, prefetched)
                    
                    json = JSON.parse(response)

                    if result && result['object'] == 'collection'
                        result['data_updated_at'] = json['data_updated_at']
                        puts "data_updated_at is #{json['data_updated_at']} vs #{updated_after} -- #{updated_after == result['data_updated_at'] ? 'same' : 'different'}"
                        data.concat(json['data'])
                    else    
                        result = json
                    end
                end
            end
        end

        if !File.exists?(filename) || updated_after != result['data_updated_at']
            NewRelic::Agent.add_custom_attributes({"cache_update/#{path}": 1})

            puts "Updating cache"

            if result['object'] == 'collection'
                map = Hash.new
                result['data'].each do |item|
                    map[item['id']] = item
                end
                puts "Original: #{result['data'].size} (#{map.size})"
                data.each do |item|
                    map[item['id']] = item
                end
                result['data'] = map.values
                puts "Replaced/new: #{data.size} (#{map.size})"
            end
            
            File.write(filename, JSON.generate(result))
        else
            NewRelic::Agent.add_custom_attributes({"cache_update/#{path}": 0})
            puts "No update to cache"
        end

        return result
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

end