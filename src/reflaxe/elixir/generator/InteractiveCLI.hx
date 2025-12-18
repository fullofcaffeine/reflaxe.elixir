package reflaxe.elixir.generator;

import sys.io.File;
import haxe.io.Input;
using StringTools;

/**
 * Interactive CLI for project configuration
 * Handles user prompts and input validation
 */
class InteractiveCLI {
	
	static var input: Input = Sys.stdin();
	
	public static function promptProjectConfiguration(?defaultName: String, ?defaultType: String): ProjectConfig {
		Sys.println("🎯 Reflaxe.Elixir Project Generator");
		Sys.println("===================================");
		Sys.println("");
		
		// Project name
		var name: String = if (defaultName != null && defaultName != "") {
			defaultName;
		} else {
			prompt("Project name", "my-app");
		};
		
		// Project type
		var type: String = if (defaultType != null && defaultType != "") {
			defaultType;
		} else {
			promptChoice(
				"Project type",
				[
					{value: "basic", label: "Basic - Standard Mix project with utilities"},
					{value: "phoenix", label: "Phoenix - Full web application"},
					{value: "liveview", label: "LiveView - Phoenix with LiveView components"},
					{value: "add-to-existing", label: "Add to existing - Add Haxe to current project"}
				],
				"basic"
			);
		};
		
		// Additional options based on type
		var options: ProjectConfig = {
			name: name,
			type: type,
			skipInstall: false,
			includeExamples: true,
			database: null,
			authentication: null
		};
		
		// Phoenix-specific options
		if (type == "phoenix" || type == "liveview") {
			options.database = promptChoice(
				"Database",
				[
					{value: "postgres", label: "PostgreSQL (recommended)"},
					{value: "mysql", label: "MySQL"},
					{value: "sqlite", label: "SQLite"},
					{value: "none", label: "No database"}
				],
				"postgres"
			);
			
			if (type == "liveview") {
				options.authentication = promptYesNo("Include authentication?", true);
			}
		}
		
		// Common options
		if (type != "add-to-existing") {
			options.includeExamples = promptYesNo("Include example modules?", true);
		}
		
		options.skipInstall = !promptYesNo("Install dependencies now?", true);
		
		// Confirmation
		Sys.println("");
		Sys.println("📋 Project Configuration:");
		Sys.println('  Name: ${options.name}');
		Sys.println('  Type: ${options.type}');
		if (options.database != null) {
			Sys.println('  Database: ${options.database}');
		}
		if (options.authentication == true) {
			Sys.println('  Authentication: Yes');
		}
		Sys.println('  Install dependencies: ${options.skipInstall ? "No" : "Yes"}');
		Sys.println("");
		
		if (!promptYesNo("Create project with these settings?", true)) {
			Sys.println("Cancelled.");
			Sys.exit(0);
		}
		
		return options;
	}
	
	public static function prompt(question: String, ?defaultValue: String): String {
		var promptText = defaultValue != null 
			? '$question [$defaultValue]: '
			: '$question: ';
		
		Sys.print(promptText);
		var answer = input.readLine();
		
		if (answer == "" && defaultValue != null) {
			return defaultValue;
		}
		
		if (answer == "") {
			Sys.println("  ⚠️  This field is required");
			return prompt(question, defaultValue);
		}
		
		return answer;
	}
	
	public static function promptChoice<T>(question: String, choices: Array<Choice<T>>, defaultValue: T): T {
		Sys.println("");
		Sys.println('$question:');
		
		var defaultIndex = -1;
		for (i in 0...choices.length) {
			var choice = choices[i];
			var marker = choice.value == defaultValue ? " (default)" : "";
			Sys.println('  ${i + 1}. ${choice.label}$marker');
			if (choice.value == defaultValue) {
				defaultIndex = i;
			}
		}
		
		Sys.print("Choose [1-" + choices.length + "]" + 
			(defaultIndex >= 0 ? " [" + (defaultIndex + 1) + "]" : "") + ": ");
		
		var answer = input.readLine();
		
		// Use default if empty
		if (answer == "" && defaultIndex >= 0) {
			return choices[defaultIndex].value;
		}
		
		// Parse choice
		var choiceNum = Std.parseInt(answer);
		if (choiceNum != null && choiceNum >= 1 && choiceNum <= choices.length) {
			return choices[choiceNum - 1].value;
		}
		
		// Check if they typed the value directly
		for (choice in choices) {
			if (Std.string(choice.value) == answer) {
				return choice.value;
			}
		}
		
		Sys.println("  ⚠️  Invalid choice. Please enter a number between 1 and " + choices.length);
		return promptChoice(question, choices, defaultValue);
	}
	
	public static function promptYesNo(question: String, defaultValue: Bool): Bool {
		var options = defaultValue ? "[Y/n]" : "[y/N]";
		Sys.print('$question $options: ');
		
		var answer = input.readLine().toLowerCase();
		
		if (answer == "") {
			return defaultValue;
		}
		
		if (answer == "y" || answer == "yes") {
			return true;
		}
		
		if (answer == "n" || answer == "no") {
			return false;
		}
		
		Sys.println("  ⚠️  Please answer 'y' or 'n'");
		return promptYesNo(question, defaultValue);
	}
	
	public static function promptMultiSelect<T>(question: String, choices: Array<Choice<T>>, defaults: Array<T>): Array<T> {
		Sys.println("");
		Sys.println('$question (space-separated numbers):');
		
		for (i in 0...choices.length) {
			var choice = choices[i];
			var isDefault = defaults != null && defaults.contains(choice.value);
			var marker = isDefault ? " ✓" : "";
			Sys.println('  ${i + 1}. ${choice.label}$marker');
		}
		
		Sys.print("Choose multiple [1-" + choices.length + "] or press Enter for defaults: ");
		
		var answer = input.readLine();
		
		// Use defaults if empty
		if (answer == "" && defaults != null && defaults.length > 0) {
			return defaults;
		}
		
		// Parse choices
		var selected = [];
		var parts = answer.split(" ");
		
		for (part in parts) {
			var choiceNum = Std.parseInt(part);
			if (choiceNum != null && choiceNum >= 1 && choiceNum <= choices.length) {
				var value = choices[choiceNum - 1].value;
				if (!selected.contains(value)) {
					selected.push(value);
				}
			}
		}
		
		if (selected.length == 0) {
			Sys.println("  ⚠️  Please select at least one option");
			return promptMultiSelect(question, choices, defaults);
		}
		
		return selected;
	}
	
	public static function showSpinner(message: String, task: () -> Void): Void {
		var frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
		var frameIndex = 0;
		
		// Note: Haxe doesn't have great async support, so we'll just show a simple message
		Sys.print('$message... ');
		
		try {
			task();
			Sys.println("✓");
		} catch (e: haxe.Exception) {
			Sys.println("✗");
			throw e;
		}
	}
	
	public static function showProgress(message: String, current: Int, total: Int): Void {
		var percent = Math.round((current / total) * 100);
		var barLength = 30;
		var filled = Math.round((current / total) * barLength);
		
		var bar = "[";
		for (i in 0...barLength) {
			bar += i < filled ? "█" : "░";
		}
		bar += "]";
		
		Sys.print('\r$message $bar $percent% ($current/$total)');
		
		if (current >= total) {
			Sys.println("");
		}
	}
	
	public static function showError(message: String): Void {
		Sys.println("");
		Sys.println('❌ Error: $message');
		Sys.println("");
	}
	
	public static function showWarning(message: String): Void {
		Sys.println('⚠️  Warning: $message');
	}
	
	public static function showSuccess(message: String): Void {
		Sys.println('✅ $message');
	}
	
	public static function showInfo(message: String): Void {
		Sys.println('ℹ️  $message');
	}
	
	public static function confirm(message: String): Bool {
		return promptYesNo(message, false);
	}
	
	public static function pause(message: String = "Press Enter to continue..."): Void {
		Sys.print(message);
		input.readLine();
	}
}

typedef Choice<T> = {
	value: T,
	label: String
}

typedef ProjectConfig = {
	name: String,
	type: String,
	skipInstall: Bool,
	includeExamples: Bool,
	?database: String,
	?authentication: Bool
}
