class ReviewDataController < ApplicationController
    include ApiConsumer

    @@subjects = Hash.new

    def merged
        json = fetch('/api/v2/review_statistics')
    
        filename = filename_for('', '/api/v2/subjects')
        if @@subjects.empty? && File.exists?(filename)
            puts 'Building subjects hash'
            subjects_json = JSON.parse(File.read(filename))
            subjects_json['data'].each do |v|
                @@subjects[v['id']] = v
            end
        end

        json['data'].each do |v|
            # puts v.inspect
            subject_id = v['data']['subject_id']
            # puts subject_id
            if @@subjects.include?(subject_id)
                v['data']['subject'] = @@subjects[subject_id]
            end
        end

        render json: json
    end
end