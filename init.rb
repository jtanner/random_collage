def require_all_files_in_folder(folder, extension = "*.rb")
  for file in Dir[File.expand_path(File.join(File.dirname(__FILE__), folder, "**/#{extension}"))]
    require file
  end
end

require_all_files_in_folder('lib')
