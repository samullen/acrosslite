require 'stringio'

=begin rdoc
The Crossword class provides a superclass structure from which to subclass
puzzle formats such as AcrossLite and CrosswordCompiler.
=end

class Crossword

attr_reader :title, :author, :across, :down, :solution, :diagram, :columns, :rows, :copyright
attr_accessor :filepath, :content

=begin rdoc
Crossword.new(:filepath => filepath) => new_crossword
Crossword.new(:content => contents) => new_crossword

Returns a crossword object
=end

def initialize(*args)
# 	@filepath = args[:filepath]
	@content = args.first[:content]

	@across = Hash.new
	@down = Hash.new
	@layout = Array.new
	@solution = Array.new
	@diagram = Array.new
	@author = String.new
	@title = String.new
	@copyright = String.new
end

=begin rdoc
If a filehandle or filepath were provided, open reads in the file's contents
into the content attribute which is then used for parsing.

open must be called prior to parsing if content has not already been provided.

=end
def open
  raise unless @filepath
	@content = open(@filepath).read
end

end
