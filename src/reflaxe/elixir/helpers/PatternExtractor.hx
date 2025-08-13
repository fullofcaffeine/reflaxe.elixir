package reflaxe.elixir.helpers;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import sys.io.File;
import sys.FileSystem;

using StringTools;
using Lambda;

/**
 * PatternExtractor - Extracts common patterns from example code
 * 
 * Analyzes example projects to identify:
 * - Common usage patterns
 * - Best practices
 * - Integration approaches
 * - Anti-patterns to avoid
 * 
 * Feeds into LLM documentation generation
 */
class PatternExtractor {
    
    static var patterns:Map<String, Pattern> = new Map();
    static var antiPatterns:Array<AntiPattern> = [];
    
    /**
     * Analyze code for patterns during compilation
     */
    public static function analyzeCode(expr:TypedExpr, context:String):Void {
        switch(expr.expr) {
            case TCall(e, args):
                analyzeFunctionCall(e, args, context);
                
            case TNew(c, _, args):
                analyzeConstructor(c, args, context);
                
            case TMeta(m, e):
                analyzeMetadata(m, e, context);
                
            case TFunction(f):
                analyzeFunction(f, context);
                
            case _:
                // Continue traversal
        }
        
        // Recursively analyze sub-expressions
        TypedExprTools.iter(expr, function(e) analyzeCode(e, context));
    }
    
    /**
     * Analyze function calls for patterns
     */
    static function analyzeFunctionCall(e:TypedExpr, args:Array<TypedExpr>, context:String):Void {
        switch(e.expr) {
            case TField(_, FStatic(c, cf)):
                var className = c.get().name;
                var methodName = cf.get().name;
                
                // LiveView patterns
                if (className == "Socket" && methodName == "assign") {
                    registerPattern(
                        "socket-assign",
                        "Socket State Management",
                        "Managing state in LiveView components using socket.assign",
                        'socket.assign(${extractArgPattern(args)})',
                        context
                    );
                }
                
                // Ecto patterns
                if (className == "Repo" && methodName == "insert") {
                    registerPattern(
                        "repo-insert",
                        "Database Insert",
                        "Inserting records using Ecto.Repo",
                        'Repo.insert(changeset)',
                        context
                    );
                }
                
            case _:
        }
    }
    
    /**
     * Analyze constructor usage
     */
    static function analyzeConstructor(c:Ref<ClassType>, args:Array<TypedExpr>, context:String):Void {
        // GenServer patterns
        var classRef = c.get();
        if (classRef.meta.has(":genserver")) {
            registerPattern(
                "genserver-init",
                "GenServer Initialization",
                "Starting a GenServer process",
                'new ${classRef.name}(${extractArgPattern(args)})',
                context
            );
        }
    }
    
    /**
     * Analyze metadata usage
     */
    static function analyzeMetadata(m:MetadataEntry, e:TypedExpr, context:String):Void {
        switch(m.name) {
            case ":liveview":
                registerPattern(
                    "liveview-component",
                    "LiveView Component",
                    "Defining Phoenix LiveView components",
                    getLiveViewPattern(e),
                    context
                );
                
            case ":schema":
                registerPattern(
                    "ecto-schema",
                    "Ecto Schema Definition",
                    "Defining database schemas with Ecto",
                    getSchemaPattern(e),
                    context
                );
                
            case ":changeset":
                registerPattern(
                    "ecto-changeset",
                    "Changeset Validation",
                    "Validating data with Ecto changesets",
                    getChangesetPattern(e),
                    context
                );
        }
    }
    
    /**
     * Analyze function definitions
     */
    static function analyzeFunction(f:TFunc, context:String):Void {
        // Pattern matching patterns
        if (hasPatternMatching(f.expr)) {
            registerPattern(
                "pattern-matching",
                "Pattern Matching",
                "Using pattern matching in function bodies",
                getPatternMatchingExample(f),
                context
            );
        }
        
        // Error handling patterns
        if (hasErrorHandling(f.expr)) {
            registerPattern(
                "error-handling",
                "Error Handling",
                "Handling errors with ok/error tuples",
                getErrorHandlingExample(f),
                context
            );
        }
    }
    
    /**
     * Register a discovered pattern
     */
    static function registerPattern(id:String, name:String, description:String, code:String, context:String):Void {
        if (!patterns.exists(id)) {
            patterns.set(id, {
                id: id,
                name: name,
                description: description,
                code: code,
                examples: [context],
                frequency: 1
            });
        } else {
            var pattern = patterns.get(id);
            if (pattern.examples.indexOf(context) == -1) {
                pattern.examples.push(context);
            }
            pattern.frequency++;
        }
    }
    
    /**
     * Register an anti-pattern
     */
    public static function registerAntiPattern(name:String, description:String, badCode:String, goodCode:String):Void {
        antiPatterns.push({
            name: name,
            description: description,
            badCode: badCode,
            goodCode: goodCode
        });
    }
    
    /**
     * Generate pattern documentation
     */
    public static function generatePatternDocs(outputDir:String):Void {
        var content = new StringBuf();
        content.add("# Reflaxe.Elixir Patterns\n\n");
        content.add("*Auto-extracted from example projects*\n\n");
        
        // Sort patterns by frequency
        var sortedPatterns = [for (p in patterns) p];
        sortedPatterns.sort((a, b) -> b.frequency - a.frequency);
        
        // Most common patterns
        content.add("## Most Common Patterns\n\n");
        
        var count = 0;
        for (pattern in sortedPatterns) {
            if (count++ >= 10) break;
            
            content.add('### ${pattern.name}\n\n');
            content.add('${pattern.description}\n\n');
            content.add('**Usage:** Found ${pattern.frequency} times\n\n');
            content.add('```haxe\n${pattern.code}\n```\n\n');
            content.add('**Examples:** ${pattern.examples.slice(0, 3).join(", ")}\n\n');
        }
        
        // Anti-patterns
        if (antiPatterns.length > 0) {
            content.add("## Anti-Patterns to Avoid\n\n");
            
            for (anti in antiPatterns) {
                content.add('### ${anti.name}\n\n');
                content.add('${anti.description}\n\n');
                content.add('**❌ Bad:**\n');
                content.add('```haxe\n${anti.badCode}\n```\n\n');
                content.add('**✅ Good:**\n');
                content.add('```haxe\n${anti.goodCode}\n```\n\n');
            }
        }
        
        File.saveContent('$outputDir/PATTERNS.md', content.toString());
    }
    
    // Helper functions
    
    static function extractArgPattern(args:Array<TypedExpr>):String {
        // Simplified arg pattern extraction
        return args.length > 0 ? "..." : "";
    }
    
    static function getLiveViewPattern(e:TypedExpr):String {
        return "@:liveview\nclass MyLive {\n    // LiveView implementation\n}";
    }
    
    static function getSchemaPattern(e:TypedExpr):String {
        return "@:schema\nclass User {\n    public var id:Int;\n    public var name:String;\n}";
    }
    
    static function getChangesetPattern(e:TypedExpr):String {
        return "@:changeset\npublic static function changeset(struct, params) {\n    // Validation logic\n}";
    }
    
    static function hasPatternMatching(e:TypedExpr):Bool {
        // Check for switch expressions
        var found = false;
        TypedExprTools.iter(e, function(expr) {
            switch(expr.expr) {
                case TSwitch(_, _, _): found = true;
                case _:
            }
        });
        return found;
    }
    
    static function hasErrorHandling(e:TypedExpr):Bool {
        // Check for ok/error tuple handling
        var found = false;
        TypedExprTools.iter(e, function(expr) {
            switch(expr.expr) {
                case TCall(e, _):
                    // Look for error handling patterns
                    found = true; // Simplified
                case _:
            }
        });
        return found;
    }
    
    static function getPatternMatchingExample(f:TFunc):String {
        return "switch(result) {\n    case {ok: value}: handleSuccess(value);\n    case {error: reason}: handleError(reason);\n}";
    }
    
    static function getErrorHandlingExample(f:TFunc):String {
        return "try {\n    performOperation();\n} catch(e:Dynamic) {\n    handleError(e);\n}";
    }
}

// Type definitions
typedef Pattern = {
    id:String,
    name:String,
    description:String,
    code:String,
    examples:Array<String>,
    frequency:Int
}

typedef AntiPattern = {
    name:String,
    description:String,
    badCode:String,
    goodCode:String
}
#end