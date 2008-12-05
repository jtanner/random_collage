require 'rubygems'
require 'active_support'
require 'pp'

def add_dir_to_load_path(dir)
  ActiveSupport::Dependencies.load_paths << File.expand_path(File.join(File.dirname(__FILE__) + '/' + dir))
end

%w[
  lib
  lib/layouts
  lib/processors
].each { |dir| add_dir_to_load_path(dir) }

#
# load files that active_support doesn't recognize
#
require 'lib/iphoto2.rb'
require 'lib/iphoto_image_list.rb'
