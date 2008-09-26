require File.dirname(__FILE__) + '/collage'

class Mosaic < Collage
  def place_photos(background, photos)
    photos.each { |photo| photo.crop_resized!(cell_width(:x), cell_width(:y), Magick::NorthGravity) }
    $geometry = "#{cell_width(:x)}x#{cell_width(:y)}+0+0"
    $tile = "#{grid.first}x#{grid.last}"
    puts "Mosaic of #{grid.first} x #{grid.last} with cell size of #{cell_width(:x)} x #{cell_width(:y)}"
    photos.collage do
      self.geometry = $geometry
      self.tile = $tile
      self.border_width = 2
      self.background_color = 'none'
      self.border_color = 'white'
    end
  end
  
  def grid
    return @grid if @grid
    width_height_ratio = @width / @height.to_f
    num_photos = @number_of_photos
    while num_photos > 0
      factors = possible_factors(num_photos)
      # find the closest factor pair to the width_height_ratio
      @grid = factors.sort_by { |f| ((f[0] / f[1].to_f) - width_height_ratio).abs }.first
      ratio_diff_percent = (width_height_ratio - (@grid[0] / @grid[1].to_f)) / width_height_ratio
      if ratio_diff_percent > 0.5
        num_photos -= 1
      else
        break
      end
    end
    @grid
  end
  
  def cell_width(axis)
    case axis
    when :x
      @x_size ||= @width  / grid.first
    when :y
      @y_size ||= @height / grid.last
    end
  end
  
  # if num_photos is 20
  # then factors will be [[20, 1], [10, 2], [5, 4], [4, 5], [2, 10], [1, 20]]
  def possible_factors(num_photos)
    numbers = []
    num_photos.downto(1) { |i| numbers << i }
    factors = numbers.map do |i|
      num = numbers.detect { |ii| i*ii == num_photos }
      [i, num] if num
    end
    factors.compact!
    factors.empty? ? [[1,1]] : factors
  end
end
