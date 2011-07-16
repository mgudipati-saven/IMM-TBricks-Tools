require 'csv'
require 'builder'
require 'getoptlong'  
require_relative 'common'

# call using "ruby bats2tbxml.rb -i<input file> [-o<output file>]"  
unless ARGV.length >= 1
  puts "Usage: ruby bats2tbxml.rb -i<input file> [-o<output file>]" 
  exit  
end  
  
infile = ''
outfile = "instruments.xml"  
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

# Process the bats master securities files
# BATS master securities file layout is defined as:
# => "symbol",
# => For e.g. A
securities = Array.new
if infile && File.exist?(infile)
	CSV.foreach(infile, :quote_char => '"', :col_sep =>',', :row_sep => :auto, :headers => true) do |row|
    sym = row.field('symbol')
    if sym
      # create a new security by passing the ticker symbol as argument
      security = Security.new(sym)

      # push it on to the master securities list
      securities.push(security)
    end
	end # CSV.foreach
else
  puts "File not found #{infile}"
end # if File.exist?(infile)

# build the tbricks instruments xml file
create_tbricks_instruments_xml(outfile, securities)