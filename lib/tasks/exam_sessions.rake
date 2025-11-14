namespace :exam_sessions do
  desc "Reset all exam session size counters based on actual registration count"
  task reset_counters: :environment do
    puts "Resetting exam session counters..."
    
    ExamSession.find_each do |session|
      old_size = session.size
      actual_count = session.registrations.count
      
      if old_size != actual_count
        session.update_column(:size, actual_count)
        puts "Session ##{session.id} (#{session.slug}): #{old_size} -> #{actual_count}"
      end
    end
    
    puts "Done! All counters have been reset."
  end
end
