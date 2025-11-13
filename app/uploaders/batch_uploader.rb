class BatchUploader < Shrine
  plugin :validation_helpers
  plugin :determine_mime_type

  Attacher.validate do
    validate_mime_type_inclusion %w[application/vnd.openxmlformats-officedocument.wordprocessingml.document]
    validate_max_size 3*1024*1024, message: "ukuran terlalu besar maksimal 3 MB"
  end
end
