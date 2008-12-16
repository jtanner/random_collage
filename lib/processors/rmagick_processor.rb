require 'RMagick'

class RmagickProcessor
  
  def initialize(options = {})
    @path   = options[:path]
    @width  = options[:width]
    @height = options[:height]
    @color  = color = options[:color]
    
    @image = if @path
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
  
  attr_reader :image, :color
  
  def width
    @image.columns
  end
  
  def height
    @image.rows
  end
  
  def save(path, type = :jpg)
    path = "#{path}.#{type}" unless path =~ /\.\w+$/
    @image.write(path)
  end
  
  def composite(other_image, x, y)
    other_image = other_image.image if respond_to?(:image)
    @image.composite!(other_image, Magick::NorthWestGravity, x, y, Magick::OverCompositeOp)
    self
  end
  
  def resize(width, height)
    @image.crop_resized!(width, height) #, Magick::NorthGravity)
    self
  end
  
  # resizes to the bounds of width and height, but keeps the same aspect ratio
  def shrink(width, height)
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
  
end