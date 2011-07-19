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

if infile && File.exist?(infile)
  baskets_a = parse_nscc_basket_composition_file(infile)
  
  # create a map of costituent tickers with share qty for each etf
  components_h = Hash.new
  baskets_a.each do |aBasket|
    aBasket.components.each do |aComponent|
      if aComponent.tickerSymbol != ''
        hash = components_h[aComponent.tickerSymbol]
        if !hash
          components_h[aComponent.tickerSymbol] = hash = Hash.new
        end
        hash[aBasket.tickerSymbol] = aComponent.shareQuantity
      end
    end
  end

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
  # A,123456789,....
  # B,123456780,....
  # ...
  CSV.open("dtcc-baskets.csv", "wb", :headers => headers_a, :write_headers => true) do |csv|
    baskets_a.each do |aBasket|
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
  baskets_a.each do |aBasket|
    # AAA,123456789,1000.0
    # BBB,123456780,1000.0
    # ...
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

  # create "All-All" file for Mike Conners...basket header fields followed by constituents layedout vertically
  # Index Receipt Symbol,A,B,C,D,E,F,...
  # CUSIP,123456789,123456780,...
  # ...
  # ...
  # AAA,1000.0,,,,100,10....
  # BBB,100.0,12,111,2,....
  # ...
  CSV.open("dtcc-all-all.csv", "wb") do |csv|
    # Basket header rows...Index Receipt Symbol, ...
    arr = ['Index Receipt Symbol']
    baskets_a.each do |aBasket|
      arr.push(aBasket.tickerSymbol)
    end
    csv << arr

    arr = ['Index Receipt CUSIP']
    baskets_a.each do |aBasket|
      arr.push(aBasket.cusip)
    end
    csv << arr
    
    arr = ['When Issued Indicator']
    baskets_a.each do |aBasket|
      arr.push(aBasket.whenIssuedIndicator)
    end
    csv << arr

    arr = ['Foreign Indicator']
    baskets_a.each do |aBasket|
      arr.push(aBasket.foreignIndicator)
    end
    csv << arr

    arr = ['Exchange Indicator']
    baskets_a.each do |aBasket|
      arr.push(aBasket.exchangeIndicator)
    end
    csv << arr

    arr = ['Portfolio Trade Date']
    baskets_a.each do |aBasket|
      arr.push(aBasket.tradeDate)
    end
    csv << arr

    arr = ['Component Count']
    baskets_a.each do |aBasket|
      arr.push(aBasket.componentCount)
    end
    csv << arr

    arr = ['Create or Redeem Units per Trade']
    baskets_a.each do |aBasket|
      arr.push(aBasket.creationUnitsPerTrade)
    end
    csv << arr

    arr = ['Estimated T-1 Cash Amount Per Creation Unit']
    baskets_a.each do |aBasket|
      arr.push(aBasket.estimatedT1CashAmountPerCreationUnit)
    end
    csv << arr

    arr = ['Estimated T-1 Cash Per Index Receipt']
    baskets_a.each do |aBasket|
      arr.push(aBasket.estimatedT1CashPerIndexReceipt)
    end
    csv << arr

    arr = ['Net Asset Value Per Creation Unit']
    baskets_a.each do |aBasket|
      arr.push(aBasket.navPerCreationUnit)
    end
    csv << arr

    arr = ['Net Asset Value Per Index Receipt']
    baskets_a.each do |aBasket|
      arr.push(aBasket.navPerIndexReceipt)
    end
    csv << arr  

    arr = ['Total Cash Amount Per Creation Unit']
    baskets_a.each do |aBasket|
      arr.push(aBasket.totalCashAmount)
    end
    csv << arr  

    arr = ['Total Shares Outstanding Per ETF']
    baskets_a.each do |aBasket|
      arr.push(aBasket.totalSharesOutstanding)
    end
    csv << arr  

    arr = ['Dividend Amount Per Index Receipt']
    baskets_a.each do |aBasket|
      arr.push(aBasket.dividendAmount)
    end
    csv << arr  

    arr = ['Cash or Security Indicator']
    baskets_a.each do |aBasket|
      arr.push(aBasket.cashIndicator)
    end
    csv << arr
    
    # Basket component rows...component, share qty, share qty, ...  
    components_h.each do |key, value|
      arr = [key]
      baskets_a.each do |aBasket|
        qty = value[aBasket.tickerSymbol]
        if !qty then qty = '' end
        arr.push(qty)
      end
      csv << arr
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