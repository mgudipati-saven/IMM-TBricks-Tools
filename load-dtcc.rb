require 'csv'
require 'redis'
require 'getoptlong'
require 'json'

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

# Process the DTCC basket composition file
# 
# DTCC file layout is defined as follows:
# Header record describing the basket information
# => 01WREI           18383M47200220110624000000950005000000000000000291+0000000000000+0000162471058+0000000003249+0000000004503+0000005000000000000000000+
# Basket component records
# => 02AKR            0042391090002011062400000193WREI           18383M472002
# => 02ALX            0147521090002011062400000013WREI           18383M472002
# => ...
# 
# Redis layout is as follows:
# Key => DTCC:BASKET:#{BasketTickerSymbol}
# Value => Hashtable {"IndexReceiptSymbol", "CreationUnit", etc...}
#
# Key => DTCC:BASKET:COMPONENTS:#{BasketTickerSymbol}
# Value => Sorted set of components as json objects {(Ticker, CUSIP, ShareQuantity), (...), ...}
if infile && File.exist?(infile)
  bticker = nil
  arr = nil
  IO.foreach(infile) do |line| 
    case line[0..1]
      when '01' # basket header record
        if bticker != nil
  	      # store the basket components
  	      json = JSON.generate arr
  	      $redisdb.hset "DTCC:BASKET:#{bticker}",
                        "Components", json
        end
                                    
        #Index Receipt Symbol...Trading Symbol
        bticker = line[2..16].strip
        arr = Array.new
        
        #Create/Redeem Units per Trade
        cunit = line[45..52].to_i

        #Total Cash Amount Per Creation Unit...99,999,999,999.99-
        cash = "#{line[110..120]}.#{line[121..122]}".to_f
        sign = line[123]
        if sign == '-' then cash *= -1 end

        #Net Asset Value Per Creation Unit...99,999,999,999.99
        nav = "#{line[82..92]}.#{line[93..94]}".to_f
        sign = line[95]
        if sign == '-' then nav *= -1 end

	      # create a new basket record
	      $redisdb.hmset  "DTCC:BASKET:#{bticker}",
	      					      "IndexReceiptSymbol", bticker,
                        "CreationUnit", cunit,
                        "TotalCashAmount", cash,
                        "NAV", nav
      when '02' # basket component detail record
        if bticker != nil
          # create a new basket component
          hash = Hash.new
          
          # Component Symbol...Trading Symbol
          hash['TickerSymbol'] = line[2..16].strip

          # Component CUSIP...S&P assigned CUSIP
          hash['CUSIP'] = line[17..25].strip

          #Component Share Qty...99,999,999
          hash['ShareQuantity '] = score = line[37..44].to_f

          arr.push(hash)
          # store it in a sorted set of basket components
  	      #json = JSON.generate hash
  	      #$redisdb.zadd "DTCC:BASKET:COMPONENTS:#{bticker}", score, json
        end
    end
  end
end

=begin rdoc
 * Name: load-dtcc.rb
 * Description: Loads the DTCC basket composition file into redis
 * Author: Murthy Gudipati
 * Date: 06-Jul-2011
 * License: Saven Technologies Inc.
=end