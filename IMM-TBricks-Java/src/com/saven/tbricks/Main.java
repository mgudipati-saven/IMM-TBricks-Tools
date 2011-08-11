package com.saven.tbricks;

import java.sql.Connection;

import org.apache.log4j.Logger;

import com.saven.tbricks.configuration.ConfigurationService;
import com.saven.tbricks.dtcc.NSCCImportingParser;
import com.saven.tbricks.dtcc.StubBasketCompXmlGenerator;
import com.saven.tbricks.util.DBUtil;


public class Main {
	private static Logger log = Logger.getLogger(Main.class);
	public static void main(String a[]){
		
		Connection conn=null;
		try{
						
			ConfigurationService.initialize("tbricks.properties");
			conn=DBUtil.getConnection();

			log.info("Tbricks Process Started.....................");
			
			/*Test test=new Test();
			test.getCusips(conn);*/
			
			//IndexUniverseFileParser iufp=new IndexUniverseFileParser();
			//iufp.updateETFMasterTable(conn);
			
			//ExdivdendFileParser efp=new ExdivdendFileParser();
			//efp.intialize(conn);
			//efp.updateExdivdentFileToDB(conn);

			
//	NSCC file parsing method
			/*NSCCImportingParser nsccimp=new NSCCImportingParser();
			nsccimp.parsingAndUpdateNSCCFile(conn);*/
			
//	SPIDER file parsing method
			//StubBasketCompXmlGenerator sbcxg=new StubBasketCompXmlGenerator();
			//sbcxg.stubBasketExporter(conn);
			//sbcxg.basketComponentsExporter(conn);
			
			
			InstrumentsGenerator ig=new InstrumentsGenerator();
			ig.generateInstrumentXML(conn);
			
			/*DBSecuritiesMasterExporter dbse=new DBSecuritiesMasterExporter();
			dbse.exportSecuritiesMasterCSV(conn);
			dbse.masterFileDumpToDB(conn);*/
			
			log.info(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.");
		}catch(Exception ex){
			
			log.error("ErrorReason: "+ex.getMessage());
			//ex.printStackTrace();
		}

		
	}
	
	
}
