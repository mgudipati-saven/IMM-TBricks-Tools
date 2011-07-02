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

# Process the xignite master securities files
# Xignite master securities file layout is defined as:
# => " Exchange"," Count"," Records Record Symbol"," Records Record CUSIP"," Records Record CIK"," Records Record ISIN"," Records Record SEDOL"," Records Record Valoren"," Records Record Exchange"," Records Record Name"," Records Record ShortName"," Records Record Issue"," Records Record Sector"," Records Record Industry"," Records Record LastUpdateDate",
# => For e.g. NYSE,3581,A,00846U101,0001090872,US00846U1016,2520153,901692,NYSE,"Agilent Technologies Inc.","Agilent Tech Inc","Common Stock",TECHNOLOGY,"Scientific & Technical Instruments",12/3/2005,
securities_by_ticker = Hash.new
securities_by_cusip = Hash.new

xfiles.split(',').each do |aFile|
  if aFile && File.exist?(aFile.strip)
  	CSV.foreach(aFile.strip, :quote_char => '"', :col_sep =>',', :row_sep => :auto, :headers => true) do |row|
      sym = row.field(' Records Record Symbol')
      if sym != nil then
        # create a new security by passing the ticker symbol as argument
        security = Security.new(sym)

        # populate the attributes
        security.cusip = row.field(' Records Record CUSIP')
        security.cik = row.field(' Records Record CIK')
        security.isin = row.field(' Records Record ISIN')
        security.sedol = row.field(' Records Record SEDOL')
        security.valoren = row.field(' Records Record Valoren')
        security.exchange = row.field(' Records Record Exchange')
        security.name = row.field(' Records Record Name')
        security.shortName = row.field(' Records Record ShortName')
        security.issue = row.field(' Records Record Issue')
        security.sector = row.field(' Records Record Sector')
        security.industry = row.field(' Records Record Industry')
        
        # save in ticker map
        securities_by_ticker[sym] = security
        
        # save in cusip map
        if security.cusip != nil then securities_by_cusip[security.cusip] = security end
      end
  	end # CSV.foreach
  else
    puts "File not found #{aFile}"
  end # if File.exist?(aFile)
end # for each aFile  

puts "Num securities in ticker map: #{securities_by_ticker.length}"
puts "Num securities in cusip map: #{securities_by_cusip.length}"