package reflaxe.elixir.ast.loop_ir;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;

/**
 * LoopIR: Intermediate Representation for Loop Constructs
 *
 * WHY: Decouple pattern recognition from code emission. The same loop pattern
 * can be emitted as Enum operations, comprehensions, or recursive functions
 * depending on context and optimization goals.
 *
 * WHAT: Captures the semantic essence of a loop:
 * - Iteration source (range, collection, stream)
 * - Element binding pattern
 * - Accumulator state and updates
 * - Filters and conditions
 * - Body effects and transformations
 * - Early exit conditions
 *
 * HOW: Analyzers populate this IR from TypedExpr patterns.
 * Emitters consume this IR to generate idiomatic Elixir.
 *
 * ARCHITECTURE BENEFITS:
 * - Single source of truth for loop semantics
 * - Testable intermediate representation
 * - Clean separation between analysis and emission
 * - Enables multiple emission strategies
 */

/**
 * Main Loop IR structure
 */
typedef LoopIR = {
    /**
     * Kind of loop structure
     */
    kind: LoopKind,

    /**
     * Source of iteration
     */
    source: LoopSource,

    /**
     * Pattern for binding iteration elements
     */
    elementPattern: Null<ElementPattern>,

    /**
     * Accumulator variables and their updates
     */
    accumulators: Array<AccumulatorInfo>,

    /**
     * Filter conditions from the loop body
     */
    filters: Array<FilterInfo>,

    /**
     * Transformation applied to produce values
     */
    yield: Null<YieldInfo>,

    /**
     * Early exit information (break/return/continue)
     */
    earlyExit: Null<EarlyExitInfo>,

    /**
     * Body effect analysis
     */
    bodyEffects: BodyEffects,

    /**
     * Confidence score for pattern detection (0.0 - 1.0)
     */
    confidence: Float,

    /**
     * Original TypedExpr for fallback
     */
    originalExpr: TypedExpr
}

/**
 * Type of loop construct
 */
enum LoopKind {
    ForRange;       // for (i in 0...n)
    ForEach;        // for (item in collection)
    While;          // while (condition)
    DoWhile;        // do { } while (condition)
    Comprehension;  // Array comprehension pattern
}

/**
 * Source of iteration values
 */
enum LoopSource {
    Range(start: ElixirAST, end: ElixirAST, step: Int);
    Collection(expr: ElixirAST);
    Stream(generator: ElixirAST);
    Condition(expr: ElixirAST);  // For while loops
    MapKeys(mapExpr: ElixirAST);  // Detected Map.keys pattern
    ReflectFields(objExpr: ElixirAST);  // Detected Reflect.fields pattern
}

/**
 * Pattern for destructuring iteration elements
 */
typedef ElementPattern = {
    varName: String,
    pattern: ElixirAST,  // Can be simple var or complex pattern
    type: Type
}

/**
 * Accumulator variable information
 */
typedef AccumulatorInfo = {
    name: String,
    initialValue: ElixirAST,
    updateExpr: ElixirAST,
    updateKind: AccumulatorUpdate,
    isMutable: Bool  // Requires rebinding in Elixir
}

/**
 * How accumulator is updated
 */
enum AccumulatorUpdate {
    Append;      // list.push(item)
    Prepend;     // [item | list]
    Increment;   // counter++
    Assignment;  // acc = expr
    Custom(expr: ElixirAST);
}

/**
 * Filter condition information
 */
typedef FilterInfo = {
    condition: ElixirAST,
    scope: FilterScope
}

/**
 * Where filter applies
 */
enum FilterScope {
    PreIteration;   // Check before processing element
    PostIteration;  // Check after processing element
    Yield;          // Only affects what gets yielded
}

/**
 * Yield/transformation information
 */
typedef YieldInfo = {
    expr: ElixirAST,
    isConditional: Bool,  // Has filters affecting yield
    targetAccumulator: Null<String>  // Which accumulator receives result
}

/**
 * Early exit information
 */
typedef EarlyExitInfo = {
    kind: EarlyExitKind,
    condition: Null<ElixirAST>,
    value: Null<ElixirAST>
}

/**
 * Type of early exit
 */
enum EarlyExitKind {
    Break;           // Simple break
    Return(value: ElixirAST);  // Return from function
    Continue;        // Skip to next iteration
    ConditionalBreak(cond: ElixirAST);  // Break on condition
}

/**
 * Analysis of loop body effects
 */
typedef BodyEffects = {
    hasSideEffects: Bool,     // IO, mutations, etc.
    producesValue: Bool,      // Returns/yields values
    modifiesAccumulator: Bool,  // Updates state
    hasNestedLoops: Bool,     // Contains inner loops
    hasComplexControl: Bool   // Multiple exit points
}

/**
 * Emission strategy preference
 */
enum EmissionStrategy {
    EnumEach;        // Enum.each for side effects
    EnumMap;         // Enum.map for transformations
    EnumReduce;      // Enum.reduce for accumulation
    EnumReduceWhile; // Enum.reduce_while for early exit
    Comprehension;   // for x <- list, do: ...
    Recursion;       // Tail-recursive function
    Stream;          // Stream operations
    Legacy;          // Fall back to original logic
}

#end