require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/processor_shared_spec'

describe RmagickProcessor do
  
  before(:each) do
    @processor  = RmagickProcessor.new(:width => 1024, :height => 768)
    @ruby_image = RmagickProcessor.new(:path => ruby_image_path)
  end
  
  it_should_behave_like 'an image processor'
  
end