require "image_processing/mini_magick"

class ImageUploader < Shrine
  plugin :default_url

  Attacher.default_url do |**options|
    "/uploads/store/#{name}/default.png"
  end

  Attacher.derivatives do |original|
    magick = ImageProcessing::MiniMagick.source(original)

    {
      small:  magick.resize_to_limit!(300, 300),
    }
  end
end
