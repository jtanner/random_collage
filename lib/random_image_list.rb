module RandomImageList
  def self.image_paths(path)
    Dir.glob(File.expand_path(File.join(path,"*.{jpg,jpeg,gif,png}")))
  end
  
  def self.random(path, count)
    image_paths(path).sort_by { rand }[0...count.to_i]
  end
  
  def self.random_image_list(path, count)
    list = Magick::ImageList.new
    count = range_rand(count.first, count.last) if count.is_a?(Range)
    random(path, count).each { |image_path| list.read(image_path) }
    list
  end
  
  def self.range_rand(min,max)
    min + rand(max-min)
  end
  
end