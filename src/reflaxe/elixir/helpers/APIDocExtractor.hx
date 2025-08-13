package reflaxe.elixir.helpers;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.io.File;
import sys.FileSystem;

using StringTools;
using Lambda;

/**
 * APIDocExtractor - Extracts API documentation from compiled code
 * 
 * Generates LLM-optimized documentation automatically from:
 * - Public API signatures
 * - Annotations and their usage
 * - Common patterns in examples
 * - Type mappings
 * 
 * Output format optimized for Claude Code CLI and other LLM agents
 */
class APIDocExtractor {
    
    static var apiData:Map<String, APIEntry> = new Map();
    static var patterns:Array<PatternEntry> = [];
    
    /**
     * Main extraction entry point
     * Called during compilation to gather API information
     */
    public static function extractAPI(module:ModuleType):Void {
        switch(module) {
            case TClassDecl(c):
                var classRef = c.get();
                extractClass(classRef);
                
            case TEnumDecl(e):
                var enumRef = e.get();
                extractEnum(enumRef);
                
            case TTypeDecl(t):
                var typeRef = t.get();
                extractTypedef(typeRef);
                
            case TAbstract(a):
                var abstractRef = a.get();
                extractAbstract(abstractRef);
        }
    }
    
    /**
     * Extract class API information
     */
    static function extractClass(c:ClassType):Void {
        if (!c.isExtern) return; // Only document extern APIs
        
        var entry:APIEntry = {
            name: c.name,
            module: c.module,
            type: "class",
            isExtern: true,
            doc: c.doc,
            meta: extractMeta(c.meta.get()),
            fields: [],
            staticFields: []
        };
        
        // Extract instance fields
        for (field in c.fields.get()) {
            if (field.isPublic) {
                entry.fields.push(extractField(field));
            }
        }
        
        // Extract static fields
        for (field in c.statics.get()) {
            if (field.isPublic) {
                entry.staticFields.push(extractField(field));
            }
        }
        
        apiData.set(c.module + "." + c.name, entry);
    }
    
    /**
     * Extract enum API information
     */
    static function extractEnum(e:EnumType):Void {
        var entry:APIEntry = {
            name: e.name,
            module: e.module,
            type: "enum",
            isExtern: e.isExtern,
            doc: e.doc,
            meta: extractMeta(e.meta.get()),
            constructors: []
        };
        
        for (name in e.names) {
            var ctor = e.constructs.get(name);
            entry.constructors.push({
                name: ctor.name,
                doc: ctor.doc,
                params: switch(ctor.type) {
                    case TFun(args, _): [for (a in args) a.name + ":" + typeToString(a.t)];
                    case _: [];
                }
            });
        }
        
        apiData.set(e.module + "." + e.name, entry);
    }
    
    /**
     * Extract typedef API information
     */
    static function extractTypedef(t:DefType):Void {
        var entry:APIEntry = {
            name: t.name,
            module: t.module,
            type: "typedef",
            isExtern: t.isExtern,
            doc: t.doc,
            meta: extractMeta(t.meta.get()),
            definition: typeToString(t.type)
        };
        
        apiData.set(t.module + "." + t.name, entry);
    }
    
    /**
     * Extract abstract API information
     */
    static function extractAbstract(a:AbstractType):Void {
        var entry:APIEntry = {
            name: a.name,
            module: a.module,
            type: "abstract",
            isExtern: false,
            doc: a.doc,
            meta: extractMeta(a.meta.get()),
            underlying: typeToString(a.type)
        };
        
        apiData.set(a.module + "." + a.name, entry);
    }
    
    /**
     * Extract field information
     */
    static function extractField(field:ClassField):FieldEntry {
        return {
            name: field.name,
            doc: field.doc,
            type: typeToString(field.type),
            isMethod: switch(field.type) {
                case TFun(_, _): true;
                case _: false;
            },
            params: switch(field.type) {
                case TFun(args, ret): {
                    args: [for (a in args) {name: a.name, type: typeToString(a.t), opt: a.opt}],
                    ret: typeToString(ret)
                };
                case _: null;
            }
        };
    }
    
    /**
     * Extract metadata information
     */
    static function extractMeta(meta:Metadata):Array<String> {
        return [for (m in meta) m.name];
    }
    
    /**
     * Convert Type to readable string
     */
    static function typeToString(t:Type):String {
        return switch(t) {
            case TInst(c, _): c.get().name;
            case TEnum(e, _): e.get().name;
            case TType(t, _): t.get().name;
            case TAbstract(a, _): a.get().name;
            case TFun(args, ret): 
                "(" + [for (a in args) a.name + ":" + typeToString(a.t)].join(", ") + ") -> " + typeToString(ret);
            case TAnonymous(a): 
                "{" + [for (f in a.get().fields) f.name + ":" + typeToString(f.type)].join(", ") + "}";
            case TDynamic(_): "Dynamic";
            case TMono(_): "Unknown";
            case TLazy(f): typeToString(f());
        }
    }
    
    /**
     * Generate API documentation files
     */
    public static function generateDocs(outputDir:String):Void {
        if (!FileSystem.exists(outputDir)) {
            FileSystem.createDirectory(outputDir);
        }
        
        // Generate CLAUDE.md API section
        generateClaudeAPI(outputDir);
        
        // Generate API_QUICK_REFERENCE.md
        generateQuickReference(outputDir);
        
        // Generate PATTERNS.md from examples
        generatePatterns(outputDir);
    }
    
    /**
     * Generate CLAUDE.md API section
     */
    static function generateClaudeAPI(outputDir:String):Void {
        var content = new StringBuf();
        content.add("## API Quick Reference (Auto-Generated)\n\n");
        
        // Group by module
        var modules = new Map<String, Array<APIEntry>>();
        for (key in apiData.keys()) {
            var entry = apiData.get(key);
            if (!modules.exists(entry.module)) {
                modules.set(entry.module, []);
            }
            modules.get(entry.module).push(entry);
        }
        
        // Generate content for each module
        for (module in modules.keys()) {
            content.add('### Module: $module\n\n');
            
            var entries = modules.get(module);
            entries.sort((a, b) -> Reflect.compare(a.name, b.name));
            
            for (entry in entries) {
                content.add('#### ${entry.name} (${entry.type})\n');
                if (entry.doc != null) {
                    content.add('${entry.doc}\n');
                }
                
                // Add fields for classes
                if (entry.fields != null && entry.fields.length > 0) {
                    content.add("**Instance Methods:**\n");
                    for (field in entry.fields) {
                        if (field.isMethod) {
                            content.add('- `${field.name}${field.params != null ? formatParams(field.params) : "()"}`\n');
                        }
                    }
                }
                
                if (entry.staticFields != null && entry.staticFields.length > 0) {
                    content.add("**Static Methods:**\n");
                    for (field in entry.staticFields) {
                        if (field.isMethod) {
                            content.add('- `${field.name}${field.params != null ? formatParams(field.params) : "()"}`\n');
                        }
                    }
                }
                
                content.add("\n");
            }
        }
        
        File.saveContent('$outputDir/API_SECTION.md', content.toString());
    }
    
    /**
     * Generate API_QUICK_REFERENCE.md
     */
    static function generateQuickReference(outputDir:String):Void {
        var content = new StringBuf();
        content.add("# API Quick Reference\n\n");
        content.add("*Auto-generated from Reflaxe.Elixir compiler*\n\n");
        
        // Common annotations
        content.add("## Common Annotations\n\n");
        content.add("```haxe\n");
        content.add("@:module         // Define Elixir module\n");
        content.add("@:liveview       // Phoenix LiveView component\n");
        content.add("@:schema         // Ecto schema\n");
        content.add("@:changeset      // Ecto changeset\n");
        content.add("@:genserver      // GenServer behavior\n");
        content.add("@:template       // Phoenix template\n");
        content.add("@:migration      // Ecto migration\n");
        content.add("```\n\n");
        
        // Quick examples
        content.add("## Quick Examples\n\n");
        content.add("### LiveView Component\n");
        content.add("```haxe\n");
        content.add("@:liveview\n");
        content.add("class MyLive {\n");
        content.add("    public static function mount(params, session, socket) {\n");
        content.add("        return socket.assign(counter: 0);\n");
        content.add("    }\n");
        content.add("}\n");
        content.add("```\n\n");
        
        File.saveContent('$outputDir/API_QUICK_REFERENCE.md', content.toString());
    }
    
    /**
     * Generate PATTERNS.md from examples
     */
    static function generatePatterns(outputDir:String):Void {
        var content = new StringBuf();
        content.add("# Common Patterns\n\n");
        content.add("*Auto-extracted from working examples*\n\n");
        
        // Add patterns discovered during compilation
        for (pattern in patterns) {
            content.add('## ${pattern.name}\n\n');
            content.add('${pattern.description}\n\n');
            content.add('```haxe\n${pattern.code}\n```\n\n');
            content.add('**Used in:** ${pattern.examples.join(", ")}\n\n');
        }
        
        File.saveContent('$outputDir/PATTERNS.md', content.toString());
    }
    
    /**
     * Format function parameters for display
     */
    static function formatParams(params:Dynamic):String {
        if (params.args == null) return "()";
        
        var args = [];
        var argsArray:Array<Dynamic> = cast params.args;
        for (arg in argsArray) {
            var s = arg.name + ":" + arg.type;
            if (arg.opt) s = "?" + s;
            args.push(s);
        }
        
        return "(" + args.join(", ") + "):" + params.ret;
    }
    
    /**
     * Register a pattern found in examples
     */
    public static function registerPattern(name:String, description:String, code:String, example:String):Void {
        // Check if pattern exists
        for (p in patterns) {
            if (p.name == name) {
                if (p.examples.indexOf(example) == -1) {
                    p.examples.push(example);
                }
                return;
            }
        }
        
        // Add new pattern
        patterns.push({
            name: name,
            description: description,
            code: code,
            examples: [example]
        });
    }
}

// Type definitions for API documentation
typedef APIEntry = {
    name:String,
    module:String,
    type:String,
    isExtern:Bool,
    ?doc:String,
    ?meta:Array<String>,
    ?fields:Array<FieldEntry>,
    ?staticFields:Array<FieldEntry>,
    ?constructors:Array<{name:String, doc:String, params:Array<String>}>,
    ?definition:String,
    ?underlying:String
}

typedef FieldEntry = {
    name:String,
    ?doc:String,
    type:String,
    isMethod:Bool,
    ?params:Dynamic
}

typedef PatternEntry = {
    name:String,
    description:String,
    code:String,
    examples:Array<String>
}
#end