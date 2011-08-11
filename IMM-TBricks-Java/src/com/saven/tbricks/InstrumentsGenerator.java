package com.saven.tbricks;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import org.apache.log4j.Logger;

import com.opensymphony.xwork2.util.TextUtils;
import com.saven.tbricks.configuration.ConfigurationConstants;
import com.saven.tbricks.configuration.ConfigurationService;
import com.saven.tbricks.dtcc.NSCCImportingParser;
import com.sun.org.apache.xerces.internal.impl.xpath.regex.RegularExpression;

public class InstrumentsGenerator {

	private static Logger log = Logger.getLogger(InstrumentsGenerator.class);	
	
	public void generateInstrumentXML(Connection conn){

		PreparedStatement pstmt=null;
		ResultSet rs=null;
		String compName="",symbol="",replaceSymb="";
		try{
			log.info("Generating Instruments.xml file........... ");
			pstmt=conn.prepareStatement("select cusip,arcx,xase,xnys,bats,cbsx,xnas,xcis,edga,xotc,otcq,company_name from securities_master");
			rs=pstmt.executeQuery();
			
			BufferedWriter bw = new BufferedWriter(new FileWriter(ConfigurationService.getValue(ConfigurationConstants.NSCC_FILE_BASKETCOMP_XML)+"instruments.xml"));
			bw.write("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n");
			bw.write("<resource name=\"instruments\" type=\"application/x-instrument-reference-data+xml\">\n");
			bw.write("<instruments>\n");
			
			/* RegularExpression r1=new RegularExpression("[.~^+&@#=$*-]");
			 RegularExpression r2=new RegularExpression("Basket");*/
			
			 int count1=0,count2=0;
			 
			 String nyseArca="";
			 String nyseAmex="";
			 String nyse="";
			 String bats="";
			 String nasdaq="";
			 String cbsx="";
			 String edge="";
			 String nsx="";
			 String otcbb="";
			 String otcqx="";
			 String cusip="";
			 
			while(rs.next()){
				//symbol=rs.getString("symbol").trim();
				compName=rs.getString("company_name").trim();
				cusip=rs.getString("cusip").trim();
				compName=TextUtils.htmlEncode(compName);
				nyseArca=rs.getString("arcx").trim();
				nyseAmex=rs.getString("xase").trim();
				nyse=rs.getString("xnys").trim();
				bats=rs.getString("bats").trim();
				nasdaq=rs.getString("xnas").trim();
				cbsx=rs.getString("cbsx").trim();
				edge=rs.getString("edga").trim();
				nsx=rs.getString("xcis").trim();
				otcbb=rs.getString("xotc").trim();
				otcqx=rs.getString("otcq").trim();
				
				if(!nyseArca.equalsIgnoreCase(""))
					symbol=nyseArca;
				else if(!nyseAmex.equalsIgnoreCase(""))
					symbol=nyseAmex;
				else if(!nyse.equalsIgnoreCase(""))
					symbol=nyse;
				else if(!bats.equalsIgnoreCase(""))
					symbol=bats;
				else if(!nasdaq.equalsIgnoreCase(""))
					symbol=nasdaq;
				else if(!cbsx.equalsIgnoreCase(""))
					symbol=cbsx;
				else if(!edge.equalsIgnoreCase(""))
					symbol=edge;
				else if(!nsx.equalsIgnoreCase(""))
					symbol=nsx;
				else if(!otcbb.equalsIgnoreCase(""))
					symbol=otcbb;
				else if(!otcqx.equalsIgnoreCase(""))
					symbol=otcqx;
				
				if(!symbol.equalsIgnoreCase("")){
				
					bw.write("<instrument short_name=\""+symbol+"\" long_name=\""+compName+"\" mnemonic=\"\" cfi=\"ES\" price_format=\"decimal 2\" precedence=\"yes\" deleted=\"no\">\n");
					bw.write("<xml type=\"fixml\" />\n");
					bw.write("<groups />\n");
					bw.write("<identifiers>\n");
					if(nyseArca.equalsIgnoreCase("")||(nyseArca==null)){
						
					}else{
						bw.write("<identifier venue=\"7c15c3c2-4a25-11e0-b2a1-2a7689193271\" mic=\"ARCX\">\n");
						bw.write("<fields>\n");
						bw.write("<field name=\"exdestination\" value=\"ARCA\" />\n");
						bw.write("<field name=\"symbol\" value=\""+nyseArca+"\" />\n");
						bw.write("</fields>\n");
						bw.write("</identifier>\n");
					}
					
					if(nyseAmex.equalsIgnoreCase("")||(nyseAmex==null)){
						
					}else{
						bw.write("<identifier venue=\"7c15c3c2-4a25-11e0-b2a1-2a7689193271\" mic=\"XASE\">\n");
						bw.write("<fields>\n");
						bw.write("<field name=\"exdestination\" value=\"AMOU\" />\n");
						bw.write("<field name=\"symbol\" value=\""+nyseAmex+"\" />\n");
						bw.write("</fields>\n");
						bw.write("</identifier>\n");
					}
					
					if(nyse.equalsIgnoreCase("")||(nyse==null)){
						
					}else{
						bw.write("<identifier venue=\"7c15c3c2-4a25-11e0-b2a1-2a7689193271\" mic=\"XNYS\">\n");
						bw.write("<fields>\n");
						bw.write("<field name=\"exdestination\" value=\"NYSE\" />\n");
						bw.write("<field name=\"symbol\" value=\""+nyse+"\" />\n");
						bw.write("</fields>\n");
						bw.write("</identifier>\n");
					}
					
					if(bats.equalsIgnoreCase("")||(bats==null)){
						
					}else{
						bw.write("<identifier venue=\"7c15c3c2-4a25-11e0-b2a1-2a7689193271\" mic=\"BATS\">\n");
						bw.write("<fields>\n");
						bw.write("<field name=\"exdestination\" value=\"BATS\" />\n");
						bw.write("<field name=\"symbol\" value=\""+bats+"\" />\n");
						bw.write("</fields>\n");
						bw.write("</identifier>\n");
					}
					
					if(nasdaq.equalsIgnoreCase("")||(nasdaq==null)){
						
					}else{
						bw.write("<identifier venue=\"7c15c3c2-4a25-11e0-b2a1-2a7689193271\" mic=\"XNAS\">\n");
						bw.write("<fields>\n");
						bw.write("<field name=\"exdestination\" value=\"INET\" />\n");
						bw.write("<field name=\"symbol\" value=\""+nasdaq+"\" />\n");
						bw.write("</fields>\n");
						bw.write("</identifier>\n");
					}
					
					if(cbsx.equalsIgnoreCase("")||(cbsx==null)){
						
					}else{
						bw.write("<identifier venue=\"7c15c3c2-4a25-11e0-b2a1-2a7689193271\" mic=\"CBSX\">\n");
						bw.write("<fields>\n");
						bw.write("<field name=\"exdestination\" value=\"CBSX\" />\n");
						bw.write("<field name=\"symbol\" value=\""+cbsx+"\" />\n");
						bw.write("</fields>\n");
						bw.write("</identifier>\n");
					}
					
					if(edge.equalsIgnoreCase("")||(edge==null)){
						
					}else{
						bw.write("<identifier venue=\"7c15c3c2-4a25-11e0-b2a1-2a7689193271\" mic=\"EDGA\">\n");
						bw.write("<fields>\n");
						bw.write("<field name=\"exdestination\" value=\"EDGA\" />\n");
						bw.write("<field name=\"symbol\" value=\""+edge+"\" />\n");
						bw.write("</fields>\n");
						bw.write("</identifier>\n");
					}
					
					if(nsx.equalsIgnoreCase("")||(nsx==null)){
						
					}else{
						bw.write("<identifier venue=\"7c15c3c2-4a25-11e0-b2a1-2a7689193271\" mic=\"XCIS\">\n");
						bw.write("<fields>\n");
						bw.write("<field name=\"exdestination\" value=\"NSX\" />\n");
						bw.write("<field name=\"symbol\" value=\""+nsx+"\" />\n");
						bw.write("</fields>\n");
						bw.write("</identifier>\n");
					}
					
					if(otcbb.equalsIgnoreCase("")||(otcbb==null)){
						
					}else{
						bw.write("<identifier venue=\"7c15c3c2-4a25-11e0-b2a1-2a7689193271\" mic=\"XOTC\">\n");
						bw.write("<fields>\n");
						bw.write("<field name=\"exdestination\" value=\"OTCBB\" />\n");
						bw.write("<field name=\"symbol\" value=\""+otcbb+"\" />\n");
						bw.write("</fields>\n");
						bw.write("</identifier>\n");
					}
					
					if(otcqx.equalsIgnoreCase("")||(otcqx==null)){
						
					}else{
						bw.write("<identifier venue=\"7c15c3c2-4a25-11e0-b2a1-2a7689193271\" mic=\"OTCQ\">\n");
						bw.write("<fields>\n");
						bw.write("<field name=\"exdestination\" value=\"OTCQX\" />\n");
						bw.write("<field name=\"symbol\" value=\""+otcqx+"\" />\n");
						bw.write("</fields>\n");
						bw.write("</identifier>\n");
					}
					
					
					symbol="";
					
					bw.write("</identifiers>\n");
					bw.write("</instrument>\n");
				}	
					count2=count2+1;
					
				//}
				
			}
			
			bw.write("</instruments>\n</resource>");
			bw.flush();
			bw.close();
			log.info("Done..........................");
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
	
}
