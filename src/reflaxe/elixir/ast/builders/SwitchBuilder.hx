package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.PosInfos;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.ECaseClause;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.context.ClauseContext;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.NameUtils;
import reflaxe.elixir.preprocessor.TypedExprPreprocessor;
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
    // Gated debug logger for SwitchBuilder to prevent noisy output in normal builds.
    static inline function sdbg(msg:String):Void {
        #if debug_switch_builder
        trace(msg);
        #end
    }
    #if debug_option_some_binder
    #error "debug_option_some_binder define detected"
    @:keep
    static var __debugOptionSomeBinderActive:Bool = (function(){
        Sys.println('[OptionSomeDiag] debug_option_some_binder flag active (SwitchBuilder)');
        return true;
    })();
    #end
    // Debug logging helper: disabled unless -D debug_switch_builder
    static inline function dbg(msg:Dynamic):Void {
        #if debug_switch_builder
        haxe.Log.trace(msg, null);
        #end
    }

    // Focused diagnostics for Option.Some binder analysis
    static inline function optionSomeLog(msg:Dynamic):Void {
        #if debug_option_some_binder
        haxe.Log.trace(msg, null);
        #end
    }

    // Override local trace within this class to be conditional on debug flag
    static inline function trace(v:Dynamic, ?pos:PosInfos):Void {
        #if debug_switch_builder
        haxe.Log.trace(v, pos);
        #end
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
        #if debug_option_some_binder
        var __optionSomeDiagPos = Std.string(e.pos);
        if (__optionSomeDiagPos.indexOf("TodoPubSub") >= 0) {
            optionSomeLog('[OptionSomeDiag] SwitchBuilder.build invoked for ' + Type.enumConstructor(e.expr) + ' at ' + __optionSomeDiagPos);
        }
        #end

        // DEBUG: Log ALL switch compilations
        dbg('[SwitchBuilder START] Compiling switch at ${e.pos}');
        dbg('[SwitchBuilder START] Switch target: ${Type.enumConstructor(e.expr)}');

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
        dbg('[SwitchBuilder DEBUG] Switch target expression type: ${Type.enumConstructor(actualSwitchExpr.expr)}');
        if (targetVarName != null) {
            dbg('[SwitchBuilder DEBUG] Extracted variable name: ${targetVarName}');
            dbg('[SwitchBuilder DEBUG] Is infrastructure var: ${isInfrastructureVar(targetVarName)}');
        }

        if (targetVarName != null && isInfrastructureVar(targetVarName)) {
            dbg('[SwitchBuilder DEBUG] Infrastructure variable detected but not handled!');
        }

        // Build the switch target expression (use actual enum, not index)
        var targetAST = if (context.compiler != null) {
            // Apply infrastructure variable substitution before re-compilation
            var substitutedTarget = context.substituteIfNeeded(actualSwitchExpr);

            // Fallback: if target is still a TLocal infra var (name-based), use name substitutions
            switch (substitutedTarget.expr) {
                case TLocal(tv) if (tv != null && (tv.name == "g" || StringTools.startsWith(tv.name, "g") || StringTools.startsWith(tv.name, "_g"))):
                    var nameSubs = TypedExprPreprocessor.getLastNameSubstitutions();
                    if (nameSubs != null) {
                        var key = tv.name;
                        if (!nameSubs.exists(key) && StringTools.startsWith(key, "_")) key = key.substr(1);
                        if (nameSubs.exists(key)) {
                            var replacement = nameSubs.get(key);
                            if (replacement != null) {
                                substitutedTarget = replacement;
                            }
                        }
                    }
                default:
            }
            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(substitutedTarget, context);
            sdbg('[SwitchBuilder DEBUG] Compiled target AST: ' + Type.enumConstructor(result.def));
            // DEBUG: Show exact variable name if it's EVar
            switch(result.def) {
                case EVar(name):
                    sdbg('[SwitchBuilder DEBUG] EVar variable name: "' + name + '"');
                default:
            }
            // Resolve infrastructure variable names to canonical mappings if available
            var fixed = switch(result.def) {
                case EVar(varName) if (isInfrastructureVar(varName) && context.tempVarRenameMap != null && context.tempVarRenameMap.exists(varName)):
                    var mapped = context.tempVarRenameMap.get(varName);
                    #if debug_infrastructure_vars
                    sdbg('[SwitchBuilder] Resolving infra target ' + varName + ' -> ' + mapped);
                    #end
                    makeAST(EVar(mapped));
                default:
                    result;
            };
            // Strong inline: if target remains an infra EVar, attempt to inline its original expression
            // using (1) AST mapping, (2) typed substitutions by sourceVarId, and (3) name-based typed substitutions.
            fixed = switch (fixed.def) {
                case EVar(vn) if (TypedExprPreprocessor.isInfrastructureVar(vn)):
                    var inlined: Null<ElixirAST> = null;
                    // 1) AST init values captured from BlockBuilder
                    if (context.infrastructureVarInitValues != null) {
                        var key = vn;
                        if (!context.infrastructureVarInitValues.exists(key) && StringTools.startsWith(key, "_")) key = key.substr(1);
                        if (context.infrastructureVarInitValues.exists(key)) inlined = context.infrastructureVarInitValues.get(key);
                    }
                    // 2) TypedExpr substitution by sourceVarId metadata
                    if (inlined == null && fixed.metadata != null && Reflect.hasField(fixed.metadata, "sourceVarId")) {
                        var sid: Dynamic = Reflect.field(fixed.metadata, "sourceVarId");
                        if (Std.isOfType(sid, Int) && context.infraVarSubstitutions != null) {
                            var texpr: TypedExpr = context.infraVarSubstitutions.get(cast sid);
                            if (texpr != null) inlined = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(texpr, context);
                        }
                    }
                    // 3) Name-based substitution fallback (preprocessor-provided)
                    if (inlined == null && context.infraVarNameSubstitutions != null) {
                        var n1 = vn; var n2 = StringTools.startsWith(vn, "_") ? vn.substr(1) : vn;
                        var texpr2: TypedExpr = null;
                        if (context.infraVarNameSubstitutions.exists(n1)) texpr2 = context.infraVarNameSubstitutions.get(n1);
                        else if (context.infraVarNameSubstitutions.exists(n2)) texpr2 = context.infraVarNameSubstitutions.get(n2);
                        if (texpr2 != null) inlined = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(texpr2, context);
                    }
                    (inlined != null) ? inlined : fixed;
                default:
                    fixed;
            };
            fixed;
        } else {
            return null;  // Can't proceed without compiler
        }

        if (targetAST == null) {
            sdbg('[SwitchBuilder ERROR] Target AST compilation returned null!');
            return null;
        }

        // Create clause context for pattern variable scoping
        var clauseContext = new ClauseContext();

        // Store enum type for use in pattern building
        if (isEnumIndexSwitch && enumType != null) {
            clauseContext.enumType = enumType;
        }
        
        // Store the old context and set new one
        var oldClauseContext = context.currentClauseContext;
        context.currentClauseContext = clauseContext;
        
        // Build case clauses (may generate multiple clauses per case due to guard chains)
        var caseClauses: Array<ECaseClause> = [];

        for (i in 0...cases.length) {
            var switchCase = cases[i];
            sdbg('[SwitchBuilder] Building case ' + (i + 1) + '/' + cases.length);
            var clausesFromCase = buildCaseClause(switchCase, targetVarName, context);
            if (clausesFromCase.length > 0) {
                sdbg('[SwitchBuilder]   Generated ' + clausesFromCase.length + ' clause(s) from this case');
                for (clause in clausesFromCase) {
                    caseClauses.push(clause);
                }
            } else {
                sdbg('[SwitchBuilder]   Case clause build returned empty array!');
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
        
        // Generate case expression
        if (caseClauses.length == 0) {
            #if debug_ast_builder
            sdbg('[SwitchBuilder] No case clauses generated');
            #end
            return null;
        }
        
        // Finalize: optionally align Option.Some binders and inject safe aliasing for conventional *_level targets
        // Generic structural rule: when switching on a *_level variable, prefer clause-local name `level`.
        caseClauses = applyOptionLevelAlias(caseClauses, targetVarName);
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
    static function buildCaseClause(switchCase: {values:Array<TypedExpr>, expr:TypedExpr}, targetVarName: String, context: CompilationContext): Array<ECaseClause> {
        // Handle multiple values in one case (fall-through pattern)
        if (switchCase.values.length == 0) {
            return [];
        }

        // For now, handle single value cases (most common)
        // TODO: Handle multiple values with pattern alternatives
        var value = switchCase.values[0];

        // CRITICAL FIX: Extract variable names from CASE BODY, not pattern or guard!
        // After TEnumIndex optimization: pattern=TConst(0), NO variable names!
        // The user's variable "action" is in the case BODY where it's used
        // This is the ONLY way to recover the correct variable name after TEnumIndex
        sdbg('[SwitchBuilder] ====== PATTERN ANALYSIS ======');
        sdbg('[SwitchBuilder] Pattern expr type: ' + Type.enumConstructor(value.expr));

        // NEW FIX: Extract variables from case body (where they're actually used)
        var patternVars = extractUsedVariablesFromCaseBody(switchCase.expr);

        #if debug_enum_extraction
        sdbg('[SwitchBuilder] Extracted ' + patternVars.length + ' variables from case body: [' + patternVars.join(',') + ']');
        #end

        // CRITICAL: Extract TLocal IDs from guard and register in ClauseContext.localToName
        // This ensures guard expressions compile with the same variable names as patterns
        // Without this, guards get different names (n, n2, n3) due to independent TLocal instances
        // NOTE: VariableBuilder.resolveVariableName() checks ClauseContext.lookupVariable() first
        var tvarMapping = extractTLocalIDsFromGuard(switchCase.expr, patternVars);

        #if debug_guard_compilation
        var mappingCount = Lambda.count(tvarMapping);
        sdbg('[SwitchBuilder] Current ClauseContext: ' + (context.currentClauseContext != null ? 'EXISTS' : 'NULL'));
        sdbg('[SwitchBuilder] Registering ' + mappingCount + ' TLocal mapping(s) in ClauseContext.localToName:');
        #end

        if (context.currentClauseContext != null) {
            for (tvarId in tvarMapping.keys()) {
                var name = tvarMapping.get(tvarId);
                #if debug_guard_compilation
                sdbg('[SwitchBuilder]   TLocal#' + tvarId + ' → ' + name);
                #end
                context.currentClauseContext.localToName.set(tvarId, name);
            }
        } #if debug_guard_compilation else {
            sdbg('[SwitchBuilder ERROR] ClauseContext is NULL - cannot register mappings!');
        } #end

        // Build pattern from case value (pass pattern variables and case body for usage analysis)
        var pattern = buildPattern(value, targetVarName, patternVars, switchCase.expr, context);
        if (pattern == null) {
            return [];
        }

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
            clauses = extractGuardChain(exprToCheck, pattern, context);
        }

        // If no guards detected, create single clause without guard
        if (clauses.length == 0) {
            var body = if (switchCase.expr != null && context.compiler != null) {
                var substitutedBody = context.substituteIfNeeded(switchCase.expr);
                reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(substitutedBody, context);
            } else {
                null;
            };

            // Ensure empty case bodies produce explicit nil for deterministic, idiomatic output
            var finalBody: ElixirAST = null;
            if (body == null) {
                finalBody = makeAST(ENil);
            } else {
                switch (body.def) {
                    case EBlock(expressions) if (expressions.length == 0):
                        finalBody = makeAST(ENil);
                    default:
                        finalBody = body;
                }
            }

            // If the body is effectively empty (nil), underscore-bind any pattern variables
            // so we do not generate unused variable warnings and to reflect true non-usage.
            var finalPattern = switch (finalBody.def) {
                case ENil:
                    underscorePatternVars(pattern);
                default:
                    pattern;
            };
            clauses.push({
                pattern: finalPattern,
                guard: null,
                body: finalBody
            });
        }

        clauses = ensureOptionSomeBinderAlignment(clauses, context);
        clauses = normalizeZeroArityEnumPatterns(clauses);
        return clauses;
    }

    // Helper: when the switch target name hints a *_level value (e.g., alert_level),
    // and a clause pattern is {:some|:ok, binder}, if the body references `level`,
    // inject a clause-local alias `level = binder` as the first statement.
    static function applyOptionLevelAlias(clauses:Array<ECaseClause>, targetVarName:String):Array<ECaseClause> {
        inline function bodyUsesVar(ast:ElixirAST, v:String):Bool {
            var found = false;
            function walk(n:ElixirAST):Void {
                if (n == null || found) return;
                switch (n.def) {
                    case EVar(name) if (name == v):
                        found = true;
                    case EBlock(exprs):
                        for (e in exprs) walk(e);
                    case EIf(c,t,e):
                        walk(c); walk(t); if (e != null) walk(e);
                    case ECase(e, cls):
                        walk(e);
                        for (c in cls) {
                            if (c.guard != null) walk(c.guard);
                            walk(c.body);
                        }
                    case ECond(conds):
                        for (c in conds) { walk(c.condition); walk(c.body); }
                    case ECall(t,_,args):
                        if (t != null) walk(t);
                        for (a in args) walk(a);
                    case ERemoteCall(m,_,args):
                        walk(m);
                        for (a in args) walk(a);
                    case EBinary(_,l,r):
                        walk(l); walk(r);
                    case EUnary(_,e):
                        walk(e);
                    case EMatch(_, e):
                        walk(e);
                    case EKeywordList(pairs):
                        for (p in pairs) walk(p.value);
                    case EMap(pairs):
                        for (p in pairs) { walk(p.key); walk(p.value); }
                    case ETuple(el):
                        for (x in el) walk(x);
                    case EList(el):
                        for (x in el) walk(x);
                    case EStruct(_, fields):
                        for (f in fields) walk(f.value);
                    case EStructUpdate(s, fields):
                        walk(s); for (f in fields) walk(f.value);
                    case EAccess(t,k):
                        walk(t); walk(k);
                    case ERange(s,e,_):
                        walk(s); walk(e);
                    case EPipe(l,r):
                        walk(l); walk(r);
                    case EParen(e):
                        walk(e);
                    case EDo(body):
                        for (s in body) walk(s);
                    default:
                        // Leaf nodes
                }
            }
            walk(ast);
            return found;
        }
        inline function injectAlias(body:ElixirAST, binder:String):ElixirAST {
            var aliasExpr = makeAST(EMatch(PVar("level"), makeAST(EVar(binder))));
            return switch (body.def) {
                case EBlock(stmts): makeAST(EBlock([aliasExpr].concat(stmts)));
                default: makeAST(EBlock([aliasExpr, body]));
            };
        }
        var res:Array<ECaseClause> = [];
        var hintLevel = false;
        var suffix:Null<String> = null;
        if (targetVarName != null) {
            var snake = reflaxe.elixir.ast.NameUtils.toSnakeCase(targetVarName);
            if (snake != null) {
                var re = ~/^.*_([a-z0-9]+)$/;
                if (re.match(snake)) suffix = re.matched(1);
                hintLevel = (suffix == "level");
            }
        }
        for (cl in clauses) {
            var out = cl;
            if (suffix != null && bodyUsesVar(cl.body, suffix)) {
                switch (cl.pattern) {
                    case PTuple(elements) if (elements.length >= 2):
                        switch (elements[0]) {
                            case PLiteral({def: EAtom(a)}) if (a == "some" || a == "ok"):
                                switch (elements[1]) {
                                    case PVar(b):
                                        // Prefer renaming binder to target suffix to avoid extra bindings
                                        var renamedPat = replaceBinderName(cl.pattern, b, suffix);
                                        out = { pattern: renamedPat, guard: cl.guard, body: cl.body };
                                    default:
                                }
                            default:
                        }
                    default:
                }
            }
            res.push(out);
        }
        return res;
    }

    /**
     * Recursively underscore all variable names in a pattern when case body is empty.
     * Keeps existing underscores and non-variable patterns intact.
     */
    static inline function underscorePatternVars(p: EPattern): EPattern {
        return switch (p) {
            case PVar(name):
                var newName = name.startsWith("_") ? name : "_" + name;
                PVar(newName);
            case PTuple(elements):
                PTuple([for (el in elements) underscorePatternVars(el)]);
            case PList(elements):
                PList([for (el in elements) underscorePatternVars(el)]);
            case PCons(head, tail):
                PCons(underscorePatternVars(head), underscorePatternVars(tail));
            case PMap(pairs):
                PMap([for (kv in pairs) {key: kv.key, value: underscorePatternVars(kv.value)}]);
            case PStruct(module, fields):
                PStruct(module, [for (f in fields) {key: f.key, value: underscorePatternVars(f.value)}]);
            case PAlias(varName, pat):
                var newVar = varName.startsWith("_") ? varName : "_" + varName;
                PAlias(newVar, underscorePatternVars(pat));
            case PPin(inner):
                PPin(underscorePatternVars(inner));
            case PBinary(segments):
                PBinary([for (s in segments) {pattern: underscorePatternVars(s.pattern), size: s.size, type: s.type, modifiers: s.modifiers}]);
            default:
                p;
        };
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
    static function extractGuardChain(expr: TypedExpr, pattern: EPattern, context: CompilationContext): Array<ECaseClause> {
        var clauses: Array<ECaseClause> = [];
        var current = expr;

        sdbg('[GuardChain] Starting extraction, expr type: ' + Type.enumConstructor(current.expr));

        // Traverse the if-else chain
        while (true) {
            switch(current.expr) {
                case TIf(econd, eif, eelse):
                    sdbg('[GuardChain] Found TIf - extracting guard');
                    // Extract guard condition
                    var guard = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(econd, context);

                    // Compile then-branch as body
                    var substitutedBody = context.substituteIfNeeded(eif);
                    var body = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(substitutedBody, context);

                    // Create clause with guard
                    clauses.push({
                        pattern: pattern,
                        guard: guard,
                        body: body
                    });
                    sdbg('[GuardChain]   Created clause with guard');

                    // Continue with else-branch (may be another TIf or final value)
                    if (eelse != null) {
                        sdbg('[GuardChain]   Else-branch type: ' + Type.enumConstructor(eelse.expr));

                        // Unwrap TBlock to find nested TIf
                        var nextExpr = eelse;
                        switch(eelse.expr) {
                            case TBlock(exprs):
                                sdbg('[GuardChain]   Unwrapping TBlock with ' + exprs.length + ' expressions');
                                // Search for TIf in the block
                                for (expr in exprs) {
                                    if (Type.enumConstructor(expr.expr) == "TIf") {
                                        sdbg('[GuardChain]   Found TIf inside TBlock');
                                        nextExpr = expr;
                                        break;
                                    }
                                }
                            default:
                                // Not a TBlock, use as-is
                        }

                        current = nextExpr;
                    } else {
                        sdbg('[GuardChain]   No else-branch, stopping');
                        break;
                    }

                default:
                    sdbg('[GuardChain] Not a TIf (type: ' + Type.enumConstructor(current.expr) + '), creating final clause');
                    // Reached final else (not a TIf) - create clause without guard
                    var substitutedBody = context.substituteIfNeeded(current);
                    var builtBody = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(substitutedBody, context);
                    var finalBody = (builtBody == null) ? makeAST(ENil) : switch (builtBody.def) {
                        case EBlock(exprs) if (exprs.length == 0): makeAST(ENil);
                        default: builtBody;
                    };

                    clauses.push({
                        pattern: pattern,
                        guard: null,
                        body: finalBody
                    });
                    break;
            }
        }

        sdbg('[GuardChain] Extracted ' + clauses.length + ' total clauses');
        return clauses;
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
        sdbg('[SwitchBuilder] Building pattern for: ' + Type.enumConstructor(value.expr));
        switch(value.expr) {
            case TConst(c):
                // Constant patterns
                sdbg('[SwitchBuilder]   Found constant pattern');
                switch(c) {
                    case TInt(i):
                            sdbg('[SwitchBuilder]     Integer constant: ' + i);

                        // CRITICAL: Check if this is a TEnumIndex case
                        if (context.currentClauseContext != null && context.currentClauseContext.enumType != null) {
                            var enumType = context.currentClauseContext.enumType;
                            sdbg('[SwitchBuilder]     *** Mapping integer ' + i + ' to enum constructor ***');

                            var constructor = getEnumConstructorByIndex(enumType, i);
                            if (constructor != null) {
                                sdbg('[SwitchBuilder]     *** Found constructor: ' + constructor.name + ' ***');

                                // Use guard variables passed from buildCaseClause
                                // When TEnumIndex optimization transforms case Ok(n) to case 0,
                                // we recover the user's variable name from the guard condition
                                // CRITICAL FIX: Use new version that analyzes case body for parameter usage
                                return generateIdiomaticEnumPatternWithBody(constructor, guardVars, caseBody, context, targetVarName);
                            } else {
                                sdbg('[SwitchBuilder]     WARNING: No constructor found for index ' + i);
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
                sdbg('[SwitchBuilder]   Found TCall, checking if enum constructor');
                if (isEnumConstructor(e)) {
                    sdbg('[SwitchBuilder]     Confirmed enum constructor, building enum pattern (usage-aware)');
                    // Extract EnumField from constructor expression
                    var ef: EnumField = switch (e.expr) {
                        case TField(_, FEnum(_, enumField)): enumField;
                        default: null;
                    };
                    if (ef != null) {
                        // Extract guard variable names (from TIf conditions) for usage awareness
                        var guardNames = extractGuardVariables(caseBody);
                        // Use usage-aware generator with guard+body analysis to avoid underscoring binders used in guards
                        return generateIdiomaticEnumPatternWithBody(ef, guardNames, caseBody, context, targetVarName);
                    } else {
                        // Fallback to legacy builder if extraction fails
                        return buildEnumPattern(e, args, guardVars, context);
                    }
                }
                sdbg('[SwitchBuilder]     Not an enum constructor');
                return null;

            case TLocal(v):
                // Variable pattern (binds the value)
                var varName = VariableAnalyzer.toElixirVarName(v.name);
                return PVar(varName);

            default:
                #if debug_ast_builder
                sdbg('[SwitchBuilder] Unhandled pattern type: ' + Type.enumConstructor(value.expr));
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
    static function generateIdiomaticEnumPatternWithBody(ef: EnumField, guardVars: Array<String>, caseBody: TypedExpr, context: CompilationContext, targetVarName:String): EPattern {
        var atomName = NameUtils.toSnakeCase(ef.name);

        // Extract variable names used in the case body to align binder names with actual usage
        var bodyUsedHaxe: Array<String> = extractUsedVariablesFromCaseBody(caseBody);
        #if debug_switch_builder
        #if debug_switch_builder
        Sys.println('[SwitchBuilder] generateIdiomaticEnumPatternWithBody bodyUsed=' + (bodyUsedHaxe != null ? bodyUsedHaxe.join(',') : 'null'));
        #end
        #end
        function isReserved(elixirName: String): Bool {
            return elixirName == null || elixirName.length == 0 ||
                elixirName == "conn" || elixirName == "socket" || elixirName == "params" ||
                ~/^_?g\d+$/.match(elixirName) ||
                elixirName == "this" || ~/^this\d+$/.match(elixirName) ||
                elixirName == "updated_socket" || elixirName == "live_socket";
        }
        var bodyVarCandidates: Array<{haxe:String, elixir:String}> = [];
        if (bodyUsedHaxe != null) {
            for (u in bodyUsedHaxe) {
                var elixirName = VariableAnalyzer.toElixirVarName(u);
                if (isReserved(elixirName)) continue;
                var dup = false;
                for (c in bodyVarCandidates) {
                    if (c.elixir == elixirName) { dup = true; break; }
                }
                if (!dup) {
                    bodyVarCandidates.push({haxe: u, elixir: elixirName});
                }
            }
        }

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
            sdbg('[SwitchBuilder]     Generated pattern: {:' + atomName + '}');
            return PLiteral(makeAST(EAtom(atomName)));
        } else {
            // Tuple pattern: {:some, value}
            var patterns: Array<EPattern> = [PLiteral(makeAST(EAtom(atomName)))];
            #if debug_switch_builder
            #if debug_switch_builder
            Sys.println('[SwitchBuilder] atom=' + atomName + ' candidates=' + [for (c in bodyVarCandidates) c.haxe + '->' + c.elixir].join(','));
            #end
            #end

            inline function baseName(s:String):String {
                var re = ~/([0-9]+)$/;
                return re.replace(s, "");
            }
            function guardHas(name:String):Bool {
                if (guardVars == null) return false;
                var b = baseName(name);
                for (gv in guardVars) {
                    if (gv == name || baseName(gv) == b) return true;
                }
                return false;
            }

            // Exclude body vars that are used as field bases in the case body (e.g., payload.message)
            // This prevents renaming {:some, binder} to an outer map variable like `msg`/`payload`.
            function collectTypedFieldBases(te:TypedExpr):Map<String,Bool> {
                var m = new Map<String,Bool>();
                function walk(e:TypedExpr):Void {
                    switch (e.expr) {
                        case TField(obj, _):
                            switch (obj.expr) {
                                case TLocal(v): m.set(v.name, true);
                                default:
                            }
                            walk(obj);
                        case TCall(target, args):
                            // Mark first arg of Map.get/Keyword.get as field base when it's a local
                            switch (target.expr) {
                                case TField(tobj, fa):
                                    var isGet = false;
                                    var isMapOrKeyword = false;
                                    switch (fa) {
                                        case FStatic(c1, cf1):
                                            isGet = (cf1.get().name == "get");
                                            var cname1 = c1.get().name;
                                            isMapOrKeyword = (cname1 == "Map" || cname1 == "Keyword");
                                        case FInstance(c2, _, cf2):
                                            isGet = (cf2.get().name == "get");
                                            var cname2 = c2.get().name;
                                            isMapOrKeyword = (cname2 == "Map" || cname2 == "Keyword");
                                        case FAnon(cf3):
                                            isGet = (cf3.get().name == "get");
                                        case FClosure(_, cf4):
                                            isGet = (cf4.get().name == "get");
                                        case _:
                                    }
                                    if (isGet && isMapOrKeyword && args.length > 0) {
                                        switch (args[0].expr) { case TLocal(v): m.set(v.name, true); default: }
                                    }
                                default:
                            }
                            walk(target);
                            for (a in args) walk(a);
                        case TBinop(_, a, b):
                            walk(a); walk(b);
                        case TParenthesis(x) | TMeta(_, x) | TCast(x, _):
                            walk(x);
                        case TArray(a, b):
                            walk(a); walk(b);
                        case TObjectDecl(fs):
                            for (f in fs) walk(f.expr);
                        case TArrayDecl(el):
                            for (x in el) walk(x);
                        case TBlock(el):
                            for (x in el) walk(x);
                        case TIf(c, t, e):
                            walk(c); walk(t); if (e != null) walk(e);
                        case TSwitch(se, cs, de):
                            walk(se);
                            for (c in cs) { for (v in c.values) walk(v); walk(c.expr); }
                            if (de != null) walk(de);
                        case TWhile(c, b, _):
                            walk(c); walk(b);
                        case TFor(v, it, body):
                            walk(it); walk(body);
                        case TReturn(x): if (x != null) walk(x);
                        default:
                    }
                }
                walk(caseBody);
                return m;
            }
            var fieldBasesHaxe = collectTypedFieldBases(caseBody);

            for (i in 0...parameterNames.length) {
                // Choose source name priority: (single-arg && body candidate) > guard var > enum param
                var chosenSource: String = null;
                if (parameterNames.length == 1 && bodyVarCandidates.length > 0) {
                    // Prefer a candidate that is NOT a field base and not obviously generic
                    var picked:Null<String> = null;
                    for (c in bodyVarCandidates) {
                        if (fieldBasesHaxe.exists(c.haxe)) continue;
                        if (c.elixir == "socket" || c.elixir == "conn") continue;
                        if (targetVarName != null && c.elixir == targetVarName) continue;
                        picked = c.haxe; break;
                    }
                    if (picked == null) picked = bodyVarCandidates[0].haxe; // fallback
                    chosenSource = picked;
                } else if (guardVars != null && i < guardVars.length) {
                    chosenSource = guardVars[i];
                } else {
                    chosenSource = parameterNames[i];
                }

                // Determine usage with Haxe name against case body
                var isUsed = EnumHandler.isVariableNameUsedInBody(chosenSource, caseBody) || guardHas(chosenSource);

                // Convert to Elixir variable and optionally underscore if unused
                var chosenElixir = VariableAnalyzer.toElixirVarName(chosenSource);
                var baseName = isUsed ? chosenElixir : "_" + chosenElixir;
                // Avoid collision with function parameters (e.g., fn arg: message) by suffixing with '2'
                var paramName = baseName;
                if ((targetVarName != null && chosenElixir == targetVarName)
                    || (context != null && context.functionParameterNames != null && context.functionParameterNames.exists(chosenElixir))) {
                    // keep underscore if present, append '2' to the core name
                    var core = isUsed ? chosenElixir : chosenElixir;
                    var suffixed = core + "2";
                    paramName = isUsed ? suffixed : "_" + suffixed;
                }

                // Hard preference: if switching on *_level, force binder name 'level' ignoring candidates
                if (parameterNames.length == 1 && targetVarName != null) {
                    var snakeTarget = reflaxe.elixir.ast.NameUtils.toSnakeCase(targetVarName);
                    if (snakeTarget != null && ~/.*_level$/.match(snakeTarget)) {
                        paramName = "level";
                    }
                }

                sdbg('[SwitchBuilder]     Parameter ' + i + ': Source=' + chosenSource + ', Usage=' + (isUsed ? 'USED' : 'UNUSED') + ', FinalName=' + paramName);

                patterns.push(PVar(paramName));

                // Populate enumBindingPlan with proper usage information (respecting collision-avoided name)
                if (context.currentClauseContext != null) {
                    context.currentClauseContext.enumBindingPlan.set(i, {
                        finalName: paramName,
                        isUsed: isUsed
                    });
                }
            }

            // No app-specific binder preferences; binder alignment remains generic downstream.

            var finalNames = [for (i in 0...parameterNames.length) {
                var base = (guardVars != null && i < guardVars.length) ? guardVars[i] : parameterNames[i];
                var preferred = (parameterNames.length == 1 && bodyVarCandidates.length > 0) ? bodyVarCandidates[0].haxe : base;
                var isUsed = EnumHandler.isVariableNameUsedInBody(preferred, caseBody) || EnumHandler.isVariableNameUsedInBody(base, caseBody) || guardHas(preferred) || guardHas(base);
                isUsed ? preferred : "_" + preferred;
            }];
            sdbg('[SwitchBuilder]     Generated pattern: {:' + atomName + ', ' + finalNames.join(', ') + '}');

            // CRITICAL FIX: Store enum field name so TEnumParameter knows this constructor was pattern-matched
            if (context.currentClauseContext != null) {
                context.currentClauseContext.patternExtractedParams.push(ef.name);
                #if sys
                var debugFile = sys.io.File.append("/tmp/enum_debug.log");
        #if debug_switch_builder
        debugFile.writeString('[SwitchBuilder.generateIdiomaticEnumPatternWithBody] ✅ STORED "${ef.name}" in patternExtractedParams\n');
        #end
                debugFile.close();
                #end
            }

            return PTuple(patterns);
        }
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
            sdbg('[SwitchBuilder]     Generated pattern: {:' + atomName + '}');
            return PLiteral(makeAST(EAtom(atomName)));
        } else {
            // Tuple pattern: {:some, value}
            var patterns: Array<EPattern> = [PLiteral(makeAST(EAtom(atomName)))];

            for (i in 0...parameterNames.length) {
                // Use guard variable if available, otherwise use enum parameter name
                var sourceName = (guardVars != null && i < guardVars.length) ? guardVars[i] : parameterNames[i];
                var paramName = VariableAnalyzer.toElixirVarName(sourceName);
                if (context != null && context.functionParameterNames != null && context.functionParameterNames.exists(paramName)) {
                    paramName = paramName + "2";
                }
                sdbg('[SwitchBuilder]     Parameter ' + i + ': GuardVar=' + (guardVars != null && i < guardVars.length ? guardVars[i] : 'none') + ', EnumParam=' + parameterNames[i] + ', Using=' + paramName);

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
            sdbg('[SwitchBuilder]     Generated pattern: {:' + atomName + ', ' + finalNames.join(', ') + '}');
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
        sdbg('[SwitchBuilder] Extracting TLocal IDs from guard expression...');
        sdbg('[SwitchBuilder]   Pattern variables: [' + patternNames.join(', ') + ']');
        #end

        traverse(expr);

        #if debug_guard_compilation
        var extractedCount = Lambda.count(mapping);
        sdbg('[SwitchBuilder] Extracted ' + extractedCount + ' TLocal ID mapping(s):');
        for (id in mapping.keys()) {
            sdbg('[SwitchBuilder]   TLocal#' + id + ' → ' + mapping.get(id));
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
                    sdbg('[SwitchBuilder] Extracted parameter names from ' + ef.name + ': ' + parameterNames);
                    #end
                default:
                    // No parameters or non-function type
                    #if debug_ast_builder
                    sdbg('[SwitchBuilder] EnumField ' + ef.name + ' has no function type, no parameters');
                    #end
            }
        }

        // Zero-arg enum constructors should pattern-match as bare atoms (e.g., :complete_all)
        if (args == null || args.length == 0) {
            return PLiteral(makeAST(EAtom(atomName)));
        }

        // Build parameter patterns - first element is the atom for tuple constructors
        var patterns: Array<EPattern> = [PLiteral(makeAST(EAtom(atomName)))];

        // Use actual parameter names with priority: guardVars > TLocal > EnumField
        for (i in 0...args.length) {
            var arg = args[i];

            #if debug_enum_extraction
            sdbg('[SwitchBuilder.buildEnumPattern] Processing arg ' + i + ': ' + Type.enumConstructor(arg.expr));
            #end

            // Priority 1: Guard variable (from user's guard condition)
            var guardVar = (guardVars != null && i < guardVars.length) ? guardVars[i] : null;

            // Priority 2: EnumField parameter name (fallback)
            var enumParam = i < parameterNames.length ? parameterNames[i] : null;

            #if debug_enum_extraction
            sdbg('[SwitchBuilder.buildEnumPattern]   guardVar: ' + guardVar + ', enumParam: ' + enumParam);
            #end

            switch(arg.expr) {
                case TLocal(v):
                    // CRITICAL: Use source variable name with priority system
                    // 1. guardVar (from guard like "n > 0") - most specific
                    // 2. v.name (from TLocal in pattern) - user's choice
                    // 3. enumParam (from enum definition) - fallback
                    var sourceName = guardVar != null ? guardVar : v.name;

                    #if debug_enum_extraction
                    sdbg('[SwitchBuilder.buildEnumPattern]   TLocal v.name: ' + v.name + ', sourceName: ' + sourceName);
                    #end

                    sdbg('[SwitchBuilder] *** PATTERN VAR DEBUG ***');
                    sdbg('[SwitchBuilder]   Index: ' + i);
                    sdbg('[SwitchBuilder]   GuardVar: ' + guardVar);
                    sdbg('[SwitchBuilder]   TLocal v.name: ' + v.name);
                    sdbg('[SwitchBuilder]   EnumParam: ' + enumParam);
                    sdbg('[SwitchBuilder]   Using sourceName: ' + sourceName);

                    var varName = VariableAnalyzer.toElixirVarName(sourceName);
                    if (context != null && context.functionParameterNames != null && context.functionParameterNames.exists(varName)) {
                        varName = varName + "2";
                    }
                    sdbg('[SwitchBuilder]   Final varName: ' + varName);

                    patterns.push(PVar(varName));

                    // CRITICAL FIX: Populate enumBindingPlan so TEnumParameter knows this was extracted
                    if (context.currentClauseContext != null) {
                        context.currentClauseContext.enumBindingPlan.set(i, {
                            finalName: varName,
                            isUsed: false  // Will be marked as used if referenced in body
                        });
                    }
                default:
                    // Use underscore for non-variable patterns
                    sdbg('[SwitchBuilder] *** PATTERN VAR DEBUG (NOT TLocal!) ***');
                    sdbg('[SwitchBuilder]   Index: ' + i);
                    sdbg('[SwitchBuilder]   Arg expr type: ' + Type.enumConstructor(arg.expr));
                    sdbg('[SwitchBuilder]   EnumParam: ' + enumParam);
                    sdbg('[SwitchBuilder]   GuardVar: ' + guardVar);
                    patterns.push(PWildcard);
            }
        }

        // TASK 4.5 FIX: Store pattern-extracted ENUM FIELD NAME in ClauseContext
        // This allows TEnumParameter handling to know this enum constructor was already pattern-matched
        #if sys
        var debugFile = sys.io.File.append("/tmp/enum_debug.log");
        #if debug_switch_builder
        debugFile.writeString('[SwitchBuilder.buildEnumPattern] About to store ef.name\n');
        debugFile.writeString('[SwitchBuilder]   ef: ${ef}\n');
        debugFile.writeString('[SwitchBuilder]   ef.name: ${ef != null ? ef.name : "NULL"}\n');
        debugFile.writeString('[SwitchBuilder]   currentClauseContext: ${context.currentClauseContext != null}\n');
        #end
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
            #if debug_switch_builder
            debugFile2.writeString('[SwitchBuilder] ✅ STORED enum field "${ef.name}" in patternExtractedParams\n');
            debugFile2.writeString('[SwitchBuilder]   patternExtractedParams now: [${context.currentClauseContext.patternExtractedParams.join(", ")}]\n');
            #end
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

    static inline function isSimpleIdentifier(name:String):Bool {
        return name != null && ~/^[a-z_][a-z0-9_]*$/.match(name);
    }

    static function ensureOptionSomeBinderAlignment(clauses:Array<ECaseClause>, context:CompilationContext):Array<ECaseClause> {
        return [for (cl in clauses) alignOptionBinderInClause(cl, context)];
    }

    // Normalize patterns like {:tag} (single-element tuple) into :tag
    static function normalizeZeroArityEnumPatterns(clauses:Array<ECaseClause>):Array<ECaseClause> {
        function normalize(p:EPattern):EPattern {
            return switch (p) {
                case PTuple(elems) if (elems.length == 1):
                    switch (elems[0]) {
                        case PLiteral({def: EAtom(a)}): PLiteral(makeAST(EAtom(a)));
                        default: p;
                    }
                default: p;
            };
        }
        return [for (cl in clauses) { pattern: normalize(cl.pattern), guard: cl.guard, body: cl.body }];
    }

    static function alignOptionBinderInClause(clause:ECaseClause, context:CompilationContext):ECaseClause {
        #if debug_option_some_binder
        optionSomeLog('[OptionSomeDiag] alignOptionBinderInClause check → pattern=' + patternPreview(clause.pattern));
        #end
        switch (clause.pattern) {
            case PTuple(elements) if (elements.length >= 2):
                switch (elements[0]) {
                    case PLiteral({def: EAtom(atom)}) if (atom == "some" || atom == "ok"):
                        switch (elements[1]) {
                            case PVar(binderName):
                                #if debug_option_some_binder
                                optionSomeLog('[OptionSomeDiag] Initial binder="' + binderName + '"');
                                #end
                                var patternBinders = collectPatternBinderNames(clause.pattern);
                                var used = collectUsedVars(clause.body);
                                var bound = collectBoundVars(clause.body);
                                var fieldBases = collectFieldBaseVars(clause.body);

                                // (debug removed)

                                var missing:Array<String> = [];
                                for (name in used.keys()) {
                                    if (!patternBinders.exists(name) && !bound.exists(name) && !fieldBases.exists(name) && isSimpleIdentifier(name)) {
                                        missing.push(name);
                                    }
                                }

                                #if debug_option_some_binder
                                optionSomeLog('[OptionSomeDiag] Used vars=' + mapKeys(used) + ' pattern=' + mapKeys(patternBinders) + ' bound=' + mapKeys(bound) + ' fieldBases=' + mapKeys(fieldBases) + ' missingCandidates=' + missing.join(', '));
                                #end

                                // Do not rename the Option.Some binder unless needed.
                                // We'll start from existing pattern/body and apply strict rule before heuristics.
                                var newPattern = clause.pattern;
                                var newBody = clause.body;
                                var activeBinder = binderName;

                                // No app-specific binder names; rely on generic heuristics below.

                                // If the current binder is not referenced in the body but there is
                                // exactly one viable identifier referenced in the body that is not a
                                // field base nor already bound, prefer renaming the binder to that
                                // identifier to keep pattern/body aligned. This avoids undefined
                                // variable references without colliding with outer variables.
                                var binderUsed = used.exists(binderName);
                                if (!binderUsed) {
                                    var renameCandidates:Array<String> = [];
                                    for (name in used.keys()) {
                                        // Exclude module-like identifiers (start with uppercase) from candidates
                                        var isModuleLike = (name != null && name.length > 0 && name.charAt(0) == name.charAt(0).toUpperCase() && name.charAt(0) != name.charAt(0).toLowerCase());
                                        var isCandidate = !isModuleLike && isSimpleIdentifier(name)
                                            && name != binderName
                                            && !fieldBases.exists(name)
                                            && !bound.exists(name)
                                            && !patternBinders.exists(name);
                                        // Avoid obvious outer/param names if we have context
                                        if (isCandidate && context != null && context.functionParameterNames != null && context.functionParameterNames.exists(name)) {
                                            isCandidate = false;
                                        }
                                        if (isCandidate) renameCandidates.push(name);
                                    }
                                    if (renameCandidates.length == 1) {
                                        var chosen = renameCandidates[0];
                                        newPattern = replaceBinderName(newPattern, binderName, chosen);
                                        activeBinder = chosen;
                                        #if debug_option_some_binder
                                        optionSomeLog('[OptionSomeDiag] Binder unused in body; renaming "' + binderName + '" → "' + chosen + '" (single viable)');
                                        #end
                                    }
                                }

                                // If binder is used only as a field-base (e.g., msg/payload in Map.get)
                                // and there is exactly one other viable identifier referenced in the body,
                                // rename binder to that identifier to keep pattern/body aligned.
                                if (binderUsed && fieldBases.exists(binderName)) {
                                    var fbCandidates:Array<String> = [];
                                    for (name in used.keys()) {
                                        var isModuleLike = (name != null && name.length > 0 && name.charAt(0) == name.charAt(0).toUpperCase() && name.charAt(0) != name.charAt(0).toLowerCase());
                                        if (name == binderName) continue;
                                        var ok = !isModuleLike && isSimpleIdentifier(name)
                                            && !fieldBases.exists(name)
                                            && !bound.exists(name)
                                            && !patternBinders.exists(name);
                                        if (ok && context != null && context.functionParameterNames != null && context.functionParameterNames.exists(name)) ok = false;
                                        if (ok) fbCandidates.push(name);
                                    }
                                    if (fbCandidates.length == 1) {
                                        var chosen2 = fbCandidates[0];
                                        newPattern = replaceBinderName(newPattern, binderName, chosen2);
                                        activeBinder = chosen2;
                                        #if debug_option_some_binder
                                        optionSomeLog('[OptionSomeDiag] Binder used only as field-base; renaming ' + binderName + ' → ' + chosen2);
                                        #end
                                    }
                                }

                                // Compute remaining missing; if unresolved, inject alias
                                var finalBinders = collectPatternBinderNames(newPattern);
                                var aliasMissing:Array<String> = [];
                                for (name in used.keys()) {
                                    if (!finalBinders.exists(name) && !bound.exists(name) && !fieldBases.exists(name) && isSimpleIdentifier(name)) {
                                        aliasMissing.push(name);
                                    }
                                }
                                if (aliasMissing.length == 1) {
                                    newBody = injectOptionBinderAlias(newBody, activeBinder, aliasMissing[0]);
                                    #if debug_option_some_binder
                                    optionSomeLog('[OptionSomeDiag] Injected alias: ' + aliasMissing[0] + ' = ' + activeBinder);
                                    #end
                                }

                                #if debug_option_some_binder
                                optionSomeLog('[OptionSomeDiag] Final binder="' + activeBinder + '" remainingMissing=' + aliasMissing.join(', '));
                                #end

                                return { pattern: newPattern, guard: clause.guard, body: newBody };
                            default:
                        }
                    default:
                }
            default:
        }
        return clause;
    }

    static function patternPreview(pattern:EPattern):String {
        return switch (pattern) {
            case PTuple(elements):
                var parts = [for (el in elements) patternPreview(el)];
                '{' + parts.join(', ') + '}';
            case PLiteral({def: EAtom(atom)}): ':' + atom;
            case PVar(name): name;
            case PWildcard: '_';
            case PAlias(alias, inner): alias + ' as ' + patternPreview(inner);
            default: Type.enumConstructor(pattern);
        };
    }

    static function mapKeys(map:Map<String,Bool>):String {
        var keys:Array<String> = [];
        for (k in map.keys()) keys.push(k);
        return '[' + keys.join(', ') + ']';
    }

    static function findViableCandidate(candidates:Array<String>, bound:Map<String,Bool>, binderName:String, context:CompilationContext):Null<String> {
        for (name in candidates) {
            if (name == binderName) continue;
            if (bound.exists(name)) continue;
            if (!isSimpleIdentifier(name)) continue;
            // Avoid colliding with function parameters (e.g., outer msg/payload)
            if (context != null && context.functionParameterNames != null && context.functionParameterNames.exists(name)) continue;
            return name;
        }
        return null;
    }

    static function collectPatternBinderNames(pattern:EPattern):Map<String,Bool> {
        var names = new Map<String,Bool>();
        function visit(p:EPattern):Void {
            switch (p) {
                case PVar(n): names.set(n, true);
                case PTuple(list): for (entry in list) visit(entry);
                case PList(list): for (entry in list) visit(entry);
                case PCons(head, tail): visit(head); visit(tail);
                case PMap(pairs): for (kv in pairs) visit(kv.value);
                case PStruct(_, fields): for (f in fields) visit(f.value);
                case PAlias(varName, inner):
                    names.set(varName, true);
                    visit(inner);
                case PPin(inner): visit(inner);
                case PBinary(segments): for (seg in segments) visit(seg.pattern);
                default:
            }
        }
        visit(pattern);
        return names;
    }

    static function collectUsedVars(body:ElixirAST):Map<String,Bool> {
        var used = new Map<String,Bool>();
        function traverse(node:ElixirAST):Void {
            if (node == null) return;
            switch (node.def) {
                case EVar(name):
                    if (isSimpleIdentifier(name)) used.set(name, true);
                case EBinary(_, left, right):
                    traverse(left);
                    traverse(right);
                case ECall(target, _, args):
                    if (target != null) traverse(target);
                    for (a in args) traverse(a);
                case ERemoteCall(target, _, args):
                    traverse(target);
                    for (a in args) traverse(a);
                case EIf(cond, thenBranch, elseBranch):
                    traverse(cond);
                    traverse(thenBranch);
                    if (elseBranch != null) traverse(elseBranch);
                case EBlock(statements):
                    for (s in statements) traverse(s);
                case ECase(target, clauses):
                    traverse(target);
                    for (c in clauses) traverse(c.body);
                case ECond(conds):
                    for (c in conds) traverse(c.body);
                case EParen(inner): traverse(inner);
                case ETuple(items): for (item in items) traverse(item);
                default:
                    // continue recursion for nested nodes where needed
            }
        }
        traverse(body);
        return used;
    }

    /**
     * Collect identifiers that become *bound* inside the clause body itself.
     *
     * "Bound" here means any variable introduced by a pattern match, let-binding,
     * or assignment within the clause body (e.g. `alert_level = ...`, `case {:ok, level}`)
     * whose scope starts in the body. These names should never be reused as
     * Option.Some binders because doing so would shadow the freshly bound local.
     */
    static function collectBoundVars(body:ElixirAST):Map<String,Bool> {
        var bound = new Map<String,Bool>();

        function gather(p:EPattern):Void {
            switch (p) {
                case PVar(n): bound.set(n, true);
                case PTuple(list): for (entry in list) gather(entry);
                case PList(list): for (entry in list) gather(entry);
                case PCons(head, tail): gather(head); gather(tail);
                case PMap(pairs): for (kv in pairs) gather(kv.value);
                case PStruct(_, fields): for (f in fields) gather(f.value);
                case PAlias(varName, inner):
                    bound.set(varName, true);
                    gather(inner);
                case PPin(inner): gather(inner);
                case PBinary(segments): for (seg in segments) gather(seg.pattern);
                default:
            }
        }

        function traverse(node:ElixirAST):Void {
            if (node == null) return;
            switch (node.def) {
                case EMatch(pattern, expr):
                    gather(pattern);
                    traverse(expr);
                case EBlock(statements):
                    for (s in statements) traverse(s);
                case EIf(cond, thenBranch, elseBranch):
                    traverse(cond);
                    traverse(thenBranch);
                    if (elseBranch != null) traverse(elseBranch);
                case ECase(target, clauses):
                    traverse(target);
                    for (c in clauses) traverse(c.body);
                case ECond(conds):
                    for (c in conds) traverse(c.body);
                case ECall(target, _, args):
                    if (target != null) traverse(target);
                    for (a in args) traverse(a);
                case ERemoteCall(target, _, args):
                    traverse(target);
                    for (a in args) traverse(a);
                default:
                    // continue recursion as needed
            }
        }

        traverse(body);
        return bound;
    }

    static function collectFieldBaseVars(body:ElixirAST):Map<String,Bool> {
        var bases = new Map<String,Bool>();
        function traverse(node:ElixirAST):Void {
            if (node == null) return;
            switch (node.def) {
                case ERemoteCall({def: EVar("Map")}, func, args) if (func == "get" && args.length > 0):
                    switch (args[0].def) {
                        case EVar(name): bases.set(name, true);
                        default:
                    }
                    for (a in args) traverse(a);
                case EField(target, _):
                    traverse(target);
                case ECall(target, _, args):
                    if (target != null) traverse(target);
                    for (a in args) traverse(a);
                case ERemoteCall(target, _, args):
                    traverse(target);
                    for (a in args) traverse(a);
                case EBinary(_, left, right):
                    traverse(left);
                    traverse(right);
                case EBlock(statements):
                    for (s in statements) traverse(s);
                case EIf(cond, thenBranch, elseBranch):
                    traverse(cond);
                    traverse(thenBranch);
                    if (elseBranch != null) traverse(elseBranch);
                case ECase(target, clauses):
                    traverse(target);
                    for (c in clauses) traverse(c.body);
                case ECond(conds):
                    for (c in conds) traverse(c.body);
                default:
            }
        }
        traverse(body);
        return bases;
    }

    static function replaceBinderName(pattern:EPattern, oldName:String, newName:String):EPattern {
        function transform(p:EPattern):EPattern {
            return switch (p) {
                case PVar(n) if (n == oldName):
                    PVar(newName);
                case PAlias(varName, inner) if (varName == oldName):
                    PAlias(newName, transform(inner));
                case PTuple(list):
                    PTuple([for (entry in list) transform(entry)]);
                case PList(list):
                    PList([for (entry in list) transform(entry)]);
                case PCons(head, tail):
                    PCons(transform(head), transform(tail));
                case PMap(pairs):
                    PMap([for (kv in pairs) {key: kv.key, value: transform(kv.value)}]);
                case PStruct(module, fields):
                    PStruct(module, [for (f in fields) {key: f.key, value: transform(f.value)}]);
                case PBinary(segments):
                    PBinary([for (seg in segments) {pattern: transform(seg.pattern), size: seg.size, type: seg.type, modifiers: seg.modifiers}]);
                default:
                    p;
            };
        }
        return transform(pattern);
    }

    static function injectOptionBinderAlias(body:ElixirAST, binderName:String, missing:String):ElixirAST {
        if (missing == null || missing.length == 0) return body;
        var aliasExpr = makeAST(EMatch(PVar(missing), makeAST(EVar(binderName))));
        return switch (body.def) {
            case EBlock(statements):
                makeAST(EBlock([aliasExpr].concat(statements)));
            default:
                makeAST(EBlock([aliasExpr, body]));
        };
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
