require 'osx/cocoa'
# this prevents a warning from AppKit
app = OSX::NSApplication.sharedApplication

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
    polaroid_text(caption, border_width + 1, -(old_width/2) + border_width, -(old_height/2) + border_width) if caption
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


class OSX::NSColor
  W3_COLORS = {
    'aliceblue'            => [240, 248, 255],
    'antiquewhite'         => [250, 235, 215],
    'aqua'                 => [ 0,  255, 255],
    'aquamarine'           => [127, 255, 212],
    'azure'                => [240, 255, 255],
    'beige'                => [245, 245, 220],
    'bisque'               => [255, 228, 196],
    'black'                => [ 0,  0,   0],
    'blanchedalmond'       => [255, 235, 205],
    'blue'                 => [ 0,  0,   255],
    'blueviolet'           => [138, 43,  226],
    'brown'                => [165, 42,  42],
    'burlywood'            => [222, 184, 135],
    'cadetblue'            => [ 95, 158, 160],
    'chartreuse'           => [127, 255, 0],
    'chocolate'            => [210, 105, 30],
    'coral'                => [255, 127, 80],
    'cornflowerblue'       => [100, 149, 237],
    'cornsilk'             => [255, 248, 220],
    'crimson'              => [220, 20,  60],
    'cyan'                 => [ 0,  255, 255],
    'darkblue'             => [ 0,  0,   139],
    'darkcyan'             => [ 0,  139, 139],
    'darkgoldenrod'        => [184, 134, 11],
    'darkgray'             => [169, 169, 169],
    'darkgreen'            => [ 0,  100, 0],
    'darkgrey'             => [169, 169, 169],
    'darkkhaki'            => [189, 183, 107],
    'darkmagenta'          => [139, 0,   139],
    'darkolivegreen'       => [ 85, 107, 47],
    'darkorange'           => [255, 140, 0],
    'darkorchid'           => [153, 50,  204],
    'darkred'              => [139, 0,   0],
    'darksalmon'           => [233, 150, 122],
    'darkseagreen'         => [143, 188, 143],
    'darkslateblue'        => [ 72, 61,  139],
    'darkslategray'        => [ 47, 79,  79],
    'darkslategrey'        => [ 47, 79,  79],
    'darkturquoise'        => [ 0,  206, 209],
    'darkviolet'           => [148, 0,   211],
    'deeppink'             => [255, 20,  147],
    'deepskyblue'          => [ 0,  191, 255],
    'dimgray'              => [105, 105, 105],
    'dimgrey'              => [105, 105, 105],
    'dodgerblue'           => [ 30, 144, 255],
    'firebrick'            => [178, 34,  34],
    'floralwhite'          => [255, 250, 240],
    'forestgreen'          => [ 34, 139, 34],
    'fuchsia'              => [255, 0,   255],
    'gainsboro'            => [220, 220, 220],
    'ghostwhite'           => [248, 248, 255],
    'gold'                 => [255, 215, 0],
    'goldenrod'            => [218, 165, 32],
    'gray'                 => [128, 128, 128],
    'grey'                 => [128, 128, 128],
    'green'                => [ 0,  128, 0],
    'greenyellow'          => [173, 255, 47],
    'honeydew'             => [240, 255, 240],
    'hotpink'              => [255, 105, 180],
    'indianred'            => [205, 92,  92],
    'indigo'               => [ 75, 0,   130],
    'ivory'                => [255, 255, 240],
    'khaki'                => [240, 230, 140],
    'lavender'             => [230, 230, 250],
    'lavenderblush'        => [255, 240, 245],
    'lawngreen'            => [124, 252, 0],
    'lemonchiffon'         => [255, 250, 205],
    'lightblue'            => [173, 216, 230],
    'lightcoral'           => [240, 128, 128],
    'lightcyan'            => [224, 255, 255],
    'lightgoldenrodyellow' => [250, 250, 210],
    'lightgray'            => [211, 211, 211],
    'lightgreen'           => [144, 238, 144],
    'lightgrey'            => [211, 211, 211],
    'lightpink'            => [255, 182, 193],
    'lightsalmon'          => [255, 160, 122],
    'lightseagreen'        => [ 32, 178, 170],
    'lightskyblue'         => [135, 206, 250],
    'lightslategray'       => [119, 136, 153],
    'lightslategrey'       => [119, 136, 153],
    'lightsteelblue'       => [176, 196, 222],
    'lightyellow'          => [255, 255, 224],
    'lime'                 => [ 0,  255, 0],
    'limegreen'            => [ 50, 205, 50],
    'linen'                => [250, 240, 230],
    'magenta'              => [255, 0,   255],
    'maroon'               => [128, 0,   0],
    'mediumaquamarine'     => [102, 205, 170],
    'mediumblue'           => [ 0,  0,   205],
    'mediumorchid'         => [186, 85,  211],
    'mediumpurple'         => [147, 112, 219],
    'mediumseagreen'       => [ 60, 179, 113],
    'mediumslateblue'      => [123, 104, 238],
    'mediumspringgreen'    => [ 0,  250, 154],
    'mediumturquoise'      => [ 72, 209, 204],
    'mediumvioletred'      => [199, 21,  133],
    'midnightblue'         => [ 25, 25,  112],
    'mintcream'            => [245, 255, 250],
    'mistyrose'            => [255, 228, 225],
    'moccasin'             => [255, 228, 181],
    'navajowhite'          => [255, 222, 173],
    'navy'                 => [ 0,  0,   128],
    'oldlace'              => [253, 245, 230],
    'olive'                => [128, 128, 0],
    'olivedrab'            => [107, 142, 35],
    'orange'               => [255, 165, 0],
    'orangered'            => [255, 69,  0],
    'orchid'               => [218, 112, 214],
    'palegoldenrod'        => [238, 232, 170],
    'palegreen'            => [152, 251, 152],
    'paleturquoise'        => [175, 238, 238],
    'palevioletred'        => [219, 112, 147],
    'papayawhip'           => [255, 239, 213],
    'peachpuff'            => [255, 218, 185],
    'peru'                 => [205, 133, 63],
    'pink'                 => [255, 192, 203],
    'plum'                 => [221, 160, 221],
    'powderblue'           => [176, 224, 230],
    'purple'               => [128, 0,   128],
    'red'                  => [255, 0,   0],
    'rosybrown'            => [188, 143, 143],
    'royalblue'            => [ 65, 105, 225],
    'saddlebrown'          => [139, 69,  19],
    'salmon'               => [250, 128, 114],
    'sandybrown'           => [244, 164, 96],
    'seagreen'             => [ 46, 139, 87],
    'seashell'             => [255, 245, 238],
    'sienna'               => [160, 82,  45],
    'silver'               => [192, 192, 192],
    'skyblue'              => [135, 206, 235],
    'slateblue'            => [106, 90,  205],
    'slategray'            => [112, 128, 144],
    'slategrey'            => [112, 128, 144],
    'snow'                 => [255, 250, 250],
    'springgreen'          => [ 0,  255, 127],
    'steelblue'            => [ 70, 130, 180],
    'tan'                  => [210, 180, 140],
    'teal'                 => [ 0,  128, 128],
    'thistle'              => [216, 191, 216],
    'tomato'               => [255, 99,  71],
    'turquoise'            => [ 64, 224, 208],
    'violet'               => [238, 130, 238],
    'wheat'                => [245, 222, 179],
    'white'                => [255, 255, 255],
    'whitesmoke'           => [245, 245, 245],
    'yellow'               => [255, 255, 0],
    'yellowgreen'          => [154, 205, 50]
  }
  
  # Supported colors can be found at http://www.w3.org/TR/SVG/types.html#ColorKeywords
  def self.color_with_name(name)
    if W3_COLORS.keys.include?(name.to_s)
      colorWithDeviceRed_green_blue_alpha(*W3_COLORS[name.to_s] + [1])
    elsif name == "transparent"
      blackColor.colorWithAlphaComponent(0.0)
    elsif name[0..0] == "#"
      r = eval("0x"+name[1..2]) / 256.0
      g = eval("0x"+name[3..4]) / 256.0
      b = eval("0x"+name[5..6]) / 256.0
      colorWithDeviceRed_green_blue_alpha(r,g,b,1)
    end
  end
end
