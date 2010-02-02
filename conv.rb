#!ruby
require 'yaml'
require 'pp'

class Parser
  
  def initialize(fname, generator)
    @file = File.open(fname)
    @lookahead = ""
    @line = ""
    @gen = generator
  end
  
  def get_line
    @line = @lookahead
    if !@file.eof?
       @lookahead = @file.readline.chomp
   else
      @lookahead = ""
    end
  end
    
  def parse_file()
    @gen.begin_file
    get_line
    get_line
    if @lookahead != ""
      parse_ballots()
    end
    @gen.end_file
  end
  
  def parse_ballots
    while !@file.eof?
      parse_ballot
    end
  end
  
  def parse_ballot
    raise "unexpected start of section" unless @line == "General Election Ballot"
    get_line
    town = @line
    get_line
    get_line
    @gen.start_ballot(town)
    parse_contests
    @gen.end_ballot
  end
  
  def parse_contests
    while @line != "General Election Ballot" && !@file.eof?
      @contest = @line.chomp
      get_line
      @rule = @line.chop.lstrip
      get_line
      @gen.start_contest(@contest, @rule)
      parse_candidates()
      @gen.end_contest
    end
  end
  
  def parse_candidates()
    while line_indented?
      parse_candidate
    end
  end
  
  def line_indented?
    @line[0] == 32
  end
  
  def parse_candidate
    name = @line.chomp.lstrip
    get_line
    party = @line.chomp.lstrip
    get_line
    @gen.add_candidate(name, party)
  end
end

class Generator
  attr_reader :h_file
  
  def initialize
    @rules = {}
    @candidates = {}
    @parties = {}
    @precincts = {}
    @cont_count = 0
    @prec_count = 0
  end
  
  def begin_file
    @h_file = []
    
  end
  
  def end_file
    pp @h_file
  end
  
  def start_ballot(town)
#    puts "\n\nnew ballot: #{town}"
    @prec_id = "prec-#{@precincts.length}"
    @precincts[town] = @prec_id
    @h_ballot = {"display_name" => "General Election"}
    @h_ballot["contest_list"] = []
  end
  
  def end_ballot
    gen_precinct_list
    @h_ballot["precinct_list"] = @h_precincts
    @h_ballot["jurisdiction_display_name"] = "middleworld"
    @h_ballot["type"] = "jurisdiction_slate"
    @h_file << @h_ballot
  end
  
  def gen_precinct_list
    @h_precincts = []
    @precincts.each do |key, value|
      @h_precincts << 
        { "voting_places" =>
            [{ "ballot_counters" => 2,
              "ident" => "vplace-xxx"}
            ],
          "display_name" => key,
          "ident" => value,
          "district_list" =>
            [{ "ident" => value,
               "display_name" => key}
            ]
        }
    end
  end
  
  def start_contest(name, rule)
    @h_contest = {"display_name" => name}
    @h_contest["district_ident"] = @prec_id
    @h_contest["ident"] = "cont-xx"
    @h_contest["candidates"] = []
    add_rule(rule)
  end
  
  def end_contest
    @h_ballot["contest_list"] << @h_contest
 end
 
  def add_rule(rule)
    @rules[rule] = 1
  end
  
  def add_candidate(name, party)
    @parties[party] = "party-#{@parties.length}"
    @candidates[name] = "cand-#{@candidates.length}"

    @h_contest["candidates"] << 
      {"party_ident" => @parties[party], 
       "ident" => @candidates[name],
       "display_name" => name}
    @parties[party] = party
    @candidates[name] = party
  end
end

g = Generator.new
p = Parser.new(ARGV[0], g)
p.parse_file
YAML.dump(g.h_file[0], File.new(ARGV[0]+".yml", "w"))


