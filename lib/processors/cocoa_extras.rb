require 'osx/cocoa'
# this prevents a warning from AppKit
app = OSX::NSApplication.sharedApplication

class OSX::NSColor
  # black, blue, brown, clear, cyan, darkGray, gray, green, lightGray, magenta, orange, purple, red, white, yellow
  def self.color_with_name(name) 
    if name[0..0] == "#"
      r = eval("0x"+name[1..2]) / 256.0
      g = eval("0x"+name[3..4]) / 256.0
      b = eval("0x"+name[5..6]) / 256.0
      colorWithDeviceRed_green_blue_alpha(r,g,b,1)
    elsif name == "transparent"
      OSX::NSColor.blackColor.colorWithAlphaComponent(0.0)
    elsif name == "grey"
      OSX::NSColor.colorWithDeviceRed_green_blue_alpha(0.5,0.5,0.5,1)
    else
      OSX::NSColor.send("#{name}Color")
    end
  end
end

class OSX::CIImage
  include OSX::OCObjWrapper
  
  def method_missing_with_filter_processing(sym, *args, &block)
    f = OSX::CIFilter.filterWithName("CI#{sym.to_s.camelize}")
    return method_missing_without_filter_processing(sym, *args, &block) unless f
  
    f.setDefaults if f.respond_to? :setDefaults
    f.setValue_forKey(self, 'inputImage')
    options = args.last.is_a?(Hash) ? args.last : {}
    options.each { |k, v| f.setValue_forKey(v, k.to_s) }
  
    block.call f.valueForKey('outputImage')
  end

  alias_method_chain :method_missing, :filter_processing
end

class OSX::NSImage
  
  def polaroid(angle = -5.0, caption = nil)
    border_width                = 12
    bordered_image              = border(12, '#f0f0ff', caption)
    shadow_width, shadow_radius = 5.0, 2.5
    old_width, old_height       = bordered_image.size.width, bordered_image.size.height
    width, height               = rotated_rectangle_bounds(angle, old_width, old_height).map { |l| l + shadow_width + shadow_radius }
    xform                       = OSX::NSAffineTransform.transform
    result                      = OSX::NSImage.alloc.initWithSize([width, height])
    result.lockFocus
    OSX::NSGraphicsContext.currentContext.setImageInterpolation(OSX::NSImageInterpolationHigh)
    OSX::CGContextTranslateCTM(OSX::NSGraphicsContext.currentContext.graphicsPort, width/2, height/2) # Move the origin to the center.
    xform.rotateByDegrees(-angle)
    xform.concat
    dest_rect   = [0 - (old_width/2.0), 0 - (old_height/2.0), old_width, old_height]
    source_rect = [0, 0, old_width, old_height]
    shadow([shadow_width, -shadow_width], shadow_radius) do
      bordered_image.drawInRect_fromRect_operation_fraction(dest_rect, source_rect, OSX::NSCompositeSourceOver, 1.0)
    end
    polaroid_text(caption, border_width + 1, -(old_width/2) + border_width, -(old_height/2) + border_width)
    result.unlockFocus
    result
  end
  
  def polaroid_text(text, size, x, y)
    ctx = OSX::NSGraphicsContext.currentContext.graphicsPort
    OSX::CGContextSelectFont(ctx, "GillSans", size, OSX::KCGEncodingMacRoman)
    OSX::CGContextSetTextDrawingMode(ctx, OSX::KCGTextFillStroke)
    OSX::CGContextSetRGBFillColor(ctx, 0.1, 0.1, 0.1, 0.7)
    OSX::CGContextSetRGBStrokeColor(ctx, 0.1, 0.1, 0.1, 0.5)
    OSX::CGContextShowTextAtPoint(ctx, x, y, text, text.size)
  end
  
  # Thanks to http:#www.codeproject.com/KB/graphics/rotateimage.aspx
  def rotated_rectangle_bounds(angle, width, height)
    pi2 = Math::PI / 2.0
    theta = angle * Math::PI / 180.0
    while theta < 0.0
      theta += 2 * Math::PI
    end
    
    adjacent_method, opposite_method, top, bottom = 
      if (theta >= 0.0 && theta < pi2) || (theta >= Math::PI && theta < (Math::PI + pi2) )
        [:cos, :sin, width, height]
      else
        [:sin, :cos, height, width]
      end
    adjacent_top    = Math.send(adjacent_method, theta).abs * top
    opposite_top    = Math.send(opposite_method, theta).abs * top
    adjacent_bottom = Math.send(adjacent_method, theta).abs * bottom
    opposite_bottom = Math.send(opposite_method, theta).abs * bottom
    
    width  = adjacent_top + opposite_bottom
    height = adjacent_bottom + opposite_top
    
    [width.ceil + 1, height.ceil + 1]
  end
  
  def shadow(offset_size, blur_radius, alpha = 0.4, &block)
    OSX::NSGraphicsContext.saveGraphicsState
    
    # Create the shadow below and to the right of the shape.
    theShadow = OSX::NSShadow.alloc.init
    theShadow.setShadowOffset(offset_size)
    theShadow.setShadowBlurRadius(blur_radius)
    
    # Use a partially transparent color for shapes that overlap.
    theShadow.setShadowColor(OSX::NSColor.blackColor.colorWithAlphaComponent(alpha))
    
    theShadow.set
    
    # Draw your custom content here. Anything you draw
    # automatically has the shadow effect applied to it.
    yield
    
    OSX::NSGraphicsContext.restoreGraphicsState
  end
  
  def border(border_width, color = nil, caption_space = false)
    new_width  = size.width  + (border_width * 2)
    new_height = size.height + (border_width * 2)
    new_height += border_width * 2 if caption_space
    result = OSX::NSImage.alloc.initWithSize([new_width, new_height])
    result.lockFocus
    OSX::NSColor.color_with_name(color).set
    OSX::NSRectFill([0, 0, new_width, new_height])
    y = border_width
    y += border_width * 2 if caption_space
    drawInRect_fromRect_operation_fraction([border_width, y, size.width, size.height], [0, 0, size.width, size.height], OSX::NSCompositeSourceOver, 1.0)
    result.unlockFocus
    result
  end
  
  
  def crop_to_fit(width, height)
    resize(width, height, :resize_crop)
  end

  def scale_to_fit(width, height)
    resize(width, height, :resize_scale)
  end

  # Resize methods:
  #   :resize_crop
  #   :resize_scale
  #   :resize_crop_start
  #   :resize_crop_end
  def resize(width, height, resize_method)
    cropping = (resize_method != :resize_scale)

    # Calculate aspect ratios
    source_ratio = size.width / size.height
    target_ratio = width / height

    # Determine what side of the source image to use for proportional scaling
    scale_width = (source_ratio <= target_ratio)

    # Proportionally scale source image
    scaled_width, scaled_height = nil, nil
    if cropping && scale_width
      scaling_factor = 1.0 / source_ratio
      scaled_width   = width
      scaled_height  = (width * scaling_factor).round
    else
      scaling_factor = source_ratio
      scaled_width   = (height * scaling_factor).round
      scaled_height  = height
    end
    scale_factor = scaled_height / size.height

    # Calculate compositing rectangles
    source_rect = nil
    if cropping
      dest_x, dest_y = nil, nil
      case resize_method
      when :resize_crop
        # Crop center
        dest_x = ((scaled_width - width) / 2.0).round
        dest_y = ((scaled_height - height) / 2.0).round
      when :resize_crop_start
        # Crop top or left (prefer top)
        if scale_width
          # Crop top
          dest_x = ((scaled_width - width) / 2.0).round
          dest_y = (scaled_height - height).round
        else
          # Crop left
          dest_x = 0.0
          dest_y = ((scaled_height - height) / 2.0).round
        end
      when :resize_crop_end
        # Crop bottom or right
        if scale_width
          # Crop bottom
          dest_x = 0.0
          dest_y = 0.0
        else
          # Crop right
          dest_x = (scaled_width - width).round
          dest_y = ((scaled_height - height) / 2.0).round
        end
      end
      source_rect = [dest_x / scale_factor, dest_y / scale_factor, width / scale_factor, height / scale_factor]
    else
      width  = scaled_width
      height = scaled_height
      source_rect = [0, 0, size.width, size.height]
    end

    result = OSX::NSImage.alloc.initWithSize([width, height])
    result.lockFocus
    OSX::NSGraphicsContext.currentContext.setImageInterpolation(OSX::NSImageInterpolationHigh)
    drawInRect_fromRect_operation_fraction([0, 0, width, height], source_rect, OSX::NSCompositeSourceOver, 1.0)
    result.unlockFocus
    result
  end

end
