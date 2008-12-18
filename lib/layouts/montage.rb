class Montage < Collage
  def place(background, photo)
    scaled_photo = photo.crop_to_fit(cell_width(:x), cell_width(:y))
    x,y = position(scaled_photo)
    puts format("Placing photo @ %5s x %-5s", x, y)
    background.composite(scaled_photo, x, y)
  end
  
  def grid
    return @grid if @grid
    width_height_ratio = @width / @height.to_f
    num_photos = @number_of_photos
    @factor_pair = []
    while num_photos > 0
      factors = possible_factors(num_photos)
      # find the closest factor pair to the width_height_ratio
      @factor_pair = factors.sort_by { |f| ((f[0] / f[1].to_f) - width_height_ratio).abs }.first
      ratio_diff_percent = (width_height_ratio - (@factor_pair[0] / @factor_pair[1].to_f)) / width_height_ratio
      if ratio_diff_percent > 0.5
        num_photos -= 1
      else
        break
      end
    end
    @grid = []
    @factor_pair[0].times do |x|
      @factor_pair[1].times { |y| @grid << "#{x}.#{y}" }
    end
    @grid
  end
  
  def factor_pair
    grid
    @factor_pair
  end
  
  def cell_width(axis)
    grid
    case axis
    when :x
      @x_size ||= @width  / factor_pair.first
    when :y
      @y_size ||= @height / factor_pair.last
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
