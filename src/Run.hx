package;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import reflaxe.elixir.generator.ProjectGenerator;
import reflaxe.elixir.generator.InteractiveCLI;
using StringTools;

/**
 * Entry point for haxelib/lix run command
 * Usage: 
 *   npx lix run reflaxe.elixir create my-app
 *   haxelib run reflaxe.elixir create my-app
 */
class Run {
	static final FALLBACK_VERSION = "unknown";
	
	public static function main() {
		var args = Sys.args();
		
		// When run via haxelib/lix, the last argument is the working directory
		var workingDir = "";
		if (args.length > 0 && FileSystem.exists(args[args.length - 1])) {
			workingDir = args.pop();
			Sys.setCwd(workingDir);
		}
		
		if (args.length == 0) {
			showHelp();
			return;
		}
		
		var command = args[0];
		
		switch (command) {
			case "create":
				handleCreate(args.slice(1));
			case "version", "--version", "-v":
				Sys.println('Reflaxe.Elixir v${detectVersion()}');
			case "help", "--help", "-h":
				showHelp();
			default:
				Sys.println('Unknown command: $command');
				Sys.println("");
				showHelp();
				Sys.exit(1);
		}
	}
	
	static function handleCreate(args: Array<String>) {
		var projectName = "";
		var projectType = "";
		var interactive = true;
		var skipInstall = false;
		var verbose = false;
		
		// Parse arguments
		var i = 0;
		while (i < args.length) {
			var arg = args[i];
			switch (arg) {
				case "--type", "-t":
					if (i + 1 < args.length) {
						projectType = args[++i];
					}
				case "--no-interactive":
					interactive = false;
				case "--skip-install":
					skipInstall = true;
				case "--verbose", "-v":
					verbose = true;
				case "--help", "-h":
					showCreateHelp();
					return;
				default:
					if (!arg.startsWith("-") && projectName == "") {
						projectName = arg;
					}
			}
			i++;
		}
		
		// Interactive mode if needed
		if (interactive) {
			var config = InteractiveCLI.promptProjectConfiguration(projectName, projectType);
			projectName = config.name;
			projectType = config.type;
			skipInstall = config.skipInstall || skipInstall;
		} else if (projectName == "") {
			Sys.println("Error: Project name is required");
			Sys.println("Usage: haxelib run reflaxe.elixir create <project-name> [options]");
			Sys.exit(1);
		}
		
		// Default project type
		if (projectType == "") {
			projectType = "basic";
		}
		
		// Validate project type
		var validTypes = ["basic", "phoenix", "liveview", "add-to-existing"];
		if (!validTypes.contains(projectType)) {
			Sys.println('Error: Invalid project type "$projectType"');
			Sys.println('Valid types: ${validTypes.join(", ")}');
			Sys.exit(1);
		}
		
		// Generate the project
		try {
			Sys.println("");
			Sys.println('🚀 Creating Reflaxe.Elixir project: $projectName');
			Sys.println('   Type: $projectType');
			Sys.println("");
			
			var generator = new ProjectGenerator();
			var options = {
				name: projectName,
				type: projectType,
				skipInstall: skipInstall,
				verbose: verbose,
				vscode: true, // Always include VS Code config
				workingDir: Sys.getCwd()
			};
			
			generator.generate(options);
			
			Sys.println("");
			Sys.println('✨ Project created successfully!');
			Sys.println("");
			showNextSteps(projectName, projectType, skipInstall);
			
		} catch (e: Dynamic) {
			Sys.println('Error: Failed to create project');
			Sys.println('  $e');
			Sys.exit(1);
		}
	}
	
	static function showNextSteps(projectName: String, projectType: String, skipInstall: Bool) {
		Sys.println("📝 Next steps:");
		Sys.println("");
		Sys.println('  cd $projectName');
		
		if (skipInstall) {
			Sys.println('  npm install          # Install Haxe dependencies');
			Sys.println('  mix deps.get         # Install Elixir dependencies');
			Sys.println('  npx lix download     # Install Haxe libraries (per .haxerc)');
		}
		
		Sys.println('  haxe build.hxml                 # Compile Haxe to Elixir');
		Sys.println('  # or: npx lix run haxe build.hxml  (lix-managed toolchain)');
		
		if (projectType == "phoenix" || projectType == "liveview") {
			Sys.println('  mix ecto.create      # Create database');
			Sys.println('  mix phx.server       # Start Phoenix server');
			Sys.println("");
			Sys.println("  Then visit http://localhost:4000");
		} else if (projectType == "basic") {
			Sys.println('  mix run              # Run the application');
		}
		
		Sys.println("");
		Sys.println("📚 Documentation:");
		Sys.println("  https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/docs/01-getting-started/installation.md");
		Sys.println("");
		Sys.println("Happy coding! 🎉");
	}
	
	static function showHelp() {
		Sys.println("Reflaxe.Elixir - Haxe to Elixir Compiler");
		Sys.println("");
		Sys.println("Usage:");
		Sys.println("  haxelib run reflaxe.elixir <command> [options]");
		Sys.println("  npx lix run reflaxe.elixir <command> [options]");
		Sys.println("");
		Sys.println("Commands:");
		Sys.println("  create <name>    Create a new Reflaxe.Elixir project");
		Sys.println("  version          Show version information");
		Sys.println("  help             Show this help message");
		Sys.println("");
		Sys.println("Examples:");
		Sys.println("  haxelib run reflaxe.elixir create my-app");
		Sys.println("  haxelib run reflaxe.elixir create my-phoenix-app --type phoenix");
		Sys.println("  npx lix run reflaxe.elixir create my-app --no-interactive");
		Sys.println("");
		Sys.println("For more information, visit:");
		Sys.println("  https://github.com/fullofcaffeine/reflaxe.elixir");
	}

	static function detectVersion(): String {
		try {
			var versionFromCwd = readVersionFrom(Path.join([Sys.getCwd(), "haxelib.json"]));
			if (versionFromCwd != null) return versionFromCwd;

			// When installed via haxelib/lix, Sys.programPath() typically lives under the library dir.
			// Walk upward a few levels looking for haxelib.json.
			var currentDir = Path.directory(Sys.programPath());
			var steps = 0;
			while (currentDir != null && currentDir != "/" && steps < 8) {
				var candidate = Path.join([currentDir, "haxelib.json"]);
				var version = readVersionFrom(candidate);
				if (version != null) return version;

				currentDir = Path.directory(currentDir);
				steps++;
			}
		} catch (_: Dynamic) {}

		return FALLBACK_VERSION;
	}

	static function readVersionFrom(path: String): Null<String> {
		if (!FileSystem.exists(path)) return null;

		try {
			var content = File.getContent(path);
			var parsed: Dynamic = haxe.Json.parse(content);
			var name: Null<String> = Reflect.field(parsed, "name");
			var version: Null<String> = Reflect.field(parsed, "version");

			if (name == "reflaxe.elixir" && version != null && version != "") {
				return version;
			}
		} catch (_: Dynamic) {}

		return null;
	}
	
	static function showCreateHelp() {
		Sys.println("Create a new Reflaxe.Elixir project");
		Sys.println("");
		Sys.println("Usage:");
		Sys.println("  haxelib run reflaxe.elixir create <project-name> [options]");
		Sys.println("");
		Sys.println("Options:");
		Sys.println("  --type, -t <type>    Project type (basic, phoenix, liveview, add-to-existing)");
		Sys.println("  --no-interactive     Skip interactive prompts");
		Sys.println("  --skip-install       Skip dependency installation");
		Sys.println("  --verbose, -v        Verbose output");
		Sys.println("  --help, -h           Show this help");
		Sys.println("");
		Sys.println("Project Types:");
		Sys.println("  basic            Standard Mix project with utilities");
		Sys.println("  phoenix          Full Phoenix web application");
		Sys.println("  liveview         Phoenix with LiveView components");
		Sys.println("  add-to-existing  Add Haxe to existing Elixir project");
		Sys.println("");
		Sys.println("Examples:");
		Sys.println("  haxelib run reflaxe.elixir create my-app");
		Sys.println("  haxelib run reflaxe.elixir create my-app --type phoenix");
		Sys.println("  haxelib run reflaxe.elixir create my-app --no-interactive --skip-install");
	}
}
