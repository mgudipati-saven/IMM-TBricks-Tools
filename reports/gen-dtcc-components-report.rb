#!/usr/bin/env ruby

require 'csv'
require 'redis'
require 'json'

# open redis db
$redisdb = Redis.new
$redisdb.select 0

# create csv files of components - one for each basket
headers_a = [
  "Component CUSIP",
  "Component Ticker Symbol",
  "Component Share Qty"
  ]
# AAA,123456789,1000.0
# BBB,123456780,1000.0
# ...
keys = $redisdb.keys "DTCC:BASKET:*"
keys.each do |key|
  bsym = $redisdb.hget key, "IndexReceiptSymbol"
  CSV.open("#{bsym}.csv", "wb", :headers => headers_a, :write_headers => true) do |csv|
    json = $redisdb.hget key, "Components"
    if json
      hash = JSON.parse json
      hash.each do |ccusip, qty|
        csv << [
          ccusip,
          ($redisdb.hget "SECURITIES:XREF:#{ccusip}", "DTCC"),
          qty
          ]
      end
    end
  end
end

=begin rdoc
 * Name: gen-dtcc-components-report.rb
 * Description: Converts DTCC file into csv files.
 * Author: Murthy Gudipati
 * Date: 12-Jul-2011
 * License: Saven Technologies Inc.
=end