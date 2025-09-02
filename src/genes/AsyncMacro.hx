package genes;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;
#end

/**
 * Build macro for automatic @:async and @:await processing with genes.
 * 
 * This integrates seamlessly with the genes ES6 generator to produce
 * clean async/await JavaScript without any wrapper functions.
 */
class AsyncMacro {
    
    #if macro
    
    /**
     * Build macro that processes @:async and @:await in classes.
     */
    public static function build(): Array<Field> {
        var fields = Context.getBuildFields();
        var processed = [];
        
        for (field in fields) {
            processed.push(processField(field));
        }
        
        return processed;
    }
    
    /**
     * Process a field, looking for @:async functions.
     */
    static function processField(field: Field): Field {
        // Check if field has @:async metadata
        var hasAsync = false;
        if (field.meta != null) {
            for (m in field.meta) {
                if (m.name == ":async" || m.name == "async") {
                    hasAsync = true;
                    break;
                }
            }
        }
        
        switch (field.kind) {
            case FFun(f) if (hasAsync || f.expr != null):
                // Process the function body for @:await
                var processedExpr = if (f.expr != null) processAwaitExpr(f.expr) else null;
                
                // If async, add the marker for genes to detect
                // AND wrap return statements in Promise.resolve() automatically
                // 
                // DESIGN NOTE: Why use __async_marker__ instead of checking metadata directly?
                // 
                // For class methods, this marker is actually REDUNDANT because genes already
                // checks field.meta for @:async directly (see ModuleEmitter.hx line 288).
                // However, we still inject it for consistency with anonymous functions.
                //
                // FUTURE REFACTOR OPPORTUNITY:
                // - Remove marker injection for class methods (since genes checks metadata)
                // - Only use markers for anonymous functions where metadata isn't preserved
                // - This would reduce generated code size and complexity
                //
                // The marker pattern ensures async intent survives all Haxe optimization passes,
                // which is critical for anonymous functions but unnecessary for class methods.
                if (hasAsync && processedExpr != null) {
                    // For async functions, automatically wrap returns in Promise.resolve()
                    // This matches JavaScript/TypeScript behavior where async functions
                    // automatically wrap return values in Promises
                    processedExpr = wrapReturnsInPromise(processedExpr);
                    processedExpr = macro {
                        var __async_marker__ = true;
                        $processedExpr;
                    };
                }
                
                field.kind = FFun({
                    args: f.args,
                    ret: f.ret,
                    expr: processedExpr,
                    params: f.params
                });
                
            case FVar(t, e) | FProp(_, _, t, e) if (e != null):
                // Process variable/property initializers for @:await
                var processedExpr = processAwaitExpr(e);
                switch (field.kind) {
                    case FVar(t, _):
                        field.kind = FVar(t, processedExpr);
                    case FProp(get, set, t, _):
                        field.kind = FProp(get, set, t, processedExpr);
                    case _:
                }
                
            case _:
        }
        
        return field;
    }
    
    /**
     * Wrap return statements in Promise.resolve() for async functions.
     * This provides JavaScript/TypeScript-like behavior where async functions
     * automatically wrap return values in Promises.
     */
    static function wrapReturnsInPromise(expr: Expr): Expr {
        if (expr == null) return null;
        
        return switch (expr.expr) {
            // Direct return statement - wrap in Promise.resolve()
            case EReturn(e) if (e != null):
                // Check if it's already a Promise.resolve/reject call
                switch (e.expr) {
                    case ECall({expr: EField(_, "resolve" | "reject")}, _):
                        // Already wrapped, don't double-wrap
                        expr;
                    case _:
                        // Wrap the return value in Promise.resolve()
                        {
                            expr: EReturn(macro js.lib.Promise.resolve($e)),
                            pos: expr.pos
                        };
                }
            
            // Empty return - return Promise.resolve()
            case EReturn(null):
                {
                    expr: EReturn(macro js.lib.Promise.resolve()),
                    pos: expr.pos
                };
            
            // Recursively process other expressions
            default:
                expr.map(wrapReturnsInPromise);
        };
    }
    
    /**
     * Process expressions looking for @:await metadata.
     */
    static function processAwaitExpr(expr: Expr): Expr {
        if (expr == null) return null;
        
        return switch (expr.expr) {
            // Handle @:await somePromise
            case EMeta({name: ":await" | "await"}, promiseExpr):
                macro js.Syntax.code("await {0}", ${processAwaitExpr(promiseExpr)});
                
            // Handle @:async function() { ... }
            case EMeta({name: ":async" | "async"}, {expr: EFunction(kind, f)}):
                var processedBody = processAwaitExpr(f.expr);
                
                // CRITICAL: Anonymous functions REQUIRE the marker pattern
                // 
                // Unlike class methods, anonymous functions in Haxe's TypedExpr
                // don't reliably preserve metadata through the compilation pipeline.
                // The @:async metadata we see here at macro-time won't be available
                // to genes at code generation time.
                //
                // The __async_marker__ variable is our workaround - it's guaranteed
                // to survive all optimization passes and be visible in the final AST.
                //
                // ALTERNATIVE APPROACHES CONSIDERED:
                // 1. Modify Haxe to preserve metadata on anonymous functions (requires Haxe fork)
                // 2. Use type annotations to signal async (would complicate type system)
                // 3. Post-process the generated JS (fragile, requires parsing JS)
                // 4. Current approach: Marker variable (simple, reliable, but adds overhead)
                //
                // The marker is removed during code generation, so the final output
                // is clean ES6 async/await without any runtime overhead.
                
                // Also wrap returns in Promise.resolve() for 1:1 JS/TS behavior
                processedBody = wrapReturnsInPromise(processedBody);
                
                var markedBody = macro {
                    var __async_marker__ = true;
                    $processedBody;
                };
                {
                    expr: EFunction(kind, {
                        args: f.args,
                        ret: f.ret,
                        expr: markedBody,
                        params: f.params
                    }),
                    pos: expr.pos
                };
                
            // Handle var x = @:await somePromise
            case EVars(vars):
                var processedVars = vars.map(v -> {
                    name: v.name,
                    type: v.type,
                    expr: processAwaitExpr(v.expr),
                    isFinal: v.isFinal,
                    isStatic: v.isStatic,
                    meta: v.meta,
                    namePos: v.namePos
                });
                {expr: EVars(processedVars), pos: expr.pos};
                
            // Recursively process all other expressions
            default:
                expr.map(processAwaitExpr);
        };
    }
    
    #end
}