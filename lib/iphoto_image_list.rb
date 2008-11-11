require File.dirname(__FILE__) + '/random_image_list'

class IphotoImageList < RandomImageList
  
  def iphoto
    @iphoto ||= @options[:input_dir].blank? ? IPhoto2.new : IPhoto2.new(File.expand_path(File.join(@options[:input_dir], 'AlbumData.xml')))
  end
  
  def image_paths
    images = images_for(:albums, @options[:albums]) | images_for(:events, @options[:events])
    images = iphoto.library.images if images.empty?
    images = filter_by_keywords(images, @options[:keywords]) if @options[:keywords]
    images = filter_by_date_range(images, parse_date_or_time(@options[:from]), parse_date_or_time(@options[:to]))
    images.map { |i| i.path }
  end
  
  # albums, events, rolls
  def images_for(method, names = nil)
    names ? iphoto.send(method).select { |a| names.include?(a.name) }.map { |a| a.images }.flatten : []
  end
  
  def filter_by_keywords(iphoto_images, keywords)
    iphoto_images.reject { |i| (i.keywords & keywords).empty? }
  end
  
  def filter_by_date_range(iphoto_images, from, to)
    iphoto_images.select do |image|
      qualified = false
      qualified = image.path =~ /(jpg|jpeg|gif|png)$/i
      if from && to
        qualified = image.created_at >= from && image.created_at <= to
      elsif from
        qualified = image.created_at >= from
      elsif to
        qualified = image.created_at <= to
      end
      qualified
    end
  end
  
private
  def parse_date_or_time(str)
    if str.is_a?(String)
      str =~ /\d\d:\d\d:\dd$/ ? Time.parse(str) : Date.parse(str)
    else
      str
    end
  end
  
end