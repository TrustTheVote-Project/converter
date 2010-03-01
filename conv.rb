#!/usr/bin/env ruby
=begin
  * Name: conv
  * Description: TTV File Converter
  * Author: Pito Salas
  * Copyright: (c) R. Pito Salas and Associates, Inc.
  * Date: January 2010
  * License: GPL

  This is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Ballot-Analyzer.  If not, see <http://www.gnu.org/licenses/>.

=end
require 'rubygems'
require 'yaml'
require 'pp'
require 'getoptlong'
require 'pathname'
require 'parser'
require 'generator'

#
# Main Program: Parse the command line and do the work
#
HELPTEXT = "TTV File Coverter.
Converts text file with ballot info into TTV standard data layer
Usage:
    conv [-options] file

 Options:
     -h   display help text
     -f   format code. -fNH - New Hampshire Ballot.txt
     -o   optional destination folder
"
opts = GetoptLong.new(
      ["-h", "--help", GetoptLong::NO_ARGUMENT],
      ["-f", "--format", GetoptLong::REQUIRED_ARGUMENT],
      ["-o", "--output", GetoptLong::REQUIRED_ARGUMENT])
@format = nil
@dir = Pathname.new(".")
opts.each do |opt, arg|
  case opt
    when "-h"
      puts HELPTEXT
      exit 0
    when "-f"
      @format = arg
      break
    when "-o"
      @dir = Pathname.new(arg)
      if @dir.exist? && !@dir.directory?
        puts "#{arg} doesn't seem to be a directory" unless @dir.directory?
        exit 0
    end
  end
end

if ARGV.length != 1
  puts "Missing file argument (try --help)"
  exit 0
end

# command line is parsed. Now lets do the work

gen = Generator.new
par = Parser.new(ARGV[0], gen)
par.parse_file

@dir.mkdir unless @dir.directory?
@dir = @dir.realpath
i = 0
gen.h_file.each do |ballot|
  i += 1
  puts "ballot #{i}: #{ballot["precinct_list"][0]["display_name"]}"
end
gen.h_file.each do |ballot|
  @file = @dir + "#{ballot["precinct_list"][0]["display_name"]}.yml"
  puts "writing file #{@file}"
  @file.open("w") do |file| 
    YAML.dump(ballot, file)
  end
end
