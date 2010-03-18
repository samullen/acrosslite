require 'uri'

require 'rubygems'
require 'htmlentities'
require 'xmlsimple'

# require 'harvester/harvester'
require 'acrosslite'
# require 'harvester/universal'
# require 'harvester/wordsearch'
# require 'lib/uclick_mailer'

# class Puzzle < Harvester

# attr_reader :content_path, :error, :error_msg
# attr_accessor :feature_puzzles

def process
	@feature_puzzles = Array.new

	@content = open(self.fullpath).read
	@content.gsub!(/(\r|\n)+/, "\n")

	self.method(self.feature_code).call
end

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
# Feature processing methods
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#

#------------------------------------------------------------------------------#
# "admin" processing: Processing for files which were dropped into any of the
#                     admin directories
#------------------------------------------------------------------------------#
# def admin
# 	self.feature_puzzles << {
# 		:feature_code => self.feature_code,
# 		:filename => self.new_filename,
# 		:filedate => self.filedate,
# 		:content => @content,
# 	}
# end

#------------------------------------------------------------------------------#
# Quickcross processing
#------------------------------------------------------------------------------#
def quickcross
	puzzle = Hash.new

	@content.gsub!(/(\r|\n)+/, "\n").gsub!(/\s*=\s*/, "=")

	@content.each do |line|
		(k,v) = line.chomp.split(/=/)
		puzzle[k.downcase] = v
	end

	title = self.feature == "pf" ? "PlayFour!" : "QuickCross"
	answers = [
		puzzle['solution'][0..3],
		puzzle['solution'][4..7],
		puzzle['solution'][8..11],
		puzzle['solution'][12..15],
		values_at(puzzle['solution'], 0,4,8,12).join,
		values_at(puzzle['solution'], 1,5,9,13).join,
		values_at(puzzle['solution'], 2,6,10,14).join,
		values_at(puzzle['solution'], 3,7,11,15).join,
	]

	output = <<EOL
<playfour>
	<Title v="#{title}" />
	<Date v="#{self.date.strftime('%y%m%d')}" />
	<Author v="#{puzzle['author']}" />
	<AllAnswer v="#{puzzle['solution']}" />
	<HorizontalClues>
		<h1 a="#{answers[0]}" c="#{puzzle['clue1']}" />
		<h2 a="#{answers[1]}" c="#{puzzle['clue2']}" />
		<h3 a="#{answers[2]}" c="#{puzzle['clue3']}" />
		<h4 a="#{answers[3]}" c="#{puzzle['clue4']}" />
	</HorizontalClues>
	<VerticalClues>
		<v1 a="#{answers[4]}" c="#{puzzle['cluea']}" />
		<v2 a="#{answers[5]}" c="#{puzzle['clueb']}" />
		<v3 a="#{answers[6]}" c="#{puzzle['cluec']}" />
		<v4 a="#{answers[7]}" c="#{puzzle['clued']}" />
	</VerticalClues>
</playfour>
EOL

	self.feature_puzzles << {
		:feature_code => self.feature_code,
		:filename => self.new_filename,
		:filedate => self.filedate,
		:content => output
	}
end

#------------------------------------------------------------------------------#
# Word Roundup: Processing of the general wordroundup files which come 
#      concatenated in a single text file and need to be broken out
#------------------------------------------------------------------------------#
def wordroundup
# 	recipients = 'editors@uclick.com'
	recipients = 'smullen@uclick.com'
	puzzle = Array.new
	grid = Array.new
	grid_matrix = Array.new
	answers = Array.new
	w = h = 0
	error = false
	error_msg = ""
	date = Date.new
	filename = ''

	@content.each do |line|
		line = HTMLEntities::decode_entities(line)

		#----- get date line and define filename -----#
		if line =~ /Date v="(.+)"/
			date_str = $1

			if date_str =~ /\d{6}/
				date = Date.strptime(date_str, "%y%m%d")
			else
				error = true
				error_msg += "wordroundup: date #{date_str} is not valid for file"
			end

			filename = self.feature_code + date.strftime("%y%m%d.xml")
			puzzle.push(line)

		#----- get grid width -----#
		elsif line =~ /Width v="(\d+)"/
			w = $1.to_i
			puzzle.push(line)

		#----- get grid Height -----#
		elsif line =~ /Height v="(\d+)"/
			h = $1.to_i

		#----- error check and clean "Grid" line -----#
		elsif line =~ /Grid v="(.+)"/i
			g = $1
			g.gsub!(/[^A-Z,]/, '')
			grid = g.split(/,/)

			if grid.length != h
				error = true
				error_msg = "wordroundup: grid does not match specified height in file #{filename}"
			end

			grid.each do |row|
				if row.length != w
					error = true
					error_msg = "wordroundup: gridrow does not match specified width in file #{filename}"
				end
			end

			line.sub!(/(Grid v=").+(")/, "Grid v='#{g}'")
			puzzle.push(line)

			#----- build the wordsearch grid for validation -----#
			grid.each do |row|
				grid_matrix.push(row.split(//))
			end

		#----- clean Clue/Answer lines -----#
		elsif line =~ /<c\d+ c="(.+)" a="(.+)"/ 
			clue = URI::escape($1, /[&?"'%]/)
			answer = $2.gsub(/[^A-Z,]/, '')

			answers.push(answer.split(/\s*,\s*/))

			line.sub!(/(<c\d c=").+(" a=").+(")/, '\1' + clue + '\2' + answer + '\3')
			puzzle.push(line)

		elsif line =~ /<\/roundup.*>/
			puzzle.push(line)

			ws = WordSearch.new(:grid => grid_matrix, :clues => answers.flatten)
			dups = ws.duplicates
			badwords = ws.badwords

			if dups
				error = true
				error_msg = "The following words are may be duplicates in file #{filename}.  Palindromes may erroneously cause this error...\n" + dups.join("\n")
			elsif badwords
				error = true
				error_msg = "The following dirty words are in file #{filename}...\n" + badwords.join("\n")
			end

			self.feature_puzzles << {
				:error => error,
				:error_message => error_msg,
				:notify => recipients,
				:feature_code => self.feature_code,
				:filename => filename,
				:filedate => date,
				:content => puzzle.join('')
			}

			error = false
			error_msg = ""
			puzzle.clear
			grid_matrix.clear

		#----- start over on blank lines -----#
		elsif line =~ /^\s*$/

		#----- Add all other lines to the current puzzle -----#
		else
			puzzle.push(line)
		end
	end
end

#------------------------------------------------------------------------------#
# WordRoundup: Single file processing
#------------------------------------------------------------------------------#
def wordroundup_xml
	error = false
	error_msg = ''
	grid_matrix = Array.new
	answers = Array.new
	root = ""
	xml = Hash.new

	#----- read in and parse XML -----#
	begin
		rootxml = XmlSimple.xml_in(@content, {
				'ForceArray' => false, 'KeepRoot' => true})
		root, xml = rootxml.shift
	rescue
		error = true
		error_msg = "Invalid XML in file "
	end

	if xml['Date']['v'] !~ /\d{6}/
		error_msg = "Invalid Date format"
	end

	#----- define and validate grid_matrix -----#
	grid_matrix = xml['Grid']['v'].split(/,/).collect {|r| r.upcase.split(//)}

	if grid_matrix.length != xml['Height']['v']
		error = true
		error_msg = "wordroundup: grid does not match specified height in file #{filename}"
	end

	grid_matrix.each do |row|
		if row.length != xml['Width']['v']
			error = true
			error_msg = "wordroundup: gridrow does not match specified width in file #{filename}"
		end
	end

	#----- validate clues/answers -----#
	xml_content = <<XML
<#{root}>
	<Title v="#{xml['Title']['v']}">
	<Date v="#{xml['Date']['v']}">
	<Author v="#{xml['Author']['v']}">
	<Width v="#{xml['Width']['v']}">
	<Height v="#{xml['Height']['v']}">
	<Grid v="#{xml['Grid']['v']}">
	<Clues>
XML

# 	puts xml['Clues'].length
# 	1.upto(xml['Clues'].length) do |i|
# 		clue = xml['Clues']['c' + i]
# 		xml_content += 
# 	end
# keys = xml[:clues].sort {|a,b| a[0].to_s <=> b[0].to_s}
# pp keys
	xml['Clues'].sort {|a,b| a[0] <=> b[0]}.each do |c|
		clue = c.shift
		xml_content += "\t\t<#{clue} c='#{c[0]['c']}' a='#{c[0]['a']}' />\n"
		answers.push(c[0]['a'].split(','))
	end

	xml_content += "\t</Clues>\n</#{root}>"
puts xml_content
# 	self.feature_puzzles << {
# 		:error => error,
# 		:error_message => error_msg,
# 		:notify => recipients,
# 		:feature_code => self.feature_code,
# 		:filename => filename,
# 		:filedate => date,
# 		:content => xml_content,
# 	}
end

#------------------------------------------------------------------------------#
# Crossword Formatting (Universal and AcrossLite)
#------------------------------------------------------------------------------#
def crossword(xw, category, editor, encoding)
	#----- build -data file contents -----#
	xml = <<XML
<crossword>
	<Title v="#{xw.title}" />
	<Author v="#{xw.author}" />
XML

	xml += "<Category v='#{category}' />" if category
	xml += "<Editor v='#{editor}' />" if editor

	xml += <<XML
	<Copyright v="uclick, LLC" />
	<Width v="#{xw.columns}" />
	<Height v="#{xw.rows}" />
	<AllAnswer v="#{xw.solution.flatten.join.gsub(/\W/, "-")}" />
XML

	#----- across clues -----#
	i = 1
	xw.across.keys.sort.each do |k|
		if encoding == 'xml'
			clue = HTMLEntities::encode_entities(xw.across[k][:clue], :decimal)
		elsif encoding == 'utf8'
			clue = URI::escape(xw.across[k][:clue], /[&?"'%]/)
		end

		xml += <<XML
	<a#{i} a="#{xw.across[k][:solution]}"
		c="#{clue}" 
		n="#{xw.across[k][:cell_number]}" 
		cn="#{xw.across[k][:clue_number]}" />
XML
		i += 1
	end

	xml += "</across>\n<down>\n"

	#----- down clues -----#
	i = 1
	xw.down.keys.sort.each do |k|
		if encoding == 'xml'
			clue = HTMLEntities.encode(xw.down[k][:clue], :decimal)
		elsif encoding == 'utf8'
			clue = URI.encode(xw.down[k][:clue])
		end

		xml += <<XML
	<d#{i} a="#{xw.down[k][:solution]}"
		c="#{xw.down[k][:clue]}" 
		n="#{xw.down[k][:cell_number]}" 
		cn="#{xw.down[k][:clue_number]}" />
XML
		i += 1
	end
	xml += "</down>\n</crossword>"

	self.feature_puzzles << {
		:feature_code => self.feature_code,
		:filename => self.new_filename=("%f%y%m%d-data.xml"),
		:filedate => self.filedate,
		:content => xml
	}

	#----- create -title file contents -----#
	xml = <<XML
<crossword>
	<Title v="#{xw.title}" />
	<Author v="#{xw.author}" />
</crossword>
XML

	self.feature_puzzles << {
		:feature_code => self.feature_code,
		:filename => self.new_filename=("%f%y%m%d-title.xml"),
		:filedate => self.filedate,
		:content => xml
	}
end

def acrosslite_utf8
	al = AcrossLite.new(:content => @content)
	al.parse
	
	crossword(al, nil, nil, "utf8")
end

def acrosslite_xml
	al = AcrossLite.new(:content => @content)
	al.parse
	
	crossword(al, nil, nil, "xml")
end

def fcx
	uc = Universal.new(:content => @content)
	uc.parse
	
# 	copy to other feature codes
	crossword(uc, "Universal Daily Crosswords", "Timothy Parker", "utf8")
end

def usaon
	#----- copy to other feature codes -----#
# copy to usxwip

	uc = Universal.new(:content => @content)
	uc.parse

	crossword(uc, "USA Today Crosswords", "Timothy Parker", "utf8")
end

def usxwip
	uc = Universal.new(:content => @content)
	uc.parse

	crossword(uc, "USA Today Crosswords", "Timothy Parker", "xml")
end

#------------------------------------------------------------------------------#
# Wonderword
#------------------------------------------------------------------------------#
def wonderword
	grid = Array.new
	clues = Array.new
	title = solution = nil

	@content.each do |line|
		line.chomp!

		#----- Grid lines -----#
		if line =~ /^(\w\t){14}\w$/
			line.gsub!(/\s/, '')
			grid << line
		#----- Title Line -----#
		elsif line =~ /(.+?)\s+Solution:\s*(\d+)\s*letters/
			title = $1
		#----- clue line -----#
		elsif line =~ /(\w+, )+/
			clues = line.split(/,\s*/)
		#----- solution line -----#
		elsif line =~ /Answer:\s+(\w+)/
			solution = $1.upcase

			contents = <<XML
<wonderword>
	<Title v="#{title}"/>
	<Author v="By David Ouellet"/>
	<Width v="15"/>
	<Height v="15"/>
	<Grid v="#{grid.join(",").upcase}"/>
	<Clues v="#{clues.join(",")}"/>
	<ClueQuantity v="#{clues.length}"/>
	<Solution v="#{solution}"/>
</wonderword>
XML

			self.feature_puzzles << {
				:feature_code => self.feature_code,
				:filename => self.new_filename=("%f%y%m%d-data.xml"),
				:filedate => self.filedate,
				:content => contents
			}

			grid.clear
			clues.clear
			title = solution = nil
			self.filedate += 1
		end
	end
end

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
# Puzzle Utility methods
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
# Class Utility methods
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
def values_at(str, *indices)
	chars = Array.new

	indices.each { |i| chars.push(str[i].chr) }

	chars
end

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
# Aliases
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=#
alias pf    quickcross
alias usaqc quickcross

# alias wr    wordroundup
alias wr    wordroundup_xml
# alias uchwr wordroundup
# alias ucwrc wordroundup
# alias ucwr  wordroundup
# alias uswr  wordroundup
# alias yawr  wordroundup

alias nlfcx fcx
alias rfcx fcx
alias sffcx fcx

alias wo wonderword
# alias wwf wonderword

alias can   acrosslite_utf8
alias crnet acrosslite_utf8
alias jnz   acrosslite_utf8
alias lacal acrosslite_utf8
alias lamag acrosslite_utf8
alias tmdxi acrosslite_utf8
alias tmcal acrosslite_utf8
alias tmlac acrosslite_utf8
alias tmtvt acrosslite_utf8
alias wpwcx acrosslite_utf8
alias xp    acrosslite_utf8

# end
