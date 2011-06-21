require 'csv'
require 'builder'
require 'getoptlong'  
  
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
  etfs = Hash.new
  components = Array.new
  IO.foreach(infile) do |line| 
    case line[0..1]
      when '01'
        # new etf
        etfs[line] = components = Array.new
      when '02'
        # constituent
        components.push(line)
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
                xml.field("name"=>"symbol", "value"=>key[2..16].strip)
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
      xml.parameter("name"=>"netassetvalue", "vlaue"=>sprintf("%.2f", nav))
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
  f.close
else
  puts "File not found #{infile}"
end # if File.exist?(infile)