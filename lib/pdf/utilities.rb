module Pdf
  module Utilities
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
end