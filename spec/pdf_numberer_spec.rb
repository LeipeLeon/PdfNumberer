require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'pdf_numberer'

describe PdfNumberer do
  SPEC_TEST_FILE = File.expand_path(File.dirname(__FILE__) + '/pref_file')
  SPEC_TEST_PDF  = File.expand_path(File.dirname(__FILE__) + '/../watch/4000000/000070010879.pdf')
  ENV['ENVIRONMENT'] = 'test'

  before(:each) do
    @preferences = YAML.load_file(SPEC_TEST_FILE)
    @numberer = PdfNumberer.new(SPEC_TEST_FILE)
  end

  it "should raise error when no config file exists" do
    lambda { 
      PdfNumberer.new('~/.no_such_file')
    }.should raise_error(RuntimeError, 'No such file! (~/.no_such_file)')
  end

  it "should read a config file" do
    @numberer.prefs.should_not be_nil
  end

  it "should set a watch folder" do
    @numberer.prefs["folders"]["in"].should   eql(@preferences["folders"]["in"])
    @numberer.prefs["folders"]["out"].should  eql(@preferences["folders"]["out"])
  end

  it "should check the preferences" do
    @numberer.prefs["folders"]["in"] = nil
    lambda {
      @numberer.check_prefs
    }.should raise_error(RuntimeError, "No watchfolder given.")
  end

  it "should watch a given folder" do
    Watcher.should_receive(:folder).with(@preferences["folders"]["in"]).and_return(@preferences["folders"]["in"])
    @numberer.watch.length.should eql(1)
  end

  it "should traverse subfolders" do
    recieve_pdf_processor
    # @numberer.traverse_subfolders(@preferences["folders"]["in"]).class.should   eql(Array)
    @numberer.traverse_subfolders(@preferences["folders"]["in"]).length.should  eql(1)
  end

  xit "should process_folder_items" do
    recieve_pdf_processor
    @numberer.process_folder_items(@preferences["folders"]["in"] + '/4001000', "4001000").should eql(true)
  end

  it "should parse a pdf" do
    recieve_pdf_processor
    @numberer.process_pdf(SPEC_TEST_PDF, "4000000").should eql(PDFlib)
  end

  it "should create code with a template" do
    @numberer.create_code('000070010879.pdf', '4000000').should eql(timestamped_code)
  end

  describe "subfolders" do
    it "should traverse through each folder" do
      @numberer.traverse_subfolders(@preferences["folders"]["in"])
    end

    it "should have an order reference number"
    it "should process new items in folder"
  end

  def recieve_pdf_processor
    PdfProcessor.should_receive(:new).with(
      SPEC_TEST_PDF, 
      :code        => timestamped_code,
      :filename    => "#{timestamped_code}.pdf",
      :savepath    => File.expand_path(@preferences["folders"]["out"] + '/4000000'),
      :on_pages    => @preferences['options']['default']['on_pages'],
      :rotation    => @preferences['options']['default']['rotation'],
      :x           => @preferences['options']['default']['x'],
      :y           => @preferences['options']['default']['y']
    ).and_return(PDFlib)
  end

  def timestamped_code
    "4000000-#{DateTime.now.strftime("%Y-%m-%d")}-0000001-000070010879"
  end

end