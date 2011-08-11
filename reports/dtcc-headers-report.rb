#!/usr/bin/env ruby

require 'csv'
require 'redis'

# open redis db
$redisdb = Redis.new
$redisdb.select 0

# create a csv file of basket records
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
# A,123456789,....
# B,123456780,....
# ...
CSV.open("etf-headers-report.csv", "wb", :headers => headers_a, :write_headers => true) do |csv|
  keys = $redisdb.keys "DTCC:BASKET:*"
  keys.each do |key|
    arr = Array.new
    headers_a.each do |header|
      arr << ($redisdb.hget key, header)
    end
    csv << arr
  end
end

