require File.dirname(__FILE__) + '/../../spec_helper'

describe Border do
  
  before(:each) do
    @g = Border.new(
      :width            => 1280,
      :height           => 800,
      :angle            => 20,
      :number_of_photos => 30,
      :image_ratio      => 0.30
    )
    @photo = Magick::Image.new(125,100)
  end
  
  it "should place photos" do
    list = Magick::ImageList.new
    list << @photo
    lambda { @g.place_photos(Magick::Image.new(200,200), list) }.should_not raise_error
  end
  
  it "should only give random_positions around the edge of the grid" do
    positions = []
    24.times do
      x,y = @g.position(@photo)
      positions << [x,y]
      x.should_not be_nil
      x.should < 1280
      y.should_not be_nil
      y.should < 800
    end
    @g.grid.should == [
      "0.0", "0.1", "0.2", "0.3", "0.4", "0.5", "0.6",
      "1.0",                                    "1.6", 
      "2.0",                                    "2.6", 
      "3.0",                                    "3.6", 
      "4.0",                                    "4.6", 
      "5.0",                                    "5.6", 
      "6.0", "6.1", "6.2", "6.3", "6.4", "6.5", "6.6"]
    positions.sort.should == [[-25, 114], [-25, 228], [-25, 342], [-25, 456], [-25, 570], [-25, 684], [0, -20], [182, -20], [182, 720], [364, -20], [364, 720], [546, -20], [546, 720], [728, -20], [728, 720], [910, -20], [910, 720], [1092, -20], [1092, 720], [1180, 114], [1180, 228], [1180, 342], [1180, 456], [1180, 570]]
  end
  
  it "should find whether x or y is closest to the edge" do
    @g.closest_to(0,0).should == :top
    @g.closest_to(0,200).should == :left
    @g.closest_to(200,0).should == :top
    @g.closest_to(1280 - @g.cell_width(:x),400).should == :right
    @g.closest_to(640,750).should == :right
  end
  
end