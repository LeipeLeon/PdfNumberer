$LOAD_PATH << File.dirname(__FILE__)
require 'rubygems'
require 'logger'

class Watcher
  attr :logger
  def initialize
    @logger = Logger.new(STDERR)
  end

  def self.folder(folder)
    # logger.info "#{self.class}\t#{File.expand_path(folder).inspect}"
    if File.exists?(File.expand_path(folder))
      `#{File.join( File.expand_path(File.dirname(__FILE__) + '/..'), 'bin', 'fsevent_sleep')} '#{File.expand_path(folder)}' 2>&1`
      folder
    else
      raise "Watchfolder doen't exist (#{folder})"
    end
  end
end

