require File.dirname(__FILE__) + '/../../spec_helper'

describe Mosaic do
  
  before(:each) do
    @g = Mosaic.new(
      :width            => 200,
      :height           => 200,
      :angle            => 20,
      :number_of_photos => 1,
      :image_ratio      => 0.30
    )
    @photo = Magick::Image.new(125,100)
  end
  
  it "should place photos" do
    list = Magick::ImageList.new
    list << @photo
    lambda { @g.place_photos(Magick::Image.new(200,200), list) }.should_not raise_error
  end

  it "should generate a grid close to the aspect ratio and number of photos" do
    # [[1920,1000], [1600,1064], [1280,1024], [1280,800], [800,600]].each do |width,height|
    [[1280,800]].each do |width,height|
      30.downto(5) do |i|
        grid = Mosaic.new(:width => width, :height => height, :number_of_photos => i).grid
        width_height_ratio = width / height.to_f
        ratio_diff_percent = (width_height_ratio - (grid[0] / grid[1].to_f)) / width_height_ratio
        ratio_diff_percent.should_not > 0.5
        i.should >= grid[0] * grid[1]
      end
    end
  end
  
  it "should find possible factors" do
    m = Mosaic.new({})
    m.possible_factors(1).should == [[1, 1]]
    m.possible_factors(15).should == [[15, 1], [5, 3], [3, 5], [1, 15]]
    m.possible_factors(16).should == [[16, 1], [8, 2], [4, 4], [2, 8], [1, 16]]
    m.possible_factors(20).should == [[20, 1], [10, 2], [5, 4], [4, 5], [2, 10], [1, 20]]
  end
  
end