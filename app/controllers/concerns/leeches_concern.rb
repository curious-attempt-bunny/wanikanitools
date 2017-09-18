module LeechesConcern
    def leeches(options = {prefetched: {}})
        review_statistics = options[:review_statistics] || fetch('/api/v2/review_statistics', options[:prefetched])
        assignments = convert_to_map_by_data_subject_id(options[:assignments] || fetch('/api/v2/assignments', options[:prefetched]))
        subjects = convert_to_map_by_id(options[:subjects] || fetch('/api/v2/subjects', options[:prefetched]))
    
        leeches = []

        review_statistics['data'].each do |item|
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
end