package com.saven.tbricks.dtcc;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.InputStream;
import java.io.OutputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.ResourceBundle;

import org.apache.log4j.Logger;

import com.saven.tbricks.configuration.ConfigurationConstants;
import com.saven.tbricks.configuration.ConfigurationService;

public class NSCCImportingParser {
private static Logger log = Logger.getLogger(NSCCImportingParser.class);
	
	public void parsingAndUpdateNSCCFile(Connection conn){
		PreparedStatement pstmt=null;
		Statement stmt=null;
		ResourceBundle rs=null;
		String fileName="";
		try{
			
			rs=ResourceBundle.getBundle("tbricks");
			stmt=conn.createStatement();

			pstmt=conn.prepareCall("{call NSCCFile_To_ETF_MasterDaily_Component_Table(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)}");
			
			File folder = new File(ConfigurationService.getValue(ConfigurationConstants.NSCC_FILE_DAILY_LOCATION));
			if(folder.exists()){
			    File[] listOfFiles = folder.listFiles();
		
			    for (int i = 0; i < listOfFiles.length; i++) {
			      if (listOfFiles[i].isFile()) {
			        //System.out.println("File ............." + listOfFiles[i].getName());
			    	  fileName=listOfFiles[i].getName().toString();
			      } else if (listOfFiles[i].isDirectory()) {
			        //System.out.println("Directory " + listOfFiles[i].getName());
			      }
			    }
			}
			
			
			FileReader fr=new FileReader(ConfigurationService.getValue(ConfigurationConstants.NSCC_FILE_DAILY_LOCATION)+fileName);
			BufferedReader br=new BufferedReader(fr);
			String ln="";
			String line="";
			String recordType="";
			String securitySymbol="";
			String tradeDate="";
			String cusip="";
			String componentCount="";
			String unitsperTrade="";
			String cashperCreationUnit="";
			String cashperIndexReceipt="";
			String navPerCreationUnit="";
			String navPerIndexReceipt="";
			String tcaPerCreationUnit="";
			String tsoPerETF="";
			String DividentAmountPerIndexreceipt="";
			String cashIndicator="";
			String componentSymbol="";
			String componentCusip="";
			String issuedIndicator="";
			String foreignIndicator="";
			String exchangeIndicator="";
			String portfolioTradeDate="";
			String componentShareQty="";
			char sign;
			
			double nav=0;
			double navIndexRecipt=0;
			double totalCashCreationUnit=0;
			double totalShareOutstanding=0;
			double dividentAmountPerIndex=0;	
			double cashPerCreation=0;
			double cashPerIndexRcpt=0;
			boolean flag=false;
			
			log.info("Parsing & Insertion Of NSCC File  Data Into DB Begins................. ");
			
			stmt.executeUpdate("delete from etf_components_daily");
			stmt=conn.createStatement();
			stmt.executeUpdate("delete from etf_master_daily");
			
			int count=1;
			
			while ((ln = br.readLine())!= null) // read through next 25,000 records
			{
				line=ln;
				if(flag){
					recordType=line.substring(0,2);
// '01' is the master record for etf_master_daily table		
					
					if(recordType.equalsIgnoreCase("01")){
						securitySymbol=line.substring(2,17);
						tradeDate=line.substring(29,37);
						cusip=line.substring(17,26);
						componentCount=line.substring(37,45);
						unitsperTrade=line.substring(45,53);
						cashperCreationUnit=line.substring(53,67);
						cashPerCreation=(Double.parseDouble(cashperCreationUnit)/100.0);
						//cashperCreationUnit=cashperCreationUnit.substring(0,12)+"."+cashperCreationUnit.substring(12,14);
						cashperIndexReceipt=line.substring(68,81);
						cashPerIndexRcpt=(Double.parseDouble(cashperIndexReceipt)/100.0);
						navPerCreationUnit=line.substring(82,95);
						//if(securitySymbol.trim().equalsIgnoreCase("SPY"))
							//System.out.println("securitySymbol: "+securitySymbol+" BEFORE navPerIndexReceipt: "+navPerCreationUnit);
						nav=(Double.parseDouble(navPerCreationUnit)/100.0);
						//if(securitySymbol.trim().equalsIgnoreCase("SPY"))
							//System.out.println("securitySymbol: "+securitySymbol+" AFTER navPerIndexReceipt: "+nav);
						navPerIndexReceipt=line.substring(96,109);
						navIndexRecipt=(Double.parseDouble(navPerIndexReceipt)/100.0f);
						sign=line.charAt(123);
						tcaPerCreationUnit=line.substring(110,123);
						totalCashCreationUnit=(Double.parseDouble(sign+tcaPerCreationUnit)/100.0f);
						tsoPerETF=line.substring(126,136);
						totalShareOutstanding=Double.parseDouble(tsoPerETF);
						DividentAmountPerIndexreceipt=line.substring(136,149);
						dividentAmountPerIndex=(Double.parseDouble(DividentAmountPerIndexreceipt)/100.0f);
						cashIndicator=line.substring(150);

						System.out.println("RecordType...................."+recordType+"  Count:  "+count);
						
						count++;
						
						
//	 '02' is the child record for etf_components_daily table								
					}else if(recordType.equalsIgnoreCase("02")){
						
						componentSymbol=line.substring(2,17);
						componentCusip=line.substring(17,26);
						issuedIndicator=line.substring(26,27);
						foreignIndicator=line.substring(70,71);
						exchangeIndicator=line.substring(71,72);
						portfolioTradeDate=line.substring(29,37);
						componentShareQty=line.substring(37,45);
					}
					
					pstmt.setString(1,recordType.trim());
					pstmt.setString(2,securitySymbol.trim());
					pstmt.setString(3,tradeDate.trim());
					pstmt.setString(4,cusip.trim());
					pstmt.setString(5,componentCount.trim());
					pstmt.setString(6,unitsperTrade.trim());
					pstmt.setDouble(7,cashPerCreation);
					pstmt.setDouble(8,cashPerIndexRcpt);
					//pstmt.setString(9,navPerCreationUnit.trim());
					pstmt.setDouble(9,nav);
					pstmt.setDouble(10,navIndexRecipt);
					pstmt.setDouble(11,totalCashCreationUnit);
					pstmt.setDouble(12,totalShareOutstanding);
					pstmt.setDouble(13,dividentAmountPerIndex);
					pstmt.setString(14,cashIndicator.trim());
					pstmt.setString(15,componentSymbol.trim());
					pstmt.setString(16,componentCusip.trim());
					pstmt.setString(17,issuedIndicator.trim());
					pstmt.setString(18,foreignIndicator.trim());
					if(exchangeIndicator.trim().equalsIgnoreCase("")){
						pstmt.setString(19,exchangeIndicator.trim());
					}else{
					pstmt.setString(19,rs.getString(exchangeIndicator.trim()));
					}
					pstmt.setString(20,portfolioTradeDate.trim());
					pstmt.setString(21,componentShareQty.trim());
					
					
					//System.out.println("securitySymbol: "+securitySymbol+" componentSymbol: "+componentSymbol+" cusip: "+cusip);
					
					pstmt.executeUpdate();
				}else{
					flag=true;
				}
			
				
			}
			log.info("Completed ............................................. ");
			br.close();
			fr.close();

//Procedure for updating basket_shares and nav_div in etf_master_daily table
			
			pstmt=conn.prepareCall("{call etf_masterdaily_basketshares_nav_update()}");
			pstmt.executeUpdate();
			
			pstmt=conn.prepareCall("{call etf_masterdaily_today_etf_div_update()}");
			pstmt.executeUpdate();
			
			moveFile(ConfigurationService.getValue(ConfigurationConstants.NSCC_FILE_DAILY_LOCATION)+fileName,ConfigurationService.getValue(ConfigurationConstants.NSCC_FILE_HISTORY_LOCATION)+fileName);
			delete(ConfigurationService.getValue(ConfigurationConstants.NSCC_FILE_DAILY_LOCATION)+fileName);
			
		}catch(Exception ex){
			ex.printStackTrace();
			log.error("ErorrReason: "+ex.getMessage());
		}
		
		finally{
			
			if(pstmt!=null){
				try{
					pstmt.close();
				}catch(Exception ex){
					log.error("ErrorReason: "+ex.getMessage());
				}
			}
			
			if(stmt!=null){
				try{
					stmt.close();
				}catch(Exception ex){
					log.error("ErrorReason: "+ex.getMessage());
				}
			}
			
			/*if(conn!=null){
				try{
					conn.close();
				}catch(Exception ex){
					log.error("ErrorReason: "+ex.getMessage());
				}
			}*/
			
		}
	}
	
	
	private void moveFile(String src,String dest){
		File srcFile=null;
		File destFile=null;
		InputStream in = null;
		OutputStream out = null;
		try{
			
			srcFile=new File(src);
			destFile=new File(dest);
			
			if(!destFile.exists()){
				  
				destFile.createNewFile();
			 
			    }

			 in = new FileInputStream(srcFile);
			 out = new FileOutputStream(destFile);
			 
			 byte[] buf = new byte[1024];
      	     int len;
			 while((len = in.read(buf)) > 0){
			        out.write(buf, 0, len);
			 }
			log.info("NSCC File Moved To HISTORY Folder.................");	
		
		}catch(Exception ex){
			ex.printStackTrace();
		}
	finally{
		try{		
			in.close();
			out.close();
		}catch(Exception ex){
			ex.printStackTrace();
		}
		
	}
		
}
	
	
	private  boolean delete(String resource){ 
		 boolean flag=false;
		 File srcFile=null;
		try{
	         // System.out.println("File......."+resource);
	      	  srcFile=new File(resource);
	      	  if(srcFile.isFile())
	          flag=srcFile.delete();
	      	log.info("NSCC File Deleted From TODAY Folder................."+flag);	
		}catch(Exception ex){
			ex.printStackTrace();
		}
		return flag;
	 
	  }
	
	/*public static void main(String a[]){
		Connection conn=null;
		try{
			
			ConfigurationService.initialize("hcdailytrade.properties");
			conn=DBUtil.getConnection();
			System.out.println("Connection.........."+conn);
			NSCCDailyParser etcp=new NSCCDailyParser();
			etcp.parsingAndUpdateNSCCFile(conn);
		}catch (Exception e) {
			// TODO: handle exception
			e.printStackTrace();
		}
	}*/
}
