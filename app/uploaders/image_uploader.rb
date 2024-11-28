require "image_processing/vips"

class ImageUploader < Shrine
  plugin :default_url

  Attacher.default_url do |**options|
    ActionController::Base.helpers.asset_path('logo.svg')
  end

  Attacher.derivatives do |original|
    {
      small: ImageProcessing::Vips.source(original).resize_to_limit!(400, 400)
    }
  end
end
