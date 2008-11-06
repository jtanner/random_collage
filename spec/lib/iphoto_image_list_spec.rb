require File.dirname(__FILE__) + '/../spec_helper'

describe IphotoImageList do
  
  before(:each) do
    @list = IphotoImageList.new
  end
  
  it "should parse image paths from the iPhoto AlbumData.xml" do
    @list.image_paths.should have(4).image_paths
  end
  
  it "should filter by date range" do
    @list.options[:from] = '2008-05-01'
    @list.options[:to] = Date.parse('2008-05-31')
    @list.image_paths.should have(1).path
    @list.options[:from] = '2008-01-02'
    @list.options[:to]   = '2008-01-05'
    @list.image_paths.should have(1).path
  end
  
  it "should filter by album" do
    @list.options[:albums] = ['an album']
    @list.image_paths.should have(2).paths
  end
  
  it "should filter by event" do
    pending
  end
  
end