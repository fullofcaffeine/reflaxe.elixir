package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
using reflaxe.helpers.TypedExprHelper;

/**
 * Common AST patterns that require special transformation.
 * Using an enum provides a clear vocabulary for pattern detection.
 */
enum ASTPatternType {
	// Loop patterns
	SimpleRangeLoop(start:Int, end:Int, variable:String);
	ArrayIteration(array:String, itemVar:String);
	WhileLoop(condition:ElixirAST);
	
	// Map iteration patterns
	MapKeyValueIteration(mapVar:String, keyVar:String, valueVar:String);
	MapKeysIteration(mapVar:String, keyVar:String);
	MapValuesIteration(mapVar:String, valueVar:String);
	
	// List patterns
	ListHead(list:String);
	ListTail(list:String);
	
	// Comprehension patterns
	ArrayComprehension(source:String, filter:ElixirAST, transform:ElixirAST);
	MapComprehension(source:String, keyTransform:ElixirAST, valueTransform:ElixirAST);
	
	// Enum patterns
	EnumMatch(enumVar:String, constructors:Array<String>);
	OptionPattern(someCase:ElixirAST, noneCase:ElixirAST);
	ResultPattern(okCase:ElixirAST, errorCase:ElixirAST);
	
	// String patterns
	StringConcatenation(parts:Array<ElixirAST>);
	StringInterpolation(template:String, values:Array<ElixirAST>);
	
	// Infrastructure patterns (patterns to eliminate)
	YCombinatorLoop(iterVar:String, accumulator:String);
	InfrastructureVariable(name:String, purpose:String);
	
	// Inline expansion patterns
	InlineExpansion(tmpVar:String, init:ElixirAST, nullBranch:ElixirAST, nonNullBranch:ElixirAST);
	NullCoalescing(tmpVar:String, leftExpr:ElixirAST, rightExpr:ElixirAST);
}

/**
 * Data about detected patterns for transformation.
 */
typedef PatternData = {
	var type:ASTPatternType;
	var node:ElixirAST;
	var metadata:Dynamic;
}

/**
 * ElixirASTPatterns: Pattern Detection and Transformation Helpers
 * 
 * WHY: Complex pattern matching in the main builder makes code unreadable and unmaintainable
 * - ElixirASTBuilder.hx was over 3000 lines with deeply nested pattern matching
 * - Complex patterns like `TVar(tmpVar, init), TIf({expr: TBinop(OpEq, {expr: TLocal(v)}, {expr: TConst(TNull)})})` are incomprehensible
 * - Pattern detection logic was mixed with AST building, violating Single Responsibility
 * - Same patterns needed detection in multiple places, causing code duplication
 * - Testing individual patterns was impossible without running the entire compiler
 * 
 * WHAT: Centralized pattern detection and transformation for common Haxe→Elixir patterns
 * - **Inline Expansion**: When Haxe inlines functions like `extern inline get_height()`, it creates TBlock with TVar+TIf
 * - **Null Coalescing**: Haxe's `??` operator creates TBlock patterns when left side isn't simple
 * - **Array Operations**: Haxe desugars `array.map()` and `array.filter()` into while loops with specific patterns
 * - **Future Patterns**: Y-combinator patterns, struct update patterns, etc. can be added here
 * 
 * HOW: Self-documenting static functions with clear naming conventions
 * - `is[Pattern]()` → Boolean detection (e.g., `isInlineExpansionBlock`)
 * - `extract[Pattern]()` → Structured data extraction (returns null or typed data)
 * - `transform[Pattern]()` → AST transformation (takes pattern, returns ElixirASTDef)
 * - `detect[Pattern]()` → Pattern classification (returns enum or string describing pattern type)
 * 
 * ARCHITECTURE BENEFITS:
 * - **Single Responsibility**: This class ONLY handles pattern detection/transformation
 * - **Self-Documenting**: Function names immediately explain what patterns they handle
 * - **Testability**: Each pattern function can be unit tested in isolation
 * - **Maintainability**: When patterns change, updates are localized here
 * - **Reusability**: Same patterns can be detected from multiple compiler phases
 * - **Debuggability**: Can add XRay traces to individual pattern functions
 * 
 * USAGE EXAMPLE:
 * ```haxe
 * // Before (unreadable):
 * case [TVar(tmpVar, init), TIf({expr: TBinop(OpEq, {expr: TLocal(v)}, {expr: TConst(TNull)})}, thenExpr, elseExpr)]
 *     | [TVar(tmpVar, init), TIf({expr: TBinop(OpNotEq, {expr: TLocal(v)}, {expr: TConst(TNull)})}, elseExpr, thenExpr)]
 *     if (v.id == tmpVar.id && init != null && elseExpr != null):
 *     // 50 lines of transformation logic...
 * 
 * // After (self-documenting):
 * if (ElixirASTPatterns.isInlineExpansionBlock(el)) {
 *     return ElixirASTPatterns.transformInlineExpansion(el, buildFromTypedExpr, toElixirVarName);
 * }
 * ```
 * 
 * WHEN TO ADD NEW PATTERNS HERE:
 * - Pattern matching exceeds 3 levels of nesting
 * - Same pattern appears in 2+ places in the compiler
 * - Pattern has complex guard conditions
 * - Pattern's purpose isn't immediately obvious from the match
 * - Pattern needs debugging/tracing independently
 */
class ElixirASTPatterns {
    
    /**
     * Detects the type of pattern in an AST node.
     * Returns null if no known pattern is detected.
     */
    public static function detectPattern(node:ElixirAST):Null<PatternData> {
        // Check for Map iteration patterns
        if (isMapIterationPattern(node)) {
            var data = extractMapIterationData(node);
            if (data != null) {
                return {
                    type: MapKeyValueIteration(data.mapVar, "key", "value"),
                    node: node,
                    metadata: data
                };
            }
        }
        
        // Check for Y-combinator patterns (infrastructure to eliminate)
        if (isYCombinatorPattern(node)) {
            return {
                type: YCombinatorLoop("_", "acc"),
                node: node,
                metadata: null
            };
        }
        
        return null;
    }
    
    /**
     * Checks if node is a Y-combinator pattern (Enum.reduce_while with Stream.iterate).
     */
    static function isYCombinatorPattern(node:ElixirAST):Bool {
        if (node == null || node.def == null) return false;
        
        return switch(node.def) {
            case ERemoteCall(module, funcName, args):
                var isReduceWhile = switch(module.def) {
                    case EVar(modName): modName == "Enum" && funcName == "reduce_while";
                    default: false;
                };
                
                if (!isReduceWhile || args == null || args.length < 1) return false;
                
                // Check if first arg is Stream.iterate
                return switch(args[0].def) {
                    case ERemoteCall(streamModule, streamFunc, _):
                        switch(streamModule.def) {
                            case EVar(modName): modName == "Stream" && streamFunc == "iterate";
                            default: false;
                        }
                    default: false;
                };
                
            default: false;
        };
    }
    
    /**
     * Transforms a detected pattern to idiomatic Elixir.
     * This is the central place for pattern-based transformations.
     */
    public static function transformPattern(pattern:PatternData):ElixirAST {
        return switch(pattern.type) {
            case MapKeyValueIteration(mapVar, keyVar, valueVar):
                // Transform to: Enum.each(map, fn {key, value} -> ... end)
                // Extract loop body from metadata
                var loopBody = pattern.metadata != null ? pattern.metadata.loopBody : null;
                if (loopBody == null) {
                    // Return a TODO string node instead of EComment which doesn't exist
                    return makeAST(EString("# TODO: Transform Map iteration to Enum.each"), pattern.node.pos);
                }
                
                // Create the idiomatic Enum.each call
                return makeAST(ERemoteCall(
                    makeAST(EVar("Enum")),
                    pattern.metadata.isCollecting ? "map" : "each",
                    [
                        makeAST(EVar(mapVar)),
                        makeAST(EFn([
                            {
                                args: [PTuple([PVar(keyVar), PVar(valueVar)])],
                                guard: null,
                                body: loopBody
                            }
                        ]))
                    ]
                ), pattern.node.pos);
                
            case YCombinatorLoop(iterVar, accumulator):
                // Transform Y-combinator patterns to appropriate Enum functions
                // This requires analyzing the loop body to determine the right transformation
                return makeAST(EString("# TODO: Eliminate Y-combinator pattern"), pattern.node.pos);
                
            case InlineExpansion(tmpVar, init, nullBranch, nonNullBranch):
                // Transform inline expansion to clean conditional
                makeAST(EIf(
                    makeAST(EBinary(Equal, 
                        makeAST(EMatch(PVar(tmpVar), init)),
                        makeAST(ENil)
                    )),
                    nullBranch,
                    nonNullBranch
                ), pattern.node.pos);
                
            default:
                pattern.node; // Return unchanged for unhandled patterns
        };
    }
    
    // =========================================================================
    // Inline Expansion Patterns
    // =========================================================================
    
    /**
     * Detects inline expansion blocks created by Haxe when inlining functions
     * that contain null checks (e.g., extern inline get_height())
     * 
     * Pattern: TVar(tmpVar, init) followed by TIf testing tmpVar for null
     */
    public static function isInlineExpansionBlock(block: Array<TypedExpr>): Bool {
        if (block.length == 2) {
            // Simple pattern: TVar + TIf
            return switch([block[0].expr, block[1].expr]) {
                case [TVar(tmpVar, init), TIf(cond, _, elseExpr)] if (init != null && elseExpr != null):
                    // Check if condition is testing the temp variable for null
                    isNullCheckCondition(cond, tmpVar.id);
                case _: 
                    false;
            }
        } else if (block.length >= 3) {
            // Complex pattern: Multiple inline expansions in a binary operation
            // This happens when both sides of a comparison are inline functions
            // e.g., root.left.getValue() >= root.right.getValue()
            return isComplexInlineExpansionBlock(block);
        }
        return false;
    }
    
    /**
     * Detects complex inline expansion patterns where multiple inline functions
     * are used in a binary operation (e.g., a.getValue() >= b.getValue())
     */
    static function isComplexInlineExpansionBlock(block: Array<TypedExpr>): Bool {
        // For now, disable complex pattern detection to avoid issues
        // TODO: Implement proper complex inline expansion handling
        return false;
        
        /* Disabled due to complexity - needs more work
        if (block.length < 3) return false;
        
        // Look for pattern: TVar, TVar, TIf with binary operation
        var varCount = 0;
        var hasIfWithBinop = false;
        
        for (expr in block) {
            switch(expr.expr) {
                case TVar(_, init) if (init != null):
                    varCount++;
                case TIf(cond, _, _):
                    // Check if condition contains a binary operation
                    hasIfWithBinop = containsBinaryOp(cond);
                case _:
            }
        }
        
        // Multiple vars and an if with binary op suggests complex inline expansion
        return varCount >= 2 && hasIfWithBinop;
        */
    }
    
    static function containsBinaryOp(expr: TypedExpr): Bool {
        if (expr == null) return false;
        return switch(expr.expr) {
            case TBinop(_, _, _): true;
            case TParenthesis(e): containsBinaryOp(e);
            case _: false;
        }
    }
    
    /**
     * Transforms an inline expansion block into a single inline conditional expression
     * This prevents malformed syntax when the block appears in expression contexts
     */
    public static function transformInlineExpansion(block: Array<TypedExpr>, 
                                                   buildFromTypedExpr: TypedExpr -> ElixirAST,
                                                   toElixirVarName: String -> String): ElixirASTDef {
        // Check if this is a complex pattern
        if (block.length >= 3 && isComplexInlineExpansionBlock(block)) {
            return transformComplexInlineExpansion(block, buildFromTypedExpr, toElixirVarName);
        }
        
        // Extract pattern components for simple case
        var pattern = extractInlineExpansionPattern(block);
        if (pattern == null) {
            throw "Invalid inline expansion pattern"; // Should never happen if isInlineExpansionBlock returned true
        }
        
        #if debug_inline_expansion
        // DISABLED: trace('[XRay InlineExpansion] Transforming inline expansion with var ${pattern.tmpVar.name}');
        #end
        
        // Build the transformed AST
        var initAst = buildFromTypedExpr(pattern.init);
        var tmpVarName = toElixirVarName(pattern.tmpVar.name.charAt(0) == "_" ? 
                                         pattern.tmpVar.name.substr(1) : 
                                         pattern.tmpVar.name);
        
        // Determine which branch is for null and which for non-null
        var isEqNull = switch(pattern.cond.expr) {
            case TBinop(OpEq, _, _): true;
            case _: false;
        };
        
        var nullBranch = isEqNull ? pattern.thenExpr : pattern.elseExpr;
        var nonNullBranch = isEqNull ? pattern.elseExpr : pattern.thenExpr;
        
        // Generate: if (tmp = init) == nil, do: nullBranch, else: nonNullBranch
        var ifExpr = makeAST(EIf(
            makeAST(EBinary(Equal,
                makeAST(EMatch(PVar(tmpVarName), initAst)),
                makeAST(ENil)
            )),
            buildFromTypedExpr(nullBranch),
            buildFromTypedExpr(nonNullBranch)
        ));
        
        // Mark that this should stay inline (not wrapped in a block)
        if (ifExpr.metadata == null) ifExpr.metadata = {};
        ifExpr.metadata.keepInlineInAssignment = true;
        
        return ifExpr.def;
    }
    
    /**
     * Extracts components of an inline expansion pattern for transformation
     */
    static function extractInlineExpansionPattern(block: Array<TypedExpr>): Null<{
        tmpVar: TVar,
        init: TypedExpr,
        cond: TypedExpr,
        thenExpr: TypedExpr,
        elseExpr: TypedExpr
    }> {
        if (block.length != 2) return null;
        
        return switch([block[0].expr, block[1].expr]) {
            case [TVar(tmpVar, init), TIf(cond, thenExpr, elseExpr)] 
                if (init != null && elseExpr != null && isNullCheckCondition(cond, tmpVar.id)):
                {
                    tmpVar: tmpVar,
                    init: init,
                    cond: cond,
                    thenExpr: thenExpr,
                    elseExpr: elseExpr
                };
            case _:
                null;
        }
    }
    
    /**
     * Checks if an expression is a null check condition for a specific variable
     */
    static function isNullCheckCondition(cond: TypedExpr, varId: Int): Bool {
        return switch(cond.expr) {
            case TBinop(OpEq | OpNotEq, {expr: TLocal(v)}, {expr: TConst(TNull)}):
                v.id == varId;
            case _:
                false;
        }
    }
    
    /**
     * Transforms complex inline expansion blocks (multiple inline functions in binary op)
     * This handles cases like: root.left.getValue() >= root.right.getValue()
     * 
     * Haxe generates something like:
     * var _this = root.left;
     * var _this2 = root.right;
     * if ((_this == null ? 0 : _this.value) >= (_this2 == null ? 0 : _this2.value))
     */
    static function transformComplexInlineExpansion(block: Array<TypedExpr>,
                                                   buildFromTypedExpr: TypedExpr -> ElixirAST,
                                                   toElixirVarName: String -> String): ElixirASTDef {
        #if debug_inline_expansion
        // DISABLED: trace('[XRay InlineExpansion] Transforming complex inline expansion block with ${block.length} expressions');
        for (i in 0...block.length) {
            // DISABLED: trace('[XRay InlineExpansion]   Block[$i]: ${Type.enumConstructor(block[i].expr)}');
        }
        #end
        
        // Complex inline expansions are too difficult to handle properly for now
        // Just return a simple expression that will compile correctly
        // This loses the inline optimization but produces valid code
        
        // Find the last expression which should be the result
        var lastExpr = block[block.length - 1];
        
        // Build just the last expression (usually the if with comparison)
        // This skips the temporary variables but produces working code
        return buildFromTypedExpr(lastExpr).def;
    }
    
    // =========================================================================
    // Null Coalescing Patterns
    // =========================================================================
    
    /**
     * Detects null coalescing pattern: TVar followed by TBinop(OpNullCoal)
     * This pattern is generated when the left side of ?? operator isn't simple
     */
    public static function isNullCoalescingBlock(block: Array<TypedExpr>): Bool {
        if (block.length != 2) return false;
        
        return switch([block[0].expr, block[1].expr]) {
            case [TVar(tmpVar, init), TBinop(OpNullCoal, {expr: TLocal(v)}, _)] 
                if (v.id == tmpVar.id && init != null):
                true;
            case _:
                false;
        }
    }
    
    // =========================================================================
    // Array Operation Patterns (map/filter/etc.)
    // =========================================================================
    
    /**
     * Detects what type of array operation a while loop body represents
     * Returns "map", "filter", or null if not an array operation
     */
    public static function detectArrayOperationPattern(body: TypedExpr): Null<String> {
        switch(body.expr) {
            case TBlock(exprs) if (exprs.length >= 3):
                // Typical pattern has at least 3 expressions:
                // 1. var v = _g2[_g1] (array element access)
                // 2. _g1++ (index increment)  
                // 3. _g.push(...) (result building)
                
                var hasArrayAccess = false;
                var hasIncrement = false;
                var hasPush = false;
                var isFilter = false;
                
                for (expr in exprs) {
                    switch(expr.expr) {
                        case TVar(tvar, init):
                            // Check for array element access: var v = _g2[_g1]
                            if (init != null) {
                                switch(init.expr) {
                                    case TArray(_, _):
                                        hasArrayAccess = true;
                                    case _:
                                }
                            }
                            
                        case TUnop(OpIncrement | OpDecrement, _, _):
                            hasIncrement = true;
                            
                        case TCall({expr: TField(_, FInstance(_, _, cf))}, args) if (cf.get().name == "push"):
                            hasPush = true;
                            
                        case TIf(_, thenExpr, _):
                            // Check if the push is inside an if (filter pattern)
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
    
    // =========================================================================
    // Map Iterator Patterns
    // =========================================================================
    
    /**
     * Detects Map iteration patterns that use key_value_iterator()
     * 
     * WHY: Haxe desugars `for (key => value in map)` into complex while loops with
     *      iterator method calls that generate non-idiomatic Elixir code
     * 
     * WHAT: Detects patterns like:
     *       - map.key_value_iterator()
     *       - iterator.has_next()
     *       - iterator.next().key / iterator.next().value
     * 
     * GENERATED PATTERN:
     * ```elixir
     * Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {map}, fn _, {map} ->
     *   if map.key_value_iterator().has_next() do
     *     key = map.key_value_iterator().next().key
     *     value = map.key_value_iterator().next().value
     *     # ... user code using key and value ...
     *     {:cont, {map}}
     *   else
     *     {:halt, {map}}
     *   end
     * end)
     * ```
     * 
     * KEY PATTERNS TO DETECT:
     * 1. Enum.reduce_while with Stream.iterate(0, ...) as first arg
     * 2. Conditional checking `.key_value_iterator().has_next()`
     * 3. Assignments extracting `.next().key` and `.next().value`
     * 4. User code in the middle
     * 5. {:cont, {map}} and {:halt, {map}} returns
     * 
     * @param ast The ElixirAST node to check
     * @return true if this is a Map iteration pattern
     */
    public static function isMapIterationPattern(ast: ElixirAST): Bool {
        if (ast == null || ast.def == null) return false;
        
        // Look for Enum.reduce_while with iterator method calls
        return switch(ast.def) {
            case ERemoteCall(module, funcName, args):
                // Direct ERemoteCall pattern
                var isReduceWhile = switch(module.def) {
                    case EVar(modName): modName == "Enum" && funcName == "reduce_while";
                    default: false;
                };
                
                if (!isReduceWhile || args == null || args.length < 3) return false;
                
                // Check if the loop function contains iterator patterns
                var loopFunc = args[2];
                return containsMapIteratorCalls(loopFunc);
                
            case ECall(func, _, args) if (args != null && args.length >= 3):
                // ECall wrapper pattern
                var isReduceWhile = switch(func.def) {
                    case ERemoteCall(module, funcName, _):
                        switch(module.def) {
                            case EVar(modName): modName == "Enum" && funcName == "reduce_while";
                            default: false;
                        }
                    default: false;
                };
                
                if (!isReduceWhile) return false;
                
                // Check if the loop function contains iterator patterns
                var loopFunc = args[2];
                return containsMapIteratorCalls(loopFunc);
                
            default:
                false;
        };
    }
    
    
    /**
     * Checks if an AST node contains Map iterator method calls
     */
    static function containsMapIteratorCalls(ast: ElixirAST): Bool {
        if (ast == null || ast.def == null) return false;
        
        var hasIteratorCalls = false;
        var hasKeyValueAccess = false;
        
        function scan(node: ElixirAST): Void {
            if (node == null || node.def == null) return;
            
            switch(node.def) {
                case EField(obj, field):
                    // Check for iterator method names
                    if (field == "key_value_iterator" || field == "has_next" || field == "next") {
                        hasIteratorCalls = true;
                    }
                    // Check for key/value field access
                    if (field == "key" || field == "value") {
                        hasKeyValueAccess = true;
                    }
                    scan(obj);
                    
                case ECall(func, _, args):
                    scan(func);
                    if (args != null) {
                        for (arg in args) scan(arg);
                    }
                    
                case EFn(clauses):
                    for (clause in clauses) {
                        if (clause.body != null) scan(clause.body);
                    }
                    
                case EBlock(exprs):
                    for (expr in exprs) scan(expr);
                    
                case EIf(cond, thenBranch, elseBranch):
                    scan(cond);
                    scan(thenBranch);
                    if (elseBranch != null) scan(elseBranch);
                    
                default:
                    // Continue scanning other node types as needed
            }
        }
        
        scan(ast);
        return hasIteratorCalls && hasKeyValueAccess;
    }
    
    /**
     * Extracts information from a Map iteration pattern.
     * This is the key function that needs to properly detect and extract Map iteration patterns.
     * 
     * @return null if not a Map iteration pattern, otherwise returns extracted data
     */
    public static function extractMapIterationData(ast: ElixirAST): Null<{
        mapVar: String,
        keyVar: String,
        valueVar: String,
        loopBody: ElixirAST,
        isCollecting: Bool
    }> {
        if (!isMapIterationPattern(ast)) return null;
        
        // Extract args from either ERemoteCall or ECall
        var args: Array<ElixirAST> = switch(ast.def) {
            case ERemoteCall(_, _, a): a;
            case ECall(_, _, a): a;
            default: null;
        };
        
        if (args == null || args.length < 3) return null;
        
        var initial = args[1];
        var loopFunc = args[2];
        
        // Extract map variable from initial value
        var mapVar: String = null;
        if (initial != null) switch(initial.def) {
            case ETuple(elements) if (elements.length >= 1):
                switch(elements[0].def) {
                    case EVar(name): mapVar = name;
                    default:
                }
            case EVar(name): mapVar = name;
            default:
        }
        
        if (mapVar == null) return null;
        
        // Extract loop body and check if collecting results
        var loopBody: ElixirAST = null;
        var isCollecting = false;
        
        switch(loopFunc.def) {
            case EFn(clauses) if (clauses.length > 0):
                // Extract the actual loop logic (removing iterator machinery)
                var firstClause = clauses[0];
                if (firstClause.body != null) {
                    loopBody = extractCleanLoopBody(firstClause.body, mapVar);
                    isCollecting = detectResultCollection(firstClause.body);
                }
            default:
        }
        
        if (loopBody == null) return null;
        
        // Extract key and value variable names from the body
        var keyVar = "key";  // Default names
        var valueVar = "value";
        
        // Try to find actual variable names from the assignments
        if (loopBody != null) {
            switch(loopBody.def) {
                case EBlock(exprs):
                    for (expr in exprs) {
                        switch(expr.def) {
                            case EMatch(PVar(varName), value):
                                if (isFieldAccess(value, "key")) keyVar = varName;
                                if (isFieldAccess(value, "value")) valueVar = varName;
                            default:
                        }
                    }
                default:
            }
        }
        
        return {
            mapVar: mapVar,
            keyVar: keyVar,
            valueVar: valueVar,
            loopBody: loopBody,
            isCollecting: isCollecting
        };
    }
    
    /**
     * Extracts the clean loop body without iterator infrastructure
     */
    static function extractCleanLoopBody(body: ElixirAST, mapVar: String): ElixirAST {
        // The body typically has an if statement checking has_next()
        // We need to extract the actual loop logic (not the iteration machinery)
        
        switch(body.def) {
            case EIf(_, thenBranch, _):
                // The then branch contains the actual loop body
                return cleanupIteratorInfrastructure(thenBranch, mapVar);
                
            case EBlock(exprs):
                // Look for the if statement in the block
                for (expr in exprs) {
                    var extracted = extractCleanLoopBody(expr, mapVar);
                    if (extracted != null) return extracted;
                }
                
            default:
        }
        
        return null;
    }
    
    /**
     * Removes iterator infrastructure code from the loop body
     */
    public static function cleanupIteratorInfrastructure(body: ElixirAST, mapVar: String): ElixirAST {
        switch(body.def) {
            case EBlock(exprs):
                var cleaned = [];
                for (expr in exprs) {
                    // Skip infrastructure assignments like:
                    // key = map.key_value_iterator().next().key
                    // value = map.key_value_iterator().next().value
                    // {:cont, {map}}
                    var skip = false;
                    
                    switch(expr.def) {
                        case EMatch(pattern, value):
                            // Check if it's a key/value extraction
                            switch(pattern) {
                                case PVar(name) if (name == "key" || name == "value"):
                                    if (isIteratorMethodChain(value)) skip = true;
                                default:
                            }
                            
                        case ETuple(elements) if (elements.length == 2):
                            // Skip continuation tuples {:cont, {map}}
                            switch(elements[0].def) {
                                case EAtom(atom) if (atom == "cont" || atom == "halt"):
                                    skip = true;
                                default:
                            }
                            
                        default:
                    }
                    
                    if (!skip) {
                        cleaned.push(expr);
                    }
                }
                
                // Return cleaned block or single expression
                if (cleaned.length == 1) {
                    return cleaned[0];
                } else if (cleaned.length > 0) {
                    return {def: EBlock(cleaned), pos: body.pos, metadata: body.metadata};
                }
                
            default:
                return body;
        }
        
        return null;
    }
    
    /**
     * Helper to check if an expression accesses a specific field.
     */
    static function isFieldAccess(expr: ElixirAST, fieldName: String): Bool {
        if (expr == null || expr.def == null) return false;
        return switch(expr.def) {
            case EField(_, field): field == fieldName;
            default: false;
        };
    }
    
    /**
     * Checks if an expression is an iterator method chain
     */
    static function isIteratorMethodChain(expr: ElixirAST): Bool {
        if (expr == null || expr.def == null) return false;
        
        switch(expr.def) {
            case EField(obj, field):
                if (field == "key" || field == "value") {
                    return isIteratorCall(obj);
                }
            default:
        }
        return false;
    }
    
    /**
     * Checks if an expression is an iterator call
     */
    static function isIteratorCall(expr: ElixirAST): Bool {
        if (expr == null || expr.def == null) return false;
        
        switch(expr.def) {
            case ECall(func, _):
                switch(func.def) {
                    case EField(_, field):
                        return field == "next" || field == "key_value_iterator" || field == "has_next";
                    default:
                }
            case EField(_, field):
                return field == "next" || field == "key_value_iterator" || field == "has_next";
            default:
        }
        return false;
    }
    
    /**
     * Detects if the loop is collecting results (for choosing Enum.map vs Enum.each)
     */
    static function detectResultCollection(body: ElixirAST): Bool {
        if (body == null || body.def == null) return false;
        
        var hasCollection = false;
        
        function scan(node: ElixirAST): Void {
            if (node == null || node.def == null) return;
            
            switch(node.def) {
                case ECall(func, _, args):
                    // Check if it's Array.push
                    switch(func.def) {
                        case ERemoteCall(module, funcName, _):
                            switch(module.def) {
                                case EVar(modName) if (modName == "Array" && funcName == "push"):
                                    hasCollection = true;
                                default:
                            }
                        default:
                    }
                    scan(func);
                    if (args != null) {
                        for (arg in args) scan(arg);
                    }
                    
                case EBlock(exprs):
                    for (expr in exprs) scan(expr);
                    
                case EIf(_, thenBranch, elseBranch):
                    scan(thenBranch);
                    if (elseBranch != null) scan(elseBranch);
                    
                default:
            }
        }
        
        scan(body);
        return hasCollection;
    }
}

#end