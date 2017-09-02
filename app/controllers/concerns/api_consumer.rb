module ApiConsumer
    def filename_for(api_key, path)
        prefix = "#{api_key}_"
        prefix = '' if path == '/api/v2/subjects'        
        "data/#{prefix}#{path.gsub('/', '_')}" # FIXME insecure
    end

    def fetch(path)
        api_key = params[:api_key] || ENV['WANIKANI_V2_API_KEY']
        filename = filename_for(api_key, path)

        result = nil
        is_result_cached = false
        if File.exists?(filename)
            puts "Cache hit ?"
            result = JSON.parse(File.read(filename))
            is_result_cached = true
        else
            puts "Cache miss"
        end

        url = "https://www.wanikani.com#{path}"
        while url
            cmd = "curl -H 'Authorization: Token token=#{api_key}' '#{url}'" # FIXME insecure
            response = `#{cmd}`
            json = JSON.parse(response)

            if is_result_cached
                if result['data_updated_at'] != json['data_updated_at']
                    result = nil
                    is_result_cached = false
                    puts "Cache invalidated"
                else
                    puts "Cache validated"
                    break
                end
            end

            if result
                result['data'] += json['data']
            else
                result = json
            end

            url = nil
            if json['pages'] && json['pages']['next_url']
                url = json['pages']['next_url']
            end
        end

        unless is_result_cached
            data_updated_at = DateTime.strptime(result['data_updated_at'], '%Y-%m-%dT%H:%M:%S%z')
            time = Time.parse(data_updated_at.to_s)
            File.write(filename, JSON.generate(result))
            File.utime(time, time, filename)
        end

        return result
    end
end