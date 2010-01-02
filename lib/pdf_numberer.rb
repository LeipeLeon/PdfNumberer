require 'logger'
require 'yaml'
require 'watcher'
require 'fileutils'
require 'pdf_processor'

class PdfNumberer

  PREFS_FILE = '~/.pdf_numberer'

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
    File.open(@config_file, 'w') { |f| f.print @prefs.to_yaml }
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
    Dir["#{dir}/*"].each do |item|
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
    logger.info "#{self.class}\t#{ordernumber}\t#{File.basename(pdf_file)}\tProcessing: #{pdf_file}"
    new_file = PdfProcessor.new(pdf_file, 
      :code        => create_code(pdf_file, ordernumber),
      :filename    => "new.pdf"
      # :savepath    => "#{ROOT}/../out"
    )
  end

  def create_code(pdf_file, ordernumber = 0)
    # {ordernumber}-{date}-{counter}-{filename}
    new_number = counter(ordernumber).to_s
    template = @prefs['orders'][ordernumber.to_i]
    template = @prefs['orders']["default"]

    template = replace_tag(template, 'ordernumber', "%07d" % ordernumber)
    template = replace_tag(template, 'date',        DateTime.now.strftime("%Y/%m/%d"))
    template = replace_tag(template, 'counter',     "%07d" % new_number)
    template = replace_tag(template, 'filename',    File.basename(pdf_file, '.pdf'))
    logger.info template
    template
  end

  def counter(ordernumber)
    if @prefs["counter"][ordernumber.to_i]
      @prefs["counter"][ordernumber.to_i] += 1
    else
      @prefs["counter"][ordernumber.to_i] = 1
    end
    save_prefs
    @prefs["counter"][ordernumber.to_i]
  end

  # def save_in_out_folder(file)
  #   logger.info "#{self.class}\tSaving PDF file #{file}"
  # end

  def move_to_processed_dir(pdf_file, ordernumber)
    if ENV['ENVIRONMENT'] == 'test'
      logger.info "#{self.class}\t(Sould move file, but we're in test)"
    else
      logger.info "#{self.class}\t#{ordernumber}\t#{File.basename(pdf_file)}\tmoving to processed (#{pdf_file})"
      FileUtils.mv(
        pdf_file, 
        File.expand_path(@prefs["folders"]["processed"], File.basename(pdf_file))
      )
    end
  end

  def replace_tag(template, tag, replace)
    matches = template.match(/\{#{tag}\}/)
    template.gsub!(/\{#{tag}\}/, replace.to_s) if matches
    template
  end
end

# if ARGV.include?('-h')
#   logger.info "#{self.class}\tUsage #{$0}:\n -p to post for real\n -d [postnumber] for ignoring \n -s Sync (fill local database)" 
#   exit
# end
