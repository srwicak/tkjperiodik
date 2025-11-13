# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_08_04_205852) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "batches", force: :cascade do |t|
    t.bigint "exam_id", null: false
    t.integer "unit"
    t.integer "registration_type"
    t.text "batch_data"
    t.integer "status", default: 0
    t.integer "total_count", default: 0
    t.integer "processed_count", default: 0
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_id"], name: "index_batches_on_exam_id"
    t.index ["slug"], name: "index_batches_on_slug", unique: true
  end

  create_table "exam_sessions", force: :cascade do |t|
    t.bigint "exam_id", null: false
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.integer "size", default: 0, null: false
    t.integer "max_size", null: false
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_id"], name: "index_exam_sessions_on_exam_id"
    t.index ["slug"], name: "index_exam_sessions_on_slug", unique: true
  end

  create_table "exams", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.string "short_name"
    t.time "exam_start", null: false
    t.integer "exam_duration", null: false
    t.integer "break_time", null: false
    t.integer "size", null: false
    t.integer "batch", null: false
    t.integer "status", default: 0, null: false
    t.text "descriptions"
    t.text "notes"
    t.date "start_register"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "exam_date_start"
    t.date "exam_date_end"
    t.time "exam_rest_start"
    t.time "exam_rest_end"
    t.index ["created_by_id"], name: "index_exams_on_created_by_id"
    t.index ["slug"], name: "index_exams_on_slug", unique: true
    t.index ["updated_by_id"], name: "index_exams_on_updated_by_id"
  end

  create_table "excel_uploads", force: :cascade do |t|
    t.bigint "exam_id", null: false
    t.integer "status", default: 0
    t.text "file_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unit"
    t.index ["exam_id"], name: "index_excel_uploads_on_exam_id"
  end

  create_table "letter_contents", force: :cascade do |t|
    t.bigint "letter_id", null: false
    t.string "name"
    t.json "placeholder"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["letter_id"], name: "index_letter_contents_on_letter_id"
    t.index ["slug"], name: "index_letter_contents_on_slug", unique: true
  end

  create_table "letters", force: :cascade do |t|
    t.bigint "exam_id", null: false
    t.text "template_data"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_id"], name: "index_letters_on_exam_id"
    t.index ["slug"], name: "index_letters_on_slug", unique: true
  end

  create_table "polda_regions", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_polda_regions_on_name", unique: true
    t.index ["slug"], name: "index_polda_regions_on_slug", unique: true
  end

  create_table "polda_reports", force: :cascade do |t|
    t.bigint "polda_region_id", null: false
    t.bigint "exam_id", null: false
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.text "file_data"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_id"], name: "index_polda_reports_on_exam_id"
    t.index ["polda_region_id"], name: "index_polda_reports_on_polda_region_id"
    t.index ["slug"], name: "index_polda_reports_on_slug", unique: true
    t.index ["user_id"], name: "index_polda_reports_on_user_id"
  end

  create_table "polda_staffs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "polda_region_id", null: false
    t.string "name"
    t.string "phone"
    t.string "identity"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identity"], name: "index_polda_staffs_on_identity", unique: true
    t.index ["polda_region_id"], name: "index_polda_staffs_on_polda_region_id"
    t.index ["user_id"], name: "index_polda_staffs_on_user_id"
  end

  create_table "registrations", force: :cascade do |t|
    t.bigint "exam_session_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "pdf_data"
    t.string "slug"
    t.integer "pdf_status"
    t.integer "registration_type"
    t.boolean "is_attending"
    t.index ["exam_session_id"], name: "index_registrations_on_exam_session_id"
    t.index ["slug"], name: "index_registrations_on_slug", unique: true
    t.index ["user_id", "exam_session_id"], name: "index_registrations_on_user_id_and_exam_session_id", unique: true
    t.index ["user_id"], name: "index_registrations_on_user_id"
  end

  create_table "result_docs", force: :cascade do |t|
    t.bigint "exam_id", null: false
    t.jsonb "content"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_id"], name: "index_result_docs_on_exam_id"
  end

  create_table "scores", force: :cascade do |t|
    t.bigint "registration_id", null: false
    t.json "score_detail"
    t.string "score_number"
    t.string "score_grade"
    t.text "result_doc_data"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
    t.text "notes"
    t.integer "doc_status"
    t.boolean "exam_present", default: false
    t.text "result_report_data"
    t.integer "result_report_status", default: 0
    t.string "result_report_slug"
    t.index ["code"], name: "index_scores_on_code", unique: true
    t.index ["registration_id"], name: "index_scores_on_registration_id", unique: true
    t.index ["result_report_slug"], name: "index_scores_on_result_report_slug", unique: true
    t.index ["slug"], name: "index_scores_on_slug", unique: true
  end

  create_table "user_details", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name", default: "", null: false
    t.integer "rank"
    t.string "position"
    t.integer "unit"
    t.boolean "gender", null: false
    t.boolean "is_operator_granted", default: false, null: false
    t.boolean "is_superadmin_granted", default: false, null: false
    t.integer "person_status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_details_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "slug", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identity", null: false
    t.boolean "is_verified", default: false
    t.boolean "is_onboarded", default: false
    t.boolean "is_forgotten", default: false
    t.datetime "forgotten_at"
    t.integer "forgotten_count", default: 0
    t.integer "account_status", default: 1, null: false
    t.string "otp_secret"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.string "account_status_reason"
    t.index ["account_status"], name: "index_users_on_account_status"
    t.index ["identity"], name: "index_users_on_identity", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "batches", "exams"
  add_foreign_key "exam_sessions", "exams"
  add_foreign_key "exams", "users", column: "created_by_id"
  add_foreign_key "exams", "users", column: "updated_by_id"
  add_foreign_key "excel_uploads", "exams"
  add_foreign_key "letter_contents", "letters"
  add_foreign_key "letters", "exams"
  add_foreign_key "polda_reports", "exams"
  add_foreign_key "polda_reports", "polda_regions"
  add_foreign_key "polda_reports", "users"
  add_foreign_key "polda_staffs", "polda_regions"
  add_foreign_key "polda_staffs", "users"
  add_foreign_key "registrations", "exam_sessions"
  add_foreign_key "registrations", "users"
  add_foreign_key "result_docs", "exams"
  add_foreign_key "scores", "registrations"
end
