module Api
  class ScoringStandardsController < ApplicationController
    # Skip CSRF token verification for API requests
    skip_before_action :verify_authenticity_token
    
    # GET /api/scoring_standards?golongan=1&jenis_kelamin=pria
    def show
      golongan_param = params[:golongan]
      jenis_kelamin_param = params[:jenis_kelamin]
      
      # Validate parameters
      unless golongan_param.present? && jenis_kelamin_param.present?
        render json: { error: "Parameter golongan dan jenis_kelamin harus diisi" }, status: :bad_request
        return
      end
      
      # Convert golongan to enum key (1 => "golongan_1")
      golongan_key = "golongan_#{golongan_param}"
      
      # Find scoring standard
      standard = ScoringStandard.find_by(
        golongan: golongan_key,
        jenis_kelamin: jenis_kelamin_param
      )
      
      unless standard
        render json: { error: "Standar penilaian tidak ditemukan" }, status: :not_found
        return
      end
      
      # Return lookup data
      render json: {
        golongan: golongan_param,
        jenis_kelamin: jenis_kelamin_param,
        lookup_data: standard.lookup_data,
        valid_test_types: standard.valid_test_types
      }
    end
    
    # GET /api/scoring_standards/all
    # Return all scoring standards (for caching all at once if needed)
    def index
      standards = ScoringStandard.all.map do |standard|
        {
          golongan: standard.golongan.gsub('golongan_', ''),
          jenis_kelamin: standard.jenis_kelamin,
          lookup_data: standard.lookup_data,
          valid_test_types: standard.valid_test_types
        }
      end
      
      render json: { standards: standards }
    end
  end
end
