require 'logger'
require 'PDFlib'
require 'pdf/utilities'

class PdfProcessor
  include Pdf::Utilities

  ROOT = File.expand_path(File.dirname(__FILE__))

  attr :pdf
  attr :logger

  def initialize(file, options={})
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @logger.level = Logger::DEBUG if ENV['DEBUG']
    set_options(options)

    @infile = File.expand_path(file)

    @pdf = PDFlib.new
    @pdf.set_parameter('license', 'X600605-009100-4658BC-16F263')

    static_file_name = File.join(File.expand_path(@savepath), @filename)
    logger.debug "#{self.class}\tOutfile: #{static_file_name}"
    @new_doc = @pdf.begin_document(static_file_name, "")
      raise "Error: " + @pdf.get_errmsg() if (@new_doc == -1)

      @searchpath.each { |path|
        @pdf.set_parameter("SearchPath", path)
      }

      @pdf.set_info("Creator", "VDA-groep")
      @pdf.set_info("Author",  "Leon Berenschot")
      @pdf.set_info("Title",   "PdfNumberer")

      logger.debug "#{self.class}\tProcessing: #{@infile}"
      @doc = @pdf.open_pdi(@infile, "", 0)
        raise "Error: " + @pdf.get_errmsg() if (@doc == -1)
        page_count = @pdf.get_pdi_value('/Root/Pages/Count', @doc, -1, 0)
        1.step(page_count, 1) do |page_counter|
          @page = @pdf.open_pdi_page(@doc, page_counter, "")
            raise "Error: " + @pdf.get_errmsg() if (@page == -1)
            # Establish coordinates with the origin in the upper left corner.
            @pdf.begin_page_ext(@pagewidth, @pageheight, "topdown")
              @pdf.fit_pdi_page(@page, 0, @pageheight, "")
              @pdf.setfont(@pdf.load_font(@regularfont, "winansi", "embedding"), @fontsize)
              @pdf.set_value("leading", @leading)

              make_grid if ENV['DEBUG']

              if @on_pages.include?(page_counter)
                # @rotation   = options[:rotation]
                @pdf.save
                @pdf.setcolor("fill", "cmyk", 0.0, 0.0, 0.0, 1)
                @pdf.translate(@position[:x], @position[:y])
                @pdf.rotate(@rotation) if @rotation != 0
                @pdf.show(@code)
                @pdf.restore

                # @pdf.continue_text(@customer.email)
                # @pdf.setcolor("fill", "cmyk", 0.0, 0, 1, 0)
                # @pdf.show_xy("#{@customer.first_name} #{@customer.last_name}", 60-2, y-2)
                # @pdf.continue_text(@customer.email)
              end
            @pdf.end_page_ext("")
          @pdf.close_pdi_page(@page)
        end
      @pdf.close_pdi(@doc)
    @pdf.end_document("")

  end

protected
  def set_options(options = {})
    options = {
      :pagewidth   => 595, # A4
      :pageheight  => 842, # A4
      :searchpath  => ["#{ROOT}/fonts","#{ROOT}/templates"],
      :filename    => "out.pdf",
      :savepath    => "#{ROOT}/../out",
      :boldfont    => "ocraext", 
      :regularfont => "ocraext", 
      :fontsize    => 8, 
      :leading     => 10,
      :pageparams  => "bleedbox {-3 -3 601 848}", # A4
      :bleedbox    => "bleedbox {-3 -3 601 848}", # A4
      :x           => 216,
      :y           => 720,
      :code        => 'CODE',
      :rotation    => 0,
      :on_pages    => [1]
    }.merge(options)

    # setting defaults
    @pagewidth  = options[:pagewidth]
    @pageheight = options[:pageheight]
    @searchpath = options[:searchpath]
    @filename   = options[:filename]
    @savepath   = options[:savepath]
    @regularfont   = options[:regularfont]
    @boldfont   = options[:boldfont]

    @fontsize   = options[:fontsize]
    @leading    = options[:leading]
    @pageparams = options[:pageparams]
    @bleedbox   = options[:bleedbox]

    @template   = options[:template]
    @position   = {
      :x => options[:x],
      :y => options[:y]
    }
    @rotation   = options[:rotation]
    @on_pages   = options[:on_pages]

    @code = options[:code]

    # list of encodings to use
    @encodings = ["iso8859-1", "iso8859-2", "iso8859-15"]
  end

end