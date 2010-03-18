require 'stringio'

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

    @filepath  = opts[:filepath]
    @content   = opts[:content]

    @across    = Hash.new
    @down      = Hash.new
    @layout    = Array.new
    @solution  = Array.new
    @diagram   = Array.new
    @author    = String.new
    @title     = String.new
    @copyright = String.new
  end

  def self.from_file(filename)
    new(:content => open(filename).read)
  end

  def content
    @content ||= read_puzzle
  end

=begin rdoc
The parse method takes the puzzle loaded into content and breaks it out into the
following attributes: rows, columns, solution, diagram, title, author, copyright, across, and down.
=end

def parse
	clues = Array.new

	@content = StringIO.new @content
	@content.seek(44)

	@rows, @columns = @content.read(2).unpack("C C")
	@content.seek(52)

	#----- solution -----#
	1.upto(@rows) do |r|
		@solution << @content.read(@columns).unpack("C" * @columns).map {|c| c.chr}
	end

	#----- diagram -----#
	1.upto(@rows) do |r|
		@diagram << @content.read(@columns).unpack("C" * @columns).map {|c| c.chr}
	end

	@title = next_field
	@author = next_field
	@copyright = next_field

	#----- build clues array -----#
	until @content.eof? do
		clues << next_field
	end

	#----- determine answers -----#
	a_clue = d_clue = 1 # clue_number: incremented only in "down" section
	0.upto(@rows - 1) do |r|
		0.upto(@columns - 1) do |c|
			next if @solution[r][c] =~ /[.:]/

			if c - 1 < 0 || @solution[r][c - 1] == "."
				@across[a_clue] = Hash.new
				c.upto(@columns - 1) do |cc|
					char = @solution[r][cc]

					if char != '.'
						@across[a_clue][:solution] ||= ""
						@across[a_clue][:solution] += char
					end

					if char == "." || cc + 1 >= @columns
						@across[a_clue][:direction] = 'across'
						@across[a_clue][:clue] = clues.shift
						@across[a_clue][:clue_number] = a_clue
						@across[a_clue][:row] = r
						@across[a_clue][:column] = c
						@across[a_clue][:length] = @across[a_clue][:solution].length
						@across[a_clue][:cell_number] = r * @columns + c + 1

						a_clue += 1
						break
					end
				end
			end

			if r - 1 < 0 || @solution[r - 1][c] == "."
				@down[d_clue] = Hash.new
				r.upto(@rows - 1) do |rr|
					char = @solution[rr][c]

					if char != '.'
						@down[d_clue][:solution] ||= ""
						@down[d_clue][:solution] += char
					end

					if char == "." || rr + 1 >= @rows
						@down[d_clue][:direction] = "across"
						@down[d_clue][:clue] = clues.shift
						@down[d_clue][:clue_number] = d_clue
						@down[d_clue][:row] = r
						@down[d_clue][:column] = c
						@down[d_clue][:length] = @down[d_clue][:solution].length
						@down[d_clue][:cell_number] = r * @columns + c + 1

						d_clue += 1
						break
					end
				end
			end

			if a_clue > d_clue
				d_clue = a_clue
			else
				a_clue = d_clue
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

	while c = @content.getc
		string += c.chr
	end

	return string
end

end
