# Abstract class
class ImageProcessor
  
  attr_reader :image, :color
  
  # subclasses should override +initialize+ and assign <tt>@image</tt>
  def initialize(options = {})
    @path   = options[:path]
    @width  = options[:width]
    @height = options[:height]
    @color  = options[:color]
    
    @image  = load_image
  end
  
protected
  
  def load_image
    raise NotImplementedError, "subclasses must declare load_image"
  end
  
end