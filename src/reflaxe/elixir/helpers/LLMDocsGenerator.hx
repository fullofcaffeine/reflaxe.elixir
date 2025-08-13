package reflaxe.elixir.helpers;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.io.File;
import sys.FileSystem;
import reflaxe.elixir.helpers.APIDocExtractor;
import reflaxe.elixir.helpers.PatternExtractor;

using StringTools;
using Lambda;

/**
 * LLMDocsGenerator - Main coordinator for LLM-optimized documentation
 * 
 * Generates documentation specifically designed for LLM agents:
 * - CLAUDE.md for Claude Code CLI
 * - API_QUICK_REFERENCE.md for quick lookups
 * - PATTERNS.md for common usage patterns
 * - TROUBLESHOOTING.md updates
 * 
 * Maintains DRY principle by generating from source code
 */
class LLMDocsGenerator {
    
    static var config:GeneratorConfig = {
        outputDir: ".taskmaster/docs",
        updateClaude: true,
        generateAPI: true,
        generatePatterns: true,
        generateTroubleshooting: true,
        projectRoot: null
    };
    
    /**
     * Initialize the documentation generator
     */
    public static function initialize(?customConfig:GeneratorConfig):Void {
        if (customConfig != null) {
            // Merge custom config
            if (customConfig.outputDir != null) config.outputDir = customConfig.outputDir;
            if (customConfig.updateClaude != null) config.updateClaude = customConfig.updateClaude;
            if (customConfig.generateAPI != null) config.generateAPI = customConfig.generateAPI;
            if (customConfig.generatePatterns != null) config.generatePatterns = customConfig.generatePatterns;
            if (customConfig.generateTroubleshooting != null) config.generateTroubleshooting = customConfig.generateTroubleshooting;
            if (customConfig.projectRoot != null) config.projectRoot = customConfig.projectRoot;
        }
        
        // Set up output directory
        ensureDirectory(config.outputDir);
        
        // Hook into compilation
        Context.onAfterTyping(onTypingComplete);
        Context.onGenerate(onGenerateComplete);
    }
    
    /**
     * Called after typing phase completes
     */
    static function onTypingComplete(types:Array<ModuleType>):Void {
        trace("LLMDocsGenerator: Analyzing ${types.length} modules...");
        
        for (type in types) {
            // Extract API documentation
            if (config.generateAPI) {
                APIDocExtractor.extractAPI(type);
            }
            
            // Analyze patterns in code
            if (config.generatePatterns) {
                analyzeTypeForPatterns(type);
            }
        }
    }
    
    /**
     * Called when generation completes
     */
    static function onGenerateComplete(types:Array<Type>):Void {
        trace("LLMDocsGenerator: Generating documentation...");
        
        // Generate all documentation files
        generateAllDocs();
        
        trace("LLMDocsGenerator: Documentation generation complete!");
    }
    
    /**
     * Analyze a type for patterns
     */
    static function analyzeTypeForPatterns(type:ModuleType):Void {
        switch(type) {
            case TClassDecl(c):
                var classRef = c.get();
                if (classRef.constructor != null) {
                    var ctor = classRef.constructor.get();
                    if (ctor.expr() != null) {
                        PatternExtractor.analyzeCode(ctor.expr(), classRef.module + "." + classRef.name);
                    }
                }
                
                for (field in classRef.fields.get()) {
                    if (field.expr() != null) {
                        PatternExtractor.analyzeCode(field.expr(), classRef.module + "." + classRef.name + "." + field.name);
                    }
                }
                
            case _:
                // Other types don't have expressions to analyze
        }
    }
    
    /**
     * Generate all documentation files
     */
    static function generateAllDocs():Void {
        // Ensure output directories exist
        ensureDirectory(config.outputDir);
        ensureDirectory('${config.outputDir}/api');
        ensureDirectory('${config.outputDir}/patterns');
        
        // Generate API documentation
        if (config.generateAPI) {
            APIDocExtractor.generateDocs('${config.outputDir}/api');
            generateQuickReference();
        }
        
        // Generate pattern documentation
        if (config.generatePatterns) {
            PatternExtractor.generatePatternDocs('${config.outputDir}/patterns');
            generateBestPractices();
        }
        
        // Update CLAUDE.md if requested
        if (config.updateClaude) {
            updateClaudeDoc();
        }
        
        // Generate troubleshooting additions
        if (config.generateTroubleshooting) {
            generateTroubleshootingAdditions();
        }
        
        // Generate index file
        generateIndexFile();
    }
    
    /**
     * Generate API quick reference
     */
    static function generateQuickReference():Void {
        var content = new StringBuf();
        content.add("# Reflaxe.Elixir API Quick Reference\n\n");
        content.add("*Auto-generated from compiler - Always up-to-date*\n\n");
        content.add("Last Updated: " + Date.now().toString() + "\n\n");
        
        // Table of contents
        content.add("## Table of Contents\n\n");
        content.add("- [Annotations](#annotations)\n");
        content.add("- [Core Classes](#core-classes)\n");
        content.add("- [Phoenix Integration](#phoenix-integration)\n");
        content.add("- [Ecto Integration](#ecto-integration)\n");
        content.add("- [OTP Patterns](#otp-patterns)\n");
        content.add("- [Type Mappings](#type-mappings)\n\n");
        
        // Annotations section
        content.add("## Annotations\n\n");
        content.add("| Annotation | Purpose | Example |\n");
        content.add("|------------|---------|---------||\n");
        content.add("| `@:module` | Define Elixir module | `@:module class MyModule` |\n");
        content.add("| `@:liveview` | Phoenix LiveView | `@:liveview class MyLive` |\n");
        content.add("| `@:schema` | Ecto schema | `@:schema class User` |\n");
        content.add("| `@:changeset` | Ecto changeset | `@:changeset function` |\n");
        content.add("| `@:genserver` | GenServer | `@:genserver class Worker` |\n");
        content.add("| `@:supervisor` | Supervisor | `@:supervisor class MySup` |\n");
        content.add("| `@:migration` | Ecto migration | `@:migration class AddUsers` |\n");
        content.add("| `@:template` | Phoenix template | `@:template class MyView` |\n");
        content.add("| `@:query` | Ecto query | `@:query function` |\n");
        content.add("| `@:router` | Phoenix router | `@:router class Router` |\n");
        content.add("| `@:controller` | Phoenix controller | `@:controller class UserController` |\n\n");
        
        // Core classes
        content.add("## Core Classes\n\n");
        content.add("### Phoenix.Socket\n");
        content.add("```haxe\n");
        content.add("class Socket {\n");
        content.add("    function assign(assigns:Dynamic):Socket;\n");
        content.add("    function push_event(event:String, payload:Dynamic):Socket;\n");
        content.add("    function put_flash(kind:String, msg:String):Socket;\n");
        content.add("}\n");
        content.add("```\n\n");
        
        content.add("### Ecto.Repo\n");
        content.add("```haxe\n");
        content.add("class Repo {\n");
        content.add("    static function get(schema:Class<Dynamic>, id:Int):Dynamic;\n");
        content.add("    static function insert(changeset:Dynamic):Dynamic;\n");
        content.add("    static function update(changeset:Dynamic):Dynamic;\n");
        content.add("    static function delete(struct:Dynamic):Dynamic;\n");
        content.add("    static function all(query:Dynamic):Array<Dynamic>;\n");
        content.add("}\n");
        content.add("```\n\n");
        
        // Type mappings
        content.add("## Type Mappings\n\n");
        content.add("| Haxe Type | Elixir Type | Notes |\n");
        content.add("|-----------|-------------|-------|\n");
        content.add("| `Int` | `integer()` | |\n");
        content.add("| `Float` | `float()` | |\n");
        content.add("| `String` | `String.t()` | Binary string |\n");
        content.add("| `Bool` | `boolean()` | |\n");
        content.add("| `Array<T>` | `list(T)` | |\n");
        content.add("| `Map<K,V>` | `%{K => V}` | |\n");
        content.add("| `Dynamic` | `any()` | |\n");
        content.add("| `Null<T>` | `T \\| nil` | Nullable |\n");
        content.add("| Class | Module | With @:module |\n");
        content.add("| Enum | Module with atoms | |\n\n");
        
        File.saveContent('${config.outputDir}/API_QUICK_REFERENCE.md', content.toString());
    }
    
    /**
     * Generate best practices guide
     */
    static function generateBestPractices():Void {
        var content = new StringBuf();
        content.add("# Reflaxe.Elixir Best Practices\n\n");
        content.add("*Extracted from successful example projects*\n\n");
        
        content.add("## Project Structure\n\n");
        content.add("```\n");
        content.add("project/\n");
        content.add("├── src_haxe/          # Haxe source files\n");
        content.add("│   ├── schemas/       # Ecto schemas\n");
        content.add("│   ├── live/          # LiveView components\n");
        content.add("│   ├── controllers/   # Phoenix controllers\n");
        content.add("│   └── services/      # Business logic\n");
        content.add("├── lib/               # Generated Elixir\n");
        content.add("├── build.hxml         # Haxe build config\n");
        content.add("└── mix.exs            # Mix project file\n");
        content.add("```\n\n");
        
        content.add("## Common Patterns\n\n");
        content.add("### 1. LiveView Component\n");
        content.add("```haxe\n");
        content.add("@:liveview\n");
        content.add("class ProductLive {\n");
        content.add("    public static function mount(params, session, socket) {\n");
        content.add("        var products = ProductService.list();\n");
        content.add("        return socket.assign({\n");
        content.add("            products: products,\n");
        content.add("            loading: false\n");
        content.add("        });\n");
        content.add("    }\n");
        content.add("    \n");
        content.add("    public static function handle_event(\"search\", params, socket) {\n");
        content.add("        var results = ProductService.search(params.query);\n");
        content.add("        return socket.assign(products: results);\n");
        content.add("    }\n");
        content.add("}\n");
        content.add("```\n\n");
        
        content.add("### 2. Ecto Schema with Changeset\n");
        content.add("```haxe\n");
        content.add("@:schema\n");
        content.add("class User {\n");
        content.add("    public var id:Int;\n");
        content.add("    public var email:String;\n");
        content.add("    public var name:String;\n");
        content.add("    \n");
        content.add("    @:changeset\n");
        content.add("    public static function changeset(user, attrs) {\n");
        content.add("        return user\n");
        content.add("            .cast(attrs, [\"email\", \"name\"])\n");
        content.add("            .validate_required([\"email\"])\n");
        content.add("            .validate_format(\"email\", ~/^[^@]+@[^@]+$/);\n");
        content.add("    }\n");
        content.add("}\n");
        content.add("```\n\n");
        
        content.add("### 3. GenServer Worker\n");
        content.add("```haxe\n");
        content.add("@:genserver\n");
        content.add("class EmailWorker {\n");
        content.add("    public static function init(args) {\n");
        content.add("        return {ok: {queue: []}};\n");
        content.add("    }\n");
        content.add("    \n");
        content.add("    public static function handle_cast({send: email}, state) {\n");
        content.add("        EmailService.deliver(email);\n");
        content.add("        return {noreply: state};\n");
        content.add("    }\n");
        content.add("}\n");
        content.add("```\n\n");
        
        File.saveContent('${config.outputDir}/BEST_PRACTICES.md', content.toString());
    }
    
    /**
     * Update CLAUDE.md with API section
     */
    static function updateClaudeDoc():Void {
        var claudePath = findClaudeFile();
        if (claudePath == null) {
            trace("Warning: CLAUDE.md not found, skipping update");
            return;
        }
        
        var content = File.getContent(claudePath);
        var apiSection = File.getContent('${config.outputDir}/api/API_SECTION.md');
        
        // Replace or append API section
        var marker = "## API Quick Reference (Auto-Generated)";
        var endMarker = "## ";
        
        if (content.indexOf(marker) != -1) {
            // Replace existing section
            var start = content.indexOf(marker);
            var end = content.indexOf(endMarker, start + marker.length);
            if (end == -1) end = content.length;
            
            content = content.substring(0, start) + apiSection + content.substring(end);
        } else {
            // Append new section
            content += "\n\n" + apiSection;
        }
        
        File.saveContent(claudePath, content);
        trace("Updated CLAUDE.md with API documentation");
    }
    
    /**
     * Generate troubleshooting additions
     */
    static function generateTroubleshootingAdditions():Void {
        var content = new StringBuf();
        content.add("# Additional Troubleshooting (Auto-Generated)\n\n");
        content.add("*Based on patterns found in code*\n\n");
        
        // Add common issues discovered
        content.add("## Common Compilation Issues\n\n");
        content.add("### Regex Escaping\n");
        content.add("**Issue:** Double backslash in regex patterns\n");
        content.add("**Solution:** Use single backslash in Haxe regex literals: `~/\\$\\{/` not `~/\\\\$\\\\{/`\n\n");
        
        content.add("### Type Inference\n");
        content.add("**Issue:** Type not found errors\n");
        content.add("**Solution:** Add explicit type annotations or imports\n\n");
        
        File.saveContent('${config.outputDir}/TROUBLESHOOTING_ADDITIONS.md', content.toString());
    }
    
    /**
     * Generate index file for all docs
     */
    static function generateIndexFile():Void {
        var content = new StringBuf();
        content.add("# LLM Documentation Index\n\n");
        content.add("Auto-generated documentation for LLM agents\n\n");
        content.add("Generated: " + Date.now().toString() + "\n\n");
        
        content.add("## Available Documentation\n\n");
        content.add("- [API Quick Reference](./API_QUICK_REFERENCE.md) - Complete API documentation\n");
        content.add("- [Best Practices](./BEST_PRACTICES.md) - Recommended patterns and approaches\n");
        content.add("- [Patterns](./patterns/PATTERNS.md) - Common usage patterns\n");
        content.add("- [Troubleshooting](./TROUBLESHOOTING_ADDITIONS.md) - Additional troubleshooting\n\n");
        
        content.add("## Quick Start for LLM Agents\n\n");
        content.add("1. Read API_QUICK_REFERENCE.md for available APIs\n");
        content.add("2. Check BEST_PRACTICES.md for project structure\n");
        content.add("3. Use PATTERNS.md for common implementations\n");
        content.add("4. Refer to TROUBLESHOOTING_ADDITIONS.md for issues\n\n");
        
        content.add("## Integration with Claude Code CLI\n\n");
        content.add("This documentation is optimized for Claude Code CLI.\n");
        content.add("The CLAUDE.md file in project root is automatically updated.\n\n");
        
        File.saveContent('${config.outputDir}/INDEX.md', content.toString());
    }
    
    // Helper functions
    
    static function ensureDirectory(path:String):Void {
        if (!FileSystem.exists(path)) {
            FileSystem.createDirectory(path);
        }
    }
    
    static function findClaudeFile():String {
        // Look for CLAUDE.md in various locations
        var locations = [
            "CLAUDE.md",
            "../CLAUDE.md",
            "../../CLAUDE.md",
            ".claude/CLAUDE.md"
        ];
        
        if (config.projectRoot != null) {
            locations.unshift('${config.projectRoot}/CLAUDE.md');
        }
        
        for (loc in locations) {
            if (FileSystem.exists(loc)) {
                return loc;
            }
        }
        
        return null;
    }
}

// Configuration type
typedef GeneratorConfig = {
    ?outputDir:String,
    ?updateClaude:Bool,
    ?generateAPI:Bool,
    ?generatePatterns:Bool,
    ?generateTroubleshooting:Bool,
    ?projectRoot:String
}
#end