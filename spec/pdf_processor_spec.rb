require File.dirname(__FILE__) + '/spec_helper'

require 'pdf_processor'

describe PdfProcessor do
  it "should description" do
    
  end

  describe "process file" do
    it "should load PDFLib" do
      numberer = PdfProcessor.new(File.dirname(__FILE__) + '/../fixtures/000070010880.pdf')
      numberer.pdf.class.should eql(PDFlib)
    end

    it "should create a new file"
    it "should put the number on the frontpage"
  end
end
