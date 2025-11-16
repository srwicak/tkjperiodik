module Manage
  module Score
    class ScoringStandardsController < ApplicationController
      before_action -> { check_admin_status(redirect: true) }
      before_action :set_scoring_standard, only: [:edit, :update]
      
      def index
        @standards = ScoringStandard.order(:golongan, :jenis_kelamin)
      end
      
      def edit
        # @scoring_standard is set by before_action
        @test_types = @scoring_standard.valid_test_types
      end
      
      def update
        if @scoring_standard.update(scoring_standard_params)
          redirect_to manage_score_scoring_standards_path, notice: "Standar penilaian berhasil diperbarui"
        else
          @test_types = @scoring_standard.valid_test_types
          render :edit, status: :unprocessable_entity
        end
      end
      
      private
      
      def set_scoring_standard
        @scoring_standard = ScoringStandard.find(params[:id])
      end
      
      def scoring_standard_params
        params.require(:scoring_standard).permit(:lookup_data)
      end
    end
  end
end
