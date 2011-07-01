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

# Process the xignite master securities files
# Xignite master securities file layout is defined as:
# => " Exchange"," Count"," Records Record Symbol"," Records Record CUSIP"," Records Record CIK"," Records Record ISIN"," Records Record SEDOL"," Records Record Valoren"," Records Record Exchange"," Records Record Name"," Records Record ShortName"," Records Record Issue"," Records Record Sector"," Records Record Industry"," Records Record LastUpdateDate",
# => For e.g. NYSE,3581,A,00846U101,0001090872,US00846U1016,2520153,901692,NYSE,"Agilent Technologies Inc.","Agilent Tech Inc","Common Stock",TECHNOLOGY,"Scientific & Technical Instruments",12/3/2005,
securities = Array.new
infiles.split(',').each do |infile|
  if infile && File.exist?(infile)
  	CSV.foreach(infile, :quote_char => '"', :col_sep =>',', :row_sep => :auto, :headers => true) do |row|
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

        # push it on to the master securities list
        securities.push(security)
      end
  	end # CSV.foreach
  else
    puts "File not found #{infile}"
  end # if File.exist?(infile)
end # for each infile  

# build the tbricks instruments xml file
create_tbricks_instruments_xml(outfile, securities)