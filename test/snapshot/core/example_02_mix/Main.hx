package;

import utils.StringUtils;

/**
 * Example 02: Mix Integration with Utility Modules
 *
 * This example demonstrates:
 * - Using utility modules in a Mix project structure
 * - String processing functions for web applications
 * - Validation and formatting utilities
 */
class Main {
	public static function main() {
		trace("=== StringUtils Mix Integration Example ===");

		// Test string processing
		var rawInput = "   hello  world   ";
		var processed = StringUtils.processString(rawInput);
		trace('Processed: "$rawInput" -> "$processed"');

		// Test display name formatting
		var userName = "john DOE smith";
		var formatted = StringUtils.formatDisplayName(userName);
		trace('Display Name: "$userName" -> "$formatted"');

		// Test email validation and processing
		var email = "  User@Example.COM  ";
		var emailResult = StringUtils.processEmail(email);
		trace('Email validation: ${emailResult.valid ? "valid" : "invalid"}');
		if (emailResult.valid) {
			trace('  Normalized: ${emailResult.email}');
			trace('  Domain: ${emailResult.domain}');
			trace('  Username: ${emailResult.username}');
		}

		// Test slug generation for URLs
		var title = "Hello World! This is a Test...";
		var slug = StringUtils.createSlug(title);
		trace('URL Slug: "$title" -> "$slug"');

		// Test text truncation
		var longText = "This is a very long text that needs to be truncated to fit in a preview area or card component.";
		var truncated = StringUtils.truncate(longText, 50);
		trace('Truncated: "$truncated"');

		// Test sensitive info masking
		var sensitiveData = "secret123";
		var masked = StringUtils.maskSensitiveInfo(sensitiveData, 2);
		trace('Masked: "$sensitiveData" -> "$masked"');

		trace("=== Example completed successfully ===");
	}
}
