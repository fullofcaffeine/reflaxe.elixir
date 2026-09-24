package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)
import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.CompilationContext;

/**
 * ArrayBuilder: Handles array declaration and access building
 * 
 * WHY: Separates array-related logic from ElixirASTBuilder
 * - Reduces ElixirASTBuilder complexity
 * - Centralizes array comprehension detection
 * - Handles array access patterns
 * 
 * WHAT: Builds ElixirAST nodes for array operations
 * - TArrayDecl: Array literal declarations [1, 2, 3]
 * - TArray: Array element access arr[index]
 * - Array comprehensions: [for (i in 0...n) expr]
 * 
 * HOW: Detects patterns and generates appropriate AST
 * - Simple arrays become EList
 * - Comprehensions become EFor
 * - Array access becomes semantic EAccess for representation-aware legalization
 */
@:nullSafety(Off)
class ArrayBuilder {
	/**
	 * Lower the existing list-backed Array.slice value operation.
	 *
	 * Haxe uses an exclusive end and clamps negative offsets relative to length.
	 * Enum.slice/3 expects a nonnegative start and count, so normalize both bounds
	 * before calling it. For example, [1, 2, 3, 4].slice(1, -1) yields [2, 3].
	 * Evaluate operands as function arguments in the caller's scope, then normalize
	 * their captured values in a pure function body. Putting operand assignments
	 * inside that body would hide their writes from the caller. A later argument
	 * can also rebind an earlier local. This does not implement managed Array identity
	 * or alias-visible mutation; those remain owned by the collection ABI work.
	 */
	public static function buildSlice(receiver:ElixirAST, start:ElixirAST, end:ElixirAST, endMayBeNil:Bool, context:CompilationContext):ElixirASTDef {
		var steps:Array<ElixirAST> = [];
		function bind(value:ElixirAST, label:String):ElixirAST {
			var name = 'array_slice_${label}_${context.generateNodeId()}';
			steps.push(makeAST(EMatch(PVar(name), value)));
			return makeAST(EVar(name));
		}
		var valuesName = 'array_slice_values_${context.generateNodeId()}';
		var startName = 'array_slice_start_${context.generateNodeId()}';
		var endName = end.def.match(ENil) ? "_" : 'array_slice_end_${context.generateNodeId()}';
		var values = makeAST(EVar(valuesName));
		var startValue = makeAST(EVar(startName));
		var endValue = makeAST(EVar(endName));
		var length = bind(makeAST(ECall(null, "length", [values])), "length");
		var zero = makeAST(EInteger(0));

		function normalize(value:ElixirAST):ElixirAST {
			var offset = makeAST(EIf(makeAST(EBinary(Less, value, zero)), makeAST(EBinary(Add, length, value)), value));
			return makeAST(ECall(null, "min", [length, makeAST(ECall(null, "max", [zero, offset]))]));
		}
		var first = bind(normalize(startValue), "first");
		var endBound = switch (end.def) {
			case ENil: length;
			case EInteger(_): normalize(endValue);
			default:
				endMayBeNil ? makeAST(EIf(makeAST(EBinary(Equal, endValue, makeAST(ENil))), length, normalize(endValue))) : normalize(endValue);
		};
		var last = bind(endBound, "last");
		var count = makeAST(ECall(null, "max", [zero, makeAST(EBinary(Subtract, last, first))]));
		steps.push(makeAST(ERemoteCall(makeAST(EVar("Enum")), "slice", [values, first, count])));
		var normalizeSlice = makeAST(EFn([
			{args: [PVar(valuesName), PVar(startName), PVar(endName)], guard: null, body: makeAST(EBlock(steps))}
		]));
		return ECall(normalizeSlice, "", [receiver, start, end]);
	}

	/**
	 * Build array declaration expression
	 * 
	 * @param elements Array elements to include
	 * @param context Build context with compilation state
	 * @return ElixirASTDef for the array
	 */
	public static function buildArrayDecl(elements:Array<TypedExpr>, context:CompilationContext):ElixirASTDef {
		var buildExpression = context.getExpressionBuilder();

		#if debug_ast_builder
		#end
		if (elements.length > 0) {
			#if debug_ast_builder
			#end
		}

		#if debug_ast_builder
		if (elements.length > 0) {}
		#end

		// Check for single-element array with TFor (direct comprehension)
		if (elements.length == 1 && elements[0].expr.match(TFor(_))) {
			// This is a comprehension like [for (i in 0...3) expr]
			// Return the TFor directly as EFor, not wrapped in EList
			#if debug_ast_builder
			#end
			return buildExpression(elements[0]).def;
		}

		// Check for single-element array with TBlock (desugared nested comprehension)
		if (elements.length == 1) {
			switch (elements[0].expr) {
				case TBlock(stmts):
					#if debug_ast_builder
					#end
					// Try to reconstruct comprehension from desugared block
					var comprehension = ComprehensionBuilder.tryBuildArrayComprehensionFromBlock(stmts, context);
					#if debug_ast_builder
					#end
					if (comprehension != null) {
						switch (comprehension.def) {
							case EFor(_, _, _, _, _):
								#if debug_ast_builder
								#end
								return comprehension.def;
							default:
								// Not a comprehension, proceed with normal list
						}
					} else {
						// Fallback: loose extraction of list-building blocks to avoid emitting
						// invalid bare concatenations inside array elements.
						var loose = ComprehensionBuilder.extractListElementsLoose(stmts, context);
						if (loose != null && loose.length > 0) {
							#if debug_ast_builder
							#end
							return EList(loose);
						}
					}
				default:
			}
		}

		// Normal array processing
		var builtElements = [];
		for (element in elements) {
			builtElements.push(buildExpression(element));
		}

		return EList(builtElements);
	}

	/**
	 * Build array access expression
	 * 
	 * @param array The array expression to access
	 * @param index The index expression
	 * @param context Build context with compilation state
	 * @return ElixirASTDef for the array access
	 */
	public static function buildArrayAccess(array:TypedExpr, index:TypedExpr, context:CompilationContext):ElixirASTDef {
		var buildExpression = context.getExpressionBuilder();

		var target = buildExpression(array);
		var key = buildExpression(index);

		// A Dynamic value can carry a list-backed Haxe array. Native Access.get
		// cannot index that list numerically. Capture both operands once, in source
		// order, and retain native access for other representations. Negative Haxe
		// indices are out of bounds, unlike Enum.at's offsets from the list tail.
		if (haxe.macro.TypeTools.follow(array.t).match(TDynamic(_))) {
			var id = context.generateNodeId();
			var valueName = 'dynamic_array_value_$id';
			var indexName = 'dynamic_array_index_$id';
			var valueRef = makeAST(EVar(valueName));
			var indexRef = makeAST(EVar(indexName));
			var pattern = PTuple([PVar(valueName), PVar(indexName)]);
			var isArrayIndex = makeAST(EBinary(And, makeAST(ECall(null, "is_list", [valueRef])), makeAST(ECall(null, "is_integer", [indexRef]))));
			var read = makeAST(EIf(makeAST(EBinary(Less, indexRef, makeAST(EInteger(0)))), makeAST(ENil),
				makeAST(ERemoteCall(makeAST(EVar("Enum")), "at", [valueRef, indexRef]))));
			var dispatch = makeAST(ECase(makeAST(ETuple([valueRef, indexRef])), [
				{pattern: pattern, guard: isArrayIndex, body: read},
				{pattern: pattern, body: makeAST(EAccess(valueRef, indexRef))}
			]));
			// Capture the receiver before lowering index effects. A tuple of the
			// original operands lets an index prelude rebind the receiver too early.
			// Keep these matches in caller scope so index writes remain visible.
			return EBlock([
				makeAST(EMatch(PVar(valueName), target)),
				makeAST(EMatch(PVar(indexName), key)),
				dispatch
			]);
		}

		return EAccess(target, key);
	}

	/**
	 * Check if an array declaration is actually a comprehension
	 * 
	 * WHY: Array comprehensions need special handling
	 * WHAT: Detects [for (...) ...] patterns
	 * HOW: Checks for single TFor element
	 */
	public static function isComprehension(elements:Array<TypedExpr>):Bool {
		if (elements.length != 1)
			return false;

		return switch (elements[0].expr) {
			case TFor(_): true;
			case TBlock(stmts):
				// Could be a desugared comprehension
				// Let ComprehensionBuilder determine
				false; // For now, let buildArrayDecl handle it
			default: false;
		}
	}
}
#end
