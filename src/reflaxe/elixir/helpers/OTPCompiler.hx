package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.helpers.AnnotationSystem;
import reflaxe.elixir.helpers.CompilerUtilities;

using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * OTPCompiler: Specialized compiler for OTP (Open Telecom Platform) patterns
 * 
 * WHY: OTP compilation (supervisors, GenServers, child specs) was embedded in ElixirCompiler,
 *      making the main compiler too large (~3100 lines) and mixing unrelated concerns.
 *      OTP patterns have specific Elixir conventions that benefit from centralized handling.
 * 
 * WHAT: Handles all OTP-related compilation for Haxe-to-Elixir transpilation:
 * - Child spec generation for supervisor children
 * - Supervisor options compilation  
 * - TypeSafeChildSpec enum handling
 * - Atom vs string key decisions for OTP structures
 * - Supervisor strategy and restart configuration
 * 
 * HOW: Maps Haxe OTP patterns to idiomatic Elixir OTP structures:
 * 1. Analyzes OTP-specific patterns and metadata
 * 2. Generates proper Elixir OTP configuration maps
 * 3. Handles atom key conversion for OTP contexts
 * 4. Ensures compliance with OTP conventions
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles OTP patterns
 * - Clear Interface: Simple public API for OTP compilation  
 * - Reduces ElixirCompiler size: Extracts ~300 lines
 * - Testability: OTP patterns isolated from general compilation
 * - Maintainability: OTP conventions centralized in one place
 * 
 * EDGE CASES:
 * - Mix of atom and string keys in maps
 * - Optional fields in child specs
 * - Supervisor name generation
 * - Type inference for worker vs supervisor
 * - Restart strategies and their constraints
 */
@:nullSafety(Off)
class OTPCompiler {
    
    /** Reference to main compiler for expression compilation */
    var compiler: ElixirCompiler;
    
    /**
     * Constructor
     * @param compiler Main ElixirCompiler instance for delegation
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
        
        #if debug_otp_compilation
        trace("[OTPCompiler] Initialized");
        #end
    }
    
    /**
     * Compile child spec configuration for OTP supervisors
     * 
     * WHY: Supervisors need properly formatted child specs to start processes
     * WHAT: Transforms Haxe objects to Elixir child spec maps
     * HOW: Extracts fields and generates proper OTP child spec format
     * 
     * @param fields Object fields containing child spec configuration
     * @param classType Optional class type for metadata extraction
     * @return Generated Elixir child spec map
     */
    public function compileChildSpec(fields: Array<{name: String, expr: TypedExpr}>, classType: Null<ClassType>): String {
        #if debug_otp_compilation
        trace('[OTPCompiler] Compiling child spec with ${fields.length} fields');
        #end
        
        var compiledFields = new Map<String, String>();
        
        // Get app name from annotation at compile time
        var appName = AnnotationSystem.getEffectiveAppName(classType);
        
        // Process each field from the child spec configuration
        for (field in fields) {
            var compiledValue = compiler.compileExpression(field.expr);
            
            switch (field.name) {
                case "id":
                    // Resolve app name interpolation first
                    compiledValue = resolveAppNameInString(compiledValue, appName);
                    // Ensure ID is always a properly formatted atom for OTP compatibility
                    if (!compiledValue.startsWith(":")) {
                        compiledValue = CompilerUtilities.formatAsAtom(compiledValue);
                    }
                    compiledFields.set("id", compiledValue);
                    
                case "start":
                    // Resolve app name interpolation first
                    compiledValue = resolveAppNameInString(compiledValue, appName);
                    // Start can be a tuple {Module, :function, [args]} or a function reference
                    if (compiledValue.startsWith("{") || compiledValue.startsWith("&")) {
                        compiledFields.set("start", compiledValue);
                    } else {
                        // Assume it's a module reference, convert to proper start tuple
                        var moduleName = CompilerUtilities.stripQuotes(compiledValue);
                        compiledFields.set("start", '{${moduleName}, :start_link, []}');
                    }
                    
                case "restart":
                    // Restart strategies: :permanent, :temporary, :transient
                    if (compiledValue == '"permanent"' || compiledValue == "'permanent'") {
                        compiledFields.set("restart", ":permanent");
                    } else if (compiledValue == '"temporary"' || compiledValue == "'temporary'") {
                        compiledFields.set("restart", ":temporary");
                    } else if (compiledValue == '"transient"' || compiledValue == "'transient'") {
                        compiledFields.set("restart", ":transient");
                    } else {
                        compiledFields.set("restart", compiledValue);
                    }
                    
                case "shutdown":
                    // Shutdown can be an integer (milliseconds), :infinity, or :brutal_kill
                    if (compiledValue == '"infinity"' || compiledValue == "'infinity'") {
                        compiledFields.set("shutdown", ":infinity");
                    } else if (compiledValue == '"brutal_kill"' || compiledValue == "'brutal_kill'") {
                        compiledFields.set("shutdown", ":brutal_kill");
                    } else {
                        compiledFields.set("shutdown", compiledValue);
                    }
                    
                case "type":
                    // Type is either :worker or :supervisor
                    var typeValue = CompilerUtilities.stripQuotes(compiledValue);
                    if (typeValue.indexOf("GenServer") != -1 || typeValue.indexOf("Agent") != -1) {
                        compiledFields.set("type", ":worker");
                    } else if (typeValue.indexOf("Supervisor") != -1) {
                        compiledFields.set("type", ":supervisor");
                    } else {
                        compiledFields.set("type", typeValue);
                    }
                    
                case "modules":
                    // Resolve app name interpolation in module references
                    compiledValue = resolveAppNameInString(compiledValue, appName);
                    // Modules is typically [Module] for dynamic modules
                    compiledFields.set("modules", compiledValue);
                    
                default:
                    // Pass through any other fields as-is
                    compiledFields.set(field.name, compiledValue);
            }
        }
        
        // Generate default values for required fields if missing
        if (!compiledFields.exists("id")) {
            // Generate ID from start module if possible
            if (compiledFields.exists("start")) {
                var startValue = compiledFields.get("start");
                if (startValue != null && startValue.startsWith("{")) {
                    // Extract module name from tuple
                    var parts = startValue.split(",");
                    if (parts.length > 0) {
                        var moduleName = parts[0].substring(1).trim();
                        // Use formatAsAtom to properly handle module names with dots
                        compiledFields.set("id", CompilerUtilities.formatAsAtom(moduleName));
                    }
                } else {
                    compiledFields.set("id", ":worker");
                }
            } else {
                compiledFields.set("id", ":worker");
            }
        }
        
        // Default restart strategy
        if (!compiledFields.exists("restart")) {
            compiledFields.set("restart", ":permanent");
        }
        
        // Default type
        if (!compiledFields.exists("type")) {
            compiledFields.set("type", ":worker");
        }
        
        // Build the child spec map
        var result = new StringBuf();
        result.add("%{");
        
        var fieldList = [];
        for (key in compiledFields.keys()) {
            var value = compiledFields.get(key);
            fieldList.push('${key}: ${value}');
        }
        
        result.add(fieldList.join(", "));
        result.add("}");
        
        #if debug_otp_compilation
        trace('[OTPCompiler] Generated child spec: ${result.toString()}');
        #end
        
        return result.toString();
    }
    
    /**
     * Compile supervisor options to Elixir keyword list format
     * 
     * WHY: Supervisors require specific keyword list format for configuration
     * WHAT: Transforms Haxe supervisor options to Elixir keyword list
     * HOW: Extracts strategy, restart limits, and name configuration
     * 
     * @param fields Object fields containing supervisor options
     * @param classType Optional class type for metadata extraction
     * @return Generated Elixir supervisor options keyword list
     */
    public function compileSupervisorOptions(fields: Array<{name: String, expr: TypedExpr}>, classType: Null<ClassType>): String {
        #if debug_otp_compilation
        trace('[OTPCompiler] Compiling supervisor options with ${fields.length} fields');
        #end
        
        var strategy = "one_for_one";
        var name = "";
        var maxRestarts = "3";
        var maxSeconds = "5";
        
        var appName = AnnotationSystem.getEffectiveAppName(classType);
        
        // Extract fields from the supervisor options object
        for (field in fields) {
            switch (field.name) {
                case "strategy":
                    strategy = CompilerUtilities.stripQuotes(compiler.compileExpression(field.expr));
                case "max_restarts":
                    maxRestarts = compiler.compileExpression(field.expr);
                case "max_seconds":  
                    maxSeconds = compiler.compileExpression(field.expr);
                case "name":
                    var compiledName = compiler.compileExpression(field.expr);
                    name = compiledName;
                default:
                    // Ignore unknown fields for supervisor options
            }
        }
        
        // If no name was specified, generate default supervisor name
        if (name == "") {
            name = '${appName}.Supervisor';
        }
        
        // Build the keyword list with supervisor options
        var options = [];
        
        // Add restart strategy - ensure proper atom formatting
        options.push('strategy: :${CompilerUtilities.stripColon(strategy)}');
        
        // Add supervisor name
        options.push('name: ${name}');
        
        // Add restart limits
        options.push('max_restarts: ${maxRestarts}');
        options.push('max_seconds: ${maxSeconds}');
        
        var result = '[${options.join(", ")}]';
        
        #if debug_otp_compilation
        trace('[OTPCompiler] Generated supervisor options: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Determine if an object should use atom keys based on OTP patterns
     * 
     * WHY: OTP structures require atom keys, regular maps use string keys
     * WHAT: Analyzes field patterns to determine key type
     * HOW: Checks for specific OTP field combinations
     * 
     * @param fields Object fields to analyze
     * @return True if atom keys should be used
     */
    public function shouldUseAtomKeys(fields: Array<{name: String, expr: TypedExpr}>): Bool {
        #if debug_otp_compilation
        trace('[OTPCompiler] Checking if should use atom keys for ${fields.length} fields');
        #end
        
        var fieldNames = fields.map(f -> f.name);
        
        // Check for supervisor configuration pattern
        var supervisorFields = ["strategy", "max_restarts", "max_seconds"];
        var hasAllSupervisorFields = true;
        for (field in supervisorFields) {
            if (fieldNames.indexOf(field) == -1) {
                hasAllSupervisorFields = false;
                break;
            }
        }
        
        if (hasAllSupervisorFields) {
            #if debug_otp_compilation
            trace("[OTPCompiler] Detected supervisor options pattern - using atom keys");
            #end
            return true;
        }
        
        // Check for child spec pattern
        var childSpecFields = ["id", "start"];
        var hasChildSpecFields = true;
        for (field in childSpecFields) {
            if (fieldNames.indexOf(field) == -1) {
                hasChildSpecFields = false;
                break;
            }
        }
        
        if (hasChildSpecFields) {
            #if debug_otp_compilation
            trace("[OTPCompiler] Detected child spec pattern - using atom keys");
            #end
            return true;
        }
        
        // Default to string keys for safety
        #if debug_otp_compilation
        trace("[OTPCompiler] No OTP pattern detected - using string keys");
        #end
        return false;
    }
    
    /**
     * Resolve app name interpolation in a string at compile time
     * 
     * WHY: Child specs need proper module names with app prefix
     * WHAT: Replaces app_name placeholders with actual app name
     * HOW: Pattern matching on common interpolation patterns
     * 
     * @param str String with potential app name placeholders
     * @param appName The actual application name
     * @return String with resolved app name
     */
    public function resolveAppNameInString(str: String, appName: String): String {
        if (str == null) return "";
        
        // Remove outer quotes
        str = CompilerUtilities.stripQuotes(str);
        
        // Handle common interpolation patterns from Haxe string interpolation
        str = StringTools.replace(str, '" <> app_name <> "', appName);
        str = StringTools.replace(str, '${appName}', appName);
        str = StringTools.replace(str, 'app_name', appName);
        
        // Clean up any remaining empty string concatenations
        str = StringTools.replace(str, '" <> "', '');
        str = StringTools.replace(str, ' <> ', '');
        
        return str;
    }
}

#end