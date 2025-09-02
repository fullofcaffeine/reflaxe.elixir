package reflaxe.js;

#if macro
import haxe.macro.JSGenApi;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import haxe.macro.Context;
import haxe.io.Path;
import sys.io.File;

/**
 * Custom JavaScript generator that adds support for async/await syntax.
 * 
 * This generator intercepts functions marked with @:jsAsync metadata
 * and generates proper ES6 async functions with the async keyword.
 * 
 * Usage:
 * --macro reflaxe.js.AsyncJSGenerator.use()
 * 
 * This wraps the standard JS generator and modifies output for async functions.
 */
class AsyncJSGenerator {
    var api: JSGenApi;
    var buf: StringBuf;
    var asyncFunctions: Map<String, Bool>;
    
    public function new(api: JSGenApi) {
        this.api = api;
        this.buf = new StringBuf();
        this.asyncFunctions = new Map();
    }
    
    /**
     * Register this generator to be used instead of the default JS generator.
     */
    public static function use() {
        Context.onAfterGenerate(function() {
            // This runs after normal generation
            // We could post-process the output here if needed
        });
        
        // Register our custom generator
        haxe.macro.Compiler.setCustomJSGenerator(function(api: JSGenApi) {
            new AsyncJSGenerator(api).generate();
        });
    }
    
    /**
     * Main generation function that processes all types.
     */
    public function generate() {
        // First pass: identify all async functions by scanning metadata
        for (type in api.types) {
            scanTypeForAsync(type);
        }
        
        // Get the default JS output
        var originalOutput = new StringBuf();
        
        // We need to capture the original generator's output
        // and then modify it for async functions
        var outputFile = api.outputFile;
        
        // Generate using the standard generator
        var generatedCode = generateStandardJS();
        
        // Post-process to add async keywords
        var modifiedCode = postProcessAsyncFunctions(generatedCode);
        
        // Write the modified output
        File.saveContent(outputFile, modifiedCode);
    }
    
    /**
     * Scan a type for functions with @:jsAsync metadata.
     */
    function scanTypeForAsync(type: Type) {
        switch (type) {
            case TInst(c, _):
                var cl = c.get();
                // Check all fields for async metadata
                for (field in cl.fields.get()) {
                    if (hasAsyncMeta(field.meta.get())) {
                        // Mark this function as async
                        var key = cl.name + "." + field.name;
                        asyncFunctions.set(key, true);
                    }
                }
                
                // Check static fields
                for (field in cl.statics.get()) {
                    if (hasAsyncMeta(field.meta.get())) {
                        var key = cl.name + "." + field.name;
                        asyncFunctions.set(key, true);
                    }
                }
                
            case _:
                // Other types don't have methods
        }
    }
    
    /**
     * Check if metadata contains @:jsAsync.
     */
    function hasAsyncMeta(meta: Metadata): Bool {
        for (m in meta) {
            if (m.name == ":jsAsync" || m.name == "jsAsync") {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Generate standard JavaScript using the default generator.
     */
    function generateStandardJS(): String {
        // This is a simplified version - in reality we'd need to
        // properly delegate to the standard generator
        var output = new StringBuf();
        
        // Process all types
        for (type in api.types) {
            var typeCode = generateType(type);
            output.add(typeCode);
        }
        
        // Add main if present
        if (api.main != null) {
            output.add("\n// Main\n");
            output.add(api.generateStatement(api.main));
        }
        
        return output.toString();
    }
    
    /**
     * Generate code for a single type.
     */
    function generateType(type: Type): String {
        // Use the API's built-in generation
        return switch (type) {
            case TInst(c, _):
                var cl = c.get();
                generateClass(cl);
            case TEnum(e, _):
                ""; // Enums handled elsewhere
            case _:
                "";
        };
    }
    
    /**
     * Generate a class with async support.
     */
    function generateClass(c: ClassType): String {
        var buf = new StringBuf();
        
        // Generate class structure
        // This is simplified - real implementation would be more complex
        
        return buf.toString();
    }
    
    /**
     * Post-process the generated JavaScript to add async keywords.
     * 
     * This is a simple regex-based approach that looks for function
     * declarations that should be async and adds the keyword.
     */
    function postProcessAsyncFunctions(code: String): String {
        // For each async function we identified, modify the output
        for (funcKey in asyncFunctions.keys()) {
            // This is a simplified approach - we'd need more sophisticated
            // pattern matching to handle all cases correctly
            
            // Look for function declarations like:
            // functionName: function() { ... }
            // or
            // function functionName() { ... }
            
            var parts = funcKey.split(".");
            var funcName = parts[parts.length - 1];
            
            // Pattern 1: Method in object literal
            var pattern1 = new EReg('(\\b' + funcName + '\\s*:\\s*)(function\\s*\\()', 'g');
            code = pattern1.replace(code, '$1async function(');
            
            // Pattern 2: Function declaration
            var pattern2 = new EReg('(function\\s+' + funcName + '\\s*\\()', 'g');
            code = pattern2.replace(code, 'async function ' + funcName + '(');
            
            // Pattern 3: Anonymous function assigned to variable
            var pattern3 = new EReg('(var\\s+' + funcName + '\\s*=\\s*)(function\\s*\\()', 'g');
            code = pattern3.replace(code, '$1async function(');
        }
        
        return code;
    }
}
#end