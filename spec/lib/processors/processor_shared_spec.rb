def ruby_image_path
  @ruby_image_path ||= File.dirname(__FILE__) + '/../../ruby.jpg'
end

# To use this shared describe declare the following variables:
#   @ruby_image: An instance of the processer (an image)
#   @processer:  An instance of the image at ruby_image_path()
describe 'an image processor', :shared => true do
  
  %w[
    image
    color
    width
    height
    save
    composite
    crop_to_fit
    scale_to_fit
    polaroid
    caption
    filename
  ].each do |required_method|
    it "should have the #{required_method} method" do
      @processor.should respond_to(required_method)
    end
  end
  
  it "should create a new image of a certain size" do
    img = @processor.class.new(:width => 640, :height => 480)
    img.width.should == 640
    img.height.should == 480
  end
  
  it "should create a new image with an optional color" do
    img = @processor.class.new(:width => 640, :height => 480, :color => 'black')
    img.color.should == 'black'
  end
  
  it "should create a new image from a path" do
    img = @processor.class.new(:path => ruby_image_path)
    img.width.should  == 100
    img.height.should == 100
  end
  
  it "should raise an error if a size or path is not provided" do
    lambda { @processor.class.new }.should raise_error(ArgumentError)
  end
  
  it "should take path over width and height" do
    img = @processor.class.new(:width => 640, :height => 480, :path => ruby_image_path)
    img.width.should == 100
  end
  
  it "should composite another image" do
    img = @processor.composite(@ruby_image, 200, 300)
    img.width.should == 1024
  end
  
  it "should crop_to_fit" do
    img = @processor.crop_to_fit(300,200)
    img.width.should  == 300
    img.height.should == 200
  end
  
  it "should scale_to_fit" do
    img = @processor.scale_to_fit(300,200)
    img.width.should  == 267
    img.height.should == 200
  end
  
  it "should do a polaroid effect" do
    width  = @ruby_image.width
    height = @ruby_image.height
    lambda { @ruby_image.polaroid }.should_not raise_error
    img = @ruby_image.polaroid(20)
    img.width.should  > width
    img.height.should > height
  end
  
  it "should save (a red square) to disk" do
    test_path = spec_dir + '/test.jpg'
    FileUtils.rm_f(test_path)
    img = @processor.class.new(:width => 50, :height => 50, :color => 'red')
    img.save(test_path)
    saved = @processor.class.new(:path => test_path)
    saved.width.should  == img.width
    saved.height.should == img.height
  end
  
  it "should save a resized ruby.jpg to disk" do
    test_path = spec_dir + '/test.jpg'
    FileUtils.rm_f(test_path)
    img = @processor.class.new(:path => ruby_image_path)
    img.crop_to_fit(75, 50)
    img.save(test_path)
    saved = @processor.class.new(:path => test_path)
    saved.width.should  == 75
    saved.height.should == 50
  end
  
  it "should add a border"
  
  it "should add a caption" do
    @ruby_image.caption = "Ruby!"
    @ruby_image.caption.should == "Ruby!"
  end
  
end