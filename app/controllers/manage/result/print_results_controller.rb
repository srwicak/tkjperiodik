class Manage::Result::PrintResultsController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }

  def index
  end

  def data
    identity = params[:identity]
    
    # Validate identity format (8 digit NRP or 18 digit NIP)
    unless [8, 18].include?(identity&.length)
      render json: { success: false, message: 'Identitas harus 8 digit (NRP) atau 18 digit (NIP).' }
      return
    end

    user = User.find_by(identity: identity)

    if user
      # Get registrations with completed result reports
      registrations = Registration.includes(exam_session: :exam, user: :user_detail, score: [])
        .where(users: { identity: identity })
        .order(created_at: :desc)
        .limit(3)

      if registrations.any?
        registration_data = registrations.map do |registration|
          score = registration.score
          
          # Check if result report exists and is completed
          has_result_report = score.result_report.present? && 
                             score.result_report_status == 'completed'

          result_report_slug = score.result_report_slug

          {
            exam_name: registration.exam_session.exam.name,
            exam_session: "#{I18n.l(registration.exam_session.start_time, format: :simple_no_sec)} - #{I18n.l(registration.exam_session.end_time, format: :time_wib)}",
            exam_date: I18n.l(registration.exam_session.start_time.to_date, format: :short),
            score_number: score.score_number,
            score_grade: score.score_grade,
            score_slug: score.slug,
            has_result_report: has_result_report,
            result_report_slug: result_report_slug,
            result_report_status: score.result_report_status || 'idle'
          }
        end

        identity_type = identity.length == 8 ? "NRP" : "NIP"
        render json: {
          success: true,
          user_identity: user.identity,
          user_name: user.user_detail.name,
          user_rank: user.user_detail.rank,
          user_status: user.account_status,
          user_slug: user.slug,
          identity_type: identity_type,
          registrations: registration_data
        }
      else
        render json: { success: false, message: 'Pengguna belum pernah daftar ujian apapun.' }
      end
    else
      identity_type = identity.length == 8 ? "NRP" : "NIP"
      render json: { success: false, message: "#{identity_type} tidak ditemukan." }
    end
  end
end
