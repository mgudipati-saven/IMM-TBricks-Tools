require 'csv'
require 'builder'
require 'getoptlong'
require_relative 'common'
  
# call using "ruby xignite2tbxml.rb -i<file1, file2, ...> [-o<file>]"  
unless ARGV.length >= 1
  puts "Usage: ruby xignite2tbxml.rb -i<file1, file2, ...> [-o<file>]" 
  exit  
end  
  
infiles = ''
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
      infiles = arg
    when '--outfile'  
      outfile = arg  
  end  
end

# Process all the xignite master securities files
securities = Array.new
infiles.split(',').each do |infile|
  infile = infile.strip
  if infile && File.exist?(infile)
    securities += parse_xignite_master_securities_file(infile)
  else
    puts "File not found #{infile}"
  end # if File.exist?(infile)
end # for each infile  

# build the tbricks instruments xml file
create_tbricks_instruments_xml(outfile, securities)