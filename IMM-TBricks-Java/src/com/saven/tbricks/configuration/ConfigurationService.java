package com.saven.tbricks.configuration;

import java.io.InputStream;

/**
 *
 * @author CMadadi
 */
public class ConfigurationService {

	private static ConfigFile cfg = null;

	public ConfigurationService() {
		super();
	}

	public static String getValue(String attribute) throws ConfigurationException {
		
		String value = null;
		if (cfg != null) {
			value = cfg.getValue(attribute);
		}

		return value;
	}

	public static String getValue(String attribute, String defValue) throws ConfigurationException {
		
		String value = null;
		if (cfg != null) {
			value = cfg.getValue(attribute, defValue);
		}

		return value;
	}

	public static void initialize(String cfgFileName) throws ConfigurationException {
		if (cfg == null) {
			cfg = new ConfigFile(cfgFileName);
		}
	}

	public static void initialize(InputStream stream) throws ConfigurationException {
		if (cfg == null) {
			cfg = new ConfigFile();
		}
		cfg.initialize(stream);
	}

}
