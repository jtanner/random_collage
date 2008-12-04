describe 'a layout', :shared => true do
  
  it "should place photos" do
    # just make sure it doesn't raise (I don't like the lambda approach)
    @g.place_photos(RmagickProcessor.new(:width => 200, :height => 200), [@photo])
  end
  
end