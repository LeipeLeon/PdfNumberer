require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'pdf_numberer'

describe PdfNumberer do
  SPEC_TEST_FILE = File.expand_path(File.dirname(__FILE__) + '/pref_file')
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
    # @numberer.watch
  end

  describe "subfolders" do
    it "should traverse through each folder" do
      @numberer.traverse_subfolders(@preferences["folders"]["in"])
    end

    it "should have an order reference number" do
    end

    xit "should process new items in folder" do
    end
  end
end