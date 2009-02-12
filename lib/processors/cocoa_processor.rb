require File.join(File.dirname(__FILE__), 'cocoa_extras.rb')

class CocoaProcessor < ImageProcessor
  
  def width
    # @image.extent.size.width CIImage
    @image.size.width
  end
  
  def height
    # @image.extent.size.height CIImage
    @image.size.height
  end
  
  def save(path, type = :jpg)
    path, type = path.split(/\.(\w+$)/) if path =~ /\.\w+$/
    type_class = case type
    when :jpg then OSX::NSJPEGFileType
    when :png then OSX::NSPNGFileType
    end
    bits = OSX::NSBitmapImageRep.alloc.initWithData(@image.TIFFRepresentation)
    data = bits.representationUsingType_properties(type_class, nil)
    data.writeToFile_atomically("#{path}.#{type}", false)
    self
  end
  
  def composite(other_image, x, y)
    other_image = other_image.image if other_image.is_a?(ImageProcessor)
    @image.lockFocus
    other_image.drawAtPoint_fromRect_operation_fraction([x,y], [0,0, other_image.size.width, other_image.size.height], OSX::NSCompositeSourceOver, 1.0)
    @image.unlockFocus
    self
  end
  
  # resizes and crops to fill bounds
  def crop_to_fit(width, height)
    @image = @image.crop_to_fit(width, height)
    self
  end
  
  # resizes to the bounds of width and height, but keeps the same aspect ratio
  def scale_to_fit(width, height)
    @image = @image.scale_to_fit(width, height)
    self
  end
  
  def polaroid(angle = -5.0)
    border(15)
    @image = @image.polaroid(angle)
    self
  end
  
  def border(border_width, color=nil)
    new_width  = self.width  + (border_width * 2)
    new_height = self.height + (border_width * 2)
    result = OSX::NSImage.alloc.initWithSize([new_width, new_height])
    result.lockFocus
    OSX::NSColor.color_with_name('#f0f0ff').set
    OSX::NSRectFill([0, 0, new_width, new_height])
    @image.drawInRect_fromRect_operation_fraction([border_width, border_width, self.width, self.height], [0, 0, self.width, self.height], OSX::NSCompositeSourceOver, 1.0)
    result.unlockFocus
    @image = result
    self
  end
  
  def filename
    raise
  end
  
  def caption=(text)
    raise
  end
  
  def caption
    raise
  end
  
protected
  
  def load_image
    if @path
      OSX::NSImage.alloc.initWithContentsOfFile(@path)
    elsif @width && @height
      img = OSX::NSImage.alloc.initWithSize([@width, @height])
      img.lockFocus
      if @color
        OSX::NSColor.color_with_name(@color).set
        OSX::NSRectFill([0, 0, @width, @height])
      end
      img.unlockFocus
      img
    else
      raise ArgumentError, "Expected either a path or a width and height"
    end
  end
  
end