package com.saven.tbricks.configuration;

/**
 * Throw to indicate a non-fatal configuration related problem.
 *
 * @see ConfigurationService
 */
public class ConfigurationException extends Exception {
	
	private static final long serialVersionUID = 973174958500481885L;
	
	/** The root cause of this exception */
	protected Throwable cause;

	/**
	 * Construct a <tt>ConfigurationException</tt>.
	 *
	 * @param message    The exception detail message.
	 */
	public ConfigurationException(final String message) {
		super(message);
	}

	/**
	 * Construct a <tt>ConfigurationException</tt>.
	 *
	 * @param message    The exception detail message.
	 * @param cause      The detail cause of the exception.
	 */
	public ConfigurationException(final String message, final Throwable cause) {
		super(message);
		this.cause = cause;
	}

	/**
	 * Get the cause of the exception.
	 *
	 * @return  The cause of the exception or null if there is none.
	 */
	public Throwable getCause() {
		return cause;
	}

	/**
	 * Return a string representation of the exception.
	 *
	 * @return  A string representation.
	 */
	public String toString() {
		return cause == null ? super.toString() : super.toString()
				+ ", Cause: " + cause;
	}
	
}
