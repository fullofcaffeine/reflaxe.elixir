package reflaxe.js;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Compiler;
import sys.io.File;

using haxe.macro.ExprTools;
#end

/**
 * The definitive, elegant async solution for JavaScript.
 * 
 * Approach:
 * 1. Mark async functions with a specific pattern in generated JS
 * 2. Post-process the file to replace patterns with async keyword
 * 3. No wrappers, no complexity - just clean ES6 async functions
 */
class AsyncSimple {
    
    #if macro
    
    /**
     * Initialize the async system.
     * Registers a post-processor to clean up the JavaScript.
     */
    public static function init() {
        // Register post-processor
        Context.onAfterGenerate(postProcessJavaScript);
    }
    
    /**
     * Post-process the generated JavaScript file.
     */
    static function postProcessJavaScript() {
        var output = Compiler.getOutput();
        if (!StringTools.endsWith(output, ".js")) return;
        
        try {
            // Read the generated JavaScript
            var js = File.getContent(output);
            
            // Pattern 1: Replace our marker pattern
            // (function() { var __async_marker__ = true; ... })
            // becomes: (async function() { ... })
            var pattern = ~/([\(=]\s*)function(\s*\([^)]*\)\s*\{\s*var\s+__async_marker__\s*=\s*true;)/g;
            js = pattern.replace(js, "$1async function$2");
            
            // Clean up the marker variable
            js = StringTools.replace(js, "var __async_marker__ = true;", "");
            
            // Write back
            File.saveContent(output, js);
        } catch (e:Dynamic) {
            // Silent fail - don't break compilation
        }
    }
    
    #end
    
    /**
     * Process @:async and @:await metadata.
     * Usage: 
     * - var myFunc = @:async function() { ... }
     * - var result = @:await somePromise;
     */
    public static macro function process(expr: Expr): Expr {
        // Check if this is an @:async function
        switch (expr.expr) {
            case EMeta({name: ":async" | "async"}, funcExpr):
                switch (funcExpr.expr) {
                    case EFunction(kind, f):
                        // Add our marker that will be post-processed
                        var markedBody = macro {
                            var __async_marker__ = true;
                            ${processAwaitInBody(f.expr)};
                        };
                        
                        // Return the function with marked body
                        return {
                            expr: EFunction(kind, {
                                args: f.args,
                                ret: f.ret,
                                expr: markedBody,
                                params: f.params
                            }),
                            pos: funcExpr.pos
                        };
                    default:
                        Context.error("@:async can only be applied to functions", funcExpr.pos);
                }
                
            case EMeta({name: ":await" | "await"}, promiseExpr):
                // Transform @:await to js.Syntax.code
                return macro js.Syntax.code("await {0}", $promiseExpr);
                
            default:
                // Recursively process the expression for nested @:await
                return expr.map(process);
        }
    }
    
    /**
     * Process @:await inside function bodies.
     */
    static function processAwaitInBody(expr: Expr): Expr {
        if (expr == null) return null;
        
        return switch (expr.expr) {
            case EMeta({name: ":await" | "await"}, promiseExpr):
                // Transform @:await to js.Syntax.code
                macro js.Syntax.code("await {0}", $promiseExpr);
                
            default:
                // Recursively process
                expr.map(processAwaitInBody);
        }
    }
    
    /**
     * Mark a function as async (convenience method).
     * Can also use @:async metadata directly.
     */
    public static macro function async(expr: Expr): Expr {
        // Add @:async metadata and process
        var metaExpr = {
            expr: EMeta({name: ":async", params: [], pos: expr.pos}, expr),
            pos: expr.pos
        };
        return process(metaExpr);
    }
}