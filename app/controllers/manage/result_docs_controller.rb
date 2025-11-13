class Manage::ResultDocsController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }
  before_action :set_result_doc, only: [:edit, :update]

  def index
  end

  def edit
    @exam = @result_doc.exam
    @content = @result_doc.content.nil? ? "" : JSON.parse(@result_doc.content)
    @url = edit_manage_result_doc_path(@result_doc.slug)

  end

  def update
    if @result_doc.update(params.require(:result_doc).permit(:content))
      redirect_to edit_manage_result_doc_path(@result_doc.slug), notice: "Konten surat telah diperbarui"
    end
  end

  def data
    # Pagination
    page = params[:page].to_i
    size = params[:size].to_i
    offset = (page - 1) * size

    if params[:filter]
      filters = params[:filter].values
      name_filter = filters.find { |f| f[:field] == "name" }

      docs = ResultDoc.joins(:exam)

      if name_filter
        name = name_filter[:value]
        docs = docs.where("exams.name ILIKE ?", "%#{name}%")
      end

      paging_docs = docs
        .order(created_at: :desc)
        .offset(offset)
        .limit(size)
    else
      paging_docs = ResultDoc.all
        .order(created_at: :desc)
        .offset(offset)
        .limit(size)
    end

    total = paging_docs.count

    paginated_docs = paging_docs.map do |doc|
      {
        id: doc.id,
        slug: doc.slug,
        created_at: doc.created_at,
        name: doc.exam.name,
        exam_date: "#{I18n.l(doc.exam.exam_date_start, format: :default)} - #{I18n.l(doc.exam.exam_date_end, format: :default)}",
        status: doc.exam.status.titlecase
      }
    end

    render json: {
      last_page: (total.to_f / size).ceil,
      data: paginated_docs,
      total: total
    }
  end

  def set_result_doc
    @result_doc = ResultDoc.find_by!(slug: params[:slug])
  end
end
