class Module::ScoresController < ApplicationController
  before_action :authorize_score_access, only: [:generate_result_report, :view_result_report]

  def generate_result_report
    @score = Score.find_by!(slug: params[:slug])
    @score.update!(result_report_slug: Nanoid.generate(size: 10)) unless @score.result_report_slug.present?

    # Jalankan job
    GenerateResultReportJob.perform_later(@score.id)

    # Redirect ke halaman show atau mana pun kamu mau
    redirect_to show_module_history_path(@score.registration.slug), notice: "Laporan sedang diproses. Silakan tunggu beberapa saat."
  end

  def view_result_report
    @score = Score.find_by!(result_report_slug: params[:slug])

    filename = @score.result_report.metadata["filename"] ||
              "hasil_#{@score.registration.user.identity}_#{@score.result_report_slug}.pdf"

    filename += ".pdf" unless filename.downcase.ends_with?(".pdf")

    send_data @score.result_report.read,
          filename: filename,
          type: 'application/pdf',
          disposition: 'inline'
  end

  private

  def authorize_score_access
    score = if params[:slug] && action_name == "generate_result_report"
      Score.find_by(slug: params[:slug])
    elsif params[:slug] && action_name == "view_result_report"
      Score.find_by(result_report_slug: params[:slug])
    end

    unless score &&
      (
        score.registration.user_id == current_user.id ||
        current_user.user_detail.is_operator_granted? ||
        current_user.user_detail.is_superadmin_granted?
      )
      render plain: "Anda tidak diizinkan mengakses data ini.", status: :forbidden
    end
  end
end
