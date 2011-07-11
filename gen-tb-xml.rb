require 'inifile'
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

# NYSE group symbol file
nyse_grp_sym_file = in_params['NYSEGrpSymFile'].strip

# Output parameters
out_params = ini_file['Output']

# Instrument Reference Data XML
instrument_reference_data_file = out_params['InstrumentReferenceData'].strip

# Basket Stub Instruments XML
basket_stub_instruments_file = out_params['BasketStubInstruments'].strip

# Basket Components XML
basket_components_file = out_params['BasketComponents'].strip

# Master securities map
$securities_by_ticker = Hash.new
$securities_by_cusip = Hash.new

# creates securities maps - by ticker, by cusip
def create_securities_maps(securities)
  securities.each do |aSecurity|
    # create a map keyed by ticker symbol
    if aSecurity.tickerSymbol != nil
      $securities_by_ticker[aSecurity.tickerSymbol] = aSecurity
    end

    # create a map keyed by cusip
    if aSecurity.cusip != nil
      $securities_by_cusip[aSecurity.cusip] = aSecurity
    end
  end
end

case src  
  when 'redis'  
    # use redis db as the source for securities master list
  
  when 'xignite'
    # use xignite files as the source for securities master list
    # Process all the xignite master securities files
    xfiles.split(',').each do |aFile|
      aFile = aFile.strip
      if aFile && File.exist?(aFile)
        securities = parse_xignite_master_securities_file(aFile)
        create_securities_maps(securities)
      else
        puts "File not found #{aFile}"
      end # if File.exist?(aFile)
    end # for each aFile  
    
  when 'nysegrp'
    # use nyse grp sym file as the source for securities master list
    if nyse_grp_sym_file && File.exist?(nyse_grp_sym_file)
      securities = parse_nyse_grp_sym_file(nyse_grp_sym_file)
      #p securities
      create_securities_maps(securities)
      puts "---num securities by ticker = #{$securities_by_ticker.length}---"
      puts "---num securities by cusip = #{$securities_by_cusip.length}---"
    else
      puts "File not found #{nyse_grp_sym_file}"
      exit
    end # if File.exist?(nyse_grp_sym_file) 
end

# build the tbricks instruments xml file
create_tbricks_instruments_xml(instrument_reference_data_file, $securities_by_ticker.values)

# Process NSCC file
baskets = Array.new
missing_cusips = Array.new
if nscc_file && File.exist?(nscc_file)
  baskets = parse_nscc_basket_composition_file(nscc_file)
  #p baskets
  # symbology conversion
  baskets.each do |aBasket|
    if $securities_by_cusip["#{aBasket.cusip}"] == nil then puts "---missing etf---#{aBasket.tickerSymbol}" end
    aBasket.components.each do |aComponent|
      sec = $securities_by_cusip["#{aComponent.cusip}"]
      if sec != nil
        aComponent.tickerSymbol = sec.tickerSymbol
      else
        missing_cusips.push(aComponent.cusip)
      end
    end
  end
else
  puts "File not found #{nscc_file}"
  exit
end # if File.exist?(nscc_file)

# build the stub basket instruments xml file
create_stub_basket_instruments_xml(basket_stub_instruments_file, baskets)

# build the basket components xml file
create_basket_components_xml(basket_components_file, baskets)

if missing_cusips.length != 0
  puts "---missing cusips = #{missing_cusips.length}---"
  missing_cusips.each do |cusip|
    puts cusip
  end
end

=begin rdoc
 * Name: gen-tb-xml.rb
 * Description: Generates tbricks xml files.
 * Author: Murthy Gudipati
 * Date: 26-Jun-2011
 * License: Saven Technologies Inc.
=end
