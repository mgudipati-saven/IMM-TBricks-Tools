require 'csv'
require 'redis'
require 'getoptlong'
require 'json'
require_relative 'common'

# call using "ruby load-nsx-symlist.rb -i<file>"  
unless ARGV.length >= 1
  puts "Usage: ruby load-nsx-symlist.rb -i<file>" 
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
# Process the NSX symbol list file
# 
# Redis layout is as follows:
# Key => XCIS:#{TickerSymbol}
# Value => Hashtable {"TickerSymbol", "CUSIP", ...}
#
# Key => SECURITIES:XREF:#{CUSIP}
# Value => Hashtable {"CUSIP" => "123456789", "XCIS" => "IBM"}
#
if infile && File.exist?(infile)
  securities = parse_nsx_symbol_list_file(infile)
  securities.each do |aSecurity|
    # update nsx records
    $redisdb.hmset  "XCIS:#{aSecurity.tickerSymbol}",
      "TickerSymbol", aSecurity.tickerSymbol,
      "CUSIP", aSecurity.cusip,
      "Tape", aSecurity.tape

    # update securities cross-reference record for this cusip
    $redisdb.hmset  "SECURITIES:XREF:#{aSecurity.cusip}",
      "CUSIP", aSecurity.cusip,
      "XCIS", aSecurity.tickerSymbol
    
  end
else
  puts "File not found #{infile}"
end # if File.exist?(infile)

=begin rdoc
 * Name: load-nsx-symlist.rb
 * Description: Loads the symbol list file into redis
 * Author: Murthy Gudipati
 * Date: 08-Aug-2011
 * License: Saven Technologies Inc.
=end