package com.saven.tbricks;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;

import com.saven.tbricks.beans.ExchangesSymbolBean;
import com.saven.tbricks.configuration.ConfigurationConstants;
import com.saven.tbricks.configuration.ConfigurationService;
import com.saven.tbricks.util.CsvReader;



public class ExdivdendFileParser {
	private static Logger log = Logger.getLogger(ExdivdendFileParser.class);		
	public void intialize(Connection conn){
		
		PreparedStatement pstmt=null;
		ResultSet rs=null;
		
		String query1="select cusip,arcx,xase,xnys,bats,xnas,cbsx,xcis,xotc,otcq,edga,listed_exchanges from securities_master where listed_exchanges <> ? and listed_exchanges <> ?";
		String query2="insert into securities_fundamentals(cusip,symbol,market)values(?,?,?)";
		String query3="delete from securities_fundamentals";
		
		String cusip="";
		String symbol="";
		
		try{
			log.info("Intializing Securities Fundamentals Table......................");
			List<ExchangesSymbolBean> list=new ArrayList<ExchangesSymbolBean>();
			
			pstmt=conn.prepareStatement(query3);
			pstmt.executeUpdate();
			
			pstmt=conn.prepareStatement(query1);
			pstmt.setString(1,"");
			pstmt.setString(2,"null");
			rs=pstmt.executeQuery();
			
			ExchangesSymbolBean esb=null;
			while(rs.next()){
				System.out.println("Cusip:  "+rs.getString(1));
				
				esb=new ExchangesSymbolBean();
				esb.setCusip(rs.getString("cusip").trim());
				esb.setAmex(rs.getString("xase").trim());
				esb.setArca(rs.getString("arcx").trim());
				esb.setNyse(rs.getString("xnys").trim());
				esb.setBats(rs.getString("bats").trim());
				esb.setCbsx(rs.getString("cbsx").trim());
				esb.setNasdaq(rs.getString("xnas").trim());
				esb.setOtcbb(rs.getString("xotc").trim());
				esb.setNsx(rs.getString("xcis").trim());
				esb.setOtcqx(rs.getString("otcq").trim());
				esb.setEdge(rs.getString("edga").trim());
				esb.setListedExchCode(rs.getString("listed_exchanges").trim());
				
				list.add(esb);
			}
			
			pstmt=conn.prepareStatement(query2);
			
			for(int i=0;i<list.size();i++){
				
				esb=list.get(i);
				
				if(esb.getListedExchCode().equalsIgnoreCase("ARCX"))
					symbol=esb.getArca();
				if(esb.getListedExchCode().equalsIgnoreCase("XASE"))
					symbol=esb.getAmex();
				if(esb.getListedExchCode().equalsIgnoreCase("XNYS"))
					symbol=esb.getNyse();
				if(esb.getListedExchCode().equalsIgnoreCase("XNAS"))
					symbol=esb.getNasdaq();
				else if(esb.getListedExchCode().equalsIgnoreCase("BATS"))
					symbol=esb.getBats();
				else if(esb.getListedExchCode().equalsIgnoreCase("CBSX"))
					symbol=esb.getCbsx();
				else if(esb.getListedExchCode().equalsIgnoreCase("EDGA"))
					symbol=esb.getEdge();
				else if(esb.getListedExchCode().equalsIgnoreCase("XCIS"))
					symbol=esb.getNsx();
				else if(esb.getListedExchCode().equalsIgnoreCase("XOTC"))
					symbol=esb.getOtcbb();
				else if(esb.getListedExchCode().equalsIgnoreCase("OTCQ"))
					symbol=esb.getOtcqx();
				
				cusip=esb.getCusip();
				
				pstmt.setString(1,cusip);
				pstmt.setString(2,symbol);
				pstmt.setString(3,esb.getListedExchCode());
				
				pstmt.executeUpdate();
			}
			
			log.info("End........................");
			
		}catch(Exception ex){
			
			ex.printStackTrace();
			log.error("Error reason: "+ex.getMessage());
		}
		finally{
			if(pstmt!=null){
				try{
					pstmt.close();
				}catch(Exception ex){
					log.error("Error Reason: "+ex.getMessage());
				}
			}
			if(rs!=null){
				try{
					rs.close();
				}catch(Exception ex){
					log.error("Error Reason: "+ex.getMessage());
				}
			}
			
		}
		
	}
	
	
	public void updateExdivdentFileToDB(Connection conn){
		
		CsvReader products = null;
		PreparedStatement pstmt=null;
		PreparedStatement pstmt1=null;
		ResultSet rs=null;
		try{
			
			log.info("Parsing ExDivdend File........................");	
			Map<String,String> exchMappings=new HashMap<String,String>();
			exchMappings.put("NASDAQ","XNAS");
			exchMappings.put("AMEX","XASE");
			exchMappings.put("NYSE","XNYS");
			
			products = new CsvReader(ConfigurationService.getValue(ConfigurationConstants.TBRICKS_EXDIV_DAILY_FILE_LOCATION)+"exdfor 8.10.2011.txt",',');
			products.readHeaders();
			
			int count=0,count1=0;
			String symbol="";
			String notes="";
			String companyName="";
			String market="";
			String amount="";
			String frequency="";
			String exDate="";
			String recordDate="";
			String paymentdate="";
			String substring="";
			
			pstmt=conn.prepareStatement("select cusip from securities_fundamentals where symbol=? and market=?");
			pstmt1=conn.prepareStatement("update securities_fundamentals set company_name=?,amount=?,freq=?,x_date=?,record_date=?,pay_date=?,notes=? where cusip=? and symbol=? and market=?");
			while (products.readRecord())
			{
				companyName=products.get("COMPANY").trim();
				symbol=products.get("SYMBOL").trim();
				market=products.get("MARKET").trim();
				amount=products.get("AMOUNT").trim();
				frequency=products.get("FREQUENCY").trim();
				exDate=products.get("EX-DATE").trim();
				recordDate=products.get("RECORD DATE").trim();
				paymentdate=products.get("PAYMENT DATE").trim();
				notes=products.get("NOTES").trim();

				substring=companyName.substring(0,7);
				if(substring.equalsIgnoreCase("&#65279")){
					
				System.exit(0);
				}else{
					pstmt.setString(1,symbol);
					pstmt.setString(2,exchMappings.get(market));
					rs=pstmt.executeQuery();
					
					if(rs.next()){
						//System.out.println("symbol:   "+products.get("COMPANY").trim()+"  Cusip: "+rs.getString(1));
						pstmt1.setString(1,companyName);
						pstmt1.setString(2,amount);
						pstmt1.setString(3,frequency);
						pstmt1.setString(4,exDate);
						pstmt1.setString(5,recordDate);
						pstmt1.setString(6,paymentdate);
						pstmt1.setString(7,notes);
						pstmt1.setString(8,rs.getString(1));
						pstmt1.setString(9,symbol);
						pstmt1.setString(10,exchMappings.get(market));
						
						pstmt1.executeUpdate();
						
					}else{
						System.out.println(symbol+","+market+","+products.get("COMPANY").trim());
					}
					
					//System.out.println(symbol+","+market+","+products.get("COMPANY").trim());
				}
				
			}
			
			
		}catch(Exception ex){
			ex.printStackTrace();
			log.error("Error Reason: "+ex.getMessage());
		}
		finally{
			if(pstmt!=null){
				try{
					pstmt.close();
				}catch(Exception ex){
					log.error("Error Reason:  "+ex.getMessage());
				}
			}
			if(rs!=null){
				try{
					rs.close();
				}catch(Exception ex){
					log.error("Error Reason:  "+ex.getMessage());
				}
			}
			
		}
		log.info("Done................................");
	}
	
}
