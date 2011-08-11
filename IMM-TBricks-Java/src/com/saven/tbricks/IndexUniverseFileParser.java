package com.saven.tbricks;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.saven.tbricks.configuration.ConfigurationConstants;
import com.saven.tbricks.configuration.ConfigurationService;
import com.saven.tbricks.util.CsvReader;

public class IndexUniverseFileParser {

	public void updateETFMasterTable(Connection conn){
		
		PreparedStatement pstmt=null;
		PreparedStatement pstmt1=null;
		ResultSet rs=null;
		CsvReader products = null;
		
		String query1="insert into etf_master(security_symbol,cusip,product_name,issuer,asset_class,region,geography,leverage_factor)values(?,?,?,?,?,?,?,?) ";
		String query2="select cusip from etf_master_daily where security_symbol=?";
		try{
			System.out.println("Start..........................");
			products = new CsvReader("C:\\Documents and Settings\\SRGillela.SAVEN.000\\Desktop\\xyz\\ECS.7.26.2011.csv",',');
			products.readHeaders();
			
			String symbol="";
			String cusip="";
			String productName="";
			String issuer="";
			String assetClass="";
			String region="";
			String geography="";
			String leverageFactor="";
			
			pstmt=conn.prepareStatement(query1);
			pstmt1=conn.prepareStatement(query2);
			
			while(products.readRecord()){
				
				symbol=products.get("Ticker Symbol").trim();
				productName=products.get("Product Name").trim();
				issuer=products.get("Issuer").trim();
				assetClass=products.get("Asset Class").trim();
				region=products.get("Region").trim();
				geography=products.get("Geography").trim();
				leverageFactor=products.get("Leverage Factor").trim();
				
				pstmt1.setString(1,symbol);
				rs=pstmt1.executeQuery();
				if(rs.next()){
					
					pstmt.setString(1,symbol);
					pstmt.setString(2,rs.getString(1));
					pstmt.setString(3,productName);
					pstmt.setString(4,issuer);
					pstmt.setString(5,assetClass);
					pstmt.setString(6,region);
					pstmt.setString(7,geography);
					pstmt.setString(8,leverageFactor);
					
					pstmt.executeUpdate();
					
				}else{
					
					System.out.println(symbol+","+productName);
				}
				
			}
			System.out.println("End.................................");
		}catch(Exception ex){
			ex.printStackTrace();
		}
		
	}
	
}
