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
    raise "No watchfolder given." if @prefs["folders"]["in"] == nil
  end

  def save_prefs
    return true if ENV['ENVIRONMENT'] == 'test'
    File.open(File.expand_path(@config_file), 'w') { |f| f.print @prefs.to_yaml }
  end

  def watch
    changed_folder = Watcher.folder(@prefs["folders"]["in"])
    traverse_subfolders(changed_folder)
  end

  def traverse_subfolders(folder)
    Dir["#{File.expand_path(folder)}/*"].each do |dir|
      ordernumber = File.basename(dir)
      if ordernumber =~ /^\d{7}$/
        logger.info "#{self.class}\tTraversing #{ordernumber} (#{dir})"
        process_folder_items(dir, ordernumber)
      else
        logger.warn "#{self.class}\tWhat is this? (#{dir})"
      end
    end
  end

  def process_folder_items(dir, ordernumber = 0)
    Dir["#{dir}/*"].sort.each do |item|
      if item =~ /.pdf$/
        if process_pdf(item, ordernumber)
          move_to_processed_dir(item, ordernumber)
          logger.info "#{self.class}\t#{ordernumber}\t#{File.basename(item)}\tdone"
        end
      else
        logger.info "#{self.class}\tNot a PDF (#{item.inspect})"
      end
    end
  end

  def process_pdf(pdf_file, ordernumber = 0)
    logger.info "#{self.class}\t[41;37;1m#{ordernumber}\t#{File.basename(pdf_file)}[0m\tProcessing: #{pdf_file}"
    savepath = prepare_out_folder(ordernumber)
    code = create_code(pdf_file, ordernumber)
    new_file = PdfProcessor.new(pdf_file, 
      :code        => code,
      :filename    => "#{code}.pdf",
      :savepath    => savepath,
      :on_pages    => [1,5]
    )
  end

  def create_code(pdf_file, ordernumber = 0)
    # {ordernumber}-{date}-{counter}-{filename}
    new_number = counter(ordernumber.to_i).to_s

    template = @prefs['orders'][ordernumber.to_i].dup if @prefs['orders'][ordernumber.to_i]
    template = @prefs['orders']["default"].dup unless template

    template = replace_tag(template, 'ordernumber', "%07d" % ordernumber)
    template = replace_tag(template, 'date',        DateTime.now.strftime("%Y-%m-%d"))
    template = replace_tag(template, 'counter',     "%07d" % new_number)
    template = replace_tag(template, 'filename',    File.basename(pdf_file, '.pdf'))
    logger.info "#{self.class}\t#{ordernumber}\t#{File.basename(pdf_file)}\tCode: #{template}"
    template
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
  #   logger.info "#{self.class}\tSaving PDF file #{file}"
  # end

  def move_to_processed_dir(pdf_file, ordernumber)
    move_to = prepare_processed_folder(ordernumber)
    logger.info "#{self.class}\t#{ordernumber}\t#{File.basename(pdf_file)}\tmoving #{File.basename(pdf_file)} to #{move_to}"

    if ENV['ENVIRONMENT'] == 'test'
      logger.info "#{self.class}\t#{ordernumber}\t#{File.basename(pdf_file)}\t(Sould move file, but we're in test)"
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

protected
  def prepare_out_folder(ordernumber)
    move_to = File.join(File.expand_path(@prefs["folders"]["out"]), ordernumber)
    FileUtils.mkdir(move_to) unless File.exists?(move_to)
    move_to
  end

  def prepare_processed_folder(ordernumber)
    move_to = File.join(File.expand_path(@prefs["folders"]["processed"]), ordernumber)
    FileUtils.mkdir(move_to) unless File.exists?(move_to)
    move_to
  end

end

# if ARGV.include?('-h')
#   logger.info "#{self.class}\tUsage #{$0}:\n -p to post for real\n -d [postnumber] for ignoring \n -s Sync (fill local database)" 
#   exit
# end
