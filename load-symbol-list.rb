require 'csv'
require 'redis'
require 'getoptlong'
require 'json'

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
# Process the symbol list file
# Symbol list file layout is defined as follows:
# Header record:
# => CUSIP,Symbol,Ext,Company Name,Primary Market,Round Lot Size,Min Order Qty
#
# Data record:
# => 00846U101,A,,AGILENT TECHNOLOGIES INC,NYSE,100,0
# 
# Redis layout is as follows:
# Key => SYMLIST:SECURITIES:BYTICKER:#{TickerSymbol}
# Value => Hashtable {"TickerSymbol", "CUSIP", ...}
#
# Key => SYMLIST:SECURITIES:BYCUSIP:#{CUSIP}
# Value => Hashtable {"TickerSymbol"}
#
if infile && File.exist?(infile)
  CSV.foreach(infile, :quote_char => '"', :col_sep =>',', :row_sep => :auto, :headers => true) do |row|
    symbol = row.field('Symbol')
    ext = row.field('Ext')
    if ext != nil then symbol += ".#{ext}" end
  
    if symbol != nil then
      $redisdb.hmset  "SYMLIST:SECURITIES:BYTICKER:#{symbol}",
        "TickerSymbol", symbol,
        "CUSIP", row.field('CUSIP'),
        "Exchange", row.field('Primary Market'),
        "Name", row.field('Company Name'),
    end

    cusip = row.field('CUSIP')
    if cusip != nil
      $redisdb.hset "SYMLIST:SECURITIES:BYCUSIP:#{cusip}", 
        "TickerSymbol", symbol
    end
  end # CSV.foreach
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