package reflaxe.elixir.generator;

import haxe.Template;
using StringTools;

/**
 * Template engine for processing project templates
 * Handles placeholder replacement and conditional sections
 */
class TemplateEngine {
	
	// Placeholder patterns: __PLACEHOLDER__ and {{PLACEHOLDER}}
	static final PLACEHOLDER_PATTERN = ~/__([A-Z_]+)__/g;
	static final MUSTACHE_PATTERN = ~/\{\{([A-Z_]+)\}\}/g;
	
	// Conditional block patterns
	static final IF_PATTERN = ~/\{\{#if\s+(\w+)\}\}(.*?)\{\{\/if\}\}/gs;
	static final UNLESS_PATTERN = ~/\{\{#unless\s+(\w+)\}\}(.*?)\{\{\/unless\}\}/gs;
	static final EACH_PATTERN = ~/\{\{#each\s+(\w+)\}\}(.*?)\{\{\/each\}\}/gs;
	
	public function new() {}
	
	/**
	 * Process file content with replacements
	 */
	public function processContent(content: String, replacements: Dynamic): String {
		// First handle conditional blocks
		content = processConditionals(content, replacements);
		
		// Then handle simple placeholders
		content = processPlaceholders(content, replacements);
		
		// Handle Haxe template syntax if present
		content = processHaxeTemplates(content, replacements);
		
		return content;
	}
	
	/**
	 * Process a single file
	 */
	public function processFile(inputPath: String, outputPath: String, replacements: Dynamic): Void {
		var content = sys.io.File.getContent(inputPath);
		content = processContent(content, replacements);
		sys.io.File.saveContent(outputPath, content);
	}
	
	/**
	 * Replace simple placeholders like __PROJECT_NAME__ and {{PROJECT_NAME}}
	 */
	function processPlaceholders(content: String, replacements: Dynamic): String {
		// Process __PLACEHOLDER__ style
		content = PLACEHOLDER_PATTERN.map(content, function(r) {
			var key = r.matched(1);
			var value = Reflect.field(replacements, key);
			
			if (value != null) {
				return Std.string(value);
			}
			
			// Try lowercase version
			value = Reflect.field(replacements, key.toLowerCase());
			if (value != null) {
				return Std.string(value);
			}
			
			// Keep original if no replacement found
			return r.matched(0);
		});
		
		// Process {{PLACEHOLDER}} style
		content = MUSTACHE_PATTERN.map(content, function(r) {
			var key = r.matched(1);
			var value = Reflect.field(replacements, key);
			
			if (value != null) {
				return Std.string(value);
			}
			
			// Try lowercase version
			value = Reflect.field(replacements, key.toLowerCase());
			if (value != null) {
				return Std.string(value);
			}
			
			// Keep original if no replacement found
			return r.matched(0);
		});
		
		return content;
	}
	
	/**
	 * Process conditional blocks {{#if condition}}...{{/if}}
	 */
	function processConditionals(content: String, context: Dynamic): String {
		// Process {{#if}} blocks
		content = IF_PATTERN.map(content, function(r) {
			var condition = r.matched(1);
			var block = r.matched(2);
			
			if (evaluateCondition(condition, context)) {
				return block;
			}
			return "";
		});
		
		// Process {{#unless}} blocks
		content = UNLESS_PATTERN.map(content, function(r) {
			var condition = r.matched(1);
			var block = r.matched(2);
			
			if (!evaluateCondition(condition, context)) {
				return block;
			}
			return "";
		});
		
		// Process {{#each}} blocks
		content = EACH_PATTERN.map(content, function(r) {
			var arrayName = r.matched(1);
			var block = r.matched(2);
			var array = Reflect.field(context, arrayName);
			
			if (array != null && Std.isOfType(array, Array)) {
				var result = "";
				var items: Array<Dynamic> = cast array;
				for (item in items) {
					// Create a new context with the item
					var itemContext = {};
					
					// Copy original context
					for (field in Reflect.fields(context)) {
						Reflect.setField(itemContext, field, Reflect.field(context, field));
					}
					
					// Add item to context
					if (Std.isOfType(item, String) || Std.isOfType(item, Int) || Std.isOfType(item, Float)) {
						Reflect.setField(itemContext, "item", item);
					} else {
						// Copy item fields to context
						for (field in Reflect.fields(item)) {
							Reflect.setField(itemContext, field, Reflect.field(item, field));
						}
					}
					
					result += processContent(block, itemContext);
				}
				return result;
			}
			return "";
		});
		
		return content;
	}
	
	/**
	 * Evaluate a condition against the context
	 */
	function evaluateCondition(condition: String, context: Dynamic): Bool {
		// Handle negation
		if (condition.startsWith("!")) {
			return !evaluateCondition(condition.substr(1), context);
		}
		
		// Handle equality check (e.g., "type==phoenix")
		if (condition.indexOf("==") > 0) {
			var parts = condition.split("==");
			var left = evaluateExpression(parts[0].trim(), context);
			var right = evaluateExpression(parts[1].trim(), context);
			return left == right;
		}
		
		// Handle inequality check (e.g., "type!=basic")
		if (condition.indexOf("!=") > 0) {
			var parts = condition.split("!=");
			var left = evaluateExpression(parts[0].trim(), context);
			var right = evaluateExpression(parts[1].trim(), context);
			return left != right;
		}
		
		// Simple field check
		var value = Reflect.field(context, condition);
		
		// Check for truthy values
		if (value == null) return false;
		if (Std.isOfType(value, Bool)) {
			var boolVal: Bool = cast value;
			if (boolVal == false) return false;
		}
		if (Std.isOfType(value, Float)) {  // Int is treated as Float in Haxe
			var numVal: Float = cast value;
			if (numVal == 0) return false;
		}
		if (Std.isOfType(value, String)) {
			var strVal: String = cast value;
			if (strVal == "") return false;
		}
		if (Std.isOfType(value, Array)) {
			var arrVal: Array<Dynamic> = cast value;
			if (arrVal.length == 0) return false;
		}
		
		return true;
	}
	
	/**
	 * Evaluate an expression (field reference or literal)
	 */
	function evaluateExpression(expr: String, context: Dynamic): Dynamic {
		// Remove quotes for string literals
		if ((expr.startsWith('"') && expr.endsWith('"')) || 
			(expr.startsWith("'") && expr.endsWith("'"))) {
			return expr.substr(1, expr.length - 2);
		}
		
		// Check for boolean literals
		if (expr == "true") return true;
		if (expr == "false") return false;
		
		// Check for numeric literals
		var num = Std.parseFloat(expr);
		if (!Math.isNaN(num)) {
			return num;
		}
		
		// Otherwise treat as field reference
		return Reflect.field(context, expr);
	}
	
	/**
	 * Process Haxe template syntax (for compatibility)
	 */
	function processHaxeTemplates(content: String, context: Dynamic): String {
		// Check if content contains Haxe template syntax
		if (content.indexOf("::") < 0 && content.indexOf("$$") < 0) {
			return content;
		}
		
		try {
			var template = new Template(content);
			return template.execute(context);
		} catch (e: Dynamic) {
			// If template parsing fails, return original content
			return content;
		}
	}
	
	/**
	 * Transform filename based on replacements
	 */
	public function transformFilename(filename: String, replacements: Dynamic): String {
		// Replace placeholders in filename
		return processPlaceholders(filename, replacements);
	}
	
	/**
	 * Check if a file should be included based on conditions
	 */
	public function shouldIncludeFile(filename: String, context: Dynamic): Bool {
		// Check for conditional file patterns
		// e.g., "auth.hx.if-authentication" should only be included if authentication is true
		
		var conditionalPattern = ~/\.if-(\w+)$/;
		if (conditionalPattern.match(filename)) {
			var condition = conditionalPattern.matched(1);
			return evaluateCondition(condition, context);
		}
		
		// Check for unless patterns
		// e.g., "simple.hx.unless-phoenix" should be excluded if phoenix is true
		var unlessPattern = ~/\.unless-(\w+)$/;
		if (unlessPattern.match(filename)) {
			var condition = unlessPattern.matched(1);
			return !evaluateCondition(condition, context);
		}
		
		return true;
	}
	
	/**
	 * Strip conditional suffixes from filename
	 */
	public function cleanFilename(filename: String): String {
		// Remove .if-* and .unless-* suffixes
		filename = ~/\.if-\w+$/.replace(filename, "");
		filename = ~/\.unless-\w+$/.replace(filename, "");
		return filename;
	}
	
	/**
	 * Create a context object from project options
	 */
	public static function createContext(options: Dynamic): Dynamic {
		var context = {};
		
		// Copy all options to context
		for (field in Reflect.fields(options)) {
			Reflect.setField(context, field, Reflect.field(options, field));
		}
		
		// Add computed fields
		if (Reflect.hasField(options, "name")) {
			var name = Reflect.field(options, "name");
			
			// Various name formats
			Reflect.setField(context, "PROJECT_NAME", name);
			Reflect.setField(context, "PROJECT_NAME_LOWER", name.toLowerCase());
			Reflect.setField(context, "PROJECT_NAME_UPPER", name.toUpperCase());
			Reflect.setField(context, "PROJECT_MODULE", toPascalCase(name));
			Reflect.setField(context, "PROJECT_SNAKE", toSnakeCase(name));
			Reflect.setField(context, "PROJECT_KEBAB", toKebabCase(name));
		}
		
		// Add date/time fields
		var now = Date.now();
		Reflect.setField(context, "YEAR", now.getFullYear());
		Reflect.setField(context, "MONTH", now.getMonth() + 1);
		Reflect.setField(context, "DAY", now.getDate());
		Reflect.setField(context, "TIMESTAMP", now.getTime());
		
		// Add boolean flags for common conditions
		var type = Reflect.field(options, "type");
		if (type != null) {
			Reflect.setField(context, "is_basic", type == "basic");
			Reflect.setField(context, "is_phoenix", type == "phoenix");
			Reflect.setField(context, "is_liveview", type == "liveview");
			Reflect.setField(context, "is_web", type == "phoenix" || type == "liveview");
		}
		
		return context;
	}
	
	// String transformation utilities
	
	static function toPascalCase(str: String): String {
		return ~/[-_\s]+(.)/g.map(str, function(r) {
			return r.matched(1).toUpperCase();
		}).substr(0, 1).toUpperCase() + 
		~/[-_\s]+(.)/g.map(str, function(r) {
			return r.matched(1).toUpperCase();
		}).substr(1);
	}
	
	static function toSnakeCase(str: String): String {
		return ~/([A-Z])/g.replace(str, "_$1").toLowerCase().substr(1);
	}
	
	static function toKebabCase(str: String): String {
		return ~/([A-Z])/g.replace(str, "-$1").toLowerCase().substr(1);
	}
}