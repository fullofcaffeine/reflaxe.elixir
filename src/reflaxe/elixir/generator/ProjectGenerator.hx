package reflaxe.elixir.generator;

import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import reflaxe.elixir.generator.TemplateEngine;
using StringTools;

/**
 * Core project generator for Reflaxe.Elixir
 * Handles creation of new projects from templates
 */
class ProjectGenerator {
	
	// Template paths relative to library root
	static final TEMPLATE_PATHS = [
		"basic" => "examples/02-mix-project",
		"phoenix" => "examples/03-phoenix-app", 
		"liveview" => "examples/06-user-management",
		"add-to-existing" => null // Special case - adds to current directory
	];
	
	public function new() {}
	
	public function generate(options: GeneratorOptions): Void {
		// Validate project doesn't already exist (unless add-to-existing)
		if (options.type != "add-to-existing") {
			var projectPath = Path.join([options.workingDir, options.name]);
			if (FileSystem.exists(projectPath)) {
				throw 'Directory already exists: $projectPath';
			}
		}
		
		// Get template path
		var templatePath = getTemplatePath(options.type);
		
		// Generate based on type
		switch (options.type) {
			case "add-to-existing":
				addToExistingProject(options);
			default:
				if (templatePath == null) {
					throw 'Invalid project type: ${options.type}';
				}
				createNewProject(options, templatePath);
		}
		
		// Install dependencies if needed
		if (!options.skipInstall) {
			installDependencies(options);
		}
	}
	
	function createNewProject(options: GeneratorOptions, templatePath: String): Void {
		var projectPath = Path.join([options.workingDir, options.name]);
		
		if (options.verbose) {
			Sys.println('Creating project using Mix generator...');
		}
		
		// Use Mix generators to create proper project structure
		var mixCommand = switch (options.type) {
			case "basic":
				'mix new ${options.name} --module ${toPascalCase(options.name)}';
			case "phoenix":
				'mix phx.new ${options.name} --module ${toPascalCase(options.name)} --no-ecto --no-html --no-gettext --no-dashboard';
			case "liveview":
				'mix phx.new ${options.name} --module ${toPascalCase(options.name)} --live --no-dashboard';
			default:
				null;
		}
		
		if (mixCommand != null) {
			// Change to working directory and run Mix generator
			var originalDir = Sys.getCwd();
			Sys.setCwd(options.workingDir);
			
			if (options.verbose) {
				Sys.println('Running: $mixCommand');
			}
			
			// Run Mix generator (add --install flag to auto-install deps)
			var installFlag = options.skipInstall ? "" : " --install";
			var result = Sys.command(mixCommand + installFlag);
			if (result != 0) {
				Sys.setCwd(originalDir);
				// If Mix generator fails, fallback to template copying
				Sys.println("Mix generator not available, using template fallback...");
				FileSystem.createDirectory(projectPath);
				copyTemplate(templatePath, projectPath, options);
			}
			
			Sys.setCwd(originalDir);
		} else {
			// Fallback to template copying for unknown types
			FileSystem.createDirectory(projectPath);
			copyTemplate(templatePath, projectPath, options);
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
	
	function addHaxeIntegration(projectPath: String, options: GeneratorOptions): Void {
		// 1. Update mix.exs to include :haxe compiler
		var mixPath = Path.join([projectPath, "mix.exs"]);
		if (FileSystem.exists(mixPath)) {
			var mixContent = File.getContent(mixPath);
			
			// Add :haxe to compilers list if not already there
			if (mixContent.indexOf("compilers: [:haxe]") == -1 && mixContent.indexOf("[:haxe") == -1) {
				// Find the compilers line and add :haxe
				var compilerPattern = ~/compilers:\s*\[([^\]]*)\]/;
				if (compilerPattern.match(mixContent)) {
					var existingCompilers = compilerPattern.matched(1);
					var newCompilers = existingCompilers.length > 0 ? ':haxe, $existingCompilers' : ':haxe';
					mixContent = compilerPattern.replace(mixContent, 'compilers: [$newCompilers]');
				} else {
					// No compilers line found, add it to project config
					var projectPattern = ~/def project do\s*\[/;
					if (projectPattern.match(mixContent)) {
						mixContent = projectPattern.replace(mixContent, 'def project do\n    [\n      compilers: [:haxe] ++ Mix.compilers(),');
					}
				}
				
				File.saveContent(mixPath, mixContent);
			}
		}
		
		// 2. Create src_haxe directory if it doesn't exist
		var srcHaxePath = Path.join([projectPath, "src_haxe"]);
		if (!FileSystem.exists(srcHaxePath)) {
			FileSystem.createDirectory(srcHaxePath);
		}
		
		// 3. Copy Mix.Tasks.Compile.Haxe to the project
		var mixTaskDir = Path.join([projectPath, "lib", "mix", "tasks"]);
		if (!FileSystem.exists(mixTaskDir)) {
			createDirectoryRecursive(mixTaskDir);
		}
		
		var compileTaskPath = Path.join([mixTaskDir, "compile.haxe.ex"]);
		if (!FileSystem.exists(compileTaskPath)) {
			// Copy from our lib directory
			var sourceTaskPath = "lib/mix/tasks/compile.haxe.ex";
			if (FileSystem.exists(sourceTaskPath)) {
				File.copy(sourceTaskPath, compileTaskPath);
			}
		}
		
		// 4. Create build.hxml if it doesn't exist
		var buildHxmlPath = Path.join([projectPath, "build.hxml"]);
		if (!FileSystem.exists(buildHxmlPath)) {
			var buildContent = generateBuildHxml(options.name);
			File.saveContent(buildHxmlPath, buildContent);
		}
		
		// 5. Update package.json to include Haxe dependencies
		var packagePath = Path.join([projectPath, "package.json"]);
		if (!FileSystem.exists(packagePath)) {
			var packageContent = generatePackageJson(options.name);
			File.saveContent(packagePath, packageContent);
		}
	}
	
	function addToExistingProject(options: GeneratorOptions): Void {
		var projectPath = options.workingDir;
		
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
		
		// Create build.hxml
		var buildHxml = Path.join([projectPath, "build.hxml"]);
		if (!FileSystem.exists(buildHxml)) {
			var content = generateBuildHxml(options.name);
			File.saveContent(buildHxml, content);
			if (options.verbose) {
				Sys.println('Created build.hxml');
			}
		}
		
		// Create package.json if it doesn't exist
		var packageJson = Path.join([projectPath, "package.json"]);
		if (!FileSystem.exists(packageJson)) {
			var content = generatePackageJson(options.name);
			File.saveContent(packageJson, content);
			if (options.verbose) {
				Sys.println('Created package.json');
			}
		}
		
		// Create example Haxe module
		var exampleModule = Path.join([srcHaxePath, "HelloWorld.hx"]);
		if (!FileSystem.exists(exampleModule)) {
			var content = generateExampleModule();
			File.saveContent(exampleModule, content);
			if (options.verbose) {
				Sys.println('Created example module: HelloWorld.hx');
			}
		}
		
		// Always regenerate CLAUDE.md from template to ensure correct project name
		var claudePath = Path.join([projectPath, "CLAUDE.md"]);
		var content = generateClaudeInstructions(options);
		File.saveContent(claudePath, content);
		if (options.verbose) {
			Sys.println('Created CLAUDE.md with AI development instructions');
		}
		
		// Update mix.exs compiler configuration
		Sys.println("");
		Sys.println("⚠️  Please update your mix.exs file:");
		Sys.println('  Add :haxe to the compilers list:');
		Sys.println('    compilers: [:haxe] ++ Mix.compilers()');
		Sys.println("");
	}
	
	function copyTemplate(templatePath: String, destPath: String, options: GeneratorOptions): Void {
		if (!FileSystem.exists(templatePath)) {
			throw 'Template not found: $templatePath';
		}
		
		var engine = new TemplateEngine();
		var replacements = {
			"__PROJECT_NAME__": options.name,
			"__PROJECT_MODULE__": toPascalCase(options.name),
			"__PROJECT_VERSION__": "0.1.0",
			"__YEAR__": Std.string(Date.now().getFullYear())
		};
		
		copyDirectory(templatePath, destPath, engine, replacements, options.verbose);
	}
	
	function copyDirectory(src: String, dest: String, engine: TemplateEngine, replacements: Dynamic, verbose: Bool): Void {
		for (item in FileSystem.readDirectory(src)) {
			// Skip hidden files and directories
			if (item.startsWith(".")) continue;
			
			// Skip template configuration files
			if (item == ".template.json") continue;
			
			var srcPath = Path.join([src, item]);
			var destPath = Path.join([dest, item]);
			
			if (FileSystem.isDirectory(srcPath)) {
				// Recursively copy directories
				if (!FileSystem.exists(destPath)) {
					FileSystem.createDirectory(destPath);
				}
				copyDirectory(srcPath, destPath, engine, replacements, verbose);
			} else {
				// Process and copy files
				if (verbose) {
					Sys.println('  Copying: $item');
				}
				
				// Check if it's a text file that needs processing
				if (isTextFile(item)) {
					var content = File.getContent(srcPath);
					content = engine.processContent(content, replacements);
					File.saveContent(destPath, content);
				} else {
					// Copy binary files as-is
					File.copy(srcPath, destPath);
				}
			}
		}
	}
	
	function createProjectFiles(projectPath: String, options: GeneratorOptions): Void {
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
		
		// Always regenerate CLAUDE.md from template to ensure correct project name
		var claudePath = Path.join([projectPath, "CLAUDE.md"]);
		var content = generateClaudeInstructions(options);
		File.saveContent(claudePath, content);
		if (options.verbose) {
			Sys.println('Created CLAUDE.md with AI development instructions');
		}
		
		// Create LLM documentation directory structure
		createLLMDocumentation(projectPath, options);
		
		// Ensure build.hxml exists
		var buildHxmlPath = Path.join([projectPath, "build.hxml"]);
		if (!FileSystem.exists(buildHxmlPath)) {
			var content = generateBuildHxml(options.name);
			File.saveContent(buildHxmlPath, content);
		}
		
		// Ensure package.json exists
		var packageJsonPath = Path.join([projectPath, "package.json"]);
		if (!FileSystem.exists(packageJsonPath)) {
			var content = generatePackageJson(options.name);
			File.saveContent(packageJsonPath, content);
		}
	}
	
	function createVSCodeConfig(projectPath: String): Void {
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
	
	function installDependencies(options: GeneratorOptions): Void {
		var projectPath = options.type == "add-to-existing" 
			? options.workingDir 
			: Path.join([options.workingDir, options.name]);
		
		Sys.println("");
		Sys.println("📦 Installing dependencies...");
		
		// Change to project directory
		var originalCwd = Sys.getCwd();
		Sys.setCwd(projectPath);
		
		try {
			// Install npm dependencies
			Sys.println("  Installing Haxe dependencies...");
			Sys.command("npm", ["install"]);
			
			// Install Mix dependencies
			if (FileSystem.exists("mix.exs")) {
				Sys.println("  Installing Elixir dependencies...");
				Sys.command("mix", ["deps.get"]);
			}
			
			Sys.println("  ✅ Dependencies installed");
		} catch (e: Dynamic) {
			Sys.println("  ⚠️  Failed to install dependencies: " + e);
			Sys.println("  Please run 'npm install' and 'mix deps.get' manually");
		}
		
		// Restore original directory
		Sys.setCwd(originalCwd);
	}
	
	function getTemplatePath(type: String): Null<String> {
		// Get the library path (where haxelib/lix installed reflaxe.elixir)
		var libPath = getLibraryPath();
		
		var relativePath = TEMPLATE_PATHS.get(type);
		if (relativePath == null) {
			return null;
		}
		
		return Path.join([libPath, relativePath]);
	}
	
	function getLibraryPath(): String {
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
	
	function generateBuildHxml(projectName: String): String {
		return '-cp src_haxe
-lib reflaxe.elixir
-D reflaxe.output=lib/generated
-D reflaxe_runtime
--main Main
';
	}
	
	function generatePackageJson(projectName: String): String {
		var name = projectName.toLowerCase().split(" ").join("-");
		return '{
  "name": "$name",
  "version": "0.1.0",
  "description": "A Reflaxe.Elixir project",
  "scripts": {
    "compile": "npx haxe build.hxml",
    "watch": "npx nodemon --watch src_haxe --ext hx --exec \\"npx haxe build.hxml\\"",
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
	function generateReadmeOld(options: GeneratorOptions): String {
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
npx haxe build.hxml
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
	
	function generateGitignore(): String {
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
	
	function generateExampleModule(): String {
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
		trace(message);
	}
}
';
	}
	
	function generateVSCodeSettings(): String {
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
	
	function generateVSCodeExtensions(): String {
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
	
	function generateVSCodeLaunch(): String {
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
	
	function createLLMDocumentation(projectPath: String, options: GeneratorOptions): Void {
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
		var sourceLLMPath = Path.join([libPath, "documentation", "llm"]);
		
		if (FileSystem.exists(sourceLLMPath)) {
			// Copy foundation docs
			var foundationFiles = [
				"HAXE_FUNDAMENTALS.md",
				"REFLAXE_ELIXIR_BASICS.md",
				"QUICK_START_PATTERNS.md"
			];
			
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
	function generateAPIReferenceSkeletonOld(options: GeneratorOptions): String {
		return ""; // Deprecated
	}
	
	function generateEmptyPatternsFileOld(options: GeneratorOptions): String {
		return ""; // Deprecated
	}
	
	function generateTemplateSpecificDocsOld(options: GeneratorOptions): String {
		return ""; // Deprecated
	}
	
	function loadTemplate(templateName: String): String {
		var libPath = getLibraryPath();
		var templatePath = Path.join([libPath, "templates", "project", templateName]);
		
		if (!FileSystem.exists(templatePath)) {
			// Fall back to embedded default if template file missing
			throw 'Template not found: $templatePath';
		}
		
		return File.getContent(templatePath);
	}
	
	function processTemplate(templateName: String, context: Dynamic): String {
		var template = loadTemplate(templateName);
		var engine = new TemplateEngine();
		return engine.processContent(template, context);
	}
	
	function generateClaudeInstructions(options: GeneratorOptions): String {
		var context = createTemplateContext(options);
		return processTemplate("claude.md.tpl", context);
	}
	
	function generateReadme(options: GeneratorOptions): String {
		var context = createTemplateContext(options);
		return processTemplate("readme.md.tpl", context);
	}
	
	function generateAPIReferenceSkeleton(options: GeneratorOptions): String {
		var context = createTemplateContext(options);
		context.BUILD_CONFIG = generateBuildHxml(options.name);
		return processTemplate("api_reference.md.tpl", context);
	}
	
	function generateEmptyPatternsFile(options: GeneratorOptions): String {
		var context = createTemplateContext(options);
		return processTemplate("patterns.md.tpl", context);
	}
	
	function generateTemplateSpecificDocs(options: GeneratorOptions): String {
		var context = createTemplateContext(options);
		return processTemplate("project_specifics.md.tpl", context);
	}
	
	function createTemplateContext(options: GeneratorOptions): Dynamic {
		var projectName = options.name;
		var projectType = options.type;
		
		var projectNameSnake = projectName.toLowerCase().replace(" ", "_").replace("-", "_");
		var projectModule = toPascalCase(projectName);
		
		// Determine project type flags
		var isPhoenix = projectType == "phoenix";
		var isLiveView = projectType == "liveview";
		var isBasic = projectType == "basic" || projectType == "add-to-existing";
		
		// Create template context object
		return {
			PROJECT_NAME: projectName,
			PROJECT_NAME_SNAKE: projectNameSnake,
			PROJECT_MODULE: projectModule,
			PROJECT_TYPE: projectType,
			PROJECT_TYPE_DISPLAY: getProjectTypeDisplay(projectType),
			PROJECT_DESCRIPTION: getProjectDescription(projectType),
			GENERATED_DATE: Date.now().toString(),
			YEAR: Std.string(Date.now().getFullYear()),
			
			// Boolean flags for conditionals
			IS_PHOENIX: isPhoenix,
			IS_LIVEVIEW: isLiveView || isPhoenix, // Phoenix includes LiveView
			IS_BASIC: isBasic,
			HAS_ECTO: isPhoenix || isLiveView,
			HAS_PATTERNS: false // Will be true after first extraction
		};
	}
	
	function getProjectTypeDisplay(type: String): String {
		return switch(type) {
			case "phoenix": "Phoenix Web Application";
			case "liveview": "Phoenix LiveView Application";
			case "basic": "Mix Project";
			case "add-to-existing": "Existing Elixir Project with Haxe";
			default: "Reflaxe.Elixir Project";
		};
	}
	
	function getProjectDescription(type: String): String {
		return switch(type) {
			case "phoenix": "A Phoenix web application built with Reflaxe.Elixir";
			case "liveview": "A Phoenix LiveView application built with Reflaxe.Elixir";
			case "basic": "A Mix project built with Reflaxe.Elixir";
			default: "A Reflaxe.Elixir project";
		};
	}
	
	// Remove the old inline template generation methods
	function generateOldClaudeInstructions(options: GeneratorOptions): String {
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
└── CLAUDE.md              # This file
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
npx haxe build.hxml -D generate-llm-docs

# Extract patterns from your code
npx haxe build.hxml -D extract-patterns
```

## 📚 Additional Resources

- [Watcher Development Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/documentation/guides/WATCHER_DEVELOPMENT_GUIDE.md)
- [Source Mapping Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/documentation/SOURCE_MAPPING.md)
- [Getting Started Guide](https://github.com/fullofcaffeine/reflaxe.elixir/blob/main/documentation/guides/GETTING_STARTED.md)

---

**Remember**: The watcher provides sub-second compilation perfect for AI-assisted development. Always start with `mix compile.haxe --watch` for the best experience!
';

		return baseInstructions;
	}
	
	// Utility functions
	
	function isTextFile(filename: String): Bool {
		var textExtensions = [
			".hx", ".ex", ".exs", ".eex", ".heex", ".hxx",
			".md", ".txt", ".json", ".xml", ".hxml",
			".yml", ".yaml", ".toml", ".ini", ".conf",
			".gitignore", ".editorconfig"
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
	
	function toPascalCase(str: String): String {
		var words = ~/[-_\s]+/g.split(str);
		return words.map(function(word) {
			if (word.length == 0) return "";
			return word.charAt(0).toUpperCase() + word.substr(1).toLowerCase();
		}).join("");
	}
}

typedef GeneratorOptions = {
	name: String,
	type: String,
	skipInstall: Bool,
	verbose: Bool,
	vscode: Bool,
	workingDir: String
}