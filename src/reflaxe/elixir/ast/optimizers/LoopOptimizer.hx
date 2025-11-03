package reflaxe.elixir.ast.optimizers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.ast.context.BuildContext;
import reflaxe.elixir.ast.intent.LoopIntent;
import reflaxe.elixir.ast.intent.LoopIntent.*;

/**
 * LoopOptimizer: Loop Analysis and Optimization Module
 * 
 * WHY: Loop optimization is a complex domain requiring specialized analysis patterns.
 * Having 1000+ lines of loop optimization code mixed with general AST building
 * violates Single Responsibility and makes the code harder to maintain. By extracting
 * loop optimization into its own module, we achieve better separation of concerns
 * and make both the optimizer and the main builder more maintainable.
 * 
 * WHAT: Provides comprehensive loop analysis and optimization capabilities:
 * - Pattern detection for array operations (map, filter, reduce)
 * - Loop intent analysis for semantic understanding
 * - Transformation from imperative loops to functional Elixir patterns
 * - Variable substitution and reference tracking
 * - Early return detection and transformation
 * 
 * HOW: The optimizer analyzes TypedExpr loop structures to detect patterns,
 * then transforms them into idiomatic Elixir constructs using Enum functions,
 * comprehensions, or recursive functions as appropriate.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on loop optimization
 * - Open/Closed Principle: New optimization patterns can be added without modifying core
 * - Testability: Loop optimization can be tested independently
 * - Maintainability: Clear boundaries and focused functionality
 * - Performance: Specialized optimization logic without overhead
 * 
 * EDGE CASES:
 * - Nested loops with shared state
 * - Early returns within loops
 * - Variable shadowing in loop bodies
 * - Complex accumulator patterns
 * 
 * @see ElixirASTBuilder For delegation and integration
 * @see LoopIntent For semantic loop representation
 */
class LoopOptimizer {
	
	/**
	 * Analyze loop body to detect common patterns
	 * 
	 * WHY: Haxe desugars high-level operations into low-level loops that
	 * need to be reconstructed for idiomatic Elixir generation.
	 * 
	 * WHAT: Analyzes a loop body to detect map, filter, and push patterns
	 * that can be optimized into functional operations.
	 * 
	 * HOW: Recursively traverses the loop body AST looking for characteristic
	 * patterns like array.push(), conditional pushes, and transformations.
	 */
	public static function analyzeLoopBody(ebody: TypedExpr): {
		hasMapPattern: Bool,
		hasFilterPattern: Bool,
		hasPushPattern: Bool,
		hasReducePattern: Bool,
		arrayVar: Null<String>,
		transformExpr: Null<TypedExpr>,
		loopVar: Null<TVar>
	} {
		var result = {
			hasMapPattern: false,
			hasFilterPattern: false,
			hasPushPattern: false,
			hasReducePattern: false,
			arrayVar: null,
			transformExpr: null,
			loopVar: null
		};
		
		function analyze(expr: TypedExpr): Void {
			switch(expr.expr) {
				case TCall(arrAccess, [pushArg]):
					switch(arrAccess.expr) {
						case TField(arr, FInstance(_, _, cf)) if (cf.get().name == "push"):
							result.hasPushPattern = true;
							switch(arr.expr) {
								case TLocal(v):
									result.arrayVar = v.name;
								default:
							}
							result.transformExpr = pushArg;
						default:
					}
				
				case TIf(cond, thenExpr, elseExpr):
					// Check for filter pattern (conditional push)
					analyze(thenExpr);
					if (result.hasPushPattern) {
						result.hasFilterPattern = true;
					}
					if (elseExpr != null) {
						analyze(elseExpr);
					}
				
				case TBlock(exprs):
					for (e in exprs) {
						analyze(e);
					}
				
				default:
					TypedExprTools.iter(expr, analyze);
			}
		}
		
		analyze(ebody);
		
		// If we have push but no filter, it's a map pattern
		if (result.hasPushPattern && !result.hasFilterPattern) {
			result.hasMapPattern = true;
		}
		
		return result;
	}
	
	/**
	 * Detect array iteration patterns in loop conditions
	 * 
	 * WHY: Haxe desugars array iteration into index-based loops that
	 * need to be detected for proper optimization.
	 * 
	 * WHAT: Identifies patterns like `i < array.length` in loop conditions.
	 * 
	 * HOW: Pattern matches on the condition expression to find array
	 * length comparisons with index variables.
	 */
	public static function detectArrayIterationPattern(econd: TypedExpr): Null<{arrayExpr: TypedExpr, indexVar: String}> {
		return switch(econd.expr) {
			case TBinop(OpLt, {expr: TLocal(indexVar)}, {expr: TField(arrayExpr, FInstance(_, _, cf))}) if (cf.get().name == "length") :
				{arrayExpr: arrayExpr, indexVar: indexVar.name};
			case TBinop(OpLt, {expr: TLocal(indexVar)}, {expr: TField(arrayExpr, FAnon(cf))}) if (cf.get().name == "length") :
				{arrayExpr: arrayExpr, indexVar: indexVar.name};
			case TBinop(OpLt, {expr: TLocal(indexVar)}, {expr: TField(arrayExpr, FDynamic("length"))}) :
				{arrayExpr: arrayExpr, indexVar: indexVar.name};
			default:
				null;
		};
	}
	
	/**
	 * Detect array operation patterns in loop body
	 * 
	 * WHY: Array operations like map, filter, and reduce are often
	 * compiled to imperative loops that need optimization.
	 * 
	 * WHAT: Detects characteristic patterns in loop bodies that indicate
	 * array transformation operations.
	 * 
	 * HOW: Analyzes the loop body structure to identify push operations,
	 * conditionals, and transformations that match functional patterns.
	 */
	public static function detectArrayOperationPattern(body: TypedExpr): Null<String> {
		// Look for the characteristic patterns in the loop body
		function detectPattern(expr: TypedExpr): Null<String> {
			switch(expr.expr) {
				case TBlock(exprs) if (exprs.length > 0):
					// Check each expression in the block
					for (e in exprs) {
						var pattern = detectPattern(e);
						if (pattern != null) return pattern;
					}
					
				case TIf(cond, thenBranch, elseBranch):
					// Check for filter pattern
					var thenPattern = detectPattern(thenBranch);
					if (thenPattern == "map") {
						return "filter"; // Conditional map = filter
					}
					
				case TCall({expr: TField(_, FInstance(_, _, cf))}, _) if (cf.get().name == "push"):
					return "map"; // Direct push = map operation
					
				case TBinop(OpAssignOp(OpAdd), _, _):
					return "reduce"; // Accumulation = reduce operation
					
				default:
			}
			return null;
		}
		
		return detectPattern(body);
	}
	
	/**
	 * Extract map transformation from loop body
	 * 
	 * WHY: Map operations need their transformation function extracted
	 * for conversion to Enum.map.
	 * 
	 * WHAT: Extracts the transformation expression from a loop body
	 * that performs mapping operations.
	 * 
	 * HOW: Traverses the loop body to find the expression that's being
	 * pushed to the result array, with variable substitution.
	 */
	public static function extractMapTransformation(ebody: TypedExpr, loopVar: Null<TVar>): ElixirAST {
		// Default case - build the entire body
		function extractTransform(expr: TypedExpr): ElixirAST {
			switch(expr.expr) {
				case TCall(arrAccess, [pushArg]):
					switch(arrAccess.expr) {
						case TField(_, FInstance(_, _, cf)) if (cf.get().name == "push"):
							// Found the push - extract the transformation
							return buildFromTypedExprWithSubstitution(pushArg, loopVar);
						default:
					}
					
				case TBlock(exprs):
					// Look for push in block
					for (e in exprs) {
						var result = extractTransform(e);
						if (result != null) return result;
					}
					
				case TIf(cond, thenBranch, elseBranch):
					// Check then branch for push
					var result = extractTransform(thenBranch);
					if (result != null) return result;
					
				default:
			}
			return null;
		}
		
		var transform = extractTransform(ebody);
		if (transform != null) {
			return transform;
		}
		
		// Fallback: build the entire body
		return buildFromTypedExprWithSubstitution(ebody, loopVar);
	}
	
	/**
	 * Extract filter condition from loop body
	 * 
	 * WHY: Array filter operations are desugared into conditional pushes.
	 * 
	 * WHAT: Extracts the condition from if-statements that wrap array pushes.
	 * 
	 * HOW: Looks for TIf patterns and extracts the condition expression.
	 */
	public static function extractFilterCondition(ebody: TypedExpr): ElixirAST {
		switch(ebody.expr) {
			case TBlock(exprs):
				for (expr in exprs) {
					switch(expr.expr) {
						case TIf(cond, _, _):
							// Found condition, convert to ElixirAST
							return buildFromTypedExpr(cond);
						default:
					}
				}
			case TIf(cond, _, _):
				return buildFromTypedExpr(cond);
			default:
		}
		// Default to true if no condition found
		return {def: EAtom("true"), metadata: {}, pos: ebody.pos};
	}
	
	/**
	 * Build AST from TypedExpr  
	 * 
	 * WHY: Need to convert TypedExpr to ElixirAST for filter conditions.
	 * 
	 * WHAT: Converts a TypedExpr to ElixirAST.
	 * 
	 * HOW: Delegates to the main builder (placeholder for now).
	 */
	static function buildFromTypedExpr(expr: TypedExpr): ElixirAST {
		// This is a placeholder - in real implementation this would
		// delegate to the main ElixirASTBuilder
		return {def: EVar("_condition_placeholder"), metadata: {}, pos: expr.pos};
	}
	
	/**
	 * Build AST from TypedExpr with variable substitution
	 * 
	 * WHY: Loop variables often need to be renamed for idiomatic output.
	 * 
	 * WHAT: Converts TypedExpr to ElixirAST while substituting variable names.
	 * 
	 * HOW: During AST building, replaces references to the loop variable
	 * with a standardized name for cleaner output.
	 */
    static function buildFromTypedExprWithSubstitution(expr: TypedExpr, loopVar: Null<TVar>): ElixirAST {
        // Preserve original loop variable name (idiomatic, avoids drift).
        // When encountering references to the loop var, emit its snake_case name.
        switch(expr.expr) {
            case TLocal(v) if (loopVar != null && v.id == loopVar.id):
                var name = reflaxe.elixir.ast.ElixirASTHelpers.toElixirVarName(loopVar.name);
                return {def: EVar(name), metadata: {}, pos: expr.pos};
            default:
                // Fallback placeholder retained for non-loop-var nodes in this stub path
                return {def: EVar("_placeholder"), metadata: {}, pos: expr.pos};
        }
    }
	
	/**
	 * Transform variable references in AST
	 * 
	 * WHY: Infrastructure variables need to be replaced with user-friendly names.
	 * 
	 * WHAT: Recursively transforms variable references according to a mapping.
	 * 
	 * HOW: Traverses the AST and replaces EVar nodes according to the
	 * provided variable name mapping.
	 */
	public static function transformVariableReferences(ast: ElixirAST, varMapping: Map<String, String>): ElixirAST {
		if (varMapping == null || varMapping.keys().hasNext() == false) {
			return ast;
		}
		
		function transform(node: ElixirAST): ElixirAST {
			switch(node.def) {
				case EVar(name):
					if (varMapping.exists(name)) {
						return {def: EVar(varMapping.get(name)), metadata: node.metadata, pos: node.pos};
					}
					
				case EBlock(exprs):
					return {def: EBlock(exprs.map(transform)), metadata: node.metadata, pos: node.pos};
					
				case ECall(target, funcName, args):
					return {def: ECall(target != null ? transform(target) : null, funcName, args.map(transform)), metadata: node.metadata, pos: node.pos};
					
				case EBinary(op, left, right):
					return {def: EBinary(op, transform(left), transform(right)), metadata: node.metadata, pos: node.pos};
					
				case EIf(cond, thenBranch, elseBranch):
					return {def: EIf(
						transform(cond),
						transform(thenBranch),
						elseBranch != null ? transform(elseBranch) : null
					), metadata: node.metadata, pos: node.pos};
					
				case EFn(clauses):
					return {def: EFn(clauses.map(c -> {
						args: c.args,
						guard: c.guard != null ? transform(c.guard) : null,
						body: transform(c.body)
					})), metadata: node.metadata, pos: node.pos};
					
				case ECase(expr, clauses):
					return {def: ECase(
						transform(expr),
						clauses.map(c -> {
							pattern: c.pattern,
							guard: c.guard != null ? transform(c.guard) : null,
							body: transform(c.body)
						})
					), metadata: node.metadata, pos: node.pos};
					
				default:
					// For other node types, return as-is
					// In a complete implementation, all node types would be handled
			}
			return node;
		}
		
		return transform(ast);
	}
	
	/**
	 * Check for early returns in AST
	 * 
	 * WHY: Early returns in loops need special handling for proper
	 * Elixir generation.
	 * 
	 * WHAT: Detects if an AST contains return statements.
	 * 
	 * HOW: Recursively traverses the AST looking for EReturn nodes.
	 */
	public static function checkForEarlyReturns(ast: ElixirAST): Bool {
		function check(node: ElixirAST): Bool {
			switch(node.def) {
				case EThrow(_):
					return true;
					
				case EBlock(exprs):
					for (e in exprs) {
						if (check(e)) return true;
					}
					
				case EIf(_, thenBranch, elseBranch):
					if (check(thenBranch)) return true;
					if (elseBranch != null && check(elseBranch)) return true;
					
				case ECase(_, clauses):
					for (clause in clauses) {
						if (check(clause.body)) return true;
					}
					
				default:
					// Continue checking other node types
			}
			return false;
		}
		
		return check(ast);
	}
	
	/**
	 * Transform returns to halts for reduce_while
	 * 
	 * WHY: Elixir's reduce_while uses {:halt, value} for early termination
	 * instead of return statements.
	 * 
	 * WHAT: Transforms EReturn nodes into {:halt, value} tuples.
	 * 
	 * HOW: Recursively replaces return statements with halt tuples
	 * while preserving the accumulator for non-return paths.
	 */
	public static function transformReturnsToHalts(body: ElixirAST, accumulator: ElixirAST): ElixirAST {
		function transform(node: ElixirAST): ElixirAST {
			switch(node.def) {
				case EThrow(value):
					// Transform throw to {:halt, value}
					return {def: ETuple([
						{def: EAtom("halt"), metadata: {}, pos: node.pos},
						value
					]), metadata: {}, pos: node.pos};
					
				case EBlock(exprs):
					var transformed = exprs.map(transform);
					// Ensure last expression continues if not a return
					if (transformed.length > 0) {
						var last = transformed[transformed.length - 1];
						if (!isHaltTuple(last)) {
							transformed[transformed.length - 1] = ensureContinue(last, accumulator);
						}
					}
					return {def: EBlock(transformed), metadata: node.metadata, pos: node.pos};
					
				case EIf(cond, thenBranch, elseBranch):
					return {def: EIf(
						cond,
						transform(thenBranch),
						elseBranch != null ? transform(elseBranch) : ensureContinue(accumulator, accumulator)
					), metadata: node.metadata, pos: node.pos};
					
				default:
					return node;
			}
		}
		
		return transform(body);
	}
	
	/**
	 * Process a LoopIntent and generate corresponding ElixirAST
	 * 
	 * WHY: The LoopIntent pattern separates semantic intent from implementation.
	 * By processing intents here, we centralize loop optimization logic.
	 * 
	 * WHAT: Transforms LoopIntent objects into idiomatic Elixir AST nodes,
	 * choosing between Enum functions, comprehensions, or recursive functions
	 * based on the loop semantics and context.
	 * 
	 * HOW: Pattern matches on LoopIntent variants and delegates to appropriate
	 * generation strategies, applying optimizations where possible.
	 */
	public static function processLoopIntent(intent: LoopIntent, metadata: LoopIntentMetadata, context: BuildContext): ElixirAST {
		#if debug_loop_optimizer
		trace('[processLoopIntent] Processing loop intent: ${intent}');
		#end
		
		switch(intent) {
			case RangeLoop(varName, start, end, body, isInclusive):
				// Generate Enum.each for range loops
				var range = generateRange(start, end, isInclusive, context);
				var lambda = generateLambda(varName, body, context);
				return generateEnumCall("each", range, lambda);
				
			case CollectionLoop(varName, collection, body):
				// Generate Enum.each for collection iteration
				var buildExpression = context.getExpressionBuilder();
				var collectionAST = buildExpression(collection);
				var lambda = generateLambda(varName, body, context);
				return generateEnumCall("each", collectionAST, lambda);
				
			case MapLoop(varName, collection, transform):
				// Generate Enum.map for transformation
				var buildExpression = context.getExpressionBuilder();
				var collectionAST = buildExpression(collection);
				var lambda = generateLambda(varName, transform, context);
				return generateEnumCall("map", collectionAST, lambda);
				
			case FilterLoop(varName, collection, predicate):
				// Generate Enum.filter for filtering
				var buildExpression = context.getExpressionBuilder();
				var collectionAST = buildExpression(collection);
				var lambda = generateLambda(varName, predicate, context);
				return generateEnumCall("filter", collectionAST, lambda);
				
			case ReduceLoop(varName, collection, accumulator, init, combine):
				// Generate Enum.reduce for accumulation
				var buildExpression = context.getExpressionBuilder();
				var collectionAST = buildExpression(collection);
				var initAST = buildExpression(init);
				var lambda = generateReduceLambda(varName, accumulator, combine, context);
				return generateEnumReduce(collectionAST, initAST, lambda);
				
			case WhileLoop(condition, body, counterVar):
				// Generate a recursive function for proper while semantics
				return generateRecursiveWhile(condition, body, counterVar, context);
				
			case ComprehensionLoop(varName, collection, transform, filter, accumulator):
				// Generate a comprehension
				return generateComprehension(varName, collection, transform, filter, context);
				
			case DoWhileLoop(body, condition):
				// Generate recursive function that executes body at least once
				return generateDoWhile(body, condition, context);
				
			default:
				#if debug_loop_optimizer
				trace('[processLoopIntent] Unhandled loop intent type: ${intent}');
				#end
				// Fallback to basic block
				return {def: EBlock([]), metadata: {}, pos: null};
		}
	}
	
	/**
	 * Detect fluent API patterns in function bodies
	 * 
	 * WHY: Fluent APIs that return 'this' need special handling to
	 * maintain chainability in generated code.
	 * 
	 * WHAT: Detects functions that mutate fields and return 'this'.
	 * 
	 * HOW: Analyzes the function body for field mutations and checks
	 * if the return value is 'this'.
	 */
	public static function detectFluentAPIPattern(func: TFunc): {returnsThis: Bool, fieldMutations: Array<{field: String, expr: TypedExpr}>} {
		var result = {
			returnsThis: false,
			fieldMutations: []
		};
		
		function analyze(expr: TypedExpr): Void {
			switch(expr.expr) {
				case TBinop(OpAssign, {expr: TField({expr: TConst(TThis)}, FInstance(_, _, fieldRef))}, value):
					result.fieldMutations.push({field: fieldRef.get().name, expr: value});
					
				case TReturn(e) if (e != null && e.expr.match(TConst(TThis))):
					result.returnsThis = true;
					
				case TConst(TThis) if (func.expr != null):
					// Check if this is the last expression (implicit return)
					switch(func.expr.expr) {
						case TBlock(exprs) if (exprs.length > 0 && exprs[exprs.length - 1] == expr):
							result.returnsThis = true;
						default:
					}
					
				default:
					TypedExprTools.iter(expr, analyze);
			}
		}
		
		if (func.expr != null) {
			analyze(func.expr);
		}
		
		return result;
	}
	
	/**
	 * Detect Map iteration patterns
	 * 
	 * WHY: Map iteration in Haxe generates complex patterns that need
	 * to be simplified to idiomatic Elixir.
	 * 
	 * WHAT: Detects Map.keyValueIterator patterns and extracts the
	 * key and value variable names.
	 * 
	 * HOW: Pattern matches on the characteristic sequence of expressions
	 * generated by Haxe's Map iteration desugaring.
	 */
	public static function detectMapIterationPattern(expressions: Array<TypedExpr>): Null<MapIterationPattern> {
		if (expressions.length < 2) return null;
		
		// Look for the pattern: iterator = map.keyValueIterator()
		for (i in 0...expressions.length) {
			switch(expressions[i].expr) {
				case TVar(iterVar, init) if (init != null && init.expr.match(TCall(_, []))):
					// Found iterator initialization, now look for the while loop
					for (j in (i+1)...expressions.length) {
						switch(expressions[j].expr) {
							case TWhile(condition, body, _):
								// Analyze the body to extract key and value variables
								var keyVar = null, valueVar = null;
								
								function findKeyValueVars(expr: TypedExpr): Void {
									switch(expr.expr) {
										case TVar(v, init) if (init != null):
											// Look for patterns like key = pair.key or value = pair.value
											switch(init.expr) {
												case TField(_, FInstance(_, _, cfRef)) if (cfRef.get().name == "key"):
													keyVar = v.name;
												case TField(_, FInstance(_, _, cfRef)) if (cfRef.get().name == "value"):
													valueVar = v.name;
												default:
											}
										case TBlock(blockExprs):
											for (e in blockExprs) {
												findKeyValueVars(e);
											}
										default:
											TypedExprTools.iter(expr, findKeyValueVars);
									}
								}
								
								findKeyValueVars(body);
								
								if (keyVar != null && valueVar != null) {
									// Return pattern compatible with ElixirASTBuilder's MapIterationPattern
									// Note: ElixirASTBuilder doesn't have iteratorVar field
									var pattern: Dynamic = {
										keyVar: keyVar,
										valueVar: valueVar,
										mapExpr: getMapExpression(init),
										body: body
									};
									return pattern;
								}
							default:
						}
					}
				default:
			}
		}
		
		return null;
	}
	
	// Helper functions for code generation
	
	static function generateRange(start: TypedExpr, end: TypedExpr, isInclusive: Bool, context: BuildContext): ElixirAST {
		var buildExpression = context.getExpressionBuilder();
		var startAST = buildExpression(start);
		var endAST = buildExpression(end);
		
		// Adjust for inclusive/exclusive range
		if (!isInclusive) {
			// For exclusive range (start...end), subtract 1 from end
			endAST = {def: EBinary(Subtract, endAST, {def: EInteger(1), metadata: {}, pos: end.pos}), metadata: {}, pos: end.pos};
		}
		
		return {def: ERange(startAST, endAST, !isInclusive), metadata: {}, pos: start.pos};
	}
	
	static function generateLambda(paramName: String, body: TypedExpr, context: BuildContext): ElixirAST {
		var buildExpression = context.getExpressionBuilder();
		var bodyAST = buildExpression(body);
		// Create EFn with a single clause
		var clause: EFnClause = {
			args: [PVar(paramName)],
			body: bodyAST
		};
		return {def: EFn([clause]), metadata: {}, pos: body.pos};
	}
	
	static function generateReduceLambda(itemVar: String, accVar: String, combine: TypedExpr, context: BuildContext): ElixirAST {
		var buildExpression = context.getExpressionBuilder();
		var combineAST = buildExpression(combine);
		var clause: EFnClause = {
			args: [PVar(itemVar), PVar(accVar)],
			body: combineAST
		};
		return {def: EFn([clause]), metadata: {}, pos: combine.pos};
	}
	
	static function generateEnumCall(method: String, collection: ElixirAST, lambda: ElixirAST): ElixirAST {
		return {def: ERemoteCall(
			{def: EVar("Enum"), metadata: {}, pos: null},
			method,
			[collection, lambda]
		), metadata: {}, pos: null};
	}
	
	static function generateEnumReduce(collection: ElixirAST, init: ElixirAST, lambda: ElixirAST): ElixirAST {
		return {def: ERemoteCall(
			{def: EVar("Enum"), metadata: {}, pos: null},
			"reduce",
			[collection, init, lambda]
		), metadata: {}, pos: null};
	}
	
	static function generateRecursiveWhile(condition: TypedExpr, body: TypedExpr, counterVar: Null<String>, context: BuildContext): ElixirAST {
		// Generate a recursive function for while loop semantics
		var buildExpression = context.getExpressionBuilder();
		var condAST = buildExpression(condition);
		var bodyAST = buildExpression(body);
		
		// Create recursive function with proper termination
		var funcName = "_while_loop";
		var recursiveCall = {def: ECall({def: EVar(funcName), metadata: {}, pos: null}, funcName, []), metadata: {}, pos: null};
		
		var ifExpr = {def: EIf(
			condAST,
			{def: EBlock([bodyAST, recursiveCall]), metadata: {}, pos: null},
			{def: EAtom("ok"), metadata: {}, pos: null}
		), metadata: {}, pos: null};
		
		// Create a proper function definition using EFn
		var fnClause: EFnClause = {
			args: [],
			body: ifExpr
		};
		var funcDef = {def: EFn([fnClause]), metadata: {}, pos: null};
		
		return {def: EBlock([
			{def: EBinary(Match, {def: EVar(funcName), metadata: {}, pos: null}, funcDef), metadata: {}, pos: null},
			{def: ECall({def: EVar(funcName), metadata: {}, pos: null}, funcName, []), metadata: {}, pos: null}
		]), metadata: {}, pos: null};
	}
	
	static function generateComprehension(varName: String, collection: TypedExpr, transform: TypedExpr, filter: Null<TypedExpr>, context: BuildContext): ElixirAST {
		var buildExpression = context.getExpressionBuilder();
		var collectionAST = buildExpression(collection);
		var transformAST = buildExpression(transform);
		
		var generators: Array<EGenerator> = [{
			pattern: PVar(varName),
			expr: collectionAST
		}];
		
		var filters = [];
		if (filter != null) {
			filters.push(buildExpression(filter));
		}
		
		return {def: EFor(generators, filters, transformAST, null, false), metadata: {}, pos: null};
	}
	
	static function generateDoWhile(body: TypedExpr, condition: TypedExpr, context: BuildContext): ElixirAST {
		// Generate a recursive function that executes body at least once
		var buildExpression = context.getExpressionBuilder();
		var bodyAST = buildExpression(body);
		var condAST = buildExpression(condition);
		
		var funcName = "_do_while";
		var recursiveCall = {def: ECall({def: EVar(funcName), metadata: {}, pos: null}, funcName, []), metadata: {}, pos: null};
		
		var funcBody = {def: EBlock([
			bodyAST,
			{def: EIf(condAST, recursiveCall, {def: EAtom("ok"), metadata: {}, pos: null}), metadata: {}, pos: null}
		]), metadata: {}, pos: null};
		
		// Create a proper function definition using EFn
		var fnClause: EFnClause = {
			args: [],
			body: funcBody
		};
		var funcDef = {def: EFn([fnClause]), metadata: {}, pos: null};
		
		return {def: EBlock([
			{def: EVar(funcName), metadata: {}, pos: null},
			{def: EBinary(Match, {def: EVar(funcName), metadata: {}, pos: null}, funcDef), metadata: {}, pos: null},
			{def: ECall({def: EVar(funcName), metadata: {}, pos: null}, funcName, []), metadata: {}, pos: null}
		]), metadata: {}, pos: null};
	}
	
	static function getMapExpression(keyValueIterator: TypedExpr): TypedExpr {
		// Extract the map expression from map.keyValueIterator() call
		switch(keyValueIterator.expr) {
			case TField(mapExpr, _):
				return mapExpr;
			default:
				return null;
		}
	}
	
	static function isHaltTuple(ast: ElixirAST): Bool {
		switch(ast.def) {
			case ETuple([{def: EAtom(a)}, _]) if (a == "halt"):
				return true;
			default:
				return false;
		}
	}
	
	static function ensureContinue(ast: ElixirAST, accumulator: ElixirAST): ElixirAST {
		// Wrap in {:cont, accumulator} if not already a control tuple
		if (isHaltTuple(ast)) {
			return ast;
		}
		
		return {def: ETuple([
			{def: EAtom("cont"), metadata: {}, pos: ast.pos},
			accumulator
		]), metadata: {}, pos: ast.pos};
	}
}

// Type definition for Map iteration pattern detection
typedef MapIterationPattern = {
	var iteratorVar: String;
	var keyVar: String;
	var valueVar: String;
	var mapExpr: TypedExpr;
	var body: TypedExpr;  // Changed from loopBody to body to match ElixirASTBuilder
}

#end
