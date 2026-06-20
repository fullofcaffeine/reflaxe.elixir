using StringTools;

/**
 * MathHelper - Demonstrates pipe operators and functional composition
 * 
 * This example showcases Elixir-style pipe operators (|>) for
 * functional composition, making code more readable and maintainable.
 */
// @:module: applies module-macro conveniences so static members emit as idiomatic module functions.
@:module
class MathHelper {
	/**
	 * Basic functional composition demonstration
	 * Shows how data flows through a pipeline of transformations
	 * Note: Pipe operators will be supported in future version
	 */
	public static function processNumber(x:Float):Float {
		var step1 = multiplyByTwo(x);
		var step2 = addTen(step1);
		var step3 = Math.round(step2);
		return step3;
	}

	/**
	 * Complex pipeline with conditional logic
	 * Demonstrates functional composition with branching
	 */
	public static function calculateDiscount(price:Float, customerType:String):Float {
		var step1 = applyBaseDiscount(price);
		var step2 = applyCustomerDiscount(step1, customerType);
		var step3 = applyMinimumPrice(step2);
		return Math.round(step3);
	}

	/**
	 * String processing pipeline
	 * Shows functional composition with different data types
	 */
	public static function formatUserName(name:String):String {
		var step1 = StringTools.trim(name);
		var step2 = step1.toLowerCase();
		return capitalizeFirst(step2);
	}

	/**
	 * Data validation pipeline
	 * Common pattern in Elixir for validation chains
	 */
	public static function validateAndProcess(input:String):String {
		var step1 = validateNotEmpty(input);
		var step2 = validateLength(step1);
		var step3 = sanitizeInput(step2);
		return processInput(step3);
	}

	// Helper functions used in pipelines

	@:private
	static function multiplyByTwo(x:Float):Float {
		return x * 2;
	}

	@:private
	static function addTen(x:Float):Float {
		return x + 10;
	}

	@:private
	static function applyBaseDiscount(price:Float):Float {
		return price * 0.9; // 10% discount
	}

	@:private
	static function applyCustomerDiscount(price:Float, customerType:String):Float {
		return switch (customerType) {
			case "premium": price * 0.8;
			case "regular": price * 0.95;
			case _: price;
		};
	}

	@:private
	static function applyMinimumPrice(price:Float):Float {
		return Math.max(price, 5.0);
	}

	@:private
	static function capitalizeFirst(str:String):String {
		if (str.length == 0)
			return str;
		return str.charAt(0).toUpperCase() + str.substr(1);
	}

	@:private
	static function validateNotEmpty(input:String):String {
		if (input == null || input.length == 0) {
			throw "Input cannot be empty";
		}
		return input;
	}

	@:private
	static function validateLength(input:String):String {
		if (input.length > 100) {
			throw "Input too long";
		}
		return input;
	}

	@:private
	static function sanitizeInput(input:String):String {
		// Simple sanitization - remove dangerous characters
		return StringTools.replace(input, "<", "");
	}

	@:private
	static function processInput(input:String):String {
		return "Processed: " + input;
	}

	/**
	 * Main function for compilation testing
	 */
	public static function main():Void {
		trace("MathHelper example compiled successfully!");
		trace("This demonstrates functional composition patterns.");
		trace("In production, these functions would be called from other modules.");
	}
}
