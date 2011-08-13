#!/usr/bin/env ruby

require 'csv'
require 'redis'
require 'json'

$redisdb = Redis.new
$redisdb.select 0

# basket cusip array
$bcusip_a = Array.new
keys = $redisdb.keys "DTCC:BASKET:*"
keys.each do |key|
  $bcusip_a << ($redisdb.hget key, "IndexReceiptCUSIP")
end

# returns an array of all the values for all the baskets for the given field
def get_array(field)
  arr = [field]
  $bcusip_a.each do |bcusip|
    val = $redisdb.hget "DTCC:BASKET:#{bcusip}", field
    arr.push(val)
  end
  
  return arr
end

#
# create "All-All" file for Mike Conners...basket header fields followed by constituents layedout vertically
# Index Receipt Symbol,A,B,C,D,E,F,...
# CUSIP,123456789,123456780,...
# ...
# ...
# AAA,1000.0,,,,100,10....
# BBB,100.0,12,111,2,....
# ...
headers_a = [
  "IndexReceiptSymbol",
  "IndexReceiptCUSIP",
  "WhenIssuedIndicator",
  "ForeignIndicator",
  "ExchangeIndicator",
  "PortfolioTradeDate",
  "ComponentCount",
  "CreationUnitsPerTrade",
  "EstimatedT1CashAmountPerCreationUnit",
  "EstimatedT1CashPerIndexReceipt",
  "NAVPerCreationUnit",
  "NAVPerIndexReceipt",
  "TotalCashAmount",
  "TotalSharesOutstanding",
  "DividendAmount",
  "CashIndicator"
  ]
CSV.open("dtcc-all-all-report.csv", "wb") do |csv|
  # Basket header rows...Index Receipt Symbol, ...
  headers_a.each do |header|
    keys = $redisdb.keys "DTCC:BASKET:*"
    arr = [header]
    keys.each do |key|
      arr << ($redisdb.hget key, header)
    end

    csv << arr
  end

  # component rows...IBM, ...
  keys = $redisdb.keys "DTCC:COMPONENT:*"
  keys.each do |key|
    ccusip = $redisdb.hget key, "CUSIP"
    csym = $redisdb.hget "SECURITIES:XREF:#{ccusip}", "DTCC"

    if csym and csym != ''
      arr = [csym]
      json = $redisdb.hget key, "Baskets"
      if json
        basket_h = JSON.parse json
        $bcusip_a.each do |bcusip|
          qty = basket_h[bcusip]
          arr << (qty ? qty : '')
        end
      end

      csv << arr
    end
  end
end

=begin rdoc
 * Name: dtcc-all-all-report.rb
 * Description: Converts DTCC file into csv files.
 * Author: Murthy Gudipati
 * Date: 12-Jul-2011
 * License: Saven Technologies Inc.
=end