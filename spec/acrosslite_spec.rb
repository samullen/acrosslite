require File.join(File.dirname(__FILE__), '..', 'lib','acrosslite')

describe Acrosslite do
  before(:all) do
    basedir        = File.dirname(__FILE__)
    @example_files = Hash.new

    @example_files[:halloween] = File.join(basedir, "files/halloween2009.puz")
  end

#   before(:each) do
#   end
# 
#   after(:each) do
#   end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
  # Builder Tests
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#

  it "should instantiate the puzzle" do
    ac = Acrosslite.new
    ac.should be_an_instance_of Acrosslite

    ac = Acrosslite.new(:filepath => @example_files[:halloween])
    ac.should be_an_instance_of Acrosslite
    ac.filepath.should == @example_files[:halloween]

    ac = Acrosslite.new(:content => File.open(@example_files[:halloween]).read)
    ac.should be_an_instance_of Acrosslite
    ac.content.should == File.open(@example_files[:halloween]).read
  end

#   it "should instantiate the puzzle from_file" do
#     ac = Acrosslite.from_file(@example_files[:halloween])
#     ac.content.should == File.open(@example_files[:halloween]).read
#   end

end
