package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
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
        trace('[SwitchBuilder START] Compiling switch at ${e.pos}');
        trace('[SwitchBuilder START] Switch target: ${Type.enumConstructor(e.expr)}');

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
        trace('[SwitchBuilder DEBUG] Switch target expression type: ${Type.enumConstructor(actualSwitchExpr.expr)}');
        if (targetVarName != null) {
            trace('[SwitchBuilder DEBUG] Extracted variable name: ${targetVarName}');
            trace('[SwitchBuilder DEBUG] Is infrastructure var: ${isInfrastructureVar(targetVarName)}');
        }

        if (targetVarName != null && isInfrastructureVar(targetVarName)) {
            trace('[SwitchBuilder DEBUG] Infrastructure variable detected but not handled!');
        }

        // Build the switch target expression (use actual enum, not index)
        var targetAST = if (context.compiler != null) {
            // Apply infrastructure variable substitution before re-compilation
            var substitutedTarget = context.substituteIfNeeded(actualSwitchExpr);
            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(substitutedTarget, context);
            trace('[SwitchBuilder DEBUG] Compiled target AST: ${Type.enumConstructor(result.def)}');
            // DEBUG: Show exact variable name if it's EVar
            switch(result.def) {
                case EVar(name):
                    trace('[SwitchBuilder DEBUG] EVar variable name: "${name}"');
                default:
            }
            result;
        } else {
            return null;  // Can't proceed without compiler
        }

        if (targetAST == null) {
            trace('[SwitchBuilder ERROR] Target AST compilation returned null!');
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
            trace('[SwitchBuilder] Building case ${i + 1}/${cases.length}');
            var clausesFromCase = buildCaseClause(switchCase, targetVarName, context);
            if (clausesFromCase.length > 0) {
                trace('[SwitchBuilder]   Generated ${clausesFromCase.length} clause(s) from this case');
                for (clause in clausesFromCase) {
                    caseClauses.push(clause);
                }
            } else {
                trace('[SwitchBuilder]   Case clause build returned empty array!');
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
    static function buildCaseClause(switchCase: {values:Array<TypedExpr>, expr:TypedExpr}, targetVarName: String, context: CompilationContext): Array<ECaseClause> {
        // Handle multiple values in one case (fall-through pattern)
        if (switchCase.values.length == 0) {
            return [];
        }

        // For now, handle single value cases (most common)
        // TODO: Handle multiple values with pattern alternatives
        var value = switchCase.values[0];

        // CRITICAL: Extract pattern variables from the CASE PATTERN, not the guard
        // The pattern (switchCase.values[0]) has the user's intended variable names (n, n, n...)
        // The guard (switchCase.expr) has Haxe's renamed variables (n, n2, n3...) - WRONG!
        // We need the canonical pattern names for consistent mapping
        trace('[SwitchBuilder] ====== PATTERN ANALYSIS ======');
        trace('[SwitchBuilder] Pattern expr type: ${Type.enumConstructor(value.expr)}');

        // CRITICAL FIX: Extract canonical variable names from GUARD when available
        // TEnumIndex changes pattern TLocal names (n → value), so we extract from guard instead
        var patternVars: Array<String> = [];

        // CRITICAL FIX: Unwrap TBlock before checking for TIf (guards are often wrapped)
        var exprForExtraction = switchCase.expr;
        switch(switchCase.expr.expr) {
            case TBlock(exprs):
                // Search for TIf in the block
                for (expr in exprs) {
                    if (Type.enumConstructor(expr.expr) == "TIf") {
                        exprForExtraction = expr;
                        break;
                    }
                }
            default:
                // Not wrapped in block
        }

        // Check if this case has a guard (TIf structure with condition containing variable)
        var guardVar: Null<String> = switch(exprForExtraction.expr) {
            case TIf(econd, _, _):
                // Guard exists - extract TLocal name from condition
                extractFirstTLocalName(econd);
            default:
                null;
        };

        if (guardVar != null) {
            // Has guard - use guard variable with stripped suffix as canonical name
            patternVars = [stripNumericSuffix(guardVar)];
        } else {
            // No guard - extract from pattern
            var patternVarsFromPattern = extractVarsFromPatternExpr(value);
            if (patternVarsFromPattern.length > 0) {
                patternVars = patternVarsFromPattern;
            }
        }

        // CRITICAL: Extract TLocal IDs from guard and register in tempVarRenameMap
        // This ensures guard expressions compile with the same variable names as patterns
        // Without this, guards get different names (n, n2, n3) due to independent TLocal instances
        // NOTE: TLocal variables look up names via context.tempVarRenameMap (ElixirASTBuilder.hx:557)
        var tvarMapping = extractTLocalIDsFromGuard(switchCase.expr, patternVars);

        #if debug_guard_compilation
        trace('[SwitchBuilder] Registering ${tvarMapping.keys().length} TLocal mapping(s) in tempVarRenameMap:');
        for (tvarId in tvarMapping.keys()) {
            var name = tvarMapping.get(tvarId);
            var idKey = Std.string(tvarId);  // Convert ID to string key format
            trace('[SwitchBuilder]   TLocal#${tvarId} → ${name}');
            context.tempVarRenameMap.set(idKey, name);
        }
        #else
        // Register mappings (without debug output)
        for (tvarId in tvarMapping.keys()) {
            var idKey = Std.string(tvarId);  // Convert ID to string key format
            context.tempVarRenameMap.set(idKey, tvarMapping.get(tvarId));
        }
        #end

        // Build pattern from case value (pass pattern variables for idiomatic enum patterns)
        var pattern = buildPattern(value, targetVarName, patternVars, context);
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

            if (body != null) {
                clauses.push({
                    pattern: pattern,
                    guard: null,
                    body: body
                });
            }
        }

        return clauses;
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

        trace('[GuardChain] Starting extraction, expr type: ${Type.enumConstructor(current.expr)}');

        // Traverse the if-else chain
        while (true) {
            switch(current.expr) {
                case TIf(econd, eif, eelse):
                    trace('[GuardChain] Found TIf - extracting guard');
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
                    var body = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(substitutedBody, context);

                    clauses.push({
                        pattern: pattern,
                        guard: null,
                        body: body
                    });
                    break;
            }
        }

        trace('[GuardChain] Extracted ${clauses.length} total clauses');
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
     */
    static function buildPattern(value: TypedExpr, targetVarName: String, guardVars: Array<String>, context: CompilationContext): Null<EPattern> {
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
                                return generateIdiomaticEnumPattern(constructor, guardVars, context);
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
                    trace('[SwitchBuilder]     Confirmed enum constructor, building enum pattern');
                    return buildEnumPattern(e, args, guardVars, context);
                }
                trace('[SwitchBuilder]     Not an enum constructor');
                return null;

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
     * Generate idiomatic Elixir pattern for enum constructor
     *
     * WHY: Convert recovered enum constructors to idiomatic {:atom, params} patterns
     * WHAT: Creates tuple patterns with user's variable names from guards when available
     * HOW: Uses guardVars if provided, otherwise falls back to EnumField parameter names
     *
     * CRITICAL: When TEnumIndex optimization loses variable names, we recover them from guard conditions
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
        trace('[SwitchBuilder] Extracted ${mapping.keys().length} TLocal ID mapping(s):');
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

            // Priority 1: Guard variable (from user's guard condition)
            var guardVar = (guardVars != null && i < guardVars.length) ? guardVars[i] : null;

            // Priority 2: EnumField parameter name (fallback)
            var enumParam = i < parameterNames.length ? parameterNames[i] : null;

            switch(arg.expr) {
                case TLocal(v):
                    // CRITICAL: Use source variable name with priority system
                    // 1. guardVar (from guard like "n > 0") - most specific
                    // 2. v.name (from TLocal in pattern) - user's choice
                    // 3. enumParam (from enum definition) - fallback
                    var sourceName = guardVar != null ? guardVar : v.name;

                    trace('[SwitchBuilder] *** PATTERN VAR DEBUG ***');
                    trace('[SwitchBuilder]   Index: $i');
                    trace('[SwitchBuilder]   GuardVar: ${guardVar}');
                    trace('[SwitchBuilder]   TLocal v.name: ${v.name}');
                    trace('[SwitchBuilder]   EnumParam: ${enumParam}');
                    trace('[SwitchBuilder]   Using sourceName: ${sourceName}');

                    var varName = VariableAnalyzer.toElixirVarName(sourceName);
                    trace('[SwitchBuilder]   Final varName: ${varName}');

                    patterns.push(PVar(varName));
                default:
                    // Use underscore for non-variable patterns
                    patterns.push(PWildcard);
            }
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