#!ruby
require 'pathname'

class Parser
  
  def parse_file(fname)
    ballot_count = 0
    ballot_text = []
    File.foreach(fname) do |line|
      case line
        when /General Election Ballot/
        if ballot_text.length != 0
          parse_ballot_info(ballot_count, ballot_text) 
          ballot_count += 1
          ballot_text = []
        end
      else
        ballot_text << line  
      end
    end
    parse_ballot_info(ballot_count, ballot_text) 
  end

  def parse_ballot_info(cnt, txt)
    puts "ballot #{cnt}"
    town = txt[0]
    (2..txt.length).each do |line|
      parse_contest(txt, line)
    end
  end
  
  def parse_contest(txt, line)
    contest = txt[line]
    contest_rule = txt[line+1]
    (line+2..txt.length).each do |line|
      if txt[line] =~ /^\s/
        parse_candidate(txt[line], txt[line+1])
        
    end
    
  end
end
  



p = Parser.new
p.parse_file(ARGV[0])
