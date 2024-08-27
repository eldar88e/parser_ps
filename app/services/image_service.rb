class ImageService
  def initialize(**args)
    @image  = MiniMagick::Image.read(args[:image]) if args[:image]
    @width  = args[:width]
    @height = args[:height]
  end

  def self.call(**args)
    new(**args).resize_to_fill
  end

  def resize_to_fill
    return unless @image

    @image.resize("#{@width}x#{@height}")
    @image.to_blob
  end
end