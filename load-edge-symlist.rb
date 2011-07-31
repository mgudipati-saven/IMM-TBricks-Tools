require 'csv'
require 'redis'
require 'getoptlong'
require 'json'
require_relative 'common'

# call using "ruby load-symbol-list.rb -i<file>"  
unless ARGV.length >= 1
  puts "Usage: ruby load-xignite.rb -i<file>" 
  exit  
end  
  
infile = ''
# specify the options we accept and initialize the option parser  
opts = GetoptLong.new(  
  [ "--infile", "-i", GetoptLong::REQUIRED_ARGUMENT ]
)  

# process the parsed options  
opts.each do |opt, arg|  
  case opt  
    when '--infile'  
      infile = arg
  end  
end

$redisdb = Redis.new
$redisdb.select 0

#
# Process the Direct Edge symbol list file
# 
# Redis layout is as follows:
# Key => EDGA:#{TickerSymbol}
# Value => Hashtable {"TickerSymbol", "CUSIP", ...}
#
if infile && File.exist?(infile)
  securities = parse_edge_symbol_list_file(infile)
  securities.each do |aSecurity|
    $redisdb.hmset  "EDGA:#{aSecurity.tickerSymbol}",
      "TickerSymbol", aSecurity.tickerSymbol,
      "CUSIP", aSecurity.cusip,
      "Name", aSecurity.name,
      "Lot", aSecurity.lot,
      "BoardLot", aSecurity.boardLot
  end
else
  puts "File not found #{infile}"
end # if File.exist?(infile)

=begin rdoc
 * Name: load-symbol-list.rb
 * Description: Loads the symbol list file into redis
 * Author: Murthy Gudipati
 * Date: 08-Jul-2011
 * License: Saven Technologies Inc.
=end