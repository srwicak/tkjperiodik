# lib/tasks/cleanup.rake
require "csv"

namespace :db do
  desc "Clean duplicate registrations (safely) with dry-run and CSV log"
  task cleanup_duplicate_registrations: :environment do
    DRY_RUN = ENV["DRY_RUN"] != "false" # default: dry-run ON
    LOG_PATH = Rails.root.join("log/registration_cleanup_log.csv")
    total_removed = 0
    total_skipped = 0

    puts "🧼 [Start] Cleaning duplicate registrations..."
    puts "📄 Logging to: #{LOG_PATH}"
    puts "🧪 Dry-run mode: #{DRY_RUN ? 'ON (no deletions)' : 'OFF (will delete)'}"

    CSV.open(LOG_PATH, "w") do |csv|
      csv << ["deleted_registration_id", "user_id", "exam_session_id", "has_score", "kept_id"]

      Registration
        .select(:user_id, :exam_session_id)
        .group(:user_id, :exam_session_id)
        .having("COUNT(*) > 1")
        .each do |dup|
          regs = Registration
            .where(user_id: dup.user_id, exam_session_id: dup.exam_session_id)
            .includes(:score)

          with_score = regs.select { |r| r.score.present? }
          keep = with_score.first || regs.first

          regs.each do |r|
            if r == keep
              total_skipped += 1
              next
            end

            csv << [r.id, r.user_id, r.exam_session_id, r.score.present?, keep.id]
            puts "🗑️  #{DRY_RUN ? '[DRY-RUN]' : '[DELETE]'} Registration ##{r.id} (user=#{r.user_id}, session=#{r.exam_session_id})"

            unless DRY_RUN
              r.destroy!
              total_removed += 1
            end
          end
        end
    end

    puts "✅ [Done]"
    puts "💾 Log saved to: #{LOG_PATH}"
    puts "🗂️ Total kept: #{total_skipped}, total removed: #{total_removed}"
  end
end
