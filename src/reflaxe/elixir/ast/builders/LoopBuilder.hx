package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Expr.Binop;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.LoopContext;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.ast.ElixirASTPatterns;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.context.BuildContext;
import reflaxe.elixir.ast.loop_ir.LoopIR;
import reflaxe.elixir.ast.analyzers.RangeIterationAnalyzer;
import reflaxe.elixir.helpers.MutabilityDetector;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.builders.ComprehensionBuilder; // for unwrap helpers
import reflaxe.elixir.ast.builders.VariableBuilder;
using StringTools;

/**
 * Variable scope analysis result
 * 
 * WHY: Need to track all variable dependencies for proper closure conversion
 * WHAT: Categorizes variables by their scope and usage patterns
 * HOW: Populated by analyzing the loop body's TypedExpr tree
 */
typedef VariableScopeAnalysis = {
    freeVariables: Map<String, TVar>,           // Variables from outer scope
    loopLocalVariables: Map<String, TVar>,      // Variables defined in loop
    accumulatorVariables: Map<String, {         // Variables that accumulate
        varName: String,
        isStringConcat: Bool,
        isListAppend: Bool,
        initialValue: ElixirAST
    }>,
    assignments: Array<{                        // All assignments for SSA analysis
        target: String,
        source: TypedExpr
    }>
}

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

    public static function containsNonLocalReturn(body: TypedExpr): Bool {
        var found = false;
        function walk(expr: TypedExpr): Void {
            if (found || expr == null) return;
            switch (expr.expr) {
                case TReturn(_):
                    found = true;
                case TFunction(_):
                    // Returns inside nested functions are local to that function, not the enclosing loop.
                    return;
                default:
                    TypedExprTools.iter(expr, walk);
            }
        }
        walk(body);
        return found;
    }

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
        // CRITICAL: Check for accumulation patterns BEFORE checking side effects
        // Accumulation needs special handling with Enum.reduce
        var accumulation = detectAccumulationPattern(e2);
        var hasSideEffects = hasSideEffectsOnly(e2) || (accumulation != null);
        
        #if debug_loop_builder
        if (accumulation != null) {
        }
        #end

        // Check for range pattern: 0...n or start...end
        switch(e1.expr) {
            case TBinop(OpInterval, startExpr, endExpr):
                // Range iteration
                // Note: Even if accumulation is detected, we still return EnumEachRange
                // The buildFromTransform method will handle converting it to reduce
                if (hasSideEffects) {
                    return EnumEachRange(v.name, startExpr, endExpr, e2);
                } else {
                    // Body produces values - use standard for
                    return StandardFor(v, e1, e2);
                }

            case TLocal(_) | TField(_, _):
                // Array or collection iteration
                if (hasSideEffects) {
                    return EnumEachCollection(v.name, e1, e2);
                } else {
                    return StandardFor(v, e1, e2);
                }

            case TCall(callTarget, _):
                // Calls that return a collection/iterator (e.g. map.keys()) should be treated as
                // collection iteration (Enum.each/Enum.reduce) rather than falling back to the
                // legacy iterator/hasNext lowering.
                //
                // This is critical for Elixir, where many helpers (Map.keys/1) return lists.
                // If we treat those as iterator objects with has_next/next closures, the generated
                // code becomes invalid and breaks under `--warnings-as-errors`.
                inline function isArrayType(t: Type): Bool {
                    return switch (haxe.macro.TypeTools.follow(t)) {
                        case TInst(_.get() => {name: "Array"}, _): true;
                        default: false;
                    };
                }
                inline function isMapType(t: Type): Bool {
                    return switch (haxe.macro.TypeTools.follow(t)) {
                        case TInst(_.get() => {name: n}, _) if (n == "Map" || n == "StringMap" || n == "IntMap" || StringTools.endsWith(n, "Map")): true;
                        case TAbstract(_.get() => {name: n2}, _) if (n2 == "Map" || n2 == "StringMap" || n2 == "IntMap" || StringTools.endsWith(n2, "Map")): true;
                        default: false;
                    };
                }
                inline function isKeysCallOnMap(callTargetExpr: TypedExpr): Bool {
                    return switch (callTargetExpr.expr) {
                        case TField(obj, FInstance(_, _, cf)) if (cf.get().name == "keys"):
                            isMapType(obj.t);
                        case TField(obj, FAnon(cf)) if (cf.get().name == "keys"):
                            isMapType(obj.t);
                        case TField(obj, FDynamic(name)) if (name == "keys"):
                            isMapType(obj.t);
                        default:
                            false;
                    };
                }

                var treatAsCollection = isArrayType(e1.t) || isKeysCallOnMap(callTarget);
                if (treatAsCollection) {
                    if (hasSideEffects) return EnumEachCollection(v.name, e1, e2);
                    return StandardFor(v, e1, e2);
                }

                // Unknown call-returning iterator: use standard for loop fallback.
                return StandardFor(v, e1, e2);

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
        // Local helper: attempt lenient list extraction for TBlock bodies to
        // reconstruct list literals instead of emitting invalid concatenations.
        function tryLooseListFromBlock(body: TypedExpr): Null<ElixirAST> {
            // Local unwrap for TMeta(:mergeBlock|:implicitReturn) and TParenthesis
            function unwrap(e: TypedExpr): TypedExpr {
                return switch (e.expr) {
                    case TMeta({name: ":mergeBlock" | ":implicitReturn"}, inner) | TParenthesis(inner): unwrap(inner);
                    default: e;
                }
            }
            return switch (body.expr) {
                case TBlock(stmts):
                    var out: Array<ElixirAST> = [];
                    for (s in stmts) {
                        var ss = unwrap(s);
                        switch (ss.expr) {
                            case TBinop(OpAdd, _, {expr: TArrayDecl([value])}):
                                out.push(buildExpr(value));
                            case TBinop(OpAssign, _, {expr: TBinop(OpAdd, _, {expr: TArrayDecl([value])})}):
                                out.push(buildExpr(value));
                            case TBinop(OpAdd, _, {expr: TBlock(inner)}):
                                var nested = tryLooseListFromBlock({expr: TBlock(inner), pos: ss.pos, t: ss.t});
                                if (nested != null) out.push(nested); 
                            case TBinop(OpAssign, _, {expr: TBinop(OpAdd, _, {expr: TBlock(inner)})}):
                                var nested2 = tryLooseListFromBlock({expr: TBlock(inner), pos: ss.pos, t: ss.t});
                                if (nested2 != null) out.push(nested2);
                            case TBlock(inner):
                                var nested3 = tryLooseListFromBlock({expr: TBlock(inner), pos: ss.pos, t: ss.t});
                                if (nested3 != null) out.push(nested3);
                            default:
                        }
                    }
                    out.length > 0 ? makeAST(EList(out)) : null;
                default:
                    null;
            }
        }
        switch(transform) {
            case EnumEachRange(varName, startExpr, endExpr, body):
                // Analyze variable scopes comprehensively
                var loopVar: TVar = {
                    name: varName, 
                    id: 0, 
                    t: null,
                    capture: false,
                    extra: null,
                    meta: null,
                    isStatic: false
                };
                var iterator = {
                    expr: TBinop(OpInterval, startExpr, endExpr),
                    pos: startExpr.pos,
                    t: startExpr.t
                };
                var analysis = analyzeVariableScopes(loopVar, iterator, body);
                
                #if debug_loop_builder
                if (Lambda.count(analysis.freeVariables) > 0) {
                }
                if (Lambda.count(analysis.loopLocalVariables) > 0) {
                }
                #end
                
                // Check if this should actually be Enum.reduce for accumulation
                var accumulation = detectAccumulationPattern(body);
                if (accumulation != null) {
                    // SPECIAL CASE: canonical list build via accumulator concatenation
                    // If the body is exactly building the accumulator with `acc = acc ++ [value]`
                    // (or `acc += [value]`) optionally behind a simple if condition, we can
                    // generate a comprehension instead of a reduce for idiomatic Elixir.
                    var pushInfo = ComprehensionBuilder.extractPushFromBody(body, accumulation.varName);
                    if (pushInfo != null && accumulation.isListAppend) {
                        var rangeFor = makeAST(ERange(
                            buildExpr(startExpr),
                            buildExpr(endExpr),
                            false,
                            makeAST(EInteger(1))
                        ));
                        var valueAst = buildExpr(pushInfo.value);
                        var filterAsts: Array<ElixirAST> = [];
                        if (pushInfo.condition != null) filterAsts.push(buildExpr(pushInfo.condition));
                        return makeAST(EFor(
                            [{ pattern: PVar(toSnakeCase(varName)), expr: rangeFor }],
                            filterAsts,
                            valueAst,
                            null,
                            false
                        ));
                    }
                    #if debug_loop_builder
                    #end
                    return buildAccumulationLoop(
                        varName,
                        makeAST(ERange(buildExpr(startExpr), buildExpr(endExpr), false, makeAST(EInteger(1)))),
                        body,
                        accumulation,
                        buildExpr,
                        toSnakeCase
                    );
                }
                
                // Track variables that need initialization (legacy approach for compatibility)
                var initializations = trackRequiredInitializations(body);
                
                // Build Enum.each with range (no accumulation)
                var range = makeAST(ERange(
                    buildExpr(startExpr),
                    buildExpr(endExpr),
                    false,  // inclusive
                    makeAST(EInteger(1))
                ));

                var snakeVar = toSnakeCase(varName);
                #if debug_loop_builder
                if (Lambda.count(initializations) > 0) {
                }
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
                    loopVariableName: varName,
                    loopContainsReturn: containsNonLocalReturn(body)
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
                #end
                var loopAst = makeAST(ERemoteCall(
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
                loopAst.metadata = metadata;
                
                // Wrap with initializations if needed
                return wrapWithInitializations(loopAst, initializations, toSnakeCase);

            case EnumEachCollection(varName, collection, body):
                // Check if this should actually be Enum.reduce for accumulation
                var accumulation = detectAccumulationPattern(body);
                if (accumulation != null) {
                    #if debug_loop_builder
                    #end
                    return buildAccumulationLoop(
                        varName,
                        buildExpr(collection),
                        body,
                        accumulation,
                        buildExpr,
                        toSnakeCase
                    );
                }
                
                // Track variables that need initialization
                var initializations = trackRequiredInitializations(body);
                
                // Build Enum.each with collection (no accumulation)
                var collectionAst = buildExpr(collection);
                var snakeVar = toSnakeCase(varName);
                var bodyAst = buildExpr(body);
                
                #if debug_loop_builder
                if (Lambda.count(initializations) > 0) {
                }
                #end
                
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
                    loopVariableName: varName,
                    loopContainsReturn: containsNonLocalReturn(body)
                };
                
                // Attach metadata to body AST
                if (bodyAst.metadata == null) bodyAst.metadata = {};
                if (bodyAst.metadata.loopContextStack == null) {
                    bodyAst.metadata.loopContextStack = [loopContext];
                } else {
                    bodyAst.metadata.loopContextStack.push(loopContext);
                }
                bodyAst.metadata.isWithinLoop = true;

                // SPECIAL CASE: Reflect.fields(collection) → hoist and iterate keys
                switch (collectionAst.def) {
                    case ERemoteCall({def: EVar(mn)}, func, args) if (mn == "Reflect" && func == "fields" && args != null && args.length == 1):
                        var fieldsVar = "fields";
                        var binder = "field";
                        var adjustedBody = (function(b:ElixirAST):ElixirAST {
                            return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(b, function(n:ElixirAST):ElixirAST {
                                return switch (n.def) {
                                    case EVar(v) if (v == snakeVar): makeASTWithMeta(EVar(binder), n.metadata, n.pos);
                                    default: n;
                                }
                            });
                        })(bodyAst);
                        var keysAssign = makeAST(EBinary(Match, makeAST(EVar(fieldsVar)), makeAST(ERemoteCall(makeAST(EVar("Map")), "keys", [args[0]]))));
                        var loopAst = makeAST(ERemoteCall(
                            makeAST(EVar("Enum")),
                            "each",
                            [ makeAST(EVar(fieldsVar)), makeAST(EFn([{ args: [PVar(binder)], body: adjustedBody }])) ]
                        ));
                        var block = makeAST(EBlock([keysAssign, loopAst]));
                        block.metadata = metadata;
                        return wrapWithInitializations(block, initializations, toSnakeCase);
                    default:
                }
                var loopAst = makeAST(ERemoteCall(
                    makeAST(EVar("Enum")),
                    "each",
                    [ collectionAst, makeAST(EFn([{ args: [PVar(snakeVar)], body: bodyAst }])) ]
                ));
                
                loopAst.metadata = metadata;
                
                // Wrap with initializations if needed
                return wrapWithInitializations(loopAst, initializations, toSnakeCase);

            case StandardFor(v, iterator, body):
                // Standard for comprehension
                var varName = toSnakeCase(v.name);
                var pattern = PVar(varName);
                var iteratorExpr = buildExpr(iterator);
                var bodyExpr = (function() {
                    var loose = tryLooseListFromBlock(body);
                    return loose != null ? loose : buildExpr(body);
                })();
                // SPECIAL CASE: Reflect.fields(collection)
                // Hoist keys = Map.keys(collection) and iterate keys to align with intended stdlib shapes
                switch (iteratorExpr.def) {
                    case ERemoteCall({def: EVar(mn)}, func, args) if (mn == "Reflect" && func == "fields" && args != null && args.length == 1):
                        var fieldsVar = "fields";
                        var keysAssign = makeAST(EBinary(Match, makeAST(EVar(fieldsVar)), makeAST(ERemoteCall(makeAST(EVar("Map")), "keys", [args[0]]))));
                        var iterOverKeys = makeAST(EFor([{pattern: pattern, expr: makeAST(EVar(fieldsVar))}], [], bodyExpr, null, false));
                        return makeAST(EBlock([keysAssign, iterOverKeys]));
                    default:
                }
                return makeAST(EFor([{pattern: pattern, expr: iteratorExpr}], [], bodyExpr, null, false));
        }
    }

    /**
     * Detect accumulation pattern in loop body
     * 
     * WHY: Loops that accumulate values (e.g., items = items ++ [...]) need Enum.reduce
     *      not Enum.each for semantic correctness
     * WHAT: Detects patterns like: var = var ++ value, var += value
     * HOW: Analyzes assignments in loop body for accumulation patterns
     * 
     * @param body The loop body to analyze
     * @return Info about accumulation if detected, null otherwise
     */
    static function detectAccumulationPattern(body: TypedExpr): Null<{
        varName: String,
        isStringConcat: Bool,
        isListAppend: Bool
    }> {
        function isStringType(t: Type): Bool {
            return switch (haxe.macro.TypeTools.follow(t)) {
                case TInst(_.get() => {name: "String"}, _): true;
                case TAbstract(_.get() => {name: "String"}, _): true;
                default: false;
            };
        }

        function isArrayType(t: Type): Bool {
            return switch (haxe.macro.TypeTools.follow(t)) {
                case TInst(_.get() => {name: "Array"}, _): true;
                default: false;
            };
        }

        #if debug_loop_builder
        #end
        switch(body.expr) {
            case TBlock(exprs):
                // Check each expression for accumulation
                for (e in exprs) {
                    var result = detectAccumulationPattern(e);
                    if (result != null) return result;
                }
                
            case TBinop(OpAssignOp(OpAdd), {expr: TLocal(v)}, rhs):
                // Pattern: var += value
                // Distinguish list append vs string concat vs numeric add by type.
                #if debug_loop_builder
                #end
                var isList = isArrayType(v.t) || switch (rhs.expr) { case TArrayDecl(_): true; default: false; };
                var isString = !isList && isStringType(v.t);
                return { varName: v.name, isStringConcat: isString, isListAppend: isList };
                
            case TBinop(OpAssign, {expr: TLocal(v1)}, {expr: TBinop(OpAdd, {expr: TLocal(v2)}, rhsAdd)})
                if (v1.name == v2.name):
                // Pattern: var = var + value
                var isListAppend = isArrayType(v1.t) || switch (rhsAdd.expr) { case TArrayDecl(_): true; default: false; };
                var isStringConcat = !isListAppend && isStringType(v1.t);
                return { varName: v1.name, isStringConcat: isStringConcat, isListAppend: isListAppend };
                
            case TBinop(OpAssign, {expr: TLocal(v1)}, {expr: TCall({expr: TField({expr: TLocal(v2)}, FInstance(_, _, cf))}, _)})
                if (v1.name == v2.name && cf.get().name == "concat"):
                // Pattern: var = var.concat([value]) (list append)
                return {
                    varName: v1.name,
                    isStringConcat: false,
                    isListAppend: true
                };
                
            case TCall({expr: TField({expr: TLocal(v)}, FInstance(_, _, cf))}, _)
                if (cf.get().name == "push"):
                // Pattern: var.push(value) - mutable array operation
                // This needs special handling as it mutates in place
                return {
                    varName: v.name,
                    isStringConcat: false,
                    isListAppend: true
                };
                
            case TIf(_, thenExpr, elseExpr):
                // Check both branches
                var thenResult = detectAccumulationPattern(thenExpr);
                if (thenResult != null) return thenResult;
                if (elseExpr != null) {
                    return detectAccumulationPattern(elseExpr);
                }
                
            default:
                // Continue searching in nested expressions
        }
        return null;
    }
    
    /**
     * Check if an expression only has side effects (no value production)
     *
     * WHY: Determine if we can use Enum.each instead of comprehension
     * WHAT: Checks if expression is purely for side effects
     * HOW: Pattern matches on common side-effect-only expressions
     * 
     * ENHANCED: Now also checks for accumulation patterns which are NOT side-effect-only
     */
    static function hasSideEffectsOnly(expr: TypedExpr): Bool {
        // First check if this contains accumulation patterns
        if (detectAccumulationPattern(expr) != null) {
            return false; // Accumulation is not a pure side effect
        }
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

        #if debug_loop_builder
        #end

        // Default snake case converter if not provided
        if (toSnakeCase == null) {
            toSnakeCase = function(s) return s.toLowerCase();
        }

        // CRITICAL: First detect if this is a desugared for loop
        var forPattern = detectDesugarForLoopPattern(econd, e);
        if (forPattern != null) {
            #if debug_loop_detection
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
        #if debug_loop_builder
        #end
        var ir = analyzeLoop(whileExpr, buildExpr);

        #if debug_loop_builder
        #end

        // Check confidence and decide emission strategy
        if (ir.confidence >= CONFIDENCE_THRESHOLD) {
            #if debug_loop_builder
            #end
            return emitFromIR(ir, buildExpr, null, toSnakeCase);
        } else {
            #if debug_loop_builder
            #end
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
        #end
        
        // Check for `_g < _g1` pattern in condition (may be wrapped in parenthesis/meta)
        function unwrap(e: TypedExpr): TypedExpr {
            return switch (e.expr) {
                case TParenthesis(inner) | TMeta(_, inner): unwrap(inner);
                default: e;
            }
        }

        var actualCond = unwrap(cond);

        var bounds: Null<{counter: String, limit: String, op: haxe.macro.Expr.Binop, counterExpr: TypedExpr, limitExpr: TypedExpr}> = switch (actualCond.expr) {
            case TBinop(op, e1, e2) if (op == OpLt || op == OpLte):
                var counter = extractInfrastructureVarName(unwrap(e1));
                var limit = extractInfrastructureVarName(unwrap(e2));
                #if debug_loop_detection
                #end
                if (counter != null && limit != null) {
                    {counter: counter, limit: limit, op: op, counterExpr: e1, limitExpr: e2};
                } else null;
            default:
                null;
        };
        
        if (bounds == null) return null;
        
        // Analyze body for user variable and increment
        var bodyInfo = analyzeForLoopBody(body, bounds.counter);
        if (bodyInfo == null) return null;
        
        // Default numeric-loop start: 0 (Haxe's 0...N).
        // Use the counter expression type to avoid incorrectly typing numeric literals as Bool.
        var startExpr: TypedExpr = {
            expr: TConst(TInt(0)),
            pos: cond.pos,
            t: bounds.counterExpr.t
        };

        // Convert `< limit` to an inclusive range end by subtracting 1 (Elixir has no exclusive ranges).
        var endExpr: TypedExpr = if (bounds.op == OpLt) {
            var one: TypedExpr = {expr: TConst(TInt(1)), pos: cond.pos, t: bounds.limitExpr.t};
            {expr: TBinop(OpSub, bounds.limitExpr, one), pos: cond.pos, t: bounds.limitExpr.t};
        } else {
            bounds.limitExpr;
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
        // Legacy entry point that identifies the counter variable by name.
        // Prefer ID-based analysis (Haxe 5 can emit non-stable/escaped names for temps).
        var counterTVar: Null<TVar> = null;
        function scan(e: TypedExpr): Void {
            if (e == null || counterTVar != null) return;
            switch (e.expr) {
                case TLocal(v) if (v.name == counterVar):
                    counterTVar = v;
                default:
                    TypedExprTools.iter(e, scan);
            }
        }
        scan(body);
        if (counterTVar == null) return null;
        return analyzeForLoopBodyWithCounterVar(body, counterTVar);
    }

    static function analyzeForLoopBodyWithCounterVar(body: TypedExpr, counterVar: TVar): Null<{
        userVar: String,
        userCode: TypedExpr,
        hasSideEffectsOnly: Bool
    }> {
        switch (body.expr) {
            case TBlock(exprs) if (exprs.length >= 1):
                // Haxe emits several equivalent desugarings for `for` loops:
                // - `var i = g; g++; ...`
                // - `var i = g++; ...` (postfix increment in header)
                //
                // We extract the user-visible loop variable and remove any counter
                // increment statement from the body so LoopBuilder can reconstruct
                // `Enum.each(range, fn i -> <userCode> end)`.
                var userVar = "i";
                var removedIndices = new Map<Int, Bool>();
                var counterIncrementHandled = false;
                var headerBindingHandled = false;

                // Helper: unwrap wrappers so we can pattern-match on the underlying expr.
                function unwrap(e: TypedExpr): TypedExpr {
                    return switch (e.expr) {
                        case TMeta(_, inner) | TParenthesis(inner): unwrap(inner);
                        default: e;
                    }
                }

                function isCounterLocalReference(e: TypedExpr): Bool {
                    return switch (unwrap(e).expr) {
                        case TLocal(localVar): localVar.id == counterVar.id;
                        default: false;
                    }
                }

                // Detect header assignment (`var i = g` or `var i = g++`)
                var first = unwrap(exprs[0]);
                switch (first.expr) {
                    case TVar(v, init) if (init != null):
                        var initUnwrapped = unwrap(init);
                        switch (initUnwrapped.expr) {
                            case TLocal(localVar) if (localVar.id == counterVar.id):
                                userVar = v.name;
                                removedIndices.set(0, true);
                                headerBindingHandled = true;
                            case TUnop(OpIncrement | OpDecrement, postFix, inner) if (postFix):
                                // Header post-inc: `var i = g++`
                                switch (unwrap(inner).expr) {
                                    case TLocal(localVar) if (localVar.id == counterVar.id):
                                        userVar = v.name;
                                        removedIndices.set(0, true);
                                        counterIncrementHandled = true;
                                        headerBindingHandled = true;
                                    default:
                                }
                            default:
                        }
                    default:
                }

                // Remove standalone counter increment if it exists (unless the header already incremented)
                if (!counterIncrementHandled) {
                    for (idx in 0...exprs.length) {
                        if (removedIndices.exists(idx)) continue;
                        var stmt = unwrap(exprs[idx]);
                        var isIncrement = switch (stmt.expr) {
                            case TUnop(OpIncrement | OpDecrement, _, target):
                                isCounterLocalReference(target);
                            case TBinop(OpAssign | OpAssignOp(_), left, _):
                                isCounterLocalReference(left);
                            default:
                                false;
                        };
                        if (isIncrement) {
                            removedIndices.set(idx, true);
                            counterIncrementHandled = true;
                            break;
                        }
                    }
                }

                if (!counterIncrementHandled) return null;
                // Desugared numeric `for (i in start...end)` always binds the user var directly
                // from the infrastructure counter (or counter++ in the header). If we didn't
                // see that binding, this is likely an indexed collection loop and should be
                // handled by the dedicated array/collection pattern detection instead.
                if (!headerBindingHandled) return null;

                // Extract user code (everything except the header binding and counter increment)
                var userCodeExprs: Array<TypedExpr> = [];
                for (idx in 0...exprs.length) {
                    if (!removedIndices.exists(idx)) userCodeExprs.push(exprs[idx]);
                }

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
            false, // inclusive
            makeAST(EInteger(1))
        ));
        
        var varName = toSnakeCase(pattern.userVar);
        // If the loop mutates an outer accumulator (e.g., `result += "x"`), lower to Enum.reduce
        // so the mutation survives beyond the anonymous function scope.
        var accumulation = detectAccumulationPattern(pattern.userCode);
        if (accumulation != null) {
            var accName = toSnakeCase(accumulation.varName);
            var accNameInReducer = (accName == "_") ? "_acc" : accName + "_acc";
            var reducerBody = transformBodyForReduce(pattern.userCode, accumulation, buildExpr, toSnakeCase, accNameInReducer);
            var reduceCall = makeAST(ERemoteCall(
                makeAST(EVar("Enum")),
                "reduce",
                [
                    range,
                    makeAST(EVar(accName)),
                    makeAST(EFn([{
                        args: [PVar(varName), PVar(accNameInReducer)],
                        guard: null,
                        body: reducerBody
                    }]))
                ]
            ));
            // Rebind the accumulator in the surrounding scope so the mutation survives
            // beyond the anonymous reduce function.
            return makeAST(EMatch(PVar(accName), reduceCall));
        }

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
        // First check for accumulation patterns in the body
        var accumulation = detectAccumulationPattern(whileBody);
        
        #if debug_loop_builder
        if (accumulation != null) {
        }
        #end
        
        // Analyze the while body to extract user variable and code
        var analysis = analyzeForLoopBody(whileBody, counterVar);
        
        #if debug_loop_builder
        if (analysis != null) {
        } else {
        }
        #end
        
        if (analysis == null) {
            // Fallback: if analysis fails, generate a basic range iteration with a default variable name
            // Use "i" as a sensible default for numeric loops instead of underscore
            var defaultVar = "i";  // Common convention for loop indices
            
            var range = makeAST(ERange(
                buildExpr(startExpr),
                buildExpr(endExpr),
                false,
                makeAST(EInteger(1))
            ));
            
            #if debug_loop_builder
            #end
            
            // Filter out infrastructure variable assignments (like i = g = g + 1)
            // These are artifacts from Haxe's desugaring and shouldn't appear in output
            var cleanedBody = cleanLoopBodyFromInfrastructure(whileBody, counterVar, defaultVar);
            
            #if debug_loop_builder
            #end
            
            // Check if accumulation was detected - use reduce if so
            if (accumulation != null) {
                return buildAccumulationLoop(
                    defaultVar,
                    range,
                    cleanedBody,
                    accumulation,
                    buildExpr,
                    toSnakeCase
                );
            }
            
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
        
        // Check for accumulation in the analyzed user code
        if (accumulation != null) {
            var range = makeAST(ERange(
                buildExpr(startExpr),
                buildExpr(endExpr),
                false,
                makeAST(EInteger(1))
            ));
            return buildAccumulationLoop(
                analysis.userVar,
                range,
                analysis.userCode,
                accumulation,
                buildExpr,
                toSnakeCase
            );
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
            // Additional analyzers can be added here as they become production-ready.
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
                        makeAST(ERange(buildExpr(startExpr), buildExpr(endExpr), false, makeAST(EInteger(1))));
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
                        makeAST(ERange(buildExpr(startExpr), buildExpr(endExpr), false, makeAST(EInteger(1))));
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
                        makeAST(ERange(buildExpr(startExpr), buildExpr(endExpr), false, makeAST(EInteger(1))));
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

        #if debug_loop_builder
        if (body != null) {
        } else {
        }
        #end

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

        #if debug_loop_builder
        #end

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

        #if debug_loop_builder
        #end

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
                makeAST(ERange(start, end, false, makeAST(EInteger(1))));
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
    
    /**
     * Analyze variable dependencies and scopes in a loop
     * 
     * WHY: Need comprehensive understanding of variable usage for proper closure conversion
     * WHAT: Categorizes all variables by scope and usage pattern
     * HOW: Deep traversal of TypedExpr tree collecting references and definitions
     * 
     * @param loopVar The loop iterator variable
     * @param iterator The loop iterator expression (may reference outer variables)
     * @param body The loop body
     * @return Complete variable scope analysis
     */
    static function analyzeVariableScopes(
        loopVar: TVar,
        iterator: TypedExpr,
        body: TypedExpr
    ): VariableScopeAnalysis {
        var analysis: VariableScopeAnalysis = {
            freeVariables: new Map<String, TVar>(),
            loopLocalVariables: new Map<String, TVar>(),
            accumulatorVariables: new Map<String, {
                varName: String,
                isStringConcat: Bool,
                isListAppend: Bool,
                initialValue: ElixirAST
            }>(),
            assignments: []
        };
        
        // Collect all variable references and definitions
        var references = new Map<String, TVar>();
        var definitions = new Map<String, TVar>();
        
        // Helper to traverse and collect variables
        function collectVars(expr: TypedExpr, inDefinition: Bool): Void {
            if (expr == null) return;
            
            switch(expr.expr) {
                case TLocal(v):
                    // Skip the loop variable itself
                    if (v.name != loopVar.name) {
                        if (!inDefinition) {
                            references.set(v.name, v);
                        }
                    }
                    
                case TVar(v, init):
                    // This is a definition
                    definitions.set(v.name, v);
                    if (init != null) {
                        collectVars(init, false);
                    }
                    
                case TBinop(OpAssign | OpAssignOp(_), e1, e2):
                    // Track assignments
                    switch(e1.expr) {
                        case TLocal(v):
                            analysis.assignments.push({
                                target: v.name,
                                source: e2
                            });
                        default:
                    }
                    collectVars(e1, true);
                    collectVars(e2, false);
                    
                case TBlock(exprs):
                    for (e in exprs) {
                        collectVars(e, false);
                    }
                    
                case TField(e, _):
                    // Check if this references an outer variable (like fields.length)
                    collectVars(e, false);
                    
                default:
                    TypedExprTools.iter(expr, function(e) collectVars(e, false));
            }
        }
        
        // First collect from iterator (may reference outer variables like fields.length)
        if (iterator != null) {
            collectVars(iterator, false);
        }
        
        // Then collect from body
        collectVars(body, false);
        
        // Classify variables
        for (name => v in references) {
            if (!definitions.exists(name) && name != loopVar.name) {
                // This is a free variable from outer scope
                analysis.freeVariables.set(name, v);
            } else if (definitions.exists(name)) {
                // This is defined within the loop
                analysis.loopLocalVariables.set(name, v);
            }
        }
        
        // Detect accumulator patterns
        var accumPattern = detectAccumulationPattern(body);
        if (accumPattern != null) {
            analysis.accumulatorVariables.set(accumPattern.varName, {
                varName: accumPattern.varName,
                isStringConcat: accumPattern.isStringConcat,
                isListAppend: accumPattern.isListAppend,
                initialValue: if (accumPattern.isStringConcat) {
                    makeAST(EString(""));
                } else if (accumPattern.isListAppend) {
                    makeAST(EList([]));
                } else {
                    makeAST(ENil);
                }
            });
        }
        
        return analysis;
    }
    
    /**
     * Track variables that need initialization before a loop
     * 
     * WHY: Loop bodies may reference variables that aren't initialized in generated code
     * WHAT: Identifies variables referenced in loop body that need pre-initialization
     * HOW: Traverses the TypedExpr to find variable references and their initializers
     * 
     * @param body The loop body to analyze
     * @return Map of variable names to their initialization expressions
     */
    static function trackRequiredInitializations(body: TypedExpr): Map<String, ElixirAST> {
        var initializations = new Map<String, ElixirAST>();
        
        // Track variables that are referenced but not locally defined
        function findReferences(expr: TypedExpr): Void {
            if (expr == null) return;
            
            switch(expr.expr) {
                case TLocal(v):
                    // Check if this variable needs initialization
                    var name = v.name;
                    // Common patterns that need initialization
                    if (name == "items" || name == "result") {
                        if (!initializations.exists(name)) {
                            // Determine initialization based on usage context
                            if (name == "items") {
                                initializations.set(name, makeAST(EList([])));  // Initialize as empty list
                            } else if (name == "result") {
                                initializations.set(name, makeAST(EString(""))); // Initialize as empty string
                            }
                        }
                    }
                    
                case TVar(v, init):
                    // This is a variable declaration - track it
                    if (init != null) {
                        // Variable is initialized, don't need to pre-initialize
                        initializations.remove(v.name);
                    }
                    
                case TBlock(exprs):
                    for (e in exprs) {
                        findReferences(e);
                    }
                    
                default:
                    TypedExprTools.iter(expr, findReferences);
            }
        }
        
        findReferences(body);
        return initializations;
    }
    
    /**
     * Build environment capture for free variables
     * 
     * WHY: Free variables from outer scope need to be accessible in the loop closure
     * WHAT: Creates a mechanism to capture and access free variables
     * HOW: Uses variable references that are already in scope
     * 
     * @param analysis The variable scope analysis
     * @param buildExpr Function to build expressions
     * @param toSnakeCase Function to convert names to snake_case
     * @return Environment capture information or null if no capture needed
     */
    static function buildEnvironmentCapture(
        analysis: VariableScopeAnalysis,
        buildExpr: TypedExpr -> ElixirAST,
        toSnakeCase: String -> String
    ): Null<{
        variables: Map<String, String>,  // Original name -> snake_case name
        needsCapture: Bool
    }> {
        if (Lambda.count(analysis.freeVariables) == 0) {
            return null;
        }
        
        var variables = new Map<String, String>();
        for (name => tvar in analysis.freeVariables) {
            variables.set(name, toSnakeCase(name));
        }
        
        return {
            variables: variables,
            needsCapture: true
        };
    }
    
    /**
     * Wrap loop AST with variable initializations
     * 
     * WHY: Ensure all referenced variables are initialized before the loop
     * WHAT: Wraps the loop in a block with initialization statements
     * HOW: Creates assignment statements for each required initialization
     * 
     * @param loopAst The loop AST to wrap
     * @param initializations Map of variable names to initialization values
     * @param toSnakeCase Function to convert names to snake_case
     * @return The wrapped AST with initializations
     */
    static function wrapWithInitializations(
        loopAst: ElixirAST,
        initializations: Map<String, ElixirAST>,
        toSnakeCase: String -> String
    ): ElixirAST {
        if (initializations == null || Lambda.count(initializations) == 0) {
            return loopAst;  // No initializations needed
        }
        
        var statements = [];
        
        // Add initialization statements
        for (varName => initValue in initializations) {
            var snakeName = toSnakeCase(varName);
            statements.push(makeAST(EBinary(
                Match,
                makeAST(EVar(snakeName)),
                initValue
            )));
        }
        
        // Add the loop itself
        statements.push(loopAst);
        
        // Wrap in a block
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build accumulation loop using Enum.reduce
     * 
     * WHY: Accumulation patterns need Enum.reduce for semantic correctness
     * WHAT: Generates Enum.reduce with proper accumulator initialization
     * HOW: Creates reduce function that threads accumulator through loop
     */
    static function buildAccumulationLoop(
        iteratorVar: String,
        source: ElixirAST,
        body: TypedExpr,
        accumulation: {varName: String, isStringConcat: Bool, isListAppend: Bool},
        buildExpr: TypedExpr -> ElixirAST,
        toSnakeCase: String -> String
    ): ElixirAST {
        var snakeIterator = toSnakeCase(iteratorVar);
        var snakeAccum = toSnakeCase(accumulation.varName);
        var snakeAccumInReducer = (snakeAccum == "_") ? "_acc" : snakeAccum + "_acc";

        // Determine initial value.
        //
        // WHY
        // - Accumulators can be initialized before the loop (not always empty).
        // - Using a constant here loses user intent and can break semantics.
        //
        // HOW
        // - Prefer the current accumulator variable binding when possible.
        // - Fall back to a sensible empty value only when the accumulator is the wildcard.
        var initialValue = if (snakeAccum != "_" && snakeAccum != null && snakeAccum.length > 0) {
            makeAST(EVar(snakeAccum));
        } else if (accumulation.isStringConcat) {
            makeAST(EString(""));  // Empty string for concatenation
        } else if (accumulation.isListAppend) {
            makeAST(EList([]));    // Empty list for appending
        } else {
            makeAST(ENil);          // Nil fallback
        };
        
        // Track any other variables that need initialization
        var initializations = trackRequiredInitializations(body);
        // Remove the accumulator variable itself from initializations (handled separately)
        initializations.remove(accumulation.varName);
        
        // Transform the body to use accumulator pattern
        // We need to replace assignments with accumulator returns
        var transformedBody = transformBodyForReduce(body, accumulation, buildExpr, toSnakeCase, snakeAccumInReducer);
        
        #if debug_loop_builder
        if (Lambda.count(initializations) > 0) {
        }
        #end
        
        // If the loop index is unused, emit `_` as the binder to avoid warnings.
        function mentionsIterator(ast: ElixirAST): Bool {
            if (ast == null || ast.def == null) return false;
            function mentionsInRaw(code: String): Bool {
                if (code == null || snakeIterator == null || snakeIterator.length == 0) return false;
                if (code.indexOf(snakeIterator) == -1) return false;
                try {
                    return new EReg('(^|[^A-Za-z0-9_])' + snakeIterator + '([^A-Za-z0-9_]|$)', '').match(code);
                } catch (_) {
                    return true;
                }
            }
            return switch (ast.def) {
                case EVar(v): v == snakeIterator;
                case ERaw(code): mentionsInRaw(code);
                case EString(str): mentionsInRaw(str);
                default:
                    var found = false;
                    ElixirASTTransformer.transformAST(ast, function(n: ElixirAST): ElixirAST {
                        if (!found && n != null) {
                            switch (n.def) {
                                case EVar(v2) if (v2 == snakeIterator):
                                    found = true;
                                case ERaw(code2) if (mentionsInRaw(code2)):
                                    found = true;
                                case EString(str2) if (mentionsInRaw(str2)):
                                    found = true;
                                default:
                            }
                        }
                        return n;
                    });
                    found;
            }
        }

        var iteratorPattern:EPattern = mentionsIterator(transformedBody) ? PVar(snakeIterator) : PWildcard;

        var reduceCall = makeAST(ERemoteCall(
            makeAST(EVar("Enum")),
            "reduce",
            [
                source,
                initialValue,
                makeAST(EFn([{
                    args: [iteratorPattern, PVar(snakeAccumInReducer)],
                    body: transformedBody
                }]))
            ]
        ));

        // Rebind the accumulator in the surrounding scope so the mutation survives beyond the reducer closure.
        var reduceAst = if (snakeAccum != "_" && snakeAccum != null && snakeAccum.length > 0) {
            makeAST(EMatch(PVar(snakeAccum), reduceCall));
        } else {
            reduceCall;
        }

        // Wrap with any additional initializations
        return wrapWithInitializations(reduceAst, initializations, toSnakeCase);
    }
    
    /**
     * Transform loop body for use in Enum.reduce
     * 
     * WHY: Accumulation assignments need to return the new accumulator value
     *      AND all intermediate variable definitions must be preserved
     * WHAT: Includes all loop body statements and ensures accumulator is returned
     * HOW: Traverses AST, includes all statements, and transforms accumulation patterns
     * 
     * CRITICAL: Must include ALL statements from loop body, not just accumulation
     * Example: var field = fields[i]; var value = ...; result += ...
     * All three statements must be in the reduce lambda body
     */
    static function transformBodyForReduce(
        expr: TypedExpr,
        accumulation: {varName: String, isStringConcat: Bool, isListAppend: Bool},
        buildExpr: TypedExpr -> ElixirAST,
        toSnakeCase: String -> String,
        accumulatorVarName: String
    ): ElixirAST {
        function unwrap(e: TypedExpr): TypedExpr {
            return switch (e.expr) {
                case TMeta({name: ":mergeBlock" | ":implicitReturn"}, inner) | TParenthesis(inner):
                    unwrap(inner);
                default:
                    e;
            };
        }

        var unwrapped = unwrap(expr);

        // Handle single-expression bodies (not wrapped in TBlock) so accumulator mutations
        // like `result += "*"`, when lowered to Enum.reduce, return the new accumulator value
        // instead of emitting an unused outer assignment (result = result <> "*"; acc).
        switch (unwrapped.expr) {
            case TBinop(OpAssignOp(OpAdd), {expr: TLocal(v)}, _) if (v.name == accumulation.varName):
                return extractAccumulationValue(unwrapped, accumulation, buildExpr, toSnakeCase, accumulatorVarName);
            case TBinop(OpAssign, {expr: TLocal(v1)}, {expr: TBinop(OpAdd, {expr: TLocal(v2)}, _)})
                if (v1.name == accumulation.varName && v2.name == accumulation.varName):
                return extractAccumulationValue(unwrapped, accumulation, buildExpr, toSnakeCase, accumulatorVarName);
            case TCall({expr: TField({expr: TLocal(v3)}, FInstance(_, _, cf))}, _)
                if (accumulation.isListAppend && v3.name == accumulation.varName && cf.get().name == "push"):
                return extractAccumulationValue(unwrapped, accumulation, buildExpr, toSnakeCase, accumulatorVarName);
            default:
        }

        switch(unwrapped.expr) {
            case TBlock(exprs):
                var transformed = [];
                var foundAccumulation = false;
                
                for (i in 0...exprs.length) {
                    var e = exprs[i];
                    
                    // Check if this is the accumulation assignment
                    var isAccumulation = switch(e.expr) {
                        case TBinop(OpAssignOp(OpAdd), {expr: TLocal(v)}, _) if (v.name == accumulation.varName): true;
                        case TBinop(OpAssign, {expr: TLocal(v1)}, {expr: TBinop(OpAdd, {expr: TLocal(v2)}, _)}) 
                            if (v1.name == accumulation.varName && v2.name == accumulation.varName): true;
                        case TCall({expr: TField({expr: TLocal(v3)}, FInstance(_, _, cf))}, _)
                            if (accumulation.isListAppend && v3.name == accumulation.varName && cf.get().name == "push"):
                            true;
                        default: false;
                    };
                    
                    if (isAccumulation) {
                        foundAccumulation = true;
                        // Transform accumulation to return new value
                        var newValue = extractAccumulationValue(e, accumulation, buildExpr, toSnakeCase, accumulatorVarName);
                        // Always return the new accumulator value at the end
                        if (i == exprs.length - 1) {
                            // Last statement is the accumulation - return it directly
                            transformed.push(newValue);
                        } else {
                            // Not the last statement - need to capture in variable and continue
                            var accVar = accumulatorVarName;
                            transformed.push(makeAST(EBinary(
                                Match,
                                makeAST(EVar(accVar)),
                                newValue
                            )));
                        }
                    } else {
                        // Check if this is an infrastructure variable assignment to skip
                        var shouldSkip = false;
                        
                        // First check the compiled AST to see if it contains infrastructure references
                        var compiledAst = buildExpr(e);
                        var astString = ElixirASTPrinter.printAST(compiledAst);
                        
                        // Skip if the generated code contains infrastructure variable references
                        // This catches patterns like "i = g + 1" that have already been compiled
                        if (astString.indexOf(" = g ") >= 0 || 
                            astString.indexOf(" = g + ") >= 0 ||
                            astString.indexOf(" = _g ") >= 0 ||
                            astString.indexOf("g + 1") >= 0) {
                            shouldSkip = true;
                            #if debug_loop_builder
                            #end
                        }
                        
                        // Also check the TypedExpr pattern
                        switch(e.expr) {
                            case TBinop(OpAssign, {expr: TLocal(lhs)}, {expr: TBinop(OpAdd, {expr: TLocal(rhs)}, {expr: TConst(TInt(1))})}):
                                // Skip patterns like: i = g + 1
                                if (lhs.name == "i" && (rhs.name == "g" || rhs.name.startsWith("_g") || rhs.name.startsWith("g"))) {
                                    shouldSkip = true;
                                }
                            case TBinop(OpAssign, {expr: TLocal(v)}, _):
                                // Skip any assignment to infrastructure variables
                                if (v.name == "g" || v.name.startsWith("_g") || v.name.startsWith("g")) {
                                    shouldSkip = true;
                                }
                            default:
                        }
                        
                        if (!shouldSkip) {
                            // Regular expression - MUST be included!
                            // This preserves variable definitions like:
                            // var field = fields[i]
                            // var value = Reflect.field(obj, field)
                            var ast = buildExpr(e);
                            transformed.push(ast);
                        }
                    }
                }
                
                // If we didn't find an explicit accumulation in the last position,
                // we need to return the accumulator variable
                if (foundAccumulation && transformed.length > 0) {
                    var lastIsAccumulation = switch(exprs[exprs.length - 1].expr) {
                        case TBinop(OpAssignOp(OpAdd), {expr: TLocal(v)}, _) if (v.name == accumulation.varName): true;
                        case TBinop(OpAssign, {expr: TLocal(v1)}, {expr: TBinop(OpAdd, {expr: TLocal(v2)}, _)}) 
                            if (v1.name == accumulation.varName && v2.name == accumulation.varName): true;
                        default: false;
                    };
                    
                    if (!lastIsAccumulation) {
                        // Need to explicitly return the accumulator
                        transformed.push(makeAST(EVar(accumulatorVarName)));
                    }
                }
                
                return makeAST(EBlock(transformed));
                
            default:
                // Simple expression - compile and return accumulator
                return makeAST(EBlock([
                    buildExpr(unwrapped),
                    makeAST(EVar(accumulatorVarName))
                ]));
        }
    }
    
    /**
     * Extract the new accumulation value from an assignment
     */
    static function extractAccumulationValue(
        expr: TypedExpr,
        accumulation: {varName: String, isStringConcat: Bool, isListAppend: Bool},
        buildExpr: TypedExpr -> ElixirAST,
        toSnakeCase: String -> String,
        accumulatorVarName: String
    ): ElixirAST {
        var accVar = makeAST(EVar(accumulatorVarName));
        
        switch(expr.expr) {
            case TBinop(OpAssignOp(OpAdd), _, value):
                // var += value -> list concat / string concat / numeric add
                if (accumulation.isListAppend) {
                    return makeAST(EBinary(Concat, accVar, buildExpr(value)));
                }
                if (accumulation.isStringConcat) return makeAST(EBinary(StringConcat, accVar, buildExpr(value)));
                return makeAST(EBinary(Add, accVar, buildExpr(value)));
                
            case TBinop(OpAssign, _, {expr: TBinop(OpAdd, _, value)}):
                // var = var + value -> list concat / string concat / numeric add
                if (accumulation.isListAppend) {
                    return makeAST(EBinary(Concat, accVar, buildExpr(value)));
                }
                if (accumulation.isStringConcat) return makeAST(EBinary(StringConcat, accVar, buildExpr(value)));
                return makeAST(EBinary(Add, accVar, buildExpr(value)));

            case TCall({expr: TField({expr: TLocal(_)}, FInstance(_, _, cf))}, args)
                if (accumulation.isListAppend && cf.get().name == "push" && args != null && args.length == 1):
                // var.push(value) -> accumulator ++ [value]
                return makeAST(EBinary(Concat, accVar, makeAST(EList([buildExpr(args[0])]))));
                
            default:
                // Fallback: just return accumulator unchanged
                return accVar;
        }
    }
    // ========================================================================================
    // EXTRACTED FROM ElixirASTBuilder: Complete loop compilation functionality
    // ========================================================================================
    
    /**
     * Check if an iterator expression is for Map key-value iteration
     * 
     * WHY: Need to detect Map iteration to generate idiomatic Elixir
     * WHAT: Checks if the iterator type is MapKeyValueIterator or similar
     * HOW: Examines the Type of the iterator expression
     */
    static function isMapIterator(iterator: TypedExpr): Bool {
        switch(iterator.t) {
            case TAbstract(t, params):
                var abstractType = t.get();
                return abstractType.name == "KeyValueIterator" || 
                       abstractType.module == "haxe.iterators.MapKeyValueIterator";
                       
            case TInst(t, params):
                var classType = t.get();
                return classType.name == "MapKeyValueIterator" ||
                       classType.module == "haxe.iterators.MapKeyValueIterator";
                       
            default:
                return false;
        }
    }
    
    /**
     * Extract key and value variable names from Map iteration body
     * 
     * WHY: Haxe desugars `for (key => value in map)` into infrastructure variables
     * WHAT: Finds the actual key/value names by looking for `var key = g.key; var value = g.value;`
     * HOW: Scans the body TBlock for TVar expressions that extract from the iterator
     * 
     * Returns null for key or value if they're not used (e.g., key-only iteration)
     */
    static function extractMapIterationVariables(body: TypedExpr, iteratorVar: String): {key: Null<String>, value: Null<String>, keyUsed: Bool, valueUsed: Bool} {
        var keyVar: String = null;
        var valueVar: String = null;
        
        // Look for pattern: var key = iterator.key; var value = iterator.value;
        switch(body.expr) {
            case TBlock(exprs):
                for (expr in exprs) {
                    switch(expr.expr) {
                        case TVar(tvar, init) if (init != null):
                            // Check if it's accessing .key or .value from the iterator
                            switch(init.expr) {
                                case TField({expr: TLocal(local)}, FInstance(_, _, cf)) 
                                    if (local.name == iteratorVar):
                                    var fieldName = cf.get().name;
                                    if (fieldName == "key") {
                                        keyVar = tvar.name;
                                    } else if (fieldName == "value") {
                                        valueVar = tvar.name;
                                    }
                                default:
                            }
                        default:
                    }
                }
            default:
        }
        
        // Return what we found
        return {
            key: keyVar,
            value: valueVar,
            keyUsed: keyVar != null,
            valueUsed: valueVar != null
        };
    }
    
    /**
     * Remove the key/value extraction statements from the body
     * 
     * WHY: These extraction statements are infrastructure code that shouldn't appear in output
     * WHAT: Filters out `var key = g.key; var value = g.value;` statements
     * HOW: Creates a new TBlock without the extraction TVar expressions
     */
    static function removeMapIterationExtractions(body: TypedExpr, iteratorVar: String): TypedExpr {
        switch(body.expr) {
            case TBlock(exprs):
                var filteredExprs = [];
                for (expr in exprs) {
                    var shouldKeep = switch(expr.expr) {
                        case TVar(_, init) if (init != null):
                            // Skip variable declarations that extract from the iterator
                            switch(init.expr) {
                                case TField({expr: TLocal(local)}, FInstance(_, _, cf)) 
                                    if (local.name == iteratorVar && 
                                        (cf.get().name == "key" || cf.get().name == "value")):
                                    false; // Remove this extraction
                                default:
                                    true; // Keep other variables
                            }
                        default:
                            true; // Keep non-variable expressions
                    };
                    
                    if (shouldKeep) {
                        filteredExprs.push(expr);
                    }
                }
                
                // Return a new TBlock with filtered expressions
                return {
                    expr: filteredExprs.length == 1 ? filteredExprs[0].expr : TBlock(filteredExprs),
                    pos: body.pos,
                    t: body.t
                };
            default:
                return body; // Return unchanged if not a block
        }
    }
    
    /**
     * Build idiomatic Map iteration using Enum.each
     * 
     * WHY: Map iteration should use Enum.each with tuple destructuring, not iterator objects
     * WHAT: Generates Enum.each(map, fn {key, value} -> body end)
     * HOW: Extracts real variable names, removes infrastructure code, builds Enum call
     */
    static function buildIdiomaticMapIteration(v: TVar, iterator: TypedExpr, body: TypedExpr,
                                               context: BuildContext,
                                               toElixirVarName: String -> String): ElixirASTDef {
        var buildExpression = context.getExpressionBuilder();
        
        #if debug_map_iteration
        #end
        
        // Extract the map expression (what we're iterating over)
        var mapExpr = switch(iterator.expr) {
            case TCall({expr: TField(map, _)}, _): map;
            default: iterator;
        };
        
        // Build the map AST
        var mapAst = buildExpression(mapExpr);
        
        // Extract the actual key and value variable names from the body
        var vars = extractMapIterationVariables(body, v.name);
        
        #if debug_map_iteration
        #end
        
        // Remove the extraction statements from the body
        var cleanedBody = removeMapIterationExtractions(body, v.name);
        
        // Build the cleaned body
        var bodyAst = buildExpression(cleanedBody);
        
        // Detect if we're collecting results or just side effects
        var isCollecting = detectAccumulationPattern(cleanedBody) != null;
        
        // Create the pattern for tuple destructuring
        var pattern = if (vars.keyUsed && vars.valueUsed) {
            // Both key and value are used
            var keyPattern = PVar(toElixirVarName(vars.key));
            var valuePattern = PVar(toElixirVarName(vars.value));
            PTuple([keyPattern, valuePattern]);
        } else if (vars.keyUsed && !vars.valueUsed) {
            // Only key is used, use underscore for value
            var keyPattern = PVar(toElixirVarName(vars.key));
            var valuePattern = PVar("_");
            PTuple([keyPattern, valuePattern]);
        } else if (!vars.keyUsed && vars.valueUsed) {
            // Only value is used, use underscore for key
            var keyPattern = PVar("_");
            var valuePattern = PVar(toElixirVarName(vars.value));
            PTuple([keyPattern, valuePattern]);
        } else {
            // Neither is used (edge case), use underscores for both
            PTuple([PVar("_"), PVar("_")]);
        };
        
        // Choose Enum function based on collection need
        var enumFunc = isCollecting ? "map" : "each";
        
        #if debug_map_iteration
        if (vars.keyUsed && vars.valueUsed) {
        } else if (vars.keyUsed) {
        } else if (vars.valueUsed) {
        } else {
        }
        #end
        
        // Build the Enum call
        return ERemoteCall(
            makeAST(EVar("Enum")),
            enumFunc,
            [
                mapAst,
                makeAST(EFn([{
                    args: [pattern],
                    body: bodyAst
                }]))
            ]
        );
    }
    
    /**
     * Main entry point for TFor compilation
     * Extracted from ElixirASTBuilder lines 5259-5349
     */
    public static function buildFor(v: TVar, e1: TypedExpr, e2: TypedExpr, 
                                   expr: TypedExpr,
                                   context: BuildContext,
                                   toElixirVarName: String -> String): ElixirASTDef {
        var buildExpression = context.getExpressionBuilder();
        
        // ALWAYS trace to understand what's being compiled
        #if debug_map_iteration
        
        // Check what method is being called in the iterator
        switch(e1.expr) {
            case TCall({expr: TField(_, FInstance(_, _, cf))}, args):
            case TCall({expr: TField(_, FStatic(_, cf))}, args):
            case TCall(e, args):
            default:
        }
        #end
        
        // Debug: Check what the iterator expression actually is
        #if debug_map_iteration
        switch(e1.expr) {
            case TCall({expr: TField(map, field)}, args):
                switch(field) {
                    case FInstance(_, _, cf):
                    default:
                }
            default:
        }
        #end
        
        // Check for Map iteration by examining the iterator expression
        var isMapIter = switch(e1.expr) {
            case TCall({expr: TField(_, FInstance(_, _, cf))}, []) if (cf.get().name == "keyValueIterator"):
                true;
            default:
                var result = isMapIterator(e1);
                result;
        };
        
        if (isMapIter) {
            #if debug_map_iteration
            // Analyze the body to find the actual key/value variables
            switch(e2.expr) {
                case TBlock(exprs) if (exprs.length > 0):
                    // Look for the pattern: var name = g.key; var hex = g.value;
                    for (i in 0...exprs.length) {
                    }
                default:
            }
            #end
            return buildIdiomaticMapIteration(v, e1, e2, context, toElixirVarName);
        }
        
        // Create loop metadata for variable restoration
        var loopMetadata = createMetadata(expr);
        
        // Create loop context that will survive all transformation passes
        var loopContext: LoopContext = {
            variableName: v.name,
            rangeMin: extractRangeMin(e1),
            rangeMax: extractRangeMax(e1),
            depth: 0,  // Will be set from context if available
            iteratorExpr: captureIteratorExpression(e1)
        };
        
        // Build context stack for nested loop support
        if (loopMetadata.loopContextStack == null) {
            loopMetadata.loopContextStack = [];
        }
        loopMetadata.loopContextStack.push(loopContext);
        loopMetadata.loopVariableName = v.name;
        loopMetadata.originalLoopExpression = captureExpressionText(e2, v.name);
        loopMetadata.isWithinLoop = true;
        loopMetadata.loopContainsReturn = containsNonLocalReturn(e2);
        
        // Check if LoopBuilder enhanced features are enabled
        // FIX: Use correct flag name - "loop_builder_enabled" not "loop_builder_enhanced"
        if (context.isFeatureEnabled("loop_builder_enabled")) {
            var transform = analyzeFor(v, e1, e2);
            var ast = buildFromTransform(
                transform,
                e -> buildExpression(e),
                name -> toElixirVarName(name)
            );
            
            // Attach metadata
            if (ast != null) {
                return makeASTWithMeta(ast.def, loopMetadata, expr.pos).def;
            }
            return ast.def;
        } else {
            // Simple for comprehension fallback
            var varName = toElixirVarName(v.name);
            var pattern = PVar(varName);
            var iteratorExpr = buildExpression(e1);
            var bodyExpr = buildExpression(e2);
            
            var forDef = EFor([{pattern: pattern, expr: iteratorExpr}], [], bodyExpr, null, false);
            return makeASTWithMeta(forDef, loopMetadata, expr.pos).def;
        }
    }
    
    /**
     * Main entry point for TWhile compilation
     * Extracted from ElixirASTBuilder lines 5350-6040
     */
    public static function buildWhileComplete(econd: TypedExpr, e: TypedExpr, 
                                              normalWhile: Bool,
                                              expr: TypedExpr,
                                              context: BuildContext,
                                              toElixirVarName: String -> String): ElixirASTDef {
        var buildExpression = context.getExpressionBuilder();
        
        // First check if this is a desugared numeric for loop (range iteration).
        //
        // WHY
        // - Haxe desugars `for (i in a...b)` into a counter var + while loop.
        // - In Elixir, lowering this shape to Enum.each/Enum.reduce over a range is both
        //   more idiomatic and avoids control-flow scoping pitfalls of list comprehensions.
        //
        // NOTE
        // - We intentionally prefer Enum.* over `for ... do:` comprehensions here.
        //   Comprehensions introduce a new scope and will not update outer bindings.
        if (context.isFeatureEnabled("loop_builder_enabled")) {
            var desugaredRange = buildDesugaredForRangeLoop(econd, e, context, toElixirVarName);
            if (desugaredRange != null) return desugaredRange;
        }

        // Detect `for (item in array)` desugared to an indexed while loop:
        //   g = 0; while (g < array.length) { var item = array[g]; g++; <userCode> }
        // and rewrite to Enum.each/Enum.reduce(array, ...).
        var forInArrayPattern = detectForInArrayPattern(econd, e);
        if (forInArrayPattern != null) {
            var arrayExpr = buildExpression(forInArrayPattern.arrayExpr);
            var binderName = toElixirVarName(forInArrayPattern.elementVarName);

            // If the user body mutates outer locals, lower to Enum.reduce with an explicit
            // state accumulator so mutations survive across iterations.
            var mutated = MutabilityDetector.detectMutatedVariables(forInArrayPattern.userBody);
            if (Lambda.count(mutated) == 0) {
                var bodyAst = buildExpression(forInArrayPattern.userBody);
                return ERemoteCall(
                    makeAST(EVar("Enum")),
                    "each",
                    [
                        arrayExpr,
                        makeAST(EFn([{
                            args: [PVar(binderName)],
                            guard: null,
                            body: bodyAst
                        }]))
                    ]
                );
            }

            var compilationContext: Null<CompilationContext> = Std.isOfType(context, CompilationContext) ? cast context : null;

            var mutatedList: Array<{ id: Int, originalName: String, outerName: String, accName: String }> = [];
            for (id => tvar in mutated) {
                var outerName = toElixirVarName(tvar.name);
                var accName = if (outerName == "_") {
                    "_acc";
                } else if (outerName.endsWith("_acc")) {
                    outerName + "_state";
                } else {
                    outerName + "_acc";
                };
                mutatedList.push({ id: id, originalName: tvar.name, outerName: outerName, accName: accName });
            }
            mutatedList.sort((a, b) -> a.id - b.id);

            function makeTupleVars(names: Array<String>): Array<ElixirAST> {
                return [for (nm in names) makeAST(EVar(nm))];
            }

            var initialState: ElixirAST = if (mutatedList.length == 1) {
                makeAST(EVar(mutatedList[0].outerName));
            } else {
                makeAST(ETuple(makeTupleVars([for (m in mutatedList) m.outerName])));
            };

            var statePattern: EPattern = if (mutatedList.length == 1) {
                PVar(mutatedList[0].accName);
            } else {
                PTuple([for (m in mutatedList) PVar(m.accName)]);
            };

            var outerBindPattern: EPattern = if (mutatedList.length == 1) {
                PVar(mutatedList[0].outerName);
            } else {
                PTuple([for (m in mutatedList) PVar(m.outerName)]);
            };

            var stateReturn: ElixirAST = if (mutatedList.length == 1) {
                makeAST(EVar(mutatedList[0].accName));
            } else {
                makeAST(ETuple(makeTupleVars([for (m in mutatedList) m.accName])));
            };

            // Temporarily remap mutated outer vars to accumulator names while compiling the reducer body.
            var savedMappings: Array<{ key: String, had: Bool, value: Null<String> }> = [];
            if (compilationContext != null) {
                for (m in mutatedList) {
                    var idKey = Std.string(m.id);
                    for (k in [idKey, m.originalName]) {
                        var had = compilationContext.tempVarRenameMap.exists(k);
                        var old = had ? compilationContext.tempVarRenameMap.get(k) : null;
                        savedMappings.push({ key: k, had: had, value: old });
                        compilationContext.tempVarRenameMap.set(k, m.accName);
                    }
                }
            }

            var compiledBody = buildExpression(forInArrayPattern.userBody);

            if (compilationContext != null) {
                for (s in savedMappings) {
                    if (s.had) compilationContext.tempVarRenameMap.set(s.key, s.value);
                    else compilationContext.tempVarRenameMap.remove(s.key);
                }
            }

            function ensureReturnsState(bodyAst: ElixirAST, ret: ElixirAST): ElixirAST {
                if (bodyAst == null) return ret;
                return switch (bodyAst.def) {
                    case EIf(cond, then_, else_):
                        var newThen = ensureReturnsState(then_, ret);
                        var newElse = if (else_ == null) {
                            ret;
                        } else switch (else_.def) {
                            case ENil: ret;
                            default: ensureReturnsState(else_, ret);
                        };
                        makeAST(EIf(cond, newThen, newElse));
                    case EUnless(condition, body, elseBranch):
                        var newBody = ensureReturnsState(body, ret);
                        var newElse = if (elseBranch == null) {
                            ret;
                        } else switch (elseBranch.def) {
                            case ENil: ret;
                            default: ensureReturnsState(elseBranch, ret);
                        };
                        makeAST(EUnless(condition, newBody, newElse));
                    case EBlock(stmts):
                        var out = stmts == null ? [] : stmts.copy();
                        out.push(ret);
                        makeAST(EBlock(out));
                    default:
                        makeAST(EBlock([bodyAst, ret]));
                };
            }

            var reducerBody = ensureReturnsState(compiledBody, stateReturn);

            var reduceCall = makeAST(ERemoteCall(
                makeAST(EVar("Enum")),
                "reduce",
                [
                    arrayExpr,
                    initialState,
                    makeAST(EFn([{
                        args: [PVar(binderName), statePattern],
                        guard: null,
                        body: reducerBody
                    }]))
                ]
            ));

            return EMatch(outerBindPattern, reduceCall);
        }
        
        // Check for array iteration patterns
        var arrayPattern = detectArrayIterationPattern(econd, e);
        if (arrayPattern != null) {
            return generateIdiomaticEnumCall(
                arrayPattern.arrayRef,
                arrayPattern.operation,
                e,
                context,
                toElixirVarName
            );
        }
        
        // Generate idiomatic while loop implementation
        return buildWhileLoop(econd, e, normalWhile, context, toElixirVarName);
    }

    static function buildDesugaredForRangeLoop(
        econd: TypedExpr,
        body: TypedExpr,
        context: BuildContext,
        toElixirVarName: String -> String
    ): Null<ElixirASTDef> {
        // Unwrap common wrappers in the while condition.
        function unwrap(e: TypedExpr): TypedExpr {
            return switch (e.expr) {
                case TParenthesis(inner) | TMeta(_, inner): unwrap(inner);
                default: e;
            };
        }

        var actualCond = unwrap(econd);
        var bounds: Null<{ counterVar: TVar, op: haxe.macro.Expr.Binop, limitExpr: TypedExpr }> = switch (actualCond.expr) {
            case TBinop(op, e1, e2) if (op == OpLt || op == OpLte):
                switch (unwrap(e1).expr) {
                    case TLocal(counter):
                        { counterVar: counter, op: op, limitExpr: e2 };
                    default:
                        null;
                }
            default:
                null;
        };
        if (bounds == null) return null;

        // Ensure the body matches Haxe's for-loop desugaring shape (user var header + counter increment).
        var bodyInfo = analyzeForLoopBodyWithCounterVar(body, bounds.counterVar);
        if (bodyInfo == null) return null;

	        var buildExpression = context.getExpressionBuilder();
	        var compilationContext: Null<CompilationContext> = Std.isOfType(context, CompilationContext) ? cast context : null;

	        #if debug_haxe5_loop_seeds
	        if (compilationContext != null && bounds != null && bounds.counterVar != null && bounds.counterVar.name != null
	            && bounds.counterVar.name.indexOf("`") != -1) {
	            var counterId = bounds.counterVar.id;
	            var idKey = Std.string(counterId);
	            trace('[haxe5-loop-seeds] range candidate: counter name="${bounds.counterVar.name}" id=$counterId'
	                + ' localInitCount=' + (compilationContext.localVarInitValuesById != null ? Lambda.count(compilationContext.localVarInitValuesById) : -1)
	                + ' hasLocalInit=' + (compilationContext.localVarInitValuesById != null && compilationContext.localVarInitValuesById.exists(counterId))
	                + ' infraInitCount=' + (compilationContext.infrastructureVarInitValues != null ? Lambda.count(compilationContext.infrastructureVarInitValues) : -1)
	                + ' hasInfraInitByName=' + (compilationContext.infrastructureVarInitValues != null && compilationContext.infrastructureVarInitValues.exists(bounds.counterVar.name))
	                + ' tempMapHasId=' + (compilationContext.tempVarRenameMap != null && compilationContext.tempVarRenameMap.exists(idKey))
	                + ' tempMapIdVal=' + (compilationContext.tempVarRenameMap != null && compilationContext.tempVarRenameMap.exists(idKey) ? compilationContext.tempVarRenameMap.get(idKey) : '<none>'));
	        }
	        #end

	        // Prefer a tracked initializer for the counter var (supports non-zero starts, e.g. (i + 1)...len).
	        // Haxe 5 preview can emit temps with non-stable/escaped names, so always try ID-keyed init tracking first.
	        var startAst: ElixirAST = makeAST(EInteger(0));
	        var hasStartSeed = false;
        if (compilationContext != null) {
            if (compilationContext.localVarInitValuesById != null && compilationContext.localVarInitValuesById.exists(bounds.counterVar.id)) {
                var init = compilationContext.localVarInitValuesById.get(bounds.counterVar.id);
                if (init != null) {
                    startAst = init;
                    hasStartSeed = true;
                }
            } else if (compilationContext.infrastructureVarInitValues != null && compilationContext.infrastructureVarInitValues.exists(bounds.counterVar.name)) {
                var init = compilationContext.infrastructureVarInitValues.get(bounds.counterVar.name);
                if (init != null) {
                    startAst = init;
                    hasStartSeed = true;
                }
            }
        }
        if (!hasStartSeed) return null;

        // Use the condition's limit expression directly (evaluated once when building the range).
        // Prefer not to inline tracked initializers here so we keep bindings aligned and readable.
        var limitAst = buildExpression(bounds.limitExpr);
        if (limitAst == null) return null;

        var endAst: ElixirAST = if (bounds.op == OpLt) {
            makeAST(EBinary(EBinaryOp.Subtract, limitAst, makeAST(EInteger(1))));
        } else {
            limitAst;
        };

        var rangeAst = makeAST(ERange(startAst, endAst, false, makeAST(EInteger(1))));
        var binderName = toElixirVarName(bodyInfo.userVar);

        // If the loop mutates outer locals, use Enum.reduce and thread state explicitly.
        var mutated = MutabilityDetector.detectMutatedVariables(bodyInfo.userCode);
        if (Lambda.count(mutated) == 0) {
            var bodyAst = buildExpression(bodyInfo.userCode);
            return ERemoteCall(
                makeAST(EVar("Enum")),
                "each",
                [
                    rangeAst,
                    makeAST(EFn([{
                        args: [PVar(binderName)],
                        guard: null,
                        body: bodyAst
                    }]))
                ]
            );
        }

        var mutatedList: Array<{ id: Int, originalName: String, outerName: String, accName: String }> = [];
        for (id => tvar in mutated) {
            var outerName = toElixirVarName(tvar.name);
            var accName = if (outerName == "_") {
                "_acc";
            } else if (outerName.endsWith("_acc")) {
                outerName + "_state";
            } else {
                outerName + "_acc";
            };
            mutatedList.push({ id: id, originalName: tvar.name, outerName: outerName, accName: accName });
        }
        mutatedList.sort((a, b) -> a.id - b.id);

        function makeTupleVars(names: Array<String>): Array<ElixirAST> {
            return [for (nm in names) makeAST(EVar(nm))];
        }

        var initialState: ElixirAST = if (mutatedList.length == 1) {
            makeAST(EVar(mutatedList[0].outerName));
        } else {
            makeAST(ETuple(makeTupleVars([for (m in mutatedList) m.outerName])));
        };

        var statePattern: EPattern = if (mutatedList.length == 1) {
            PVar(mutatedList[0].accName);
        } else {
            PTuple([for (m in mutatedList) PVar(m.accName)]);
        };

        var outerBindPattern: EPattern = if (mutatedList.length == 1) {
            PVar(mutatedList[0].outerName);
        } else {
            PTuple([for (m in mutatedList) PVar(m.outerName)]);
        };

        var stateReturn: ElixirAST = if (mutatedList.length == 1) {
            makeAST(EVar(mutatedList[0].accName));
        } else {
            makeAST(ETuple(makeTupleVars([for (m in mutatedList) m.accName])));
        };

        // Temporarily remap mutated outer vars to accumulator names while compiling the reducer body.
        var savedMappings: Array<{ key: String, had: Bool, value: Null<String> }> = [];
        if (compilationContext != null) {
            for (m in mutatedList) {
                var idKey = Std.string(m.id);
                for (k in [idKey, m.originalName]) {
                    var had = compilationContext.tempVarRenameMap.exists(k);
                    var old = had ? compilationContext.tempVarRenameMap.get(k) : null;
                    savedMappings.push({ key: k, had: had, value: old });
                    compilationContext.tempVarRenameMap.set(k, m.accName);
                }
            }
        }

        var compiledBody = buildExpression(bodyInfo.userCode);

        if (compilationContext != null) {
            for (s in savedMappings) {
                if (s.had) compilationContext.tempVarRenameMap.set(s.key, s.value);
                else compilationContext.tempVarRenameMap.remove(s.key);
            }
        }

        function ensureReturnsState(bodyAst: ElixirAST, ret: ElixirAST): ElixirAST {
            if (bodyAst == null) return ret;
            return switch (bodyAst.def) {
                case EIf(cond, then_, else_):
                    var newThen = ensureReturnsState(then_, ret);
                    var newElse = if (else_ == null) {
                        ret;
                    } else switch (else_.def) {
                        case ENil: ret;
                        default: ensureReturnsState(else_, ret);
                    };
                    makeAST(EIf(cond, newThen, newElse));
                case EUnless(condition, b, elseBranch):
                    var newBody = ensureReturnsState(b, ret);
                    var newElse = if (elseBranch == null) {
                        ret;
                    } else switch (elseBranch.def) {
                        case ENil: ret;
                        default: ensureReturnsState(elseBranch, ret);
                    };
                    makeAST(EUnless(condition, newBody, newElse));
                case EBlock(stmts):
                    var out = stmts == null ? [] : stmts.copy();
                    out.push(ret);
                    makeAST(EBlock(out));
                default:
                    makeAST(EBlock([bodyAst, ret]));
            };
        }

        var reducerBody = ensureReturnsState(compiledBody, stateReturn);

        var reduceCall = makeAST(ERemoteCall(
            makeAST(EVar("Enum")),
            "reduce",
            [
                rangeAst,
                initialState,
                makeAST(EFn([{
                    args: [PVar(binderName), statePattern],
                    guard: null,
                    body: reducerBody
                }]))
            ]
        ));

        return EMatch(outerBindPattern, reduceCall);
    }
    
    static function detectForInArrayPattern(econd: TypedExpr, body: TypedExpr): Null<{
        arrayExpr: TypedExpr,
        elementVarName: String,
        userBody: TypedExpr
    }> {
        // Condition: <counter> < array.length
        var actualCond = switch (econd.expr) {
            case TParenthesis(inner) | TMeta(_, inner): inner;
            default: econd;
        };

        var counterVar: Null<TVar> = null;
        var arrayExpr: Null<TypedExpr> = null;
        switch (actualCond.expr) {
            case TBinop(OpLt | OpLte, {expr: TLocal(counter)}, {expr: TField(arr, fieldAccess)}):
                var isLength = switch (fieldAccess) {
                    case FInstance(_, _, cf): cf.get().name == "length";
                    case FAnon(cf): cf.get().name == "length";
                    case FDynamic(name): name == "length";
                    default: false;
                };
                if (isLength) {
                    counterVar = counter;
                    arrayExpr = arr;
                }
            default:
        }
        if (counterVar == null || arrayExpr == null) return null;

        // Body: var elem = array[counter]; counter++; <userCode>
        var exprs: Null<Array<TypedExpr>> = switch (body.expr) {
            case TBlock(stmts): stmts;
            default: null;
        };
        if (exprs == null || exprs.length < 2) return null;

        function isCounterReference(expr: TypedExpr): Bool {
            if (expr == null) return false;
            return switch (expr.expr) {
                case TLocal(localVar): localVar.id == counterVar.id;
                case TParenthesis(inner) | TMeta(_, inner): isCounterReference(inner);
                default: false;
            };
        }

        var elementVarName: Null<String> = null;
        var userStmtsStart = 0;

        // First statement: var elem = array[counter]
        var first = exprs[0];
        switch (first.expr) {
            case TVar(v, init) if (init != null):
                switch (init.expr) {
                    case TArray(arr2, idx):
                        var isCounterIndex = isCounterReference(idx);
                        if (isCounterIndex) {
                            // Ensure we're indexing the same array as in the condition (common case: both are TLocal)
                            var sameArray = switch ([arrayExpr.expr, arr2.expr]) {
                                case [TLocal(a), TLocal(b)] if (a.id == b.id): true;
                                default: false;
                            };
                            if (!sameArray) return null;
                            elementVarName = v.name;
                            userStmtsStart = 1;
                        }
                    default:
                }
            default:
        }
        if (elementVarName == null) return null;

        // Second statement: counter++
        var second = exprs[1];
        var isCounterIncrement = switch (second.expr) {
            case TUnop(OpIncrement | OpDecrement, _, target):
                isCounterReference(target);
            case TBinop(OpAssign | OpAssignOp(_), left, _):
                isCounterReference(left);
            default:
                false;
        };
        if (!isCounterIncrement) return null;

        // Remaining user statements
        var userExprs = exprs.slice(2);
        var userBody: TypedExpr = if (userExprs.length == 0) {
            {expr: TBlock([]), pos: body.pos, t: body.t};
        } else if (userExprs.length == 1) {
            userExprs[0];
        } else {
            {expr: TBlock(userExprs), pos: body.pos, t: body.t};
        };

        #if debug_enum_each_early_return
        trace('[detectForInArrayPattern] userBody=' + reflaxe.elixir.util.EnumReflection.enumConstructor(userBody.expr)
            + ' containsReturn=' + containsNonLocalReturn(userBody));
        #end

        // Avoid rewriting if the user body references the counter variable (index-based loops).
        var usesCounter = false;
        function scan(e: TypedExpr): Void {
            if (e == null || usesCounter) return;
            switch (e.expr) {
                case TLocal(v4) if (v4.id == counterVar.id):
                    usesCounter = true;
                default:
                    TypedExprTools.iter(e, scan);
            }
        }
        scan(userBody);
        if (usesCounter) return null;

        return {
            arrayExpr: arrayExpr,
            elementVarName: elementVarName,
            userBody: userBody
        };
    }
    
    /**
     * Detect array iteration patterns in while loops
     */
    static function detectArrayIterationPattern(econd: TypedExpr, body: TypedExpr): Null<{
        arrayRef: TypedExpr,
        operation: String
    }> {
        // Check for _g1 < _g2.length pattern
        var actualCond = switch(econd.expr) {
            case TParenthesis(inner): inner;
            default: econd;
        };
        
        switch(actualCond.expr) {
            case TBinop(OpLt, {expr: TLocal(indexVar)}, {expr: TField(arr, FInstance(_, _, cf))}) 
                if (StringTools.startsWith(indexVar.name, "_g") && cf.get().name == "length"):
                
                // Found array iteration pattern
                var pattern = ElixirASTPatterns.detectArrayOperationPattern(body);
                if (pattern != null) {
                    return {
                        arrayRef: arr,
                        operation: pattern
                    };
                }
                
            default:
        }
        
        return null;
    }
    
    /**
     * Build idiomatic while loop using reduce_while
     */
    static function wrapLoopControlTry(body: ElixirAST, currentAcc: ElixirAST): ElixirAST {
        if (body == null) return body;

        var breakAtom = makeAST(EAtom(ElixirAtom.raw("break")));
        var continueAtom = makeAST(EAtom(ElixirAtom.raw("continue")));
        var haltAtom = makeAST(EAtom(ElixirAtom.raw("halt")));
        var contAtom = makeAST(EAtom(ElixirAtom.raw("cont")));

        var catchClauses: Array<ECatchClause> = [
            // Preferred: carry state explicitly.
            {
                kind: Throw,
                pattern: PTuple([PLiteral(breakAtom), PVar("break_state")]),
                body: makeAST(ETuple([haltAtom, makeAST(EVar("break_state"))]))
            },
            {
                kind: Throw,
                pattern: PTuple([PLiteral(continueAtom), PVar("continue_state")]),
                body: makeAST(ETuple([contAtom, makeAST(EVar("continue_state"))]))
            },

            // Back-compat: bare atoms (state falls back to current accumulator).
            {
                kind: Throw,
                pattern: PLiteral(breakAtom),
                body: makeAST(ETuple([haltAtom, currentAcc]))
            },
            {
                kind: Throw,
                pattern: PLiteral(continueAtom),
                body: makeAST(ETuple([contAtom, currentAcc]))
            }
        ];

        return makeAST(ETry(body, [], catchClauses, null, null));
    }

    static function buildWhileLoop(econd: TypedExpr, e: TypedExpr,
                                   normalWhile: Bool,
                                   context: BuildContext,
                                   toElixirVarName: String -> String): ElixirASTDef {

        #if debug_loop_builder
        #end

        var buildExpression = context.getExpressionBuilder();

        // Detect mutated variables for state threading
        var mutatedVars = MutabilityDetector.detectMutatedVariables(e);
        // NOTE: We only thread truly mutated locals through the reduce_while accumulator.
        // Variables that are only *read* (e.g. function params used in the condition) are
        // safely captured by the reducer closure and should not be included in the state tuple.

        // Provide loop-control state info (break/continue) during body compilation so
        // ExceptionBuilder can emit `throw({:break, state})` / `throw({:continue, state})`.
        var compilationContext: Null<CompilationContext> = Std.isOfType(context, CompilationContext) ? cast context : null;
        if (compilationContext != null) {
            if (Lambda.count(mutatedVars) > 0) {
                var accVarList: Array<{ name: String, tvar: TVar }> = [];
                for (id => v in mutatedVars) accVarList.push({ name: VariableBuilder.resolveVariableName(v, compilationContext), tvar: v });
                accVarList.sort((a, b) -> Reflect.compare(a.tvar.id, b.tvar.id));
                compilationContext.loopControlStateStack.push([for (it in accVarList) it.name]);
            } else {
                // Stateless reduce_while uses `acc`.
                compilationContext.loopControlStateStack.push(null);
            }
        }

        var condition = buildExpression(econd);
        var body = buildExpression(e);

        if (compilationContext != null && compilationContext.loopControlStateStack != null && compilationContext.loopControlStateStack.length > 0) {
            compilationContext.loopControlStateStack.pop();
        }

        #if debug_loop_builder
        if (body != null) {
            var bodyStr = ElixirASTPrinter.print(body, 0);
        }
        #end
        
        // If there are variables to thread, use reduce_while with state
        if (Lambda.count(mutatedVars) > 0) {
            return buildReduceWhileWithState(
                mutatedVars,
                condition,
                body,
                context,
                toElixirVarName
            );
        } else {
            // Flatten body blocks so downstream hygiene can see assignments and the {:cont, acc}
            // tuple in a single block (avoids incorrect "unused assignment" underscoring).
            function buildThenBlock(bodyExpr: ElixirAST): ElixirAST {
                var cont = makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("cont"))), makeAST(EVar("acc"))]));
                return switch (bodyExpr.def) {
                    case EBlock(stmts):
                        var merged = stmts.copy();
                        merged.push(cont);
                        makeAST(EBlock(merged));
                    case EDo(stmts):
                        var merged = stmts.copy();
                        merged.push(cont);
                        makeAST(EBlock(merged));
                    default:
                        makeAST(EBlock([bodyExpr, cont]));
                }
            }

            // Simple reduce_while without state
            return ERemoteCall(
                makeAST(EVar("Enum")),  
                "reduce_while",
                [
                    makeAST(ERemoteCall(
                        makeAST(EVar("Stream")),
                        "iterate",
                        [
                            makeAST(EInteger(0)),
                            makeAST(EFn([{
                                args: [PVar("n")],
                                guard: null,
                                body: makeAST(EBinary(Add, makeAST(EVar("n")), makeAST(EInteger(1))))
                            }]))
                        ]
                    )),
                    makeAST(EAtom(ElixirAtom.ok())),
                    makeAST(EFn([
                        {
                            args: [PWildcard, PVar("acc")],
                            guard: null,
                            body: wrapLoopControlTry(
                                makeAST(EIf(
                                    condition,
                                    buildThenBlock(body),
                                    makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("halt"))), makeAST(EVar("acc"))]))
                                )),
                                makeAST(EVar("acc"))
                            )
                        }
                    ]))
                ]
            );
        }
    }
    
    /**
     * Build reduce_while with state threading for mutated variables
     */
    static function buildReduceWhileWithState(
        mutatedVars: Map<Int, TVar>,
        condition: ElixirAST,
        body: ElixirAST,
        context: BuildContext,
        toElixirVarName: String -> String
    ): ElixirASTDef {

        #if debug_loop_builder
        if (body != null) {
            var bodyStr = ElixirASTPrinter.print(body, 0);
            switch(body.def) {
                case EBlock(exprs):
                default:
            }
        } else {
        }
        #end

        var concreteContext: Null<CompilationContext> = Std.isOfType(context, CompilationContext) ? cast context : null;

        // Build the initial accumulator tuple
        var accVarList: Array<{name: String, tvar: TVar}> = [];
        for (id => v in mutatedVars) {
            accVarList.push({name: concreteContext != null ? VariableBuilder.resolveVariableName(v, concreteContext) : toElixirVarName(v.name), tvar: v});
        }
        accVarList.sort((a, b) -> Reflect.compare(a.tvar.id, b.tvar.id));
        
        var accInitializers = [];
        var finalAccPatterns = [];
        var reducerAccPatterns = [];
        var reducerAccRebuilders = [];
        var outerToReducerVar: Map<String, String> = new Map();

        // Try to seed accumulator variables with a concrete initial value when we can prove it,
        // so the reduce_while does not depend on prior bindings in the surrounding scope.
        // This is especially important for desugared for/while loops where Haxe introduces
        // compiler temps (_g, _g1, ...) and accumulator locals (sum/result/items) that must
        // be initialized for the reducer to be valid Elixir.
        function inferAccumulatorSeed(elixirName: String, tvar: Null<TVar>): Null<ElixirAST> {
            if (elixirName == null || elixirName.length == 0) return null;
            if (tvar == null) return null;
            var originalName = tvar.name;

            // Prefer ID-keyed tracked initializers (Haxe 5 temp names can be non-stable/escaped).
            if (concreteContext != null && concreteContext.localVarInitValuesById != null &&
                concreteContext.localVarInitValuesById.exists(tvar.id)) {
                var init = concreteContext.localVarInitValuesById.get(tvar.id);
                if (init != null) return init;
            }

            // Prefer any tracked initializer (e.g. _g = 5) captured at block level.
            if (concreteContext != null && concreteContext.infrastructureVarInitValues != null &&
                originalName != null && concreteContext.infrastructureVarInitValues.exists(originalName)) {
                return concreteContext.infrastructureVarInitValues.get(originalName);
            }

            // Default seed for compiler counters (g, g1, _g, _g1, ...): 0
            if (originalName != null && (originalName == "g" || originalName == "_g" || ~/^_?g[0-9]*$/.match(originalName))) {
                return makeAST(EInteger(0));
            }
            if (elixirName == "g" || ~/^g[0-9]*$/.match(elixirName)) {
                return makeAST(EInteger(0));
            }

            // IMPORTANT:
            // We intentionally do not infer seeds from self-accumulating assignments (x = x + 1, etc.)
            // because the initial value may come from a function argument or prior binding. Seeding to
            // 0/""/[] would silently corrupt semantics (e.g., Input.readBytes/4 where `pos` and `k`
            // begin from caller-provided values).
            return null;
        }

        for (item in accVarList) {
            var outerName = item.name;
            var reducerName = 'acc_${outerName}';
            outerToReducerVar.set(outerName, reducerName);

            var seed = inferAccumulatorSeed(item.name, item.tvar);
            accInitializers.push(seed != null ? seed : makeAST(EVar(outerName)));
            finalAccPatterns.push(PVar(outerName));
            reducerAccPatterns.push(PVar(reducerName));
            reducerAccRebuilders.push(makeAST(EVar(reducerName)));
        }
        
        var initAcc = makeAST(ETuple(accInitializers));
        var finalAccPattern = PTuple(finalAccPatterns);
        var reducerAccPattern = PTuple(reducerAccPatterns);
        var newAccTuple = makeAST(ETuple(reducerAccRebuilders));
        
        // Transform condition to use pattern-matched variables
        var transformedCondition = transformExpressionWithMapping(
            condition,
            outerToReducerVar
        );
        
        // Transform body similarly
        var transformedBody = transformExpressionWithMapping(
            body,
            outerToReducerVar
        );

        #if debug_loop_builder
        #end

        function buildThenBlock(bodyExpr: ElixirAST): ElixirAST {
            var cont = makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("cont"))), newAccTuple]));
            return switch (bodyExpr.def) {
                case EBlock(stmts):
                    var merged = stmts.copy();
                    merged.push(cont);
                    makeAST(EBlock(merged));
                case EDo(stmts):
                    var merged = stmts.copy();
                    merged.push(cont);
                    makeAST(EBlock(merged));
                default:
                    makeAST(EBlock([bodyExpr, cont]));
            }
        }

        // Build the lambda body EIf structure
        var lambdaIfBody = makeAST(EIf(
            transformedCondition,
            buildThenBlock(transformedBody),
            makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("halt"))), newAccTuple]))
        ));

        #if debug_loop_builder
        var ifBodyStr = ElixirASTPrinter.print(lambdaIfBody, 0);
        #end

        // Build the complete reducer function
        var reducerFn = makeAST(EFn([
            {
                args: [PWildcard, reducerAccPattern],
                guard: null,
                body: wrapLoopControlTry(lambdaIfBody, newAccTuple)
            }
        ]));

        #if debug_loop_builder
        var reducerStr = ElixirASTPrinter.print(reducerFn, 0);
        #end

        var result = ERemoteCall(
            makeAST(EVar("Enum")),
            "reduce_while",
            [
                makeAST(ERemoteCall(
                    makeAST(EVar("Stream")),
                    "iterate",
                    [
                        makeAST(EInteger(0)),
                        makeAST(EFn([{
                            args: [PVar("n")],
                            guard: null,
                            body: makeAST(EBinary(Add, makeAST(EVar("n")), makeAST(EInteger(1))))
                        }]))
                    ]
                )),
                initAcc,
                reducerFn
            ]
        );

        #if debug_loop_builder
        #end

        // Critical: bind the final accumulator back to the local variables so mutations
        // are visible after the loop.
        //
        // IMPORTANT:
        // - Avoid wrapping this rebinding in an EBlock. Nested EBlocks are printed as
        //   plain statement sequences in Elixir (no scope), but several hygiene passes
        //   treat EBlocks as analysis boundaries and can incorrectly underscore binders
        //   that are used *after* the loop in the surrounding function block.
        //
        // Haxe while/for expressions are Void, so the match expression's value is ignored
        // in statement position.
        return EMatch(finalAccPattern, makeAST(result));
    }
    
    /**
     * Transform expression to use pattern-matched variables
     *
     * NOTE: We intentionally use distinct reducer binder names (acc_<var>) to avoid
     * Elixir shadowing warnings when the loop variables already exist in the outer scope.
     * This helper rewrites references/assignments inside the reducer body accordingly.
     */
    static function transformExpressionWithMapping(expr: ElixirAST, rename: Map<String, String>): ElixirAST {
        if (expr == null || rename == null) return expr;

        inline function mapped(name: String): Null<String> {
            return (name != null && rename.exists(name)) ? rename.get(name) : null;
        }

        function renamePattern(p: EPattern): EPattern {
            return switch (p) {
                case PVar(nm):
                    var to = mapped(nm);
                    to != null ? PVar(to) : p;
                case PTuple(items): PTuple([for (it in items) renamePattern(it)]);
                case PList(items): PList([for (it in items) renamePattern(it)]);
                case PCons(h, t): PCons(renamePattern(h), renamePattern(t));
                case PMap(pairs):
                    PMap([for (pair in pairs) { key: pair.key, value: renamePattern(pair.value) }]);
                case PStruct(name, fields):
                    PStruct(name, [for (f in fields) { key: f.key, value: renamePattern(f.value) }]);
                case PPin(inner): PPin(renamePattern(inner));
                case PAlias(aliasName, inner):
                    var toAlias = mapped(aliasName);
                    var renamedInner = renamePattern(inner);
                    (toAlias != null) ? PAlias(toAlias, renamedInner) : PAlias(aliasName, renamedInner);
                default:
                    p;
            }
        }

        return ElixirASTTransformer.transformNode(expr, function(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;

            return switch (n.def) {
                case EVar(name):
                    var to = mapped(name);
                    to != null ? makeASTWithMeta(EVar(to), n.metadata, n.pos) : n;

                // Match with pattern binder (assignments): rewrite LHS patterns for threaded vars.
                case EMatch(pattern, rhs):
                    var newPattern = renamePattern(pattern);
                    newPattern != pattern ? makeASTWithMeta(EMatch(newPattern, rhs), n.metadata, n.pos) : n;

                default:
                    n;
            }
        });
    }
    
    /**
     * Generate idiomatic Enum call for array operations
     */
    static function generateIdiomaticEnumCall(
        arrayRef: TypedExpr,
        operation: String,
        body: TypedExpr,
        context: BuildContext,
        toElixirVarName: String -> String
    ): ElixirASTDef {
        var buildExpression = context.getExpressionBuilder();
        var array = buildExpression(arrayRef);
        
        switch(operation) {
            case "map":
                // Extract the transformation from the body
                var itemVar = "item";
                var transformation = buildExpression(body);
                
                return ERemoteCall(
                    makeAST(EVar("Enum")),
                    "map",
                    [
                        array,
                        makeAST(EFn([{
                            args: [PVar(itemVar)],
                            guard: null,
                            body: transformation
                        }]))
                    ]
                );
                
            case "filter":
                var itemVar = "item";
                var predicate = buildExpression(body);
                
                return ERemoteCall(
                    makeAST(EVar("Enum")),
                    "filter",
                    [
                        array,
                        makeAST(EFn([{
                            args: [PVar(itemVar)],
                            guard: null,
                            body: predicate
                        }]))
                    ]
                );
                
            case "each":
                // Derive a stable binder name from the body when possible
                var itemVar = (function(): String {
                    // Try to find a local used as a field target, e.g., `todo.completed`
                    var candidate: Null<String> = null;
                    function scan(e: TypedExpr): Void {
                        if (e == null) return;
                        switch (e.expr) {
                            case TField(obj, _):
                                switch (obj.expr) {
                                    case TLocal(v):
                                        // Prefer user vars (not compiler temps starting with _)
                                        if (candidate == null && !StringTools.startsWith(v.name, "_")) candidate = v.name;
                                    default:
                                }
                                // Continue scanning nested
                                scan(obj);
                            case TLocal(v2):
                                if (candidate == null && !StringTools.startsWith(v2.name, "_")) candidate = v2.name;
                            case TCall(f, args):
                                scan(f); for (a in args) scan(a);
                            case TBlock(es):
                                for (ee in es) scan(ee);
                            case TIf(c,t,el):
                                scan(c); scan(t); if (el != null) scan(el);
                            default:
                        }
                    }
                    scan(body);
                    return candidate != null ? reflaxe.elixir.ast.ElixirASTHelpers.toElixirVarName(candidate) : "item";
                })();
                var action = buildExpression(body);
                
                return ERemoteCall(
                    makeAST(EVar("Enum")),
                    "each",
                    [
                        array,
                        makeAST(EFn([{
                            args: [PVar(itemVar)],
                            guard: null,
                            body: action
                        }]))
                    ]
                );
                
            default:
                // Fall back to generic iteration
                return buildWhileLoop(
                    arrayRef,  // Use as condition (simplified)
                    body,
                    true,
                    context,
                    toElixirVarName
                );
        }
    }
    
    /**
     * Helper: Create metadata for loop expressions
     */
    static function createMetadata(expr: TypedExpr): ElixirMetadata {
        return {};
    }
    
    /**
     * Helper: Extract range minimum value
     */
    static function extractRangeMin(iterator: TypedExpr): Int {
        switch(iterator.expr) {
            case TBinop(OpInterval, startExpr, _):
                switch(startExpr.expr) {
                    case TConst(TInt(i)): return i;
                    default: return 0;
                }
            default: return 0;
        }
    }
    
    /**
     * Helper: Extract range maximum value
     */
    static function extractRangeMax(iterator: TypedExpr): Int {
        switch(iterator.expr) {
            case TBinop(OpInterval, _, endExpr):
                switch(endExpr.expr) {
                    case TConst(TInt(i)): return i - 1;  // Exclusive range
                    default: return 0;
                }
            default: return 0;
        }
    }
    
    /**
     * Helper: Capture iterator expression as string
     */
    static function captureIteratorExpression(iterator: TypedExpr): String {
        switch(iterator.expr) {
            case TBinop(OpInterval, startExpr, endExpr):
                var start = switch(startExpr.expr) {
                    case TConst(TInt(i)): Std.string(i);
                    default: "?";
                };
                var end = switch(endExpr.expr) {
                    case TConst(TInt(i)): Std.string(i - 1);
                    default: "?";
                };
                return start + ".." + end;
            default: return "unknown";
        }
    }
    
    /**
     * Helper: Capture expression text for debugging
     */
    static function captureExpressionText(expr: TypedExpr, varName: String): String {
        // Simplified implementation
        return "<expression with " + varName + ">";
    }
}

/**
 * Import emission strategies from LoopIR
 */
typedef EmissionStrategy = reflaxe.elixir.ast.loop_ir.LoopIR.EmissionStrategy;

#end
