require 'csv'
require 'redis'
require 'getoptlong'
require_relative 'common'

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
# Load the nyse group symbol file into redis db
# 
# Redis layout is as follows:
# Key => ARCX:#{TickerSymbol} for NYSE ARCA
# Value => Hashtable {"TickerSymbol" => "IBM", "CUSIP" => "123456789", ...}
#
# Key => XASE:#{TickerSymbol} for NYSE AMEX
# Value => Hashtable {"TickerSymbol" => "IBM", "CUSIP" => "123456789", ...}
#
# Key => XNYS:#{TickerSymbol} for NYSE
# Value => Hashtable {"TickerSymbol" => "IBM", "CUSIP" => "123456789", ...}
#
# Key => SECURITIES:XREF:#{CUSIP}
# Value => Hashtable {"CUSIP" => "123456789", "ARCX" => "IBM", "XASE" => "IBM", "XNYS" => "IBM"}
#
if infile && File.exist?(infile)
  securities_a = parse_nyse_grp_sym_file(infile)
  securities_a.each do |aSecurity|
    if aSecurity.cusip
      mic = nil
      case aSecurity.exchange
        when 'A' # AMEX
          mic = "XASE"
        when 'N' # NYSE
          mic = "XNYS"
        when 'P' # ARCA
          mic = "ARCX"
      end
      if mic
        # update the exchange record for this cusip
        $redisdb.hmset "#{mic}:#{aSecurity.cusip}",
                        "CUSIP", aSecurity.cusip,
                        "TickerSymbol", aSecurity.tickerSymbol,
                        "Exchange", aSecurity.exchange,
                        "CompanyName", aSecurity.companyName,
                        "IndustryCode", aSecurity.industryCode,
                        "IndustryName", aSecurity.industryName,
                        "SuperSectorCode", aSecurity.superSectorCode,
                        "SuperSectorName", aSecurity.superSectorName,
                        "SectorCode", aSecurity.sectorCode,
                        "SectorName", aSecurity.sectorName,
                        "SubSectorCode", aSecurity.subSectorCode,
                        "SubSectorName", aSecurity.subSectorName
      end
      
      # update securities cross-reference record for this cusip
      $redisdb.hmset  "SECURITIES:XREF:#{aSecurity.cusip}",
        "CUSIP", aSecurity.cusip,
        "#{mic}", aSecurity.tickerSymbol      
    end
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