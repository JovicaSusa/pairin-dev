require "image_processing/vips"

class ImageUploader < Shrine
  plugin :default_url

  Attacher.validate do
    validate_max_size 1*1024*1024
    validate_mime_type %w[image/jpeg image/png image/webp image/tiff]
    validate_extension %w[jpg jpeg png webp tiff tif]
  end

  Attacher.default_url do |**options|
    ActionController::Base.helpers.asset_path('logo.svg')
  end

  Attacher.derivatives do |original|
    {
      small: ImageProcessing::Vips.source(original).resize_to_limit!(400, 400)
    }
  end
end
