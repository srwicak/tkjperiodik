# app/uploaders/excel_uploader.rb
class ExcelUploader < Shrine
  plugin :validation_helpers
  plugin :determine_mime_type

  Attacher.validate do
    validate_extension_inclusion %w[xlsx]
    # Allow multiple MIME types as Excel files can be detected differently
    validate_mime_type_inclusion %w[
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      application/zip
      application/octet-stream
    ]
    validate_max_size 3*1024*1024, message: "ukuran terlalu besar maksimal 3 MB"
  end
end