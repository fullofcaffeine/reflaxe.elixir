package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.CompilationContext;

/**
 * ControlFlowBuilder: Handles control flow statement building
 * 
 * WHY: Separates control flow logic from ElixirASTBuilder
 * - Reduces main builder complexity
 * - Centralizes if/else transformation logic
 * - Handles optimized enum switch detection
 * 
 * WHAT: Builds ElixirAST nodes for control flow
 * - TIf: Conditional statements with optimized enum switch detection
 * - Cond pattern detection for chained if-else
 * - Guard clause optimization
 * 
 * HOW: Analyzes patterns and generates appropriate AST
 * - Detects enum index comparisons for case transformation
 * - Builds ECase or ECond based on pattern
 * - Handles inline conditional expressions
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only control flow logic
 * - Pattern Detection: Sophisticated enum switch recognition
 * - Future-Ready: Easy to add cond/with patterns
 */
@:nullSafety(Off)
class ControlFlowBuilder {
    
    /**
     * Build if/else conditional expression
     * 
     * WHY: TIf can represent simple conditionals OR optimized enum switches
     * WHAT: Detects pattern and generates ECase or ECond
     * HOW: Checks for TEnumIndex comparisons that indicate switch optimization
     * 
     * @param econd Condition expression
     * @param eif Then branch expression
     * @param eelse Optional else branch expression
     * @param context Build context with compilation state
     * @return ElixirASTDef for the conditional
     */
    public static function buildIf(econd: TypedExpr, eif: TypedExpr, eelse: Null<TypedExpr>, context: CompilationContext): ElixirASTDef {
        var buildExpression = context.getExpressionBuilder();
        
        #if debug_ast_builder
        trace('[ControlFlow] Processing TIf with condition: ${Type.enumConstructor(econd.expr)}');
        #end
        
        // Check if this is an optimized enum switch
        var optimizedSwitch = detectOptimizedEnumSwitch(econd, eif, eelse, context);
        if (optimizedSwitch != null) {
            return optimizedSwitch;
        }
        
        // Build standard conditional
        var condition = buildExpression(econd);
        var thenBranch = buildExpression(eif);
        var elseBranch = eelse != null ? buildExpression(eelse) : null;
        
        // Check if this should be a cond statement (multiple chained if-else)
        if (shouldUseCond(eif, eelse)) {
            return buildCondStatement(econd, eif, eelse, context);
        }
        
        // Simple if-else or inline conditional
        if (elseBranch != null) {
            // Check if this is an inline expression
            if (isInlineExpression(eif) && isInlineExpression(eelse)) {
                // Inline conditional: if(cond, do: then, else: else)
                return ECall(makeAST(EVar("if")), "", [
                    condition,
                    makeAST(ETuple([
                        makeAST(EAtom("do")),
                        thenBranch
                    ])),
                    makeAST(ETuple([
                        makeAST(EAtom("else")),
                        elseBranch
                    ]))
                ]);
            }
        }
        
        // Regular if-else block
        // For simple if-else, we need to generate a simple conditional
        // In Elixir AST, this is typically an EIf or inline conditional
        if (elseBranch != null) {
            // With else branch
            return EIf(condition, thenBranch, elseBranch);
        } else {
            // Without else branch
            return EIf(condition, thenBranch, null);
        }
    }
    
    /**
     * Detect if TIf is actually an optimized enum switch
     * 
     * WHY: Haxe optimizes single-case switches to if statements
     * WHAT: Detects TEnumIndex comparisons and transforms back to case
     * HOW: Looks for pattern: if (enumValue.index == N) then else
     * 
     * EDGE CASES:
     * - Wrapped in TParenthesis
     * - Reversed comparison order
     * - Negated conditions
     */
    static function detectOptimizedEnumSwitch(econd: TypedExpr, eif: TypedExpr, eelse: Null<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        var buildExpression = context.getExpressionBuilder();
        
        // Unwrap parenthesis if present
        var condToCheck = switch(econd.expr) {
            case TParenthesis(inner): inner;
            default: econd;
        };
        
        // Check for enum index comparison
        var enumValue: TypedExpr = null;
        var enumIndex: Int = -1;
        var enumTypeRef: haxe.macro.Type.Ref<haxe.macro.Type.EnumType> = null;
        
        switch(condToCheck.expr) {
            case TBinop(OpEq, {expr: TEnumIndex(e)}, {expr: TConst(TInt(index))}) | 
                 TBinop(OpEq, {expr: TConst(TInt(index))}, {expr: TEnumIndex(e)}):
                // Found enum index comparison
                switch(e.t) {
                    case TEnum(eRef, _):
                        enumValue = e;
                        enumIndex = index;
                        enumTypeRef = eRef;
                        #if debug_ast_builder
                        trace('[ControlFlow] Detected optimized enum switch: index $index');
                        #end
                    default:
                }
            default:
        }
        
        if (enumValue != null && enumIndex >= 0 && enumTypeRef != null) {
            // Transform to proper case pattern matching
            var enumTypeInfo = enumTypeRef.get();
            var matchingConstructor: String = null;
            var constructorParams = 0;
            
            // Find constructor by index
            for (name in enumTypeInfo.constructs.keys()) {
                var construct = enumTypeInfo.constructs.get(name);
                if (construct.index == enumIndex) {
                    matchingConstructor = name;
                    // Count constructor parameters
                    switch(construct.type) {
                        case TFun(args, _):
                            constructorParams = args.length;
                        default:
                            constructorParams = 0;
                    }
                    break;
                }
            }
            
            if (matchingConstructor != null) {
                #if debug_ast_builder
                trace('[ControlFlow] Transforming to case with constructor: $matchingConstructor');
                #end
                
                // Build case expression
                var enumExpr = buildExpression(enumValue);
                var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(matchingConstructor);
                
                // Build pattern based on parameter count
                var patternAST = if (constructorParams == 0) {
                    // No parameters: just atom
                    makeAST(EAtom(atomName));
                } else {
                    // With parameters: tuple with wildcards
                    var elements = [makeAST(EAtom(atomName))];
                    for (_ in 0...constructorParams) {
                        elements.push(makeAST(EVar("_")));
                    }
                    makeAST(ETuple(elements));
                };
                
                // Convert ElixirAST to EPattern using PLiteral wrapper
                var pattern = EPattern.PLiteral(patternAST);
                
                // Build case clauses
                var clauses = [];
                
                // Matching case
                // TODO: Consider renaming 'guard' to 'guards' in ECaseClause typedef
                // since it's conceptually an array of guard conditions
                clauses.push({
                    pattern: pattern,
                    guard: null,  // No guards for this case
                    body: buildExpression(eif)
                });
                
                // Default case (else branch or raise)
                if (eelse != null) {
                    clauses.push({
                        pattern: EPattern.PWildcard,
                        guard: null,
                        body: buildExpression(eelse)
                    });
                } else {
                    // No else branch - add default that raises
                    clauses.push({
                        pattern: EPattern.PWildcard,
                        guard: null,
                        body: makeAST(EThrow(makeAST(EString("Unmatched enum value"))))
                    });
                }
                
                return ECase(enumExpr, clauses);
            }
        }
        
        return null; // Not an optimized enum switch
    }
    
    /**
     * Check if expression should use cond instead of if-else
     * 
     * WHY: Chained if-else statements are better as cond in Elixir
     * WHAT: Detects nested if-else chains
     * HOW: Checks if else branch contains another if
     */
    static function shouldUseCond(eif: TypedExpr, eelse: Null<TypedExpr>): Bool {
        if (eelse == null) return false;
        
        // Check if else branch is another if statement
        return switch(eelse.expr) {
            case TIf(_, _, _): true;
            case TBlock([single]) if (single.expr.match(TIf(_, _, _))): true;
            default: false;
        };
    }
    
    /**
     * Build cond statement from chained if-else
     * 
     * WHY: More idiomatic for multiple conditions in Elixir
     * WHAT: Transforms if-else chain to cond clauses
     * HOW: Recursively extracts conditions and branches
     */
    static function buildCondStatement(econd: TypedExpr, eif: TypedExpr, eelse: Null<TypedExpr>, context: CompilationContext): ElixirASTDef {
        var buildExpression = context.getExpressionBuilder();
        var clauses = [];
        
        // Add first condition
        clauses.push({
            condition: buildExpression(econd),
            body: buildExpression(eif)
        });
        
        // Extract remaining conditions from else chain
        var current = eelse;
        while (current != null) {
            switch(current.expr) {
                case TIf(cond2, if2, else2):
                    clauses.push({
                        condition: buildExpression(cond2),
                        body: buildExpression(if2)
                    });
                    current = else2;
                    
                case TBlock([single]):
                    current = single;
                    
                default:
                    // Final else becomes true -> body
                    clauses.push({
                        condition: makeAST(EAtom("true")),
                        body: buildExpression(current)
                    });
                    break;
            }
        }
        
        // If no else, add default true -> nil
        if (clauses[clauses.length - 1].condition.def != EAtom("true")) {
            clauses.push({
                condition: makeAST(EAtom("true")),
                body: makeAST(EAtom("nil"))
            });
        }
        
        return ECond(clauses);
    }
    
    /**
     * Check if expression is suitable for inline conditional
     * 
     * WHY: Simple expressions can use inline if(cond, do: x, else: y)
     * WHAT: Checks if expression is simple enough for inline
     * HOW: Looks for single expressions without complex blocks
     */
    static function isInlineExpression(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TConst(_): true;
            case TLocal(_): true;
            case TCall(_, _): true;
            case TField(_, _): true;
            case TBinop(_, _, _): true;
            case TUnop(_, _, _): true;
            case TArrayDecl(_): true;
            case TObjectDecl(_): true;
            case TBlock([single]): isInlineExpression(single);
            default: false;
        };
    }
    
    /**
     * Helper to create AST nodes
     */
    static inline function makeAST(def: ElixirASTDef, ?pos: haxe.macro.Expr.Position): ElixirAST {
        return {def: def, metadata: {}, pos: pos};
    }
}

#end