package com.saven.tbricks.configuration;

/**
 * Interface to help read configuration values
 * 
 * @author Chethan Reddy
 */
public interface ConfigSource {

	/**
	 * getValue method returns the value of an attribute
	 * @return java.lang.String
	 * @param attribute java.lang.String
	 * @exception com.saventech.etf.configuration.ConfigurationException The exception description.
	 */
	String getValue(String attribute) throws ConfigurationException;
	
	/**
	 * This method returns defaultValue if the attribute is not found
	 * Creation date: (6/2/01 9:50:36 AM)
	 * @return java.lang.String
	 * @param attribute java.lang.String
	 * @param defaultValue java.lang.String
	 */
	String getValue(String attribute, String defaultValue);
	
}
