require File.dirname(__FILE__) + '/../../spec_helper'

describe Collage do
  
  before(:each) do
    @g = Collage.new(
      :width            => 200,
      :height           => 200,
      :angle            => 25,
      :number_of_photos => 1,
      :image_ratio      => 0.3
    )
    @photo = Magick::Image.new(125,100)
  end
  
  it "should place photos" do
    list = Magick::ImageList.new
    list << @photo
    lambda { @g.place_photos(Magick::Image.new(200,200), list) }.should_not raise_error
  end
  
  it "should flip flop new_geometry based on the layout of the photo" do
    @g.width = 1280
    @g.height = 800
    @g.stub!(:image_ratio).and_return(0.3)
    vertical = Magick::Image.new(100,125)
    square   = Magick::Image.new(100,100)
    @g.geometry_for(@photo).should   == "384x240"
    @g.geometry_for(vertical).should == "240x384"
    @g.geometry_for(square).should   == "240x384"
  end
  
  it "should only give random_positions within the width and height" do
    lower = -90
    upper = 10
    20.times do
      @g.random_position.each do |axis|
        axis.should be_between(lower,upper)
      end
    end
  end
  
  it "should not choose the same position unless the grid is empty" do
    20.times { @g.random_position }
    @g.instance_variable_get('@grid').should == []
  end
  
  it "should give random_position within the photo bounds or the grid position bounds, whichever is larger" do
    # small photo
    10.times do
      x,y = @g.position(@photo)
      (0..75).should include(x)
      (0..100).should include(y)
    end
    # large photo
    photo = Magick::Image.new(300,250)
    10.times do
      x,y = @g.position(photo)
      (-100..0).should include(x)
      (-50..0).should include(y)
    end
  end
  
end