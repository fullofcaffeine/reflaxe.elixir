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
			Sys.println('Creating project directory: $projectPath');
		}
		
		// Create project directory
		FileSystem.createDirectory(projectPath);
		
		// Copy template files
		copyTemplate(templatePath, projectPath, options);
		
		// Create additional files
		createProjectFiles(projectPath, options);
		
		// Add VS Code configuration if requested
		if (options.vscode) {
			createVSCodeConfig(projectPath);
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
		
		// Create CLAUDE.md with AI development instructions
		var claudePath = Path.join([projectPath, "CLAUDE.md"]);
		if (!FileSystem.exists(claudePath)) {
			var content = generateClaudeInstructions(options);
			File.saveContent(claudePath, content);
			if (options.verbose) {
				Sys.println('Created CLAUDE.md with AI development instructions');
			}
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
		// Create README.md if it doesn't exist
		var readmePath = Path.join([projectPath, "README.md"]);
		if (!FileSystem.exists(readmePath)) {
			var content = generateReadme(options);
			File.saveContent(readmePath, content);
		}
		
		// Create .gitignore if it doesn't exist
		var gitignorePath = Path.join([projectPath, ".gitignore"]);
		if (!FileSystem.exists(gitignorePath)) {
			var content = generateGitignore();
			File.saveContent(gitignorePath, content);
		}
		
		// Create CLAUDE.md with AI development instructions
		var claudePath = Path.join([projectPath, "CLAUDE.md"]);
		if (!FileSystem.exists(claudePath)) {
			var content = generateClaudeInstructions(options);
			File.saveContent(claudePath, content);
			if (options.verbose) {
				Sys.println('Created CLAUDE.md with AI development instructions');
			}
		}
		
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
	
	function generateReadme(options: GeneratorOptions): String {
		var title = options.name;
		var description = switch (options.type) {
			case "phoenix": "A Phoenix web application built with Reflaxe.Elixir";
			case "liveview": "A Phoenix LiveView application built with Reflaxe.Elixir";
			case "basic": "A Mix project built with Reflaxe.Elixir";
			default: "A Reflaxe.Elixir project";
		};
		
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
	
	function generateClaudeInstructions(options: GeneratorOptions): String {
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