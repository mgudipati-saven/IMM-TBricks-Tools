#!/usr/bin/env ruby

# Security
class Security
  attr_accessor( :tickerSymbol )
  attr_accessor( :cusip )
  attr_accessor( :cik )
  attr_accessor( :isin )
  attr_accessor( :sedol )
  attr_accessor( :valoren )
  attr_accessor( :exchange )
  attr_accessor( :name )
  attr_accessor( :shortName )
  attr_accessor( :issue )
  attr_accessor( :sector )
  attr_accessor( :industry )
  attr_accessor( :companyName )

  def initialize( aSymbol )
    @tickerSymbol = aSymbol
  end  
end

# Basket
class Basket < Security
  #Create/Redeem Units per Trade
  attr_accessor( :creationUnit )

  #Total Cash Amount Per Creation Unit...99,999,999,999.99-
  attr_accessor( :totalCashAmount )

  #Net Asset Value Per Creation Unit...99,999,999,999.99
  attr_accessor( :nav )

  #Components...
  attr_accessor( :components )

  def initialize( aSymbol )
    @tickerSymbol = aSymbol
    @components = Array.new
  end  
end

# Basket Component
class BasketComponent < Security
  #Component Share Qty...99,999,999
  attr_accessor( :shareQuantity )
end

# Process the symbol list file
# Symbol list file layout is defined as follows:
# Header record:
# => CUSIP,Symbol,Ext,Company Name,Primary Market,Round Lot Size,Min Order Qty
#
# Data record:
# => 00846U101,A,,AGILENT TECHNOLOGIES INC,NYSE,100,0
# 
def parse_symbol_list_file( aFile )
  securities = Array.new
  
  CSV.foreach(aFile, :quote_char => '"', :col_sep =>',', :row_sep => :auto, :headers => true) do |row|
    symbol = row.field('Symbol')
    ext = row.field('Ext')
    if ext != '' then symbol += ".#{ext}" end
  
    if symbol != '' then
      # create a new security by passing the ticker symbol as argument
      security = Security.new(symbol)

      # populate the attributes
      security.cusip = row.field('CUSIP')
      security.exchange = row.field('Primary Market')
      security.name = row.field('Company Name')

      # push it to the securities list
      securities.push(security)
    end
  end # CSV.foreach
  
  return securities
end

# Process the NSCC basket composition file
# NSCC file layout is defined as follows:
# Header record describing the basket information
# => 01WREI           18383M47200220110624000000950005000000000000000291+0000000000000+0000162471058+0000000003249+0000000004503+0000005000000000000000000+
# Basket component records
# => 02AKR            0042391090002011062400000193WREI           18383M472002
# => 02ALX            0147521090002011062400000013WREI           18383M472002
# => ...
def parse_nscc_basket_composition_file( aFile )
  baskets = Array.new
  aBasket = nil
  dirty = false
  
  IO.foreach(aFile) do |line| 
    case line[0..1]
      when '01' # basket header type record
        # new basket...save the old basket if it is not dirty
        if aBasket != nil && !dirty
          baskets.push(aBasket)
        end

        #Index Receipt Symbol...Trading Symbol
        aBasket = Basket.new(line[2..16].strip)
        dirty = false
        
        #Create/Redeem Units per Trade
        aBasket.creationUnit = line[45..52].to_i

        #Total Cash Amount Per Creation Unit...99,999,999,999.99-
        aBasket.totalCashAmount = "#{line[110..120]}.#{line[121..122]}".to_f
        sign = line[123]
        if sign == '-' then aBasket.totalCashAmount *= -1 end

        #Net Asset Value Per Creation Unit...99,999,999,999.99
        aBasket.nav = "#{line[82..92]}.#{line[93..94]}".to_f
        sign = line[95]
        if sign == '-' then aBasket.nav *= -1 end
      when '02'
        # basket component symbol...Trading Symbol
        sym = line[2..16].strip
        if sym == ''
          # mark components with blank symbol as dirty baskets
          dirty = true
        end

        aComponent = BasketComponent.new(sym)

        #Component Share Qty...99,999,999
        aComponent.shareQuantity = line[37..44].to_f

        aBasket.components.push(aComponent)
    end
  end
  
  return baskets
end

# build the tbricks instruments xml file
#<?xml version="1.0" encoding="UTF-8"?>
#<resource name="instruments" type="application/x-instrument-reference-data+xml">
#  <instruments>
#    <instrument short_name="AADR" mnemonic="AADR" precedence="no" cfi="ESNTFR" price_format="decimal 2" deleted="no">
#      <xml type="fixml"/>
#      <groups/>
#      <identifiers>
#        <identifier venue="7c15c3c2-4a25-11e0-b2a1-2a7689193271" mic="BATS">
#          <fields>
#            <field name="exdestination" value="BATS"/>
#            <field name="symbol" value="AADR"/>
#          </fields>
#        </identifier>
#        <identifier venue="7c15c3c2-4a25-11e0-b2a1-2a7689193271" mic="EDGA">
#          <fields>
#            <field name="exdestination" value="EDGA"/>
#            <field name="symbol" value="AADR"/>
#          </fields>
#        </identifier>
#        <identifier venue="7c15c3c2-4a25-11e0-b2a1-2a7689193271" mic="EDGX">
#          <fields>
#            <field name="exdestination" value="EDGX"/>
#            <field name="symbol" value="AADR"/>
#          </fields>
#        </identifier>
#      </identifiers>
#    </instrument>
#    ...
#    ...
#  </instruments>
#</resource>
def create_tbricks_instruments_xml(outfile, securities)
  f = File.new(outfile, "w")
  xml = Builder::XmlMarkup.new(:target=>f, :indent=>2)
  xml.instruct!
  xml.resource( "name"=>"instruments", 
                "type"=>"application/x-instrument-reference-data+xml") {
    xml.instruments {
      # create an instrument node for each security
      securities.each do |aSecurity|
        # short_name should not be null
        short_name = aSecurity.shortName
        if short_name == nil then short_name = aSecurity.name end
        if short_name == nil then short_name = aSecurity.tickerSymbol end
        
        # to be consistent with baskets xml definition, ticker symbol is used for short_name
        xml.instrument( "short_name"=>aSecurity.tickerSymbol, 
                        "long_name"=>aSecurity.name,
                        "mnemonic"=>aSecurity.tickerSymbol, 
                        "precedence"=>"no", 
                        "cfi"=>"ESNTFR", 
                        "price_format"=>"decimal 2", 
                        "deleted"=>"no") {
          xml.xml("type"=>"fixml")
          xml.groups
          xml.identifiers {
            xml.identifier("venue"=>"7c15c3c2-4a25-11e0-b2a1-2a7689193271", "mic"=>"BATS") {
              xml.fields {
                xml.field("name"=>"exdestination", "value"=>"BATS")
                xml.field("name"=>"symbol", "value"=>aSecurity.tickerSymbol)
              }
            }
            xml.identifier("venue"=>"7c15c3c2-4a25-11e0-b2a1-2a7689193271", "mic"=>"EDGA") {
              xml.fields {
                xml.field("name"=>"exdestination", "value"=>"EDGA")
                xml.field("name"=>"symbol", "value"=>aSecurity.tickerSymbol)
              }
            }
            xml.identifier("venue"=>"7c15c3c2-4a25-11e0-b2a1-2a7689193271", "mic"=>"EDGX") {
              xml.fields {
                xml.field("name"=>"exdestination", "value"=>"EDGX")
                xml.field("name"=>"symbol", "value"=>aSecurity.tickerSymbol)
              }
            }
          }
        }
      end
    }
  }
  f.close
end

# build the tbricks stub basket instruments xml file
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
def create_stub_basket_instruments_xml(outfile, baskets)
  f = File.new(outfile, "w")
  xml = Builder::XmlMarkup.new(:target=>f, :indent=>2)
  xml.instruct!
  xml.resource("name"=>"instruments", "type"=>"application/x-instrument-reference-data+xml") {
    xml.instruments {
      baskets.each do |aBasket|
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
end

# build the tbricks basket components xml file
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
def create_basket_components_xml(outfile, baskets)  
  f = File.new(outfile, "w")
  xml = Builder::XmlMarkup.new(:target=>f, :indent=>2)
  xml.instruct!
  xml.instruments {
    baskets.each do |aBasket|
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
end

# Process the xignite master securities file
# Xignite master securities file layout is defined as follows:
# => " Exchange"," Count"," Records Record Symbol"," Records Record CUSIP"," Records Record CIK"," Records Record ISIN"," Records Record SEDOL"," Records Record Valoren"," Records Record Exchange"," Records Record Name"," Records Record ShortName"," Records Record Issue"," Records Record Sector"," Records Record Industry"," Records Record LastUpdateDate",
# => For e.g. NYSE,3581,A,00846U101,0001090872,US00846U1016,2520153,901692,NYSE,"Agilent Technologies Inc.","Agilent Tech Inc","Common Stock",TECHNOLOGY,"Scientific & Technical Instruments",12/3/2005,
def parse_xignite_master_securities_file( aFile )
  securities = Array.new
  
  CSV.foreach(aFile, :quote_char => '"', :col_sep =>',', :row_sep => :auto, :headers => true) do |row|
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

      # push it to the securities list
      securities.push(security)
    end
  end # CSV.foreach
  
  return securities
end