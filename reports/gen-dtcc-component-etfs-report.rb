#!/usr/bin/env ruby

require 'csv'
require 'redis'
require 'json'

# open redis db
$redisdb = Redis.new
$redisdb.select 0

#
# create a csv file of components and the etf baskets
#
# 100,A,ETFA, ETFB, ETFC,....
# 11,B,ETFD, EFTF,...
# 110,C,ETFA,ETFF,...
#
headers_a = [
  "Component CUSIP",
  "Component Ticker",
  "Count",
  "ETF Baskets"
  ]
CSV.open("dtcc-component-etfs-report.csv", "wb", :headers => headers_a, :write_headers => true) do |csv|
  keys = $redisdb.keys "DTCC:COMPONENT:*"
  keys.each do |key|
    ccusip = $redisdb.hget key, "CUSIP"
    csym = $redisdb.hget "SECURITIES:XREF:#{ccusip}", "DTCC"
    
    json = $redisdb.hget key, "Baskets"
    if json
      hash = JSON.parse json
      arr = Array.new
      hash.each_key do |bcusip|
        bsym = $redisdb.hget "SECURITIES:XREF:#{bcusip}", "DTCC"
        arr << bsym
      end
      
      csv << [ccusip, csym, arr.length] + arr
    end
  end
end

=begin rdoc
 * Name: gen-dtcc-component-etfs-report.rb
 * Description: Creates a report of security(s) and all the etfs it is part of.
 * Call using "ruby comp-etfs-report.rb [-i<input file>]"  
 * Author: Murthy Gudipati
 * Date: 12-Jul-2011
 * License: Saven Technologies Inc.
=end