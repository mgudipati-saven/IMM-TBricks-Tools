require 'csv'
require 'redis'
require 'getoptlong'

# call using "ruby load-nyse-grp-sym.rb -i<file>"  
unless ARGV.length >= 1
  puts "Usage: ruby load-nyse-grp-sym.rb -i<file>" 
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
# Process the nyse group symbol file
# Symbol file layout is defined as follows:
# Header record:
# => Symbol,CUSIP,CompanyName,NYSEGroupMarket,PrimaryMarket,IndustryCode,SuperSectorCode,SectorCode,SubSectorCode,IndustryName,SuperSectorName,SectorName,SubSectorName
#
# Data record:
# => AA,13817101,"ALCOA, INC",N,N,1000,1700,1750,1753,Basic Materials,Basic Resources,Industrial Metals & Mining,Aluminum
# 
# Redis layout is as follows:
# Key => NYSEGRP:SECURITIES:BYTICKER:#{TickerSymbol}
# Value => Hashtable {"TickerSymbol", "CUSIP", ...}
#
# Key => NYSEGRP:SECURITIES:BYCUSIP:#{CUSIP}
# Value => Hashtable {"TickerSymbol"}
#
if infile && File.exist?(infile)
  CSV.foreach(infile, :quote_char => '"', :col_sep =>',', :row_sep => :auto, :headers => true) do |row|
    symbol = row.field('Symbol')
    cusip = row.field('CUSIP').rjust(9, '0')
    if symbol != nil then
      # Symbology conversion...BRK A => BRK.A
      symbol = symbol.sub(" ", ".")
      $redisdb.hmset  "NYSEGRP:SECURITIES:BYTICKER:#{symbol}",
        "TickerSymbol", symbol,
        "CUSIP", cusip,
        "Exchange", row.field('PrimaryMarket'),
        "Name", row.field('CompanyName')

        if cusip != nil
          $redisdb.hset "NYSEGRP:SECURITIES:BYCUSIP:#{cusip}", 
            "TickerSymbol", symbol
        end
    else
      puts "Symbol nil in record => #{row}"
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