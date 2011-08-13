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

# prints db stats
def print_stats
  puts "DTCC DB Stats:"
  ver = $redisdb.get "DTCC:VERSION"
  puts "\tVersion: #{ver}"
  keys = $redisdb.keys "DTCC:BASKET:*"
  puts "\tNum Baskets: #{keys.length}"
  keys = $redisdb.keys "DTCC:COMPONENT:*"
  puts "\tNum Components: #{keys.length}"
end

# flush the db records for keys DTCC:* and delete DTCC symbols from xref
def flush_db
  keys = $redisdb.keys "DTCC:*"
  keys.each do |aKey|
    $redisdb.del aKey
  end    
  keys = $redisdb.keys "SECURITIES:XREF:*"
  keys.each do |aKey|
    $redisdb.hdel aKey, "DTCC"
  end
  puts "Flushed out current db records for keys DTCC:*..."
end

#
# Redis layout is as follows:
# Key => DTCC:BASKET:#{Index Receipt CUSIP}
# Value => Hashtable {"IndexReceiptSymbol" => "SPY", "CreationUnit" => "50000", "Components" => json object of components hash}
#
# Key => DTCC:COMPONENT:#{CUSIP}
# Value => Hashtable {"CUSIP" => "123456789", "Baskets" => json object of baskets hash}
#
# Key => SECURITIES:XREF:#{CUSIP}
# Value => Hashtable {"CUSIP" => "123456789", "DTCC" => "IBM"}
#
if infile && File.exist?(infile)
  baskets_a = parse_nscc_basket_composition_file(infile)
  
  if baskets_a and baskets_a.length != 0
    # report current stats
    print_stats
    
    # flush the current db records
    flush_db
  end
  
  # update dtcc version
  $redisdb.set "DTCC:VERSION", infile
  
  # components to baskets hash
  c2b_h = Hash.new
  
  baskets_a.each do |aBasket| 
    # create a new basket record
    $redisdb.hmset "DTCC:BASKET:#{aBasket.cusip}",
    					      "IndexReceiptCUSIP", aBasket.cusip,
    					      "IndexReceiptSymbol", aBasket.tickerSymbol,
    					      "WhenIssuedIndicator", aBasket.whenIssuedIndicator,
    					      "ForeignIndicator", aBasket.foreignIndicator,
    					      "ExchangeIndicator", aBasket.exchangeIndicator,
    					      "PortfolioTradeDate", aBasket.tradeDate,
    					      "ComponentCount", aBasket.componentCount,
                    "CreationUnitsPerTrade", aBasket.creationUnitsPerTrade,
    					      "EstimatedT1CashAmountPerCreationUnit", aBasket.estimatedT1CashAmountPerCreationUnit,
    					      "EstimatedT1CashPerIndexReceipt", aBasket.estimatedT1CashPerIndexReceipt,
    					      "NAVPerCreationUnit", aBasket.navPerCreationUnit,
    					      "NAVPerIndexReceipt", aBasket.navPerIndexReceipt,
    					      "TotalCashAmount", aBasket.totalCashAmount,
    					      "TotalSharesOutstanding", aBasket.totalSharesOutstanding,
    					      "DividendAmount", aBasket.dividendAmount,
                    "CashIndicator", aBasket.cashIndicator

    # update securities cross-reference record for this basket
    $redisdb.hmset "SECURITIES:XREF:#{aBasket.cusip}",
      "CUSIP", aBasket.cusip,
      "DTCC", aBasket.tickerSymbol
                    
    # store the basket components
    if aBasket.components
      components_h = Hash.new
      aBasket.components.each do |ccusip, aComponent|
        # component cusip => share qty
        components_h[ccusip] = aComponent.shareQuantity
        
        # basket cusip => share qty
        if !c2b_h.key?(ccusip)
          c2b_h[ccusip] = Hash.new
        end
        c2b_h[ccusip][aBasket.cusip] = aComponent.shareQuantity
        
        # update securities cross-reference record for this component
        $redisdb.hmset "SECURITIES:XREF:#{aComponent.cusip}",
          "CUSIP", aComponent.cusip,
          "DTCC", aComponent.tickerSymbol        
      end
      
      # Key => DTCC:BASKET:#{Index Receipt CUSIP}
      # Value => Hashtable {"IndexReceiptSymbol" => "SPY", "CreationUnit" => "50000", "Components" => json object of components hash}
      json = JSON.generate components_h
      $redisdb.hset "DTCC:BASKET:#{aBasket.cusip}", "Components", json
    end                              
  end

  # Key => DTCC:COMPONENT:#{CUSIP}
  # Value => Hashtable {"CUSIP" => "123456789", "Baskets" => json object of baskets hash}
  c2b_h.each do |ccusip, hash|
    json = JSON.generate hash
    $redisdb.hmset "DTCC:COMPONENT:#{ccusip}", "CUSIP", ccusip, "Baskets", json
  end

  # report new stats
  print_stats
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