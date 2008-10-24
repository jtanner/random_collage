#!/usr/bin/env ruby
require 'rubygems'
require 'active_support'
require 'RMagick'
require 'pp'

class RandomCollage
  
  VALID_KEYS = [
    :width,
    :height,
    :image_ratio,
    :number_of_photos,
    :angle,
    :background,
    :layout,
    :show_titles,
    :input_dir,
    :output_dir,
    :collages_to_keep,
    :using_iphoto,
    :from,
    :to
  ].freeze
  
  def initialize(options = {})
    options.assert_valid_keys(VALID_KEYS)
    @options = {}
    options.each { |k,v| @options[k.to_sym] = v }
  end
  
  def write!
    final = layout.place_photos(background, photos)
    final = photo_background.composite(final, 0, 0, Magick::OverCompositeOp) if photo_background
    final.write(File.join(File.expand_path(@options[:output_dir]), "#{Time.now.strftime("%Y%m%d%H%M%S")}.jpg"))
    remove_old_files
  end
  
private
  
  def layout
    @layout ||= @options[:layout].classify.constantize.new(@options)
  end
  
  def image_list_class
    if @options[:using_iphoto]
      IphotoImageList
    else
      RandomImageList
    end
  end
  
  def photos
    return @photos if @photos
    @photos = image_list_class.new(@options).random_image_list
    if @photos.empty?
      puts "No photos were found in #{@options[:input_dir]}"
      exit(1)
    end
    @options[:number_of_photos] = @photos.size
    @photos.each { |p| p[:Caption] = p.filename.scan(/.*?([^\.\/]+)\.\w+/).to_s.titleize } if @options[:show_titles]
    @photos
  end
  
  def photo_background
    return @photo_background if @photo_background
    if @options[:background] == 'photo'
      @photo_background = photos.pop.crop_resized!(@options[:width], @options[:height], Magick::NorthGravity)
      @options[:number_of_photos] -= 1
      @options[:background] = 'none'
    end
    @photo_background
  end
  
  # background_color = 'none' for a blank PNG
  def background
    return @background if @background
    photo_background # modifies the background option
    color = @options[:background]
    @background = Magick::Image.new(@options[:width], @options[:height]) { self.background_color = color; self.depth = 8 }
  end
  
  def remove_old_files
    return if @options[:collages_to_keep] == 'all'
    files = Dir.glob(File.expand_path(@options[:output_dir] + '/*')).sort.reverse[@options[:collages_to_keep].to_i..-1]
    files.each { |file| File.delete(file) } if files
  end

end
