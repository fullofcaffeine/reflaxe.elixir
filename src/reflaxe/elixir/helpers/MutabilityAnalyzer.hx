package reflaxe.elixir.helpers;

import haxe.macro.Type;

/**
 * MutabilityAnalyzer: Detects and analyzes mutable field assignments in struct methods
 * 
 * WHY: Elixir's immutable data structures require transforming Haxe's mutable field
 * assignments into functional struct updates. This analyzer identifies which methods
 * mutate state so they can be transformed to return updated structs.
 * 
 * WHAT: Provides analysis capabilities for:
 * - Detecting field assignments to 'this' in methods
 * - Tracking which struct fields are mutated
 * - Marking methods as mutating or pure
 * - Identifying nested field mutations
 * 
 * HOW: Recursively traverses TypedExpr AST to find:
 * - Direct field assignments: this.field = value
 * - Nested field mutations: this.data.value = newValue
 * - Method calls on mutable fields: this.buf.add(value)
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only analyzes mutability patterns
 * - Open/Closed: Can be extended for new mutation patterns
 * - Testability: Pure analysis without side effects
 * - Maintainability: Isolated from compilation logic
 * 
 * EDGE CASES:
 * - Mutations through method calls (buf.add) require special handling
 * - Conditional mutations may not always execute
 * - Loop mutations need accumulation pattern
 * 
 * @see documentation/STATE_THREADING.md - Complete state threading strategy
 */
@:nullSafety(Off)
class MutabilityAnalyzer {
    
    var compiler: ElixirCompiler;
    
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Analyzes a method to determine if it mutates struct fields
     * 
     * @param expr The method body expression
     * @return MutabilityInfo containing mutation details
     */
    public function analyzeMethod(expr: TypedExpr): MutabilityInfo {
        var info: MutabilityInfo = {
            isMutating: false,
            mutatedFields: [],
            hasNestedMutations: false,
            returnsVoid: true
        };
        
        #if debug_mutability
        trace("[MutabilityAnalyzer] Starting analysis of method");
        #end
        
        analyzeMutations(expr, info);
        
        #if debug_mutability
        trace('[MutabilityAnalyzer] Analysis complete: isMutating=${info.isMutating}, fields=${info.mutatedFields}');
        #end
        
        return info;
    }
    
    /**
     * Recursively analyzes expressions for field mutations
     * 
     * WHY: Need to traverse entire AST to find all mutation points
     * WHAT: Detects assignments to 'this' fields at any depth
     * HOW: Pattern matches on OpAssign with TField targets
     */
    function analyzeMutations(expr: TypedExpr, info: MutabilityInfo): Void {
        if (expr == null) return;
        
        switch (expr.expr) {
            case TBinop(OpAssign, e1, e2):
                // Check if assigning to a field of 'this'
                if (isThisFieldAccess(e1)) {
                    info.isMutating = true;
                    var fieldName = extractFieldName(e1);
                    if (fieldName != null && info.mutatedFields.indexOf(fieldName) == -1) {
                        info.mutatedFields.push(fieldName);
                    }
                    
                    // Check for nested mutations
                    if (isNestedFieldAccess(e1)) {
                        info.hasNestedMutations = true;
                    }
                    
                    #if debug_mutability
                    trace('[MutabilityAnalyzer] Found field mutation: ${fieldName}');
                    #end
                }
                
                // Continue analyzing both sides
                analyzeMutations(e1, info);
                analyzeMutations(e2, info);
                
            case TBinop(op, e1, e2):
                // Check compound assignments like +=, -=, etc.
                switch (op) {
                    case OpAssignOp(_):
                        if (isThisFieldAccess(e1)) {
                            info.isMutating = true;
                            var fieldName = extractFieldName(e1);
                            if (fieldName != null && info.mutatedFields.indexOf(fieldName) == -1) {
                                info.mutatedFields.push(fieldName);
                            }
                        }
                    case _:
                }
                analyzeMutations(e1, info);
                analyzeMutations(e2, info);
                
            case TCall(e, params):
                // Check for method calls on mutable fields (like buf.add())
                if (isMutatingMethodCall(e)) {
                    info.isMutating = true;
                    var fieldName = extractFieldFromMethodCall(e);
                    if (fieldName != null && info.mutatedFields.indexOf(fieldName) == -1) {
                        info.mutatedFields.push(fieldName);
                    }
                }
                
                analyzeMutations(e, info);
                for (param in params) {
                    analyzeMutations(param, info);
                }
                
            case TBlock(exprs):
                for (e in exprs) {
                    analyzeMutations(e, info);
                }
                
            case TIf(econd, eif, eelse):
                analyzeMutations(econd, info);
                analyzeMutations(eif, info);
                if (eelse != null) {
                    analyzeMutations(eelse, info);
                }
                
            case TWhile(econd, e, _):
                analyzeMutations(econd, info);
                analyzeMutations(e, info);
                
            case TFor(v, e1, e2):
                analyzeMutations(e1, info);
                analyzeMutations(e2, info);
                
            case TSwitch(e, cases, edef):
                analyzeMutations(e, info);
                for (c in cases) {
                    for (v in c.values) {
                        analyzeMutations(v, info);
                    }
                    analyzeMutations(c.expr, info);
                }
                if (edef != null) {
                    analyzeMutations(edef, info);
                }
                
            case TReturn(e):
                if (e != null) {
                    info.returnsVoid = false;
                    analyzeMutations(e, info);
                }
                
            case TTry(e, catches):
                analyzeMutations(e, info);
                for (c in catches) {
                    analyzeMutations(c.expr, info);
                }
                
            case TVar(v, expr):
                if (expr != null) {
                    analyzeMutations(expr, info);
                }
                
            case TField(e, _):
                analyzeMutations(e, info);
                
            case TLocal(_):
                // Local variables don't affect struct mutability
                
            case TConst(_):
                // Constants don't mutate
                
            case _:
                // Handle other expression types recursively
                TypedExprHelper.iter(expr, function(e) analyzeMutations(e, info));
        }
    }
    
    /**
     * Checks if an expression is a field access on 'this'
     */
    function isThisFieldAccess(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TField(e, _):
                isThisExpression(e) || isThisFieldAccess(e);
            case _:
                false;
        };
    }
    
    /**
     * Checks if an expression references 'this'
     */
    function isThisExpression(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TConst(TThis):
                true;
            case TLocal(v) if (v.name == "this" || v.name == "_this"):
                true;
            case _:
                false;
        };
    }
    
    /**
     * Checks if a field access is nested (e.g., this.data.value)
     */
    function isNestedFieldAccess(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TField(e, _):
                switch (e.expr) {
                    case TField(_, _):
                        true;
                    case _:
                        false;
                }
            case _:
                false;
        };
    }
    
    /**
     * Extracts the top-level field name from a field access expression
     */
    function extractFieldName(expr: TypedExpr): Null<String> {
        return switch (expr.expr) {
            case TField(e, fa):
                if (isThisExpression(e)) {
                    switch (fa) {
                        case FInstance(_, _, cf):
                            cf.get().name;
                        case FAnon(cf):
                            cf.get().name;
                        case _:
                            null;
                    }
                } else {
                    extractFieldName(e);
                }
            case _:
                null;
        };
    }
    
    /**
     * Checks if a method call is mutating (e.g., buf.add())
     */
    function isMutatingMethodCall(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TField(e, fa):
                if (isThisFieldAccess(e)) {
                    // Check if the method name suggests mutation
                    var methodName = switch (fa) {
                        case FInstance(_, _, cf): cf.get().name;
                        case FAnon(cf): cf.get().name;
                        case _: null;
                    };
                    
                    if (methodName != null) {
                        // Common mutating method names
                        return ["add", "push", "pop", "shift", "unshift", "remove", 
                                "clear", "set", "update", "append", "prepend"].indexOf(methodName) != -1;
                    }
                }
                false;
            case _:
                false;
        };
    }
    
    /**
     * Extracts field name from a method call expression
     */
    function extractFieldFromMethodCall(expr: TypedExpr): Null<String> {
        return switch (expr.expr) {
            case TField(e, _):
                extractFieldName(e);
            case _:
                null;
        };
    }
    
    /**
     * Determines if a class type is a struct (uses @:structInit)
     */
    public static function isStructClass(c: ClassType): Bool {
        return c.meta.has(":structInit") || c.meta.has(":struct");
    }
    
    /**
     * Checks if a method should be transformed for state threading
     * 
     * @param info The mutability analysis results
     * @param isStruct Whether the containing class is a struct
     * @return True if the method should return updated struct
     */
    public static function shouldTransformMethod(info: MutabilityInfo, isStruct: Bool): Bool {
        /**
         * WHY: Transform ALL mutating methods in structs, not just void-returning ones
         * WHAT: Methods that mutate fields need to return updated structs in Elixir
         * HOW: Check if it's a struct method that mutates any fields
         * 
         * Previously we required returnsVoid, but this was too restrictive.
         * Methods like JsonPrinter.write might have implicit returns or return values,
         * but still need transformation to work with Elixir's immutability.
         */
        return isStruct && info.isMutating;
    }
}

/**
 * Information about method mutability
 */
typedef MutabilityInfo = {
    /**
     * Whether the method mutates any fields
     */
    var isMutating: Bool;
    
    /**
     * List of field names that are mutated
     */
    var mutatedFields: Array<String>;
    
    /**
     * Whether there are nested field mutations (e.g., this.data.value = x)
     */
    var hasNestedMutations: Bool;
    
    /**
     * Whether the method returns void (candidates for transformation)
     */
    var returnsVoid: Bool;
}

/**
 * Helper for traversing TypedExpr trees
 */
class TypedExprHelper {
    public static function iter(expr: TypedExpr, f: TypedExpr -> Void): Void {
        haxe.macro.TypedExprTools.iter(expr, f);
    }
}