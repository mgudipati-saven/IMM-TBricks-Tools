#!/usr/bin/env ruby -wKU
require 'csv'
require 'redis'
require 'json'

$redisdb = Redis.new

#
# create a csv file of components and their etf baskets
# 100, A, ETFA, ETFB, ETFC, ...
# 10, B, ETFB, ETFC, ...
# 20, C, ETFA, ETFC, ...
#
csv_headers = [
  "Count",
  "Component Ticker",
  "ETF Baskets"
  ]
CSV.open("comp-etfs.csv", "wb", :headers => csv_headers, :write_headers => true) do |csv|
  # obtain all the securities from EDGA exchange db
  security_keys = $redisdb.keys "EDGA:*"
  security_keys.each do |security_key|
    # for each security,
    security_ticker = $redisdb.hget security_key, "TickerSymbol"
    security_cusip = $redisdb.hget security_key, "CUSIP"

    # obtain the etf baskets it belongs to...
    arr = Array.new
    basket_keys = $redisdb.keys "DTCC:BASKET:*"
    basket_keys.each do |basket_key|
      basket_ticker = $redisdb.hget basket_key, "IndexReceiptSymbol"
      json = $redisdb.hget basket_key, "Components"
      if json
        hash = JSON.parse json
        if hash.key?(security_cusip)
          arr.push(basket_ticker)
        end
      end
    end
    
    # create a csv record
    csv << [arr.length, security_ticker] + arr
  end
end