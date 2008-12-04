#!/usr/bin/env ruby
require 'rubygems'
require 'active_support'
require 'pp'

class RandomCollage
  
  DEFAULTS = {
    :width            => 1680,
    :height           => 1050,
    :image_ratio      => 0.35,
    :number_of_photos => 25,
    :angle            => 15,
    :background       => 'black',
    :layout           => 'collage',
    :show_titles      => false,
    :input_dir        => nil,
    :output_dir       => '~/Pictures/collages',
    :collages_to_keep => 20,
    :using_iphoto     => false,
    :from             => nil,
    :to               => nil,
    :albums           => nil,
    :events           => nil,
    :keywords         => nil
  }.freeze
  
  def initialize(options = {})
    @options = {}
    DEFAULTS.each { |k,v| @options[k] = options[k] || v }
    
    @options[:processor] = RmagickProcessor
  end
  
  def save
    final = layout.place_photos(background, photos)
    final = photo_background.composite(final, 0, 0) if photo_background
    final.save(File.join(File.expand_path(@options[:output_dir]), "#{Time.now.strftime("%Y%m%d%H%M%S")}.jpg"))
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
      @photo_background = photos.pop.resize(@options[:width], @options[:height])
      @options[:number_of_photos] -= 1
      @options[:background] = 'none'
    end
    @photo_background
  end
  
  # background_color = 'none' for a blank PNG
  def background
    return @background if @background
    photo_background # modifies the background option
    @background = @options[:processor].new(:color => @options[:background], :width => @options[:width], :height => @options[:height])
    @background.resize(@options[:width], @options[:height])
  end
  
  def remove_old_files
    return if @options[:collages_to_keep] == 'all'
    files = Dir.glob(File.expand_path(@options[:output_dir] + '/*')).sort.reverse[@options[:collages_to_keep].to_i..-1]
    files.each { |file| File.delete(file) } if files
  end

end
