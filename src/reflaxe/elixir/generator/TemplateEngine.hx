package reflaxe.elixir.generator;

import reflaxe.elixir.generator.TemplateContext;
import reflaxe.elixir.generator.TemplateContext.TemplateValue;
import reflaxe.elixir.generator.TemplateContext.TemplateValueTools;
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
	public function processContent(content: String, replacements: TemplateContext): String {
		// First handle conditional blocks
		content = processConditionals(content, replacements);
		
		// Then handle simple placeholders
		content = processPlaceholders(content, replacements);
		
		return content;
	}
	
	/**
	 * Process a single file
	 */
	public function processFile(inputPath: String, outputPath: String, replacements: TemplateContext): Void {
		var content = sys.io.File.getContent(inputPath);
		content = processContent(content, replacements);
		sys.io.File.saveContent(outputPath, content);
	}
	
	/**
	 * Replace simple placeholders like __PROJECT_NAME__ and {{PROJECT_NAME}}
	 */
	function processPlaceholders(content: String, replacements: TemplateContext): String {
		// Process __PLACEHOLDER__ style
		content = PLACEHOLDER_PATTERN.map(content, function(r) {
			var key = r.matched(1);
			var value = replacements.get(key);
			if (value != null) return TemplateValueTools.toString(value);

			// Try lowercase version (legacy templates)
			value = replacements.get(key.toLowerCase());
			if (value != null) return TemplateValueTools.toString(value);
			
			// Keep original if no replacement found
			return r.matched(0);
		});
		
		// Process {{PLACEHOLDER}} style
		content = MUSTACHE_PATTERN.map(content, function(r) {
			var key = r.matched(1);
			var value = replacements.get(key);
			if (value != null) return TemplateValueTools.toString(value);

			// Try lowercase version (legacy templates)
			value = replacements.get(key.toLowerCase());
			if (value != null) return TemplateValueTools.toString(value);
			
			// Keep original if no replacement found
			return r.matched(0);
		});
		
		return content;
	}
	
	/**
	 * Process conditional blocks {{#if condition}}...{{/if}}
	 */
	function processConditionals(content: String, context: TemplateContext): String {
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
			var array = context.get(arrayName);
			if (array != null) switch (array) {
				case VArray(items):
					var result = "";
					for (item in items) {
						var itemContext = context.copy();
						itemContext.set("item", item);
						switch (item) {
							case VObject(fields):
								itemContext.mergeFrom(fields);
							default:
						}
						result += processContent(block, itemContext);
					}
					return result;
				default:
			}
			return "";
		});
		
		return content;
	}
	
	/**
	 * Evaluate a condition against the context
	 */
	function evaluateCondition(condition: String, context: TemplateContext): Bool {
		// Handle negation
		if (condition.startsWith("!")) {
			return !evaluateCondition(condition.substr(1), context);
		}
		
		// Handle equality check (e.g., "type==phoenix")
		if (condition.indexOf("==") > 0) {
			var parts = condition.split("==");
			var left = evaluateExpression(parts[0].trim(), context);
			var right = evaluateExpression(parts[1].trim(), context);
			return TemplateValueTools.equals(left, right);
		}
		
		// Handle inequality check (e.g., "type!=basic")
		if (condition.indexOf("!=") > 0) {
			var parts = condition.split("!=");
			var left = evaluateExpression(parts[0].trim(), context);
			var right = evaluateExpression(parts[1].trim(), context);
			return !TemplateValueTools.equals(left, right);
		}
		
		// Simple field check
		return TemplateValueTools.truthy(context.get(condition));
	}
	
	/**
	 * Evaluate an expression (field reference or literal)
	 */
	function evaluateExpression(expr: String, context: TemplateContext): TemplateValue {
		// Remove quotes for string literals
		if ((expr.startsWith('"') && expr.endsWith('"')) || 
			(expr.startsWith("'") && expr.endsWith("'"))) {
			return VString(expr.substr(1, expr.length - 2));
		}
		
		// Check for boolean literals
		if (expr == "true") return VBool(true);
		if (expr == "false") return VBool(false);
		
		// Check for numeric literals
		var num = Std.parseFloat(expr);
		if (!Math.isNaN(num)) {
			// If the token is an integer, preserve it as Int for comparisons.
			var intVal = Std.parseInt(expr);
			return intVal != null && Std.string(intVal) == expr ? VInt(intVal) : VFloat(num);
		}
		
		// Otherwise treat as field reference
		var v = context.get(expr);
		return v != null ? v : VNull;
	}
	
	/**
	 * Transform filename based on replacements
	 */
	public function transformFilename(filename: String, replacements: TemplateContext): String {
		// Replace placeholders in filename
		return processPlaceholders(filename, replacements);
	}
	
	/**
	 * Check if a file should be included based on conditions
	 */
	public function shouldIncludeFile(filename: String, context: TemplateContext): Bool {
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
