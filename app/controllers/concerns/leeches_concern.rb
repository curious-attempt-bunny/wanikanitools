module LeechesConcern
    def leeches(options = Hash.new)
        review_statistics = options[:review_statistics] || fetch('/api/v2/review_statistics')
        assignments = convert_to_map_by_data_subject_id(options[:assignments] || fetch('/api/v2/assignments'))
        subjects = convert_to_map_by_id(options[:subjects] || fetch('/api/v2/subjects'))
    
        leeches = []

        review_statistics['data'].each do |item|
            review_data = item['data']
            next if review_data['subject_type'] == 'radical'
            next if review_data['meaning_incorrect'] + review_data['meaning_correct'] == 0
            next if assignments[review_data['subject_id']]['burned_at'].present?
            
            meaning_score = (review_data['meaning_incorrect'] / (review_data['meaning_current_streak'] || 0.5).to_f).round(1)
            reading_score = (review_data['reading_incorrect'] / (review_data['reading_current_streak'] || 0.5).to_f).round(1)
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

            leech = {
                subject_id: review_data['subject_id'],
                subject_type: review_data['subject_type'],
                name: subjects[review_data['subject_id']]['data']['character'] || subjects[review_data['subject_id']]['data']['characters'],
                srs_stage: assignments[review_data['subject_id']]['data']['srs_stage'],
                srs_stage_name: assignments[review_data['subject_id']]['data']['srs_stage_name'],
                worst_score: worst_score,
                worst_type: worst_type,
                worst_incorrect: worst_incorrect,
                worst_current_streak: worst_current_streak
            }

            leeches << leech if worst_score >= 0.5
        end

        leeches.sort_by! { |item| -item[:worst_score] }
        # leeches = leeches[0...50]

        leeches
    end
end