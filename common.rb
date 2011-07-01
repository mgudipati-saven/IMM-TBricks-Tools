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