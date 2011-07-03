require 'inifile'
require 'csv'
require_relative 'common'

# Read the INI file
ini_file = IniFile.load('tbxml.ini')

# Input parameters
in_params = ini_file['Input']

# Comma separated list of xignite files
xfiles = in_params['XigniteFiles']

# Output parameters
out_params = ini_file['Output']

# Process all the xignite master securities files
securities_by_ticker = Hash.new
securities_by_cusip = Hash.new

xfiles.split(',').each do |aFile|
  aFile = aFile.strip
  if aFile && File.exist?(aFile)
    securities = parse_xignite_master_securities_file(aFile)
    
    securities.each do |aSecurity|
      # create a map keyed by ticker symbol
      if aSecurity.tickerSymbol != nil
        securities_by_ticker[aSecurity.tickerSymbol] = aSecurity
      end

      # create a map keyed by cusip
      if aSecurity.cusip != nil
        securities_by_cusip[aSecurity.cusip] = aSecurity
      end
    end
  else
    puts "File not found #{aFile}"
  end # if File.exist?(aFile)
end # for each aFile  

p securities_by_ticker
p securities_by_cusip
puts "Num securities in ticker map: #{securities_by_ticker.length}"
puts "Num securities in cusip map: #{securities_by_cusip.length}"