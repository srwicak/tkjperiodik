class Manage::UserManagement::FormsController < ApplicationController
  before_action :check_admin_status

  def search
  end

  def data
    identity = params[:identity]
    
    # Validate identity format
    unless identity.length == 8 || identity.length == 18
      render json: { success: false, message: 'Identitas harus 8 digit (NRP) atau 18 digit (NIP).' }
      return
    end
    
    user = User.find_by(identity: identity)

    if user
      registrations = Registration.includes(exam_session: :exam, user: :user_detail)
        .where(users: { identity: identity })
        .order(created_at: :desc)
        .limit(3)
      if registrations.any?
        registration_data  = registrations.map do |registration|
          {
            exam_name: registration.exam_session.exam.name,
            exam_session: "#{I18n.l(registration.exam_session.start_time, format: :simple_no_sec)} - #{I18n.l(registration.exam_session.end_time, format: :time_wib)}",
            exam_slug: registration.slug
          }
        end

        identity_type = identity.length == 8 ? "NRP" : "NIP"
        render json: {
          success: true,
          user_identity: user.identity,
          user_name: user.user_detail.name,
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
