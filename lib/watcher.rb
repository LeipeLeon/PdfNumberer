$LOAD_PATH << File.dirname(__FILE__)
require 'rubygems'
require 'logger'

class Watcher
  attr :logger
  def initialize
    @logger = Logger.new(STDERR)
  end

  def self.folder(folder)
    # logger.info "#{self.class}:#{__LINE__}\t#{File.expand_path(folder).inspect}"
    if File.exists?(File.expand_path(folder))
      %x[#{File.join( File.expand_path(File.dirname(__FILE__) + '/..'), 'bin', 'fsevent_sleep')} '#{File.expand_path(folder)}' 2>&1]

      # force a sleep for size * 10 milliseconds
      Dir["#{File.expand_path(folder)}/*"].each do |dir|
        sleep Dir["#{dir}/*"].size / 100.0
      end

      folder
    else
      raise ArgumentError, "Watchfolder doesn't exist (#{folder})"
    end
  end
end

