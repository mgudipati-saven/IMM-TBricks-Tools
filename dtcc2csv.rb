#!/usr/bin/env ruby

require 'csv'
require 'getoptlong'
require_relative 'common'

# call using "ruby dtcc2csv.rb -i<input file>"  
unless ARGV.length == 1
  puts "Usage: ruby dtcc2csv.rb -i<input file>" 
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

baskets = Array.new
if infile && File.exist?(infile)
  baskets = parse_nscc_basket_composition_file(infile)
  #p baskets
  #puts "Basket count => #{baskets.length}"
  # create a csv file of basket records
  headers_a = [
    "Index Receipt Symbol",
    "Index Receipt CUSIP",
    "When Issued Indicator",
    "Foreign Indicator",
    "Exchange Indicator",
    "Portfolio Trade Date",
    "Component Count",
    "Create or Redeem Units per Trade",
    "Estimated T-1 Cash Amount Per Creation Unit",
    "Estimated T-1 Cash Per Index Receipt",
    "Net Asset Value Per Creation Unit",
    "Net Asset Value Per Index Receipt",
    "Total Cash Amount Per Creation Unit",
    "Total Shares Outstanding Per ETF",
    "Dividend Amount Per Index Receipt",
    "Cash or Security Indicator"
    ]
  CSV.open("dtcc-baskets.csv", "wb", :headers => headers_a, :write_headers => true) do |csv|
    baskets.each do |aBasket|
      csv << [
        aBasket.tickerSymbol,
        aBasket.cusip,
        aBasket.whenIssuedIndicator,
        aBasket.foreignIndicator,
        aBasket.exchangeIndicator,
        aBasket.tradeDate,
        aBasket.componentCount,
        aBasket.creationUnitsPerTrade,
        aBasket.estimatedT1CashAmountPerCreationUnit,
        aBasket.estimatedT1CashPerIndexReceipt,
        aBasket.navPerCreationUnit,
        aBasket.navPerIndexReceipt,
        aBasket.totalCashAmount,
        aBasket.totalSharesOutstanding,
        aBasket.dividendAmount,
        aBasket.cashIndicator
        ]
    end
  end
  
  # create csv files of components - one for each basket
  headers_a = [
    "Component Ticker Symbol",
    "Component CUSIP",
    "Component Share Qty"
    ]
  baskets.each do |aBasket|
    CSV.open("dtcc-components-#{aBasket.tickerSymbol}.csv", "wb", :headers => headers_a, :write_headers => true) do |csv|
      aBasket.components.each do |aComponent|
        csv << [
          aComponent.tickerSymbol,
          aComponent.cusip,
          aComponent.shareQuantity
          ]
      end
    end
  end
else
  puts "File not found #{infile}"
end # if File.exist?(infile)

=begin rdoc
 * Name: dtcc2csv.rb
 * Description: Converts DTCC file into csv files.
 * Author: Murthy Gudipati
 * Date: 12-Jul-2011
 * License: Saven Technologies Inc.
=end