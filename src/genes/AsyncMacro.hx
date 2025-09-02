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
                if (hasAsync && processedExpr != null) {
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