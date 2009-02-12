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
      eval "OSX::NSColor.#{name}Color"
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
  
  def polaroid(angle = -5.0)
    width, height = rotated_rectangle_bounds(angle)
    xform = OSX::NSAffineTransform.transform
    result = OSX::NSImage.alloc.initWithSize([width, height])
    result.lockFocus
    OSX::NSGraphicsContext.currentContext.setImageInterpolation(OSX::NSImageInterpolationHigh)
    OSX::CGContextTranslateCTM(OSX::NSGraphicsContext.currentContext.graphicsPort, width/2, height/2) # Move the origin to the center.
    xform.rotateByDegrees(-angle)
    xform.concat
    dest_rect   = [0 - (size.width/2.0), 0 - (size.height/2.0), size.width, size.height]
    source_rect = [0, 0, size.width, size.height]
    drawInRect_fromRect_operation_fraction(dest_rect, source_rect, OSX::NSCompositeSourceOver, 1.0)
    result.unlockFocus
    result
  end
  
  # Thanks to http://www.codeproject.com/KB/graphics/rotateimage.aspx
  def rotated_rectangle_bounds(angle)
    pi2 = Math::PI / 2.0
    theta = angle * Math::PI / 180.0
    while theta < 0.0
      theta += 2 * Math::PI
    end
    
    adjacent_method, opposite_method, top_method, bottom_method = 
      if (theta >= 0.0 && theta < pi2) || (theta >= Math::PI && theta < (Math::PI + pi2) )
        [:cos, :sin, :width, :height]
      else
        [:sin, :cos, :height, :width]
      end
    adjacent_top    = Math.send(adjacent_method, theta).abs * size.send(top_method)
    opposite_top    = Math.send(opposite_method, theta).abs * size.send(top_method)
    adjacent_bottom = Math.send(adjacent_method, theta).abs * size.send(bottom_method)
    opposite_bottom = Math.send(opposite_method, theta).abs * size.send(bottom_method)
    
    width  = adjacent_top + opposite_bottom
    height = adjacent_bottom + opposite_top
    
    [width.ceil + 1, height.ceil + 1]
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
