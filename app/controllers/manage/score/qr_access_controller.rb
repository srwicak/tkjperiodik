class Manage::Score::QrAccessController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }

  def show
    # Remove dash from code if present (EN5-OA3G -> EN5OA3G)
    code = params[:code].to_s.upcase.gsub('-', '')
    
    # Find score by code
    score = Score.find_by(code: code)
    
    if score
      # Clear any existing flash messages before redirect
      flash.discard
      # Redirect to edit page
      redirect_to edit_manage_score_path(score.slug)
    else
      # Code not found
      redirect_to index_manage_score_path, alert: "Kode registrasi tidak ditemukan: #{params[:code]}"
    end
  end
end
