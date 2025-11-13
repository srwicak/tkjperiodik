class PdfUploader < Shrine
  plugin :validation_helpers

  Attacher.validate do
    validate_mime_type_inclusion %w[application/pdf]
    validate_max_size 3*1024*1024, message: "ukuran terlalu besar maksimal 3 MB"
  end
end
