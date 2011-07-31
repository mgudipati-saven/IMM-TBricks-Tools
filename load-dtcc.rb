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
# Redis layout is as follows:
# Key => DTCC:BASKET:#{BasketTickerSymbol}
# Value => Hashtable {"IndexReceiptSymbol" => "SPY", "CreationUnit" => "50000", "Components" => json object(array of hashes)}
#
if infile && File.exist?(infile)
  baskets_a = parse_nscc_basket_composition_file(infile)
  baskets_a.each do |aBasket| 
    # create a new basket record
    $redisdb.hmset  "DTCC:BASKET:#{aBasket.tickerSymbol}",
    					      "IndexReceiptSymbol", aBasket.tickerSymbol,
    					      "WhenIssuedIndicator", aBasket.whenIssuedIndicator,
    					      "ForeignIndicator", aBasket.foreignIndicator,
    					      "ExchangeIndicator", aBasket.exchangeIndicator,
    					      "TradeDate", aBasket.tradeDate,
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
                    
    # store the basket components
    if aBasket.components
      hash = Hash.new
      aBasket.components.each do |aComponent|
        hash[aComponent.cusip] = aComponent.shareQuantity
      end
      json = JSON.generate hash
      $redisdb.hset "DTCC:BASKET:#{aBasket.tickerSymbol}", "Components", json
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