package com.saven.tbricks;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.util.Date;

import org.apache.log4j.Logger;

import com.saven.tbricks.configuration.ConfigurationConstants;
import com.saven.tbricks.configuration.ConfigurationService;
import com.saven.tbricks.dtcc.NSCCImportingParser;



public class DBSecuritiesMasterExporter {
	private static Logger log = Logger.getLogger(DBSecuritiesMasterExporter.class);
	
	public void exportSecuritiesMasterCSV(Connection conn){
		
		log.info("Generating SecuritiesMaster As .txt.....................");
		
		String fileName="securities_master.txt";
		
		String query="select * from securities_master";
		String header="CUSIP|ARCX|XASE|XNYS|BATS|XNAS|CBSX|EDGA|XCIS|XOTC|OTCQX|Ratio DR ORD|Company Name|Security type|Security Id|Security Symbol BB|Security Description|Sedol|Isin|Listed Exchanges|Gics Sector|Gics Sector Name|Gics Industry Group|Gics Industry Group Name|Gics Industry|Gics Industry Name|Gics Sub Industry|Gics Sub Industry Name|Last Updated";
		
		String cusip="";
		String nyseArca="";
		String nyseAmex="";
		String nyse="";
		String bats="";
		String nasdaq="";
		String cbsx="";
		String edge="";
		String nsx="";
		String xotc="";
		String otcq="";
		String ratioDrOrd="";
		String companyName="";
		String securityType="";
		String securityId="";
		String securitySymbolBB="";
		String securityDescription="";
		String sedol="";
		String isin="";
		String listedExchanges="";
		String gicsSector="";
		String gicsSectorName="";
		String gicsIndustryGroup="";
		String gicsIndustryGroupName="";	
		String gicsIndustry="";
		String gicsIndustryName="";
		String gicsSubIndustry="";
		String gicsSubIndustryName="";
		String lastUpdated="";
		
		long date=0;
		
		PreparedStatement pstmt=null;
		ResultSet rs=null;
		try{
			pstmt=conn.prepareStatement(query);
			rs=pstmt.executeQuery();
			StringBuffer sb=new StringBuffer();
			SimpleDateFormat sdf=new SimpleDateFormat("MM/dd/yyyy");
			FileWriter writer = new FileWriter(ConfigurationService.getValue(ConfigurationConstants.NSCC_FILE_BASKETCOMP_XML)+fileName);
			
			//BufferedWriter bw = new BufferedWriter(writer);
			sb.append(header+"\n");
			
			Date dt=new Date();			
			while(rs.next()){
				
				cusip=rs.getString("cusip");
				nyseArca=rs.getString("arcx");
				nyseAmex=rs.getString("xase");
				nyse=rs.getString("xnys");
				bats=rs.getString("bats");
				nasdaq=rs.getString("xnas");
				cbsx=rs.getString("cbsx");
				edge=rs.getString("edga"); 
				nsx=rs.getString("xcis"); 
				xotc=rs.getString("xotc"); 
				otcq=rs.getString("otcq"); 
				
				ratioDrOrd=rs.getString("ratio_dr_ord");
				companyName=rs.getString("company_name");
				securityType=rs.getString("security_type");
				securityId=rs.getString("security_id");
				securitySymbolBB=rs.getString("security_symbol_bb");
				securityDescription=rs.getString("security_description");
				sedol=rs.getString("sedol");
				isin=rs.getString("isin");
				listedExchanges=rs.getString("listed_exchanges");
				gicsSector=rs.getString("gics_sector");
				gicsSectorName=rs.getString("gics_sector_name");
				gicsIndustryGroup=rs.getString("gics_industry_group");
				gicsIndustryGroupName=rs.getString("gics_industry_group_name");
				gicsIndustry=rs.getString("gics_industry");
				gicsIndustryName=rs.getString("gics_industry_name");
				gicsSubIndustry=rs.getString("gics_sub_industry");
				gicsSubIndustryName=rs.getString("gics_sub_industry_name");
				
				date=rs.getDate("last_updated").getTime();
				
				dt.setTime(date);
				
				sb.append(cusip+"|");
				sb.append(testNULLAndEmpty(nyseArca)+"|");
				sb.append(testNULLAndEmpty(nyseAmex)+"|");
				sb.append(testNULLAndEmpty(nyse)+"|");
				sb.append(testNULLAndEmpty(bats)+"|");
				sb.append(testNULLAndEmpty(nasdaq)+"|");
				sb.append(testNULLAndEmpty(cbsx)+"|");
				sb.append(testNULLAndEmpty(edge)+"|");
				sb.append(testNULLAndEmpty(nsx)+"|");
				sb.append(testNULLAndEmpty(xotc)+"|");
				sb.append(testNULLAndEmpty(otcq)+"|");
				sb.append(testNULLAndEmpty(ratioDrOrd)+"|");
				sb.append(testNULLAndEmpty(companyName)+"|");
				//sb.append(testNULLAndEmpty(securitySymbol)+"|");
				sb.append(testNULLAndEmpty(securityType)+"|");
				sb.append(testNULLAndEmpty(securityId)+"|");
				sb.append(testNULLAndEmpty(securitySymbolBB)+"|");
				sb.append(testNULLAndEmpty(securityDescription)+"|");
				sb.append(testNULLAndEmpty(sedol)+"|");
				sb.append(testNULLAndEmpty(isin)+"|");
				sb.append(testNULLAndEmpty(listedExchanges)+"|");
				sb.append(testNULLAndEmpty(gicsSector)+"|");
				sb.append(testNULLAndEmpty(gicsSectorName)+"|");
				sb.append(testNULLAndEmpty(gicsIndustryGroup)+"|");
				sb.append(testNULLAndEmpty(gicsIndustryGroupName)+"|");
				sb.append(testNULLAndEmpty(gicsIndustry)+"|");
				sb.append(testNULLAndEmpty(gicsIndustryName)+"|");
				sb.append(testNULLAndEmpty(gicsSubIndustry)+"|");
				sb.append(testNULLAndEmpty(gicsSubIndustryName)+"|");
				sb.append(testNULLAndEmpty(sdf.format(dt))+"\n");
								
				//sb.append("\""+testNULLAndEmpty(lastUpdated)+"\"\n");
				
				/*if(nsx.trim().equalsIgnoreCase("ADSI")){
					
					System.out.println(testNULLAndEmpty(securitySymbolBB));
					
				}*/
			}
			
			writer.append(sb.toString());
			writer.flush();
			writer.close();
			
			log.info("Ended.....................");
			
		}catch(Exception ex){
			ex.printStackTrace();
			log.error("Error Reason:  "+ex.getMessage());
		}
		
		finally{
			
			if(pstmt!=null){
				try{
					pstmt.close();
				}catch(Exception ex){
					log.error("ErrorReason: "+ex.getMessage());
				}
				
			}
			if(rs!=null){
				try{
					rs.close();
				}catch(Exception ex){
					log.error("ErrorReason: "+ex.getMessage());
				}
				
			}
			
		}
		
	}
	
	private String testNULLAndEmpty(String value){
		
		if(value.equalsIgnoreCase("")||(value.equalsIgnoreCase("NULL"))){
			
			value="";
		}
		
		return value;
	}
	
	public void masterFileDumpToDB(Connection conn){
		
		String line="";
		String ln="";
		
		String cusip="";
		String nyseArca="";
		String nyseAmex="";
		String nyse="";
		String bats="";
		String nasdaq="";
		String cbsx="";
		String edge="";
		String nsx="";
		String xotc="";
		String otcq="";
		String ratioDrOrd="";
		String companyName="";
		String securitySymbol="";
		String securityType="";
		String securityId="";
		String securitySymbolBB="";
		String securityDescription="";
		String sedol="";
		String isin="";
		String listedExchanges="";
		String gicsSector="";
		String gicsSectorName="";
		String gicsIndustryGroup="";
		String gicsIndustryGroupName="";	
		String gicsIndustry="";
		String gicsIndustryName="";
		String gicsSubIndustry="";
		String gicsSubIndustryName="";
		
		String fields[]=null;
		
		PreparedStatement pstmt1=null;
		try{
			
			log.info("Importing SecuritiesMaster text file into DB.....................");
			
			pstmt1=conn.prepareStatement("delete from securities_master");
			pstmt1.executeUpdate();
			
			pstmt1=conn.prepareStatement("insert into securities_master(cusip,arcx,xase,xnys,bats,xnas,cbsx," +
					"edga,xcis,xotc,otcq,ratio_dr_ord,company_name,security_type," +
					"listed_exchanges) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
			
			FileReader fr=new FileReader(ConfigurationService.getValue(ConfigurationConstants.NSCC_FILE_BASKETCOMP_XML)+"securities_master.txt");
			BufferedReader br=new BufferedReader(fr);
			br.readLine();
			while ((ln = br.readLine())!= null) // read through next 25,000 records
			{
				line=ln;
				
				fields=line.split("\\|",29);
				
				cusip=testNULLAndEmpty(fields[0]);
				nyseArca=testNULLAndEmpty(fields[1]);
				nyseAmex=testNULLAndEmpty(fields[2]);
				nyse=testNULLAndEmpty(fields[3]);
				bats=testNULLAndEmpty(fields[4]);
				nasdaq=testNULLAndEmpty(fields[5]);	
				cbsx=testNULLAndEmpty(fields[6]);	
				edge=testNULLAndEmpty(fields[7]);	
				nsx=testNULLAndEmpty(fields[8]);
				xotc=testNULLAndEmpty(fields[9]);
				otcq=testNULLAndEmpty(fields[10]);
				ratioDrOrd=testNULLAndEmpty(fields[11]);
				companyName=testNULLAndEmpty(fields[12]);
				securityType=testNULLAndEmpty(fields[13]);
				listedExchanges=testNULLAndEmpty(fields[19]);
					
				pstmt1.setString(1,cusip.trim());
				pstmt1.setString(2,nyseArca.trim());
				pstmt1.setString(3,nyseAmex.trim());
				pstmt1.setString(4,nyse.trim());
				pstmt1.setString(5,bats.trim());
				pstmt1.setString(6,nasdaq.trim());
				pstmt1.setString(7,cbsx.trim());
				pstmt1.setString(8,edge.trim());
				pstmt1.setString(9,nsx.trim());
				pstmt1.setString(10,xotc.trim());
				pstmt1.setString(11,otcq.trim());
				pstmt1.setString(12,ratioDrOrd.trim());
				pstmt1.setString(13,companyName.trim());
				pstmt1.setString(14,securityType.trim());
				pstmt1.setString(15,listedExchanges.trim());
				
				
				pstmt1.executeUpdate();
				
			}	
			log.info("Ended....................");
		}catch(Exception ex){
			ex.printStackTrace();
			log.error("Error Reason: "+ex.getLocalizedMessage());
		}
		
		finally{
			
			if(pstmt1!=null){
				
				try{
					pstmt1.close();
				}catch(Exception ex){
					log.error("Error Reason: "+ex.getMessage());
				}
			}
			
		}
		
	}
	
	
	
}
