require File.join(File.dirname(__FILE__), '..', 'lib','acrosslite')

describe Acrosslite do
  before(:all) do
    basedir        = File.dirname(__FILE__)
    @example_files = Hash.new

    @example_files[:halloween] = File.join(basedir, "files/halloween2009.puz")
    @example_files[:crnet]     = File.join(basedir, "files/crnet100306.puz")
    @example_files[:tmcal]     = File.join(basedir, "files/tmcal100306.puz")
    @example_files[:xp]        = File.join(basedir, "files/xp100306.puz")
    @example_files[:ydx]       = File.join(basedir, "files/ydx100515.puz")
  end

#   before(:each) do
#   end
# 
#   after(:each) do
#   end

  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
  # Builder Tests
  #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#

  it "should instantiate the puzzle with passing of file" do
    ac = Acrosslite.new(:filepath => @example_files[:halloween])
    ac.should be_an_instance_of Acrosslite
    ac.filepath.should == @example_files[:halloween]
    ac.content.should == File.open(@example_files[:halloween]).read
  end

  it "should instantiate the puzzle with passing of an acrosslite blob" do
    ac = Acrosslite.new(:content => File.open(@example_files[:halloween]).read)
    ac.should be_an_instance_of Acrosslite
    ac.content.should == File.open(@example_files[:halloween]).read
  end

  it "should parse dimensions" do
    ac = Acrosslite.new(:filepath => @example_files[:tmcal])
    ac.rows.should == 15
    ac.columns.should == 15
    ac.area.should == 15 * 15
  end

  it "should parse solution and diagram" do
    ac = Acrosslite.new(:filepath => @example_files[:crnet])
    ac.solution.join.should == 'PASSED.MAMACASSLEANER.AMICABLYURBANA.FIGUREONCARRYWEIGHT.TVAKTEL.BLOAT.STEPYES.GLASS.COINS...KYOTO.TOWNIEMCENROE.RAREGASALLIED.RAKED...NESTS.HADES.PEWDAIS.REPOS.MUNIARN.FORINSTANCELOOKATME.IONIANAUREVOIR.CROSSESTEWARTS.KOSHER'
    ac.diagram.join.should == '------.--------------.--------------.-------------------.-------.-----.-------.-----.-----...-----.-------------.-------------.-----...-----.-----.-------.-----.-------.-------------------.--------------.--------------.------'
  end

  it "should retrieve meta data about the puzzle" do
    ac = Acrosslite.new(:filepath => @example_files[:tmcal])
    ac.title.should == 'LA Times, Sat, Mar 6, 2010'
    ac.author.should == 'Barry C. Silk / Ed. Rich Norris'
#     ac.copyright.should == "© 2010 Tribune Media Services, Inc."

    ac = Acrosslite.new(:filepath => @example_files[:crnet])
    ac.title.should == '03/06/10 SATURDAY STUMPER'
    ac.author.should == 'Merle Baker , edited by Stanley Newman'
#     ac.copyright.should == "© Copyright 2010 Stanley Newman, Distributed by Creators Syndicate, Inc."

    ac = Acrosslite.new(:filepath => @example_files[:xp])
    ac.title.should == ''
    ac.author.should == ''
    ac.copyright.should == ''
  end

  it "should retrieve the data for each of the entries" do
    ac = Acrosslite.new(:filepath => @example_files[:halloween])
    ac.across.first.clue.should == "Item sought by kids in costumes"
    ac.across.first.answer.should == "CANDY"
    ac.across.first.clue_number.should == 1
    ac.across.first.row.should == 0
    ac.across.first.column.should == 0
    ac.across.first.length.should == 5
    ac.across.first.cell_number.should == 1

    ac.across.last.clue.should == "Has to have"
    ac.across.last.answer.should == "NEEDS"
    ac.across.last.clue_number.should == 73
    ac.across.last.row.should == 14
    ac.across.last.column.should == 10
    ac.across.last.length.should == 5
    ac.across.last.cell_number.should == 221

    ac.down.first.clue.should == "Slept under the stars"
    ac.down.first.answer.should == "CAMPED"
    ac.down.first.clue_number.should == 1
    ac.down.first.row.should == 0
    ac.down.first.column.should == 0
    ac.down.first.length.should == 6
    ac.down.first.cell_number.should == 1

    ac.down.last.clue.should == "Take in slowly"
    ac.down.last.answer.should == "SIP"
    ac.down.last.clue_number.should == 66
    ac.down.last.row.should == 12
    ac.down.last.column.should == 6
    ac.down.last.length.should == 3
    ac.down.last.cell_number.should == 187
  end
end
