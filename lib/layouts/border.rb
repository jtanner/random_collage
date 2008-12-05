class Border < Collage
  
  def place_photos(background, photos)
    background_photo = photos.delete(photos.detect { |photo| photo.width > photo.height }) || photos.pop
    @number_of_photos -= 1
    x, y = geometry_for(background_photo)
    x = x - (x / 4)
    y = y - (y / 4)
    background_photo.resize(width - (x * 2), height - (y * 2))
    background.composite(background_photo, x, y) # TODO put a border around background_photo (match polaroid border width)
    photos.each { |photo| place(background, photo) }
    background
  end
  
  def position(photo)
    x,y = random_position
    case closest_to(x,y)
    when :top
      y = 0 - (photo.height / 5)
      # x -= (cell_width(:x) / 3)
    when :bottom
      y = @height - photo.height - 15 # for polaroid border
      # x -= (cell_width(:x) / 3)
    when :left
      x = 0 - (photo.width / 5)
    when :right
      x = @width - photo.width - 15 # for polaroid border
    end
    [x.to_i,y.to_i]
  end
  
  def closest_to(x,y)
    case
    when y == 0
      :top
    when x == 0
      :left
    when y == (cell_width(:y) * ratio) - cell_width(:y)
      :bottom
    else
      :right
    end
  end
  
  def grid
    return @grid if @grid && !@grid.empty?
    @grid = []
    ratio.times do |x|
      ratio.times { |y| @grid << "#{x}.#{y}" if x == 0 || x == (ratio - 1) || y == 0 || y == (ratio - 1) }
    end
    @grid
  end
  
  def ratio
    @ratio ||= (@number_of_photos + 4) / 4
  end
  
end
