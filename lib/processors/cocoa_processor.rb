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
    other_image.drawAtPoint_fromRect_operation_fraction([x,y], [0,0,800,800], OSX::NSCompositeSourceOver, 1.0)
    @image.unlockFocus
    self
  end
  
  # resizes and crops to fill bounds
  def crop_to_fit(width, height)
    # create_core_image_context(width, height)
    # scale_x, scale_y = scaling(width, height)
    # ciimage = OSX::CIImage.alloc.initWithData(@image.TIFFRepresentation)
    # resized_image = nil
    # ciimage.affine_clamp :inputTransform => OSX::NSAffineTransform.transform do |clamped|
    #   clamped.lanczos_scale_transform :inputScale => scale_x > scale_y ? scale_x : scale_y, :inputAspectRatio => scale_x / scale_y do |scaled|
    #     scaled.crop :inputRectangle => vector(0, 0, width, height) do |cropped|
    #       resized_image = cropped
    #     end
    #   end
    # end
    # @image = OSX::NSImage.alloc.initWithSize([resized_image.extent.size.width, resized_image.extent.size.height])
    # composite(resized_image, 0, 0)
    
    @image = @image.crop_to_fit(width, height)
    self
  end
  
  # resizes to the bounds of width and height, but keeps the same aspect ratio
  def scale_to_fit(width, height)
    @image = @image.scale_to_fit(width, height)
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
  
private

  def create_core_image_context(width, height)
    output = OSX::NSBitmapImageRep.alloc.initWithBitmapDataPlanes_pixelsWide_pixelsHigh_bitsPerSample_samplesPerPixel_hasAlpha_isPlanar_colorSpaceName_bytesPerRow_bitsPerPixel(nil, width, height, 8, 4, true, false, OSX::NSDeviceRGBColorSpace, 0, 0)
    context = OSX::NSGraphicsContext.graphicsContextWithBitmapImageRep(output)
    OSX::NSGraphicsContext.setCurrentContext(context)
    @ci_context = context.CIContext
  end
  
  def vector(x, y, w, h)
    OSX::CIVector.vectorWithX_Y_Z_W(x, y, w, h)
  end
  
  def scaling(width, height)
    [width.to_f / self.width.to_f, height.to_f / self.height.to_f]
  end
  
end