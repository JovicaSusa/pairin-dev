require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/s3"

permanent_storage =
  if Rails.env.production?
    Shrine::Storage::S3.new(
      bucket: "pairin",
      region: "eu-north-1",
      access_key_id: Rails.application.credentials.aws_access_key_id,
      secret_access_key: Rails.application.credentials.secret_access_key
    )
  else
    Shrine::Storage::FileSystem.new("public", prefix: "uploads")
  end

Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
  store: permanent_storage
}

Shrine.plugin :activerecord           # loads Active Record integration
Shrine.plugin :cached_attachment_data # enables retaining cached file across form redisplays
Shrine.plugin :restore_cached_data    # extracts metadata for assigned cached files
Shrine.plugin :derivatives, create_on_promote: true
