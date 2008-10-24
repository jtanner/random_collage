require File.dirname(__FILE__) + '/random_image_list'

class IphotoImageList < RandomImageList
  
  def iphoto
    @iphoto ||= @options[:input_dir].blank? ? IPhoto2.new : IPhoto2.new(File.expand_path(File.join(@options[:input_dir], 'AlbumData.xml')))
  end
  
  def image_paths
    from = parse_date_or_time(@options[:from])
    to   = parse_date_or_time(@options[:to])
    
    iphoto.library.images.map do |image|
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