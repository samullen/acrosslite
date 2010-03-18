#!/usr/bin/ruby

require 'acrosslite'

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
end

@content = File.open(ARGV[0], 'r').read
puts acrosslite_utf8
