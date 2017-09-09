module ApiConsumer
    def filename_for(api_key, path)
        prefix = "#{api_key}_"
        prefix = '' if path == '/api/v2/subjects'        
        stem = ENV['CACHE_DIR'] || 'data'
        "#{stem}/#{prefix}#{path.gsub('/', '_')}" 
    end

    def api_key
        api_key = params[:api_key] || ENV['WANIKANI_V2_API_KEY']
    end    

    def fetch(path)
        filename = filename_for(api_key, path)

        result = nil
        data = []
        updated_after = nil
        if File.exists?(filename)
            puts "Cache hit ?"
            result = JSON.parse(File.read(filename))
            updated_after = result['data_updated_at'] if result['object'] == 'collection'
        else
            puts "Cache miss"
        end

        url = "https://www.wanikani.com#{path}#{updated_after ? "?updated_after=#{updated_after}" : ''}"
        while url
            cmd = "curl -H 'Authorization: Token token=#{api_key}' '#{url}'" # FIXME insecure
            puts ">>> #{cmd}"
            response = `#{cmd}`
            json = JSON.parse(response)

            if result && result['object'] == 'collection'
                result['data_updated_at'] = json['data_updated_at']
                puts "data_updated_at is #{json['data_updated_at']} vs #{updated_after} -- #{updated_after == result['data_updated_at'] ? 'same' : 'different'}"
                data.concat(json['data'])
            else    
                result = json
            end
            
            url = nil
            if json['pages'] && json['pages']['next_url']
                url = json['pages']['next_url']
            end
        end

        if !File.exists?(filename) || updated_after != result['data_updated_at']
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
            
            data_updated_at = DateTime.strptime(result['data_updated_at'], '%Y-%m-%dT%H:%M:%S%z')
            time = Time.parse(data_updated_at.to_s)
            File.write(filename, JSON.generate(result))
            File.utime(time, time, filename)
        else
            puts "No update to cache"
        end

        return result
    end
end