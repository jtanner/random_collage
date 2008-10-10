require File.dirname(__FILE__) + '/../spec_helper'

describe IphotoImageList do
  
  before(:each) do
    @paths = IphotoImageList.image_paths(File.dirname(__FILE__))
  end
  
  it "should parse image paths from the iPhoto AlbumData.xml" do
    @paths.should have(12).paths
  end
  
  it "should use the modified path when available instead of the original" do
    @paths.select { |p| p.include?('Modified') }.should have(1).path
  end
  
end