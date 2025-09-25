package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Expr.Binop;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.loop_ir.LoopIR;
import reflaxe.elixir.ast.analyzers.RangeIterationAnalyzer;
// Temporarily disabled for debugging
// import reflaxe.elixir.ast.builders.ArrayBuildingAnalyzer;
// import reflaxe.elixir.ast.builders.ArrayBuildingAnalyzer.ArrayBuildingPattern;

/**
 * Loop transformation instructions
 *
 * WHY: Describes how to transform loops without building AST
 * WHAT: Instructions for ElixirASTBuilder to generate idiomatic patterns
 * HOW: Analyzed patterns return these, builder interprets them
 */
enum LoopTransform {
    // Transform to Enum.each with range (0..n)
    EnumEachRange(varName: String, start: TypedExpr, end: TypedExpr, body: TypedExpr);

    // Transform to Enum.each with collection
    EnumEachCollection(varName: String, collection: TypedExpr, body: TypedExpr);

    // Transform to comprehension with optional filter
    Comprehension(targetVar: String, v: TVar, iterator: TypedExpr, filter: Null<TypedExpr>, body: TypedExpr);

    // Keep as standard for comprehension
    StandardFor(v: TVar, iterator: TypedExpr, body: TypedExpr);
}

/**
 * LoopBuilder: Orchestrator for Loop Analysis and Emission
 *
 * WHY: Loops need sophisticated transformation from imperative Haxe to functional Elixir.
 * The current implementation generates complex reduce_while patterns for everything,
 * when simple Enum operations or comprehensions would be more idiomatic.
 *
 * WHAT: Orchestrates:
 * - Loop pattern analysis via specialized analyzers
 * - LoopIR construction from multiple analyzer inputs
 * - Strategy selection based on IR characteristics
 * - Delegation to appropriate emitters
 * - Fallback to legacy implementation when needed
 *
 * HOW: Uses analyzer-IR-emitter pipeline:
 * 1. Analyzers detect patterns and populate IR
 * 2. IR captures semantic essence of loop
 * 3. Strategy selector chooses best emission approach
 * 4. Emitter generates idiomatic Elixir
 * 5. Falls back to legacy for low confidence
 *
 * ARCHITECTURE BENEFITS:
 * - Separation of concerns (analysis vs emission)
 * - Incremental migration from legacy code
 * - Testable at each pipeline stage
 * - Extensible with new analyzers/emitters
 * - Safe fallback prevents regressions
 *
 * EDGE CASES:
 * - Complex nested patterns may need legacy fallback
 * - Early exit patterns require reduce_while
 * - Mutable state needs careful rebinding
 * - Performance-critical loops may prefer specific forms
 */
class LoopBuilder {

    // Confidence threshold for using new emission vs legacy
    static inline var CONFIDENCE_THRESHOLD = 0.7;

    /**
     * Analyze a for loop and return transformation instructions
     *
     * WHY: Entry point for TFor analysis without building AST
     * WHAT: Analyzes loop pattern and returns transformation instructions
     * HOW: Checks patterns and returns appropriate LoopTransform enum
     *
     * ARCHITECTURE: This method does NOT call buildExpr to avoid recursion.
     * It only analyzes the TypedExpr structure and returns instructions.
     */
    public static function analyzeFor(v: TVar, e1: TypedExpr, e2: TypedExpr): LoopTransform {
        // Temporarily disable array building analysis to debug compilation hang
        // TODO: Re-enable after fixing compilation issues
        /*
        // First check for array building patterns
        var arrayPattern = ArrayBuildingAnalyzer.analyzeForLoop(v, e1, e2);
        var transform = ArrayBuildingAnalyzer.generateTransform(arrayPattern, v, e1);

        // If we found a comprehension pattern, use it
        switch(transform) {
            case Comprehension(_, _, _, _, _):
                return transform;
            case _:
                // Continue with other pattern detection
        }
        */

        // Check for range pattern: 0...n or start...end
        switch(e1.expr) {
            case TBinop(OpInterval, startExpr, endExpr):
                // Range iteration - check if body only has side effects
                if (hasSideEffectsOnly(e2)) {
                    return EnumEachRange(v.name, startExpr, endExpr, e2);
                } else {
                    // Body produces values - use standard for
                    return StandardFor(v, e1, e2);
                }

            case TLocal(_) | TField(_, _):
                // Array or collection iteration
                if (hasSideEffectsOnly(e2)) {
                    return EnumEachCollection(v.name, e1, e2);
                } else {
                    return StandardFor(v, e1, e2);
                }

            default:
                // Unknown pattern - use standard for loop
                return StandardFor(v, e1, e2);
        }
    }

    /**
     * Extract integer value from constant expression
     * 
     * WHY: Need to know loop bounds for metadata
     * WHAT: Extracts integer from TConst(TInt(_)) expressions
     * HOW: Pattern matches on TypedExpr structure
     */
    static function extractIntValue(expr: TypedExpr): Int {
        return switch(expr.expr) {
            case TConst(TInt(i)): i;
            default: 0;  // Default for unknown patterns
        };
    }
    
    /**
     * Build AST from transformation instructions
     *
     * WHY: Convert analysis results to actual AST
     * WHAT: Builds idiomatic Elixir AST based on transformation type
     * HOW: Pattern matches on LoopTransform and builds appropriate AST
     *
     * ARCHITECTURE: This is called by ElixirASTBuilder with its buildExpr
     * function, maintaining control over recursive compilation.
     */
    public static function buildFromTransform(
        transform: LoopTransform,
        buildExpr: TypedExpr -> ElixirAST,
        toSnakeCase: String -> String
    ): ElixirAST {
        switch(transform) {
            case EnumEachRange(varName, startExpr, endExpr, body):
                // Build Enum.each with range
                var range = makeAST(ERange(
                    buildExpr(startExpr),
                    buildExpr(endExpr),
                    false  // exclusive range
                ));

                var snakeVar = toSnakeCase(varName);
                #if debug_loop_builder
                trace('[LoopBuilder] EnumEachRange - Original varName: $varName, snakeVar: $snakeVar');
                #end
                var bodyAst = buildExpr(body);
                
                // Create loop context metadata for variable restoration
                // WHY: Loop variables get replaced with literals during compilation
                // RELATES TO: LoopVariableRestorer will use this to restore variables
                var loopContext: LoopContext = {
                    variableName: varName,
                    rangeMin: extractIntValue(startExpr),
                    rangeMax: extractIntValue(endExpr) - 1,  // Exclusive range
                    depth: 0,
                    iteratorExpr: "${extractIntValue(startExpr)}..${extractIntValue(endExpr) - 1}"
                };
                
                var metadata: ElixirMetadata = {
                    loopContextStack: [loopContext],
                    isWithinLoop: true,
                    loopVariableName: varName
                };
                
                // Attach metadata to body AST for propagation
                if (bodyAst.metadata == null) bodyAst.metadata = {};
                if (bodyAst.metadata.loopContextStack == null) {
                    bodyAst.metadata.loopContextStack = [loopContext];
                } else {
                    bodyAst.metadata.loopContextStack.push(loopContext);
                }
                bodyAst.metadata.isWithinLoop = true;

                #if debug_loop_builder
                trace('[LoopBuilder] Creating EFn with PVar($snakeVar) for Enum.each');
                #end
                var result = makeAST(ERemoteCall(
                    makeAST(EVar("Enum")),
                    "each",
                    [
                        range,
                        makeAST(EFn([{
                            args: [PVar(snakeVar)],
                            body: bodyAst
                        }]))
                    ]
                ));
                
                // Attach metadata to the result
                result.metadata = metadata;
                return result;

            case EnumEachCollection(varName, collection, body):
                // Build Enum.each with collection
                var collectionAst = buildExpr(collection);
                var snakeVar = toSnakeCase(varName);
                var bodyAst = buildExpr(body);
                
                // For collections, we can't know the exact values but we can still track the variable
                // This helps with nested loops where inner loop uses collection
                var loopContext: LoopContext = {
                    variableName: varName,
                    rangeMin: 0,
                    rangeMax: 999,  // Unknown upper bound for collections
                    depth: 0,
                    iteratorExpr: "collection"
                };
                
                var metadata: ElixirMetadata = {
                    loopContextStack: [loopContext],
                    isWithinLoop: true,
                    loopVariableName: varName
                };
                
                // Attach metadata to body AST
                if (bodyAst.metadata == null) bodyAst.metadata = {};
                if (bodyAst.metadata.loopContextStack == null) {
                    bodyAst.metadata.loopContextStack = [loopContext];
                } else {
                    bodyAst.metadata.loopContextStack.push(loopContext);
                }
                bodyAst.metadata.isWithinLoop = true;

                var result = makeAST(ERemoteCall(
                    makeAST(EVar("Enum")),
                    "each",
                    [
                        collectionAst,
                        makeAST(EFn([{
                            args: [PVar(snakeVar)],
                            body: bodyAst
                        }]))
                    ]
                ));
                
                result.metadata = metadata;
                return result;

            case Comprehension(targetVar, v, iterator, filter, body):
                // For now, just use standard for pattern to avoid compilation issues
                // TODO: Implement proper comprehension generation
                var varName = toSnakeCase(v.name);
                var pattern = PVar(varName);
                var iteratorExpr = buildExpr(iterator);
                var bodyExpr = buildExpr(body);
                return makeAST(EFor([{pattern: pattern, expr: iteratorExpr}], [], bodyExpr, null, false));

            case StandardFor(v, iterator, body):
                // Standard for comprehension
                var varName = toSnakeCase(v.name);
                var pattern = PVar(varName);
                var iteratorExpr = buildExpr(iterator);
                var bodyExpr = buildExpr(body);
                return makeAST(EFor([{pattern: pattern, expr: iteratorExpr}], [], bodyExpr, null, false));
        }
    }

    /**
     * Check if an expression only has side effects (no value production)
     *
     * WHY: Determine if we can use Enum.each instead of comprehension
     * WHAT: Checks if expression is purely for side effects
     * HOW: Pattern matches on common side-effect-only expressions
     */
    static function hasSideEffectsOnly(expr: TypedExpr): Bool {
        switch(expr.expr) {
            case TCall(e, _):
                // Check various call patterns for side-effect functions
                switch(e.expr) {
                    case TIdent(s):
                        // Global functions like trace() that are side-effect only
                        return s == "trace" || s == "throw" || s == "assert";
                    
                    case TField(_, FStatic(_, cf)):
                        // Static method calls like Log.trace, Sys.println
                        var name = cf.get().name;
                        return name == "trace" || name == "log" || name == "println" || 
                               name == "print" || name == "debug" || name == "info" ||
                               name == "warn" || name == "error";
                    
                    case TField(_, FInstance(_, _, cf)):
                        // Instance method calls that might be side effects
                        var name = cf.get().name;
                        return name == "push" || name == "add" || name == "remove" ||
                               name == "set" || name == "clear";
                    
                    default:
                        // Check if the call itself looks like a trace call
                        // This handles cases where trace might be accessed differently
                        return false;
                }

            case TBlock(exprs):
                // Check if all expressions in block are side-effect only
                // Empty blocks are side-effect only
                if (exprs.length == 0) return true;
                for (e in exprs) {
                    if (!hasSideEffectsOnly(e)) return false;
                }
                return true;

            case TBinop(OpAssign | OpAssignOp(_), _, _):
                // Assignments are side effects
                return true;

            case TUnop(OpIncrement | OpDecrement, _, _):
                // Increment/decrement are side effects
                return true;

            case TIf(_, then_, else_):
                // If both branches are side-effect only
                return hasSideEffectsOnly(then_) &&
                       (else_ == null || hasSideEffectsOnly(else_));
            
            case TConst(_):
                // Constants alone don't have side effects, but also don't produce meaningful values in a loop
                return true;
            
            case TLocal(_):
                // Just referencing a variable is effectively a side effect only in a loop context
                return true;

            default:
                // Conservative - assume it produces a value
                return false;
        }
    }

    /**
     * Build a while loop expression
     *
     * WHY: Entry point for TWhile transformation
     * WHAT: Analyzes loop and generates appropriate Elixir
     * HOW: First checks for desugared for-loop patterns, then runs analyzers
     */
    public static function buildWhile(econd: TypedExpr, e: TypedExpr,
                                     normalWhile: Bool,
                                     buildExpr: TypedExpr -> ElixirAST,
                                     toSnakeCase: String -> String = null): ElixirAST {
        
        // Default snake case converter if not provided
        if (toSnakeCase == null) {
            toSnakeCase = function(s) return s.toLowerCase();
        }
        
        // CRITICAL: First detect if this is a desugared for loop
        var forPattern = detectDesugarForLoopPattern(econd, e);
        if (forPattern != null) {
            #if debug_loop_detection
            trace("[LoopBuilder] Detected desugared for loop pattern");
            #end
            return buildFromForPattern(forPattern, buildExpr, toSnakeCase);
        }

        // Create the full TWhile expression for analysis
        var whileExpr: TypedExpr = {
            expr: TWhile(econd, e, normalWhile),
            pos: econd.pos,
            t: e.t
        };

        // Build and analyze IR
        var ir = analyzeLoop(whileExpr, buildExpr);

        // Check confidence and decide emission strategy
        if (ir.confidence >= CONFIDENCE_THRESHOLD) {
            return emitFromIR(ir, buildExpr, null, toSnakeCase);
        } else {
            // Fall back to legacy - would delegate to original TWhile handling
            // For now, use simple reduce_while
            return buildLegacyWhile(buildExpr(econd), buildExpr(e), normalWhile, buildExpr);
        }
    }
    
    /**
     * Detect if TWhile is actually a desugared for loop
     * 
     * WHY: Haxe desugars for(i in 0...5) into TWhile with _g variables
     * WHAT: Detects the pattern and extracts loop bounds
     * HOW: Looks for _g < _g1 pattern in condition, _g++ in body
     */
    public static function detectDesugarForLoopPattern(cond: TypedExpr, body: TypedExpr): Null<{
        userVar: String,
        startExpr: TypedExpr,
        endExpr: TypedExpr,
        userCode: TypedExpr,
        hasSideEffectsOnly: Bool
    }> {
        #if debug_loop_detection
        trace('[LoopBuilder] detectDesugarForLoopPattern called with cond: ${cond.expr}');
        #end
        
        // Check for _g < _g1 pattern in condition (may be wrapped in parenthesis)
        var actualCond = switch(cond.expr) {
            case TParenthesis(inner): inner;
            default: cond;
        };
        
        var bounds = switch(actualCond.expr) {
            case TBinop(OpLt | OpLte, e1, e2):
                var counter = extractInfrastructureVarName(e1);
                var limit = extractInfrastructureVarName(e2);
                #if debug_loop_detection
                trace('[LoopBuilder] Extracted counter: $counter, limit: $limit from e1: ${e1.expr}, e2: ${e2.expr}');
                #end
                if (counter != null && limit != null) {
                    {counter: counter, limit: limit};
                } else null;
            default: null;
        };
        
        if (bounds == null) return null;
        
        // Analyze body for user variable and increment
        var bodyInfo = analyzeForLoopBody(body, bounds.counter);
        if (bodyInfo == null) return null;
        
        // Create simple start/end expressions (will be refined later with actual init values)
        var startExpr: TypedExpr = {
            expr: TConst(TInt(0)),
            pos: cond.pos,
            t: cond.t
        };
        
        // For limit, we need to extract from context or use a placeholder
        var endExpr = switch(cond.expr) {
            case TBinop(_, _, limit): limit;
            default: startExpr;
        };
        
        return {
            userVar: bodyInfo.userVar,
            startExpr: startExpr,
            endExpr: endExpr,
            userCode: bodyInfo.userCode,
            hasSideEffectsOnly: bodyInfo.hasSideEffectsOnly
        };
    }
    
    /**
     * Extract infrastructure variable name from expression
     */
    static function extractInfrastructureVarName(expr: TypedExpr): Null<String> {
        return switch(expr.expr) {
            case TLocal(v):
                var name = v.name;
                // Match infrastructure variables: g, g1, g2, _g, _g1, _g2, etc.
                if (name == "g" || name == "_g" || 
                    ~/^_?g[0-9]*$/.match(name)) {  // Matches g, g1, g2, _g, _g1, _g2, etc.
                    name;
                } else null;
            default: null;
        };
    }
    
    /**
     * Analyze for loop body structure
     */
    static function analyzeForLoopBody(body: TypedExpr, counterVar: String): Null<{
        userVar: String,
        userCode: TypedExpr,
        hasSideEffectsOnly: Bool
    }> {
        switch(body.expr) {
            case TBlock(exprs) if (exprs.length >= 2):
                // Look for pattern: [optional var assignment, user code, increment]
                var userVar = "i"; // Default
                var userCodeStart = 0;
                
                // Check if first expr is var assignment from counter
                switch(exprs[0].expr) {
                    case TVar(v, init) if (init != null):
                        if (extractInfrastructureVarName(init) == counterVar) {
                            userVar = v.name;
                            userCodeStart = 1;
                        }
                    default:
                }
                
                // Check last expr is increment
                var lastExpr = exprs[exprs.length - 1];
                var isIncrement = switch(lastExpr.expr) {
                    case TUnop(OpIncrement, _, e): extractInfrastructureVarName(e) == counterVar;
                    case TBinop(OpAssign, e1, _): extractInfrastructureVarName(e1) == counterVar;
                    default: false;
                };
                
                if (!isIncrement) return null;
                
                // Extract user code
                var userCodeExprs = exprs.slice(userCodeStart, exprs.length - 1);
                var userCode = if (userCodeExprs.length == 1) {
                    userCodeExprs[0];
                } else {
                    {expr: TBlock(userCodeExprs), pos: body.pos, t: body.t};
                };
                
                return {
                    userVar: userVar,
                    userCode: userCode,
                    hasSideEffectsOnly: hasSideEffectsOnly(userCode)
                };
            default: 
                return null;
        }
    }
    
    /**
     * Build AST from detected for loop pattern
     */
    public static function buildFromForPattern(pattern: {
        userVar: String,
        startExpr: TypedExpr,
        endExpr: TypedExpr,
        userCode: TypedExpr,
        hasSideEffectsOnly: Bool
    }, buildExpr: TypedExpr -> ElixirAST, toSnakeCase: String -> String): ElixirAST {
        
        // Build range
        var range = makeAST(ERange(
            buildExpr(pattern.startExpr),
            buildExpr(pattern.endExpr),
            false // inclusive
        ));
        
        var varName = toSnakeCase(pattern.userVar);
        var body = buildExpr(pattern.userCode);
        
        // Generate Enum.each for side-effect-only loops
        if (pattern.hasSideEffectsOnly) {
            return makeAST(ERemoteCall(
                makeAST(EVar("Enum")),
                "each",
                [
                    range,
                    makeAST(EFn([{
                        args: [PVar(varName)],
                        body: body
                    }]))
                ]
            ));
        } else {
            // Generate comprehension for value-producing loops
            return makeAST(EFor(
                [{pattern: PVar(varName), expr: range}],
                [],
                body,
                null,
                false
            ));
        }
    }

    /**
     * Build loop from complete context (alternative entry point)
     * 
     * WHY: TBlock detection provides complete context upfront
     * WHAT: Accepts start/end expressions and while body directly
     * HOW: Analyzes body to extract user variable and delegates to buildFromForPattern
     * 
     * This method complements existing detection by accepting pre-extracted context
     * from TBlock-level detection where all components are visible together.
     */
    public static function buildWithFullContext(
        startExpr: TypedExpr, 
        endExpr: TypedExpr, 
        whileBody: TypedExpr,
        counterVar: String,  // Infrastructure counter variable (e.g., "g")
        buildExpr: TypedExpr -> ElixirAST, 
        toSnakeCase: String -> String
    ): ElixirAST {
        // Analyze the while body to extract user variable and code
        var analysis = analyzeForLoopBody(whileBody, counterVar);
        
        #if debug_loop_builder
        trace('[LoopBuilder] buildWithFullContext - counterVar: $counterVar');
        if (analysis != null) {
            trace('[LoopBuilder] Analysis found userVar: ${analysis.userVar}');
        } else {
            trace('[LoopBuilder] Analysis returned null - using fallback with default variable');
        }
        #end
        
        if (analysis == null) {
            // Fallback: if analysis fails, generate a basic range iteration with a default variable name
            // Use "i" as a sensible default for numeric loops instead of underscore
            var defaultVar = "i";  // Common convention for loop indices
            
            var range = makeAST(ERange(
                buildExpr(startExpr),
                buildExpr(endExpr),
                false
            ));
            
            #if debug_loop_builder
            trace('[LoopBuilder] WARNING: Analysis failed, using default variable name: $defaultVar');
            trace('[LoopBuilder] Original whileBody type: ${whileBody.expr}');
            #end
            
            // Filter out infrastructure variable assignments (like i = g = g + 1)
            // These are artifacts from Haxe's desugaring and shouldn't appear in output
            var cleanedBody = cleanLoopBodyFromInfrastructure(whileBody, counterVar, defaultVar);
            
            #if debug_loop_builder
            trace('[LoopBuilder] Cleaned body: ${cleanedBody}');
            #end
            
            return makeAST(ERemoteCall(
                makeAST(EVar("Enum")),
                "each",
                [
                    range,
                    makeAST(EFn([{
                        args: [PVar(defaultVar)],  // Fixed: Use sensible default instead of underscore
                        body: buildExpr(cleanedBody)
                    }]))
                ]
            ));
        }
        
        // Delegate to buildFromForPattern with the complete context
        return buildFromForPattern({
            userVar: analysis.userVar,
            startExpr: startExpr,
            endExpr: endExpr,
            userCode: analysis.userCode,
            hasSideEffectsOnly: analysis.hasSideEffectsOnly
        }, buildExpr, toSnakeCase);
    }

    /**
     * Analyze loop with all available analyzers
     *
     * WHY: Different analyzers detect different patterns
     * WHAT: Runs analyzers and aggregates results into IR
     * HOW: Each analyzer contributes to IR and confidence
     */
    static function analyzeLoop(expr: TypedExpr, buildExpr: TypedExpr -> ElixirAST): LoopIR {
        // Initialize IR
        var ir: LoopIR = {
            kind: switch(expr.expr) {
                case TFor(_, _, _): ForEach;
                case TWhile(_, _, _): While;
                case _: ForEach;
            },
            source: Collection(makeAST(ENil)),  // Default
            elementPattern: null,
            accumulators: [],
            filters: [],
            yield: null,
            earlyExit: null,
            bodyEffects: {
                hasSideEffects: false,
                producesValue: false,
                modifiesAccumulator: false,
                hasNestedLoops: false,
                hasComplexControl: false
            },
            confidence: 0.0,
            originalExpr: expr
        };

        // Run analyzers
        var analyzers = [
            new RangeIterationAnalyzer(buildExpr)
            // Future: ArrayBuildAnalyzer, EarlyExitAnalyzer, etc.
        ];

        var totalConfidence = 0.0;
        var analyzerCount = 0;

        for (analyzer in analyzers) {
            analyzer.analyze(expr, ir);
            var confidence = analyzer.calculateConfidence();
            if (confidence > 0) {
                totalConfidence += confidence;
                analyzerCount++;
            }
        }

        // Average confidence from all analyzers
        if (analyzerCount > 0) {
            ir.confidence = totalConfidence / analyzerCount;
        }

        return ir;
    }

    /**
     * Emit Elixir code from LoopIR
     *
     * WHY: IR captures semantics, now generate idiomatic code
     * WHAT: Selects emission strategy and delegates to emitter
     * HOW: Examines IR characteristics to choose best approach
     */
    static function emitFromIR(ir: LoopIR,
                              buildExpr: TypedExpr -> ElixirAST,
                              extractPattern: Null<TypedExpr -> EPattern>,
                              toSnakeCase: String -> String): ElixirAST {

        // Select emission strategy based on IR
        var strategy = selectStrategy(ir);

        return switch(strategy) {
            case EnumEach:
                emitEnumEach(ir, buildExpr, toSnakeCase);
            case EnumMap:
                emitEnumMap(ir, buildExpr, toSnakeCase);
            case Comprehension:
                emitComprehension(ir, buildExpr, toSnakeCase);
            case EnumReduce:
                emitEnumReduce(ir, buildExpr, toSnakeCase);
            case _:
                // Fall back to simple implementation
                emitSimpleLoop(ir, buildExpr, toSnakeCase);
        };
    }

    /**
     * Select best emission strategy for IR
     */
    static function selectStrategy(ir: LoopIR): EmissionStrategy {
        // Simple heuristics for now
        if (ir.bodyEffects.hasSideEffects && !ir.bodyEffects.producesValue) {
            return EnumEach;
        }

        if (ir.filters.length > 0 && ir.yield != null) {
            return Comprehension;
        }

        if (ir.yield != null && !ir.bodyEffects.modifiesAccumulator) {
            return EnumMap;
        }

        if (ir.accumulators.length > 0) {
            return EnumReduce;
        }

        return EnumEach;  // Default
    }

    /**
     * Emit Enum.each for side-effect-only loops
     */
    static function emitEnumEach(ir: LoopIR,
                                buildExpr: TypedExpr -> ElixirAST,
                                toSnakeCase: String -> String): ElixirAST {
        // Build source from original expression
        var source = switch(ir.originalExpr.expr) {
            case TFor(_, e1, _):
                // Check if it's a range iteration (0...n or start...end)
                switch(e1.expr) {
                    case TBinop(OpInterval, startExpr, endExpr):
                        // Build range expression
                        makeAST(ERange(buildExpr(startExpr), buildExpr(endExpr), false));
                    case _:
                        // Regular collection
                        buildExpr(e1);
                }
            case _:
                makeAST(ENil);
        };

        var varName = if (ir.elementPattern != null) {
            toSnakeCase(ir.elementPattern.varName);
        } else {
            "_item";
        };

        // Extract the body from the original loop expression
        var body = switch(ir.originalExpr.expr) {
            case TFor(_, _, bodyExpr): buildExpr(bodyExpr);
            case TWhile(_, bodyExpr, _): buildExpr(bodyExpr);
            case _: makeAST(ENil);
        };

        return makeAST(ERemoteCall(
            makeAST(EVar("Enum")),
            "each",
            [
                source,
                makeAST(EFn([{
                    args: [PVar(varName)],
                    body: body
                }]))
            ]
        ));
    }

    /**
     * Emit Enum.map for transformation loops
     */
    static function emitEnumMap(ir: LoopIR,
                               buildExpr: TypedExpr -> ElixirAST,
                               toSnakeCase: String -> String): ElixirAST {
        // Build source from original expression
        var source = switch(ir.originalExpr.expr) {
            case TFor(_, e1, _):
                // Check if it's a range iteration
                switch(e1.expr) {
                    case TBinop(OpInterval, startExpr, endExpr):
                        // Build range expression
                        makeAST(ERange(buildExpr(startExpr), buildExpr(endExpr), false));
                    case _:
                        // Regular collection
                        buildExpr(e1);
                }
            case _:
                makeAST(ENil);
        };

        var varName = if (ir.elementPattern != null) {
            toSnakeCase(ir.elementPattern.varName);
        } else {
            "_item";
        };

        // Extract the body from the loop expression
        var body = switch(ir.originalExpr.expr) {
            case TFor(_, _, bodyExpr): buildExpr(bodyExpr);
            case TWhile(_, bodyExpr, _): buildExpr(bodyExpr);
            case _:
                // Use yield if available, otherwise nil
                if (ir.yield != null) {
                    ir.yield.expr;
                } else {
                    makeAST(ENil);
                }
        };

        return makeAST(ERemoteCall(
            makeAST(EVar("Enum")),
            "map",
            [
                source,
                makeAST(EFn([{
                    args: [PVar(varName)],
                    body: body
                }]))
            ]
        ));
    }

    /**
     * Emit comprehension for filter/yield patterns
     */
    static function emitComprehension(ir: LoopIR,
                                    buildExpr: TypedExpr -> ElixirAST,
                                    toSnakeCase: String -> String): ElixirAST {
        // Build source from original expression
        var source = switch(ir.originalExpr.expr) {
            case TFor(_, e1, _):
                // Check if it's a range iteration
                switch(e1.expr) {
                    case TBinop(OpInterval, startExpr, endExpr):
                        // Build range expression
                        makeAST(ERange(buildExpr(startExpr), buildExpr(endExpr), false));
                    case _:
                        // Regular collection
                        buildExpr(e1);
                }
            case _:
                makeAST(ENil);
        };

        var varName = if (ir.elementPattern != null) {
            toSnakeCase(ir.elementPattern.varName);
        } else {
            "_item";
        };

        var generators = [{
            pattern: PVar(varName),
            expr: source
        }];

        var filters = [];
        for (filter in ir.filters) {
            filters.push(filter.condition);
        }

        // Extract the body from the loop expression
        var body = switch(ir.originalExpr.expr) {
            case TFor(_, _, bodyExpr): buildExpr(bodyExpr);
            case TWhile(_, bodyExpr, _): buildExpr(bodyExpr);
            case _:
                // Use yield if available, otherwise nil
                if (ir.yield != null) {
                    ir.yield.expr;
                } else {
                    makeAST(ENil);
                }
        };

        return makeAST(EFor(generators, filters, body, null, false));
    }

    /**
     * Emit Enum.reduce for accumulator loops
     */
    static function emitEnumReduce(ir: LoopIR,
                                  buildExpr: TypedExpr -> ElixirAST,
                                  toSnakeCase: String -> String): ElixirAST {
        // Simplified - would need proper accumulator handling
        return emitSimpleLoop(ir, buildExpr, toSnakeCase);
    }

    /**
     * Simple fallback emission
     */
    static function emitSimpleLoop(ir: LoopIR,
                                  buildExpr: TypedExpr -> ElixirAST,
                                  toSnakeCase: String -> String): ElixirAST {
        // Simplified loop generation
        switch(ir.kind) {
            case ForRange | ForEach:
                return buildLegacyForFromIR(ir, buildExpr, toSnakeCase);
            case While | DoWhile:
                return buildLegacyWhileFromIR(ir, buildExpr);
            case _:
                return makeAST(ENil);
        }
    }

    /**
     * Legacy for loop builder (fallback)
     */
    static function buildLegacyFor(v: TVar, e1: TypedExpr, e2: TypedExpr,
                                  buildExpr: TypedExpr -> ElixirAST,
                                  extractPattern: TypedExpr -> EPattern,
                                  toSnakeCase: String -> String): ElixirAST {
        var varName = toSnakeCase(v.name);
        var pattern = PVar(varName);
        var expr = buildExpr(e1);
        var body = buildExpr(e2);

        return makeAST(EFor([{pattern: pattern, expr: expr}], [], body, null, false));
    }

    /**
     * Legacy while loop builder (fallback)
     */
    static function buildLegacyWhile(cond: ElixirAST, body: ElixirAST,
                                    normalWhile: Bool,
                                    buildExpr: TypedExpr -> ElixirAST): ElixirAST {
        // Simple reduce_while implementation
        var stream = makeAST(ERemoteCall(
            makeAST(EVar("Stream")),
            "iterate",
            [
                makeAST(EInteger(0)),
                makeAST(EFn([{
                    args: [PVar("n")],
                    body: makeAST(EBinary(Add, makeAST(EVar("n")), makeAST(EInteger(1))))
                }]))
            ]
        ));

        var initAcc = makeAST(EAtom("ok"));

        var reducerBody = makeAST(EIf(
            cond,
            makeAST(ETuple([
                makeAST(EAtom("cont")),
                makeAST(EBlock([body, makeAST(EAtom("ok"))]))
            ])),
            makeAST(ETuple([
                makeAST(EAtom("halt")),
                makeAST(EAtom("ok"))
            ]))
        ));

        var reducerFn = makeAST(EFn([{
            args: [PWildcard, PVar("acc")],
            body: reducerBody
        }]));

        return makeAST(ERemoteCall(
            makeAST(EVar("Enum")),
            "reduce_while",
            [stream, initAcc, reducerFn]
        ));
    }

    /**
     * Clean loop body from infrastructure variable assignments
     *
     * WHY: When loop analysis fails, the raw while body contains infrastructure
     *      variable assignments like "i = g = g + 1" from Haxe's desugaring
     * WHAT: Filters out assignments that involve infrastructure variables (g, g1, _g)
     * HOW: Recursively traverses the TypedExpr and removes problematic assignments
     */
    static function cleanLoopBodyFromInfrastructure(expr: TypedExpr, counterVar: String, userVar: String): TypedExpr {
        return switch(expr.expr) {
            case TBlock(exprs):
                var cleaned = [];
                for (e in exprs) {
                    var shouldInclude = switch(e.expr) {
                        // Skip assignments involving infrastructure variables
                        case TBinop(OpAssign, {expr: TLocal(v1)}, {expr: TBinop(OpAssign, {expr: TLocal(v2)}, _)}):
                            // This is a double assignment like "i = g = g + 1"
                            false;
                        case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TLocal(v2)}) 
                            if (v.name == userVar && (v2.name == counterVar || v2.name.indexOf("g") == 0 || v2.name.indexOf("_g") == 0)):
                            // Skip assignments like "i = g" or "i = g1"
                            false;
                        case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, {expr: TLocal(v2)}, _)}) 
                            if (v.name == counterVar && v2.name == counterVar):
                            // Skip counter increments like "g = g + 1"
                            false;
                        default:
                            true;
                    };
                    
                    if (shouldInclude) {
                        // Recursively clean nested expressions
                        var cleanedExpr = cleanLoopBodyFromInfrastructure(e, counterVar, userVar);
                        cleaned.push(cleanedExpr);
                    }
                }
                
                // If we cleaned everything out, return a no-op
                if (cleaned.length == 0) {
                    // Return nil as a no-op
                    {expr: TConst(TNull), pos: expr.pos, t: expr.t};
                } else if (cleaned.length == 1) {
                    cleaned[0];
                } else {
                    {expr: TBlock(cleaned), pos: expr.pos, t: expr.t};
                }
                
            case TIf(cond, thenExpr, elseExpr):
                var cleanedThen = cleanLoopBodyFromInfrastructure(thenExpr, counterVar, userVar);
                var cleanedElse = elseExpr != null ? cleanLoopBodyFromInfrastructure(elseExpr, counterVar, userVar) : null;
                {expr: TIf(cond, cleanedThen, cleanedElse), pos: expr.pos, t: expr.t};
                
            default:
                expr; // Return unchanged for other expression types
        };
    }
    
    /**
     * Build legacy for from IR
     */
    static function buildLegacyForFromIR(ir: LoopIR,
                                        buildExpr: TypedExpr -> ElixirAST,
                                        toSnakeCase: String -> String): ElixirAST {
        // Extract variable name
        var varName = if (ir.elementPattern != null) {
            toSnakeCase(ir.elementPattern.varName);
        } else {
            "_item";
        };

        // Extract source
        var source = switch(ir.source) {
            case Range(start, end, _):
                makeAST(ERange(start, end, false));
            case Collection(expr):
                expr;
            case _:
                makeAST(ENil);
        };

        // Build body from original expression
        var body = switch(ir.originalExpr.expr) {
            case TFor(_, _, bodyExpr):
                buildExpr(bodyExpr);
            case _:
                makeAST(ENil);
        };

        return makeAST(EFor([{pattern: PVar(varName), expr: source}], [], body, null, false));
    }

    /**
     * Build legacy while from IR
     */
    static function buildLegacyWhileFromIR(ir: LoopIR,
                                          buildExpr: TypedExpr -> ElixirAST): ElixirAST {
        // Extract condition and body
        var cond = makeAST(ENil);
        var body = makeAST(ENil);

        switch(ir.originalExpr.expr) {
            case TWhile(condExpr, bodyExpr, _):
                cond = buildExpr(condExpr);
                body = buildExpr(bodyExpr);
            case _:
        }

        return buildLegacyWhile(cond, body, true, buildExpr);
    }
}

/**
 * Import emission strategies from LoopIR
 */
typedef EmissionStrategy = reflaxe.elixir.ast.loop_ir.LoopIR.EmissionStrategy;

#end