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

# Process the NSCC basket composition file
# NSCC file layout is defined as:
# Header record describing the basket information
# Basket component records
# => 01WREI           18383M47200220110624000000950005000000000000000291+0000000000000+0000162471058+0000000003249+0000000004503+0000005000000000000000000+
# => 02AKR            0042391090002011062400000193WREI           18383M472002
# => 02ALX            0147521090002011062400000013WREI           18383M472002
# => ...
baskets = Array.new
if infile && File.exist?(infile)
  nscc = NSCC.new(infile)
  baskets = nscc.baskets
else
  puts "File not found #{infile}"
end # if File.exist?(infile)

# build the stub basket instruments xml file
create_stub_basket_instruments_xml("stub-basket-instruments.xml", baskets)

# build the basket components xml file
create_basket_components_xml("basket-components.xml", baskets)

=begin rdoc
 * Name: nscc2tbxml.rb
 * Description: Converts DTCC file into TBricks xml files.
 * Author: Murthy Gudipati
 * Date: 26-Jun-2011
 * License: Saven Technologies Inc.
=end