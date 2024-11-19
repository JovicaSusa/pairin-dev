require "image_processing/mini_magick"

class ImageUploader < Shrine
  plugin :default_url

  Attacher.default_url do |**options|
    "/assets/images/logo.svg"
  end

  Attacher.derivatives do |original|
    magick = ImageProcessing::MiniMagick.source(original)

    {
      small:  magick.resize_to_limit!(300, 300),
    }
  end
end
