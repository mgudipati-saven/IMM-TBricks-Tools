require 'csv'
require 'builder'
require 'getoptlong'  
  
# call using "ruby arca2tbxml.rb -i<input file> [-o<output file>]"  
unless ARGV.length >= 1
  puts "Usage: ruby arca2tbxml.rb -i<input file> [-o<output file>]" 
  exit  
end  
  
infile = ''
outfile = "arca-instruments.xml"  
# specify the options we accept and initialize the option parser  
opts = GetoptLong.new(  
  [ "--infile", "-i", GetoptLong::REQUIRED_ARGUMENT ],  
  [ "--outfile", "-o", GetoptLong::REQUIRED_ARGUMENT ]
)  

# process the parsed options  
opts.each do |opt, arg|  
  case opt  
    when '--infile'  
      infile = arg  
    when '--outfile'  
      outfile = arg  
  end  
end

if infile && File.exist?(infile)
  f = File.new(outfile, "w")
  xml = Builder::XmlMarkup.new(:target=>f, :indent=>2)
  xml.instruct!
  xml.resource("name"=>"instruments", "type"=>"application/x-instrument-reference-data+xml") {
    xml.instruments {
    	CSV.foreach(infile, :quote_char => '"', :col_sep =>',', :row_sep =>:auto) do |row|
        xml.instrument("short_name"=>row[1], "long_name"=>row[0], "mnemonic"=>row[1], "precedence"=>"no", "cfi"=>"ESNTFR", "price_format"=>"decimal 2", "deleted"=>"no") {
          xml.xml("type"=>"fixml")
          xml.groups
          xml.identifiers {
            xml.identifier("venue"=>"7c15c3c2-4a25-11e0-b2a1-2a7689193271", "mic"=>"BATS") {
              xml.fields {
                xml.field("name"=>"exdestination", "value"=>"BATS")
                xml.field("name"=>"symbol", "value"=>row[1])
              }
            }
            xml.identifier("venue"=>"7c15c3c2-4a25-11e0-b2a1-2a7689193271", "mic"=>"EDGA") {
              xml.fields {
                xml.field("name"=>"exdestination", "value"=>"EDGA")
                xml.field("name"=>"symbol", "value"=>row[1])
              }
            }
            xml.identifier("venue"=>"7c15c3c2-4a25-11e0-b2a1-2a7689193271", "mic"=>"EDGX") {
              xml.fields {
                xml.field("name"=>"exdestination", "value"=>"EDGX")
                xml.field("name"=>"symbol", "value"=>row[1])
              }
            }
          }
        }
    	end # CSV.foreach
    }
  }
  f.close
else
  puts "File not found #{infile}"
end # if File.exist?(infile)