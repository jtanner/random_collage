class Collage
  attr_accessor :width, :height, :angle, :image_ratio, :number_of_photos
  
  def initialize(options)
    @width            = options[:width]
    @height           = options[:height]
    @angle            = options[:angle]
    @image_ratio      = options[:image_ratio]
    @number_of_photos = options[:number_of_photos]
  end
  
  def place_photos(background, photos)
    photos.each { |photo| place(background, photo) }
    background
  end
  
  def place(background, photo)
    shrunken_photo = photo.shrink(*geometry_for(photo))
    x,y = position(shrunken_photo)
    puts format("Placing photo @ %5s x %-5s", x, y)
    background.composite(shrunken_photo.polaroid(random_angle), x, y)
  end
  
  def geometry_for(photo)
    ratio = image_ratio
    if photo.width - photo.height > 0
      [(@width * ratio).to_i, (@height * ratio).to_i]
    else
      [(@height * ratio).to_i, (@width * ratio).to_i]
    end
  end
    
  def image_ratio
    @image_ratio.is_a?(Range) ? float_range_rand(@image_ratio.first, @image_ratio.last) : @image_ratio
  end
  
  def grid
    return @grid if @grid
    @grid = []
    ratio.times do |x|
      ratio.times { |y| @grid << "#{x}.#{y}" }
    end
    @grid
  end
  
  def full?
    grid.empty?
  end
  
  def ratio
    @ratio ||= Math.sqrt(@number_of_photos).floor
  end
  
  def cell_width(axis)
    case axis
    when :x
      @x_size ||= @width  / ratio
    when :y
      @y_size ||= @height / ratio
    end
  end
  
  def random_angle
    rand(@angle * 2) - @angle
  end
  
  def position(photo)
    offset_position(photo, random_position)
  end
  
  def random_position
    x_index, y_index = if full?
      [rand(ratio), rand(ratio)]
    else
      grid.delete(grid.sort_by { rand }.pop).split('.').map { |e| e.to_i }
    end
    x = (cell_width(:x) * (x_index + 1)) - cell_width(:x)
    y = (cell_width(:y) * (y_index + 1)) - cell_width(:y)
    [x.to_i, y.to_i]
  end
  
  #   ________________________
  #   |#######| <- possible  |
  #   |#######|    position  |
  #   |#######|______________|
  #   |       |              |
  #   |       |   photo or   |
  #   |       |   grid box   |
  #   |       |              |
  #   |_______|______________|
  # 
  def offset_position(photo, position)
    x,y = position
    possible_x = cell_width(:x) - photo.width
    possible_y = cell_width(:y) - photo.height
    new_x = x + rand(possible_x.abs + 1) * (possible_x < 0 ? -1 : 1)
    new_y = y + rand(possible_y.abs + 1) * (possible_y < 0 ? -1 : 1)
    [new_x.to_i, new_y.to_i]
  end
  
  # a plus or minus random value
  def rand_minus(value)
    plus_or_minus = rand(2) == 1 ? 1 : -1
    plus_or_minus * rand(value)
  end
  
  def float_range_rand(min,max)
    ((min * 1000).to_i + rand((max * 1000).to_i - (min * 1000).to_i)) / 1000.0
  end
  
end
