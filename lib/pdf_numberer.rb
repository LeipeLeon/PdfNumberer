$LOAD_PATH << File.dirname(__FILE__)

require 'rubygems'
require 'logger'
require 'yaml'
require 'fileutils'
require 'watcher'
require 'pdf_processor'

class PdfNumberer

  PREFS_FILE = '~/pdf_numberer'

  attr :pdf
  attr :prefs
  attr :logger

  def initialize(config_file = PREFS_FILE)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @logger.level = Logger::DEBUG if ENV['DEBUG']
    @config_file = config_file
    read_prefs
  end

  def read_prefs
    if File.exists?(File.expand_path(@config_file))
      file = File.expand_path(@config_file)
      @prefs = YAML.load_file(file)
      check_prefs
    else
      raise "No such file! (#{@config_file})"
    end
  end

  def check_prefs
    raise "No watchfolder given."       if get_pref('options', 'folder_in') == nil
    raise "No outfolder given."         if get_pref('options', 'folder_out') == nil
    raise "No processed folder given."  if get_pref('options', 'folder_processed') == nil
  end

  def save_prefs
    return true if ENV['ENVIRONMENT'] == 'test'
    File.open(File.expand_path(@config_file), 'w') { |f| f.print @prefs.to_yaml }
  end

  def watch
    changed_folder = Watcher.folder(get_pref('options', 'folder_in'))
    traverse_subfolders(changed_folder)
  end

  def traverse_subfolders(folder)
    Dir["#{File.expand_path(folder)}/*"].each do |dir|
      ordernumber = File.basename(dir)
      if ordernumber =~ /^\d{7}$/
        logger.debug "#{self.class}:#{__LINE__}\tTraversing #{ordernumber} (#{dir})"
        process_folder_items(dir, ordernumber)
      else
        logger.warn "#{self.class}:#{__LINE__}\tWhat is this? (#{dir})"
      end
    end
  end

  def process_folder_items(dir, ordernumber = 0)
    Dir["#{dir}/*"].sort.each do |item|
      if item =~ /.pdf$/
        if process_pdf(item, ordernumber)
          move_to_processed_dir(item, ordernumber)
          logger.debug "#{self.class}:#{__LINE__}\t#{ordernumber}\t#{File.basename(item)}\tdone"
        end
      else
        logger.debug "#{self.class}:#{__LINE__}\tNot a PDF (#{item.inspect})"
      end
    end
  end

  def process_pdf(pdf_file, ordernumber = 0)
    logger.info "#{self.class}:#{__LINE__}\t[42;37;1m#{ordernumber}\t#{File.basename(pdf_file)}[0m\tProcessing..."
    savepath = prepare_out_folder(ordernumber)
    code, file_name = create_code(pdf_file, ordernumber)
    if file_name.length >= get_pref('options','max_filename_size')
      logger.warn "#{self.class}:#{__LINE__}\t[41;37;1m#{ordernumber}\t#{File.basename(pdf_file)}\tFilename to long? (#{file_name})[0m" 
    end
    new_file = PdfProcessor.new(pdf_file, 
      :code        => code,
      :filename    => file_name,
      :savepath    => savepath,
      :on_pages    => get_pref('options', 'on_pages', ordernumber),
      :rotation    => get_pref('options', 'rotation', ordernumber),
      :x           => get_pref('options', 'x', ordernumber),
      :y           => get_pref('options', 'y', ordernumber)
    )
  end

  def create_code(pdf_file, ordernumber = 0)
    # {ordernumber}-{date}-{counter}-{filename}
    new_number = counter(ordernumber.to_i).to_s

    res = []
    [ get_pref('options', 'code_format',     ordernumber).dup,
      get_pref('options', 'file_out_format', ordernumber).dup
    ].each do |template|
      template = replace_tag(template, 'ordernumber', "%07d" % ordernumber)
      template = replace_tag(template, 'date',        DateTime.now.strftime("%Y-%m-%d"))
      template = replace_tag(template, 'counter',     "%05d" % new_number)
      template = replace_tag(template, 'filename',    File.basename(pdf_file, '.pdf'))
      res << template
    end

    logger.debug "#{self.class}:#{__LINE__}\t#{ordernumber}\t#{File.basename(pdf_file)}\tCode: #{res.inspect}"
    res
  end

  def counter(ordernumber)
    if @prefs["counter"][ordernumber]
      @prefs["counter"][ordernumber] += 1
    else
      @prefs["counter"][ordernumber] = 1
    end
    save_prefs
    @prefs["counter"][ordernumber]
  end

  # def save_in_out_folder(file)
  #   logger.debug "#{self.class}:#{__LINE__}\tSaving PDF file #{file}"
  # end

  # INFO: Folders must be on the same filesystem
  def move_to_processed_dir(pdf_file, ordernumber)
    move_to = prepare_processed_folder(ordernumber)
    logger.debug "#{self.class}:#{__LINE__}\t#{ordernumber}\t#{File.basename(pdf_file)}\tmoving #{File.basename(pdf_file)} to #{move_to}"

    if ENV['ENVIRONMENT'] == 'test'
      logger.debug "#{self.class}:#{__LINE__}\t#{ordernumber}\t#{File.basename(pdf_file)}\t(Sould move file, but we're in test)"
    else
      FileUtils.mv(
        pdf_file, 
        File.join(File.expand_path(move_to), File.basename(pdf_file))
      )
    end
  end

  def replace_tag(template, tag, replace)
    matches = template.match(/\{#{tag}\}/)
    template.gsub!(/\{#{tag}\}/, replace.to_s) if matches
    template
  end

  def get_pref(scope, pref, ordernumber = nil)
    if @prefs[scope][ordernumber] && @prefs[scope][ordernumber][pref]
      @prefs[scope][ordernumber][pref]
    elsif @prefs[scope]['default'] && @prefs[scope]['default'][pref]
      @prefs[scope]['default'][pref]
    else
      raise ArgumentError, "[41;37;1m\n\n\nPreference file may be corrupt (missing #{scope}: #{ordernumber ? ordernumber : 'default' }: #{pref})\n\nSee\n#{File.dirname(__FILE__)}/spec/pref_file\nfor a sample pref file\n\n[0m"
    end
  end

protected
  def prepare_out_folder(ordernumber)
    move_to = File.join(File.expand_path(get_pref('options', 'folder_out')), ordernumber)
    FileUtils.mkdir(move_to) unless File.exists?(move_to)
    move_to
  end

  def prepare_processed_folder(ordernumber)
    move_to = File.join(File.expand_path(get_pref('options', 'folder_processed')), ordernumber)
    FileUtils.mkdir(move_to) unless File.exists?(move_to)
    move_to
  end

end

# if ARGV.include?('-h')
#   logger.debug "#{self.class}:#{__LINE__}\tUsage #{$0}:\n -p to post for real\n -d [postnumber] for ignoring \n -s Sync (fill local database)" 
#   exit
# end
