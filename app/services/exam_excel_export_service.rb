require 'caxlsx'

class ExamExcelExportService
  def initialize(exam, unit)
    @exam = exam
    @unit = unit
  end

  def generate_scored_participants
    package = Axlsx::Package.new
    workbook = package.workbook

    # Define styles
    header_style = workbook.styles.add_style(
      bg_color: "4472C4",
      fg_color: "FFFFFF",
      b: true,
      alignment: { horizontal: :center, vertical: :center, wrap_text: true },
      border: { style: :thin, color: "000000" }
    )

    cell_style = workbook.styles.add_style(
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: "000000" }
    )

    workbook.add_worksheet(name: "Peserta Yang Sudah Dinilai") do |sheet|
      # Header row
      headers = [
        "No",
        "Nama Lengkap",
        "Pangkat",
        "NRP",
        "Kesatuan",
        "Tanggal Lahir",
        "Tanggal Ujian",
        "Usia Saat Ujian",
        "Jenis Kelamin",
        "Golongan Saat Ujian",
        "HGA",
        "NGA",
        "HGB1",
        "NGB1",
        "HGB2",
        "NGB2",
        "HGB3",
        "NGB3",
        "HGB4",
        "NGB4",
        "Nilai Rerata UKJ B",
        "Nilai Akhir A+B",
        "KTGR",
        "Ket"
      ]
      
      sheet.add_row headers, style: header_style

      # Get participants with scores
      participants = get_scored_participants

      participants.each_with_index do |participant, index|
        row_data = build_row_data(participant, index + 1)
        sheet.add_row row_data, style: cell_style
      end

      # Auto-fit columns
      sheet.column_widths 5, 25, 12, 12, 20, 12, 12, 15, 12, 18, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 15, 15, 8, 15
    end

    package.to_stream.read
  end

  private

  def get_scored_participants
    unit_name = @unit.tr("-", " ").upcase

    # Get participants and sort by rank (lowest first) then name (A-Z)
    participants = Registration
      .joins(:exam_session, :score, user: :user_detail)
      .where(exam_sessions: { exam_id: @exam.id })
      .where(user_details: { unit: UserDetail.units[unit_name] })
      .where.not(scores: { score_number: nil })
      .select(
        "registrations.*",
        "scores.score_number",
        "scores.score_detail",
        "scores.score_grade",
        "users.identity",
        "user_details.name",
        "user_details.rank",
        "user_details.unit",
        "user_details.date_of_birth",
        "user_details.gender"
      )
    
    # Sort in Ruby: rank from lowest to highest, then name A-Z within same rank
    participants.sort_by do |p|
      rank_value = UserDetail.ranks[p.user.user_detail.rank] || 999
      [rank_value, p.user.user_detail.name]
    end
  end

  def build_row_data(participant, row_number)
    score_data = parse_score_data(participant.score_detail)
    exam_date = participant.exam_schedule&.exam_date
    golongan = participant.age_category_at_exam || "-"
    is_male = participant.user.user_detail.gender

    # Calculate age at exam
    age_data = participant.age_in_years_and_days_at_exam
    age_display = if age_data
      "#{age_data[:years]} thn #{age_data[:months]} bln #{age_data[:days]} hr"
    else
      "-"
    end

    # Get rank and unit (already stored as string keys)
    rank_name = participant.user.user_detail.rank || "-"
    unit_name = participant.user.user_detail.unit || "-"

    # Get physical test scores
    hga = score_data[:raw][:lari_12_menit] || "-"
    nga = score_data[:score][:lari_12_menit] || "-"

    # For golongan 4, only HGA and NGA are shown
    if golongan == "4"
      hgb1 = "-"
      ngb1 = "-"
      hgb2 = "-"
      ngb2 = "-"
      hgb3 = "-"
      ngb3 = "-"
      hgb4 = "-"
      ngb4 = "-"
      nilai_rerata_b = "-"
    else
      # Get HGB scores based on gender
      upper_body_key = is_male ? :pull_ups : :chinning
      hgb1 = score_data[:raw][upper_body_key] || "-"
      ngb1 = score_data[:score][upper_body_key] || "-"
      
      hgb2 = score_data[:raw][:sit_ups] || "-"
      ngb2 = score_data[:score][:sit_ups] || "-"
      
      hgb3 = score_data[:raw][:push_ups] || "-"
      ngb3 = score_data[:score][:push_ups] || "-"
      
      hgb4 = score_data[:raw][:shuttle_run] || "-"
      ngb4 = score_data[:score][:shuttle_run] || "-"

      # Calculate average of UKJ B (only if all values are present)
      b_scores = [ngb1, ngb2, ngb3, ngb4].reject { |v| v == "-" }
      nilai_rerata_b = if b_scores.size == 4
        (b_scores.sum.to_f / 4).round(2)
      else
        "-"
      end
    end

    # Get final score
    nilai_akhir = participant.score_number.to_f rescue 0

    [
      row_number,
      participant.user.user_detail.name,
      rank_name,
      participant.user.identity,
      unit_name,
      participant.user.user_detail.date_of_birth&.strftime("%d/%m/%Y") || "-",
      exam_date&.strftime("%d/%m/%Y") || "-",
      age_display,
      is_male ? "Pria" : "Wanita",
      golongan,
      hga,
      nga,
      hgb1,
      ngb1,
      hgb2,
      ngb2,
      hgb3,
      ngb3,
      hgb4,
      ngb4,
      nilai_rerata_b,
      nilai_akhir,
      participant.score_grade || "-",
      "" # Ket - empty for now
    ]
  end

  def parse_score_data(score_detail)
    return { raw: {}, score: {} } if score_detail.blank?

    begin
      data = JSON.parse(score_detail, symbolize_names: true)
      {
        raw: data[:raw] || {},
        score: data[:score] || {}
      }
    rescue JSON::ParserError
      { raw: {}, score: {} }
    end
  end
end
