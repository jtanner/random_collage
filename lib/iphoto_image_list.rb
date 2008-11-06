require File.dirname(__FILE__) + '/random_image_list'

class IphotoImageList < RandomImageList
  
  def iphoto
    @iphoto ||= @options[:input_dir].blank? ? IPhoto2.new : IPhoto2.new(File.expand_path(File.join(@options[:input_dir], 'AlbumData.xml')))
  end
  
  def image_paths
    images = images_for_albums(@options[:albums] || [])
    images_for_range(images, parse_date_or_time(@options[:from]), parse_date_or_time(@options[:to]))
  end
  
  def images_for_albums(albums = [])
    albums.empty? ? iphoto.library.images : iphoto.albums.select { |a| albums.include?(a.name) }.map { |a| a.images }.flatten
  end
  
  def images_for_range(iphoto_images, from, to)
    iphoto_images.map do |image|
      qualified = false
      qualified = image.path =~ /(jpg|jpeg|gif|png)$/i
      if from && to
        qualified = image.created_at >= from && image.created_at <= to
      elsif from
        qualified = image.created_at >= from
      elsif to
        qualified = image.created_at <= to
      end
      image.path if qualified
    end.compact
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