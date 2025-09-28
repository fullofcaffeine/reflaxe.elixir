package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.TypeHelper;
using StringTools;

/**
 * PatternDetector: Centralized Pattern Detection Module
 * 
 * WHY: ElixirASTBuilder has grown to 11,137 lines with pattern detection logic scattered throughout.
 * This violates the Single Responsibility Principle and makes the code unmaintainable.
 * Pattern detection should be centralized for consistency and maintainability.
 * 
 * WHAT: Provides all pattern detection functions used during AST building phase.
 * - Loop patterns (for, while, do-while transformations)
 * - Array operations (map, filter, comprehensions)
 * - String patterns (interpolation candidates, concatenation)
 * - Enum patterns (constructor calls, pattern matching)
 * - Special constructs (HXX modules, Map types, fluent APIs)
 * 
 * HOW: Pure functions that analyze TypedExpr nodes and return detection results.
 * - No side effects or state mutation
 * - Returns structured data about detected patterns
 * - Used by ElixirASTBuilder to make transformation decisions
 * - Enables metadata attachment for transformer consumption
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only pattern detection, no AST building
 * - Open/Closed: Easy to add new patterns without modifying existing
 * - Testability: Pure functions can be tested independently
 * - Maintainability: All detection logic in one place
 * - Performance: Can optimize detection algorithms centrally
 * 
 * EDGE CASES:
 * - Nested patterns (loops within loops)
 * - Synthetic variables from Haxe desugaring
 * - Complex expressions with multiple patterns
 * - Pattern conflicts and priority resolution
 * 
 * @see ElixirASTBuilder for usage
 * @see ElixirASTTransformer for pattern consumption
 */
class PatternDetector {
    
    /**
     * Detects if an expression is an enum constructor call
     * 
     * WHY: Enum constructors need special handling in Elixir as tagged tuples
     * WHAT: Identifies TCall expressions that invoke enum constructors
     * HOW: Checks if the called expression is a FEnum field
     */
    public static function isEnumConstructor(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TField(_, FEnum(_, ef)):
                true;
            case _:
                false;
        };
    }
    
    /**
     * Detects if a type is an Array type
     * 
     * WHY: Arrays need different handling than other collections
     * WHAT: Checks if a Type is an Array<T> for any T
     * HOW: Unwraps type aliases and checks for TInst with Array name
     */
    public static function isArrayType(t: Type): Bool {
        return switch(t) {
            case TInst(ct, _):
                ct.get().name == "Array";
            case TAbstract(a, _):
                var abs = a.get();
                abs.name == "Array" || abs.name == "NativeArray";
            case _:
                false;
        };
    }
    
    /**
     * Detects if a type is a Map type
     * 
     * WHY: Maps need special iteration patterns in Elixir
     * WHAT: Identifies Map types including IMap and abstract types
     * HOW: Checks multiple Map type patterns
     */
    public static function isMapType(t: Type): Bool {
        return switch(t) {
            case TInst(c, _):
                var cl = c.get();
                cl.name == "StringMap" || cl.name == "IntMap" || cl.name == "ObjectMap" || 
                cl.name == "Map" || cl.name.endsWith("Map");
            case TAbstract(a, params):
                var abs = a.get();
                abs.name == "Map" || abs.name.endsWith("Map");
            default: false;
        }
    }
    
    /**
     * Detects array iteration patterns in while loops
     * 
     * WHY: Haxe desugars array comprehensions into while loops with specific patterns
     * WHAT: Identifies the array being iterated and the index variable
     * HOW: Pattern matches on the while condition structure
     * 
     * @return Array expression and index variable name, or null if not detected
     */
    public static function detectArrayIterationPattern(econd: TypedExpr): Null<{arrayExpr: TypedExpr, indexVar: String}> {
        return switch(econd.expr) {
            case TBinop(OpLt, {expr: TLocal(indexVar)}, {expr: TField({expr: TLocal(arrayVar)}, FInstance(_, _, cf))}) 
                if (cf.get().name == "length"):
                // Pattern: indexVar < arrayVar.length
                {arrayExpr: {expr: TLocal(arrayVar), t: arrayVar.t, pos: econd.pos}, indexVar: indexVar.name};
                
            case TBinop(OpLt, {expr: TLocal(indexVar)}, {expr: TField(arrayExpr, FInstance(_, _, cf))})
                if (cf.get().name == "length"):
                // Pattern: indexVar < someExpr.length
                {arrayExpr: arrayExpr, indexVar: indexVar.name};
                
            case _:
                null;
        };
    }
    
    /**
     * Detects array operation patterns in loop bodies
     * 
     * WHY: Array operations like map/filter are desugared into specific patterns
     * WHAT: Identifies whether a loop body performs map, filter, or other operations
     * HOW: Analyzes the structure of expressions in the loop body
     * 
     * @return Operation type ("map", "filter") or null
     */
    public static function detectArrayOperationPattern(body: TypedExpr): Null<String> {
        switch(body.expr) {
            case TBlock(exprs) if (exprs.length >= 3):
                var hasArrayAccess = false;
                var hasIncrement = false;
                var hasPush = false;
                var isFilter = false;
                
                for (expr in exprs) {
                    switch(expr.expr) {
                        case TVar(tvar, init):
                            if (init != null) {
                                switch(init.expr) {
                                    case TArray(_, _):
                                        hasArrayAccess = true;
                                    case _:
                                }
                            }
                            
                        case TUnop(OpIncrement, _, _) | TUnop(OpDecrement, _, _):
                            hasIncrement = true;
                            
                        case TCall({expr: TField(_, FInstance(_, _, cf))}, args) if (cf.get().name == "push"):
                            hasPush = true;
                            
                        case TIf(_, thenExpr, _):
                            switch(thenExpr.expr) {
                                case TCall({expr: TField(_, FInstance(_, _, cf))}, _) if (cf.get().name == "push"):
                                    hasPush = true;
                                    isFilter = true;
                                case TBlock([{expr: TCall({expr: TField(_, FInstance(_, _, cf))}, _)}]) if (cf.get().name == "push"):
                                    hasPush = true;
                                    isFilter = true;
                                case _:
                            }
                            
                        case _:
                    }
                }
                
                if (hasArrayAccess && hasIncrement && hasPush) {
                    return isFilter ? "filter" : "map";
                }
                
            case _:
        }
        
        return null;
    }
    
    /**
     * Detects if a string should use interpolation
     * 
     * WHY: String concatenation should be converted to interpolation in Elixir
     * WHAT: Identifies strings that contain variables or expressions
     * HOW: Analyzes string operations and patterns
     */
    public static function isStringInterpolationCandidate(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TBinop(OpAdd, e1, e2):
                // String concatenation
                isStringType(e1.t) && isStringType(e2.t);
            case _:
                false;
        };
    }
    
    /**
     * Helper to check if a type is String
     */
    private static function isStringType(t: Type): Bool {
        return switch(t) {
            case TInst(ct, _):
                ct.get().name == "String";
            case TAbstract(a, _):
                a.get().name == "String";
            case _:
                false;
        };
    }
    
    /**
     * Detects if an expression is a loop pattern
     * 
     * WHY: Different loop types need different transformations
     * WHAT: Identifies for, while, do-while patterns
     * HOW: Examines expression structure
     */
    public static function isLoopPattern(expr: TypedExpr): LoopType {
        return switch(expr.expr) {
            case TFor(_, _, _):
                ForLoop;
            case TWhile(_, _, true):
                WhileLoop;
            case TWhile(_, _, false):
                DoWhileLoop;
            case _:
                NotALoop;
        };
    }
    
    /**
     * Detects if a parameter name uses camelCase
     * 
     * WHY: CamelCase parameters need snake_case conversion
     * WHAT: Checks if a string follows camelCase pattern
     * HOW: Regex pattern matching
     */
    public static function isCamelCaseParameter(name: String): Bool {
        // Check if it starts with lowercase and has an uppercase letter
        if (name.length > 0 && name.charAt(0) == name.charAt(0).toLowerCase()) {
            for (i in 1...name.length) {
                var c = name.charAt(i);
                if (c == c.toUpperCase() && c != c.toLowerCase()) {
                    return true;
                }
            }
        }
        return false;
    }
    
    /**
     * Detects if a variable name is a temporary pattern variable
     * 
     * WHY: Haxe generates temporary variables that should be hidden
     * WHAT: Identifies g, g1, g2 style temporary variables
     * HOW: Pattern matching on variable names
     */
    public static function isTempPatternVarName(name: String): Bool {
        if (name == "g") return true;
        if (name.length > 1 && name.charAt(0) == "g") {
            var suffix = name.substr(1);
            return isDigits(suffix);
        }
        return false;
    }
    
    private static function isDigits(str: String): Bool {
        if (str.length == 0) return false;
        for (i in 0...str.length) {
            var c = str.charCodeAt(i);
            if (c < 48 || c > 57) return false; // 0-9
        }
        return true;
    }
    
    /**
     * Detects if an expression is an HXX module call
     * 
     * WHY: HXX templates need special compilation
     * WHAT: Identifies calls to HXX.hxx() or HXX.raw()
     * HOW: Checks for specific module and method names
     */
    public static function isHXXModule(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TTypeExpr(TClassDecl(c)):
                c.get().name == "HXX";
            case _:
                false;
        };
    }
    
    /**
     * Detects fluent API patterns
     * 
     * WHY: Fluent APIs that return 'this' need special handling
     * WHAT: Identifies methods that return the same object for chaining
     * HOW: Analyzes function return patterns
     */
    public static function detectFluentAPIPattern(func: TFunc): {returnsThis: Bool, fieldMutations: Array<{field: String, expr: TypedExpr}>} {
        var result = {
            returnsThis: false,
            fieldMutations: []
        };
        
        function checkReturnsThis(expr: TypedExpr): Bool {
            return switch(expr.expr) {
                case TLocal(v) if (v.name == "this"):
                    true;
                case TBlock(exprs) if (exprs.length > 0):
                    checkReturnsThis(exprs[exprs.length - 1]);
                case TReturn(e) if (e != null):
                    checkReturnsThis(e);
                case _:
                    false;
            };
        }
        
        function detectMutations(expr: TypedExpr): Void {
            switch(expr.expr) {
                case TBinop(OpAssign, {expr: TField({expr: TLocal(v)}, FInstance(_, _, cf))}, value) 
                    if (v.name == "this"):
                    result.fieldMutations.push({field: cf.get().name, expr: value});
                case TBlock(exprs):
                    for (e in exprs) detectMutations(e);
                case _:
            }
        }
        
        if (func.expr != null) {
            result.returnsThis = checkReturnsThis(func.expr);
            detectMutations(func.expr);
        }
        
        return result;
    }
    
    /**
     * Detects if an expression is a constant
     * 
     * WHY: Constants can be evaluated at compile time
     * WHAT: Identifies literal values and const expressions
     * HOW: Checks for literal patterns
     */
    public static function isConstant(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TConst(_):
                true;
            case TLocal(v) if (v.name.indexOf("const") == 0):
                true;
            case _:
                false;
        };
    }
    
    /**
     * Detects if an expression is pure (no side effects)
     * 
     * WHY: Pure expressions can be safely moved or eliminated
     * WHAT: Identifies expressions without side effects
     * HOW: Recursively checks expression tree
     */
    public static function isPure(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TConst(_) | TLocal(_) | TTypeExpr(_):
                true;
            case TField(e, _):
                isPure(e);
            case TArray(e1, e2):
                isPure(e1) && isPure(e2);
            case TBinop(_, e1, e2):
                isPure(e1) && isPure(e2);
            case TUnop(_, _, e):
                isPure(e);
            case TParenthesis(e):
                isPure(e);
            case _:
                false;
        };
    }
    
    /**
     * Detects array comprehension patterns
     * 
     * WHY: Array comprehensions should become Elixir for comprehensions
     * WHAT: Identifies [for ...] patterns
     * HOW: Checks for specific AST structures
     */
    public static function isArrayComprehension(expr: TypedExpr): Bool {
        // This would need more complex analysis of TArrayDecl with TFor
        // Simplified for now
        return false; // TODO: Implement comprehension detection
    }
}

/**
 * Loop type enumeration for pattern detection
 */
enum LoopType {
    ForLoop;
    WhileLoop;
    DoWhileLoop;
    NotALoop;
}

#end