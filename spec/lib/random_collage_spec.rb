require File.dirname(__FILE__) + '/../spec_helper'

describe RandomCollage do
  
  before(:each) do
    @options = {:input_dir => spec_dir, :output_dir => spec_dir, :width => 300, :height => 300, :number_of_photos => 1}
    FileUtils.rm_f(Dir.glob("#{spec_dir}/#{Time.now.strftime("%Y%m%d%H")}*.jpg") << "#{spec_dir}/test.jpg")
  end
  
  it "should save a file" do
    RandomCollage.new(@options).save
    pictures = Dir.glob(spec_dir + "/#{Time.now.strftime("%Y%m%d%H")}*.jpg")
    pictures.should have(1).picture
  end
  
  it "should assign a caption" do
    photos = RandomCollage.new(@options.merge(:show_titles => true)).send(:photos)
    photos.first.caption.should == "Ruby"
  end
  
end