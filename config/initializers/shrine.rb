require "shrine"
require "shrine/storage/file_system"

Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("private", prefix: "uploads/cache"),
  store: Shrine::Storage::FileSystem.new("private", prefix: "uploads/store"),
}

Shrine.plugin :activerecord # loads Active Record integration
Shrine.plugin :cached_attachment_data # for retaining cached file across form redisplays
Shrine.plugin :restore_cached_data # re-extract metadata when attaching a cached file
Shrine.plugin :determine_mime_type # automatically determine mime type
Shrine.plugin :backgrounding # for running background jobs
Shrine.plugin :store_dimensions # for storing image dimensions
Shrine.plugin :validation_helpers # for validations
