require 'inifile'
require 'csv'
require 'builder'
require_relative 'common'

# Read the INI file
ini_file = IniFile.load('tbxml.ini')

# Input parameters
in_params = ini_file['Input']

# Source of data - redis or files
src = in_params['Source']

# Comma separated list of xignite files
xfiles = in_params['XigniteFiles']

# NSCC basket composition file
nscc_file = in_params['NSCCFile'].strip

# Output parameters
out_params = ini_file['Output']

# Instrument Reference Data XML
instrument_reference_data_file = out_params['InstrumentReferenceData'].strip

# Basket Stub Instruments XML
basket_stub_instruments_file = out_params['BasketStubInstruments'].strip

# Basket Components XML
basket_components_file = out_params['BasketComponents'].strip

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

# build the tbricks instruments xml file
create_tbricks_instruments_xml(instrument_reference_data_file, securities_by_ticker.values)

# Process NSCC file
baskets = Array.new
if nscc_file && File.exist?(nscc_file)
  baskets = parse_nscc_basket_composition_file(nscc_file)
else
  puts "File not found #{nscc_file}"
end # if File.exist?(nscc_file)

# build the stub basket instruments xml file
create_stub_basket_instruments_xml(basket_stub_instruments_file, baskets)

# build the basket components xml file
create_basket_components_xml(basket_components_file, baskets)

