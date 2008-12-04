class RandomImageList
  
  attr_reader :options
  
  def initialize(options = {})
    @options = options
  end
  
  def random_image_list
    count = @options[:number_of_photos]
    count = range_rand(count.first, count.last) if count.is_a?(Range)
    @options[:number_of_photos] = count
    random(count).map { |image_path| @options[:processor].new(:path => File.expand_path(image_path)) }
  end
  
protected
  
  def image_paths
    Dir.glob(File.expand_path(File.join(@options[:input_dir], '**', '*.{jpg,jpeg,gif,png}')), File::FNM_CASEFOLD)
  end
  
  def random(count)
    image_paths.sort_by { rand }[0...count.to_i]
  end
  
  def range_rand(min, max)
    min + rand(max - min)
  end
  
end