class Superadmin::FormsController < ApplicationController
  before_action :check_admin_status
  before_action :superadminonly

  def search
  end

  def data
    user = User.find_by(identity: params[:identity])

    if user
      if user.is_police?
        registrations = Registration.includes(exam_session: :exam, user: :user_detail)
          .where(users: { identity: params[:identity] })
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

          render json: {
            success: true,
            user_identity: user.identity,
            user_name: user.user_detail.name,
            user_status: user.account_status,
            user_slug: user.slug,
            registrations: registration_data
           }
        else
          render json: { success: false, message: 'Pengguna belum pernah daftar ujian apapun.' }
        end
      else
        render json: { success: false, message: 'Pengguna ini bukan polisi.' }
      end
    else
      render json: { success: false, message: 'Pengguna tidak ditemukan.' }
    end
  end

  private

  def superadminonly
    unless current_user.user_detail.is_superadmin_granted
      redirect_to root_path
    end
  end
end
