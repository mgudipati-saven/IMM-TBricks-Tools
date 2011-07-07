require 'csv'
require 'redis'
require 'getoptlong'
require 'json'

# call using "ruby load-xignite.rb -i<file1, file2, ...> [-o<file>]"  
unless ARGV.length >= 1
  puts "Usage: ruby load-xignite.rb -i<file1, file2, ...> [-o<file>]" 
  exit  
end  
  
infiles = ''
outfile = "instruments.xml"
# specify the options we accept and initialize the option parser  
opts = GetoptLong.new(  
  [ "--infile", "-i", GetoptLong::REQUIRED_ARGUMENT ],  
  [ "--outfile", "-o", GetoptLong::REQUIRED_ARGUMENT ]
)  

# process the parsed options  
opts.each do |opt, arg|  
  case opt  
    when '--infile'  
      infiles = arg
    when '--outfile'  
      outfile = arg  
  end  
end

$redisdb = Redis.new
$redisdb.select 0

#
# Process all the xignite master securities files
#
# Xignite master securities file layout is defined as follows:
# => " Exchange"," Count"," Records Record Symbol"," Records Record CUSIP"," Records Record CIK"," Records Record ISIN"," Records Record SEDOL"," Records Record Valoren"," Records Record Exchange"," Records Record Name"," Records Record ShortName"," Records Record Issue"," Records Record Sector"," Records Record Industry"," Records Record LastUpdateDate",
# => For e.g. NYSE,3581,A,00846U101,0001090872,US00846U1016,2520153,901692,NYSE,"Agilent Technologies Inc.","Agilent Tech Inc","Common Stock",TECHNOLOGY,"Scientific & Technical Instruments",12/3/2005,
#
# Redis layout is as follows:
# Key => XIGNITE:SECURITIES:BYTICKER:#{TickerSymbol}
# Value => Hashtable {"TickerSymbol", "CUSIP", ...}
#
# Key => XIGNITE:SECURITIES:BYCUSIP:#{CUSIP}
# Value => Hashtable {"TickerSymbol"}
#
infiles.split(',').each do |infile|
  infile = infile.strip
  if infile && File.exist?(infile)
    CSV.foreach(infile, :quote_char => '"', :col_sep =>',', :row_sep => :auto, :headers => true) do |row|
      ticker = row.field(' Records Record Symbol')
      if ticker != ''
        $redisdb.hmset  "XIGNITE:SECURITIES:BYTICKER:#{ticker}",
          "TickerSymbol", row.field(' Records Record Symbol'),
          "CUSIP", row.field(' Records Record CUSIP'),
          "CIK", row.field(' Records Record CIK'),
          "ISIN", row.field(' Records Record ISIN'),
          "SEDOL", row.field(' Records Record SEDOL'),
          "Valoren", row.field(' Records Record Valoren'),
          "Exchange", row.field(' Records Record Exchange'),
          "Name", row.field(' Records Record Name'),
          "ShortName", row.field(' Records Record ShortName'),
          "Issue", row.field(' Records Record Issue'),
          "Sector", row.field(' Records Record Sector'),
          "Industry", row.field(' Records Record Industry')
      end      

      cusip = row.field(' Records Record CUSIP')
      if cusip != ''
        $redisdb.hset "XIGNITE:SECURITIES:BYCUSIP:#{cusip}", 
          "TickerSymbol", row.field(' Records Record Symbol')
      end
    end # CSV.foreach
  else
    puts "File not found #{infile}"
  end # if File.exist?(infile)
end # for each infile  

=begin rdoc
 * Name: load-xignite.rb
 * Description: Loads the xignite files into redis
 * Author: Murthy Gudipati
 * Date: 06-Jul-2011
 * License: Saven Technologies Inc.
=end