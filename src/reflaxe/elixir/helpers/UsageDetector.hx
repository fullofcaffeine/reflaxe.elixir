package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;

/**
 * UsageDetector: Simple parameter usage detection
 * 
 * WHY: Detect if function parameters are actually used in the function body
 * to enable proper underscore prefixing for unused variables.
 * 
 * WHAT: Traverses the function body to find TLocal references to parameters.
 * 
 * HOW: Recursively checks the AST for any reference to the parameter's ID.
 */
class UsageDetector {
    /**
     * Check if a parameter is used in the function body
     * 
     * @param param The parameter TVar to check
     * @param body The function body expression to search
     * @return True if the parameter is referenced, false otherwise
     */
    public static function isParameterUsed(param: TVar, body: TypedExpr): Bool {
        if (body == null) return false;
        
        var used = false;
        
        function checkExpr(e: TypedExpr): Void {
            if (e == null || used) return;
            
            switch(e.expr) {
                case TLocal(v):
                    // Check if this local reference is to our parameter
                    if (v.id == param.id) {
                        used = true;
                    }
                    
                default:
                    // Recursively check all sub-expressions
                    TypedExprTools.iter(e, checkExpr);
            }
        }
        
        checkExpr(body);
        return used;
    }
}

#end