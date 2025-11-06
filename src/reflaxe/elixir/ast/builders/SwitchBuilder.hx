package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import haxe.macro.Expr;
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ECaseClause;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.context.ClauseContext;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.NameUtils;
import reflaxe.elixir.ast.analyzers.VariableAnalyzer;

using StringTools;

/**
 * SwitchBuilder: Handles switch/case pattern matching transformations
 * 
 * WHY: Separates complex switch logic from ElixirASTBuilder
 * - Reduces ElixirASTBuilder complexity (500+ lines of switch handling)
 * - Centralizes pattern matching transformations
 * - Manages infrastructure variable tracking for desugared switches
 * - Handles enum destructuring and pattern extraction
 * 
 * WHAT: Builds ElixirAST case expressions from Haxe switch statements
 * - TSwitch expressions with enum patterns
 * - Infrastructure variable management (_g, g, g1, etc.)
 * - Pattern extraction and variable binding
 * - Default case handling
 * - Nested switch support with ClauseContext
 * 
 * HOW: Pattern-based switch compilation with context tracking
 * - Detects desugared switch patterns from Haxe
 * - Creates ClauseContext for variable scoping
 * - Generates idiomatic case expressions
 * - Handles enum parameter extraction
 * - Manages pattern variable naming
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on switch/case
 * - Open/Closed Principle: Can extend pattern matching without modifying core
 * - Testability: Switch logic can be tested independently
 * - Maintainability: Clear boundaries for pattern matching code
 * - Performance: Optimized pattern detection and transformation
 * 
 * EDGE CASES:
 * - Direct field switches (rare, should be desugared)
 * - Infrastructure variable switches (_g from desugaring)
 * - Nested switch expressions
 * - Empty case bodies
 * - Complex enum patterns with multiple parameters
 */
@:nullSafety(Off)
class SwitchBuilder {
    static function cleanupTempBinderAliases(body: ElixirAST): ElixirAST {
        // Remove statements like `lhs = _g*` or `lhs = g*` inside blocks
        function isInfraTemp(name:String):Bool {
            if (name == null || name.length == 0) return false;
            if (name.charAt(0) == "_") name = name.substr(1);
            if (name == "g") return true;
            if (name.charAt(0) == "g") {
                for (i in 1...name.length) {
                    var c = name.charCodeAt(i);
                    if (c < '0'.code || c > '9'.code) return false;
                }
                return true;
            }
            return false;
        }

        switch (body.def) {
            case EBlock(stmts):
                var filtered:Array<ElixirAST> = [];
                for (s in stmts) {
                    var drop = false;
                    switch (s.def) {
                        case EBinary(Match, left, right):
                            switch (right.def) { case EVar(rn) if (isInfraTemp(rn)): drop = true; default: }
                        case EMatch(pat, rhs):
                            switch (rhs.def) { case EVar(rn) if (isInfraTemp(rn)): drop = true; default: }
                        default:
                    }
                    if (!drop) filtered.push(s);
                }
                return {def: EBlock(filtered), metadata: body.metadata, pos: body.pos};
            default:
                return body;
        }
    }
    
    /**
     * Build switch/case expression
     * 
     * WHY: Switch statements are central to pattern matching in functional languages
     * WHAT: Converts TSwitch to Elixir case expression
     * HOW: Analyzes patterns, creates clause context, generates case clauses
     * 
     * @param e The expression being switched on
     * @param cases Array of switch cases
     * @param edef Default case expression
     * @param context Build context with compilation state
     * @return ElixirASTDef for the case expression
     */
    public static function build(e: TypedExpr, cases: Array<{values:Array<TypedExpr>, expr:TypedExpr}>, edef: Null<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {

        // DEBUG: Log ALL switch compilations
        #if debug_switch_builder
        trace('[SwitchBuilder START] Compiling switch at ${e.pos}');
        trace('[SwitchBuilder START] Switch target: ${Type.enumConstructor(e.expr)}');
        #end

        // CRITICAL: Detect TEnumIndex optimization and recover enum type
        // This is the KEY to eliminating integer-based switch cases!
        var enumType: Null<EnumType> = null;
        var isEnumIndexSwitch = false;
        var actualSwitchExpr = e;

        // Look inside TParenthesis and TMeta wrappers to find actual expression
        var innerExpr = e;
        switch(e.expr) {
            case TParenthesis(innerE):
                innerExpr = innerE;
                // Check for TMeta inside
                switch(innerExpr.expr) {
                    case TMeta(_, metaE):
                        innerExpr = metaE;
                    default:
                }
            default:
        }

        switch(innerExpr.expr) {
            case TEnumIndex(enumExpr):
                // Haxe optimizer converted enum pattern matching to integer index comparison

                isEnumIndexSwitch = true;
                actualSwitchExpr = enumExpr;  // Switch on actual enum value, not index

                // Extract enum type from the expression
                enumType = getEnumTypeFromExpression(enumExpr);
                if (enumType != null) {
                } else {
                }
            default:

                // ALTERNATIVE: Check if integer case patterns with enum target type
                enumType = getEnumTypeFromExpression(innerExpr);
                if (enumType != null) {
                    isEnumIndexSwitch = true;
                    actualSwitchExpr = innerExpr;
                }
        }

        // Track switch target for infrastructure variable management
        var targetVarName = extractTargetVarName(actualSwitchExpr);

        // DEBUG: Output switch target info
        #if debug_switch_builder
        trace('[SwitchBuilder DEBUG] Switch target expression type: ${Type.enumConstructor(actualSwitchExpr.expr)}');
        if (targetVarName != null) {
            trace('[SwitchBuilder DEBUG] Extracted variable name: ${targetVarName}');
            trace('[SwitchBuilder DEBUG] Is infrastructure var: ${isInfrastructureVar(targetVarName)}');
        }
        if (targetVarName != null && isInfrastructureVar(targetVarName)) {
            trace('[SwitchBuilder DEBUG] Infrastructure variable detected but not handled!');
        }
        #end

        // Build the switch target expression (use actual enum, not index)
        var targetAST = if (context.compiler != null) {
            // Apply infrastructure variable substitution before re-compilation
            var substitutedTarget = context.substituteIfNeeded(actualSwitchExpr);
            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(substitutedTarget, context);
            #if debug_switch_builder
            trace('[SwitchBuilder DEBUG] Compiled target AST: ${Type.enumConstructor(result.def)}');
            // DEBUG: Show exact variable name if it's EVar
            switch(result.def) {
                case EVar(name):
                    trace('[SwitchBuilder DEBUG] EVar variable name: "${name}"');
                default:
            }
            #end
            result;
        } else {
            return null;  // Can't proceed without compiler
        }

        if (targetAST == null) {
            trace('[SwitchBuilder ERROR] Target AST compilation returned null!');
            return null;
        }

        // Store the old clause context; per-clause contexts will be pushed for each arm
        var oldClauseContext = context.currentClauseContext;
        
        // Build case clauses (may generate multiple clauses per case due to guard chains)
        var caseClauses: Array<ECaseClause> = [];

        for (i in 0...cases.length) {
            var switchCase = cases[i];
            #if debug_switch_builder
            trace('[SwitchBuilder] Building case ${i + 1}/${cases.length}');
            #end
            var clausesFromCase = buildCaseClause(switchCase, targetVarName, context, i, enumType);
            if (clausesFromCase.length > 0) {
                #if debug_switch_builder
                trace('[SwitchBuilder]   Generated ${clausesFromCase.length} clause(s) from this case');
                #end
                for (clause in clausesFromCase) {
                    caseClauses.push(clause);
                }
            } else {
                #if debug_switch_builder
                trace('[SwitchBuilder]   Case clause build returned empty array!');
                #end
            }
        }
        
        // Add default case if present
        if (edef != null) {
            var defaultBody = if (context.compiler != null) {
                // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(edef, context);
            } else {
                null;
            }
            
            if (defaultBody != null) {
                caseClauses.push({
                    pattern: PWildcard,  // _ pattern matches anything
                    guard: null,
                    body: defaultBody
                });
            }
        }
        
        // Restore previous clause context
        context.currentClauseContext = oldClauseContext;
        
        // Repair inner case scrutinees in clause bodies using binder metadata
        if (caseClauses.length > 0) {
            var repaired:Array<ECaseClause> = [];
            for (cl in caseClauses) {
                var binder: Null<String> = null;
                if (cl.body != null && cl.body.metadata != null) {
                    // Use binder computed during case building when available
                    binder = try {
                        untyped cl.body.metadata.primaryCaseBinder; 
                    } catch (e:Dynamic) {
                        null;
                    }
                }
                if (binder == null) {
                    // Fallback: derive from pattern shape
                    binder = selectPrimaryBinder(cl.pattern);
                }
                var newBody = cl.body;
                // Strategy A: when original target var name is known, replace that scrutinee
                if (targetVarName != null && binder != null && binder != targetVarName) {
                    newBody = rewriteInnerCaseScrutinee(newBody, targetVarName, binder);
                }
                // Strategy B: regardless of target var, replace infra-temp scrutinee (g/_g/gN) with binder
                if (binder != null) {
                    newBody = rewriteInnerCaseScrutineeInfra(newBody, binder);
                }
                repaired.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
            }
            caseClauses = repaired;
        }

        // Generate case expression
        if (caseClauses.length == 0) {
            #if debug_ast_builder
            trace('[SwitchBuilder] No case clauses generated');
            #end
            return null;
        }
        
        return ECase(targetAST, caseClauses);
    }
    
    /**
     * Build case clause(s) - may return multiple clauses for guard chains
     *
     * WHY: Each switch case needs proper pattern extraction and body compilation
     *      Guard chains (multiple if-else) should generate separate when clauses
     * WHAT: Creates one or more ECaseClause with pattern, optional guard, and body
     * HOW: Analyzes case values, extracts patterns, detects guard chains, compiles bodies
     */
    static function buildCaseClause(
        switchCase: {values:Array<TypedExpr>, expr:TypedExpr},
        targetVarName: String,
        context: CompilationContext,
        caseIndex: Int,
        enumTypeForSwitch: Null<EnumType>
    ): Array<ECaseClause> {
        // Per-clause ClauseContext for proper binding and usage tracking
        var parentCtx = context.getCurrentClauseContext();
        var clauseCtx = new ClauseContext(parentCtx);
        if (enumTypeForSwitch != null) clauseCtx.enumType = enumTypeForSwitch;
        context.pushClauseContext(clauseCtx);
        // Handle multiple values in one case (fall-through pattern)
        if (switchCase.values.length == 0) {
            context.popClauseContext();
            return [];
        }

        // For now, handle single value cases (most common)
        // TODO: Handle multiple values with pattern alternatives
        var value = switchCase.values[0];

        // OPTIMIZATION: Flatten "Option.Some(param) with inner switch(param)" into a single
        // top-level case with nested enum pattern, e.g.:
        //   case Some(x): switch(x) { case TodoCreated(todo): ... }
        // becomes
        //   case {:some, {:todo_created, todo}} -> ...
        function isOptionSomeCall(v: TypedExpr): { isSome:Bool, param:Null<TypedExpr> } {
            return switch (v.expr) {
                case TCall(ctorExpr, args) if (args != null && args.length == 1):
                    switch (ctorExpr.expr) {
                        case TField(_, FEnum(_, ef)):
                            ef != null && ef.name == "Some" ? { isSome: true, param: args[0] } : { isSome: false, param: null };
                        default:
                            { isSome: false, param: null };
                    }
                default:
                    { isSome: false, param: null };
            };
        }

        function findNestedSwitchOnVar(e: TypedExpr, varName: String): Null<{ cases:Array<{values:Array<TypedExpr>, expr:TypedExpr}>, edef:Null<TypedExpr> } > {
            if (e == null) return null;
            return switch (e.expr) {
                case TSwitch(scrutinee, innerCases, innerDefault):
                    switch (scrutinee.expr) {
                        case TLocal(v) if (v.name == varName): { cases: innerCases, edef: innerDefault };
                        default: null;
                    }
                case TBlock(exprs):
                    // Search within block statements
                    var hit: Null<{ cases:Array<{values:Array<TypedExpr>, expr:TypedExpr}>, edef:Null<TypedExpr> }> = null;
                    for (ex in exprs) {
                        hit = findNestedSwitchOnVar(ex, varName);
                        if (hit != null) return hit;
                    }
                    null;
                case TMeta(_, inner):
                    findNestedSwitchOnVar(inner, varName);
                case TParenthesis(inner):
                    findNestedSwitchOnVar(inner, varName);
                default:
                    null;
            };
        }

        #if enable_nested_switch_flatten
        // Attempt flattening when matching Option.Some(var) and body switches on that var
        var someInfo = isOptionSomeCall(value);
        if (someInfo.isSome) {
            // Determine the parameter variable name if it is a simple local; otherwise skip flatten
            var paramVarName: Null<String> = switch (someInfo.param.expr) {
                case TLocal(v): v.name;
                case TParenthesis(inner):
                    switch (inner.expr) { case TLocal(v2): v2.name; default: null; }
                default: null;
            };
            if (paramVarName != null) {
                var nested = findNestedSwitchOnVar(switchCase.expr, paramVarName);
                if (nested != null) {
                    // Build flattened clauses: for each inner case value, create {:some, <nestedPattern>} -> innerBody
                    var flattened: Array<ECaseClause> = [];
                    for (ic in nested.cases) {
                        if (ic.values == null || ic.values.length == 0) continue;
                        var innerVal = ic.values[0];
                        // Build nested pattern for the inner enum constructor
                        var nestedPattern = buildPattern(innerVal, paramVarName, [], ic.expr, context);
                        if (nestedPattern != null) {
                            var combined: EPattern = PTuple([
                                PLiteral(makeAST(EAtom("some"))),
                                nestedPattern
                            ]);
                            var bodyAst = context.compiler != null ? reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(ic.expr, context) : null;
                            if (bodyAst != null) flattened.push({ pattern: combined, guard: null, body: bodyAst });
                        }
                    }
                    // Handle inner default: {:some, _} -> defaultBody
                    if (nested.edef != null) {
                        var defaultBodyAst = context.compiler != null ? reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(nested.edef, context) : null;
                        if (defaultBodyAst != null) {
                            flattened.push({ pattern: PTuple([ PLiteral(makeAST(EAtom("some"))), PWildcard ]), guard: null, body: defaultBodyAst });
                        }
                    }
                    if (flattened.length > 0) {
                        return flattened;
                    }
                }
            }
        }
        #end

        // CRITICAL FIX: Extract variable names from CASE BODY, not pattern or guard!
        // After TEnumIndex optimization: pattern=TConst(0), NO variable names!
        // The user's variable "action" is in the case BODY where it's used
        // This is the ONLY way to recover the correct variable name after TEnumIndex
        trace('[SwitchBuilder] ====== PATTERN ANALYSIS ======');
        trace('[SwitchBuilder] Pattern expr type: ${Type.enumConstructor(value.expr)}');

        // NEW FIX: Extract variables from case body (where they're actually used)
        var patternVars = extractUsedVariablesFromCaseBody(switchCase.expr);

        #if debug_enum_extraction
        trace('[SwitchBuilder] Extracted ${patternVars.length} variables from case body: [${patternVars.join(", ")}]');
        #end

        // CRITICAL: Extract TLocal IDs from guard and register in ClauseContext.localToName
        // This ensures guard expressions compile with the same variable names as patterns
        // Without this, guards get different names (n, n2, n3) due to independent TLocal instances
        // NOTE: VariableBuilder.resolveVariableName() checks ClauseContext.lookupVariable() first
        var tvarMapping = extractTLocalIDsFromGuard(switchCase.expr, patternVars);

        #if debug_guard_compilation
        var mappingCount = Lambda.count(tvarMapping);
        trace('[SwitchBuilder] Current ClauseContext: ${context.currentClauseContext != null ? "EXISTS" : "NULL"}');
        trace('[SwitchBuilder] Registering $mappingCount TLocal mapping(s) in ClauseContext.localToName:');
        #end

        if (context.currentClauseContext != null) {
            for (tvarId in tvarMapping.keys()) {
                var name = tvarMapping.get(tvarId);
                #if debug_guard_compilation
                trace('[SwitchBuilder]   TLocal#${tvarId} → ${name}');
                #end
                context.currentClauseContext.localToName.set(tvarId, name);
            }
        } #if debug_guard_compilation else {
            trace('[SwitchBuilder ERROR] ClauseContext is NULL - cannot register mappings!');
        } #end

        // Build pattern from case value (pass pattern variables and case body for usage analysis)
        var pattern = buildPattern(value, targetVarName, patternVars, switchCase.expr, context);
        if (pattern == null) {
            context.popClauseContext();
            return [];
        }

        // Compute and store the primary binder for this clause
        clauseCtx.primaryCaseBinder = selectPrimaryBinder(pattern);

        // ENHANCED GUARD CHAIN DETECTION: Extract ALL guards from if-else chain
        var clauses: Array<ECaseClause> = [];

        if (switchCase.expr != null) {
            // Haxe may wrap guard clauses in TBlock - unwrap if needed
            var exprToCheck = switchCase.expr;
            switch(switchCase.expr.expr) {
                case TBlock(exprs):
                    // Search for TIf in the block
                    for (expr in exprs) {
                        if (Type.enumConstructor(expr.expr) == "TIf") {
                            exprToCheck = expr;
                            break;
                        }
                    }
                default:
                    // Not wrapped in block
            }

            // Extract all guards from the if-else chain
            clauses = extractGuardChain(exprToCheck, pattern, context, clauseCtx.primaryCaseBinder, switchCase.expr);
        }

        // If no guards detected, create single clause without guard
        if (clauses.length == 0) {
            var body = if (switchCase.expr != null && context.compiler != null) {
                var substitutedBody = context.substituteIfNeeded(switchCase.expr);
                reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(substitutedBody, context);
            } else {
                null;
            };

            if (body != null) {
                // Attach clause-local metadata to aid late binder harmonization:
                // - primaryCaseBinder (selected from pattern)
                // - usedLocalsFromTyped (names discovered from TypedExpr case body)
                var usedTyped:Array<String> = collectUsedLowerLocalsTyped(switchCase.expr);
                var annotated = body;
                try {
                    var meta:Dynamic = annotated.metadata;
                    if (meta == null) meta = {};
                    if (clauseCtx != null && clauseCtx.primaryCaseBinder != null) {
                        untyped meta.primaryCaseBinder = clauseCtx.primaryCaseBinder;
                    }
                    untyped meta.usedLocalsFromTyped = usedTyped;
                    annotated = makeASTWithMeta(annotated.def, meta, annotated.pos);
                } catch (e:Dynamic) {}

                var cleanedBody = cleanupTempBinderAliases(annotated);
                clauses.push({
                    pattern: pattern,
                    guard: null,
                    body: cleanedBody
                });
            }
        }

        return clauses;
    }

    /**
     * Collect lower-case local variable names used in a TypedExpr case body.
     * Excludes common env names (socket/live_socket) and prefers simple locals.
     */
    static function collectUsedLowerLocalsTyped(caseBodyExpr: TypedExpr): Array<String> {
        var names = new Map<String,Bool>();
        function walk(e: TypedExpr): Void {
            if (e == null) return;
            switch (e.expr) {
                case TLocal(v):
                    var n = v.name;
                    if (n != null && n.length > 0) {
                        var c = n.charAt(0);
                        if (c.toLowerCase() == c && n != "socket" && n != "live_socket" && n != "liveSocket") names.set(n, true);
                    }
                default:
            }
            TypedExprTools.iter(e, walk);
        }
        walk(caseBodyExpr);
        return [for (k in names.keys()) k];
    }

    /**
     * Extract all guards from an if-else chain
     *
     * WHY: Haxe merges multiple guard clauses into nested if-else before TypedExpr
     *      We need to reconstruct the original guard clauses for idiomatic Elixir
     * WHAT: Traverses if-else chain and creates separate clause for each condition
     * HOW: Recursively walks TIf else-branches, extracting each condition as a guard
     *
     * Example:
     *   TIf(n > 0, "pos", TIf(n < 0, "neg", "zero"))
     *   →
     *   [{guard: n > 0, body: "pos"}, {guard: n < 0, body: "neg"}, {guard: null, body: "zero"}]
     */
    static function extractGuardChain(expr: TypedExpr, pattern: EPattern, context: CompilationContext, primaryBinder: Null<String>, originalCaseBody: TypedExpr): Array<ECaseClause> {
        var clauses: Array<ECaseClause> = [];
        var current = expr;

        trace('[GuardChain] Starting extraction, expr type: ${Type.enumConstructor(current.expr)}');

        // Traverse the if-else chain
        while (true) {
            switch(current.expr) {
                case TIf(econd, eif, eelse):
                    trace('[GuardChain] Found TIf - extracting guard');
                    // Extract guard condition
                    var guard = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(econd, context);

                    // Compile then-branch as body and clean temp→binder aliases
                    var substitutedBody = context.substituteIfNeeded(eif);
                    var rawBody = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(substitutedBody, context);
                    // Annotate with clause-local metadata to aid late passes
                    var metaBody = (function(b:ElixirAST){
                        try {
                            var meta:Dynamic = b.metadata;
                            if (meta == null) meta = {};
                            if (primaryBinder != null) untyped meta.primaryCaseBinder = primaryBinder;
                            untyped meta.usedLocalsFromTyped = collectUsedLowerLocalsTyped(originalCaseBody);
                            return makeASTWithMeta(b.def, meta, b.pos);
                        } catch (e:Dynamic) { return b; }
                    })(rawBody);
                    var body = cleanupTempBinderAliases(metaBody);

                    // Create clause with guard
                    clauses.push({
                        pattern: pattern,
                        guard: guard,
                        body: body
                    });
                    trace('[GuardChain]   Created clause with guard');

                    // Continue with else-branch (may be another TIf or final value)
                    if (eelse != null) {
                        trace('[GuardChain]   Else-branch type: ${Type.enumConstructor(eelse.expr)}');

                        // Unwrap TBlock to find nested TIf
                        var nextExpr = eelse;
                        switch(eelse.expr) {
                            case TBlock(exprs):
                                trace('[GuardChain]   Unwrapping TBlock with ${exprs.length} expressions');
                                // Search for TIf in the block
                                for (expr in exprs) {
                                    if (Type.enumConstructor(expr.expr) == "TIf") {
                                        trace('[GuardChain]   Found TIf inside TBlock');
                                        nextExpr = expr;
                                        break;
                                    }
                                }
                            default:
                                // Not a TBlock, use as-is
                        }

                        current = nextExpr;
                    } else {
                        trace('[GuardChain]   No else-branch, stopping');
                        break;
                    }

                default:
                    trace('[GuardChain] Not a TIf (type: ${Type.enumConstructor(current.expr)}), creating final clause');
                    // Reached final else (not a TIf) - create clause without guard
                    var substitutedBody = context.substituteIfNeeded(current);
                    var rawBody = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(substitutedBody, context);
                    var metaBody2 = (function(b:ElixirAST){
                        try {
                            var meta:Dynamic = b.metadata;
                            if (meta == null) meta = {};
                            if (primaryBinder != null) untyped meta.primaryCaseBinder = primaryBinder;
                            untyped meta.usedLocalsFromTyped = collectUsedLowerLocalsTyped(originalCaseBody);
                            return makeASTWithMeta(b.def, meta, b.pos);
                        } catch (e:Dynamic) { return b; }
                    })(rawBody);
                    var body = cleanupTempBinderAliases(metaBody2);

                    clauses.push({
                        pattern: pattern,
                        guard: null,
                        body: body
                    });
                    break;
            }
        }

        // Annotate clause bodies with the computed binder and apply clause-local binder harmonization
        var _cctx = context.getCurrentClauseContext();
        if (_cctx != null && _cctx.primaryCaseBinder != null) {
            var annotated:Array<ECaseClause> = [];
            for (cl in clauses) {
                var harmonized = cl;
                // If pattern is {:tag, PVar(binder)} and the body clearly uses one undefined local,
                // rename the binder to that local (usage-driven, per clause).
                switch (cl.pattern) {
                    case PTuple(es) if (es.length == 2):
                        switch (es[0]) {
                            case PLiteral(_):
                                switch (es[1]) {
                                    case PVar(bn):
                                        var declared = new Map<String,Bool>();
                                        function patDecl(p:EPattern):Void {
                                            switch (p) { case PVar(n): declared.set(n,true); case PTuple(ps) | PList(ps): for (pp in ps) patDecl(pp); case PCons(h,t): patDecl(h); patDecl(t); case PMap(kvs): for (kv in kvs) patDecl(kv.value); case PStruct(_,fs): for (f in fs) patDecl(f.value); case PPin(inner): patDecl(inner); default: }
                                        }
                                        patDecl(cl.pattern);
                                        reflaxe.elixir.ast.ElixirASTTransformer.transformNode(cl.body, function(n:ElixirAST):ElixirAST {
                                            switch (n.def) { case EMatch(p,_): patDecl(p); case EBinary(Match, {def: EVar(lhs)}, _): declared.set(lhs, true); default: }
                                            return n;
                                        });
                                        var used = new Map<String,Bool>();
                                        reflaxe.elixir.ast.ElixirASTTransformer.transformNode(cl.body, function(n:ElixirAST):ElixirAST {
                                            switch (n.def) { case EVar(v): if (v != null && v.length > 0 && v.charAt(0).toLowerCase() == v.charAt(0)) used.set(v,true); default: }
                                            return n;
                                        });
                                        var undef:Array<String> = [];
                                        for (k in used.keys()) if (!declared.exists(k) && k != bn) undef.push(k);
                                        if (undef.length == 1) {
                                            var newName = undef[0];
                                            harmonized = { pattern: PTuple([es[0], PVar(newName)]), guard: cl.guard,
                                                body: reflaxe.elixir.ast.ElixirASTTransformer.transformNode(cl.body, function(x:ElixirAST):ElixirAST {
                                                    return switch (x.def) { case EVar(v) if (v == bn): makeASTWithMeta(EVar(newName), x.metadata, x.pos); default: x; };
                                                }) };
                                        }
                                    default:
                                }
                            default:
                        }
                    default:
                }
                var b = harmonized.body;
                if (b != null) {
                    if (b.metadata == null) b.metadata = {};
                    untyped b.metadata.primaryCaseBinder = _cctx.primaryCaseBinder; // store for outer repair
                }
                annotated.push(harmonized);
            }
            clauses = annotated;
        }

        trace('[GuardChain] Extracted ${clauses.length} total clauses');
        context.popClauseContext();
        return clauses;
    }

    /**
     * Choose primary binder variable for a case pattern.
     * Preference: first variable in the tagged payload (PTuple {:tag, payload})
     * Fallback: first variable anywhere in the pattern (alias > var > nested).
     */
    static function selectPrimaryBinder(p: EPattern): Null<String> {
        function firstVar(pt:EPattern):Null<String> {
            return switch (pt) {
                case PAlias(nm, _): nm;
                case PVar(nm): nm;
                case PPin(inner): firstVar(inner);
                case PTuple(es):
                    for (e in es) {
                        var v = firstVar(e);
                        if (v != null) return v;
                    }
                    null;
                case PList(es):
                    for (e in es) {
                        var v = firstVar(e);
                        if (v != null) return v;
                    }
                    null;
                case PCons(h, t):
                    var v1 = firstVar(h);
                    if (v1 != null) v1 else firstVar(t);
                case PMap(kvs):
                    for (kv in kvs) {
                        var v = firstVar(kv.value);
                        if (v != null) return v;
                    }
                    null;
                case PStruct(_, fs):
                    for (f in fs) {
                        var v = firstVar(f.value);
                        if (v != null) return v;
                    }
                    null;
                default:
                    null;
            };
        }

        switch (p) {
            case PTuple(es) if (es.length >= 2):
                switch (es[0]) {
                    case PLiteral(ast):
                        switch (ast.def) {
                            case EAtom(_):
                                var pv = firstVar(es[1]);
                                if (pv != null) return pv;
                            default:
                        }
                    default:
                }
            default:
        }
        return firstVar(p);
    }

    /**
     * Recursively rewrite any inner case scrutinee `case oldName ->` to `case newName ->`.
     */
    static function rewriteInnerCaseScrutinee(body: ElixirAST, oldName:String, newName:String): ElixirAST {
        return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                case ECase(scrut, cls):
                    var nscrut = switch (scrut.def) {
                        case EVar(v) if (v == oldName): { def: EVar(newName), metadata: scrut.metadata, pos: scrut.pos };
                        default: scrut;
                    };
                    var ncls = [];
                    for (c in cls) ncls.push({ pattern: c.pattern, guard: c.guard == null ? null : rewriteInnerCaseScrutinee(c.guard, oldName, newName), body: rewriteInnerCaseScrutinee(c.body, oldName, newName) });
                    { def: ECase(nscrut, ncls), metadata: n.metadata, pos: n.pos };
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    for (s in stmts) out.push(rewriteInnerCaseScrutinee(s, oldName, newName));
                    { def: EBlock(out), metadata: n.metadata, pos: n.pos };
                case EDo(stmts2):
                    var out2:Array<ElixirAST> = [];
                    for (s in stmts2) out2.push(rewriteInnerCaseScrutinee(s, oldName, newName));
                    { def: EDo(out2), metadata: n.metadata, pos: n.pos };
                case EIf(c,t,e):
                    { def: EIf(rewriteInnerCaseScrutinee(c, oldName, newName), rewriteInnerCaseScrutinee(t, oldName, newName), e == null ? null : rewriteInnerCaseScrutinee(e, oldName, newName)), metadata: n.metadata, pos: n.pos };
                case EBinary(op, l, r):
                    { def: EBinary(op, rewriteInnerCaseScrutinee(l, oldName, newName), rewriteInnerCaseScrutinee(r, oldName, newName)), metadata: n.metadata, pos: n.pos };
                case EMatch(pat, rhs):
                    { def: EMatch(pat, rewriteInnerCaseScrutinee(rhs, oldName, newName)), metadata: n.metadata, pos: n.pos };
                case ECall(tgt, fnm, args):
                    var nt = tgt == null ? null : rewriteInnerCaseScrutinee(tgt, oldName, newName);
                    var nargs = [for (a in args) rewriteInnerCaseScrutinee(a, oldName, newName)];
                    { def: ECall(nt, fnm, nargs), metadata: n.metadata, pos: n.pos };
                case ERemoteCall(mod, fnm2, args2):
                    var nmod = rewriteInnerCaseScrutinee(mod, oldName, newName);
                    var nargs2 = [for (a in args2) rewriteInnerCaseScrutinee(a, oldName, newName)];
                    { def: ERemoteCall(nmod, fnm2, nargs2), metadata: n.metadata, pos: n.pos };
                default:
                    n;
            }
        });
    }

    /**
     * Rewrite inner case scrutinee when it references an infrastructure temp (g/_g/gN)
     */
    static function rewriteInnerCaseScrutineeInfra(body: ElixirAST, newName:String): ElixirAST {
        return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                case ECase(scrut, cls):
                    var nscrut = switch (scrut.def) {
                        case EVar(v) if (isInfrastructureVar(v)): { def: EVar(newName), metadata: scrut.metadata, pos: scrut.pos };
                        default: scrut;
                    };
                    var ncls = [];
                    for (c in cls) ncls.push({ pattern: c.pattern, guard: c.guard == null ? null : rewriteInnerCaseScrutineeInfra(c.guard, newName), body: rewriteInnerCaseScrutineeInfra(c.body, newName) });
                    { def: ECase(nscrut, ncls), metadata: n.metadata, pos: n.pos };
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    for (s in stmts) out.push(rewriteInnerCaseScrutineeInfra(s, newName));
                    { def: EBlock(out), metadata: n.metadata, pos: n.pos };
                case EDo(stmts2):
                    var out2:Array<ElixirAST> = [];
                    for (s in stmts2) out2.push(rewriteInnerCaseScrutineeInfra(s, newName));
                    { def: EDo(out2), metadata: n.metadata, pos: n.pos };
                case EIf(c,t,e):
                    { def: EIf(rewriteInnerCaseScrutineeInfra(c, newName), rewriteInnerCaseScrutineeInfra(t, newName), e == null ? null : rewriteInnerCaseScrutineeInfra(e, newName)), metadata: n.metadata, pos: n.pos };
                case EBinary(op, l, r):
                    { def: EBinary(op, rewriteInnerCaseScrutineeInfra(l, newName), rewriteInnerCaseScrutineeInfra(r, newName)), metadata: n.metadata, pos: n.pos };
                case EMatch(pat, rhs):
                    { def: EMatch(pat, rewriteInnerCaseScrutineeInfra(rhs, newName)), metadata: n.metadata, pos: n.pos };
                case ECall(tgt, fnm, args):
                    var nt = tgt == null ? null : rewriteInnerCaseScrutineeInfra(tgt, newName);
                    var nargs = [for (a in args) rewriteInnerCaseScrutineeInfra(a, newName)];
                    { def: ECall(nt, fnm, nargs), metadata: n.metadata, pos: n.pos };
                case ERemoteCall(mod, fnm2, args2):
                    var nmod = rewriteInnerCaseScrutineeInfra(mod, newName);
                    var nargs2 = [for (a in args2) rewriteInnerCaseScrutineeInfra(a, newName)];
                    { def: ERemoteCall(nmod, fnm2, nargs2), metadata: n.metadata, pos: n.pos };
                default:
                    n;
            }
        });
    }
    
    /**
     * Build pattern from case value expression
     *
     * WHY: Patterns need to match Elixir's pattern matching semantics
     * WHAT: Converts Haxe case values to Elixir patterns, handling TEnumIndex optimization
     * HOW: Analyzes value type, generates appropriate pattern, maps integers to enum constructors
     *
     * @param guardVars - Variable names extracted from guard conditions (for TEnumIndex cases)
     * @param caseBody - The case body expression for usage analysis (determines underscore prefixes)
     */
    static function buildPattern(value: TypedExpr, targetVarName: String, guardVars: Array<String>, caseBody: TypedExpr, context: CompilationContext): Null<EPattern> {
        trace('[SwitchBuilder] Building pattern for: ${Type.enumConstructor(value.expr)}');
        switch(value.expr) {
            case TConst(c):
                // Constant patterns
                trace('[SwitchBuilder]   Found constant pattern');
                switch(c) {
                    case TInt(i):
                        trace('[SwitchBuilder]     Integer constant: $i');

                        // CRITICAL: Check if this is a TEnumIndex case
                        if (context.currentClauseContext != null && context.currentClauseContext.enumType != null) {
                            var enumType = context.currentClauseContext.enumType;
                            trace('[SwitchBuilder]     *** Mapping integer $i to enum constructor ***');

                            var constructor = getEnumConstructorByIndex(enumType, i);
                            if (constructor != null) {
                                trace('[SwitchBuilder]     *** Found constructor: ${constructor.name} ***');

                                // Use guard variables passed from buildCaseClause
                                // When TEnumIndex optimization transforms case Ok(n) to case 0,
                                // we recover the user's variable name from the guard condition
                                // CRITICAL FIX: Use new version that analyzes case body for parameter usage
                                return generateIdiomaticEnumPatternWithBody(constructor, guardVars, caseBody, context);
                            } else {
                                trace('[SwitchBuilder]     WARNING: No constructor found for index $i');
                            }
                        }

                        // Fallback: regular integer pattern
                        return PLiteral(makeAST(EInteger(i)));
                    case TFloat(f): return PLiteral(makeAST(EFloat(Std.parseFloat(Std.string(f)))));
                    case TString(s): return PLiteral(makeAST(EString(s)));
                    case TBool(true): return PLiteral(makeAST(EAtom("true")));
                    case TBool(false): return PLiteral(makeAST(EAtom("false")));
                    case TNull: return PLiteral(makeAST(ENil));
                    default: return null;
                }

      case TCall(e, args):
        // Enum constructor patterns
        trace('[SwitchBuilder]   Found TCall, checking if enum constructor');
        if (isEnumConstructor(e)) {
                    trace('[SwitchBuilder]     Confirmed enum constructor, building enum pattern (with body usage analysis)');
                    // Prefer body-aware variant so parameter names (todo/id/message) and underscore usage are correct
                    var ef: EnumField = null;
                    switch (e.expr) {
                        case TField(_, FEnum(_, enumField)):
                            ef = enumField;
                        default:
                    }
                    if (ef != null) {
                        return generateIdiomaticEnumPatternWithBodyArgs(ef, args, guardVars, caseBody, context);
                    } else {
                        // Fallback to legacy builder if we couldn't extract EnumField
                        return buildEnumPattern(e, args, guardVars, context);
                    }
                }
        trace('[SwitchBuilder]     Not an enum constructor');
        return null;

      case TField(e2, FEnum(_, enumField2)):
        // Direct reference to enum constructor (no immediate call in AST)
        // Use body-aware idiomatic generator to pick binder names and usage
        trace('[SwitchBuilder]   Found TField FEnum, building enum pattern (with body usage analysis)');
        return generateIdiomaticEnumPatternWithBody(enumField2, guardVars, caseBody, context);

      case TLocal(v):
        // Variable pattern (binds the value)
        var varName = VariableAnalyzer.toElixirVarName(v.name);
        return PVar(varName);

            default:
                #if debug_ast_builder
                trace('[SwitchBuilder] Unhandled pattern type: ${Type.enumConstructor(value.expr)}');
                #end
                return null;
        }
    }

    /**
     * Generate idiomatic Elixir pattern for enum constructor WITH usage analysis
     *
     * WHY: Detect unused parameters to apply underscore prefix and prevent orphaned TEnumParameter extraction
     * WHAT: Creates tuple patterns with proper naming based on actual parameter usage in case body
     * HOW: Uses EnumHandler.isEnumParameterUsedAtIndex to detect usage, applies underscore prefix if unused
     *
     * CRITICAL: This solves the "empty case body" bug where unused parameters generate orphaned _g variables
     */
    static function generateIdiomaticEnumPatternWithBody(ef: EnumField, guardVars: Array<String>, caseBody: TypedExpr, context: CompilationContext): EPattern {
        var atomName = NameUtils.toSnakeCase(ef.name);

        // Extract parameter names from EnumField.type (fallback)
        var parameterNames: Array<String> = [];
        switch(ef.type) {
            case TFun(args, _):
                for (arg in args) {
                    parameterNames.push(arg.name);
                }
            default:
                // No parameters
        }

        if (parameterNames.length == 0) {
            // Simple tagged tuple with single atom: {:none}
            trace('[SwitchBuilder]     Generated pattern: {:${atomName}}');
            return PTuple([PLiteral(makeAST(EAtom(atomName)))]);
        } else {
            // Tuple pattern: {:some, value}
            var patterns: Array<EPattern> = [PLiteral(makeAST(EAtom(atomName)))];

            // Helper: test if a name is considered an environment/function-parameter name (exclude from binders)
            function isEnvLikeName(n:String):Bool {
                if (n == null) return false;
                // Strict minimal set; avoid broad app coupling. These are common function params, not payloads.
                if (n == "socket" || n == "live_socket" || n == "liveSocket" || n == "conn" || n == "params") return true;
                // Exclude compiler-introduced temporaries like this, this1, this2, etc.
                if (StringTools.startsWith(n, "this")) {
                    var rest = n.substr(4);
                    var ok = true;
                    for (i in 0...rest.length) {
                        var ch = rest.charAt(i);
                        if (ch < "0" || ch > "9") { ok = false; break; }
                    }
                    if (rest.length == 0 || ok) return true;
                }
                // Also exclude obvious alias/temp names used around json calls
                if (n == "json" || n == "data") return true;
                return false;
            }

            // Helper: collect lower-case simple names used in the clause body (exclude env-like names)
            function collectUsedLowerLocals(body: TypedExpr): Array<String> {
                var names = new Map<String,Bool>();
                function walk(e: TypedExpr): Void {
                    if (e == null) return;
                    switch (e.expr) {
                        case TLocal(v):
                            var n = v.name;
                            if (n != null && n.length > 0) {
                                var c = n.charAt(0);
                                if (c.toLowerCase() == c && !isEnvLikeName(n)) names.set(n, true);
                            }
                        default:
                    }
                    TypedExprTools.iter(e, walk);
                }
                walk(body);
                return [for (k in names.keys()) k];
            }

            var usedLower = collectUsedLowerLocals(caseBody);

            // Helper: check if a name corresponds to a current function parameter (shape-based exclusion)
            function isFunctionParamByName(n:String):Bool {
                if (n == null || n.length == 0) return false;
                // Find first matching TLocal id for this name in the case body
                var foundId:Null<Int> = null;
                function findId(e:TypedExpr):Void {
                    if (e == null || foundId != null) return;
                    switch (e.expr) {
                        case TLocal(v) if (v.name == n):
                            foundId = v.id;
                        default:
                    }
                    if (foundId == null) haxe.macro.TypedExprTools.iter(e, findId);
                }
                findId(caseBody);
                return foundId != null && context.functionParameterIds.exists(Std.string(foundId));
            }

            // Choose a better binder when exactly one parameter and there are lower-case locals used
            function bestUsedLowerName(): Null<String> {
                if (parameterNames.length != 1 || usedLower.length == 0) return null;
                // Filter out env-like and function parameters
                var filtered = [];
                for (n in usedLower) {
                    var alt = VariableAnalyzer.toElixirVarName(n);
                    if (!isEnvLikeName(alt) && !isFunctionParamByName(alt)) filtered.push(alt);
                }
                // Only choose when exactly one clear candidate remains
                if (filtered.length == 1) return filtered[0];
                return null;
            }
            var preferredLower: Null<String> = bestUsedLowerName();

            var isResultCtor = (ef.name == "Ok" || ef.name == "Error");
            for (i in 0...parameterNames.length) {
                // Select a safe base source name with strict filtering
                var candidate:Null<String> = null;
                if (guardVars != null && i < guardVars.length) candidate = guardVars[i];
                if (candidate == null || isEnvLikeName(candidate) || isFunctionParamByName(candidate)) {
                    candidate = parameterNames[i];
                }

                var baseParamName = VariableAnalyzer.toElixirVarName(candidate);
                if (isResultCtor && i == 0) baseParamName = (ef.name == "Ok") ? "value" : "reason";

                // If only one parameter and we detected lower-case locals in body,
                // prefer the first safe lower-case local as binder (usage-driven, generic).
                if (preferredLower != null) baseParamName = preferredLower;

                // CRITICAL: Analyze case body to determine if this parameter is actually used
                var isUsed = EnumHandler.isEnumParameterUsedAtIndex(i, caseBody);
                if (!isUsed) {
                    var rawParamName = candidate;
                    if (rawParamName != null) isUsed = EnumHandler.isLocalNameUsed(rawParamName, caseBody);
                }
                // If a preferred lower-case local was selected, treat binder as used
                if (!isUsed && preferredLower != null) isUsed = true;
                if (!isUsed && isResultCtor) isUsed = true;

                // Apply underscore prefix for unused parameters
                var paramName = isUsed ? baseParamName : "_" + baseParamName;

                trace('[SwitchBuilder]     Parameter $i: EnumParam=${parameterNames[i]}, Usage=${isUsed ? "USED" : "UNUSED"}, FinalName=${paramName}');

                patterns.push(PVar(paramName));

                // Populate enumBindingPlan with proper usage information
                if (context.currentClauseContext != null) {
                    context.currentClauseContext.enumBindingPlan.set(i, {
                        finalName: paramName,
                        isUsed: isUsed
                    });
                }
            }

            var finalNames = [for (i in 0...parameterNames.length) {
                var base = (guardVars != null && i < guardVars.length) ? guardVars[i] : parameterNames[i];
                var effectiveBase = (preferredLower != null) ? preferredLower : base;
                var isUsed = EnumHandler.isEnumParameterUsedAtIndex(i, caseBody) ||
                    (effectiveBase != null && EnumHandler.isLocalNameUsed(effectiveBase, caseBody));
                isUsed ? base : "_" + base;
            }];
            trace('[SwitchBuilder]     Generated pattern: {:${atomName}, ${finalNames.join(", ")}}');

            // CRITICAL FIX: Store enum field name so TEnumParameter knows this constructor was pattern-matched
            if (context.currentClauseContext != null) {
                context.currentClauseContext.patternExtractedParams.push(ef.name);
                #if sys
                var debugFile = sys.io.File.append("/tmp/enum_debug.log");
                debugFile.writeString('[SwitchBuilder.generateIdiomaticEnumPatternWithBody] ✅ STORED "${ef.name}" in patternExtractedParams\n');
                debugFile.close();
                #end
            }

            return PTuple(patterns);
        }
    }

    /**
     * Generate idiomatic enum pattern using constructor args to recover user variable names.
     *
     * WHY: Haxe enum field arg names sometimes default to `value`, but callers often bind
     *      meaningful names in TCall (e.g., TodoCreated(todo)). Prefer those names.
     */
    static function generateIdiomaticEnumPatternWithBodyArgs(ef: EnumField, callArgs: Array<TypedExpr>, guardVars: Array<String>, caseBody: TypedExpr, context: CompilationContext): EPattern {
        var atomName = NameUtils.toSnakeCase(ef.name);
        var paramCount = 0;
        switch(ef.type) {
            case TFun(args, _): paramCount = args.length;
            default:
        }
        if (paramCount == 0) {
            return PLiteral(makeAST(EAtom(atomName)));
        }
        var patterns: Array<EPattern> = [PLiteral(makeAST(EAtom(atomName)))];
        var isResultCtor = (ef.name == "Ok" || ef.name == "Error");
        for (i in 0...paramCount) {
            // Priority: guard var > TLocal name from arg > enum field param name
            var guardName = (guardVars != null && i < guardVars.length) ? guardVars[i] : null;
            var argLocal: Null<String> = null;
            if (i < callArgs.length) {
                switch (callArgs[i].expr) {
                    case TLocal(v): argLocal = v.name;
                    case TParenthesis(inner):
                        switch(inner.expr) { case TLocal(v2): argLocal = v2.name; default: }
                    default:
                }
            }
            var enumParamName: Null<String> = null;
            switch(ef.type) { case TFun(args, _): if (i < args.length) enumParamName = args[i].name; default: }
            var chosen = guardName != null ? guardName : (argLocal != null ? argLocal : enumParamName);
            var baseParamName = VariableAnalyzer.toElixirVarName(chosen);
            if (isResultCtor && i == 0) baseParamName = (ef.name == "Ok") ? "value" : "reason";
            var isUsed = EnumHandler.isEnumParameterUsedAtIndex(i, caseBody) || (chosen != null && EnumHandler.isLocalNameUsed(chosen, caseBody));
            if (!isUsed && isResultCtor) isUsed = true;
            var finalName = isUsed ? baseParamName : "_" + baseParamName;
            patterns.push(PVar(finalName));
            if (context.currentClauseContext != null) {
                context.currentClauseContext.enumBindingPlan.set(i, { finalName: finalName, isUsed: isUsed });
            }
        }
        return PTuple(patterns);
    }

    /**
     * Generate idiomatic Elixir pattern for enum constructor (LEGACY - no body analysis)
     *
     * WHY: Convert recovered enum constructors to idiomatic {:atom, params} patterns
     * WHAT: Creates tuple patterns with user's variable names from guards when available
     * HOW: Uses guardVars if provided, otherwise falls back to EnumField parameter names
     *
     * CRITICAL: When TEnumIndex optimization loses variable names, we recover them from guard conditions
     * NOTE: This version doesn't analyze usage - prefer generateIdiomaticEnumPatternWithBody instead
     */
    static function generateIdiomaticEnumPattern(ef: EnumField, guardVars: Array<String>, context: CompilationContext): EPattern {
        var atomName = NameUtils.toSnakeCase(ef.name);

        // Extract parameter names from EnumField.type (fallback)
        var parameterNames: Array<String> = [];
        switch(ef.type) {
            case TFun(args, _):
                for (arg in args) {
                    parameterNames.push(arg.name);
                }
            default:
                // No parameters
        }

        if (parameterNames.length == 0) {
            // Simple atom pattern: :none
            trace('[SwitchBuilder]     Generated pattern: {:${atomName}}');
            return PLiteral(makeAST(EAtom(atomName)));
        } else {
            // Tuple pattern: {:some, value}
            var patterns: Array<EPattern> = [PLiteral(makeAST(EAtom(atomName)))];

            for (i in 0...parameterNames.length) {
                // Use guard variable if available, otherwise use enum parameter name
                var sourceName = (guardVars != null && i < guardVars.length) ? guardVars[i] : parameterNames[i];
                var paramName = VariableAnalyzer.toElixirVarName(sourceName);
                trace('[SwitchBuilder]     Parameter $i: GuardVar=${guardVars != null && i < guardVars.length ? guardVars[i] : "none"}, EnumParam=${parameterNames[i]}, Using=${paramName}');

                // CRITICAL FIX: Populate enumBindingPlan so TEnumParameter knows this was extracted
                // Now properly detecting parameter usage to apply underscore prefix
                if (context.currentClauseContext != null) {
                    // The isUsed flag is now set during pattern building
                    // (see generateIdiomaticEnumPatternWithBody for the proper implementation)
                    context.currentClauseContext.enumBindingPlan.set(i, {
                        finalName: paramName,
                        isUsed: false  // Will be updated by usage analysis
                    });
                }

                patterns.push(PVar(paramName));
            }

            var finalNames = [for (i in 0...parameterNames.length)
                (guardVars != null && i < guardVars.length) ? guardVars[i] : parameterNames[i]];
            trace('[SwitchBuilder]     Generated pattern: {:${atomName}, ${finalNames.join(", ")}}');
            return PTuple(patterns);
        }
    }

    /**
     * Extract variable names from guard condition
     *
     * WHY: TEnumIndex optimization loses user's variable names from patterns
     * WHAT: Recovers variable names by analyzing guard TIf conditions
     * HOW: Recursively traverses TIf to find TLocal variables used in comparisons
     *
     * Example: case Ok(n) if (n > 0) → guards have TIf(TBinop(OpGt, TLocal(n), TConst(0)))
     *          We extract "n" from the TLocal
     */
    static function extractGuardVariables(caseExpr: TypedExpr): Array<String> {
        var vars: Array<String> = [];

        function traverse(expr: TypedExpr): Void {
            if (expr == null) return;

            switch(expr.expr) {
                case TLocal(v):
                    // Found a variable in the guard
                    if (!vars.contains(v.name)) {
                        vars.push(v.name);
                    }
                case TBinop(_, e1, e2):
                    traverse(e1);
                    traverse(e2);
                case TIf(econd, eif, eelse):
                    traverse(econd);
                    traverse(eif);
                    if (eelse != null) traverse(eelse);
                case TBlock(exprs):
                    for (e in exprs) traverse(e);
                case TUnop(_, _, e1):
                    traverse(e1);
                case TField(e, _):
                    traverse(e);
                case TCall(e, el):
                    traverse(e);
                    for (arg in el) traverse(arg);
                case TParenthesis(e):
                    traverse(e);
                default:
                    // Other expressions don't contain variable references we care about
            }
        }

        traverse(caseExpr);
        return vars;
    }

    /**
     * Extract first TLocal variable name from expression (for guard variable extraction)
     *
     * WHY: Guards in TIf conditions contain the user's variable choice
     * WHAT: Returns first TLocal.name found, or null if none
     * HOW: Simple recursive traversal stopping at first TLocal
     */
    static function extractFirstTLocalName(expr: Null<TypedExpr>): Null<String> {
        if (expr == null) return null;

        return switch(expr.expr) {
            case TLocal(v):
                v.name;
            case TBinop(_, e1, e2):
                var result = extractFirstTLocalName(e1);
                result != null ? result : extractFirstTLocalName(e2);
            case TUnop(_, _, e):
                extractFirstTLocalName(e);
            case TParenthesis(e):
                extractFirstTLocalName(e);
            case TCall(e, el):
                var result = extractFirstTLocalName(e);
                if (result != null) return result;
                for (arg in el) {
                    result = extractFirstTLocalName(arg);
                    if (result != null) return result;
                }
                null;
            default:
                null;
        };
    }

    /**
     * Extract variable names from GUARD expression (for finding canonical names)
     *
     * WHY: When TEnumIndex optimization changes pattern variable names, guard preserves originals
     * WHAT: Extracts TLocal names from guard expression
     * HOW: Simple traversal collecting v.name from TLocal nodes
     */
    static function extractVarsFromGuardExpr(guardExpr: Null<TypedExpr>): Array<String> {
        if (guardExpr == null) {
            trace('[extractVarsFromGuardExpr] guardExpr is null');
            return [];
        }

        trace('[extractVarsFromGuardExpr] Starting extraction from: ${Type.enumConstructor(guardExpr.expr)}');
        var vars: Array<String> = [];

        function traverse(expr: TypedExpr): Void {
            if (expr == null) return;

            trace('[extractVarsFromGuardExpr]   Traversing: ${Type.enumConstructor(expr.expr)}');
            switch(expr.expr) {
                case TLocal(v):
                    trace('[extractVarsFromGuardExpr]     FOUND TLocal: ${v.name} (id=${v.id})');
                    if (!vars.contains(v.name)) {
                        vars.push(v.name);
                    }
                case TIf(econd, eif, eelse):
                    // CRITICAL: Guard is ONLY in the TIf condition, not in then/else branches
                    // Structure: TIf(guard_condition, case_body, else_next_case)
                    // We ONLY want variables from the guard condition!
                    traverse(econd);  // Extract from guard only
                    // Don't traverse eif/eelse - those are case body and continuation
                case TBinop(_, e1, e2):
                    traverse(e1); traverse(e2);
                case TUnop(_, _, e):
                    traverse(e);
                case TParenthesis(e):
                    traverse(e);
                case TCall(e, el):
                    traverse(e);
                    for (arg in el) traverse(arg);
                default:
            }
        }

        traverse(guardExpr);
        return vars;
    }

    /**
     * Strip numeric suffix from Haxe-renamed variables
     *
     * WHY: Haxe adds suffixes (n, n2, n3) for same variable in different cases
     * WHAT: Removes numeric suffix to get canonical name
     * HOW: Regex to strip trailing digits
     *
     * Examples: n2 -> n, value3 -> value, msg -> msg
     */
    static function stripNumericSuffix(name: String): String {
        var pattern = ~/^(.+?)(\d+)$/;
        if (pattern.match(name)) {
            return pattern.matched(1);
        }
        return name;
    }

    /**
     * Extract variable names from case PATTERN (not guard)
     *
     * WHY: Case patterns contain the user's intended variable names before Haxe's renaming
     *      Guard expressions have Haxe's renamed variables (n, n2, n3) which are wrong
     *
     * WHAT: Extracts variable names from pattern TEnumParameter or TLocal nodes
     *
     * HOW: Recursively traverses pattern expression, collects TLocal names
     *
     * Example: case Ok(n) → extract "n" from pattern
     *          Guard has n2, but pattern has the canonical "n"
     */
    /**
     * Extract variable names from CASE BODY (post-TEnumIndex optimization)
     *
     * WHY: After TEnumIndex optimization, pattern becomes TConst(TInt(0)) with NO variable names
     *      The user's variable binding "action" is REMOVED from pattern but PRESERVED in case body
     *      We must scan the case body for TLocal references to recover original variable names
     *
     * WHAT: Traverses case body expression to find ALL TLocal variables used
     *       These are the variables that the pattern SHOULD bind to
     *
     * HOW: Recursively walks case body AST, collecting unique TLocal variable names
     *      Returns them in discovery order (matches parameter order for multi-param enums)
     *
     * CRITICAL: This is the ONLY way to get correct variable names after TEnumIndex optimization!
     *
     * Example:
     *   Haxe: case Some(action): switch(action) { ... }
     *   After TEnumIndex: pattern=TConst(0), body=TBlock([TSwitch(TLocal(action), ...)])
     *   This function finds "action" in the body and returns ["action"]
     */
    static function extractUsedVariablesFromCaseBody(caseBodyExpr: TypedExpr): Array<String> {
        var vars: Array<String> = [];
        var seenIds: Map<Int, Bool> = new Map();  // Track by TLocal.id to avoid duplicates

        #if debug_enum_extraction
        trace('[extractUsedVariablesFromCaseBody] Scanning case body type: ${Type.enumConstructor(caseBodyExpr.expr)}');
        #end

        // CRITICAL: For TSwitch in case body, the switch TARGET is the variable we need!
        // Example: case Some(_): switch(action) { ... }
        // We need "action" (the switch target), NOT variables from inner cases
        switch(caseBodyExpr.expr) {
            case TSwitch(e, _, _):
                // The switch target expression is what the outer pattern should bind
                switch(e.expr) {
                    case TLocal(v):
                        #if debug_enum_extraction
                        trace('[extractUsedVariablesFromCaseBody]   Found TSwitch target TLocal: ${v.name} (id=${v.id})');
                        #end
                        return [v.name];  // Return immediately - this is THE variable
                    default:
                        // Switch target isn't a simple variable - fall through to full traversal
                }
            case TBlock(exprs):
                // Unwrap block and recursively check expressions for TSwitch
                #if debug_enum_extraction
                trace('[extractUsedVariablesFromCaseBody]   TBlock has ${exprs.length} expressions');
                for (i in 0...exprs.length) {
                    trace('[extractUsedVariablesFromCaseBody]     Expression $i type: ${Type.enumConstructor(exprs[i].expr)}');
                }
                #end

                // Helper to recursively unwrap TBlocks, TMeta, and TParenthesis to find TSwitch
                function findSwitchTarget(expr: TypedExpr, depth: Int = 0): Null<String> {
                    #if debug_enum_extraction
                    var indent = [for (i in 0...depth) "  "].join("");
                    trace('[findSwitchTarget]${indent}Checking expr type: ${Type.enumConstructor(expr.expr)}');
                    #end

                    switch(expr.expr) {
                        case TSwitch(e, _, _):
                            // Found a switch! Extract its target
                            #if debug_enum_extraction
                            trace('[findSwitchTarget]${indent}  Found TSwitch! Target type: ${Type.enumConstructor(e.expr)}');
                            #end

                            // Unwrap target if it's wrapped in TParenthesis or TMeta
                            var unwrappedTarget = e;
                            while (true) {
                                switch(unwrappedTarget.expr) {
                                    case TParenthesis(inner):
                                        #if debug_enum_extraction
                                        trace('[findSwitchTarget]${indent}    Unwrapping target TParenthesis...');
                                        #end
                                        unwrappedTarget = inner;
                                    case TMeta(_, inner):
                                        #if debug_enum_extraction
                                        trace('[findSwitchTarget]${indent}    Unwrapping target TMeta...');
                                        #end
                                        unwrappedTarget = inner;
                                    default:
                                        break;
                                }
                            }

                            // Now check if unwrapped target is TLocal or TEnumIndex
                            switch(unwrappedTarget.expr) {
                                case TLocal(v):
                                    #if debug_enum_extraction
                                    trace('[findSwitchTarget]${indent}    ✅ TSwitch target is TLocal: ${v.name} (id=${v.id})');
                                    #end
                                    return v.name;
                                case TEnumIndex(e):
                                    // The variable was transformed to enum index - extract from inner expr
                                    #if debug_enum_extraction
                                    trace('[findSwitchTarget]${indent}    Found TEnumIndex, extracting from inner expr type: ${Type.enumConstructor(e.expr)}');
                                    #end
                                    switch(e.expr) {
                                        case TLocal(v):
                                            #if debug_enum_extraction
                                            trace('[findSwitchTarget]${indent}    ✅ TEnumIndex inner is TLocal: ${v.name} (id=${v.id})');
                                            #end
                                            return v.name;
                                        default:
                                            #if debug_enum_extraction
                                            trace('[findSwitchTarget]${indent}    ❌ TEnumIndex inner is not TLocal (type: ${Type.enumConstructor(e.expr)})');
                                            #end
                                            return null;
                                    }
                                default:
                                    #if debug_enum_extraction
                                    trace('[findSwitchTarget]${indent}    ❌ TSwitch target is not TLocal or TEnumIndex (type: ${Type.enumConstructor(unwrappedTarget.expr)})');
                                    #end
                                    return null;
                            }
                        case TMeta(_, innerExpr):
                            // Unwrap metadata wrapper
                            #if debug_enum_extraction
                            trace('[findSwitchTarget]${indent}  Unwrapping TMeta...');
                            #end
                            return findSwitchTarget(innerExpr, depth + 1);
                        case TParenthesis(innerExpr):
                            // Unwrap parenthesis wrapper
                            #if debug_enum_extraction
                            trace('[findSwitchTarget]${indent}  Unwrapping TParenthesis...');
                            #end
                            return findSwitchTarget(innerExpr, depth + 1);
                        case TBlock(innerExprs):
                            // Recursively unwrap nested TBlock
                            #if debug_enum_extraction
                            trace('[findSwitchTarget]${indent}  TBlock has ${innerExprs.length} inner expressions');
                            #end
                            for (i in 0...innerExprs.length) {
                                #if debug_enum_extraction
                                trace('[findSwitchTarget]${indent}    Checking inner expr $i...');
                                #end
                                var result = findSwitchTarget(innerExprs[i], depth + 1);
                                if (result != null) {
                                    #if debug_enum_extraction
                                    trace('[findSwitchTarget]${indent}    ✅ Found in inner expr $i: $result');
                                    #end
                                    return result;
                                }
                            }
                            #if debug_enum_extraction
                            trace('[findSwitchTarget]${indent}  ❌ No TSwitch found in any inner expr');
                            #end
                            return null;
                        default:
                            return null;
                    }
                }

                // Try to find TSwitch in any expression (including nested blocks)
                for (expr in exprs) {
                    var switchTarget = findSwitchTarget(expr);
                    if (switchTarget != null) {
                        return [switchTarget];  // Found it!
                    }
                }
            default:
                // Not a switch - continue with full traversal
        }

        // Fallback: Full traversal for non-switch cases
        function traverse(expr: TypedExpr): Void {
            if (expr == null) return;

            switch(expr.expr) {
                case TLocal(v):
                    // Found a variable used in case body
                    if (!seenIds.exists(v.id)) {
                        #if debug_enum_extraction
                        trace('[extractUsedVariablesFromCaseBody]   Found TLocal (traversal): ${v.name} (id=${v.id})');
                        #end
                        vars.push(v.name);
                        seenIds.set(v.id, true);
                    }

                // Traverse all expression types to find TLocal variables
                case TBlock(exprs):
                    for (e in exprs) traverse(e);
                case TBinop(_, e1, e2):
                    traverse(e1);
                    traverse(e2);
                case TUnop(_, _, e):
                    traverse(e);
                case TCall(e, args):
                    traverse(e);
                    for (arg in args) traverse(arg);
                case TField(e, _):
                    traverse(e);
                case TArray(e1, e2):
                    traverse(e1);
                    traverse(e2);
                case TIf(econd, eif, eelse):
                    traverse(econd);
                    traverse(eif);
                    if (eelse != null) traverse(eelse);
                case TSwitch(e, _, _):
                    // DON'T traverse into nested switches - we already handled this above
                    // Only traverse the switch target at the immediate level
                    traverse(e);
                case TWhile(econd, e, _):
                    traverse(econd);
                    traverse(e);
                case TFor(v, e1, e2):
                    traverse(e1);
                    traverse(e2);
                case TReturn(e):
                    if (e != null) traverse(e);
                case TThrow(e):
                    traverse(e);
                case TTry(e, catches):
                    traverse(e);
                    for (c in catches) traverse(c.expr);
                case TParenthesis(e):
                    traverse(e);
                case TMeta(_, e):
                    traverse(e);
                case TCast(e, _):
                    traverse(e);
                case TEnumParameter(e, _, _):
                    traverse(e);
                case TObjectDecl(fields):
                    for (f in fields) traverse(f.expr);
                case TArrayDecl(el):
                    for (e in el) traverse(e);
                case TNew(_, _, el):
                    for (e in el) traverse(e);

                default:
                    // TConst, TBreak, TContinue, TIdent, TTypeExpr - no traversal needed
            }
        }

        traverse(caseBodyExpr);

        #if debug_enum_extraction
        trace('[extractUsedVariablesFromCaseBody] Extracted ${vars.length} variables: [${vars.join(", ")}]');
        #end

        return vars;
    }

    static function extractVarsFromPatternExpr(patternExpr: TypedExpr): Array<String> {
        var vars: Array<String> = [];

        trace('[extractVarsFromPatternExpr] Pattern expr type: ${Type.enumConstructor(patternExpr.expr)}');

        function traverse(expr: TypedExpr): Void {
            if (expr == null) return;

            trace('[extractVarsFromPatternExpr]   Traversing: ${Type.enumConstructor(expr.expr)}');

            switch(expr.expr) {
                case TEnumParameter(e, ef, index):
                    // This is an enum constructor parameter in the pattern
                    // Extract the actual parameter name from the enum field
                    trace('[extractVarsFromPatternExpr]     Found TEnumParameter, ef.name=${ef.name}, index=$index');
                    trace('[extractVarsFromPatternExpr]     Inner expr (e) type: ${Type.enumConstructor(e.expr)}');

                    // CRITICAL: Don't extract from enum type definition - traverse to find actual TLocal
                    // The enum parameter type has names like "value", but we need the actual variable like "n"
                    traverse(e);
                case TLocal(v):
                    // Direct variable in pattern
                    trace('[extractVarsFromPatternExpr]     Found TLocal: ${v.name} (id=${v.id})');
                    if (!vars.contains(v.name)) {
                        vars.push(v.name);
                    }
                case TCall(_, args):
                    // Constructor call in pattern
                    trace('[extractVarsFromPatternExpr]     Found TCall with ${args.length} args');
                    for (arg in args) traverse(arg);
                case TField(e, _):
                    trace('[extractVarsFromPatternExpr]     Found TField');
                    traverse(e);
                default:
                    // Other pattern types
                    trace('[extractVarsFromPatternExpr]     Unhandled type');
            }
        }

        traverse(patternExpr);
        trace('[extractVarsFromPatternExpr] Final vars: [${vars.join(", ")}]');
        return vars;
    }

    /**
     * Extract TLocal variable IDs from guard expressions and map to canonical names
     *
     * WHY: Guard expressions create independent TLocal instances with different IDs
     *      for the same variable name. This causes guards to use different names (n, n2, n3)
     *      even though they should all use the pattern variable name (n).
     *
     * WHAT: Maps each TLocal ID found in guard to its canonical variable name from pattern.
     *       Only maps TLocals that appear in patternNames to avoid pollution.
     *
     * HOW: Recursively traverses guard expression AST, extracts TLocal IDs,
     *      registers them in ClauseContext.localToName for consistent compilation.
     *
     * Example:
     *   Pattern: case Ok(n) if (n > 0)
     *   Guard has: TBinop(OpGt, TLocal(id=42, name="n"), TConst(0))
     *   Mapping: {42 => "n"} so guard compiles to "n > 0" not "n2 > 0"
     */
    static function extractTLocalIDsFromGuard(expr: TypedExpr, patternNames: Array<String>): Map<Int, String> {
        var mapping = new Map<Int, String>();

        function traverse(e: TypedExpr) {
            if (e == null) return;

            switch(e.expr) {
                case TLocal(v):
                    // CRITICAL FIX: Strip numeric suffix before checking pattern names
                    // Haxe renames variables (n → n2, n3), but we want to map them all to canonical "n"
                    var baseName = stripNumericSuffix(v.name);

                    if (patternNames.contains(baseName)) {
                        // Map this TLocal ID to the canonical name (not the renamed version)
                        mapping.set(v.id, baseName);
                    }
                case TBinop(_, e1, e2):
                    traverse(e1);
                    traverse(e2);
                case TIf(econd, eif, eelse):
                    traverse(econd);
                    traverse(eif);
                    if (eelse != null) traverse(eelse);
                case TUnop(_, _, e1):
                    traverse(e1);
                case TParenthesis(e1):
                    traverse(e1);
                case TMeta(_, e1):
                    traverse(e1);
                case TBlock(el):
                    for (e in el) traverse(e);
                case TCall(_, el):
                    for (e in el) traverse(e);
                case TField(e, _):
                    traverse(e);
                default:
                    // Other cases don't contain TLocal variables we care about
            }
        }

        #if debug_guard_compilation
        trace('[SwitchBuilder] Extracting TLocal IDs from guard expression...');
        trace('[SwitchBuilder]   Pattern variables: [${patternNames.join(", ")}]');
        #end

        traverse(expr);

        #if debug_guard_compilation
        var extractedCount = Lambda.count(mapping);
        trace('[SwitchBuilder] Extracted $extractedCount TLocal ID mapping(s):');
        for (id in mapping.keys()) {
            trace('[SwitchBuilder]   TLocal#${id} → ${mapping.get(id)}');
        }
        #end

        return mapping;
    }

    /**
     * Build enum constructor pattern
     *
     * WHY: Enum patterns need special handling for parameter extraction
     * WHAT: Creates tuple patterns for enum constructors with ACTUAL parameter names
     * HOW: Extracts parameter names from EnumField.type (TFun args) instead of using Haxe's generated "g" variables
     *
     * CRITICAL FIX: This eliminates generated "g" variables by using the actual parameter
     * names defined in the enum constructor (e.g., "value" for Some(value: T))
     *
     * @param guardVars - Variable names extracted from guard conditions (preferred over enum param names)
     */
    static function buildEnumPattern(constructorExpr: TypedExpr, args: Array<TypedExpr>, guardVars: Array<String>, context: CompilationContext): Null<EPattern> {
        // Extract constructor name and EnumField
        var ef: EnumField = null;
        var constructorName = switch(constructorExpr.expr) {
            case TField(_, FEnum(_, enumField)):
                ef = enumField;
                enumField.name;
            default: return null;
        };

        // Convert to snake_case atom
        var atomName = NameUtils.toSnakeCase(constructorName);

        // CRITICAL: Extract actual parameter names from EnumField.type
        // This is the KEY to eliminating "g" variables!
        var parameterNames: Array<String> = [];
        if (ef != null) {
            switch(ef.type) {
                case TFun(tfunArgs, _):
                    // Extract actual parameter names from function arguments
                    for (arg in tfunArgs) {
                        parameterNames.push(arg.name);
                    }

                    #if debug_ast_builder
                    trace('[SwitchBuilder] Extracted parameter names from ${ef.name}: ${parameterNames}');
                    #end
                default:
                    // No parameters or non-function type
                    #if debug_ast_builder
                    trace('[SwitchBuilder] EnumField ${ef.name} has no function type, no parameters');
                    #end
            }
        }

        // Build parameter patterns - first element is the atom
        var patterns: Array<EPattern> = [PLiteral(makeAST(EAtom(atomName)))];

        // Use actual parameter names with priority: guardVars > TLocal > EnumField
        for (i in 0...args.length) {
            var arg = args[i];

            #if debug_enum_extraction
            trace('[SwitchBuilder.buildEnumPattern] Processing arg $i: ${Type.enumConstructor(arg.expr)}');
            #end

            // Priority 1: Guard variable (from user's guard condition)
            var guardVar = (guardVars != null && i < guardVars.length) ? guardVars[i] : null;

            // Priority 2: EnumField parameter name (fallback)
            var enumParam = i < parameterNames.length ? parameterNames[i] : null;

            #if debug_enum_extraction
            trace('[SwitchBuilder.buildEnumPattern]   guardVar: $guardVar, enumParam: $enumParam');
            #end

            switch(arg.expr) {
                case TLocal(v):
                    // CRITICAL: Use source variable name with priority system
                    // 1. guardVar (from guard like "n > 0") - most specific
                    // 2. v.name (from TLocal in pattern) - user's choice
                    // 3. enumParam (from enum definition) - fallback
                    var sourceName = guardVar != null ? guardVar : v.name;

                    #if debug_enum_extraction
                    trace('[SwitchBuilder.buildEnumPattern]   TLocal v.name: ${v.name}, sourceName: $sourceName');
                    #end

                    trace('[SwitchBuilder] *** PATTERN VAR DEBUG ***');
                    trace('[SwitchBuilder]   Index: $i');
                    trace('[SwitchBuilder]   GuardVar: ${guardVar}');
                    trace('[SwitchBuilder]   TLocal v.name: ${v.name}');
                    trace('[SwitchBuilder]   EnumParam: ${enumParam}');
                    trace('[SwitchBuilder]   Using sourceName: ${sourceName}');

                    var varName = VariableAnalyzer.toElixirVarName(sourceName);
                    trace('[SwitchBuilder]   Final varName: ${varName}');

                    patterns.push(PVar(varName));

                    // CRITICAL FIX: Populate enumBindingPlan so TEnumParameter knows this was extracted
                    if (context.currentClauseContext != null) {
                        context.currentClauseContext.enumBindingPlan.set(i, {
                            finalName: varName,
                            isUsed: false  // Will be marked as used if referenced in body
                        });
                    }
                case TCall(innerCtor, innerArgs):
                    // Support nested enum constructor patterns, e.g., Some(TodoCreated(todo))
                    var nested = buildEnumPattern(innerCtor, innerArgs, guardVars, context);
                    if (nested != null) {
                        patterns.push(nested);
                    } else {
                        patterns.push(PWildcard);
                    }

                case TParenthesis(innerP):
                    // Unwrap parentheses and retry
                    var nested2 = buildEnumPattern(innerP, [], guardVars, context);
                    if (nested2 != null) {
                        patterns.push(nested2);
                    } else {
                        patterns.push(PWildcard);
                    }

                case TMeta(_, innerM):
                    // Unwrap metadata and attempt nested pattern
                    var nested3 = buildEnumPattern(innerM, [], guardVars, context);
                    if (nested3 != null) {
                        patterns.push(nested3);
                    } else {
                        patterns.push(PWildcard);
                    }

                default:
                    // Use underscore for non-variable patterns
                    trace('[SwitchBuilder] *** PATTERN VAR DEBUG (NOT TLocal!) ***');
                    trace('[SwitchBuilder]   Index: $i');
                    trace('[SwitchBuilder]   Arg expr type: ${Type.enumConstructor(arg.expr)}');
                    trace('[SwitchBuilder]   EnumParam: ${enumParam}');
                    trace('[SwitchBuilder]   GuardVar: ${guardVar}');
                    patterns.push(PWildcard);
            }
        }

        // TASK 4.5 FIX: Store pattern-extracted ENUM FIELD NAME in ClauseContext
        // This allows TEnumParameter handling to know this enum constructor was already pattern-matched
        #if sys
        var debugFile = sys.io.File.append("/tmp/enum_debug.log");
        debugFile.writeString('[SwitchBuilder.buildEnumPattern] About to store ef.name\n');
        debugFile.writeString('[SwitchBuilder]   ef: ${ef}\n');
        debugFile.writeString('[SwitchBuilder]   ef.name: ${ef != null ? ef.name : "NULL"}\n');
        debugFile.writeString('[SwitchBuilder]   currentClauseContext: ${context.currentClauseContext != null}\n');
        debugFile.close();
        #end

        if (context.currentClauseContext != null && ef != null) {
            // Store the ENUM FIELD NAME (constructor name like "Click", "Hover")
            // NOT the parameter names (like "x", "y") - that was the bug!
            // TEnumParameter checks: patternExtractedParams.contains(ef.name)
            // So we need to store ef.name here
            context.currentClauseContext.patternExtractedParams.push(ef.name);

            #if sys
            var debugFile2 = sys.io.File.append("/tmp/enum_debug.log");
            debugFile2.writeString('[SwitchBuilder] ✅ STORED enum field "${ef.name}" in patternExtractedParams\n');
            debugFile2.writeString('[SwitchBuilder]   patternExtractedParams now: [${context.currentClauseContext.patternExtractedParams.join(", ")}]\n');
            debugFile2.close();
            #end
        }

        // Return tuple pattern for enum constructor
        return PTuple(patterns);
    }
    
    /**
     * Extract target variable name from switch expression
     * 
     * WHY: Infrastructure variables need special tracking
     * WHAT: Gets the variable name being switched on
     * HOW: Pattern matches on expression structure
     */
    static function extractTargetVarName(e: TypedExpr): Null<String> {
        return switch(e.expr) {
            case TLocal(v): v.name;
            case TParenthesis({expr: TLocal(v)}): v.name;
            default: null;
        };
    }
    
    /**
     * Extract enum type from a typed expression
     *
     * WHY: Need to recover enum type info after Haxe's TEnumIndex optimization
     * WHAT: Extracts EnumType from expression's type annotation
     * HOW: Pattern matches on Type structure
     */
    static function getEnumTypeFromExpression(expr: TypedExpr): Null<EnumType> {
        return switch(expr.t) {
            case TEnum(ref, _):
                ref.get();
            case TAbstract(ref, _):
                // Check if abstract wraps an enum
                var abs = ref.get();
                switch(abs.type) {
                    case TEnum(enumRef, _): enumRef.get();
                    default: null;
                }
            default:
                null;
        };
    }

    /**
     * Get enum constructor by index
     *
     * WHY: Map integer indices back to enum constructors
     * WHAT: Retrieves EnumField for a given index
     * HOW: Uses constructor's index field
     */
    static function getEnumConstructorByIndex(enumType: EnumType, index: Int): Null<EnumField> {
        for (name in enumType.constructs.keys()) {
            var constructor = enumType.constructs.get(name);
            if (constructor.index == index) {
                return constructor;
            }
        }
        return null;
    }

    /**
     * Check if variable is an infrastructure variable
     *
     * WHY: Haxe generates _g, g, g1 etc. for desugared expressions
     * WHAT: Identifies compiler-generated temporary variables
     * HOW: Checks naming patterns
     */
    static function isInfrastructureVar(name: String): Bool {
        return name == "g" || name == "_g" || 
               ~/^g\d+$/.match(name) || ~/^_g\d+$/.match(name);
    }
    
    /**
     * Check if expression is an enum constructor
     *
     * WHY: Enum constructors need special pattern handling
     * WHAT: Identifies enum constructor calls
     * HOW: Checks field access type
     */
    static function isEnumConstructor(e: TypedExpr): Bool {
        return switch(e.expr) {
            case TField(_, FEnum(_, _)): true;
            default: false;
        };
    }

    /**
     * Extract variable names from pattern
     *
     * WHY: Pattern variables must be registered in ClauseContext before body compilation
     * WHAT: Recursively extracts all PVar names from a pattern
     * HOW: Traverses pattern structure, collecting variable names in order
     */
    static function extractPatternVariables(pattern: EPattern): Array<String> {
        var vars: Array<String> = [];

        function traverse(p: EPattern): Void {
            switch(p) {
                case PVar(name):
                    vars.push(name);
                case PTuple(elements):
                    for (elem in elements) {
                        traverse(elem);
                    }
                case PList(elements):
                    for (elem in elements) {
                        traverse(elem);
                    }
                case PCons(head, tail):
                    traverse(head);
                    traverse(tail);
                case PMap(pairs):
                    for (pair in pairs) {
                        traverse(pair.value);
                    }
                case PStruct(_, fields):
                    for (field in fields) {
                        traverse(field.value);
                    }
                case PLiteral(_):
                    // Literals don't bind variables
                case PWildcard:
                    // Underscore doesn't bind
                case PPin(inner):
                    // Pin patterns don't bind new variables
                    traverse(inner);
                case PAlias(varName, pattern):
                    // Alias creates a binding for the variable name
                    vars.push(varName);
                    // But also traverse the inner pattern
                    traverse(pattern);
                case PBinary(segments):
                    // Binary patterns can contain variable bindings in segments
                    for (segment in segments) {
                        traverse(segment.pattern);
                    }
            }
        }

        traverse(pattern);
        return vars;
    }

    /**
     * Extract TVar declarations from case body expression
     *
     * WHY: Need to match TVar IDs with pattern variable names for ClauseContext registration
     * WHAT: Finds all TVar nodes in the expression tree
     * HOW: Recursively traverses TypedExpr, collecting TVar nodes
     */
    static function extractTVarsFromExpr(expr: TypedExpr): Array<{id: Int, name: String}> {
        var tvars: Array<{id: Int, name: String}> = [];

        function traverse(e: TypedExpr): Void {
            switch(e.expr) {
                case TVar(tvar, init):
                    tvars.push({id: tvar.id, name: tvar.name});
                    if (init != null) {
                        traverse(init);
                    }
                case TBlock(el):
                    for (expr in el) {
                        traverse(expr);
                    }
                case TBinop(_, e1, e2):
                    traverse(e1);
                    traverse(e2);
                case TCall(e, el):
                    traverse(e);
                    for (arg in el) {
                        traverse(arg);
                    }
                case TField(e, _):
                    traverse(e);
                case TIf(econd, eif, eelse):
                    traverse(econd);
                    traverse(eif);
                    if (eelse != null) {
                        traverse(eelse);
                    }
                case TSwitch(e, cases, edef):
                    traverse(e);
                    for (c in cases) {
                        for (v in c.values) {
                            traverse(v);
                        }
                        traverse(c.expr);
                    }
                    if (edef != null) {
                        traverse(edef);
                    }
                case TWhile(econd, e, _):
                    traverse(econd);
                    traverse(e);
                case TFor(v, it, expr):
                    traverse(it);
                    traverse(expr);
                case TReturn(e):
                    if (e != null) {
                        traverse(e);
                    }
                case TArrayDecl(el):
                    for (e in el) {
                        traverse(e);
                    }
                case TObjectDecl(fields):
                    for (f in fields) {
                        traverse(f.expr);
                    }
                case TParenthesis(e) | TMeta(_, e) | TCast(e, _):
                    traverse(e);
                case TArray(e1, e2):
                    traverse(e1);
                    traverse(e2);
                case TUnop(_, _, e):
                    traverse(e);
                case TNew(_, _, el):
                    for (e in el) {
                        traverse(e);
                    }
                default:
                    // Other expression types don't contain TVars we care about
            }
        }

        traverse(expr);
        return tvars;
    }
}

#end
