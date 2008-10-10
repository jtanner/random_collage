require File.dirname(__FILE__) + '/random_image_list'

class IphotoImageList < RandomImageList
  
  def self.image_paths(path_to_iphoto_library)
    data_file = File.read(File.expand_path(File.join(path_to_iphoto_library, 'AlbumData.xml')))
    paths = data_file.scan(/^<key>ImagePath<\/key>\n<string>(.*?)<\/string>$/).flatten
    paths.delete_if { |path| !(path =~ /(jpg|jpeg|gif|png)$/i) }
  end
  
end