package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.loop_ir.LoopIR;
import reflaxe.elixir.ast.analyzers.RangeIterationAnalyzer;

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
     * Build a for loop expression
     *
     * WHY: Entry point for TFor transformation
     * WHAT: Analyzes loop and generates appropriate Elixir
     * HOW: Runs analyzers, builds IR, selects strategy, emits code
     */
    public static function buildFor(v: TVar, e1: TypedExpr, e2: TypedExpr,
                                   buildExpr: TypedExpr -> ElixirAST,
                                   extractPattern: TypedExpr -> EPattern,
                                   toSnakeCase: String -> String): ElixirAST {

        // Create the full TFor expression for analysis
        var forExpr: TypedExpr = {
            expr: TFor(v, e1, e2),
            pos: e1.pos,
            t: e2.t
        };

        // Build and analyze IR
        var ir = analyzeLoop(forExpr);

        // Check confidence and decide emission strategy
        if (ir.confidence >= CONFIDENCE_THRESHOLD) {
            return emitFromIR(ir, buildExpr, extractPattern, toSnakeCase);
        } else {
            // Fall back to legacy simple handling
            return buildLegacyFor(v, e1, e2, buildExpr, extractPattern, toSnakeCase);
        }
    }

    /**
     * Build a while loop expression
     *
     * WHY: Entry point for TWhile transformation
     * WHAT: Analyzes loop and generates appropriate Elixir
     * HOW: Runs analyzers, builds IR, selects strategy, emits code
     */
    public static function buildWhile(econd: TypedExpr, e: TypedExpr,
                                     normalWhile: Bool,
                                     buildExpr: TypedExpr -> ElixirAST): ElixirAST {

        // Create the full TWhile expression for analysis
        var whileExpr: TypedExpr = {
            expr: TWhile(econd, e, normalWhile),
            pos: econd.pos,
            t: e.t
        };

        // Build and analyze IR
        var ir = analyzeLoop(whileExpr);

        // Check confidence and decide emission strategy
        if (ir.confidence >= CONFIDENCE_THRESHOLD) {
            return emitFromIR(ir, buildExpr, null, function(s) return s);
        } else {
            // Fall back to legacy - would delegate to original TWhile handling
            // For now, use simple reduce_while
            return buildLegacyWhile(econd, e, normalWhile, buildExpr);
        }
    }

    /**
     * Analyze loop with all available analyzers
     *
     * WHY: Different analyzers detect different patterns
     * WHAT: Runs analyzers and aggregates results into IR
     * HOW: Each analyzer contributes to IR and confidence
     */
    static function analyzeLoop(expr: TypedExpr): LoopIR {
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
            new RangeIterationAnalyzer()
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
        var source = switch(ir.source) {
            case Range(start, end, _):
                // Create range expression
                makeAST(ERange(start, end, false));
            case Collection(expr):
                expr;
            case _:
                makeAST(ENil);
        };

        var varName = if (ir.elementPattern != null) {
            toSnakeCase(ir.elementPattern.varName);
        } else {
            "_item";
        };

        var body = buildExpr(ir.originalExpr);  // Build body from original

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
        var source = switch(ir.source) {
            case Range(start, end, _):
                makeAST(ERange(start, end, false));
            case Collection(expr):
                expr;
            case _:
                makeAST(ENil);
        };

        var varName = if (ir.elementPattern != null) {
            toSnakeCase(ir.elementPattern.varName);
        } else {
            "_item";
        };

        var body = if (ir.yield != null) {
            ir.yield.expr;
        } else {
            buildExpr(ir.originalExpr);
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
        var source = switch(ir.source) {
            case Range(start, end, _):
                makeAST(ERange(start, end, false));
            case Collection(expr):
                expr;
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
            source: source
        }];

        var filters = [];
        for (filter in ir.filters) {
            filters.push(filter.condition);
        }

        var body = if (ir.yield != null) {
            ir.yield.expr;
        } else {
            buildExpr(ir.originalExpr);
        };

        return makeAST(EFor(generators, filters, body));
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
            args: [PUnused, PVar("acc")],
            body: reducerBody
        }]));

        return makeAST(ERemoteCall(
            makeAST(EVar("Enum")),
            "reduce_while",
            [stream, initAcc, reducerFn]
        ));
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