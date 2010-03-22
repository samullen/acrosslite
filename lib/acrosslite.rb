require 'stringio'

require File.join(File.dirname(__FILE__), 'entry')


class Acrosslite
  attr_reader :across, :down, :solution, :diagram, :copyright, :title, :author
  attr_accessor :filepath
  attr_writer :content

  VERSION = '0.0.1'

  ACROSSLITE = 2
  ROWS       = 44
  COLUMNS    = 45
  SOLUTION   = 52

  DEFAULT_OPTIONS = {
    :filepath => nil,
    :content  => nil,
  }

  def initialize(*args)
    opts = {}

    case
    when args.length == 0 then
    when args.length == 1 && args[0].class == Hash then
      arg = args.shift

      if arg.class == Hash
        opts = arg
      end
    else
      raise ArgumentError, "new() expects hash or hashref as argument"
    end

    opts = DEFAULT_OPTIONS.merge opts

    @filepath   = opts[:filepath]
    @content    = opts[:content] || content

    @content_io = StringIO.new @content

    @across     = Array.new
    @down       = Array.new
    @layout     = Array.new
    @solution   = Array.new
    @diagram    = Array.new
    @author     = String.new
    @title      = String.new
    @copyright  = String.new
  end

  def content
    @content ||= read_puzzle
  end

#   def self.from_file(filename)
#     @acrosslite = new
#     @acrosslite.read_puzzle(filename)
#     @acrosslite.parse
#     self
#   end

  def rows
    unless @rows 
      @content_io.seek(ROWS)
      @rows = @content_io.read(1).unpack('C').first
    end
    @rows
  end

  def columns
    unless @columns 
      @content_io.seek(COLUMNS)
      @columns = @content_io.read(1).unpack('C').first
    end
    @columns
  end

  def solution
    width = columns

    unless @solution.size == rows
      @content_io.seek(SOLUTION)
      rows.times do |r|
        @solution << @content_io.read(width).unpack("C#{width}").map {|c| c.chr}
      end
    end
    @solution
  end

  def diagram
    width = columns

    unless @diagram.size == rows
      @content_io.seek(SOLUTION + rows * width)
      rows.times do |r|
        @diagram << @content_io.read(width).unpack("C#{width}").map {|c| c.chr}
      end
    end
    @diagram
  end

  def area
    rows * columns
  end
=begin rdoc
The parse method takes the puzzle loaded into content and breaks it out into the
following attributes: rows, columns, solution, diagram, title, author, copyright, across, and down.
=end

def parse
	clues = Array.new

  @content_io.seek(SOLUTION + area + area)

	@title = next_field
	@author = next_field
	@copyright = next_field

	#----- build clues array -----#
	until @content_io.eof? do
		clues << next_field
	end

	#----- determine answers -----#
	across_clue = down_clue = 1 # clue_number: incremented only in "down" section

	0.upto(rows - 1) do |r|
		0.upto(columns - 1) do |c|
			next if solution[r][c] =~ /[.:]/

			if c - 1 < 0 || solution[r][c - 1] == "."
        entry = Entry.new
        answer = ''

				c.upto(columns - 1) do |cc|
					char = solution[r][cc]

					if char != '.'
            answer += char
					end

					if char == "." || cc + 1 >= columns
            entry.direction   = "across"
            entry.clue        = clues.shift
            entry.answer      = answer
            entry.clue_number = across_clue
            entry.row         = r
            entry.column      = c
            entry.length      = answer.size
            entry.cell_number = r * columns + c + 1

            @across << entry
						across_clue += 1
						break
					end
				end
			end

			if r - 1 < 0 || solution[r - 1][c] == "."
        entry = Entry.new
        answer = ''

				r.upto(rows - 1) do |rr|
          char = solution[rr][c]

					if char != '.'
            answer += char
					end

					if char == "." || rr + 1 >= rows
            entry.direction   = "down"
            entry.clue        = clues.shift
            entry.answer      = answer
            entry.clue_number = down_clue
            entry.row         = r
            entry.column      = c
            entry.length      = answer.size
            entry.cell_number = r * columns + c + 1

            @down << entry
						down_clue += 1
						break
					end
				end
			end

			if across_clue > down_clue
				down_clue = across_clue
			else
				across_clue = down_clue
			end
		end
	end
end

=begin rdoc
If a filehandle or filepath were provided, open reads in the file's contents
into the content attribute which is then used for parsing.

open must be called prior to parsing if content has not already been provided.

=end
def read_puzzle(filepath=nil)
  filepath ||= @filepath
  raise unless filepath
	@content = open(@filepath).read
end

private

=begin rdoc
=end
def next_field
	string = String.new

	while (c = @content_io.getc.chr) != "\0"
		string += c
	end

	return string
end

def content_io
  @content_io ||= StringIO.new @content
end

end
