require File.dirname(__FILE__) + '/collage'

class Border < Collage
  
  def position(photo)
    x,y = random_position
    case closest_to(x,y)
    when :top
      y = 0 - (photo.height / 5)
    when :bottom
      y = @height - photo.height - 15 # for polaroid border
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
    @ratio ||= @number_of_photos / 4
  end
  
end
