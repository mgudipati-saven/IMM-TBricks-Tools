require 'redis'
require 'getoptlong'
require 'json'
require_relative 'common'

# call using "ruby load-dtcc.rb -i<input file>"  
unless ARGV.length == 1
  puts "Usage: ruby load-dtcc.rb -i<input file>" 
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
# Process the NSCC basket composition file
# NSCC file layout is defined as follows:
# Header record describing the basket information
# => 01WREI           18383M47200220110624000000950005000000000000000291+0000000000000+0000162471058+0000000003249+0000000004503+0000005000000000000000000+
# Basket component records
# => 02AKR            0042391090002011062400000193WREI           18383M472002
# => 02ALX            0147521090002011062400000013WREI           18383M472002
# => ...
# Redis layout is as follows:
# Key => DTCC:BASKET:#{Index Receipt CUSIP}
# Value => Hashtable {"CUSIP" => "123456789, ""TickerSymbol" => "ETFA", "CreationUnit" => "50000", ...}
#
# Key => DTCC:COMP:#{CUSIP}
# Value => Hashtable {"CUSIP" => "123456789, ""TickerSymbol" => "IBM", "ETFA" => "500", "ETFB" => "100"}
#
if infile && File.exist?(infile)
  numrec = 0

  IO.foreach(infile) do |line|
    line.chomp!
    case line[0..1]
      when '01' #Basket Header
        numrec += 1

        #Index Receipt Symbol...Trading Symbol
        sym = line[2..16].strip

        #Index Receipt CUSIP...S&P assigned CUSIP
        cusip = line[17..25].strip

        #Create a component record
        $redisdb.hmset "DTCC:COMP:#{cusip}", "CUSIP", cusip, "TickerSymbol", sym

        #Create a redis key using the cusip and store the record
        key = "DTCC:BASKET:#{cusip}"
        $redisdb.hmset key, "CUSIP", cusip, "TickerSymbol", sym
	      
        #When Issued Indicator...0 = Regular Way 1 = When Issued
        $redisdb.hset key, "WhenIssuedIndicator", line[26]

        #Foreign Indicator...0 = Domestic 1 = Foreign
        $redisdb.hset key, "ForeignIndicator", line[27]

        #Exchange Indicator...0 = NYSE 1 = AMEX 2 = Other
        $redisdb.hset key, "ExchangeIndicator", line[28]

        #Portfolio Trade Date...CCYYMMDD
        $redisdb.hset key, "TradeDate", line[29..36]

        #Component Count...99,999,999
        $redisdb.hset key, "ComponentCount", line[37..44].to_i

        #Create/Redeem Units per Trade...99,999,999
        $redisdb.hset key, "CreationUnitsPerTrade", line[45..52].to_i

        #Estimated T-1 Cash Amount Per Creation Unit...999,999,999,999.99-
        val = "#{line[53..64]}.#{line[65..66]}".to_f
        sign = line[67]
        if sign == '-' then val *= -1 end
        $redisdb.hset key, "EstimatedT1CashAmountPerCreationUnit", val
        
        #Estimated T-1 Cash Per Index Receipt...99,999,999,999.99
        val = "#{line[68..78]}.#{line[79..80]}".to_f
        sign = line[81]
        if sign == '-' then val *= -1 end
        $redisdb.hset key, "EstimatedT1CashPerIndexReceipt", val

        #Net Asset Value Per Creation Unit...99,999,999,999.99
        val = "#{line[82..92]}.#{line[93..94]}".to_f
        sign = line[95]
        if sign == '-' then val *= -1 end
        $redisdb.hset key, "NAVPerCreationUnit", val

        #Net Asset Value Per Index Receipt...99,999,999,999.99
        val = "#{line[96..106]}.#{line[107..108]}".to_f
        sign = line[109]
        if sign == '-' then val *= -1 end
        $redisdb.hset key, "NAVPerIndexReceipt", val

        #Total Cash Amount Per Creation Unit...99,999,999,999.99-
        val = "#{line[110..120]}.#{line[121..122]}".to_f
        sign = line[123]
        if sign == '-' then val *= -1 end
        $redisdb.hset key, "TotalCashAmount", val

        #Total Shares Outstanding Per ETF...999,999,999,999
        $redisdb.hset key, "TotalSharesOutstanding", line[124..135].to_i

        #Dividend Amount Per Index Receipt...99,999,999,999.99
        val = "#{line[136..146]}.#{line[147..148]}".to_f
        sign = line[149]
        if sign == '-' then val *= -1 end        
        $redisdb.hset key, "DividendAmount", val

        #Cash / Security Indicator...  1 = Cash only 2 = Cash or components other – components only
        $redisdb.hset key, "CashIndicator", line[150]
      when '02' #Basket Component Detail
        numrec += 1

        #Component Symbol...Trading Symbol
        csym = line[2..16].strip

        #Component CUSIP...S&P assigned CUSIP
        ccusip = line[17..25].strip

        #Create a component record
        key = "DTCC:COMP:#{ccusip}"
        $redisdb.hsetnx key, "CUSIP", ccusip
        $redisdb.hsetnx key, "TickerSymbol", csym
        
        #Component Share Qty...99,999,999
        qty = line[37..44].to_f

        #Index Receipt CUSIP...S&P assigned CUSIP
        bcusip = line[60..68].strip
        
        #Update the component record with the share qty for the basket
        $redisdb.hset key, bcusip, qty
      when '09' #File Trailer
        numrec += 1

        # Record Count...99,999,999 Includes Records 01, 02, 09
        reccnt = line[37..44].to_i
        if numrec != reccnt
          puts "Error in DTCC File: records found:#{numrec} != records reported:#{reccnt}"
        end
    end
  end                    
else
  puts "File not found #{infile}"
end # if File.exist?(infile)

=begin rdoc
 * Name: load-dtcc.rb
 * Description: Loads the DTCC basket composition file into redis
 * Author: Murthy Gudipati
 * Date: 06-Jul-2011
 * License: Saven Technologies Inc.
=end