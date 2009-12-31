require 'PDFlib'
class PdfProcessor
  attr :pdf

  def initialize(file)
    puts "processing #{File.expand_path(file)}"
    @pdf = PDFlib.new
  end
  
  def make_code(code)
    # put the code on the file
    puts "\t\t[41;37;1m CODE [0m"
  end
end