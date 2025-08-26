package reflaxe.elixir.preprocessors;

// =======================================================
// * RemoveOrphanedEnumParametersImpl
// =======================================================

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NullableMetaAccessHelper;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.TypedExprHelper;

/**
 * Removes orphaned enum parameter extractions in switch expressions
 * 
 * WHY: Haxe generates TVar(g, TEnumParameter(...)) for enum destructuring even when
 *      parameters are never used in case bodies. This creates orphaned assignments
 *      like 'g_array = elem(action, 1)' that pollute generated code.
 * 
 * WHAT: Analyzes switch expressions to detect when enum parameters are extracted
 *       but never referenced in their corresponding case bodies.
 * 
 * HOW: Traverses TypedExpr AST looking for TVar(TEnumParameter) declarations
 *      and marks unused parameter variables with -reflaxe.unused metadata.
 *      
 * RENAMED VARIABLE HANDLING:
 *      When Haxe renames variables to avoid shadowing (spec → spec2), we track
 *      both the renamed variable AND check if the original name is referenced.
 *      This prevents incorrectly marking renamed-but-used variables as unused.
 * 
 * ARCHITECTURAL ALIGNMENT: Follows Reflaxe's established preprocessor pattern
 *                         instead of inventing ad-hoc detection systems.
 */
class RemoveOrphanedEnumParametersImpl {
    var exprList: Array<TypedExpr>;
    
    /**
     * Static entry point following Reflaxe preprocessor pattern
     */
    public static function remove(list: Array<TypedExpr>): Array<TypedExpr> {
        final processor = new RemoveOrphanedEnumParametersImpl(list);
        return processor.removeOrphanedEnumParameters();
    }
    
    public function new(list: Array<TypedExpr>) {
        exprList = list;
    }
    
    var foundOrphaned: Bool = false;
    var parameterVars: Map<Int, {tvar: TVar, used: Bool, originalName: String}> = [];
    var renamedVariableMap: Map<String, Int> = []; // Maps original names to TVar IDs
    
    /**
     * Main processing function - analyzes expressions for orphaned enum parameters
     */
    public function removeOrphanedEnumParameters(): Array<TypedExpr> {
        foundOrphaned = false;
        
        for (e in exprList) {
            analyzeExpression(e);
        }
        
        // Mark orphaned parameter variables with metadata
        for (id => data in parameterVars) {
            if (!data.used) {
                // Add -reflaxe.unused for truly unused variables
                if (!data.tvar.meta.maybeHas("-reflaxe.unused")) {
                    data.tvar.meta.maybeAdd("-reflaxe.unused", [], Context.currentPos());
                    foundOrphaned = true;
                }
            } else {
                // For renamed variables that ARE used, add metadata to track the relationship
                if (isRenamedVariable(data.tvar.name)) {
                    var originalName = extractOriginalName(data.tvar.name);
                    if (!data.tvar.meta.maybeHas("-reflaxe.renamed")) {
                        // Store original name in metadata for pattern matching compiler
                        data.tvar.meta.maybeAdd("-reflaxe.renamed", [
                            {expr: EConst(CString(originalName)), pos: Context.currentPos()}
                        ], Context.currentPos());
                    }
                }
            }
        }
        
        return exprList;
    }
    
    /**
     * Check if a variable name appears to be renamed (has numeric suffix)
     */
    function isRenamedVariable(name: String): Bool {
        return ~/^.+[0-9]+$/.match(name);
    }
    
    /**
     * Extract original name from renamed variable (strip numeric suffix)
     */
    function extractOriginalName(name: String): String {
        if (~/^(.+?)([0-9]+)$/.match(name)) {
            return ~/^(.+?)([0-9]+)$/.replace(name, "$1");
        }
        return name;
    }
    
    /**
     * Analyze a TypedExpr for enum parameter patterns
     */
    function analyzeExpression(expr: TypedExpr): Void {
        switch (expr.expr) {
            case TSwitch(e, cases, edef):
                // Analyze switch expression for enum parameter usage
                analyzeSwitchExpression(e, cases, edef);
                
            case TVar(tvar, maybeExpr) if (maybeExpr != null):
                // Check if this is an enum parameter extraction
                switch (maybeExpr.expr) {
                    case TEnumParameter(_, _, _):
                        // Track this as a potential orphaned parameter
                        var originalName = extractOriginalName(tvar.name);
                        parameterVars.set(tvar.id, {tvar: tvar, used: false, originalName: originalName});
                    case _:
                }
                
            case TLocal(tvar):
                // Mark variable as used if we encounter a reference
                if (parameterVars.exists(tvar.id)) {
                    parameterVars.get(tvar.id).used = true;
                }
                
            case _:
        }
        
        // Recursively analyze sub-expressions
        haxe.macro.TypedExprTools.iter(expr, analyzeExpression);
    }
    
    /**
     * Analyze switch expression to track enum parameter usage across cases
     */
    function analyzeSwitchExpression(switchExpr: TypedExpr, cases: Array<{values:Array<TypedExpr>, expr:TypedExpr}>, defaultExpr: Null<TypedExpr>): Void {
        // Reset parameter tracking for this switch
        parameterVars = [];
        
        // First pass: collect all enum parameter extractions from case bodies
        // The TEnumParameter expressions are generated in the case bodies, not patterns
        for (c in cases) {
            collectEnumParameters(c.expr);
        }
        
        if (defaultExpr != null) {
            collectEnumParameters(defaultExpr);
        }
        
        // Second pass: check if collected parameters are actually used
        for (c in cases) {
            checkParameterUsageInExpression(c.expr);
        }
        
        if (defaultExpr != null) {
            checkParameterUsageInExpression(defaultExpr);
        }
    }
    
    /**
     * Collect enum parameter variables from case patterns
     */
    function collectEnumParameters(expr: TypedExpr): Void {
        switch (expr.expr) {
            case TVar(tvar, maybeExpr) if (maybeExpr != null):
                switch (maybeExpr.expr) {
                    case TEnumParameter(_, _, _):
                        var originalName = extractOriginalName(tvar.name);
                        parameterVars.set(tvar.id, {tvar: tvar, used: false, originalName: originalName});
                        
                        // If this is a renamed variable, also track the mapping
                        if (isRenamedVariable(tvar.name)) {
                            renamedVariableMap.set(originalName, tvar.id);
                        }
                    case _:
                }
            case _:
        }
        
        haxe.macro.TypedExprTools.iter(expr, collectEnumParameters);
    }
    
    /**
     * Check if any tracked parameter variables are used in the expression
     */
    function checkParameterUsageInExpression(expr: TypedExpr): Void {
        switch (expr.expr) {
            case TLocal(tvar):
                if (parameterVars.exists(tvar.id)) {
                    parameterVars.get(tvar.id).used = true;
                }
            case _:
        }
        
        haxe.macro.TypedExprTools.iter(expr, checkParameterUsageInExpression);
    }
}


#end