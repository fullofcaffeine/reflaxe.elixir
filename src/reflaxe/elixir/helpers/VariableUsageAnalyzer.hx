package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;

/**
 * VariableUsageAnalyzer: Pre-compilation variable usage analysis
 * 
 * WHY: The compiler needs to know which variables are actually used before generating
 * code, so it can properly prefix unused variables with underscore in Elixir.
 * This is critical for enum extraction patterns where temporary variables (_g)
 * are generated but may not be used in the case body.
 * 
 * WHAT: Performs a complete AST traversal to build a usage map that tracks:
 * - Which variables are referenced (TLocal)
 * - Which variables are used in expressions (TNew, TCall, etc.)
 * - Which extracted enum parameters are actually used
 * 
 * HOW: Two-pass analysis:
 * 1. First pass: Collect all variable declarations (TVar)
 * 2. Second pass: Mark variables as used when referenced
 * The resulting map is used by ElixirASTBuilder for context-aware naming.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only analyzes usage, doesn't generate code
 * - Open/Closed: Can be extended for new usage patterns
 * - Predictable Pipeline: Analysis happens before AST building
 * - Clean Separation: Usage analysis is independent of code generation
 * 
 * EDGE CASES:
 * - Handles nested scopes (functions, loops, conditionals)
 * - Tracks usage through complex expressions (field access, array access)
 * - Distinguishes between declaration and usage
 * - Handles variable shadowing correctly
 */
@:nullSafety(Off)
class VariableUsageAnalyzer {
    /**
     * Analyze variable usage in an expression
     * 
     * @param expr The TypedExpr to analyze
     * @return Map of variable ID to usage status (true if used)
     */
    public static function analyzeUsage(expr: TypedExpr): Map<Int, Bool> {
        var declaredVars = new Map<Int, TVar>();
        var usedVars = new Map<Int, Bool>();
        
        // First pass: collect all variable declarations
        collectDeclarations(expr, declaredVars);
        
        // Initialize all declared variables as unused
        for (id => tvar in declaredVars) {
            usedVars.set(id, false);
        }
        
        // Second pass: mark used variables
        markUsedVariables(expr, usedVars, declaredVars);
        
        #if debug_variable_usage
        trace('[VariableUsageAnalyzer] Analysis complete: ${Lambda.count(usedVars)} variables analyzed');
        for (id => isUsed in usedVars) {
            if (declaredVars.exists(id)) {
                var v = declaredVars.get(id);
                if ((v.name.charAt(0) == "_" && v.name.charAt(1) == "g") || v.name == "g" || ~/^g\d+$/.match(v.name) || 
                    v.name == "value" || v.name == "msg" || v.name == "err" || v.name == "left" || v.name == "right") {
                    trace('  Variable ${v.name} (id: $id): ${isUsed ? "USED" : "UNUSED"}');
                }
            }
        }
        #end
        
        return usedVars;
    }
    
    /**
     * Collect all variable declarations
     */
    static function collectDeclarations(expr: TypedExpr, declaredVars: Map<Int, TVar>): Void {
        switch (expr.expr) {
            case TVar(v, init):
                declaredVars.set(v.id, v);
                #if debug_variable_usage
                if (v.name == "value" || v.name == "msg" || v.name == "err") {
                    trace('[VariableUsageAnalyzer] Collecting TVar: ${v.name} (id: ${v.id})');
                }
                #end
                if (init != null) {
                    collectDeclarations(init, declaredVars);
                }
                
            case TFunction(tfunc):
                // Function parameters are declarations
                for (arg in tfunc.args) {
                    declaredVars.set(arg.v.id, arg.v);
                }
                collectDeclarations(tfunc.expr, declaredVars);
                
            default:
                // Recursively process all sub-expressions
                TypedExprTools.iter(expr, function(e) {
                    collectDeclarations(e, declaredVars);
                });
        }
    }
    
    /**
     * Mark variables as used when they're referenced
     */
    static function markUsedVariables(expr: TypedExpr, usedVars: Map<Int, Bool>, declaredVars: Map<Int, TVar>): Void {
        switch (expr.expr) {
            case TLocal(v):
                // Variable reference - mark as used
                if (usedVars.exists(v.id)) {
                    usedVars.set(v.id, true);
                    
                    #if debug_variable_usage
                    trace('[VariableUsageAnalyzer] Marking ${v.name} (id: ${v.id}) as USED (TLocal reference)');
                    #end
                }
                
            case TVar(v, init):
                // Process initialization expression
                if (init != null) {
                    markUsedVariables(init, usedVars, declaredVars);
                }
                
            case TNew(_, _, el):
                // Constructor arguments - all expressions are used
                for (e in el) {
                    markUsedVariables(e, usedVars, declaredVars);
                }
                
            case TCall(e, el):
                // Function call - target and arguments are used
                markUsedVariables(e, usedVars, declaredVars);
                for (arg in el) {
                    markUsedVariables(arg, usedVars, declaredVars);
                }
                
            case TField(e, _):
                // Field access - object is used
                markUsedVariables(e, usedVars, declaredVars);
                
            case TArray(e1, e2):
                // Array access - both array and index are used
                markUsedVariables(e1, usedVars, declaredVars);
                markUsedVariables(e2, usedVars, declaredVars);
                
            case TBinop(_, e1, e2):
                // Binary operation - both operands are used
                markUsedVariables(e1, usedVars, declaredVars);
                markUsedVariables(e2, usedVars, declaredVars);
                
            case TUnop(_, _, e):
                // Unary operation - operand is used
                markUsedVariables(e, usedVars, declaredVars);
                
            case TReturn(e) if (e != null):
                // Return value is used
                markUsedVariables(e, usedVars, declaredVars);
                
            case TThrow(e):
                // Thrown value is used
                markUsedVariables(e, usedVars, declaredVars);
                
            case TSwitch(e, cases, edef):
                // Switch target is used
                markUsedVariables(e, usedVars, declaredVars);
                
                // Process each case
                for (c in cases) {
                    // Case patterns don't count as usage (they're declarations)
                    // But the case body does
                    markUsedVariables(c.expr, usedVars, declaredVars);
                }
                
                // Process default case
                if (edef != null) {
                    markUsedVariables(edef, usedVars, declaredVars);
                }
                
            case TEnumParameter(e, _, _):
                // Enum parameter extraction - the enum value is used
                markUsedVariables(e, usedVars, declaredVars);
                
            case TObjectDecl(fields):
                // Object literal - all field values are used
                for (field in fields) {
                    markUsedVariables(field.expr, usedVars, declaredVars);
                }
                
            case TArrayDecl(el):
                // Array literal - all elements are used
                for (e in el) {
                    markUsedVariables(e, usedVars, declaredVars);
                }
                
            case TIf(econd, ethen, eelse):
                // Conditional - condition is used, branches processed
                markUsedVariables(econd, usedVars, declaredVars);
                markUsedVariables(ethen, usedVars, declaredVars);
                if (eelse != null) {
                    markUsedVariables(eelse, usedVars, declaredVars);
                }
                
            case TWhile(econd, e, _):
                // While loop - condition and body are processed
                markUsedVariables(econd, usedVars, declaredVars);
                markUsedVariables(e, usedVars, declaredVars);
                
            case TFor(v, e1, e2):
                // For loop - iterator expression is used, body is processed
                markUsedVariables(e1, usedVars, declaredVars);
                markUsedVariables(e2, usedVars, declaredVars);
                
            case TBlock(el):
                // Block - process all expressions
                for (e in el) {
                    markUsedVariables(e, usedVars, declaredVars);
                }
                
            case TFunction(tfunc):
                // Function - process body
                markUsedVariables(tfunc.expr, usedVars, declaredVars);
                
            case TTry(e, catches):
                // Try/catch - process try block and catch blocks
                markUsedVariables(e, usedVars, declaredVars);
                for (c in catches) {
                    markUsedVariables(c.expr, usedVars, declaredVars);
                }
                
            case TCast(e, _):
                // Cast - expression is used
                markUsedVariables(e, usedVars, declaredVars);
                
            case TMeta(_, e):
                // Metadata - process wrapped expression
                markUsedVariables(e, usedVars, declaredVars);
                
            case TParenthesis(e):
                // Parenthesis - process inner expression
                markUsedVariables(e, usedVars, declaredVars);
                
            case TBreak | TContinue:
                // Control flow - no variables used
                
            case TConst(_):
                // Constants - no variables used
                
            case TTypeExpr(_):
                // Type expressions - no variables used
                
            case TIdent(_):
                // Identifiers - handled as TLocal if it's a variable
                
            default:
                // For any other expression types, recursively process sub-expressions
                TypedExprTools.iter(expr, function(e) {
                    markUsedVariables(e, usedVars, declaredVars);
                });
        }
    }
    
    /**
     * Check if a specific variable is used
     * 
     * @param varId The variable ID to check
     * @param usageMap The usage map from analyzeUsage
     * @return true if the variable is used, false otherwise
     */
    public static function isVariableUsed(varId: Int, usageMap: Map<Int, Bool>): Bool {
        return usageMap.exists(varId) && usageMap.get(varId);
    }
    
    /**
     * Analyze a specific scope (like a function body) for variable usage
     * Useful for analyzing case expressions independently
     * 
     * @param expr The scope expression to analyze
     * @param parentUsageMap Optional parent scope usage map to inherit from
     * @return Usage map for this scope
     */
    public static function analyzeScopeUsage(expr: TypedExpr, ?parentUsageMap: Map<Int, Bool>): Map<Int, Bool> {
        var usageMap = analyzeUsage(expr);
        
        // Merge with parent scope if provided
        if (parentUsageMap != null) {
            for (id => isUsed in parentUsageMap) {
                if (!usageMap.exists(id)) {
                    usageMap.set(id, isUsed);
                }
            }
        }
        
        return usageMap;
    }
    
    /**
     * Check if an expression contains a reference to "this"
     * Used to determine if the struct parameter in instance methods should be prefixed with underscore
     * 
     * @param expr The TypedExpr to analyze for "this" references
     * @return true if the expression contains a reference to "this", false otherwise
     */
    public static function containsThisReference(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch(expr.expr) {
            case TConst(TThis):
                return true;
                
            case TLocal(v) if (v.name == "this" || v.name == "_this"):
                return true;
                
            case TBlock(exprs):
                for (e in exprs) {
                    if (containsThisReference(e)) return true;
                }
                
            case TBinop(_, e1, e2):
                return containsThisReference(e1) || containsThisReference(e2);
                
            case TUnop(_, _, e):
                return containsThisReference(e);
                
            case TField(e, _):
                return containsThisReference(e);
                
            case TCall(e, el):
                if (containsThisReference(e)) return true;
                for (arg in el) {
                    if (containsThisReference(arg)) return true;
                }
                
            case TIf(econd, eif, eelse):
                if (containsThisReference(econd)) return true;
                if (containsThisReference(eif)) return true;
                if (eelse != null && containsThisReference(eelse)) return true;
                
            case TSwitch(e, cases, edef):
                if (containsThisReference(e)) return true;
                for (c in cases) {
                    if (containsThisReference(c.expr)) return true;
                }
                if (edef != null && containsThisReference(edef)) return true;
                
            case TWhile(econd, e, _):
                return containsThisReference(econd) || containsThisReference(e);
                
            case TFor(_, e1, e2):
                return containsThisReference(e1) || containsThisReference(e2);
                
            case TTry(e, catches):
                if (containsThisReference(e)) return true;
                for (c in catches) {
                    if (containsThisReference(c.expr)) return true;
                }
                
            case TReturn(e):
                if (e != null) return containsThisReference(e);
                
            case TThrow(e):
                return containsThisReference(e);
                
            case TVar(_, e):
                if (e != null) return containsThisReference(e);
                
            case TFunction(tfunc):
                return containsThisReference(tfunc.expr);
                
            case TArrayDecl(el):
                for (e in el) {
                    if (containsThisReference(e)) return true;
                }
                
            case TObjectDecl(fields):
                for (f in fields) {
                    if (containsThisReference(f.expr)) return true;
                }
                
            case TParenthesis(e):
                return containsThisReference(e);
                
            case TCast(e, _):
                return containsThisReference(e);
                
            case TMeta(_, e):
                return containsThisReference(e);
                
            case TNew(_, _, el):
                for (e in el) {
                    if (containsThisReference(e)) return true;
                }
                
            case TEnumParameter(e, _, _):
                return containsThisReference(e);
                
            case TEnumIndex(e):
                return containsThisReference(e);
                
            default:
                // For other cases, assume no this reference
        }
        
        return false;
    }
}

#end