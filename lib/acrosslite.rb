require 'stringio'

require File.join(File.dirname(__FILE__), 'entry')


class Acrosslite
  attr_reader :title, :author, :across, :down, :solution, :diagram, :columns, 
              :rows, :copyright
  attr_accessor :filepath
  attr_writer :content

  VERSION = '0.0.1'

  DEFAULT_OPTIONS = {
    :filepath => '',
    :content  => '',
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
    @content    = opts[:content]

    @content_io = String.new

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


=begin rdoc
The parse method takes the puzzle loaded into content and breaks it out into the
following attributes: rows, columns, solution, diagram, title, author, copyright, across, and down.
=end

def parse
	clues = Array.new

	@content_io = StringIO.new content
	@content_io.seek(44)

	@rows, @columns = @content_io.read(2).unpack("C C")
	@content_io.seek(52)

	#----- solution -----#
	1.upto(@rows) do |r|
		@solution << @content_io.read(@columns).unpack("C" * @columns).map {|c| c.chr}
	end

	#----- diagram -----#
	1.upto(@rows) do |r|
		@diagram << @content_io.read(@columns).unpack("C" * @columns).map {|c| c.chr}
	end

	@title = next_field
	@author = next_field
	@copyright = next_field

	#----- build clues array -----#
	until @content_io.eof? do
		clues << next_field
	end

	#----- determine answers -----#
	across_clue = down_clue = 1 # clue_number: incremented only in "down" section

	0.upto(@rows - 1) do |r|
		0.upto(@columns - 1) do |c|
			next if @solution[r][c] =~ /[.:]/

			if c - 1 < 0 || @solution[r][c - 1] == "."
        entry = Entry.new
        answer = ''

				c.upto(@columns - 1) do |cc|
					char = @solution[r][cc]

					if char != '.'
            answer += char
					end

					if char == "." || cc + 1 >= @columns
            entry.direction   = "across"
            entry.clue        = clues.shift
            entry.clue_number = across_clue
            entry.row         = r
            entry.column      = c
            entry.length      = answer.size
            entry.cell_number = r * @columns + c + 1

            @across << entry
						across_clue += 1
						break
					end
				end
			end

			if r - 1 < 0 || @solution[r - 1][c] == "."
        entry = Entry.new
        answer = ''

				r.upto(@rows - 1) do |rr|
          char = @solution[rr][c]

					if char != '.'
            answer += char
					end

					if char == "." || rr + 1 >= @rows
            entry.direction   = "down"
            entry.clue        = clues.shift
            entry.clue_number = down_clue
            entry.row         = r
            entry.column      = c
            entry.length      = answer.size
            entry.cell_number = r * @columns + c + 1

            @across << entry
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

end
