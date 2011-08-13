package com.saven.tbricks.util;

import java.sql.Connection;
import java.sql.DriverManager;

import org.apache.log4j.Logger;

import com.saven.tbricks.configuration.ConfigurationConstants;
import com.saven.tbricks.configuration.ConfigurationService;


public class DBUtil {
	private static Logger log = Logger.getLogger(DBUtil.class);
	private static Connection conn = null;
    public static Connection getConnection() throws Exception {
    	   	
    	if(conn == null) {
			
			try {
				Class.forName(ConfigurationService.getValue(ConfigurationConstants.POSITION_DBSERVER_DRIVERCLASS));
				conn=DriverManager.getConnection(ConfigurationService.getValue(ConfigurationConstants.POSITION_DBSERVER_URL),
						ConfigurationService.getValue(ConfigurationConstants.POSITION_DBSERVER_USERNAME),
						ConfigurationService.getValue(ConfigurationConstants.POSITION_DBSERVER_PASSWORD));
			} 
			catch (Exception e) {
				//e.printStackTrace();
				log.error("ErrorReason: "+e.getMessage());
				throw new RuntimeException(e);
				
			}			
		}
    	log.info("Connection........."+conn);
		return conn;
    	
    }
	
    
}
