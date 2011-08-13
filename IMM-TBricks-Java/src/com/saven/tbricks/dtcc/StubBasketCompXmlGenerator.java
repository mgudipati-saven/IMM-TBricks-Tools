package com.saven.tbricks.dtcc;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;

import com.saven.tbricks.beans.BasketCompBean;
import com.saven.tbricks.configuration.ConfigurationConstants;
import com.saven.tbricks.configuration.ConfigurationService;



public class StubBasketCompXmlGenerator {
	private static Logger log = Logger.getLogger(StubBasketCompXmlGenerator.class);
	
	public void stubBasketExporter(Connection con){
		
		PreparedStatement pstmt=null;
		ResultSet rs=null;
		String securitySymbol="";
		
		String query="select security_symbol  from etf_master_daily";
		try{
			
			pstmt=con.prepareStatement(query);
			rs=pstmt.executeQuery();
			
			log.info("Generating StubBaskets.xml....................");
			
			BufferedWriter bw = new BufferedWriter(new FileWriter(ConfigurationService.getValue(ConfigurationConstants.NSCC_FILE_BASKETCOMP_XML)+"stubbaskets.xml"));
			bw.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
			bw.write("<resource name=\"instruments\" type=\"application/x-instrument-reference-data+xml\">");
			bw.write("<instruments>");
			
			while(rs.next()){
				
				securitySymbol=rs.getString("security_symbol");
				
				bw.write("<instrument short_name=\""+securitySymbol.trim()+" Basket\" long_name=\"\" mnemonic=\"\" cfi=\"ESXXXX\" price_format=\"decimal 2\" precedence=\"yes\" deleted=\"no\">");
				bw.write("<xml type=\"fixml\"></xml>");
				bw.write("<groups></groups>");
				bw.write("<identifiers>");
				bw.write("<identifier venue=\"c0c78852-efd6-11de-9fb8-dfdb5824b38d\" mic=\"XXXX\">");
				bw.write("<fields>");
				bw.write("<field name=\"symbol\" value=\""+securitySymbol.trim()+"\"></field>");
				bw.write("</fields>");
				bw.write("</identifier>");
				bw.write("</identifiers>");
				bw.write("</instrument>");
				
			}
			
			bw.write("</instruments>");
			bw.write("</resource>");
			log.info("Completed ............................................. ");

			bw.flush();
			bw.close();
			
		}catch(Exception ex){
			
			ex.printStackTrace();
			log.error("Error Reason: "+ex.getMessage());
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
	
	public void basketComponentsExporter(Connection con){
		
		PreparedStatement pstmt=null;
		PreparedStatement pstmt1=null;
		ResultSet rs=null;
		ResultSet rs1=null;
		
		String securitySymbol="";
		String componentSymb="";
		String header="";
		int componentCount=0;
		
		double unitsperTrade=0;
		double basketshares=0;
		double totCashAmtperUnit=0;
		double netAssetValue=0;
		double ratio=0;
		
		boolean flag=false,flag1=false,flag2=false;
		
		int basketCount=0;
		int count=0;
		
		BasketCompBean compbean=null;
		List<BasketCompBean> list=new ArrayList<BasketCompBean>();
		List<String> list1=new ArrayList<String>();
		
		String query="select h.security_symbol,h.units_per_trade,h.total_cash_per_unit,c.component_symbol,h.component_count,c.basket_shares  from etf_master_daily h left join etf_components_daily c on c.security_symbol=h.security_symbol";
		try{
			
			log.info("Generating BasketComponents.xml....................");
			
			pstmt=con.prepareStatement(query);
			rs=pstmt.executeQuery();
			
			pstmt1=con.prepareStatement("select bats from securities_master group by bats");
			DecimalFormat df=new DecimalFormat("##############0.00000000");
			
			BufferedWriter bw = new BufferedWriter(new FileWriter(ConfigurationService.getValue(ConfigurationConstants.NSCC_FILE_BASKETCOMP_XML)+"basketcomponents.xml"));
			bw.write("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>");
			bw.write("<instruments>");
			
			rs1=pstmt1.executeQuery();
			
			while(rs1.next()){
				
				list1.add(rs1.getString("bats").trim());
			}
			
			while(rs.next()){
				if(!flag){
					securitySymbol=rs.getString("security_symbol");
					componentSymb=rs.getString("component_symbol");
					unitsperTrade=Double.parseDouble(rs.getString("units_per_trade"));
					totCashAmtperUnit=Double.parseDouble(rs.getString("total_cash_per_unit"));
					componentCount=Integer.parseInt(rs.getString("component_count"));
					netAssetValue=(totCashAmtperUnit/unitsperTrade);
					
					count++;
					System.out.println("RecordType...................."+count+"   securitySymbol:  "+securitySymbol);
					//ts2010??----TSTRACKER password---tstech---username
					//66.17.138.30
					//bw.write("<etf short_name=\""+securitySymbol+"\" long_name=\"\" mic=\"BATS\" cusip=\"\" currency=\"USD\">");
					
					header="<etf short_name=\""+securitySymbol+" Basket\">"+
						"<parameter name=\"netassetvalue\" value=\""+df.format(netAssetValue)+"\"/>";
					
					flag1=true;
					flag2=false;
					//basketCount=0;
					list.clear();
					if(componentSymb!=null){	
						basketshares=Double.parseDouble(rs.getString("basket_shares"));
						ratio=(basketshares/unitsperTrade);
						compbean=new BasketCompBean();
						if(componentSymb.equalsIgnoreCase(""))
							flag2=true;
						compbean.setCompSymbol(componentSymb);
						compbean.setRatio(df.format(ratio));
						
						list.add(compbean);
					
					}
					
					flag=true;
				}else{
					
					if(securitySymbol.trim().equalsIgnoreCase(rs.getString("security_symbol").trim())){
						componentSymb=rs.getString("component_symbol");
						if(componentSymb!=null){	
							basketshares=Double.parseDouble(rs.getString("basket_shares"));
							ratio=(basketshares/unitsperTrade);
							compbean=new BasketCompBean();
							if(componentSymb.equalsIgnoreCase(""))
								flag2=true;
							compbean.setCompSymbol(componentSymb);
							compbean.setRatio(df.format(ratio));
							
							list.add(compbean);
						}
					
					}else{
						if(flag1){
							if(!flag2){
								if(list.size()==componentCount){
									basketCount=basketCount+1;
									bw.write(header);
									bw.write("<basket short_name=\""+securitySymbol+" Basket\">");
									bw.write("<legs>");
									for(int i=0;i<list.size();i++){
										compbean=list.get(i);
										if(list1.contains(compbean.getCompSymbol().trim())){
											bw.write("<leg short_name=\""+compbean.getCompSymbol()+"\" mic=\"BATS\" ratio=\""+compbean.getRatio()+"\"/>");
										}
									}
									bw.write("</legs>");
									bw.write("</basket>");
									bw.write("</etf>\n");
								
									System.out.println("basketCount.............................."+basketCount+"  list.size():   "+list.size()+"  componentCount:  "+componentCount);
								}
							
							}
						}
						
						
						list.clear();
						
						securitySymbol=rs.getString("security_symbol");
						componentSymb=rs.getString("component_symbol");
						unitsperTrade=Double.parseDouble(rs.getString("units_per_trade"));
						totCashAmtperUnit=Double.parseDouble(rs.getString("total_cash_per_unit"));
						componentCount=Integer.parseInt(rs.getString("component_count"));
						netAssetValue=(totCashAmtperUnit/unitsperTrade);
						
						header="<etf short_name=\""+securitySymbol+" Basket\">"+
						"<parameter name=\"netassetvalue\" value=\""+df.format(netAssetValue)+"\"/>";
					
						if(componentSymb!=null){	
							
							basketshares=Double.parseDouble(rs.getString("basket_shares"));
							ratio=(basketshares/unitsperTrade);
							compbean=new BasketCompBean();
							
							if(componentSymb.equalsIgnoreCase(""))
								flag2=true;
							compbean.setCompSymbol(componentSymb);
							compbean.setRatio(df.format(ratio));
							
							list.add(compbean);
							
							
						}
					flag1=true;
					flag2=false;
					//basketCount=0;
						
					}
					
					
				}
				
			}
			
			if(flag1){
				
				if(!flag2){
				
					if(list.size()==componentCount){
						basketCount=basketCount+1;
						bw.write(header);
						bw.write("<basket short_name=\""+securitySymbol+" Basket\">");
						bw.write("<legs>");
						for(int i=0;i<list.size();i++){
							compbean=list.get(i);
							if(list1.contains(compbean.getCompSymbol().trim())){
								bw.write("<leg short_name=\""+compbean.getCompSymbol()+"\" mic=\"BATS\" ratio=\""+compbean.getRatio()+"\"/>");
							}
						}
						bw.write("</legs>");
						bw.write("</basket>");
						bw.write("</etf>\n");
					
						System.out.println("basketCount.............................."+basketCount+"  list.size():   "+list.size()+"  componentCount:  "+componentCount);
					}
				
				}
			}

			list.clear();
			
			bw.write("</instruments>");
			log.info("Completed ............................................. ");

			bw.flush();
			bw.close();
			
		}catch(Exception ex){
			
			ex.printStackTrace();
			log.error("Error Reason:  "+ex.getMessage());
		}
		
		finally{
			
			if(pstmt1!=null){
				try{
					pstmt1.close();
				}catch(Exception ex){
					log.error("While pstmt1 closing the error is: "+ ex.getMessage());
				}
			}
			if(pstmt!=null){
				try{
					pstmt.close();
				}catch(Exception ex){
					log.error("While pstmt closing the error is: "+ ex.getMessage());
				}
			}
			if(rs!=null){
				try{
					rs.close();
				}catch(Exception ex){
					log.error("While rs closing the error is: "+ ex.getMessage());
				}
			}
			if(rs1!=null){
				try{
					rs1.close();
				}catch(Exception ex){
					log.error("While rs1 closing the error is: "+ ex.getMessage());
				}
			}
		}
		
	}
}
