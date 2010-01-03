require File.dirname(__FILE__) + '/spec_helper'

require 'watcher'

module Kernel 
  def `(cmd)
    puts cmd.split(" ")[1]
  end
end

describe Watcher do
  it "should watch a folder" do
    Watcher.folder(File.dirname(__FILE__) + "/../watch").should eql(File.dirname(__FILE__) + "/../watch")
  end

  it "should raise error when folder doesn't exists" do
    lambda {
      Watcher.folder(File.dirname(__FILE__) + "/../nowatch")
    }.should raise_error(ArgumentError, "Watchfolder doesn't exist (./spec/../nowatch)")
  end
end
