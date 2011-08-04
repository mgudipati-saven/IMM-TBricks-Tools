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
# Key => SECURITIES:XREF:#{CUSIP}
# Value => Hashtable {"CUSIP" => "123456789", "EDGA" => "IBM"}
#
if infile && File.exist?(infile)
  securities = parse_edge_symbol_list_file(infile)
  securities.each do |aSecurity|
    # update direct edge records
    $redisdb.hmset  "EDGA:#{aSecurity.tickerSymbol}",
      "TickerSymbol", aSecurity.tickerSymbol,
      "CUSIP", aSecurity.cusip,
      "Name", aSecurity.name,
      "Lot", aSecurity.lot,
      "BoardLot", aSecurity.boardLot

    # update securities cross-reference record for this cusip
    $redisdb.hmset  "SECURITIES:XREF:#{aSecurity.cusip}",
      "CUSIP", aSecurity.cusip,
      "EDGA", aSecurity.tickerSymbol
    
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