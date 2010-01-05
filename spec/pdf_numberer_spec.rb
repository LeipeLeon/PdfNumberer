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
    @numberer.prefs["options"]["folder_in"].should   eql(@preferences["options"]["folder_in"])
    @numberer.prefs["options"]["folder_out"].should  eql(@preferences["options"]["folder_out"])
  end

  ['folder_in', 'folder_out', 'folder_processed'].each do |folder|
    it "should check the preferences '#{folder}'" do
      @numberer.prefs["options"]['default'][folder] = nil
      lambda {
        @numberer.check_prefs
      }.should raise_error(ArgumentError) #, "Preference file may be corrupt (missing options: default: folder_in)")
    end
  end

  it "should watch a given folder" do
    Watcher.should_receive(:folder).with(@preferences["options"]['default']["folder_in"]).and_return(@preferences["options"]['default']["folder_in"])
    @numberer.should_receive(:traverse_subfolders).and_return(['folder_path'])
    @numberer.watch.length.should eql(1)
  end

  it "should traverse subfolders" do
    @numberer.should_receive(:process_folder_items).twice.with(File.expand_path(@preferences["options"]['default']["folder_in"] + '/4000000'), '4000000').and_return(['something'])
    @numberer.traverse_subfolders(@preferences["options"]['default']["folder_in"]).class.should   eql(Array)
    @numberer.traverse_subfolders(@preferences["options"]['default']["folder_in"]).length.should  eql(1)
  end

  it "should process_folder_items" do
    @numberer.should_receive(:process_pdf).with(SPEC_TEST_PDF, '4000000').and_return(true)
    @numberer.should_receive(:move_to_processed_dir).and_return(true)
    @numberer.process_folder_items(File.expand_path(@preferences["options"]['default']["folder_in"] + '/4000000'), "4000000").should eql([SPEC_TEST_PDF])
  end

  it "should parse a pdf" do
    PdfProcessor.should_receive(:new).with(
      SPEC_TEST_PDF, 
      :code        => timestamped_code,
      :filename    => "4000000-00001-000070010879.pdf",
      :savepath    => File.expand_path(@preferences["options"]['default']["folder_out"] + '/4000000'),
      :on_pages    => @preferences['options']['default']['on_pages'],
      :rotation    => @preferences['options']['default']['rotation'],
      :x           => @preferences['options']['default']['x'],
      :y           => @preferences['options']['default']['y'],
      :regularfont => @preferences['options']['default']['regularfont']
    ).and_return(PDFlib)
    @numberer.process_pdf(SPEC_TEST_PDF, "4000000").should eql(PDFlib)
  end

  it "should create code with a template" do
    @numberer.create_code('000070010879.pdf', '4000000').should eql([timestamped_code, '4000000-00001-000070010879.pdf'])
  end

  def timestamped_code
    "4000000-#{DateTime.now.strftime("%Y-%m-%d")}-00001-000070010879"
  end

end