require 'yaml'
require 'watcher'
require 'fileutils'
require 'pdf_processor'

class PdfNumberer

  PREFS_FILE = '~/.pdf_numberer'

  attr :pdf
  attr :prefs

  def initialize(config_file = PREFS_FILE)
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
    File.open(@config_file, 'w') { |f| f.puts @prefs.to_yaml }
  end

  def watch
    changed_folder = Watcher.folder(@prefs["folders"]["in"])
    traverse_subfolders(changed_folder)
  end

  def traverse_subfolders(folder)
    Dir["#{File.expand_path(folder)}/*"].each do |dir|
      if File.basename(dir) =~ /^\d{7}$/
        puts "Processing: #{dir}"
        process_folder_items(dir)
      else
        puts "What is this? (#{dir})"
      end
    end
  end

  def process_folder_items(dir)
    Dir["#{dir}/*"].each do |item|
      if item =~ /.pdf$/
        if process_pdf(item)
          puts "\tdone"
        end
      else
        puts "\tNot a PDF (#{item.inspect})"
      end
    end
  end

  def process_pdf(pdf_file)
    # pdf = PDFlib.new
    puts "\tProcessing #{pdf_file}"
    new_file = PdfProcessor.new(pdf_file)
    new_file.make_code('123123123')
    save_in_out_folder(new_file)
  end

  def save_in_out_folder(file)
    puts "\t\tSaving PDF file #{file}"
  end

  # def move_to_out_folder(pdf_file)
  #   if ENV['ENVIRONMENT'] == 'test'
  #     puts "\t\t(Sould move file, but we're in test)"
  #   else
  #     FileUtils.mv(
  #       pdf_file, 
  #       File.expand_path(@prefs["folders"]["out"], File.basename(pdf_file))
  #     )
  #   end
  # end
end

# if ARGV.include?('-h')
#   puts "Usage #{$0}:\n -p to post for real\n -d [postnumber] for ignoring \n -s Sync (fill local database)" 
#   exit
# end
