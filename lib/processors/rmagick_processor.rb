require 'RMagick'

class RmagickProcessor < ImageProcessor
  
  def width
    @image.columns
  end
  
  def height
    @image.rows
  end
  
  def save(path, type = :jpg)
    path = "#{path}.#{type}" unless path =~ /\.\w+$/
    @image.write(path)
    self
  end
  
  def composite(other_image, x, y)
    other_image = other_image.image if other_image.is_a?(ImageProcessor)
    @image.composite!(other_image, Magick::NorthWestGravity, x, y, Magick::OverCompositeOp)
    self
  end
  
  # crop resize
  def crop_to_fit(width, height)
    @image.crop_resized!(width, height, Magick::NorthGravity)
    self
  end
  
  # resizes to the bounds of width and height, but keeps the same aspect ratio
  def scale_to_fit(width, height)
    @image.change_geometry("#{width}x#{height}") { |cols, height, img| img.resize!(cols, height) }
    self
  end
  
  def polaroid(angle = -5.0)
    @image = @image.polaroid(angle) do
      self.shadow_color = "darkslategray"
      self.pointsize = 12
    end
    self
  end
  
  def filename
    @image.filename
  end
  
  def caption=(text)
    @image[:Caption] = text
  end
  
  def caption
    @image[:Caption]
  end
  
protected
  
  def load_image
    color = @color
    if @path
      Magick::Image.read(File.expand_path(@path)).first
    elsif @width && @height
      Magick::Image.new(@width, @height) do
        self.depth = 8
        self.background_color = color if color
      end
    else
      raise ArgumentError, "Expected either a path or a width and height"
    end
  end
  
end