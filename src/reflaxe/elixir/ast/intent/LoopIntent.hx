package reflaxe.elixir.ast.intent;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr.Position;
import reflaxe.elixir.ast.ElixirAST;

typedef TypedExpr = haxe.macro.Type.TypedExpr;
/**
 * LoopIntent: Semantic Loop Representation
 * 
 * WHY: Haxe desugars for loops into while loops with infrastructure variables (g, g1, etc.)
 * that leak into generated code. By capturing the loop's semantic intent BEFORE it enters
 * the complex LoopBuilder transformation pipeline, we preserve the original variable names
 * and can generate clean, idiomatic Elixir without infrastructure variable pollution.
 * 
 * WHAT: An intermediate representation that captures the essential semantics of loops:
 * - User-defined loop variable names (not infrastructure variables)
 * - Range/collection expressions
 * - Loop body with proper variable bindings
 * - Accumulator patterns for functional transformations
 * 
 * HOW: The ElixirASTBuilder detects desugared loop patterns and creates LoopIntent objects
 * instead of directly calling LoopBuilder. The LoopIntentProcessor then transforms these
 * intents into idiomatic Elixir (Enum.each, comprehensions, etc.) with correct variable names.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Intent captures WHAT, processor decides HOW
 * - Open/Closed: New loop patterns can be added without modifying existing code
 * - Testability: Intent objects can be tested independently of generation
 * - Clarity: Explicit representation of loop semantics improves debugging
 * 
 * @since LoopIntent Architecture (September 2025)
 */
enum LoopIntent {
	/**
	 * Range-based for loop: for (i in start...end)
	 * 
	 * @param varName The user-defined loop variable name (e.g., "i", "index")
	 * @param start The starting value expression
	 * @param end The ending value expression (exclusive)
	 * @param body The loop body to execute for each iteration
	 * @param isInclusive Whether the range is inclusive (start..end) or exclusive (start...end)
	 */
	RangeLoop(varName: String, start: TypedExpr, end: TypedExpr, body: TypedExpr, isInclusive: Bool);
	
	/**
	 * Collection-based for loop: for (item in collection)
	 * 
	 * @param varName The user-defined iteration variable name (e.g., "item", "todo")
	 * @param collection The collection expression to iterate over
	 * @param body The loop body to execute for each element
	 */
	CollectionLoop(varName: String, collection: TypedExpr, body: TypedExpr);
	
	/**
	 * While loop: while (condition)
	 * 
	 * @param condition The loop continuation condition
	 * @param body The loop body to execute while condition is true
	 * @param counterVar Optional counter variable for desugared patterns
	 */
	WhileLoop(condition: TypedExpr, body: TypedExpr, ?counterVar: String);
	
	/**
	 * Do-while loop: do { body } while (condition)
	 * 
	 * @param body The loop body to execute at least once
	 * @param condition The continuation condition checked after each iteration
	 */
	DoWhileLoop(body: TypedExpr, condition: TypedExpr);
	
	/**
	 * Comprehension pattern: [for (x in xs) if (pred(x)) transform(x)]
	 * Detected when loop builds a collection with accumulator
	 * 
	 * @param varName The iteration variable name
	 * @param collection The source collection
	 * @param transform The transformation applied to each element
	 * @param filter Optional predicate for filtering elements
	 * @param accumulator Variable that collects results (e.g., "items", "results")
	 */
	ComprehensionLoop(varName: String, collection: TypedExpr, transform: TypedExpr, ?filter: TypedExpr, ?accumulator: String);
	
	/**
	 * Map pattern: collection.map(x -> transform(x))
	 * Detected when loop transforms each element without filtering
	 * 
	 * @param varName The iteration variable name
	 * @param collection The source collection
	 * @param transform The transformation function
	 */
	MapLoop(varName: String, collection: TypedExpr, transform: TypedExpr);
	
	/**
	 * Filter pattern: collection.filter(x -> predicate(x))
	 * Detected when loop selectively includes elements
	 * 
	 * @param varName The iteration variable name
	 * @param collection The source collection
	 * @param predicate The filter condition
	 */
	FilterLoop(varName: String, collection: TypedExpr, predicate: TypedExpr);
	
	/**
	 * Reduce/fold pattern: collection.reduce(init, (acc, x) -> combine(acc, x))
	 * Detected when loop accumulates a single value
	 * 
	 * @param varName The iteration variable name
	 * @param collection The source collection
	 * @param accumulator The accumulator variable name
	 * @param init Initial accumulator value
	 * @param combine The combination function
	 */
	ReduceLoop(varName: String, collection: TypedExpr, accumulator: String, init: TypedExpr, combine: TypedExpr);
}

/**
 * Accumulator variable information
 */
typedef AccumulatorVar = {
	var name: String;
	var type: String;
}

/**
 * Metadata attached to LoopIntent for additional context
 */
typedef LoopIntentMetadata = {
	/**
	 * Variables that appear to be accumulators (modified in loop body)
	 * These need initialization before the loop (e.g., items = [])
	 */
	var ?accumulatorVars: Array<AccumulatorVar>;
	
	/**
	 * Original source position for error reporting
	 */
	var ?sourcePos: Position;
	
	/**
	 * Whether this loop was desugared from a for loop by Haxe
	 */
	var ?wasDesugared: Bool;
	
	/**
	 * Infrastructure variables to remove (g, g1, _g, etc.)
	 */
	var ?infrastructureVars: Array<String>;
	
	/**
	 * Variable mapping for infrastructure variable elimination
	 * Maps infrastructure names (_g, _g1) to user names (i, limit)
	 */
	var ?variableMapping: Map<String, String>;
	
	/**
	 * Hints for optimization (e.g., "can_be_comprehension", "tail_recursive")
	 */
	var ?optimizationHints: Array<String>;
}

/**
 * Container for LoopIntent with metadata
 */
typedef LoopIntentWithMetadata = {
	var intent: LoopIntent;
	var metadata: LoopIntentMetadata;
}
#end
