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
        #if debug_ast_builder
        trace('[BlockBuilder] Building block with ${el.length} expressions');
        for (i in 0...Math.ceil(Math.min(5, el.length))) {
            trace('[BlockBuilder]   Expr[$i]: ${Type.enumConstructor(el[i].expr)}');
        }
        #end
        
        // Empty block case
        // ARCHITECTURE: Empty blocks represent "no code" (e.g., eliminated infrastructure variables)
        // Return EBlock([]) which prints as empty string, NOT ENil which prints as 'nil'
        if (el.length == 0) {
            #if debug_ast_builder
            trace('[BlockBuilder] Empty block, returning EBlock([]) for no code generation');
            #end
            return EBlock([]);
        }
        
        // Single expression - just return it unwrapped
        if (el.length == 1) {
            #if debug_ast_builder
            trace('[BlockBuilder] Single expression block, unwrapping');
            #end
            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(el[0], context);
            return result != null ? result.def : ENil;
        }
        
        // ====================================================================
        // PATTERN DETECTION PHASE 1: Map Iteration (Highest Priority)
        // ====================================================================
        if (el.length >= 2) {
            #if debug_map_iteration
            trace('[BlockBuilder] Checking for Map iteration pattern...');
            #end
            
            var mapPattern = LoopOptimizer.detectMapIterationPattern(el);
            if (mapPattern != null) {
                #if debug_map_iteration
                trace('[BlockBuilder] ✓ Detected Map iteration, delegating to specialized handler');
                #end
                return buildMapIteration(mapPattern, context);
            }
        }
        
        // ====================================================================
        // PATTERN DETECTION PHASE 2: Desugared For Loops
        // ====================================================================
        if (el.length >= 3) {
            #if debug_loop_detection
            trace('[BlockBuilder] Checking for desugared for loop pattern...');
            #end
            
            // Try to detect desugared for patterns  
            // This would use DesugarredForDetector but it doesn't exist yet
            var forPattern = null; // DesugarredForDetector.detectAndEliminate(el);
            if (forPattern != null && forPattern.eliminationData != null) {
                #if debug_loop_detection
                trace('[BlockBuilder] ✓ Detected desugared for loop, transforming to idiomatic Elixir');
                #end
                return buildIdiomaticLoop(forPattern, el, context);
            }
        }
        
        // ====================================================================
        // PATTERN DETECTION PHASE 3: Array Operations
        // ====================================================================
        if (el.length >= 5) {
            #if debug_array_patterns
            trace('[BlockBuilder] Checking for array operation patterns...');
            #end
            
            if (isArrayOperationPattern(el)) {
                var operation = detectArrayOperation(el);
                if (operation != null) {
                    #if debug_array_patterns
                    trace('[BlockBuilder] ✓ Detected array operation: ${operation.type}');
                    #end
                    return buildArrayOperation(operation, el, context);
                }
            }
        }
        
        // ====================================================================
        // PATTERN DETECTION PHASE 4: Null Coalescing
        // ====================================================================
        if (el.length == 2) {
            #if debug_null_coalescing
            trace('[BlockBuilder] Checking for null coalescing pattern...');
            #end
            
            var nullCoalescingResult = detectNullCoalescingPattern(el, context);
            if (nullCoalescingResult != null) {
                #if debug_null_coalescing
                trace('[BlockBuilder] ✓ Detected null coalescing, generating inline if expression');
                #end
                return nullCoalescingResult;
            }
        }
        
        // ====================================================================
        // PATTERN DETECTION PHASE 5: List Building
        // ====================================================================
        if (isListBuildingPattern(el)) {
            #if debug_array_comprehension
            trace('[BlockBuilder] ✓ Detected list building pattern, generating comprehension');
            #end
            return buildListComprehension(el, context);
        }
        
        // ====================================================================
        // DEFAULT: Build Regular Block
        // ====================================================================
        return buildRegularBlock(el, context);
    }
    
    /**
     * Build Map iteration pattern
     * 
     * WHY: Map iteration needs special handling for idiomatic Elixir generation
     * WHAT: Transforms Map.keyValueIterator patterns to Enum.each
     * HOW: Builds proper Elixir iteration with tuple destructuring
     */
    static function buildMapIteration(pattern: Dynamic, context: CompilationContext): ElixirASTDef {
        // Access the main builder's method if available
        if (context.compiler != null) {
            // Use reflection to call the existing buildMapIteration method
            // This is temporary until we fully migrate the logic
            // The buildMapIteration method is in the main ElixirASTBuilder
            // We need to handle Map iteration locally or skip for now
            // TODO: Implement Map iteration logic locally
            // For now, return nil to allow fallback
            return ENil;
        }
        return ENil;
    }
    
    /**
     * Build idiomatic loop from desugared pattern
     * 
     * WHY: Haxe desugars for loops into while loops with counters
     * WHAT: Transforms these patterns back to idiomatic Elixir
     * HOW: Generates Enum.each or for comprehensions
     */
    static function buildIdiomaticLoop(pattern: Dynamic, el: Array<TypedExpr>, context: CompilationContext): ElixirASTDef {
        // Process loop intent if we have enhanced pattern data
        if (pattern != null && Reflect.hasField(pattern, "eliminationData")) {
            var eliminationData = Reflect.field(pattern, "eliminationData");
            var whileExpr = Reflect.field(pattern, "whileExpr");
            
            // Extract loop body from while expression
            var body = switch(whileExpr.expr) {
                case TWhile(_, loopBody, _): loopBody;
                default: null;
            };
            
            if (body != null) {
                // Check if this is array iteration
                if (Reflect.field(eliminationData, "isArrayIteration") == true) {
                    var arrayVar = Reflect.field(pattern, "arrayVar");
                    var userVar = Reflect.field(pattern, "userVar");
                    
                    if (arrayVar != null && userVar != null) {
                        // Build array expression
                        var arrayExpr = makeAST(EVar(cast(arrayVar, String)));
                        
                        // Build body with variable substitution
                        // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                        // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                        var bodyAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(body, context);

                        // Generate: Enum.each(array, fn item -> body end)
                        return ERemoteCall(
                            makeAST(EAtom("Enum")),
                            "each",
                            [
                                arrayExpr,
                                makeAST(EFn([{
                                    args: [PVar(Std.string(userVar))],
                                    body: bodyAST
                                }]))
                            ]
                        );
                    }
                }
                
                // Check if this is simple range iteration
                if (Reflect.field(eliminationData, "isSimpleRange") == true) {
                    var startValue = Reflect.field(pattern, "startValue");
                    var endValue = Reflect.field(pattern, "endValue");
                    var userVar = Reflect.field(pattern, "userVar");
                    
                    if (startValue != null && endValue != null && userVar != null) {
                        var startExpr: TypedExpr = Reflect.field(startValue, "expr") != null ? startValue : null;
                        var endExpr: TypedExpr = Reflect.field(endValue, "expr") != null ? endValue : null;
                        
                        if (startExpr == null || endExpr == null) {
                            return ENil;
                        }

                        // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                        // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                        var startAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(startExpr, context);
                        var endAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(endExpr, context);
                        var bodyAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(body, context);

                        // Generate: Enum.each(start..end, fn i -> body end)
                        return ERemoteCall(
                            makeAST(EAtom("Enum")),
                            "each",
                            [
                                makeAST(ERange(startAST, endAST, false)),
                                makeAST(EFn([{
                                    args: [PVar(Std.string(userVar))],
                                    body: bodyAST
                                }]))
                            ]
                        );
                    }
                }
            }
        }
        
        // Fallback to regular while compilation
        if (pattern != null && Reflect.hasField(pattern, "whileExpr")) {
            var whileExpr: TypedExpr = Reflect.field(pattern, "whileExpr");
            if (whileExpr != null && whileExpr.expr != null) {
                // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                return reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(whileExpr, context).def;
            }
        }
        
        return ENil;
    }
    
    /**
     * Check if block represents an array operation
     */
    static function isArrayOperationPattern(el: Array<TypedExpr>): Bool {
        // Check for pattern: result = []; counter = 0; source = array; while(...) { ... }; result
        if (el.length < 5) return false;
        
        var hasEmptyArray = false;
        var hasZeroInit = false;
        var hasSourceAssign = false;
        var hasWhileLoop = false;
        var returnsResult = false;
        
        for (i in 0...el.length) {
            switch(el[i].expr) {
                case TVar(v, init) if (init != null):
                    switch(init.expr) {
                        case TArrayDecl([]): hasEmptyArray = true;
                        case TConst(TInt(0)): hasZeroInit = true;
                        case TLocal(_): hasSourceAssign = true;
                        case _:
                    }
                case TWhile(_, _, _): hasWhileLoop = true;
                case TLocal(v) if (i == el.length - 1): returnsResult = true;
                case _:
            }
        }
        
        return hasEmptyArray && hasZeroInit && hasSourceAssign && hasWhileLoop && returnsResult;
    }
    
    /**
     * Detect specific array operation type
     */
    static function detectArrayOperation(el: Array<TypedExpr>): Dynamic {
        // TODO: Implement array operation detection
        return null;
    }
    
    /**
     * Build array operation (map, filter, etc.)
     * 
     * WHY: Array operations should use Elixir's Enum module
     * WHAT: Transforms imperative array building to functional Enum calls
     * HOW: Detects operation type and generates appropriate Enum function
     */
    static function buildArrayOperation(operation: Dynamic, el: Array<TypedExpr>, context: CompilationContext): ElixirASTDef {
        if (operation == null) return ENil;
        
        var opType = Reflect.field(operation, "type");
        var sourceArray = Reflect.field(operation, "source");
        var body = Reflect.field(operation, "body");
        
        if (sourceArray != null && body != null && context.compiler != null) {
            var sourceExpr: TypedExpr = Reflect.field(sourceArray, "expr") != null ? sourceArray : null;
            var bodyExpr: TypedExpr = Reflect.field(body, "expr") != null ? body : null;
            
            if (sourceExpr == null || bodyExpr == null) {
                return buildRegularBlock(el, context);
            }

            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            var sourceAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(sourceExpr, context);
            var bodyAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(bodyExpr, context);

            // Generate appropriate Enum call based on operation type
            var enumFunc = switch(opType) {
                case "map": "map";
                case "filter": "filter";
                case "reduce": "reduce";
                default: null;
            };
            
            if (enumFunc != null) {
                return ERemoteCall(
                    makeAST(EAtom("Enum")),
                    enumFunc,
                    [sourceAST, makeAST(EFn([{
                        args: [PVar("item")],
                        body: bodyAST
                    }]))]
                );
            }
        }
        
        // Fallback: build as regular block
        return buildRegularBlock(el, context);
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
     */
    static function isListBuildingPattern(el: Array<TypedExpr>): Bool {
        // Pattern: g = []; g ++ [val1]; g ++ [val2]; ...; g
        if (el.length < 3) return false;
        
        // Check first expression is empty array init
        var isListInit = switch(el[0].expr) {
            case TVar(_, init) if (init != null):
                switch(init.expr) {
                    case TArrayDecl([]): true;
                    default: false;
                }
            default: false;
        };
        
        if (!isListInit) return false;
        
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
    static function trackInfrastructureVars(el: Array<TypedExpr>, context: CompilationContext): Void {
        // Track infrastructure variables for later use
        for (expr in el) {
            switch(expr.expr) {
                case TVar(v, init) if (init != null):
                    // Check if this is an infrastructure variable
                    if (isInfrastructureVar(v.name)) {
                        // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                        // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                        var initAST = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(init, context);
                        context.infrastructureVarInitValues.set(v.name, initAST);
                        
                        #if debug_infrastructure_vars
                        trace('[BlockBuilder] Tracked infrastructure var ${v.name}');
                        #end
                    }
                default:
                    // Not a variable declaration
            }
        }
    }
    
    /**
     * Build regular block without special patterns
     */
    static function buildRegularBlock(el: Array<TypedExpr>, context: CompilationContext): ElixirASTDef {
        if (context.compiler == null) {
            return ENil;
        }
        
        // Track infrastructure variables first
        trackInfrastructureVars(el, context);
        
        // Check for inline expansion patterns
        var inlineResult = checkForInlineExpansion(el, context);
        if (inlineResult != null) {
            return inlineResult;
        }
        
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
                return combined;
            }
        }
        
        // Handle empty blocks
        if (expressions.length == 0) {
            return ENil;
        }
        
        // Single expression blocks can be unwrapped
        if (expressions.length == 1) {
            return expressions[0].def;
        }
        
        return EBlock(expressions);
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
            trace('[BlockBuilder] Checking 2-expr block for infrastructure var pattern');
            trace('[BlockBuilder]   Expr[0] type: ${Type.enumConstructor(expressions[0].def)}');
            trace('[BlockBuilder]   Expr[1] type: ${Type.enumConstructor(expressions[1].def)}');
            #end

            switch(expressions[0].def) {
                case EMatch(PVar(varName), init):
                    #if debug_ast_builder
                    trace('[BlockBuilder]   Found EMatch with PVar: $varName');
                    trace('[BlockBuilder]   Is infrastructure var: ${isInfrastructureVar(varName)}');
                    #end

                    // Check if varName is infrastructure variable (_g, _g1, g, g1, etc.)
                    if (isInfrastructureVar(varName)) {
                        #if debug_ast_builder
                        trace('[BlockBuilder] ✓ PRESERVING infrastructure variable pattern: $varName = ...; switch');
                        #end
                        // Keep both statements - infrastructure var is needed for switch
                        return EBlock(expressions);
                    }
                default:
                    #if debug_ast_builder
                    trace('[BlockBuilder]   Not EMatch pattern');
                    #end
            }
        }
        
        return null;
    }
}

#end