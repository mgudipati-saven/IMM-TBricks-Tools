require 'csv'
require 'builder'
require 'getoptlong'  

  # Security
  class Security
  
    attr_accessor( :tickerSymbol )
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
  
# global symbol list
symlist = Hash.new

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
  #etfs = Hash.new
  baskets = Array.new
  aBasket = ''
  #components = Array.new
  IO.foreach(infile) do |line| 
    case line[0..1]
      when '01' # basket header type record
        # new basket
        #etfs[line] = components = Array.new
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

  # build the stub basket instrument xml file
  f = File.new("stub-basket-instruments.xml", "w")
  xml = Builder::XmlMarkup.new(:target=>f, :indent=>2)
  xml.instruct!
  xml.resource("name"=>"instruments", "type"=>"application/x-instrument-reference-data+xml") {
    xml.instruments {
      etfs.each_key do |key|
        xml.instrument("short_name"=>"#{key[2..16].strip} Basket", "long_name"=>"", "mnemonic"=>"", "precedence"=>"yes", "cfi"=>"ESXXXX", "price_format"=>"decimal 2", "deleted"=>"no") {
          xml.xml("type"=>"fixml")
          xml.groups
          xml.identifiers {
            xml.identifier("venue"=>"c0c78852-efd6-11de-9fb8-dfdb5824b38d", "mic"=>"XXXX") {
              xml.fields {
                #Component Symbol...Trading Symbol
                sym = key[2..16].strip
                symlist[sym] = sym
                xml.field("name"=>"symbol", "value"=>sym)
              }
            }
          }
        }
      end
    }
  }
  f.close
  
  # build the etf components xml file
  f = File.new("basket-components.xml", "w")
  xml = Builder::XmlMarkup.new(:target=>f, :indent=>2)
  xml.instruct!
  xml.instruments {
    etfs.each do |key, value|
      #Create/Redeem Units per Trade
      cunit = key[45..52].to_i
      xml.etf("short_name"=>key[2..16].strip) {
        #Total Cash Amount Per Creation Unit...99,999,999,999.99-
        cashamt = "#{key[110..120]}.#{key[121..122]}".to_f
        sign = key[123]
        if sign == '-' then cashamt *= -1 end
      
        #Net Asset Value Per Creation Unit...99,999,999,999.99
        nav = "#{key[82..92]}.#{key[93..94]}".to_f
        sign = key[95]
        if sign == '-' then nav *= -1 end

        nav = cashamt/cunit
        xml.parameter("name"=>"netassetvalue", "value"=>sprintf("%.2f", nav))
        xml.basket("short_name"=>"#{key[2..16].strip} Basket") {
          xml.legs {
            value.each do |comp|
              #Component Share Qty
              qty = comp[37..44].to_f
              ratio = qty/cunit
              xml.leg("short_name"=>comp[2..16].strip, "mic"=>"BATS", "ratio"=>sprintf("%.4f", ratio))
            end
          }
        }
      } 
    end
  }
  f.close

  # build the instrument reference data xml
  f = File.new('instruments.xml', "w")
  xml = Builder::XmlMarkup.new(:target=>f, :indent=>2)
  xml.instruct!
  xml.resource("name"=>"instruments", "type"=>"application/x-instrument-reference-data+xml") {
    xml.instruments {
      symlist.sort.each do |key, value|
        xml.instrument("short_name"=>key, "mnemonic"=>key, "precedence"=>"no", "cfi"=>"ESNTFR", "price_format"=>"decimal 2", "deleted"=>"no") {
          xml.xml("type"=>"fixml")
          xml.groups
          xml.identifiers {
            xml.identifier("venue"=>"7c15c3c2-4a25-11e0-b2a1-2a7689193271", "mic"=>"BATS") {
              xml.fields {
                xml.field("name"=>"exdestination", "value"=>"BATS")
                xml.field("name"=>"symbol", "value"=>key)
              }
            }
            xml.identifier("venue"=>"7c15c3c2-4a25-11e0-b2a1-2a7689193271", "mic"=>"EDGA") {
              xml.fields {
                xml.field("name"=>"exdestination", "value"=>"EDGA")
                xml.field("name"=>"symbol", "value"=>key)
              }
            }
            xml.identifier("venue"=>"7c15c3c2-4a25-11e0-b2a1-2a7689193271", "mic"=>"EDGX") {
              xml.fields {
                xml.field("name"=>"exdestination", "value"=>"EDGX")
                xml.field("name"=>"symbol", "value"=>key)
              }
            }
          }
        }
    	end
    }
  }
  f.close
else
  puts "File not found #{infile}"
end # if File.exist?(infile)