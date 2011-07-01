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

