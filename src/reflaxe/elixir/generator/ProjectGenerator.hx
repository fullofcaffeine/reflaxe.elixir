package reflaxe.elixir.generator;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import reflaxe.elixir.generator.TemplateEngine;
import reflaxe.elixir.generator.TemplateContext;
import reflaxe.elixir.generator.TemplateContext.TemplateValue;

using StringTools;

/**
 * ProjectGenerator (Haxe-side scaffolding)
 *
 * WHAT
 * - Creates new Elixir projects (basic / Phoenix / Phoenix LiveView) by shelling out to Mix generators
 *   (`mix new` / `mix phx.new`) and then layering Reflaxe.Elixir integration on top.
 * - Supports "add-to-existing" mode to scaffold into an existing Mix project directory.
 *
 * WHY
 * - Greenfield projects should start from the canonical Phoenix templates so they stay aligned with
 *   upstream conventions (assets, endpoint wiring, and directory structure).
 * - Existing apps benefit from in-place Mix tasks (`mix haxe.gen.project`, `mix haxe.phoenix.scaffold`)
 *   because those run in the target project's Mix environment and are easier to adopt incrementally.
 *
 * HOW
 * - For new apps: run the appropriate Mix generator, then patch `mix.exs` to add `:haxe` compiler wiring,
 *   write `build.hxml` + `src_haxe/**`, and optionally run `mix haxe.phoenix.scaffold` for Phoenix projects
 *   after dependencies are installed.
 * - For existing apps: modify files in the current directory without creating a new project folder.
 *
 * SCENARIOS
 * - New Phoenix app with Haxe integration: prefer `haxe --run Run create <name> --type phoenix`.
 * - Existing Phoenix app (gradual adoption): prefer `mix haxe.gen.project --phoenix` + `mix haxe.phoenix.scaffold`.
 */
class ProjectGenerator {
	// Supported generator types:
	// - basic: `mix new`
	// - phoenix: `mix phx.new`
	// - liveview: `mix phx.new --live`
	// - add-to-existing: scaffold into the current directory
	public function new() {}

	public function generate(options:GeneratorOptions):Void {
		// Validate project doesn't already exist (unless add-to-existing)
		if (options.type != "add-to-existing") {
			var projectPath = Path.join([options.workingDir, options.name]);
			if (FileSystem.exists(projectPath)) {
				throw 'Directory already exists: $projectPath';
			}
		}

		// Generate based on type
		switch (options.type) {
			case "add-to-existing":
				addToExistingProject(options);
			case "basic", "phoenix", "liveview":
				createNewProject(options);
			default:
				throw 'Invalid project type: ${options.type}';
		}

		// Install dependencies if needed
		if (!options.skipInstall) {
			installDependencies(options);
		}
	}

	function createNewProject(options:GeneratorOptions):Void {
		var projectPath = Path.join([options.workingDir, options.name]);

		if (options.verbose) {
			Sys.println('Creating project using Mix generator...');
		}

		// Use Mix generators to create proper project structure.
		//
		// IMPORTANT: Always use `--no-install` for Phoenix generators to avoid interactive prompts.
		// We install dependencies explicitly in `installDependencies()` when requested.
		var projectModule = toPascalCase(options.name);

		var mixArgs:Null<Array<String>> = switch (options.type) {
			case "basic":
				["new", options.name, "--module", projectModule];
			case "phoenix":
				[
					"phx.new",
					options.name,
					"--module",
					projectModule,
					"--no-dashboard",
					"--no-install"
				];
			case "liveview":
				[
					"phx.new",
					options.name,
					"--module",
					projectModule,
					"--live",
					"--no-dashboard",
					"--no-install"
				];
			default:
				null;
		};

		if (mixArgs == null) {
			throw 'Invalid project type: ${options.type}';
		}

		// Change to working directory and run Mix generator
		var originalDir = Sys.getCwd();
		Sys.setCwd(options.workingDir);

		if (options.verbose) {
			Sys.println('Running: mix ${mixArgs.join(" ")}');
		}

		var result = Sys.command("mix", mixArgs);
		Sys.setCwd(originalDir);

		if (result != 0) {
			throw 'Mix generator failed (exit $result). Ensure Elixir/Mix (and Phoenix for phx.new) are installed.';
		}

		// Add Haxe integration to the project
		addHaxeIntegration(projectPath, options);

		// Create additional Haxe-specific files
		createProjectFiles(projectPath, options);

		// Add VS Code configuration if requested
		if (options.vscode) {
			createVSCodeConfig(projectPath);
		}
	}

	function createDirectoryRecursive(path:String):Void {
		var parts = path.split("/");
		var current = path.startsWith("/") ? "/" : "";
		for (part in parts) {
			if (part.length == 0)
				continue;
			if (current == "" || current == "/") {
				current = current + part;
			} else {
				current = Path.join([current, part]);
			}
			if (!FileSystem.exists(current)) {
				FileSystem.createDirectory(current);
			}
		}
	}

	// Phoenix generators already create the correct JS/CSS asset pipeline (including LiveView JS).
	// Reflaxe.Elixir intentionally does not reimplement Phoenix assets, but for Phoenix/LiveView
	// projects we do generate a minimal, opt-in Haxe client integration:
	// - `mix haxe.phoenix.scaffold` applies the Phoenix client JS scaffold (Genes build + watcher promotion)

	function addHaxeIntegration(projectPath:String, options:GeneratorOptions):Void {
		// 1. Update mix.exs to include :haxe compiler + config, and add the reflaxe_elixir Mix dependency.
		var haxeNamespace = toSnakeCase(options.name) + "_hx";
		var outputDir = 'lib/${haxeNamespace}';

		var mixPath = Path.join([projectPath, "mix.exs"]);
		if (FileSystem.exists(mixPath)) {
			var mixContent = File.getContent(mixPath);
			mixContent = ensureReflaxeElixirDependency(mixContent);
			mixContent = ensureHaxeCompilerConfigured(mixContent, "src_haxe", outputDir);
			mixContent = ensureHaxeTestAliases(mixContent);
			File.saveContent(mixPath, mixContent);
		}

		// 2. Create src_haxe directory if it doesn't exist
		var srcHaxePath = Path.join([projectPath, "src_haxe"]);
		if (!FileSystem.exists(srcHaxePath)) {
			FileSystem.createDirectory(srcHaxePath);
		}

		// 3. Create a minimal Haxe entrypoint in an isolated namespace.
		var namespaceDir = Path.join([srcHaxePath, haxeNamespace]);
		if (!FileSystem.exists(namespaceDir)) {
			createDirectoryRecursive(namespaceDir);
		}

		var mainPath = Path.join([namespaceDir, "Main.hx"]);
		if (!FileSystem.exists(mainPath)) {
			File.saveContent(mainPath, generateMainHx(haxeNamespace, options));
		}

		// 4. Create build.hxml if it doesn't exist
		var buildHxmlPath = Path.join([projectPath, "build.hxml"]);
		if (!FileSystem.exists(buildHxmlPath)) {
			var buildContent = generateBuildHxml(options);
			File.saveContent(buildHxmlPath, buildContent);
		}

		ensureHaxeTestScaffold(projectPath, options);

		// 5. Update package.json to include Haxe dependencies
		var packagePath = Path.join([projectPath, "package.json"]);
		if (!FileSystem.exists(packagePath)) {
			var packageContent = generatePackageJson(options.name);
			File.saveContent(packagePath, packageContent);
		}

		// Phoenix/LiveView scaffolding is applied after dependencies are installed (so the generated
		// project can run the canonical Mix task: `mix haxe.phoenix.scaffold`).
	}

	function addToExistingProject(options:GeneratorOptions):Void {
		var projectPath = options.workingDir;
		var haxeNamespace = toSnakeCase(options.name) + "_hx";
		var outputDir = 'lib/${haxeNamespace}';

		Sys.println("Adding Reflaxe.Elixir to existing project...");

		// Check if it's an Elixir project
		if (!FileSystem.exists(Path.join([projectPath, "mix.exs"]))) {
			throw "Not an Elixir project (mix.exs not found)";
		}

		// Create src_haxe directory
		var srcHaxePath = Path.join([projectPath, "src_haxe"]);
		if (!FileSystem.exists(srcHaxePath)) {
			FileSystem.createDirectory(srcHaxePath);
			if (options.verbose) {
				Sys.println('Created src_haxe/ directory');
			}
		}

		// Ensure mix.exs has the dependency + compiler integration
		var mixPath = Path.join([projectPath, "mix.exs"]);
		if (FileSystem.exists(mixPath)) {
			var mixContent = File.getContent(mixPath);
			mixContent = ensureReflaxeElixirDependency(mixContent);
			mixContent = ensureHaxeCompilerConfigured(mixContent, "src_haxe", outputDir);
			mixContent = ensureHaxeTestAliases(mixContent);
			File.saveContent(mixPath, mixContent);
		}

		// Create isolated namespace entrypoint
		var namespaceDir = Path.join([srcHaxePath, haxeNamespace]);
		if (!FileSystem.exists(namespaceDir)) {
			createDirectoryRecursive(namespaceDir);
		}

		var mainPath = Path.join([namespaceDir, "Main.hx"]);
		if (!FileSystem.exists(mainPath)) {
			File.saveContent(mainPath, generateMainHx(haxeNamespace, options));
		}

		// Create build.hxml
		var buildHxml = Path.join([projectPath, "build.hxml"]);
		if (!FileSystem.exists(buildHxml)) {
			var content = generateBuildHxml(options);
			File.saveContent(buildHxml, content);
			if (options.verbose) {
				Sys.println('Created build.hxml');
			}
		}

		ensureHaxeTestScaffold(projectPath, options);

		// Create package.json if it doesn't exist
		var packageJson = Path.join([projectPath, "package.json"]);
		if (!FileSystem.exists(packageJson)) {
			var content = generatePackageJson(options.name);
			File.saveContent(packageJson, content);
			if (options.verbose) {
				Sys.println('Created package.json');
			}
		}

		// Ensure .haxerc exists for lix-managed toolchain
		var haxercPath = Path.join([projectPath, ".haxerc"]);
		if (!FileSystem.exists(haxercPath)) {
			File.saveContent(haxercPath, '{\n  "version": "4.3.7",\n  "resolveLibs": "scoped"\n}\n');
		}

		// Always regenerate AGENTS.md + CLAUDE.md from the same template (kept in sync).
		var agentPath = Path.join([projectPath, "AGENTS.md"]);
		var claudePath = Path.join([projectPath, "CLAUDE.md"]);
		var content = generateClaudeInstructions(options);
		File.saveContent(agentPath, content);
		File.saveContent(claudePath, content);
		if (options.verbose) {
			Sys.println('Created AGENTS.md + CLAUDE.md with AI development instructions');
		}

		Sys.println("");
		Sys.println("✅ Updated mix.exs with :haxe compiler + reflaxe_elixir dependency");
		Sys.println("");
	}

	function createProjectFiles(projectPath:String, options:GeneratorOptions):Void {
		// Always regenerate README.md from template to ensure correct project name
		var readmePath = Path.join([projectPath, "README.md"]);
		var content = generateReadme(options);
		File.saveContent(readmePath, content);

		// Create .gitignore if it doesn't exist
		var gitignorePath = Path.join([projectPath, ".gitignore"]);
		if (!FileSystem.exists(gitignorePath)) {
			var content = generateGitignore();
			File.saveContent(gitignorePath, content);
		}

		// Always regenerate AGENTS.md + CLAUDE.md from the same template (kept in sync).
		var agentPath = Path.join([projectPath, "AGENTS.md"]);
		var claudePath = Path.join([projectPath, "CLAUDE.md"]);
		var content = generateClaudeInstructions(options);
		File.saveContent(agentPath, content);
		File.saveContent(claudePath, content);
		if (options.verbose) {
			Sys.println('Created AGENTS.md + CLAUDE.md with AI development instructions');
		}

		// Ensure .haxerc exists for lix-managed toolchain
		var haxercPath = Path.join([projectPath, ".haxerc"]);
		if (!FileSystem.exists(haxercPath)) {
			File.saveContent(haxercPath, '{\n  "version": "4.3.7",\n  "resolveLibs": "scoped"\n}\n');
		}

		// Create LLM documentation directory structure
		createLLMDocumentation(projectPath, options);

		// Ensure build.hxml exists
		var buildHxmlPath = Path.join([projectPath, "build.hxml"]);
		if (!FileSystem.exists(buildHxmlPath)) {
			var content = generateBuildHxml(options);
			File.saveContent(buildHxmlPath, content);
		}

		// Ensure package.json exists
		var packageJsonPath = Path.join([projectPath, "package.json"]);
		if (!FileSystem.exists(packageJsonPath)) {
			var content = generatePackageJson(options.name);
			File.saveContent(packageJsonPath, content);
		}
	}

	function createVSCodeConfig(projectPath:String):Void {
		var vscodePath = Path.join([projectPath, ".vscode"]);
		if (!FileSystem.exists(vscodePath)) {
			FileSystem.createDirectory(vscodePath);
		}

		// Create settings.json
		var settingsPath = Path.join([vscodePath, "settings.json"]);
		if (!FileSystem.exists(settingsPath)) {
			var content = generateVSCodeSettings();
			File.saveContent(settingsPath, content);
		}

		// Create extensions.json
		var extensionsPath = Path.join([vscodePath, "extensions.json"]);
		if (!FileSystem.exists(extensionsPath)) {
			var content = generateVSCodeExtensions();
			File.saveContent(extensionsPath, content);
		}

		// Create launch.json
		var launchPath = Path.join([vscodePath, "launch.json"]);
		if (!FileSystem.exists(launchPath)) {
			var content = generateVSCodeLaunch();
			File.saveContent(launchPath, content);
		}
	}

	function installDependencies(options:GeneratorOptions):Void {
		var projectPath = options.type == "add-to-existing" ? options.workingDir : Path.join([options.workingDir, options.name]);

		Sys.println("");
		Sys.println("📦 Installing dependencies...");

		// Change to project directory
		var originalCwd = Sys.getCwd();
		Sys.setCwd(projectPath);

		try {
			// Install npm dependencies
			Sys.println("  Installing Haxe dependencies...");
			Sys.command("npm", ["install"]);

			// Ensure the project has a local lix scope so `lix install` doesn't fall back to global scope.
			if (!FileSystem.exists(".haxelib")) {
				Sys.println("  Creating lix scope...");
				Sys.command("npx", ["lix", "scope", "create"]);
			}

			// Install Reflaxe.Elixir as a Haxe library in this project (via lix)
			var haxeLibVersion = "v" + readLibraryVersion();
			Sys.println('  Installing Haxe library: reflaxe.elixir#${haxeLibVersion} ...');
			Sys.command("npx", ["lix", "install", 'github:fullofcaffeine/reflaxe.elixir#${haxeLibVersion}']);
			Sys.command("npx", ["lix", "download"]);

			// Install Mix dependencies
			if (FileSystem.exists("mix.exs")) {
				Sys.println("  Installing Elixir dependencies...");
				Sys.command("mix", ["deps.get"]);

				// Phoenix apps typically require assets setup after deps are fetched.
				// Run it opportunistically when available.
				if (FileSystem.exists("assets") && FileSystem.exists(Path.join(["assets", "package.json"]))) {
					Sys.println("  Installing Phoenix assets...");
					Sys.command("mix", ["assets.setup"]);
				}

				// Phoenix/LiveView: apply the canonical Phoenix client scaffold via Mix tooling.
				if (options.type == "phoenix" || options.type == "liveview") {
					Sys.println("  Applying Phoenix client scaffold...");
					var args = ["haxe.phoenix.scaffold", "--client-mode", phoenixClientMode(options), "--yes"];
					if (options.verbose) {
						args.push("--verbose");
					}
					var rc = Sys.command("mix", args);
					if (rc != 0) {
						throw 'Failed to apply Phoenix client scaffold (exit $rc).';
					}
				}
			}

			Sys.println("  ✅ Dependencies installed");
		} catch (e:haxe.Exception) {
			Sys.println("  ⚠️  Failed to install dependencies: " + e);
			Sys.println("  Please run 'npm install' and 'mix deps.get' manually");
		}

		// Restore original directory
		Sys.setCwd(originalCwd);
	}

	function getLibraryPath():String {
		// Try to find the library path
		// First check if we're running from the source directory
		if (FileSystem.exists("haxelib.json") && FileSystem.exists("src/Run.hx")) {
			return Sys.getCwd();
		}

		// Check if we're in a subdirectory of the library
		var currentPath = Sys.getCwd();
		while (currentPath != "/" && currentPath.length > 3) {
			if (FileSystem.exists(Path.join([currentPath, "haxelib.json"]))) {
				var content = File.getContent(Path.join([currentPath, "haxelib.json"]));
				if (content.indexOf('"reflaxe.elixir"') >= 0) {
					return currentPath;
				}
			}
			currentPath = Path.directory(currentPath);
		}

		// Fall back to assuming we're installed via haxelib/lix
		// The library should be in a parent directory
		var runPath = Sys.programPath();
		var libPath = Path.directory(Path.directory(runPath));
		return libPath;
	}

	// Helper functions for generating files

	function generateBuildHxml(options:GeneratorOptions):String {
		var haxeNamespace = toSnakeCase(options.name) + "_hx";
		var appName = toPascalCase(options.name);
		var outputDir = 'lib/${haxeNamespace}';
		var phoenixFlags = options.type == "phoenix" || options.type == "liveview" ? "-D hxx_string_to_sigil\n" : "";

		return '# Reflaxe.Elixir Build Configuration
# Generated by reflaxe.elixir (ProjectGenerator)
#
# Notes
# - `-lib reflaxe.elixir` loads the compiler + bootstrap macro via haxe_libraries/reflaxe.elixir.hxml.

# Libraries
-lib reflaxe.elixir

# Source directories
-cp src_haxe

# Output directory for generated .ex files
-D elixir_output=${outputDir}

# Required for Reflaxe targets
-D reflaxe_runtime

# Elixir is not a UTF-16 platform
-D no-utf16

# Application module prefix
-D app_name=${appName}

# Enable dead code elimination to remove unused functions and reduce output noise
-dce full

${phoenixFlags}--main ${haxeNamespace}.Main
';
	}

	function getLibraryVersionTag():String {
		try {
			var libPath = getLibraryPath();
			var haxelibPath = Path.join([libPath, "haxelib.json"]);
			if (FileSystem.exists(haxelibPath)) {
				var parsed:{version:String} = cast haxe.Json.parse(File.getContent(haxelibPath));
				var version = parsed.version;
				if (version != null && version != "") {
					return "v" + version;
				}
			}
		} catch (e:haxe.Exception) {}

		return "latest";
	}

	function generatePackageJson(projectName:String):String {
		var name = projectName.toLowerCase().split(" ").join("-");
		var tag = getLibraryVersionTag();
		return '{
  "name": "$name",
  "version": "0.1.0",
  "description": "A Reflaxe.Elixir project",
  "scripts": {
    "setup:haxe": "npx lix scope create && npx lix install github:fullofcaffeine/reflaxe.elixir#$tag && npx lix download",
    "compile": "haxe build.hxml",
    "watch": "nodemon --watch src_haxe --ext hx --exec \\"haxe build.hxml\\"",
    "test": "mix test"
  },
  "devDependencies": {
    "lix": "^15.12.4",
    "nodemon": "^3.0.0"
  }
}
';
	}

	// Keep the old methods for backward compatibility but mark as deprecated
	function generateReadmeOld(options:GeneratorOptions):String {
		var title = options.name;
		var description = getProjectDescription(options.type);

		return '# $title

$description

## Getting Started

### Prerequisites

- Haxe 4.3+
- Elixir 1.14+
- Node.js 16+

### Installation

```bash
# Install dependencies
npm install
mix deps.get

# Compile Haxe to Elixir
haxe build.hxml
```

### Development

```bash
# Watch mode (auto-compile on changes)
npm run watch

# Run tests
mix test
```

### Project Structure

```
.
├── src_haxe/          # Haxe source files
├── lib/               # Elixir code
│   └── generated/     # Generated from Haxe
├── test/              # Tests
├── build.hxml         # Haxe build configuration
├── mix.exs            # Elixir project file
└── package.json       # Node dependencies
```

## Learn More

- [Reflaxe.Elixir Documentation](https://github.com/fullofcaffeine/reflaxe.elixir)
- [Haxe Documentation](https://haxe.org)
- [Elixir Documentation](https://elixir-lang.org)
';
		return ""; // Deprecated
	}

	function generateGitignore():String {
		return '# Dependencies
node_modules/
deps/
_build/

# Generated files
lib/generated/

# IDE
.vscode/
.idea/
*.iml

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*

# Environment
.env
.env.local
';
	}

	function generateExampleModule():String {
		return 'package;

/**
 * Example Haxe module
 */
@:module
class HelloWorld {
	public static function greet(person: String): String {
		return \'Hello, \' + person + \' from Haxe!\';
	}
	
	public static function main(): Void {
		var message = greet("World");
	}
}
';
	}

	function generateVSCodeSettings():String {
		return '{
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/node_modules": true,
    "**/_build": true,
    "**/deps": true
  },
  "editor.formatOnSave": true,
  "editor.tabSize": 2,
  "[haxe]": {
    "editor.insertSpaces": false
  },
  "[elixir]": {
    "editor.insertSpaces": true,
    "editor.tabSize": 2
  }
}
';
	}

	function generateVSCodeExtensions():String {
		return '{
  "recommendations": [
    "vshaxe.haxe-extension-pack",
    "jakebecker.elixir-ls",
    "phoenixframework.phoenix",
    "editorconfig.editorconfig",
    "esbenp.prettier-vscode"
  ]
}
';
	}

	function generateVSCodeLaunch():String {
		return '{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "mix_task",
      "name": "mix phx.server",
      "request": "launch",
      "task": "phx.server",
      "projectDir": "$${workspaceRoot}"
    },
    {
      "type": "mix_task",
      "name": "mix test",
      "request": "launch",
      "task": "test",
      "projectDir": "$${workspaceRoot}"
    }
  ]
}
';
	}

	function createLLMDocumentation(projectPath:String, options:GeneratorOptions):Void {
		// Create .taskmaster/docs structure for LLM documentation
		var taskmasterPath = Path.join([projectPath, ".taskmaster"]);
		var docsPath = Path.join([taskmasterPath, "docs"]);
		var llmPath = Path.join([docsPath, "llm"]);

		if (!FileSystem.exists(taskmasterPath)) {
			FileSystem.createDirectory(taskmasterPath);
		}
		if (!FileSystem.exists(docsPath)) {
			FileSystem.createDirectory(docsPath);
		}
		if (!FileSystem.exists(llmPath)) {
			FileSystem.createDirectory(llmPath);
		}

		// Copy foundation documentation from library
		var libPath = getLibraryPath();
		var sourceLLMPath = Path.join([libPath, "docs", "10-contributing", "llm-integration"]);

		if (FileSystem.exists(sourceLLMPath)) {
			// Copy foundation docs
			var foundationFiles = ["HAXE_FUNDAMENTALS.md", "REFLAXE_ELIXIR_BASICS.md", "QUICK_START_PATTERNS.md"];

			for (file in foundationFiles) {
				var srcFile = Path.join([sourceLLMPath, file]);
				var destFile = Path.join([llmPath, file]);
				if (FileSystem.exists(srcFile) && !FileSystem.exists(destFile)) {
					File.copy(srcFile, destFile);
					if (options.verbose) {
						Sys.println('  Copied LLM documentation: $file');
					}
				}
			}
		}

		// Create API reference skeleton
		var apiRefPath = Path.join([llmPath, "API_REFERENCE_SKELETON.md"]);
		if (!FileSystem.exists(apiRefPath)) {
			var content = generateAPIReferenceSkeleton(options);
			File.saveContent(apiRefPath, content);
			if (options.verbose) {
				Sys.println('  Created API_REFERENCE_SKELETON.md');
			}
		}

		// Create patterns directory
		var patternsPath = Path.join([docsPath, "patterns"]);
		if (!FileSystem.exists(patternsPath)) {
			FileSystem.createDirectory(patternsPath);
		}

		// Create empty PATTERNS.md that will be populated when code is written
		var patternsFile = Path.join([patternsPath, "PATTERNS.md"]);
		if (!FileSystem.exists(patternsFile)) {
			var content = generateEmptyPatternsFile(options);
			File.saveContent(patternsFile, content);
			if (options.verbose) {
				Sys.println('  Created PATTERNS.md (will be populated as you code)');
			}
		}

		// Create template-specific documentation
		var templateDocPath = Path.join([llmPath, "PROJECT_SPECIFICS.md"]);
		if (!FileSystem.exists(templateDocPath)) {
			var content = generateTemplateSpecificDocs(options);
			File.saveContent(templateDocPath, content);
			if (options.verbose) {
				Sys.println('  Created PROJECT_SPECIFICS.md for ${options.type} template');
			}
		}
	}

	// Deprecated old inline methods - kept for backward compatibility
	function generateAPIReferenceSkeletonOld(options:GeneratorOptions):String {
		return ""; // Deprecated
	}

	function generateEmptyPatternsFileOld(options:GeneratorOptions):String {
		return ""; // Deprecated
	}

	function generateTemplateSpecificDocsOld(options:GeneratorOptions):String {
		return ""; // Deprecated
	}

	function loadTemplate(templateName:String):String {
		var libPath = getLibraryPath();
		var templatePath = Path.join([libPath, "templates", "project", templateName]);

		if (!FileSystem.exists(templatePath)) {
			// Fall back to embedded defaults when running from a minimal distribution.
			return defaultTemplate(templateName);
		}

		return File.getContent(templatePath);
	}

	function defaultTemplate(templateName:String):String {
		return switch (templateName) {
			case "readme.md.tpl":
				'# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Quick Start

```bash
npm install
npm run setup:haxe
mix deps.get
mix compile
```

### Compile Haxe → Elixir
```bash
npm run compile
# or: ./node_modules/.bin/haxe build.hxml
```

## Phoenix

If this is a Phoenix project:
```bash
mix phx.server
```
';

			case "claude.md.tpl":
				'# AI/Agent Development Context for {{PROJECT_NAME}}

> **⚠️ SYNC DIRECTIVE**: `AGENTS.md` and `CLAUDE.md` must be kept in sync. When updating either file, update the other as well.

This project uses Reflaxe.Elixir (Haxe → Elixir) for type-safe BEAM development.

## Day-to-day commands

```bash
# Compile once (Haxe -> Elixir)
npm run compile

# Watch + recompile on changes (recommended during development)
mix haxe.watch

# Run Elixir tests
mix test
```

## Phoenix projects

```bash
# Start the Phoenix dev server (uses config/dev.exs watchers)
mix phx.server

# If you need to wire the client JS build (Genes + esbuild watch safety):
mix haxe.phoenix.scaffold
```

`mix haxe.phoenix.scaffold` is strict by default (fail-fast). For heavily customized Phoenix templates, use:

```bash
mix haxe.phoenix.scaffold --warn-only
```

## Frontend/UI Work (Required)

	- When making changes to frontend/UI/UX (HTML/CSS/JS, LiveView templates, hooks, layouts), use the `$$frontend-design` skill to keep output production-grade and intentional.

## HXX Raw HEEx Policy (Required)

	- Avoid embedding raw EEx/HEEx blocks (`<% ... %>`, `<%= ... %>`) inside `hxx("...")` / `HXX.hxx("...")` templates.
- Use HXX constructs (`#{...}` text interpolation, `<if>` / `<for>` control tags) and typed assigns instead.
- Escape hatch (avoid): add `@:allow_heex` to the enclosing function/class, or compile with `-D hxx_allow_raw_heex`.

## Source-of-truth rule

- Do not patch generated `.ex` files to change behavior. Fix the Haxe source (`src_haxe/**`) or the compiler/stdlib upstream instead.
';

			case "api_reference.md.tpl":
				'# API Reference Skeleton

This file is a starting point for documenting your public modules.
';

			case "patterns.md.tpl":
				'# Patterns

This file can be used to record stable patterns discovered in the codebase.
';

			case "project_specifics.md.tpl":
				'# Project Specifics

Describe decisions and conventions unique to this project.
';

			default:
				"";
		}
	}

	function processTemplate(templateName:String, context:TemplateContext):String {
		var template = loadTemplate(templateName);
		var engine = new TemplateEngine();
		return engine.processContent(template, context);
	}

	function generateClaudeInstructions(options:GeneratorOptions):String {
		var context = createTemplateContext(options);
		return processTemplate("claude.md.tpl", context);
	}

	function generateReadme(options:GeneratorOptions):String {
		var context = createTemplateContext(options);
		return processTemplate("readme.md.tpl", context);
	}

	function generateAPIReferenceSkeleton(options:GeneratorOptions):String {
		var context = createTemplateContext(options);
		context.set("BUILD_CONFIG", VString(generateBuildHxml(options)));
		return processTemplate("api_reference.md.tpl", context);
	}

	function generateEmptyPatternsFile(options:GeneratorOptions):String {
		var context = createTemplateContext(options);
		return processTemplate("patterns.md.tpl", context);
	}

	function generateTemplateSpecificDocs(options:GeneratorOptions):String {
		var context = createTemplateContext(options);
		return processTemplate("project_specifics.md.tpl", context);
	}

	function createTemplateContext(options:GeneratorOptions):TemplateContext {
		var projectName = options.name;
		var projectType = options.type;

		var projectNameSnake = projectName.toLowerCase().replace(" ", "_").replace("-", "_");
		var projectModule = toPascalCase(projectName);

		// Determine project type flags
		var isPhoenix = projectType == "phoenix";
		var isLiveView = projectType == "liveview";
		var isBasic = projectType == "basic" || projectType == "add-to-existing";

		// Create template context map
		var context = TemplateContext.empty();
		context.set("PROJECT_NAME", VString(projectName));
		context.set("PROJECT_NAME_SNAKE", VString(projectNameSnake));
		context.set("PROJECT_MODULE", VString(projectModule));
		context.set("PROJECT_TYPE", VString(projectType));
		context.set("PROJECT_TYPE_DISPLAY", VString(getProjectTypeDisplay(projectType)));
		context.set("PROJECT_DESCRIPTION", VString(getProjectDescription(projectType)));
		context.set("GENERATED_DATE", VString(Date.now().toString()));
		context.set("YEAR", VString(Std.string(Date.now().getFullYear())));

		// Boolean flags for conditionals
		context.set("IS_PHOENIX", VBool(isPhoenix));
		context.set("IS_LIVEVIEW", VBool(isLiveView || isPhoenix)); // Phoenix includes LiveView
		context.set("IS_BASIC", VBool(isBasic));
		context.set("HAS_ECTO", VBool(isPhoenix || isLiveView));
		context.set("HAS_PATTERNS", VBool(false)); // Will be true after first extraction

		return context;
	}

	function getProjectTypeDisplay(type:String):String {
		return switch (type) {
			case "phoenix": "Phoenix Web Application";
			case "liveview": "Phoenix LiveView Application";
			case "basic": "Mix Project";
			case "add-to-existing": "Existing Elixir Project with Haxe";
			default: "Reflaxe.Elixir Project";
		};
	}

	function getProjectDescription(type:String):String {
		return switch (type) {
			case "phoenix": "A Phoenix web application built with Reflaxe.Elixir";
			case "liveview": "A Phoenix LiveView application built with Reflaxe.Elixir";
			case "basic": "A Mix project built with Reflaxe.Elixir";
			default: "A Reflaxe.Elixir project";
		};
	}

	// Remove the old inline template generation methods
	function generateOldClaudeInstructions(options:GeneratorOptions):String {
		var projectName = options.name;
		var projectType = options.type;

		var baseInstructions = '# AI Development Instructions for $projectName

This file contains instructions for AI assistants (Claude, ChatGPT, etc.) working on this Reflaxe.Elixir project.

## 📋 Project Overview

- **Project**: $projectName
- **Type**: $projectType
- **Framework**: Reflaxe.Elixir (Haxe → Elixir compilation)
- **Architecture**: Compile-time transpiler with file watching

## 🚀 Quick Start for AI Development

### 1. Start File Watcher
```bash
# Start the watcher for real-time compilation
mix compile.haxe --watch

# You\'ll see:
[10:30:45] Starting HaxeWatcher...
[10:30:45] Watching directories: ["src_haxe"]
[10:30:45] Ready for changes. Press Ctrl+C to stop.
```

### 2. Development Workflow
1. Edit .hx files in `src_haxe/`
2. Save file → Automatic compilation in ~100-200ms
3. Generated .ex files appear in `lib/generated/`
4. Test changes immediately - no manual compilation needed!

## ⚡ File Watching Benefits

- **Sub-second compilation**: 0.1-0.3s per file change (10-50x faster than cold compilation)
- **Immediate error feedback**: See compilation errors instantly
- **Source mapping**: Errors show Haxe source positions, not generated Elixir
- **Continuous validation**: Code always compiles before you move on

';

		// Add project-type specific instructions
		switch (projectType) {
			case "phoenix" | "liveview":
				baseInstructions += '## 🌐 Phoenix Development

### Start Development Server
```bash
# This starts Phoenix + HaxeWatcher + LiveReload all together
iex -S mix phx.server

# Visit http://localhost:4000
# Browser auto-refreshes when you edit .hx files!
```

### Development Flow
1. Edit .hx files → HaxeWatcher compiles to .ex
2. Phoenix detects .ex changes → Recompiles to BEAM  
3. LiveReload refreshes browser → See changes instantly!

### Phoenix-Specific Configuration
```elixir
# config/dev.exs - Watcher integration
config :$projectName, ${toPascalCase(projectName)}Web.Endpoint,
  watchers: [
    haxe: ["mix", "compile.haxe", "--watch", cd: Path.expand("../", __DIR__)]
  ],
  live_reload: [
    patterns: [
      ~r"lib/generated/.*(ex)$$"  # Watch generated Elixir files
    ]
  ]
```

';
			case "basic":
				baseInstructions += '## 🔧 Mix Project Development

### Development Commands
```bash
# Terminal 1: Start watcher
mix compile.haxe --watch

# Terminal 2: Run your application
iex -S mix

# Or run specific modules
mix run -e "MyModule.main()"
```

';
			default:
				// Add-to-existing or other types get basic instructions
		}

		baseInstructions += '## 🗺️ Source Mapping & Debugging

### Enable Source Mapping
Add to your `build.hxml`:
```hxml
-D source-map  # Enable source mapping for debugging
```

### Use Source Maps for Debugging
```bash
# Map Elixir error back to Haxe source
mix haxe.source_map lib/MyModule.ex 45 12
# Output: src_haxe/MyModule.hx:23:15

# Check compilation errors with source positions
mix haxe.errors --format json

# Get structured compilation status
mix haxe.status --format json
```

## 📁 Project Structure

```
$projectName/
├── src_haxe/              # 🎯 Edit Haxe files here
│   ├── Main.hx            # Entry point
│   └── utils/             # Utility modules
├── lib/                   
│   └── generated/         # ⚡ Auto-generated Elixir code
├── build.hxml             # Haxe build configuration  
├── mix.exs                # Elixir project configuration
└── AGENTS.md              # This file
```

## ✅ Best Practices

### 1. Always Use File Watcher
- **Start watcher first**: `mix compile.haxe --watch`
- **Keep it running**: One terminal dedicated to watching
- **Check feedback**: Watch for compilation success/errors

### 2. Source Mapping for Error Fixes
- **Use precise positions**: Source maps show exact Haxe line/column
- **Query error locations**: `mix haxe.source_map <file> <line> <col>`
- **Fix at source**: Edit Haxe files, not generated Elixir

### 3. Rapid Development Loop
1. Edit .hx file and save
2. Watch compilation result (~200ms)
3. Test changes immediately
4. Fix errors using source positions
5. Repeat for fast iteration

## 🔧 Troubleshooting

### Watcher Not Starting
```bash
# Check if port 6000 is in use
lsof -i :6000

# Use different port if needed
mix compile.haxe --watch --port 6001

# Reset watcher state
rm -rf .haxe_cache && mix compile.haxe --watch --force
```

### Changes Not Detected
```bash
# Verify files are in watched directories
mix haxe.status

# Check if src_haxe/ contains .hx files
ls src_haxe/**/*.hx
```

### Compilation Errors
```bash
# Get detailed error information
mix haxe.errors --format json

# Check source mapping
mix haxe.source_map <generated_file> <line> <column>
```

## 📚 LLM-Optimized Documentation

This project includes comprehensive documentation specifically designed for AI assistants:

### Foundation Documentation (in .taskmaster/docs/llm/)
- **HAXE_FUNDAMENTALS.md** - Essential Haxe language knowledge
- **REFLAXE_ELIXIR_BASICS.md** - Core Reflaxe.Elixir concepts and patterns
- **QUICK_START_PATTERNS.md** - Copy-paste ready code patterns
- **PROJECT_SPECIFICS.md** - Template-specific guidance for this project
- **API_REFERENCE_SKELETON.md** - API documentation (grows as you code)

### Pattern Extraction (in .taskmaster/docs/patterns/)
- **PATTERNS.md** - Auto-extracted patterns from your code

### Generating Enhanced Documentation
```bash
# Generate full API documentation
haxe build.hxml -D generate-llm-docs

# Extract patterns from your code
haxe build.hxml -D extract-patterns
```

## 📚 Additional Resources

- [Watcher Development Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/docs/06-guides/WATCHER_DEVELOPMENT_GUIDE.md)
- [Source Mapping Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/docs/04-api-reference/SOURCE_MAPPING.md)
- [Getting Started Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/docs/01-getting-started/installation.md)

---

**Remember**: The watcher provides sub-second compilation perfect for AI-assisted development. Always start with `mix compile.haxe --watch` for the best experience!
';

		return baseInstructions;
	}

	// Utility functions

	function isTextFile(filename:String):Bool {
		var textExtensions = [
			".hx",
			".ex",
			".exs",
			".eex",
			".heex",
			".hxx",
			".md",
			".txt",
			".json",
			".xml",
			".hxml",
			".yml",
			".yaml",
			".toml",
			".ini",
			".conf",
			".gitignore",
			".editorconfig"
		];

		for (ext in textExtensions) {
			if (filename.endsWith(ext)) {
				return true;
			}
		}

		// Check for files without extensions
		var noExtFiles = ["README", "LICENSE", "Makefile", "Dockerfile"];
		return noExtFiles.contains(filename);
	}

	function toPascalCase(str:String):String {
		var words = ~/[-_\s]+/g.split(str);
		return words.map(function(word) {
			if (word.length == 0)
				return "";
			return word.charAt(0).toUpperCase() + word.substr(1).toLowerCase();
		}).join("");
	}

	function toSnakeCase(str:String):String {
		var cleaned = str.toLowerCase();
		cleaned = ~/[^a-z0-9]+/g.replace(cleaned, "_");
		cleaned = ~/_{2,}/g.replace(cleaned, "_");
		cleaned = cleaned.trim();
		if (cleaned.startsWith("_"))
			cleaned = cleaned.substr(1);
		if (cleaned.endsWith("_"))
			cleaned = cleaned.substr(0, cleaned.length - 1);
		return cleaned;
	}

	function generateMainHx(haxeNamespace:String, options:GeneratorOptions):String {
		var elixirNamespace = toPascalCase(options.name) + "Hx";
		return 'package ${haxeNamespace};

/**
 * Minimal entrypoint for Haxe→Elixir compilation.
 *
 * This module exists primarily to give the Haxe compiler a stable `--main`.
 * Add your application modules under `${haxeNamespace}.*` and call them from Elixir as `${elixirNamespace}.*`.
 */
@:native("${elixirNamespace}.Main")
@:module
class Main {
  public static function main(): Void {}
}
';
	}

	function ensureReflaxeElixirDependency(mixContent:String):String {
		if (mixContent.indexOf("{:reflaxe_elixir") >= 0)
			return mixContent;

		var version = "v" + readLibraryVersion();
		var depLine = '      {:reflaxe_elixir, github: \"fullofcaffeine/reflaxe.elixir\", tag: \"${version}\", runtime: false},';

		// Insert just after the deps list opening bracket, preserving existing indentation.
		var depsPattern = ~/defp deps do\s*\[/m;
		if (depsPattern.match(mixContent)) {
			var pos = depsPattern.matchedPos();
			var insertAt = pos.pos + pos.len;
			return mixContent.substr(0, insertAt) + "\n" + depLine + mixContent.substr(insertAt);
		}

		return mixContent;
	}

	function ensureHaxeCompilerConfigured(mixContent:String, sourceDir:String, targetDir:String):String {
		// Reuse existing conservative compiler insertion logic.
		if (mixContent.indexOf("compilers: [:haxe]") == -1 && mixContent.indexOf("[:haxe") == -1) {
			var compilerPattern = ~/compilers:\s*\[([^\]]*)\]/;
			if (compilerPattern.match(mixContent)) {
				var existingCompilers = compilerPattern.matched(1);
				var newCompilers = existingCompilers.length > 0 ? ':haxe, $existingCompilers' : ':haxe';
				mixContent = compilerPattern.replace(mixContent, 'compilers: [$newCompilers]');
			} else {
				var projectPattern = ~/def project do\s*\[/;
				if (projectPattern.match(mixContent)) {
					mixContent = projectPattern.replace(mixContent, 'def project do\n    [\n      compilers: [:haxe] ++ Mix.compilers(),');
				}
			}
		}

		// Add `haxe:` config block if missing.
		if (mixContent.indexOf("\n      haxe: [") == -1
			&& mixContent.indexOf("\n    haxe: [") == -1
			&& mixContent.indexOf("haxe: [") == -1) {
			// Match the full `compilers:` entry including any commas inside list literals.
			var compilersLinePattern = ~/compilers:\s*([^\n]+),/m;
			if (compilersLinePattern.match(mixContent)) {
				var matched = compilersLinePattern.matched(0);
				mixContent = compilersLinePattern.replace(mixContent,
					matched
					+ '\n      haxe: [hxml_file: \"build.hxml\", source_dir: \"'
					+ sourceDir
					+ '\", target_dir: \"'
					+ targetDir
					+ '\", watch: Mix.env() == :dev],');
			}
		}

		return mixContent;
	}

	function ensureHaxeTestAliases(mixContent:String):String {
		var updated = mixContent;

		if (~/"haxe\.compile\.tests"\s*:/m.match(updated) == false) {
			updated = insertAliasEntry(updated, '"haxe.compile.tests": ["cmd haxe build-tests.hxml"],');
		}

		if (~/"test"\s*:/m.match(updated) == false) {
			updated = insertAliasEntry(updated, '"test": ["haxe.compile.tests", "test"],');
		}

		return updated;
	}

	function insertAliasEntry(mixContent:String, aliasEntry:String):String {
		var defpAliases = ~/defp aliases do\s*\[/m;
		var defAliases = ~/def aliases do\s*\[/m;
		var insertAt:Null<Int> = null;

		if (defpAliases.match(mixContent)) {
			var pos = defpAliases.matchedPos();
			insertAt = pos.pos + pos.len;
		} else if (defAliases.match(mixContent)) {
			var pos = defAliases.matchedPos();
			insertAt = pos.pos + pos.len;
		}

		if (insertAt == null) {
			return mixContent;
		}

		return mixContent.substr(0, insertAt) + "\n        " + aliasEntry + "\n" + mixContent.substr(insertAt);
	}

	function ensureHaxeTestScaffold(projectPath:String, options:GeneratorOptions):Void {
		var testHaxeDir = Path.join([projectPath, "test_haxe"]);
		if (!FileSystem.exists(testHaxeDir)) {
			FileSystem.createDirectory(testHaxeDir);
		}

		var testGeneratedDir = Path.join([projectPath, "test", "generated"]);
		createDirectoryRecursive(testGeneratedDir);

		var buildTestsPath = Path.join([projectPath, "build-tests.hxml"]);
		if (!FileSystem.exists(buildTestsPath)) {
			File.saveContent(buildTestsPath, generateBuildTestsHxml(options));
		}

		var testHelperPath = Path.join([projectPath, "test", "test_helper.exs"]);
		var testHelperContent = FileSystem.exists(testHelperPath) ? File.getContent(testHelperPath) : "ExUnit.start()\n";
		var patchedTestHelper = patchTestHelperExs(testHelperContent);
		File.saveContent(testHelperPath, patchedTestHelper);
	}

	function generateBuildTestsHxml(options:GeneratorOptions):String {
		var appName = toPascalCase(options.name);
		var phoenixFlags = "";

		return '# Reflaxe.Elixir ExUnit Test Build Configuration
# Generated by reflaxe.elixir (ProjectGenerator)
#
# Notes
# - Compile Haxe-authored ExUnit modules to test/generated/**/*.exs.
# - test/test_helper.exs requires these files before ExUnit discovery.

# Libraries
-lib reflaxe.elixir

# Source directories
-cp src_haxe
-cp test_haxe

# Output test modules as .exs so ExUnit can require them directly
-D elixir_output=test/generated
-D elixir_output_exs

# Required for Reflaxe targets
-D reflaxe_runtime

# Enable ExUnit test codegen
-D exunit

# Application module prefix
-D app_name=${appName}

${phoenixFlags}# Enable dead code elimination to remove unused functions and reduce output noise
-dce full

# Add test modules to compile (one per line), for example:
# ${toSnakeCase(options.name)}_hx.tests.ExampleTest
';
	}

	function patchTestHelperExs(content:String):String {
		var beginMarker = "# BEGIN reflaxe_elixir haxe_exunit_require";
		var endMarker = "# END reflaxe_elixir haxe_exunit_require";
		var block = '\n${beginMarker}
# Require Haxe-compiled ExUnit scripts generated by `haxe build-tests.hxml`.
for file <- Path.wildcard("test/generated/**/*_test.exs") do
  Code.require_file(file)
end
${endMarker}
';

		if (content.indexOf(beginMarker) >= 0 && content.indexOf(endMarker) >= 0) {
			var start = content.indexOf(beginMarker);
			var end = content.indexOf(endMarker);
			var endLine = content.indexOf("\n", end);
			if (endLine == -1)
				endLine = content.length;
			return content.substr(0, start) + block + content.substr(endLine);
		}

		if (content.indexOf("Path.wildcard(\"test/generated/**/*_test.exs\")") >= 0 && content.indexOf("Code.require_file(") >= 0) {
			return content;
		}

		var trimmed = StringTools.rtrim(content);
		return trimmed + "\n" + block;
	}

	function readLibraryVersion():String {
		try {
			var libPath = getLibraryPath();
			var content = File.getContent(Path.join([libPath, "haxelib.json"]));
			var parsed = haxe.Json.parse(content);
			var version:Null<String> = Reflect.field(parsed, "version");
			if (version != null && version != "")
				return version;
		} catch (_:haxe.Exception) {}

		return "1.0.0";
	}

	function phoenixClientMode(options:GeneratorOptions):String {
		var mode = options.clientMode;
		if (mode == null || mode == "") {
			return "genes";
		}
		var normalized = mode.toLowerCase();
		return switch (normalized) {
			case "genes": "genes";
			case "plain-js", "plain_js": "plain-js";
			default: "genes";
		};
	}
}

typedef GeneratorOptions = {
	name:String,
	type:String,
	?clientMode:String,
	skipInstall:Bool,
	verbose:Bool,
	vscode:Bool,
	workingDir:String
}
