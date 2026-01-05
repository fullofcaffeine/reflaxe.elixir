package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.EBinaryOp;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.optimizers.LoopOptimizer;
import reflaxe.elixir.ast.ElixirASTPatterns;
import reflaxe.elixir.ast.analyzers.VariableAnalyzer;
import reflaxe.elixir.ast.builders.ComprehensionBuilder;
import reflaxe.elixir.ast.ElixirASTBuilder;

/**
 * BlockBuilder: Handles block expression compilation and pattern detection
 * 
 * WHY: Centralizes massive block pattern detection logic from ElixirASTBuilder
 * - Extracts 1,285 lines of complex pattern matching logic
 * - Handles loop desugaring, array operations, comprehensions
 * - Manages null coalescing, inline expansions, list building
 * - Detects and transforms Map iterations, for loops, while loops
 * 
 * WHAT: Transforms Haxe TBlock expressions to idiomatic Elixir patterns
 * - Desugared for loop detection and transformation
 * - Map iteration pattern detection
 * - Array operation patterns (filter, map, etc.)
 * - Null coalescing patterns
 * - List building through concatenation
 * - Inline expansion patterns
 * - Complex statement combining
 * 
 * HOW: Multi-pass pattern detection with targeted transformations
 * - First pass: Detect high-priority patterns (Map iteration)
 * - Second pass: Loop desugaring patterns
 * - Third pass: Array operations and comprehensions
 * - Fourth pass: Null coalescing and inline patterns
 * - Final pass: General block construction
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on block patterns
 * - Open/Closed Principle: Can add new patterns without modifying core
 * - Testability: Block patterns can be tested independently
 * - Maintainability: 1,285 lines extracted to focused module
 * - Performance: Pattern detection optimized in one place
 * 
 * EDGE CASES:
 * - Empty blocks → EBlock([]) (generates no code, not 'nil')
 * - Single expression blocks → unwrap to expression
 * - Nested blocks → recursive pattern detection
 * - Infrastructure variables → skip generation (via empty blocks)
 * - Statement combining → merge related statements
 */
@:nullSafety(Off)
class BlockBuilder {
    
    /**
     * Build block expression with comprehensive pattern detection
     * 
     * WHY: Blocks contain complex desugared patterns that need transformation
     * WHAT: Detects and transforms various block patterns to idiomatic Elixir
     * HOW: Multi-pass pattern detection with priority ordering
     * 
     * @param el Array of expressions in the block
     * @param context Compilation context
     * @return ElixirASTDef for the block or transformed pattern
     */
    public static function build(el: Array<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        return withScopedInitTracking(el, context, function() {
        #if debug_ast_builder
        for (i in 0...Math.ceil(Math.min(5, el.length))) {
        }
        #end
        
        // Empty block case
        // ARCHITECTURE: Empty blocks represent "no code" (e.g., eliminated infrastructure variables)
        // Return EBlock([]) which prints as empty string, NOT ENil which prints as 'nil'
        if (el.length == 0) {
            #if debug_ast_builder
            #end
            return EBlock([]);
        }
        
        // Single expression - just return it unwrapped
        if (el.length == 1) {
            #if debug_ast_builder
            #end
            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(el[0], context);
            return result != null ? result.def : ENil;
        }

        // ====================================================================
        // PATTERN DETECTION: Map Literal Builder Blocks
        // ====================================================================
        //
        // Haxe desugars Map literals to a temp + repeated `set` calls:
        //   var g = new Map();
        //   g.set(k1, v1);
        //   g.set(k2, v2);
        //   g;
        //
        // For the Elixir target, emitting this shape and relying on later rebinding
        // is fragile (and can break when infra vars are eliminated too early).
        // Prefer compiling directly to an Elixir map literal `%{k1 => v1, k2 => v2}`.
        var mapLiteral = detectMapLiteralBuilder(el, context);
        if (mapLiteral != null) {
            return mapLiteral;
        }
        
        // ====================================================================
        // PATTERN DETECTION PHASE 4: Null Coalescing
        // ====================================================================
        if (el.length == 2) {
            #if debug_null_coalescing
            #end
            
            var nullCoalescingResult = detectNullCoalescingPattern(el, context);
            if (nullCoalescingResult != null) {
                #if debug_null_coalescing
                #end
                return nullCoalescingResult;
            }
        }
        
        // ====================================================================
        // PATTERN DETECTION PHASE 5: List Building
        // ====================================================================
        if (isListBuildingPattern(el)) {
            #if debug_array_comprehension
            #end
            return buildListComprehension(el, context);
        }

        // NEW: Multi‑segment list building (outer list‑of‑lists)
        // Detect repeated "temp = []" segments followed by concatenations and construct
        // a list of lists deterministically instead of leaking the mutable temp.
        var multi = detectMultiSegmentListOfLists(el);
        if (multi != null) {
            // Only apply when the last expression is an array literal of the same temp variable (e.g., [v, v, v])
            var last = el[el.length - 1];
            var tempInLast: Null<String> = null;
            switch (last.expr) {
                case TArrayDecl(items) if (items.length > 0):
                    var same = true;
                    var nameRef: String = null;
                    for (it in items) switch (it.expr) {
                        case TLocal(v):
                            if (nameRef == null) nameRef = v.name; else if (nameRef != v.name) same = false;
                        default: same = false;
                    }
                    if (same) tempInLast = nameRef;
                default:
            }
            if (tempInLast == null) {
                // Do not transform this block; keep default path
            } else {
                // Build full block: prefix statements + synthesized list-of-lists
                var build = context.getExpressionBuilder();
                var prefixBuilt: Array<ElixirAST> = [];
                for (p in multi.prefix) {
                    var pb = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(p, context);
                    if (pb != null) prefixBuilt.push(pb);
                }
                // Build [[...], [...], ...]
                var outer: Array<ElixirAST> = [];
                for (seg in multi.segments) {
                    var inner: Array<ElixirAST> = [];
                    for (v in seg) {
                        switch (v.expr) {
                            case TBlock(nested) if (ComprehensionBuilder.looksLikeListBuildingBlock(nested)):
                                var strictVals = ComprehensionBuilder.extractListElements(nested);
                                if (strictVals != null && strictVals.length > 0) for (sv in strictVals) inner.push(build(sv));
                                else {
                                    var looseVals = ComprehensionBuilder.extractListElementsLoose(nested, context);
                                    if (looseVals != null && looseVals.length > 0) inner.push({def: EList(looseVals), metadata: {}, pos: null});
                                    else inner.push(build(v));
                                }
                            default:
                                inner.push(build(v));
                        }
                    }
                    outer.push({def: EList(inner), metadata: {}, pos: null});
                }
                prefixBuilt.push({def: EList(outer), metadata: {}, pos: null});
                return EBlock(prefixBuilt);
            }
        }

        // ====================================================================
        // PATTERN DETECTION PHASE 6: Embedded Array Comprehensions
        // ====================================================================
        // NEW: Scan for comprehension sub-sequences within larger blocks
        // Pattern: doubled = n = 1; [] ++ [expr]; n = 2; ...; []
        if (el.length >= 3) {
            #if debug_array_comprehension
            #end

            var result = detectAndReplaceEmbeddedComprehensions(el, context);
            if (result != null) {
                #if debug_array_comprehension
                #end
                return result;
            }
        }

        // ====================================================================
        // DEFAULT: Build Regular Block
        // ====================================================================
        // Before falling back, attempt a lenient extraction of list-building
        // statements to avoid emitting invalid bare concatenations.
        if (el.length >= 2) {
            var loose = ComprehensionBuilder.extractListElementsLoose(el, context);
            if (loose != null && loose.length > 0) {
                #if debug_array_comprehension
                #end
                return EList(loose);
            }
        }

        return buildRegularBlock(el, context);
        });
    }
    
    /**
     * Detect null coalescing pattern
     */
    static function detectNullCoalescingPattern(el: Array<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        // Pattern: TVar followed by TBinop(OpNullCoal) using that var
        switch([el[0].expr, el[1].expr]) {
            case [TVar(tmpVar, init), TBinop(OpNullCoal, {expr: TLocal(v)}, defaultExpr)]
                if (v.id == tmpVar.id && init != null):
                // This is the null coalescing pattern
                if (context.compiler != null) {
                    // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                    // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                    var initAst = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(init, context);
                    var defaultAst = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(defaultExpr, context);
                    var tmpVarName = VariableAnalyzer.toElixirVarName(tmpVar.name);
                    
                    // Generate: if (tmp = init) != nil, do: tmp, else: default
                    var ifExpr = makeAST(EIf(
                        makeAST(EBinary(EBinaryOp.NotEqual, 
                            makeAST(EMatch(PVar(tmpVarName), initAst)),
                            makeAST(ENil)
                        )),
                        makeAST(EVar(tmpVarName)),
                        defaultAst
                    ));
                    
                    // Mark as inline for null coalescing
                    if (ifExpr.metadata == null) ifExpr.metadata = {};
                    ifExpr.metadata.keepInlineInAssignment = true;
                    
                    return ifExpr.def;
                }
            case _:
                // Not the null coalescing pattern
        }
        return null;
    }
    
    /**
     * Check if block is building a list through concatenations
     *
     * WHY: Detects both legacy and new unrolled comprehension patterns
     * WHAT: Checks for TWO patterns:
     *       1. Legacy: g = []; g ++ [val1]; g ++ [val2]; ...; g
     *       2. New: result = n = 1; [] ++ [n * 2]; n = 2; ...; []
     * HOW: Pattern detection based on first and last statements
     */
    static function isListBuildingPattern(el: Array<TypedExpr>): Bool {
        if (el.length < 3) return false;

        #if debug_ast_builder
        #end

        // Check if first statement is TVar with TBlock initialization (unrolled comprehension)
        var hasVarWithBlock = switch(el[0].expr) {
            case TVar(v, init) if (init != null):
                #if debug_ast_builder
                #end
                switch(init.expr) {
                    case TBlock(stmts):
                        #if debug_ast_builder
                        #end
                        true;
                    default: false;
                }
            default: false;
        };

        // Pattern 1: Legacy unrolled comprehension (g = []; g ++ [val]; g)
        var isLegacyPattern = switch(el[0].expr) {
            case TVar(_, init) if (init != null):
                switch(init.expr) {
                    case TArrayDecl([]): true;
                    default: false;
                }
            default: false;
        };

        if (isLegacyPattern) {
            // Check for concatenation pattern
            var hasConcatenations = false;
            for (i in 1...el.length - 1) {
                switch(el[i].expr) {
                    case TBinop(OpAdd, _, _): hasConcatenations = true;
                    case _:
                }
            }
            return hasConcatenations;
        }

        // Pattern 2: New chained assignment pattern (doubled = n = 1; [] ++ [expr]; n = 2; ...)
        var hasChainedAssignment = switch(el[0].expr) {
            case TBinop(OpAssign, {expr: TLocal(_)}, {expr: TBinop(OpAssign, {expr: TLocal(_)}, _)}):
                true;
            default: false;
        };

        #if debug_ast_builder
        #end

        if (hasChainedAssignment) {
            #if debug_ast_builder
            #end

            // Check last statement is empty array
            var lastIdx = el.length - 1;
            var endsWithEmptyArray = switch(el[lastIdx].expr) {
                case TArrayDecl([]): true;
                default: false;
            };

            #if debug_array_comprehension
            #end

            if (endsWithEmptyArray) {
                // Check middle statements have bare concatenations
                for (i in 1...lastIdx) {
                    switch(el[i].expr) {
                        case TBinop(OpAdd, {expr: TArrayDecl([])}, {expr: TArrayDecl(_)}):
                            #if debug_array_comprehension
                            #end
                            return true;  // Found bare concatenation - this is the pattern!
                        case _:
                    }
                }
                #if debug_array_comprehension
                #end
            }
        }

        return false;
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
     * Build list comprehension from concatenation pattern
     * 
     * WHY: List building through concatenation should be comprehensions
     * WHAT: Transforms g = []; g ++ [x]; patterns to for comprehensions
     * HOW: Extracts elements and generates for x <- list, do: transform(x)
     */
    static function buildListComprehension(el: Array<TypedExpr>, context: CompilationContext): ElixirASTDef {
        // Try to use ComprehensionBuilder if available
        var comprehension = ComprehensionBuilder.tryBuildArrayComprehensionFromBlock(el, context);
        if (comprehension != null) {
            return comprehension.def;
        }
        
        // Extract list elements manually
        var elements = ComprehensionBuilder.extractListElements(el);
        if (elements != null && elements.length > 0 && context.compiler != null) {
            // Build a simple list from the elements
            var listItems = [];
            for (elem in elements) {
                // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                var ast = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(elem, context);
                if (ast != null) {
                    listItems.push(ast);
                }
            }

            if (listItems.length > 0) {
                return EList(listItems);
            }
        }
        
        // Fallback to regular block
        return buildRegularBlock(el, context);
    }

    /**
     * Detect and replace embedded comprehension patterns within larger blocks
     *
     * WHY: Comprehensions may be embedded within blocks containing other statements
     * WHAT: Scans for chained assignment comprehension patterns and replaces them
     * HOW: Finds pattern start, extracts subsequence, builds comprehension, rebuilds block
     */
    static function detectAndReplaceEmbeddedComprehensions(el: Array<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        var i = 0;
        var statements = [];

        while (i < el.length) {
            // Check if current position starts a comprehension pattern
            // Pattern: doubled = n = 1; [] ++ [expr]; n = 2; ...; []
            var patternStart = i;
            var isComprehensionStart = false;

            if (i < el.length) {
                switch(el[i].expr) {
                    case TBinop(OpAssign, {expr: TLocal(_)}, {expr: TBinop(OpAssign, {expr: TLocal(_)}, _)}):
                        // Found chained assignment - potential comprehension start
                        isComprehensionStart = true;
                    default:
                }
            }

            if (isComprehensionStart) {
                // Find the end of the comprehension pattern (empty array)
                var patternEnd = -1;
                for (j in (i + 1)...el.length) {
                    switch(el[j].expr) {
                        case TArrayDecl([]):
                            // Check if this empty array ends the pattern
                            // (must have bare concatenations between start and here)
                            var hasBareConcat = false;
                            for (k in (i + 1)...j) {
                                switch(el[k].expr) {
                                    case TBinop(OpAdd, {expr: TArrayDecl([])}, {expr: TArrayDecl(_)}):
                                        hasBareConcat = true;
                                    default:
                                }
                            }
                            if (hasBareConcat) {
                                patternEnd = j;
                                break;
                            }
                        default:
                    }
                }

                if (patternEnd > patternStart) {
                    // Extract the comprehension subsequence
                    var comprehensionStmts = el.slice(patternStart, patternEnd + 1);

                    #if debug_array_comprehension
                    #end

                    // Try to build comprehension from this subsequence
                    var comprehension = ComprehensionBuilder.tryBuildArrayComprehensionFromBlock(comprehensionStmts, context);
                    if (comprehension != null) {
                        #if debug_array_comprehension
                        #end

                        // Add the comprehension as a statement
                        statements.push(comprehension);

                        // Skip past the comprehension pattern
                        i = patternEnd + 1;
                        continue;
                    }
                }
            }

            // Not a comprehension - process normally
            var stmt = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(el[i], context);
            if (stmt != null) {
                statements.push(stmt);
            }
            i++;
        }

        // If we replaced any comprehensions, return the rebuilt block
        if (statements.length != el.length) {
            return EBlock(statements);
        }

        return null;  // No comprehensions found
    }

    /**
     * Detect and compile Haxe's desugared Map-literal builder blocks into a literal `%{}`.
     *
     * Pattern (TypedExpr, simplified):
     *   TVar(mapVar, TNew(Map, ...))
     *   [zero or more TVar value temps]
     *   TCall(TField(TLocal(mapVar), "set"), [keyExpr, valueExpr])
     *   ...
     *   TLocal(mapVar)
     */
    static function detectMapLiteralBuilder(el: Array<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        if (el == null || el.length < 3) return null;

        // First statement must declare the map var.
        var mapVar: Null<TVar> = null;
        var mapInit: Null<TypedExpr> = null;
        switch (el[0].expr) {
            case TVar(v, init) if (init != null):
                mapVar = v;
                mapInit = init;
            default:
                return null;
        }

        // Must be a map constructor (`new Map()` / `new StringMap()` etc).
        var isMapCtor = switch (mapInit.expr) {
            case TNew(c, _, _):
                var ct = c.get();
                ct != null && (ct.name == "Map" || ct.name == "StringMap" || ct.name == "IntMap" || StringTools.endsWith(ct.name, "Map"));
            default:
                false;
        }
        if (!isMapCtor) return null;

        // Last statement must be returning the same var.
        var returnsMapVar = switch (el[el.length - 1].expr) {
            case TLocal(v) if (v.id == mapVar.id): true;
            default: false;
        }
        if (!returnsMapVar) return null;

        // Track simple value temps declared in the block and used as the value of a set call.
        var tempInits = new Map<Int, TypedExpr>(); // TVar.id -> init expr

        // Collect map.set calls.
        var pairs: Array<{ key: TypedExpr, value: TypedExpr }> = [];
        for (i in 1...el.length - 1) {
            var stmt = el[i];
            switch (stmt.expr) {
                case TVar(v, init) if (init != null):
                    // Keep temp initializers around for inline substitution when used once.
                    tempInits.set(v.id, init);

                case TCall(target, args) if (args != null && args.length == 2):
                    // Must be `mapVar.set(key, value)`.
                    var isSetOnMapVar = false;
                    switch (target.expr) {
                        case TField(obj, FInstance(_, _, cf)):
                            if (cf.get().name == "set") {
                                switch (obj.expr) {
                                    case TLocal(v) if (v.id == mapVar.id): isSetOnMapVar = true;
                                    default:
                                }
                            }
                        case TField(obj, FAnon(cf)):
                            if (cf.get().name == "set") {
                                switch (obj.expr) {
                                    case TLocal(v) if (v.id == mapVar.id): isSetOnMapVar = true;
                                    default:
                                }
                            }
                        case TField(obj, FDynamic(name)):
                            if (name == "set") {
                                switch (obj.expr) {
                                    case TLocal(v) if (v.id == mapVar.id): isSetOnMapVar = true;
                                    default:
                                }
                            }
                        default:
                    }
                    if (!isSetOnMapVar) return null;

                    var keyExpr = args[0];
                    var valueExpr = args[1];

                    // Inline a simple `tmp` value when the set call uses it directly.
                    switch (valueExpr.expr) {
                        case TLocal(v) if (tempInits.exists(v.id)):
                            valueExpr = tempInits.get(v.id);
                        default:
                    }

                    pairs.push({ key: keyExpr, value: valueExpr });

                default:
                    // Unknown statement in the middle - not a pure map builder.
                    return null;
            }
        }

        if (pairs.length == 0) return null;

        var buildExpression = context.getExpressionBuilder();
        var mapPairs: Array<reflaxe.elixir.ast.ElixirAST.EMapPair> = [];
        for (p in pairs) {
            var keyAst = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(p.key, context);
            var valueAst = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(p.value, context);
            if (keyAst == null || valueAst == null) return null;
            mapPairs.push({ key: keyAst, value: valueAst });
        }

        return EMap(mapPairs);
    }

    /**
     * Check for inline expansion patterns
     */
    static function checkForInlineExpansion(el: Array<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        if (ElixirASTPatterns.isInlineExpansionBlock(el)) {
            return ElixirASTPatterns.transformInlineExpansion(
                el,
                // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                function(e) return reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e, context),
                function(name) return VariableAnalyzer.toElixirVarName(name)
            );
        }
        return null;
    }
    
    /**
     * Track infrastructure variables
     */
    static function trackInfrastructureVars(el: Array<TypedExpr>, context: CompilationContext): Array<{name: String, had: Bool, value: Null<ElixirAST>}> {
        if (el == null) return [];

        // Track infrastructure variables for later use, but keep mappings scoped to this block.
        // Haxe often reuses infra names like `_g1` across nested blocks; using a single global
        // map without restoration can leak incorrect bounds into later codegen.
        var snapshots: Array<{name: String, had: Bool, value: Null<ElixirAST>}> = [];
        var captured = new Map<String, Bool>();

        for (expr in el) {
            switch(expr.expr) {
                case TVar(v, init) if (init != null && isInfrastructureVar(v.name)):
                    if (!captured.exists(v.name)) {
                        var had = context.infrastructureVarInitValues.exists(v.name);
                        var value = had ? context.infrastructureVarInitValues.get(v.name) : null;
                        snapshots.push({name: v.name, had: had, value: value});
                        captured.set(v.name, true);
                    }

                    // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                    // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                    var initAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(init, context);
                    context.infrastructureVarInitValues.set(v.name, initAST);

                    #if debug_infrastructure_vars
                    #end
                default:
                    // Not an infrastructure variable declaration
            }
        }

        return snapshots;
    }

    static function shouldTrackLocalInitValueById(varName: String): Bool {
        if (varName == null) return false;

        // Always track classic infra vars (_g/_g1/...) because loop lowering needs their seeds.
        if (isInfrastructureVar(varName)) return true;

        // Haxe 5 preview can emit temps with backticks preserved in the typed AST.
        // If stripping backticks yields an empty identifier, name-keyed tracking is useless and
        // we must rely on TVar.id-keyed init tracking to recover loop bounds safely.
        if (varName.indexOf("`") != -1) {
            var stripped = varName.split("`").join("");
            return StringTools.trim(stripped).length == 0;
        }

        return false;
    }

    static function trackLocalInitValuesById(
        el: Array<TypedExpr>,
        context: CompilationContext
    ): Array<{id: Int, had: Bool, value: Null<ElixirAST>}> {
        if (el == null) return [];
        if (context.localVarInitValuesById == null) context.localVarInitValuesById = new Map();

        var snapshots: Array<{id: Int, had: Bool, value: Null<ElixirAST>}> = [];
        var captured = new Map<Int, Bool>();

        for (expr in el) {
            switch (expr.expr) {
                case TVar(v, init) if (init != null && shouldTrackLocalInitValueById(v.name)):
                    #if debug_haxe5_loop_seeds
                    if (v.name != null && v.name.indexOf("`") != -1) {
                        trace('[haxe5-loop-seeds] trackLocalInitValuesById: name="${v.name}" id=${v.id} init='
                            + reflaxe.elixir.util.EnumReflection.enumConstructor(init.expr));
                    }
                    #end
                    if (!captured.exists(v.id)) {
                        var had = context.localVarInitValuesById.exists(v.id);
                        var value = had ? context.localVarInitValuesById.get(v.id) : null;
                        snapshots.push({id: v.id, had: had, value: value});
                        captured.set(v.id, true);
                    }

                    var initAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(init, context);
                    context.localVarInitValuesById.set(v.id, initAST);
                default:
            }
        }

        return snapshots;
    }

    static function restoreLocalInitValuesById(snapshots: Array<{id: Int, had: Bool, value: Null<ElixirAST>}>, context: CompilationContext): Void {
        if (snapshots == null || context == null || context.localVarInitValuesById == null) return;
        for (snapshot in snapshots) {
            if (snapshot.had) {
                context.localVarInitValuesById.set(snapshot.id, snapshot.value);
            } else {
                context.localVarInitValuesById.remove(snapshot.id);
            }
        }
    }

    static function restoreInfrastructureVars(snapshots: Array<{name: String, had: Bool, value: Null<ElixirAST>}>, context: CompilationContext): Void {
        if (snapshots == null) return;
        for (snapshot in snapshots) {
            if (snapshot.had) {
                context.infrastructureVarInitValues.set(snapshot.name, snapshot.value);
            } else {
                context.infrastructureVarInitValues.remove(snapshot.name);
            }
        }
    }

    /**
     * Execute a compilation callback with block-scoped init tracking enabled.
     *
     * WHY
     * - Some block compilation paths (e.g., special-case hoists in ElixirASTBuilder) build
     *   statements manually and bypass BlockBuilder.buildRegularBlock.
     * - Loop lowering relies on initializer tracking (`infrastructureVarInitValues` and
     *   `localVarInitValuesById`) to recover desugared `for` loop bounds safely.
     *
     * WHAT
     * - Temporarily populates init maps for the duration of `fn`, then restores prior values.
     *
     * HOW
     * - Mirrors buildRegularBlock's tracking + restoration behavior without forcing callers
     *   to route through BlockBuilder's full block compilation logic.
     */
    public static function withScopedInitTracking<T>(
        el: Array<TypedExpr>,
        context: CompilationContext,
        fn: () -> T
    ): T {
        if (context == null || fn == null) return fn();

        var infraSnapshots = trackInfrastructureVars(el, context);
        var localInitSnapshots = trackLocalInitValuesById(el, context);
        try {
            var result = fn();
            restoreInfrastructureVars(infraSnapshots, context);
            restoreLocalInitValuesById(localInitSnapshots, context);
            return result;
        } catch (e: Any) {
            restoreInfrastructureVars(infraSnapshots, context);
            restoreLocalInitValuesById(localInitSnapshots, context);
            throw e;
        }
    }
    
    /**
     * Build regular block without special patterns
     */
    static function buildRegularBlock(el: Array<TypedExpr>, context: CompilationContext): ElixirASTDef {
        if (context.compiler == null) {
            return ENil;
        }

        var result: ElixirASTDef = ENil;
        var didSetResult = false;
        // Check for inline expansion patterns
        var inlineResult = checkForInlineExpansion(el, context);
        if (inlineResult != null) {
            result = inlineResult;
            didSetResult = true;
        } else {
            var expressions: Array<ElixirAST> = [];

            for (expr in el) {
                // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                var compiled = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);
                if (compiled != null) {
                    expressions.push(compiled);
                }
            }

            // Check for combining TVar and TBinop patterns
            if (expressions.length >= 2) {
                var combined = attemptStatementCombining(expressions);
                if (combined != null) {
                    result = combined;
                    didSetResult = true;
                }
            }

            if (!didSetResult) {
                // Handle empty blocks
                if (expressions.length == 0) {
                    result = ENil;
                } else if (expressions.length == 1) {
                    // Single expression blocks can be unwrapped
                    result = expressions[0].def;
                } else {
                    result = EBlock(expressions);
                }
            }
        }

        return result;
    }
    
    /**
     * Attempt to combine related statements
     * 
     * WHY: Some patterns generate separate statements that should be combined
     * WHAT: Combines TVar + TBinop and similar patterns
     * HOW: Pattern matches on statement sequences
     */
    static function attemptStatementCombining(expressions: Array<ElixirAST>): Null<ElixirASTDef> {
        if (expressions.length < 2) return null;
        
        // Check for null coalescing pattern in AST form
        switch([expressions[0].def, expressions[1].def]) {
            case [EMatch(PVar(varName), init), EIf(cond, thenBranch, elseBranch)]:
                // Check if this is the null coalescing pattern
                switch(cond.def) {
                    case EBinary(EBinaryOp.NotEqual, matchExpr, nilExpr):
                        switch([matchExpr.def, nilExpr.def]) {
                            case [EMatch(PVar(v), _), ENil] if (v == varName):
                                // This is null coalescing, combine into inline if
                                var ifExpr = makeAST(EIf(cond, thenBranch, elseBranch));
                                if (ifExpr.metadata == null) ifExpr.metadata = {};
                                ifExpr.metadata.keepInlineInAssignment = true;
                                return ifExpr.def;
                            default:
                        }
                    default:
                }
            default:
        }
        
        // Check for infrastructure variable + switch pattern
        // CRITICAL: This preserves `var _g = expr; switch(_g)` patterns from Haxe desugaring
        if (expressions.length == 2) {
            #if debug_ast_builder
            #end

            switch(expressions[0].def) {
                case EMatch(PVar(varName), init):
                    #if debug_ast_builder
                    #end

                    // Check if varName is infrastructure variable (_g, _g1, g, g1, etc.)
                    if (isInfrastructureVar(varName)) {
                        #if debug_ast_builder
                        #end
                        // Keep both statements - infrastructure var is needed for switch
                        return EBlock(expressions);
                    }
                default:
                    #if debug_ast_builder
                    #end
            }
        }
        
        return null;
    }

    /**
     * Detects repeated segments of the form:
     *   v = [];
     *   v = v ++ [x]; v = v ++ [y]; ...
     *   v = [];
     *   v = v ++ [a]; ...
     * and constructs a list of lists: [[x,y,...],[a,...], ...]
     * This repairs shapes where a mutable temp leaks into the final array literal
     * (e.g., [v, v, v]) by materializing each segment's value.
     */
    static function detectMultiSegmentListOfLists(el: Array<TypedExpr>): Null<{prefix:Array<TypedExpr>, segments:Array<Array<TypedExpr>>}> {
        if (el.length < 3) return null;

        // Track the candidate temp variable and collect segments
        var temp: String = null;
        var segments: Array<Array<TypedExpr>> = [];
        var current: Array<TypedExpr> = null;
        var prefix: Array<TypedExpr> = [];
        var inPattern = false;

        inline function pushSegment() {
            if (current != null && current.length > 0) segments.push(current);
            current = [];
        }

        // Scan statements for resets and concatenations
        for (stmt in el) {
            var s = switch (stmt.expr) {
                case TMeta({name: ":mergeBlock" | ":implicitReturn"}, e) | TParenthesis(e): e;
                default: stmt;
            };
            switch (s.expr) {
                case TVar(v, init) if (init != null && switch (init.expr) { case TArrayDecl([]): true; default: false; }):
                    if (temp == null) temp = v.name;
                    if (v.name == temp) { pushSegment(); inPattern = true; }
                case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TArrayDecl([])}):
                    if (temp == null) temp = v.name;
                    if (v.name == temp) { pushSegment(); inPattern = true; }
                case TBinop(OpAssignOp(OpAdd), {expr: TLocal(v)}, {expr: TArrayDecl([value])}) if (temp != null && v.name == temp):
                    if (current == null) current = [];
                    current.push(value);
                case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, _, {expr: TArrayDecl([value])})}) if (temp != null && v.name == temp):
                    if (current == null) current = [];
                    current.push(value);
                case TBinop(OpAssignOp(OpAdd), {expr: TLocal(v)}, {expr: TBlock(blockStmts)}) if (temp != null && v.name == temp):
                    // Nested block appends a whole list; capture as a block value
                    if (current == null) current = [];
                    current.push({t: s.t, pos: s.pos, expr: TBlock(blockStmts)});
                case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, _, {expr: TBlock(blockStmts)})}) if (temp != null && v.name == temp):
                    if (current == null) current = [];
                    current.push({t: s.t, pos: s.pos, expr: TBlock(blockStmts)});
                default:
                    if (!inPattern) prefix.push(stmt);
            }
        }
        pushSegment();

        if (temp == null || segments.length == 0) return null;
        return {prefix: prefix, segments: segments};
    }
}

#end
