package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.analyzers.VariableAnalyzer;
import reflaxe.elixir.ast.context.ClauseContext;

private typedef EnumParamBinderRecovery = {
    var binderNames: Array<Null<String>>;
    var extractedVarIds: Array<Null<Int>>;
};

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
        // DISABLED: trace('[ControlFlow] Processing TIf with condition: ${reflaxe.elixir.util.EnumReflection.enumConstructor(econd.expr)}');
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
                var thenBody: ElixirAST = null;
                var recovered: Null<EnumParamBinderRecovery> = null;
                var binderElixirNames: Array<Null<String>> = [for (_ in 0...constructorParams) null];

                #if debug_enum_param_recovery
                function debugPattern(pattern: EPattern): String {
                    return switch (pattern) {
                        case PVar(name):
                            name == null ? "<null>" : name;
                        case PWildcard:
                            "_";
                        case PLiteral(ast):
                            switch (ast.def) {
                                case EAtom(a): ":" + a;
                                default: "lit(" + reflaxe.elixir.util.EnumReflection.enumConstructor(ast.def) + ")";
                            }
                        case PTuple(elements):
                            "{" + [for (e in elements) debugPattern(e)].join(", ") + "}";
                        default:
                            reflaxe.elixir.util.EnumReflection.enumConstructor(pattern);
                    };
                }
                #end

                var pattern: EPattern = if (constructorParams == 0) {
                    // All enums are represented as tagged tuples (including 0-arity constructors),
                    // e.g. `Red` → `{:red}`. Match the tuple shape, not the bare atom.
                    EPattern.PTuple([EPattern.PLiteral(makeAST(EAtom(atomName)))]);
                } else {
                    recovered = extractEnumParamBindersFromThenBranch(eif, enumValue, matchingConstructor, constructorParams, context);
                    var binderPatterns: Array<EPattern> = [];
                    for (paramIndex in 0...constructorParams) {
                        var haxeBinderName: Null<String> = null;
                        if (recovered != null && paramIndex < recovered.binderNames.length) {
                            haxeBinderName = recovered.binderNames[paramIndex];
                        }
                        if ((haxeBinderName == null || haxeBinderName.length == 0) && paramIndex < constructorParamNames.length) {
                            haxeBinderName = constructorParamNames[paramIndex];
                        }

                        // Only bind names that the then-branch actually uses.
                        var binderUsed = haxeBinderName != null && haxeBinderName.length > 0 && branchUsesHaxeVarName(eif, haxeBinderName);
                        #if debug_enum_param_recovery
                        trace('[EnumParamRecovery] chosen binder index=' + paramIndex + ' haxe=' + haxeBinderName + ' used=' + binderUsed);
                        #end
                        if (haxeBinderName == null || haxeBinderName.length == 0 || !binderUsed) {
                            binderPatterns.push(EPattern.PWildcard);
                        } else {
                            var elixirBinderName = VariableAnalyzer.toElixirVarName(haxeBinderName);
                            binderElixirNames[paramIndex] = elixirBinderName;
                            binderPatterns.push(EPattern.PVar(elixirBinderName));
                        }
                    }

                    EPattern.PTuple([EPattern.PLiteral(makeAST(EAtom(atomName)))].concat(binderPatterns));
                };

                #if debug_enum_param_recovery
                trace('[EnumParamRecovery] final pattern ctor=' + matchingConstructor + ' pattern=' + debugPattern(pattern) + ' binders=' + binderElixirNames);
                #end

                // Compile the matching-clause body under a clause context so that:
                // - temp enum extraction vars (_g/_g1/...) resolve to the pattern binders
                // - redundant TEnumParameter and temp→binder assignments are skipped
                var parentCtx = context.getCurrentClauseContext();
                var clauseCtx = new ClauseContext(parentCtx);
                clauseCtx.enumType = enumTypeInfo;
                clauseCtx.patternExtractedParams.push(matchingConstructor);
                for (i in 0...constructorParams) {
                    var name = binderElixirNames[i];
                    if (name == null) {
                        clauseCtx.enumBindingPlan.set(i, { finalName: "_", isUsed: false });
                    } else {
                        clauseCtx.enumBindingPlan.set(i, { finalName: name, isUsed: true });
                    }
                }
                if (constructorParams > 0 && recovered != null) {
                    var bindings:Array<{varId:Int, binderName:String}> = [];
                    for (i in 0...constructorParams) {
                        var id = recovered.extractedVarIds[i];
                        var name = binderElixirNames[i];
                        if (id != null && name != null) {
                            bindings.push({ varId: id, binderName: name });
                        }
                    }
                    if (bindings.length > 0) {
                        clauseCtx.pushPatternBindings(bindings);
                    }
                }
                context.pushClauseContext(clauseCtx);
                thenBody = buildExpression(eif);
                context.popClauseContext();
                
                // Build case clauses
                var clauses = [];
                
                // Matching case
                clauses.push({
                    pattern: pattern,
                    guard: null,  // No guards for this case
                    body: thenBody
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
     * - Traverse the then-branch and capture `TVar(name, TEnumParameter(scrutinee, ef, index))` where:
     *   - `scrutinee` matches the enum value used in the `TEnumIndex(scrutinee) == N` condition
     *   - `ef.name` matches the constructor name
     *   mapping `index -> name`.
     */
	    static function extractEnumParamBindersFromThenBranch(thenBranch: TypedExpr, enumScrutinee: TypedExpr, constructorName: String, paramCount: Int, context: CompilationContext): EnumParamBinderRecovery {
	        var out: Array<Null<String>> = [for (_ in 0...paramCount) null];
        // Track the first local ID that received the extracted parameter for each index.
        // This lets us prefer a subsequent alias assignment (binder = extracted_temp) as the
        // actual binder name without accidentally chasing unrelated locals.
        var extractedIdByIndex: Array<Null<Int>> = [for (_ in 0...paramCount) null];

        function unwrapNoOpWrappers(expr: TypedExpr): TypedExpr {
            var cur = expr;
            while (cur != null) {
                switch (cur.expr) {
                    case TParenthesis(inner):
                        cur = inner;
                        continue;
                    case TMeta(_, inner):
                        cur = inner;
                        continue;
                    case TCast(inner, _):
                        cur = inner;
                        continue;
                    default:
                }
                break;
            }
            return cur;
        }

        function rememberExtraction(index: Int, v: TVar): Void {
            if (index < 0 || index >= paramCount) return;
            if (extractedIdByIndex[index] == null) {
                extractedIdByIndex[index] = v.id;
            }
        }

        #if debug_enum_param_recovery
        var scrutineeDebug = switch (enumScrutinee.expr) {
            case TLocal(v): v.name + "#" + v.id;
            default: reflaxe.elixir.util.EnumReflection.enumConstructor(enumScrutinee.expr);
        };
        trace('[EnumParamRecovery] ctor=' + constructorName + ' scrutinee=' + scrutineeDebug + ' paramCount=' + paramCount);
        #end

        function resolveInfraScrutinee(expr: TypedExpr): TypedExpr {
            // Map infrastructure locals (g/_g/etc.) back to their substituted expression when available.
            var cur = unwrapNoOpWrappers(expr);
            if (context != null && context.infraVarSubstitutions != null) {
                switch (cur.expr) {
                    case TLocal(v) if (context.infraVarSubstitutions.exists(v.id)):
                        return unwrapNoOpWrappers(context.infraVarSubstitutions.get(v.id));
                    default:
                }
            }
            return cur;
        }

        function scrutineeMatches(sourceExpr: TypedExpr): Bool {
            var left = resolveInfraScrutinee(enumScrutinee);
            var right = resolveInfraScrutinee(sourceExpr);

            // Fast path: both locals with same ID.
            switch (left.expr) {
                case TLocal(va):
                    switch (right.expr) {
                        case TLocal(vb): return va.id == vb.id;
                        default:
                    }
                default:
            }

            // Conservative structural equality for the common access shapes.
            function eq(a: TypedExpr, b: TypedExpr): Bool {
                if (a == null || b == null) return false;
                var aa = unwrapNoOpWrappers(a);
                var bb = unwrapNoOpWrappers(b);
                return switch (aa.expr) {
                    case TLocal(va):
                        switch (bb.expr) { case TLocal(vb): va.id == vb.id; default: false; }
                    case TField(oa, fa):
                        switch (bb.expr) {
                            case TField(ob, fb):
                                // Match field names; ignore resolution differences across fa variants.
                                var nameA = switch (fa) {
                                    case FInstance(_, _, cf): cf.get().name;
                                    case FStatic(_, cf): cf.get().name;
                                    case FAnon(cf): cf.get().name;
                                    case FDynamic(s): s;
                                    default: null;
                                };
                                var nameB = switch (fb) {
                                    case FInstance(_, _, cf2): cf2.get().name;
                                    case FStatic(_, cf2): cf2.get().name;
                                    case FAnon(cf2): cf2.get().name;
                                    case FDynamic(s2): s2;
                                    default: null;
                                };
                                nameA != null && nameB != null && nameA == nameB && eq(oa, ob);
                            default:
                                false;
                        }
                    default:
                        false;
                };
            }

            return eq(left, right);
        }

	        function tryPromoteAlias(targetVar: TVar, initExpr: TypedExpr): Bool {
	            var initUnwrapped = unwrapNoOpWrappers(initExpr);
	            return switch (initUnwrapped.expr) {
	                case TLocal(src):
                    // If this assignment aliases a previously-extracted param temp, promote the alias name.
                    var matched = false;
                    for (index in 0...paramCount) {
                        if (extractedIdByIndex[index] != null && extractedIdByIndex[index] == src.id) {
                            if (out[index] == null || out[index] == src.name) {
                                out[index] = targetVar.name;
                            }
                            matched = true;
                            #if debug_enum_param_recovery
                            trace('[EnumParamRecovery] alias by extractedId index=' + index + ' target=' + targetVar.name + '#' + targetVar.id + ' src=' + src.name + '#' + src.id + ' out=' + out[index]);
                            #end
                            break;
                        }
                    }

                    // If the temp extraction statement was removed by the TypedExpr preprocessor,
                    // we won't have seen it in this traversal. Recover the index by consulting the
                    // preprocessor substitution map (tempVar.id -> original extraction expr).
	                    if (!matched && context != null && context.infraVarSubstitutions != null && context.infraVarSubstitutions.exists(src.id)) {
	                        var subst = unwrapNoOpWrappers(context.infraVarSubstitutions.get(src.id));
	                        switch (subst.expr) {
	                            case TEnumParameter(source, ef, index)
	                                if (ef != null
	                                    && ef.name == constructorName
	                                    && index >= 0
	                                    && index < paramCount
	                                    && scrutineeMatches(source)
	                                ):
	                                if (out[index] == null || out[index] == src.name) {
	                                    out[index] = targetVar.name;
	                                }
	                                // Record the temp ID so subsequent alias steps can reuse it.
	                                rememberExtraction(index, src);
	                                matched = true;
	                                #if debug_enum_param_recovery
	                                trace('[EnumParamRecovery] alias by substitution index=' + index + ' target=' + targetVar.name + '#' + targetVar.id + ' src=' + src.name + '#' + src.id + ' out=' + out[index]);
	                                #end
	                            case TArray(source, indexExpr):
	                                var idxU = unwrapNoOpWrappers(indexExpr);
	                                switch (idxU.expr) {
	                                    case TConst(TInt(i))
	                                        if (i >= 0 && i < paramCount && scrutineeMatches(source)):
	                                        if (out[i] == null || out[i] == src.name) {
	                                            out[i] = targetVar.name;
	                                        }
	                                        rememberExtraction(i, src);
	                                        matched = true;
	                                        #if debug_enum_param_recovery
	                                        trace('[EnumParamRecovery] alias by substitution index=' + i + ' target=' + targetVar.name + '#' + targetVar.id + ' src=' + src.name + '#' + src.id + ' out=' + out[i]);
	                                        #end
	                                    default:
	                                }
	                            default:
	                        }
	                    }

                    matched;
                default:
                    false;
            };
        }

	        function unwrapEnumParameter(expr: TypedExpr): Null<{ ctorName: String, index: Int, source: TypedExpr }> {
	            var cur = unwrapNoOpWrappers(expr);
	            return switch (cur.expr) {
	                case TEnumParameter(source, ef, index):
	                    { ctorName: ef.name, index: index, source: source };
	                case TArray(source, indexExpr):
	                    // Enum-index switch lowering can emit payload extraction as an index access:
	                    //   var _g = scrutinee[0];
	                    // Treat `scrutinee[i]` as "parameter i" for the currently matched constructor.
	                    var idxU = unwrapNoOpWrappers(indexExpr);
	                    switch (idxU.expr) {
	                        case TConst(TInt(i)): { ctorName: constructorName, index: i, source: source };
	                        default: null;
	                    }
	                default:
	                    null;
	            };
	        }

	        function traverse(expr: TypedExpr): Void {
	            if (expr == null) return;

	            switch (expr.expr) {
	                case TVar(v, init) if (init != null):
                    var info = unwrapEnumParameter(init);
                    if (info != null
                        && info.ctorName == constructorName
                        && info.index >= 0
                        && info.index < paramCount
                        && scrutineeMatches(info.source)
                    ) {
                        out[info.index] = v.name;
                        rememberExtraction(info.index, v);
                        #if debug_enum_param_recovery
                        var srcDbg = switch (info.source.expr) { case TLocal(sv): sv.name + "#" + sv.id; default: reflaxe.elixir.util.EnumReflection.enumConstructor(info.source.expr); };
                        trace('[EnumParamRecovery] extract index=' + info.index + ' v=' + v.name + '#' + v.id + ' source=' + srcDbg);
                        #end
                    } else {
                        // Also handle the common pattern:
                        //   var tmp = TEnumParameter(scrutinee, Ctor, idx);
                        //   var binder = tmp;
                        // Promote binder as the recovered name for idx.
                        tryPromoteAlias(v, init);
	                    }
	                    traverse(init);
	                case TBinop(OpAssign, lhs, rhs):
	                    // Some lowering emits aliases as assignments instead of TVar initializers.
	                    switch (lhs.expr) {
	                        case TLocal(v):
	                            var info = unwrapEnumParameter(rhs);
	                            if (info != null
	                                && info.ctorName == constructorName
	                                && info.index >= 0
	                                && info.index < paramCount
	                                && scrutineeMatches(info.source)
	                            ) {
	                                out[info.index] = v.name;
	                                extractedIdByIndex[info.index] = v.id;
	                            } else {
	                                tryPromoteAlias(v, rhs);
	                            }
	                        default:
	                    }
	                    traverse(rhs);
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
        #if debug_enum_param_recovery
        trace('[EnumParamRecovery] result names=' + out + ' ids=' + extractedIdByIndex);
        #end
        return { binderNames: out, extractedVarIds: extractedIdByIndex };
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
