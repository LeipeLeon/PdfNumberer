require 'PDFlib'
class PdfNumberer
  attr :pdf

  def initialize
    @pdf = PDFlib.new
  end
end