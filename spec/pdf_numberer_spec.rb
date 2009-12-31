require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'pdf_numberer'

describe PdfNumberer do
  xit "should read a config file" do
    
  end

  xit "should watch a folder" do
  end

  xit "should process new items in folder" do
  end

  describe "process file" do
    it "should load PDFLib" do
      numberer = PdfNumberer.new()
      numberer.pdf.class.should eql(PDFlib)
    end
  end
end