require 'logger'
require 'PDFlib'
class PdfProcessor
  ROOT = File.expand_path(File.dirname(__FILE__))

  attr :pdf
  attr :logger

  def initialize(file, options={})
    @logger = Logger.new(STDOUT)
    set_options(options)

    @infile = File.expand_path(file)

    @pdf = PDFlib.new
    @pdf.set_parameter('license', 'X600605-009100-4658BC-16F263')

    static_file_name = File.join(File.expand_path(@savepath), @filename)
    logger.info "#{self.class}\tOutfile: #{static_file_name}"
    @new_doc = @pdf.begin_document(static_file_name, "")
      raise "Error: " + @pdf.get_errmsg() if (@new_doc == -1)

      @searchpath.each { |path|
        @pdf.set_parameter("SearchPath", path)
      }

      @pdf.set_info("Creator", "VDA-groep")
      @pdf.set_info("Author",  "Leon Berenschot")
      @pdf.set_info("Title",   "PdfNumberer")

      logger.info "#{self.class}\tProcessing: #{@infile}"
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

  def make_grid(subdivide = true)
    make_grid_box(0,0,@pagewidth,@pageheight,subdivide)
  end

  def make_grid_box(x, y, width, height, subdivide=true)
    # hor
    if subdivide 
      @pdf.setcolor("fillstroke", "rgb", 0.0, 0.0, 1.0, 0.0)
      @pdf.save
      # minute strokes 
      @pdf.setlinewidth(0.01)
      y.step(y+height, 10) do |alpha|
        draw_line(x, alpha, x+width, alpha)
      end
      @pdf.restore
    end

    @pdf.save
    @pdf.setcolor("fillstroke", "rgb", 1.0, 0.0, 0.0, 0.0)
    # minute strokes 
    @pdf.setlinewidth(0.05)
    y.step(y+height, 100) do |alpha|
      draw_line(x, alpha, x+width, alpha)
      @pdf.fit_textline(alpha.to_s, x, alpha, "boxsize {10 10} position 0"); 
    end
    @pdf.restore

    # vert
    if subdivide 
      @pdf.setcolor("fillstroke", "rgb", 0.0, 0.0, 1.0, 0.0)
      @pdf.save
      @pdf.setlinewidth(0.01)
      x.step(x+width, 10) do |alpha|
        draw_line(alpha, y, alpha, y+height)
      end
      @pdf.restore
    end

    @pdf.setcolor("fillstroke", "rgb", 1.0, 0.0, 0.0, 0.0)
    @pdf.save
    @pdf.setlinewidth(0.05)
    x.step(x+width, 100) do |alpha|
      draw_line(alpha, y, alpha, y+height)
      @pdf.fit_textline(alpha.to_s, alpha, y, "boxsize {10 10} position 0"); 
    end
    @pdf.restore

    # border
    draw_box_relative(x, y, width, height)
  end

  def draw_line(from_x, from_y, to_x, to_y)
    @pdf.moveto(from_x, from_y)
    @pdf.lineto(to_x, to_y)
    @pdf.stroke
  end

  def draw_box_abosolute(left_x, top_y, right_x, bot_y)
    @pdf.setcolor("fillstroke", "rgb", 1.0, 0.0, 1.0, 0.0)
    @pdf.setlinewidth(0.25)
    @pdf.moveto(left_x, bot_y)
    @pdf.lineto(left_x, top_y)
    @pdf.lineto(right_x,top_y)
    @pdf.lineto(right_x,bot_y)
    @pdf.closepath
    @pdf.stroke
    # @pdf.restore
  end

  def draw_box_relative(x, y, width, height)
    @pdf.setcolor("fillstroke", "rgb", 0.0, 1.0, 1.0, 0.0)
    @pdf.setlinewidth(0.25)
    @pdf.moveto(x, y)
    @pdf.lineto(x, y+height)
    @pdf.lineto(x+width,y+height)
    @pdf.lineto(x+width,y)
    @pdf.closepath
    @pdf.stroke
    # @pdf.restore
  end

end