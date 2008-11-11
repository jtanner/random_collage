require File.dirname(__FILE__) + '/../spec_helper'

describe IphotoImageList do
  
  before(:each) do
    @list = IphotoImageList.new(:input_dir => File.dirname(__FILE__))
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
  
  it "should filter by events" do
    @list.options[:events] = ['Dec 25, 2007']
    @list.image_paths.should have(1).path
  end
  
  it "should filter by keywords" do
    @list.options[:keywords] = ['Nature']
    @list.image_paths.should have(2).paths
    @list.options[:keywords] = ['Christmas']
    @list.image_paths.should have(1).path
  end
  
end