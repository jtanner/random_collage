require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/layout_shared_spec'

describe Border do
  
  before(:each) do
    @g = Border.new(
      :width            => 1280,
      :height           => 800,
      :angle            => 20,
      :number_of_photos => 30,
      :image_ratio      => 0.30
    )
    @photo = RmagickProcessor.new(:width => 125, :height => 100)
  end
  
  it_should_behave_like 'a layout'
  
  it "should only give random_positions around the edge of the grid" do
    positions = []
    28.times do
      x,y = @g.position(@photo)
      positions << [x,y]
      x.should_not be_nil
      x.should < 1280
      y.should_not be_nil
      y.should < 800
    end
    @g.grid.should == [
      "0.0", "0.1", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7",
      "1.0",                                           "1.7", 
      "2.0",                                           "2.7", 
      "3.0",                                           "3.7", 
      "4.0",                                           "4.7", 
      "5.0",                                           "5.7", 
      "6.0",                                           "6.7", 
      "7.0", "7.1", "7.2", "7.3", "7.4", "7.5", "7.6", "7.7"]
    positions.sort.should == [[-25, 100], [-25, 200], [-25, 300], [-25, 400], [-25, 500], [-25, 600], [-25, 700], [0, -20], [160, -20], [160, 685], [320, -20], [320, 685], [480, -20], [480, 685], [640, -20], [640, 685], [800, -20], [800, 685], [960, -20], [960, 685], [1120, -20], [1120, 685], [1140, 100], [1140, 200], [1140, 300], [1140, 400], [1140, 500], [1140, 600]]
  end
  
  it "should find whether x or y is closest to the edge" do
    @g.closest_to(0,0).should == :top
    @g.closest_to(0,200).should == :left
    @g.closest_to(200,0).should == :top
    @g.closest_to(1280 - @g.cell_width(:x),400).should == :right
    @g.closest_to(640,750).should == :right
  end
  
end