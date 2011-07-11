#!/usr/bin/env ruby

require 'csv'
require 'builder'
require 'getoptlong'
require_relative 'common'

# call using "ruby nscc2tbxml.rb -i<input file>"  
unless ARGV.length == 1
  puts "Usage: ruby nscc2tbxml.rb -i<input file>" 
  exit  
end  
  
infile = ''
# specify the options we accept and initialize the option parser  
opts = GetoptLong.new(  
  [ "--infile", "-i", GetoptLong::REQUIRED_ARGUMENT ]
)  

# process the parsed options  
opts.each do |opt, arg|  
  case opt  
    when '--infile'  
      infile = arg  
  end  
end

baskets = Array.new
if infile && File.exist?(infile)
  baskets = parse_nscc_basket_composition_file(infile)
  #puts "Basket count => #{baskets.length}"
else
  puts "File not found #{infile}"
end # if File.exist?(infile)

# build the tbricks stub basket instruments xml file
create_stub_basket_instruments_xml("stub-basket-instruments.xml", baskets)

# build the tbricks basket components xml file
create_basket_components_xml("basket-components.xml", baskets)

# build the tbricks instruments xml file from the basket components
securities = Hash.new
baskets.each do |aBasket|
  securities[aBasket.tickerSymbol] = aBasket
  aBasket.components.each do |aComponent|
    securities[aComponent.tickerSymbol] = aComponent
  end
end
create_tbricks_instruments_xml("instruments.xml", securities.values)

=begin rdoc
 * Name: nscc2tbxml.rb
 * Description: Converts DTCC file into TBricks xml files.
 * Author: Murthy Gudipati
 * Date: 26-Jun-2011
 * License: Saven Technologies Inc.
=end