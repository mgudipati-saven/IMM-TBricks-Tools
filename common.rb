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
class Basket
  #Index Receipt Symbol...Trading Symbol
  attr_accessor( :tickerSymbol )

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
class BasketComponent
  #Component Symbol...Trading Symbol
  attr_accessor( :tickerSymbol )
  
  #Component Share Qty...99,999,999
  attr_accessor( :shareQuantity )
  
  def initialize( aSymbol )
    @tickerSymbol = aSymbol
  end  
end

# NSCC 
class NSCC
  attr_accessor( :baskets )

  def initialize( file )
    @baskets = Array.new
    aBasket = ''
    IO.foreach(file) do |line| 
      case line[0..1]
        when '01' # basket header type record
          # new basket
          #Index Receipt Symbol...Trading Symbol
          aBasket = Basket.new(line[2..16].strip)

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

          baskets.push(aBasket)        
        when '02'
          # basket component
          aComponent = BasketComponent.new(line[2..16].strip)

          #Component Share Qty...99,999,999
          aComponent.shareQuantity = line[37..44].to_f

          aBasket.components.push(aComponent)
      end
    end
  end 
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
        
        xml.instrument( "short_name"=>short_name, 
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