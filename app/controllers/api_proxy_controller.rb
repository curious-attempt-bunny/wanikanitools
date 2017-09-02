class ApiProxyController < ActionController::Base
    @@subjects = Hash.new

    def get
        json = fetch(request.path)

        if request.path == '/api/v2/review_statistics'
            filename = filename_for('', '/api/v2/subjects')
            if @@subjects.empty? && File.exists?(filename)
                puts 'Building subjects hash'
                subjects_json = JSON.parse(File.read(filename))
                subjects_json['data'].each do |v|
                    @@subjects[v['id']] = v
                end
            end

            json['data'].each do |v|
                puts v.inspect
                subject_id = v['data']['subject_id']
                puts subject_id
                if @@subjects.include?(subject_id)
                    v['data']['subject'] = @@subjects[subject_id]
                end
            end
        end

        # render json: cmd
        render json: json
    end

    private

    def filename_for(api_key, path)
        prefix = "#{api_key}_"
        prefix = '' if path == '/api/v2/subjects'        
        "data/#{prefix}#{path.gsub('/', '_')}" # FIXME insecure
    end

    def fetch(path)
        api_key = params[:api_key] || ENV['WANIKANI_V2_API_KEY']
        filename = filename_for(api_key, path)

        if File.exists?(filename)
            puts "Cache hit"
            return JSON.parse(File.read(filename))
        else
            puts "Cache miss"
        end

        result = nil

        url = "https://www.wanikani.com#{path}"
        while url
            cmd = "curl -H 'Authorization: Token token=#{api_key}' '#{url}'" # FIXME insecure
            response = `#{cmd}`
            json = JSON.parse(response)

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

        data_updated_at = DateTime.strptime(result['data_updated_at'], '%Y-%m-%dT%H:%M:%S%z')
        time = Time.parse(data_updated_at.to_s)
        File.write(filename, JSON.generate(result))
        File.utime(time, time, filename)

        return result
    end
end