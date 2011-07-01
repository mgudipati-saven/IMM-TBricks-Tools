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

if infile && File.exist?(infile)
  nscc = NSCC.new(infile)
  
  # build the stub basket instruments xml file
  #<?xml version="1.0" encoding="UTF-8"?>
  #<resource name="instruments" type="application/x-instrument-reference-data+xml">
  #  <instruments>
  #    <instrument short_name="EDZ Basket" long_name="" mnemonic="" precedence="yes" cfi="ESXXXX" price_format="decimal 2" deleted="no">
  #      <xml type="fixml"/>
  #      <groups/>
  #      <identifiers>
  #        <identifier venue="c0c78852-efd6-11de-9fb8-dfdb5824b38d" mic="XXXX">
  #          <fields>
  #            <field name="symbol" value="EDZ"/>
  #          </fields>
  #        </identifier>
  #      </identifiers>
  #    </instrument>
  #    ...
  #    ...
  #  </instruments>
  #</resource>
  f = File.new("stub-basket-instruments.xml", "w")
  xml = Builder::XmlMarkup.new(:target=>f, :indent=>2)
  xml.instruct!
  xml.resource("name"=>"instruments", "type"=>"application/x-instrument-reference-data+xml") {
    xml.instruments {
      #etfs.each_key do |key|
      nscc.baskets.each do |aBasket|
        xml.instrument("short_name"=>"#{aBasket.tickerSymbol} Basket", "long_name"=>"", "mnemonic"=>"", "precedence"=>"yes", "cfi"=>"ESXXXX", "price_format"=>"decimal 2", "deleted"=>"no") {
          xml.xml("type"=>"fixml")
          xml.groups
          xml.identifiers {
            xml.identifier("venue"=>"c0c78852-efd6-11de-9fb8-dfdb5824b38d", "mic"=>"XXXX") {
              xml.fields {
                xml.field("name"=>"symbol", "value"=>aBasket.tickerSymbol)
              }
            }
          }
        }
      end
    }
  }
  f.close
  
  # build the basket components xml file
  #  
  #<?xml version="1.0" encoding="UTF-8"?>
  #<instruments>
  #  <etf short_name="WREI">
  #    <parameter name="netassetvalue" value="0.10"/>
  #    <basket short_name="WREI Basket">
  #      <legs>
  #        <leg short_name="AMB" mic="BATS" ratio="0.0165"/>
  #        <leg short_name="AKR" mic="BATS" ratio="0.0039"/>
  #        ...
  #        ...
  #      </legs>
  #    </basket>
  #  </etf>
  #</instruments>  
  f = File.new("basket-components.xml", "w")
  xml = Builder::XmlMarkup.new(:target=>f, :indent=>2)
  xml.instruct!
  xml.instruments {
    nscc.baskets.each do |aBasket|
      xml.etf("short_name"=>aBasket.tickerSymbol) {
        # NAV defined by Michael R. Conners...totalCashAmount/creationUnit
        nav = aBasket.totalCashAmount/aBasket.creationUnit
        xml.parameter("name"=>"netassetvalue", "value"=>sprintf("%.4f", nav))
        xml.basket("short_name"=>"#{aBasket.tickerSymbol} Basket") {
          xml.legs {
            aBasket.components.each do |aComponent|
              # Ratio defined by Michael R. Conners...shareQuantity/creationUnit
              ratio = aComponent.shareQuantity/aBasket.creationUnit
              xml.leg("short_name"=>aComponent.tickerSymbol, "mic"=>"BATS", "ratio"=>sprintf("%.4f", ratio))
            end
          }
        }
      } 
    end
  }
  f.close
else
  puts "File not found #{infile}"
end # if File.exist?(infile)

=begin rdoc
 * Name: nscc2tbxml.rb
 * Description: Converts DTCC file into TBricks xml files.
 * Author: Murthy Gudipati
 * Date: 26-Jun-2011
 * License: Saven Technologies Inc.
=end