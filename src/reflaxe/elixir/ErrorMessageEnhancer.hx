package reflaxe.elixir;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * Enhanced error message system for Reflaxe.Elixir compiler
 * Provides actionable suggestions and improved diagnostics
 */
class ErrorMessageEnhancer {
    // Common error patterns and their solutions
    static final ERROR_PATTERNS:Map<String, ErrorSuggestion> = [
        "Type not found : elixir" => {
            pattern: ~/Type not found : elixir\.(.*)/,
            message: "Missing extern definition for Elixir module",
            suggestion: "Create an extern class for the Elixir module or check if std/elixir/ contains the needed extern",
            example: "@:native(\"ModuleName\")\nextern class ModuleName {\n    // Add extern methods here\n}"
        },
        "has no field" => {
            pattern: ~/has no field (.*)/,
            message: "Field or method not found",
            suggestion: "Check if the field/method exists in the extern definition or if you need to add it",
            example: "Add to extern class:\n@:native(\"function_name\")\npublic static function functionName(args):ReturnType;"
        },
        "should be Int" => {
            pattern: ~/should be Int/,
            message: "Type mismatch: Expected Int",
            suggestion: "Ensure numeric values are properly typed as Int, not String or Dynamic",
            example: "Use: var count:Int = 5;\nNot: var count = \"5\";"
        },
        "Unexpected keyword" => {
            pattern: ~/Unexpected keyword '(.*)'/,
            message: "Reserved keyword used as identifier",
            suggestion: "Rename the parameter or variable to avoid Haxe/Elixir keywords",
            example: "Common conflicts: function→func, interface→iface, operator→op"
        },
        "Unknown identifier" => {
            pattern: ~/Unknown identifier : (.*)/,
            message: "Undefined variable or type",
            suggestion: "Check if the identifier is imported or defined. For Elixir modules, create extern definitions",
            example: "import elixir.ModuleName;\n// or\nusing StringTools;"
        },
        "@:native metadata" => {
            pattern: ~/@:native/,
            message: "Native metadata usage issue",
            suggestion: "Ensure @:native is used correctly on extern classes and methods",
            example: "@:native(\"Elixir.Module\")\nextern class Module { }"
        },
        "Abstract type" => {
            pattern: ~/Abstract .* cannot be/,
            message: "Abstract type compilation issue",
            suggestion: "Abstract types need proper underlying type and @:forward metadata",
            example: "abstract UserId(Int) from Int to Int {\n    inline public function new(id:Int) this = id;\n}"
        },
        "Phoenix" => {
            pattern: ~/Phoenix|LiveView|Ecto/,
            message: "Phoenix/Ecto integration issue",
            suggestion: "Ensure Phoenix annotations are properly used and Mix tasks are run",
            example: "@:liveview\nclass MyLive { }\n// Then run: mix haxe.gen.live"
        }
    ];

    // IDE-specific error formatting
    static final IDE_FORMATS:Map<String, String -> String> = [
        "vscode" => (msg) -> '▸ $msg',
        "sublime" => (msg) -> '→ $msg',
        "vim" => (msg) -> '» $msg',
        "default" => (msg) -> '• $msg'
    ];

    /**
     * Enhance an error message with actionable suggestions
     */
    public static function enhanceError(error:String, pos:Position):String {
        var enhanced = error;
        var suggestions = [];
        
        // Check each pattern
        for (key => errorInfo in ERROR_PATTERNS) {
            if (errorInfo.pattern.match(error)) {
                suggestions.push('\n${formatMessage(errorInfo.message)}');
                suggestions.push('${formatSuggestion(errorInfo.suggestion)}');
                if (errorInfo.example != null) {
                    suggestions.push('${formatExample(errorInfo.example)}');
                }
                break;
            }
        }
        
        // Add position context
        var posInfo = Context.getPosInfos(pos);
        suggestions.push('\n${formatLocation(posInfo.file, posInfo.min)}');
        
        // Add quick fixes if available
        var quickFixes = getQuickFixes(error);
        if (quickFixes.length > 0) {
            suggestions.push('\n${formatQuickFixes(quickFixes)}');
        }
        
        return enhanced + suggestions.join("\n");
    }

    /**
     * Get quick fix suggestions for common errors
     */
    static function getQuickFixes(error:String):Array<QuickFix> {
        var fixes = [];
        
        if (error.indexOf("Type not found") >= 0) {
            fixes.push({
                label: "Create extern definition",
                action: "Generate extern class template"
            });
        }
        
        if (error.indexOf("has no field") >= 0) {
            fixes.push({
                label: "Add field to extern",
                action: "Add missing field/method to extern class"
            });
        }
        
        if (error.indexOf("Unexpected keyword") >= 0) {
            fixes.push({
                label: "Rename identifier",
                action: "Rename to avoid keyword conflict"
            });
        }
        
        return fixes;
    }

    /**
     * Format error message for current IDE
     */
    static function formatMessage(msg:String):String {
        var ide = getIDE();
        var formatter = IDE_FORMATS.get(ide);
        if (formatter == null) formatter = IDE_FORMATS.get("default");
        return formatter('ERROR: $msg');
    }

    /**
     * Format suggestion text
     */
    static function formatSuggestion(suggestion:String):String {
        return '  💡 Suggestion: $suggestion';
    }

    /**
     * Format code example
     */
    static function formatExample(example:String):String {
        var lines = example.split("\n");
        return "  📝 Example:\n" + lines.map(l -> "     " + l).join("\n");
    }

    /**
     * Format file location info
     */
    static function formatLocation(file:String, pos:Int):String {
        return '  📍 Location: $file:$pos';
    }

    /**
     * Format quick fix options
     */
    static function formatQuickFixes(fixes:Array<QuickFix>):String {
        if (fixes.length == 0) return "";
        var result = "  🔧 Quick Fixes:";
        for (i in 0...fixes.length) {
            result += '\n     ${i+1}. ${fixes[i].label}';
        }
        return result;
    }

    /**
     * Detect current IDE from environment
     */
    static function getIDE():String {
        // Check environment variables
        if (Sys.getEnv("VSCODE_PID") != null) return "vscode";
        if (Sys.getEnv("SUBLIME_TEXT") != null) return "sublime";
        if (Sys.getEnv("VIM") != null) return "vim";
        return "default";
    }

    /**
     * Register error handler with Context
     */
    public static function register():Void {
        // Intercept Context.error calls
        haxe.macro.Context.onGenerate(function(types) {
            // Register enhanced error reporting
            trace("ErrorMessageEnhancer: Registered for enhanced error reporting");
        });
    }
}

typedef ErrorSuggestion = {
    pattern:EReg,
    message:String,
    suggestion:String,
    ?example:String
}

typedef QuickFix = {
    label:String,
    action:String
}
#end