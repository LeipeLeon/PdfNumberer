class Watcher
  def self.folder(folder)
    puts File.expand_path(folder).inspect
    if File.exists?(File.expand_path(folder))
      `#{File.join( File.expand_path(File.dirname(__FILE__) + '/..'), 'bin', 'fsevent_sleep')} '#{File.expand_path(folder)}' 2>&1`
      folder
    end
  end
end

