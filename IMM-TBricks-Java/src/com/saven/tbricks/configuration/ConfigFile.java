package com.saven.tbricks.configuration;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * @author Chethan Reddy
 *
 * Helper class to help read config values from files
 */
public class ConfigFile extends Properties implements ConfigSource {

	private static final long serialVersionUID = 1120073107432732804L;
	private String cfgFileName;

	public ConfigFile() {
	}
	
	public ConfigFile(String fileName) throws ConfigurationException {
		initialize(fileName);
	}

	public void initialize(String fileName) throws ConfigurationException {

		cfgFileName = fileName;
		InputStream is = null;
		is = Thread.currentThread().getContextClassLoader().getResourceAsStream(fileName);

		try {
			if (is == null) {
                is = getClass().getClassLoader().getResourceAsStream("tbricks.properties");
            }
            if (is == null) {
                is = getClass().getClassLoader().getResourceAsStream("/tbricks.properties");
            }
            if (is == null) {
                throw new ConfigurationException("Default etf.properties not found in class path");
            }
            load(is);
        } 
		catch (IOException ioe) {
			throw new ConfigurationException("Resource properties file: 'etf.properties' "
                    + "could not be read from the classpath.", ioe);
        }
	}

	public void initialize(InputStream propertiesStream) throws ConfigurationException {

		if (propertiesStream != null) {
            try {
                load(propertiesStream);
            } 
            catch (IOException e) {
            	throw new ConfigurationException("Error loading property data from InputStream", e);
            }
        }
		else {
        	throw new ConfigurationException("Error loading property data from InputStream - InputStream is null.");
        }
	}

	public ConfigFile(Properties defaults) {
		super(defaults);
	}

	public void setCfgFileName(String newCfgFileName) {
		cfgFileName = newCfgFileName;
	}

	public String getCfgFileName() {
		return cfgFileName;
	}

	public String getValue(String attribute) throws ConfigurationException {

		String result = getProperty(attribute);

		if (result == null) {
			String extMsg = attribute + " - Not Found in file " + cfgFileName;
			String intMsg = extMsg;
			ConfigurationException anf = new ConfigurationException(intMsg + extMsg);
			throw anf;
		}

		return result.trim();
	}

	public String getValue(String attribute, String defaultValue) {

		String result = getProperty(attribute);
		if (result == null) {
			result = defaultValue;
		}
		
		return result.trim();
	}
	
}
