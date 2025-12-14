package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.analyzers.VariableAnalyzer;

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
        // DISABLED: trace('[ControlFlow] Processing TIf with condition: ${Type.enumConstructor(econd.expr)}');
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
        
        // CRITICAL FIX: Always use EIf, never ECall
        // WHY: 'if' is a keyword/macro in Elixir, not a function
        // WHAT: EIf generates proper 'if cond, do: then, else: else' syntax
        // HOW: ElixirASTPrinter handles inline vs block formatting automatically
        //
        // The printer (ElixirASTPrinter.hx:338-372) automatically detects:
        // - Simple expressions → inline format: if cond, do: val1, else: val2
        // - Complex expressions → block format: if cond do\n  val1\nelse\n  val2\nend
        //
        // OLD BUGGY CODE (generated invalid if.() lambda calls):
        //   return ECall(makeAST(EVar("if")), "", [condition, {:do, then}, {:else, else}]);
        //
        // NEW CORRECT CODE (generates proper if expressions):
        return EIf(condition, thenBranch, elseBranch);
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
                        // DISABLED: trace('[ControlFlow] Detected optimized enum switch: index $index');
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
            var constructorParamNames: Array<String> = [];
            
            // Find constructor by index
            for (name in enumTypeInfo.constructs.keys()) {
                var construct = enumTypeInfo.constructs.get(name);
                if (construct.index == enumIndex) {
                    matchingConstructor = name;
                    // Count constructor parameters
                    switch(construct.type) {
                        case TFun(args, _):
                            constructorParams = args.length;
                            constructorParamNames = [for (a in args) a.name];
                        default:
                            constructorParams = 0;
                    }
                    break;
                }
            }
            
            if (matchingConstructor != null) {
                #if debug_ast_builder
                // DISABLED: trace('[ControlFlow] Transforming to case with constructor: $matchingConstructor');
                #end
                
                // Build case expression
                var enumExpr = buildExpression(enumValue);
                var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(matchingConstructor);

                // Build case pattern based on parameter count, preserving binders when possible.
                //
                // WHY: Haxe optimizes single-case switches into `if enumIndex == N`, which loses
                // the original `case Ctor(binder)` parameter names. The then-branch still references
                // those binders, so we must recover them to avoid generating wildcard patterns that
                // break semantics (e.g., {:ok, _} but body uses `value`).
                //
                // HOW:
                // - Prefer binders recovered from the then-branch (via `var x = TEnumParameter(...)`).
                // - Fallback to the enum constructor parameter names.
                // - Emit PWildcard when the binder isn't used in the then-branch.
                var pattern: EPattern = if (constructorParams == 0) {
                    EPattern.PLiteral(makeAST(EAtom(atomName)));
                } else {
                    var recovered = extractEnumParamBindersFromThenBranch(eif, matchingConstructor, constructorParams);
                    var binderPatterns: Array<EPattern> = [];
                    for (paramIndex in 0...constructorParams) {
                        var haxeBinderName: Null<String> = null;
                        if (recovered != null && paramIndex < recovered.length) {
                            haxeBinderName = recovered[paramIndex];
                        }
                        if ((haxeBinderName == null || haxeBinderName.length == 0) && paramIndex < constructorParamNames.length) {
                            haxeBinderName = constructorParamNames[paramIndex];
                        }

                        // Only bind names that the then-branch actually uses.
                        if (haxeBinderName == null || haxeBinderName.length == 0 || !branchUsesHaxeVarName(eif, haxeBinderName)) {
                            binderPatterns.push(EPattern.PWildcard);
                        } else {
                            binderPatterns.push(EPattern.PVar(VariableAnalyzer.toElixirVarName(haxeBinderName)));
                        }
                    }
                    EPattern.PTuple([EPattern.PLiteral(makeAST(EAtom(atomName)))].concat(binderPatterns));
                };
                
                // Build case clauses
                var clauses = [];
                
                // Matching case
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
     * Recover enum constructor parameter binder names from the `then` branch of an optimized enum switch.
     *
     * WHY
     * - When Haxe rewrites `switch (e) { case Ctor(x): ...; case _: ... }` into an `if` on TEnumIndex,
     *   it typically extracts constructor parameters inside the then-branch via `TEnumParameter(...)`.
     * - We use these extracted local names (when present) to rebuild a `case` pattern that binds the
     *   same identifiers the branch body references.
     *
     * HOW
     * - Traverse the then-branch and capture `TVar(name, TEnumParameter(_, ef, index))` where `ef.name`
     *   matches the constructor name, mapping `index -> name`.
     */
    static function extractEnumParamBindersFromThenBranch(thenBranch: TypedExpr, constructorName: String, paramCount: Int): Array<Null<String>> {
        var out: Array<Null<String>> = [for (_ in 0...paramCount) null];

        inline function unwrapEnumParameter(expr: TypedExpr): Null<{ ctorName: String, index: Int }> {
            var cur = expr;
            while (cur != null) {
                switch (cur.expr) {
                    case TParenthesis(inner):
                        cur = inner;
                        continue;
                    case TMeta(_, inner):
                        cur = inner;
                        continue;
                    default:
                }
                break;
            }

            return switch (cur.expr) {
                case TEnumParameter(_, ef, index):
                    { ctorName: ef.name, index: index };
                default:
                    null;
            };
        }

        function traverse(expr: TypedExpr): Void {
            if (expr == null) return;

            switch (expr.expr) {
                case TVar(v, init) if (init != null):
                    var info = unwrapEnumParameter(init);
                    if (info != null && info.ctorName == constructorName && info.index >= 0 && info.index < paramCount) {
                        out[info.index] = v.name;
                    }
                    traverse(init);
                case TBlock(exprs):
                    for (e in exprs) traverse(e);
                case TIf(c, t, eelse):
                    traverse(c);
                    traverse(t);
                    if (eelse != null) traverse(eelse);
                case TBinop(_, left, right):
                    traverse(left);
                    traverse(right);
                case TUnop(_, _, e):
                    traverse(e);
                case TCall(e, args):
                    traverse(e);
                    for (a in args) traverse(a);
                case TField(e, _):
                    traverse(e);
                case TArray(arrayTarget, arrayIndex):
                    traverse(arrayTarget);
                    traverse(arrayIndex);
                case TReturn(e):
                    if (e != null) traverse(e);
                case TThrow(e):
                    traverse(e);
                case TSwitch(e, cases, edefault):
                    traverse(e);
                    for (c in cases) traverse(c.expr);
                    if (edefault != null) traverse(edefault);
                case TWhile(c, e, _):
                    traverse(c);
                    traverse(e);
                case TFor(_, iterator, body):
                    traverse(iterator);
                    traverse(body);
                case TTry(e, catches):
                    traverse(e);
                    for (catchClause in catches) traverse(catchClause.expr);
                case TMeta(_, inner):
                    traverse(inner);
                case TParenthesis(inner):
                    traverse(inner);
                case TCast(inner, _):
                    traverse(inner);
                case TObjectDecl(fields):
                    for (f in fields) traverse(f.expr);
                case TArrayDecl(el):
                    for (e in el) traverse(e);
                case TNew(_, _, newArgs):
                    for (newArg in newArgs) traverse(newArg);
                default:
            }
        }

        traverse(thenBranch);
        return out;
    }

    /**
     * Check whether a given Haxe local variable name is referenced anywhere in an expression.
     *
     * WHY
     * - When rebuilding `case` patterns for optimized enum switches, we should only bind
     *   names that are actually used in the then-branch to avoid unused-variable warnings.
     */
    static function branchUsesHaxeVarName(expr: TypedExpr, name: String): Bool {
        if (expr == null || name == null || name.length == 0) return false;
        var found = false;

        function traverse(e: TypedExpr): Void {
            if (e == null || found) return;
            switch (e.expr) {
                case TLocal(v) if (v.name == name):
                    found = true;
                case TVar(_, init) if (init != null):
                    traverse(init);
                case TBlock(exprs):
                    for (x in exprs) traverse(x);
                case TIf(c, t, eelse):
                    traverse(c);
                    traverse(t);
                    if (eelse != null) traverse(eelse);
                case TBinop(_, left, right):
                    traverse(left);
                    traverse(right);
                case TUnop(_, _, inner):
                    traverse(inner);
                case TCall(target, args):
                    traverse(target);
                    for (a in args) traverse(a);
                case TField(inner, _):
                    traverse(inner);
                case TArray(arrayTarget, arrayIndex):
                    traverse(arrayTarget);
                    traverse(arrayIndex);
                case TReturn(inner):
                    if (inner != null) traverse(inner);
                case TThrow(inner):
                    traverse(inner);
                case TSwitch(switchTarget, cases, defaultExpr):
                    traverse(switchTarget);
                    for (caseClause in cases) traverse(caseClause.expr);
                    if (defaultExpr != null) traverse(defaultExpr);
                case TWhile(c, body, _):
                    traverse(c);
                    traverse(body);
                case TFor(_, iterator, body):
                    traverse(iterator);
                    traverse(body);
                case TTry(tryExpr, catches):
                    traverse(tryExpr);
                    for (catchClause in catches) traverse(catchClause.expr);
                case TMeta(_, inner):
                    traverse(inner);
                case TParenthesis(inner):
                    traverse(inner);
                case TCast(inner, _):
                    traverse(inner);
                case TObjectDecl(fields):
                    for (f in fields) traverse(f.expr);
                case TArrayDecl(el):
                    for (item in el) traverse(item);
                case TNew(_, _, newArgs):
                    for (newArg in newArgs) traverse(newArg);
                default:
            }
        }

        traverse(expr);
        return found;
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

        inline function isSimpleLiteral(te: TypedExpr): Bool {
            return switch (te.expr) {
                case TConst(TInt(_)) | TConst(TFloat(_)) | TConst(TString(_)) | TConst(TNull) | TConst(TBool(_)): true;
                case _: false;
            };
        }

        // If else branch is another if, prefer cond except when all branches are simple literals
        return switch (eelse.expr) {
            case TIf(_, if2, else2):
                // Keep nested if when then/else are simple literals on both levels
                if (isSimpleLiteral(eif) && isSimpleLiteral(if2) && else2 != null && isSimpleLiteral(else2)) false else true;
            case TBlock([single]) if (single.expr.match(TIf(_, _, _))):
                // Unwrap single block and apply same rule
                switch (single.expr) {
                    case TIf(_, ifb, elseb): if (isSimpleLiteral(eif) && isSimpleLiteral(ifb) && elseb != null && isSimpleLiteral(elseb)) false else true;
                    case _: true;
                }
            default:
                false;
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
        var hasFinalElse = false; // Track if we emitted a final else clause
        
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
                    hasFinalElse = true;
                    break;
            }
        }
        
        // If no else was present, add default true -> nil
        if (!hasFinalElse) {
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
