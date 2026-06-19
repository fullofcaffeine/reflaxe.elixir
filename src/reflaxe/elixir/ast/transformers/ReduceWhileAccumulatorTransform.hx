package reflaxe.elixir.ast.transformers;

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;

using reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceWhileAccumulatorTransform: Fixes variable shadowing in reduce_while loops
 * 
 * WHY: When variables are mutated inside Enum.reduce_while, Elixir doesn't allow
 * direct reassignment like `result = result <> "x"`. Instead, mutations must be
 * returned as part of the accumulator tuple {:cont, {new_values...}}.
 * 
 * WHAT: Transforms variable assignments inside reduce_while bodies to proper
 * accumulator updates, eliminating "variable unused" warnings from shadowing.
 * 
 * HOW:
 * - Detects Enum.reduce_while calls with tuple accumulators
 * - Finds variable assignments that shadow accumulator variables
 * - Transforms assignments into accumulator updates
 * - Ensures proper tuple return values with {:cont/:halt, updated_accumulator}
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles reduce_while accumulator threading
 * - Generates idiomatic Elixir: Proper functional accumulator patterns
 * - Eliminates warnings: No more variable shadowing issues
 * - Preserves semantics: Maintains correct execution order
 * 
 * EDGE CASES:
 * - Nested reduce_while calls
 * - Multiple variable mutations in one iteration
 * - Conditional mutations (inside if/case)
 * - Early returns with :halt
 *
 * EXAMPLES
 * Haxe:
 *   var users = [];
 *   for (u in 0...n) users.push(u);
 * Elixir (after lowering, before):
 *   Enum.reduce_while(..., {users}, fn _, {users} -> {:cont, {users}} end)
 * Elixir (after):
 *   {users} = Enum.reduce_while(...)
 */
@:nullSafety(Off)
class ReduceWhileAccumulatorTransform {
	/**
	 * Main transformation pass for fixing reduce_while accumulators
	 */
	public static function reduceWhileAccumulatorPass(ast:ElixirAST):ElixirAST {
		#if debug_reduce_while_transform
		#end

		return transformReduceWhile(ast);
	}

	static function transformReduceWhile(node:ElixirAST):ElixirAST {
		// First recursively transform children
		var transformedNode = ElixirASTTransformer.transformAST(node, transformReduceWhile);

		// Handle null nodes (which can indicate removed nodes)
		if (transformedNode == null) {
			return null;
		}

		// Then check if this is a reduce_while that needs transformation
		switch (transformedNode.def) {
			case ERemoteCall(module, "reduce_while", args) if (isEnumModule(module)):
				#if debug_reduce_while_transform
				#end

				if (args.length >= 3) {
					var collection = args[0];
					var initialAcc = args[1];
					var fnArg = args[2];

					// Check if the function has accumulator variables
					switch (fnArg.def) {
						case EFn(clauses):
							var transformedClauses = [];
							for (clause in clauses) {
								var transformedClause = transformReduceWhileClause(clause, initialAcc);
								transformedClauses.push(transformedClause);
							}

							// Return the transformed reduce_while
							return makeAST(ERemoteCall(module, "reduce_while", [collection, initialAcc, makeAST(EFn(transformedClauses))]));

						default:
							// Not a function literal, return as-is
							return transformedNode;
					}
				}

			default:
				// Not a reduce_while call
		}

		return transformedNode;
	}

	/**
	 * Transform a single clause of the reduce_while function
	 */
	static function transformReduceWhileClause(clause:{args:Array<EPattern>, guard:Null<ElixirAST>, body:ElixirAST},
			initialAcc:ElixirAST):{args:Array<EPattern>, guard:Null<ElixirAST>, body:ElixirAST} {
		// Extract accumulator variable names from the pattern
		var accVarNames = extractAccumulatorVars(clause.args);

		if (accVarNames.length == 0) {
			// No accumulator variables to track
			return clause;
		}

		#if debug_reduce_while_transform
		#end

		// Map outer accumulator locals (from the initial accumulator expression) to the reducer's
		// accumulator binder vars (often prefixed like `acc_names`). This lets us treat assignments
		// to the outer locals as accumulator updates instead of unrelated shadowed locals.
		var outerToAccAliases = buildOuterToAccumulatorAliases(initialAcc, accVarNames);

		// Nested loops are lowered to nested Enum.reduce_while calls. Transform those
		// inner reducers first, otherwise the outer reducer pass treats them as opaque
		// function calls and misses loop-local mutations such as an inner `y++`.
		var bodyWithNestedReducers = transformReduceWhile(clause.body);

		// Transform the body to handle variable mutations properly
		var transformedBody = transformClauseBody(bodyWithNestedReducers, accVarNames, outerToAccAliases);

		return {
			args: clause.args,
			guard: clause.guard,
			body: transformedBody
		};
	}

	/**
	 * Extract accumulator variable names from function arguments
	 */
	static function extractAccumulatorVars(args:Array<EPattern>):Array<String> {
		var varNames = [];

		// Usually pattern is [_, {var1, var2, ...}] for reduce_while
		if (args.length >= 2) {
			switch (args[1]) {
				case PTuple(patterns):
					for (p in patterns) {
						switch (p) {
							case PVar(name):
								varNames.push(name);
							default:
						}
					}
				case PVar(name):
					varNames.push(name);
				default:
			}
		}

		return varNames;
	}

	/**
	 * Transform the clause body to properly handle accumulator updates
	 */
	static function transformClauseBody(body:ElixirAST, accVarNames:Array<String>, outerToAccAliases:Map<String, String>):ElixirAST {
		// Deep transform to handle nested structures
		return transformBodyRecursive(body, accVarNames, new Map<String, ElixirAST>(), false, outerToAccAliases);
	}

	static function transformBodyRecursive(body:ElixirAST, accVarNames:Array<String>, accUpdates:Map<String, ElixirAST>, preserveAssignments:Bool = false,
			outerToAccAliases:Map<String, String> = null):ElixirAST {
		if (body == null)
			return null;

		function resolveAccumulatorName(varName:String):Null<String> {
			if (varName == null)
				return null;
			if (accVarNames.indexOf(varName) >= 0)
				return varName;
			var baseVarName = varName.length > 1 && varName.charAt(0) == "_" ? varName.substr(1) : varName;
			if (accVarNames.indexOf(baseVarName) >= 0)
				return baseVarName;
			if (outerToAccAliases != null && outerToAccAliases.exists(varName)) {
				var mapped = outerToAccAliases.get(varName);
				if (mapped != null && accVarNames.indexOf(mapped) >= 0)
					return mapped;
			}
			if (outerToAccAliases != null && baseVarName != varName && outerToAccAliases.exists(baseVarName)) {
				var mapped = outerToAccAliases.get(baseVarName);
				if (mapped != null && accVarNames.indexOf(mapped) >= 0)
					return mapped;
			}
			return null;
		}

		function rewriteAliasedVarRefs(expr:ElixirAST):ElixirAST {
			if (expr == null || outerToAccAliases == null)
				return expr;
			return ElixirASTTransformer.transformAST(expr, function(n:ElixirAST):ElixirAST {
				return switch (n.def) {
					case EVar(name) if (outerToAccAliases.exists(name)):
						var mapped = outerToAccAliases.get(name);
						mapped != null ? makeAST(EVar(mapped)) : n;
					default:
						n;
				}
			});
		}

		function rewriteAccumulatorVarRefs(expr:ElixirAST, sourceName:String, accName:String):ElixirAST {
			var aliased = rewriteAliasedVarRefs(expr);
			if (aliased == null || sourceName == null || accName == null)
				return aliased;
			var sourceBaseName = sourceName.length > 1 && sourceName.charAt(0) == "_" ? sourceName.substr(1) : sourceName;
			return ElixirASTTransformer.transformAST(aliased, function(n:ElixirAST):ElixirAST {
				return switch (n.def) {
					case EVar(name) if (name == sourceName || name == sourceBaseName):
						makeAST(EVar(accName));
					default:
						n;
				}
			});
		}

		function rewritePostfixValue(expr:ElixirAST, sourceName:String, accName:String):ElixirAST {
			var sourceBaseName = sourceName.length > 1 && sourceName.charAt(0) == "_" ? sourceName.substr(1) : sourceName;
			return switch (expr.def) {
				case EVar(name) if (name == sourceName || name == sourceBaseName):
					makeAST(EVar(accName));
				default:
					rewriteAccumulatorVarRefs(expr, sourceName, accName);
			};
		}

		// Convert a branch body into an expression that yields the updated accumulator variable,
		// while preserving side effects and without leaving rebinding assignments behind.
		inline function branchToAccumulatorValue(branchBody:ElixirAST, accVarName:String):ElixirAST {
			var branchUpdates = new Map<String, ElixirAST>();
			var transformedBranch = transformBodyRecursive(branchBody, accVarNames, branchUpdates, false, outerToAccAliases);
			var updatedValue = branchUpdates.exists(accVarName) ? branchUpdates.get(accVarName) : makeAST(EVar(accVarName));
			return switch (transformedBranch.def) {
				case EBlock(stmts):
					makeAST(EBlock(stmts.concat([updatedValue])));
				case EDo(stmts2):
					makeAST(EBlock(stmts2.concat([updatedValue])));
				case ENil:
					updatedValue;
				default:
					makeAST(EBlock([transformedBranch, updatedValue]));
			};
		}

		switch (body.def) {
			case ETry(tryBody, rescueClauses, catchClauses, afterBlock, elseBlock):
				// Preserve try/catch structure while still rewriting accumulator assignments
				// inside the try body (common for break/continue lowering).
				//
				// IMPORTANT:
				// Reducer bodies lowered from `for` loops are typically wrapped in `try/catch` to
				// support break/continue semantics. In that shape, we must preserve explicit
				// accumulator rebindings inside the try body; relying on "update substitution" into
				// the final `{:cont/:halt, acc}` tuple is brittle and can erase the reducer body when
				// nested control-flow is involved.
				//
				// So inside ETry we always preserve assignments, and allow the final return tuple to
				// simply reference the accumulator vars (which now hold the updated values).
				var transformedTryBody = transformBodyRecursive(tryBody, accVarNames, accUpdates.copy(), true, outerToAccAliases);
				var transformedRescue = rescueClauses == null ? [] : [
					for (r in rescueClauses)
						{
							pattern: r.pattern,
							varName: r.varName,
							body: transformBodyRecursive(r.body, accVarNames, accUpdates.copy(), true, outerToAccAliases)
						}
				];
				var transformedCatch = catchClauses == null ? [] : [
					for (c in catchClauses)
						{
							kind: c.kind,
							pattern: c.pattern,
							body: transformBodyRecursive(c.body, accVarNames, accUpdates.copy(), true, outerToAccAliases)
						}
				];
				var transformedAfter = afterBlock != null ? transformBodyRecursive(afterBlock, accVarNames, accUpdates.copy(), true, outerToAccAliases) : null;
				var transformedElse = elseBlock != null ? transformBodyRecursive(elseBlock, accVarNames, accUpdates.copy(), true, outerToAccAliases) : null;
				return makeAST(ETry(transformedTryBody, transformedRescue, transformedCatch, transformedAfter, transformedElse));

			case EIf(condition, thenBranch, elseBranch):
				// ⚠️ FIX: Don't remove if-expressions that contain return tuples
				// These are the lambda's main control flow (do-while pattern)
				var hasReturnTuple = containsReturnTuple(thenBranch) || (elseBranch != null && containsReturnTuple(elseBranch));

				#if debug_ast_transformer trace('[DEBUG] EIf processing - hasReturnTuple: $hasReturnTuple'); #end
				#if debug_ast_transformer trace('[DEBUG] thenBranch containsReturnTuple: ${containsReturnTuple(thenBranch)}'); #end
				if (elseBranch != null) {
					#if debug_ast_transformer trace('[DEBUG] elseBranch containsReturnTuple: ${containsReturnTuple(elseBranch)}'); #end
				}

				if (hasReturnTuple) {
					// This if-expression is the lambda's main control flow
					// Preserve it and recursively transform branches WITHOUT removing assignments
					#if debug_ast_transformer trace('[XRay ReduceWhile] Preserving if-expression with return tuples (main control flow)'); #end

					var transformedThen = transformBodyRecursive(thenBranch, accVarNames, accUpdates.copy(), true, outerToAccAliases);
					var transformedElse = elseBranch != null ? transformBodyRecursive(elseBranch, accVarNames, accUpdates.copy(), true,
						outerToAccAliases) : null;
					return makeAST(EIf(condition, transformedThen, transformedElse));
				}

				// Check if this if statement contains accumulator assignments
				var hasAccAssignments = checkForAccumulatorAssignments(thenBranch, accVarNames, outerToAccAliases)
					|| (elseBranch != null && checkForAccumulatorAssignments(elseBranch, accVarNames, outerToAccAliases));

				if (hasAccAssignments) {
					// This if contains accumulator updates (often nested). Rewrite it into an explicit
					// accumulator rebinding:
					//
					//   acc = if cond do ... updated acc ... else acc end
					//
					// This avoids erasing the reducer body (no "empty block" placeholders) and is robust
					// inside ETry-wrapped reducers.
					var resultVarName = findAccumulatorVarInIf(thenBranch, elseBranch, accVarNames, outerToAccAliases);
					if (resultVarName != null) {
						var rhs = makeAST(EIf(condition, branchToAccumulatorValue(thenBranch, resultVarName),
							elseBranch != null ? branchToAccumulatorValue(elseBranch, resultVarName) : makeAST(EVar(resultVarName))));
						return makeAST(EBinary(Match, makeAST(EVar(resultVarName)), rhs));
					}
				}

				// Regular if without accumulator assignments
				var transformedThen = transformBodyRecursive(thenBranch, accVarNames, accUpdates.copy(), false, outerToAccAliases);
				var transformedElse = elseBranch != null ? transformBodyRecursive(elseBranch, accVarNames, accUpdates.copy(), false, outerToAccAliases) : null;
				return makeAST(EIf(condition, transformedThen, transformedElse));

			case ECase(expr, branches):
				// Handle case statements with accumulator updates
				var hasAccAssignments = false;
				var accVarName:String = null;

				// Check if any branch contains accumulator assignments
				for (branch in branches) {
					if (checkForAccumulatorAssignments(branch.body, accVarNames, outerToAccAliases)) {
						hasAccAssignments = true;
						// Find which accumulator variable is being assigned
						accVarName = findAssignedAccumulator(branch.body, accVarNames, outerToAccAliases);
						if (accVarName != null)
							break;
					}
				}

				if (hasAccAssignments && accVarName != null) {
					// Transform case branches to return values instead of assigning.
					// When we are preserving assignments (main control-flow with return tuples),
					// we cannot rely on update-substitution into {:cont/:halt, acc} because that
					// would double-apply updates. Instead, rewrite to a direct rebinding:
					//
					//   acc = case ... do
					//     {:some, v} -> Map.put(acc, k, v)
					//     {:none} -> acc
					//   end
					//
					// This avoids Elixir's "unused/shadowed variable" warnings inside clause bodies
					// and keeps the accumulator threaded correctly within the reducer.
					var transformedBranches = [];
					for (branch in branches) {
						var extracted = extractValueFromAssignment(branch.body, accVarName);
						var transformedBody = extracted;
						if (transformedBody == branch.body) {
							// No assignment in this branch: preserve side effects, but ensure we
							// return the accumulator unchanged so all branches unify.
							var inner = transformBodyRecursive(branch.body, accVarNames, accUpdates.copy(), preserveAssignments, outerToAccAliases);
							if (preserveAssignments) {
								transformedBody = switch (inner.def) {
									case EBlock(sts): makeAST(EBlock(sts.concat([makeAST(EVar(accVarName))])));
									case EDo(sts2): makeAST(EBlock(sts2.concat([makeAST(EVar(accVarName))])));
									case ENil: makeAST(EVar(accVarName));
									default: makeAST(EBlock([inner, makeAST(EVar(accVarName))]));
								};
							} else {
								transformedBody = inner;
							}
						}
						transformedBranches.push({
							pattern: branch.pattern,
							guard: branch.guard,
							body: transformedBody
						});
					}

					var transformedCase = makeAST(ECase(expr, transformedBranches));

					if (preserveAssignments) {
						return makeAST(EBinary(Match, makeAST(EVar(accVarName)), transformedCase));
					}

					// Non-control-flow context: store the case expression as an update and splice it
					// into the next {:cont/:halt, acc} tuple.
					accUpdates.set(accVarName, transformedCase);

					#if debug_reduce_while_transform
					#end

					return makeAST(EBlock([]));
				} else {
					// Regular case without accumulator assignments
					var transformedBranches = [];
					for (branch in branches) {
						transformedBranches.push({
							pattern: branch.pattern,
							guard: branch.guard,
							body: transformBodyRecursive(branch.body, accVarNames, accUpdates.copy(), false, outerToAccAliases)
						});
					}
					return makeAST(ECase(expr, transformedBranches));
				}

			case EMatch(pattern, value):
				// If an ordinary assignment contains a nested loop on its RHS, still
				// transform that loop. The left side is not an accumulator write, but
				// the nested reducer may have its own accumulator locals to thread.
				return makeAST(EMatch(pattern, transformBodyRecursive(value, accVarNames, accUpdates, preserveAssignments, outerToAccAliases)));

			case EBinary(Match, left, value):
				return makeAST(EBinary(Match, left, transformBodyRecursive(value, accVarNames, accUpdates, preserveAssignments, outerToAccAliases)));

			case ERemoteCall(module, "reduce_while", args) if (isEnumModule(module)):
				return transformReduceWhile(body);

			case EBlock(exprs):
				// Process block expressions
				var transformedExprs = [];
				// IMPORTANT:
				// `accUpdates` is the mutable "thread" used to communicate accumulator updates to
				// enclosing transforms (notably `branchToAccumulatorValue`). Copying here prevents
				// nested transforms from observing updates, which can erase reducer logic by making
				// branches appear to leave the accumulator unchanged.
				var localUpdates = accUpdates;

				for (i in 0...exprs.length) {
					var expr = exprs[i];

					// Check if this is an assignment to an accumulator variable
					switch (expr.def) {
						case EReceiverEffect(effect):
							var accNameEffect = resolveAccumulatorName(effect.receiver.name);
							if (accNameEffect == null || effect.resultShape != UpdatedReceiverAndValue) {
								var transformedEffect = transformBodyRecursive(expr, accVarNames, localUpdates, preserveAssignments, outerToAccAliases);
								if (transformedEffect != null)
									transformedExprs.push(transformedEffect);
								continue;
							}

							switch (effect.operation.def) {
								case ETuple([updatedValue, expressionValue]):
									// Some receiver effects reach this pass before ReceiverEffectLowering
									// has turned them into a match. Handle that semantic node directly,
									// otherwise a loop-local `i++` can update the outer `i` instead of the
									// reducer accumulator `acc_i`.
									var rewrittenUpdatedValue = rewriteAccumulatorVarRefs(updatedValue, effect.receiver.name, accNameEffect);
									localUpdates.set(accNameEffect, rewrittenUpdatedValue);
									if (preserveAssignments) transformedExprs.push(makeAST(EMatch(PVar(accNameEffect), rewrittenUpdatedValue)));
								default:
									var transformedEffect = transformBodyRecursive(expr, accVarNames, localUpdates, preserveAssignments, outerToAccAliases);
									if (transformedEffect != null) transformedExprs.push(transformedEffect);
							}

						case EMatch(PTuple([PVar(varName), PVar(valueName)]), {def: ETuple([updatedValue, expressionValue])}):
							var accNameTuple = resolveAccumulatorName(varName);
							if (accNameTuple == null) {
								var transformedTuple = transformBodyRecursive(expr, accVarNames, localUpdates, preserveAssignments, outerToAccAliases);
								if (transformedTuple != null)
									transformedExprs.push(transformedTuple);
								continue;
							}

							// Haxe postfix mutation in a value expression lowers to:
							//   {outer_var, value_tmp} = {outer_var + 1, outer_var}
							// Inside Enum.reduce_while, `outer_var` is really part of the
							// accumulator tuple. Keep the expression temp as a local binding,
							// and thread the updated value through the reducer accumulator.
							var rewrittenUpdatedValue = rewriteAccumulatorVarRefs(updatedValue, varName, accNameTuple);
							var rewrittenExpressionValue = rewritePostfixValue(expressionValue, varName, accNameTuple);
							localUpdates.set(accNameTuple, rewrittenUpdatedValue);

							transformedExprs.push(makeAST(EMatch(PVar(valueName), rewrittenExpressionValue)));
							if (preserveAssignments) transformedExprs.push(makeAST(EMatch(PVar(accNameTuple), rewrittenUpdatedValue)));

						case EBinary(Match, {def: ETuple([{def: EVar(varName)}, {def: EVar(valueName)}])}, {def: ETuple([updatedValue, expressionValue])}):
							var accNameTuple = resolveAccumulatorName(varName);
							if (accNameTuple == null) {
								var transformedTuple = transformBodyRecursive(expr, accVarNames, localUpdates, preserveAssignments, outerToAccAliases);
								if (transformedTuple != null)
									transformedExprs.push(transformedTuple);
								continue;
							}

							// Some cleanup passes represent the same postfix mutation as a binary
							// match instead of an EMatch pattern. Treat both shapes the same so a
							// loop-local `i++` updates the reducer accumulator, not the outer `i`.
							var rewrittenUpdatedValue = rewriteAccumulatorVarRefs(updatedValue, varName, accNameTuple);
							var rewrittenExpressionValue = rewritePostfixValue(expressionValue, varName, accNameTuple);
							localUpdates.set(accNameTuple, rewrittenUpdatedValue);

							transformedExprs.push(makeAST(EMatch(PVar(valueName), rewrittenExpressionValue)));
							if (preserveAssignments) transformedExprs.push(makeAST(EMatch(PVar(accNameTuple), rewrittenUpdatedValue)));

						case EMatch(PVar(varName), value):
							var accName = resolveAccumulatorName(varName);
							if (accName == null) {
								var transformed = transformBodyRecursive(expr, accVarNames, localUpdates, preserveAssignments, outerToAccAliases);
								if (transformed != null)
									transformedExprs.push(transformed);
								continue;
							}
							// Store the update - we'll use it when we see the return tuple
							var rewrittenValue = rewriteAliasedVarRefs(value);
							localUpdates.set(accName, rewrittenValue);

							#if debug_reduce_while_transform
							#end

							// ⚠️ FIX: If we're preserving assignments (inside main control flow), keep them
							if (preserveAssignments) {
								#if debug_reduce_while_transform
								#end
								transformedExprs.push(makeAST(EMatch(PVar(accName), rewrittenValue)));
							}
						// Otherwise, don't add the assignment to the output (will be merged into return tuple)
						case EBinary(Match, {def: EVar(varName)}, value):
							var accName2 = resolveAccumulatorName(varName);
							if (accName2 == null) {
								var transformed2 = transformBodyRecursive(expr, accVarNames, localUpdates, preserveAssignments, outerToAccAliases);
								if (transformed2 != null)
									transformedExprs.push(transformed2);
								continue;
							}
							var rewrittenValue2 = rewriteAliasedVarRefs(value);
							localUpdates.set(accName2, rewrittenValue2);
							if (preserveAssignments) {
								transformedExprs.push(makeAST(EBinary(Match, makeAST(EVar(accName2)), rewrittenValue2)));
							}

						case ETuple([atom, accTuple]):
							// This is a return statement {:cont, acc} or {:halt, acc}
							switch (atom.def) {
								// OR patterns like "cont" | "halt" don't work with abstract types, use guard clause instead
								case EAtom(atom) if (atom == "cont" || atom == "halt"):
									// Build new accumulator with updates
									// IMPORTANT:
									// When `preserveAssignments` is true, accumulator assignments were kept in the
									// block (to preserve control-flow shapes). In that case the accumulator vars
									// already hold the updated values, and substituting RHS expressions into the
									// return tuple can silently change semantics:
									//   acc_len = acc_len + n
									//   {:cont, {acc_len}}  -- correct
									// would become:
									//   {:cont, {acc_len + n}} -- double-add (incorrect)
									// So only apply RHS-substitution when we *removed* the assignments.
									var newAcc = preserveAssignments ? accTuple : applyAccumulatorUpdates(accTuple, accVarNames, localUpdates);
									transformedExprs.push(makeAST(ETuple([makeAST(EAtom(atom)), newAcc])));

								default:
									transformedExprs.push(expr);
							}

						default:
							// Recursively transform other expressions
							var transformed = transformBodyRecursive(expr, accVarNames, localUpdates, preserveAssignments, outerToAccAliases);
							// Only add non-null results
							if (transformed != null) {
								transformedExprs.push(transformed);
							}
					}
				}

				return makeAST(EBlock(transformedExprs));

			case ETuple([atom, accTuple]):
				// Direct return of {:cont/:halt, accumulator}
				switch (atom.def) {
					// OR patterns like "cont" | "halt" don't work with abstract types, use guard clause instead
					case EAtom(atom) if (atom == "cont" || atom == "halt"):
						// Apply any accumulated updates
						var newAcc = preserveAssignments ? accTuple : applyAccumulatorUpdates(accTuple, accVarNames, accUpdates);
						return makeAST(ETuple([makeAST(EAtom(atom)), newAcc]));
					default:
						return body;
				}

			default:
				// For other patterns, return as-is
				return body;
		}
	}

	static function buildOuterToAccumulatorAliases(initialAcc:ElixirAST, accVarNames:Array<String>):Map<String, String> {
		var out:Map<String, String> = new Map();
		if (initialAcc == null || initialAcc.def == null)
			return out;
		if (accVarNames == null || accVarNames.length == 0)
			return out;

		var elems:Array<ElixirAST> = switch (initialAcc.def) {
			case ETuple(items): items;
			default: [initialAcc];
		};
		if (elems == null || elems.length != accVarNames.length)
			return out;

		for (i in 0...elems.length) {
			var e = elems[i];
			if (e == null || e.def == null)
				continue;
			switch (e.def) {
				case EVar(name):
					var mapped = accVarNames[i];
					if (name != null && mapped != null && name != mapped)
						out.set(name, mapped);
				default:
			}
		}

		return out;
	}

	/**
	 * Apply accumulator updates to the return tuple
	 */
	static function applyAccumulatorUpdates(accTuple:ElixirAST, varNames:Array<String>, updates:Map<String, ElixirAST>):ElixirAST {
		// Check if updates map has any entries
		var hasUpdates = false;
		for (key in updates.keys()) {
			hasUpdates = true;
			break;
		}

		if (!hasUpdates) {
			return accTuple;
		}

		switch (accTuple.def) {
			case ETuple(elements):
				// Update tuple elements
				var newElements = [];
				for (i in 0...elements.length) {
					if (i < varNames.length && updates.exists(varNames[i])) {
						newElements.push(updates.get(varNames[i]));
					} else {
						newElements.push(elements[i]);
					}
				}
				return makeAST(ETuple(newElements));

			case EVar(name) if (updates.exists(name)):
				// Single variable accumulator
				return updates.get(name);

			default:
				return accTuple;
		}
	}

	/**
	 * Build an updated accumulator tuple with new values
	 */
	static function buildUpdatedAccumulator(varNames:Array<String>, updates:Map<String, ElixirAST>):ElixirAST {
		var accValues = [];

		for (varName in varNames) {
			if (updates.exists(varName)) {
				// Use the updated value
				accValues.push(updates.get(varName));
			} else {
				// Use the original variable
				accValues.push(makeAST(EVar(varName)));
			}
		}

		// Handle the simple case of a single variable
		if (accValues.length == 1) {
			return accValues[0];
		}

		// Return as tuple for multiple values
		return makeAST(ETuple(accValues));
	}

	/**
	 * Check if an AST node contains return tuples {:cont/:halt, accumulator}
	 * These indicate the node is part of the lambda's main control flow
	 */
	static function containsReturnTuple(node:ElixirAST):Bool {
		if (node == null)
			return false;

		switch (node.def) {
			case ETuple([atom, _]):
				// Check if this is a {:cont/:halt, acc} tuple
				switch (atom.def) {
					case EAtom(a) if (a == "cont" || a == "halt"):
						return true;
					default:
				}

			case EBlock(exprs):
				// Check if any expression in the block is a return tuple
				for (expr in exprs) {
					if (containsReturnTuple(expr)) {
						return true;
					}
				}

			case EIf(_, thenBranch, elseBranch):
				// Recursively check branches
				if (containsReturnTuple(thenBranch))
					return true;
				if (elseBranch != null && containsReturnTuple(elseBranch))
					return true;

			default:
		}

		return false;
	}

	/**
	 * Check if an AST node represents the Enum module
	 */
	static function isEnumModule(module:ElixirAST):Bool {
		return switch (module.def) {
			case EVar("Enum"): true;
			case EAtom(atom) if (atom == "Elixir.Enum"): true;
			default: false;
		};
	}

	/**
	 * Check if an AST node contains assignments to accumulator variables
	 */
	static function checkForAccumulatorAssignments(node:ElixirAST, accVarNames:Array<String>, outerToAccAliases:Map<String, String>):Bool {
		if (node == null)
			return false;

		switch (node.def) {
			case EMatch(PVar(varName), _):
				if (accVarNames.indexOf(varName) >= 0)
					return true;
				if (outerToAccAliases != null
					&& outerToAccAliases.exists(varName)
					&& accVarNames.indexOf(outerToAccAliases.get(varName)) >= 0)
					return true;
				return false;
			case EBinary(Match, {def: EVar(varName)}, _):
				if (accVarNames.indexOf(varName) >= 0)
					return true;
				if (outerToAccAliases != null
					&& outerToAccAliases.exists(varName)
					&& accVarNames.indexOf(outerToAccAliases.get(varName)) >= 0)
					return true;
				return false;
			case EBlock(exprs):
				for (expr in exprs) {
					if (checkForAccumulatorAssignments(expr, accVarNames, outerToAccAliases)) {
						return true;
					}
				}
				return false;
			case EDo(exprsDo):
				for (exprDo in exprsDo) {
					if (checkForAccumulatorAssignments(exprDo, accVarNames, outerToAccAliases))
						return true;
				}
				return false;
			case EIf(_, thenBranch, elseBranch):
				return checkForAccumulatorAssignments(thenBranch, accVarNames, outerToAccAliases)
					|| (elseBranch != null && checkForAccumulatorAssignments(elseBranch, accVarNames, outerToAccAliases));
			case ECase(_, branches):
				for (branch in branches)
					if (checkForAccumulatorAssignments(branch.body, accVarNames, outerToAccAliases))
						return true;
				return false;
			case ETry(tryBody, rescueClauses, catchClauses, afterBlock, elseBlock):
				if (checkForAccumulatorAssignments(tryBody, accVarNames, outerToAccAliases))
					return true;
				if (rescueClauses != null)
					for (r in rescueClauses)
						if (checkForAccumulatorAssignments(r.body, accVarNames, outerToAccAliases))
							return true;
				if (catchClauses != null)
					for (c in catchClauses)
						if (checkForAccumulatorAssignments(c.body, accVarNames, outerToAccAliases))
							return true;
				if (afterBlock != null && checkForAccumulatorAssignments(afterBlock, accVarNames, outerToAccAliases))
					return true;
				if (elseBlock != null && checkForAccumulatorAssignments(elseBlock, accVarNames, outerToAccAliases))
					return true;
				return false;
			default:
				return false;
		}
	}

	/**
	 * Find which accumulator variable is being assigned in an if statement
	 */
	static function findAccumulatorVarInIf(thenBranch:ElixirAST, elseBranch:ElixirAST, accVarNames:Array<String>,
			outerToAccAliases:Map<String, String>):Null<String> {
		// Check then branch for assignments
		var varName = findAssignedAccumulator(thenBranch, accVarNames, outerToAccAliases);
		if (varName != null)
			return varName;

		// Check else branch if it exists
		if (elseBranch != null) {
			return findAssignedAccumulator(elseBranch, accVarNames, outerToAccAliases);
		}

		return null;
	}

	/**
	 * Find an accumulator variable being assigned in an AST node
	 */
	static function findAssignedAccumulator(node:ElixirAST, accVarNames:Array<String>, outerToAccAliases:Map<String, String>):Null<String> {
		if (node == null)
			return null;

		switch (node.def) {
			case EMatch(PVar(varName), _):
				if (accVarNames.indexOf(varName) >= 0)
					return varName;
				if (outerToAccAliases != null && outerToAccAliases.exists(varName)) {
					var mapped = outerToAccAliases.get(varName);
					if (mapped != null && accVarNames.indexOf(mapped) >= 0)
						return mapped;
				}
				return null;
			case EBinary(Match, {def: EVar(varName)}, _):
				if (accVarNames.indexOf(varName) >= 0)
					return varName;
				if (outerToAccAliases != null && outerToAccAliases.exists(varName)) {
					var mapped2 = outerToAccAliases.get(varName);
					if (mapped2 != null && accVarNames.indexOf(mapped2) >= 0)
						return mapped2;
				}
				return null;
			case EBlock(exprs):
				for (expr in exprs) {
					var result = findAssignedAccumulator(expr, accVarNames, outerToAccAliases);
					if (result != null)
						return result;
				}
				return null;
			case EDo(exprsDo):
				for (exprDo in exprsDo) {
					var resultDo = findAssignedAccumulator(exprDo, accVarNames, outerToAccAliases);
					if (resultDo != null)
						return resultDo;
				}
				return null;
			case EIf(_, thenBranch, elseBranch):
				var inThen = findAssignedAccumulator(thenBranch, accVarNames, outerToAccAliases);
				if (inThen != null)
					return inThen;
				if (elseBranch != null)
					return findAssignedAccumulator(elseBranch, accVarNames, outerToAccAliases);
				return null;
			case ECase(_, branches):
				for (branch in branches) {
					var inBranch = findAssignedAccumulator(branch.body, accVarNames, outerToAccAliases);
					if (inBranch != null)
						return inBranch;
				}
				return null;
			case ETry(tryBody, rescueClauses, catchClauses, afterBlock, elseBlock):
				var inTry = findAssignedAccumulator(tryBody, accVarNames, outerToAccAliases);
				if (inTry != null)
					return inTry;
				if (rescueClauses != null)
					for (r in rescueClauses) {
						var inR = findAssignedAccumulator(r.body, accVarNames, outerToAccAliases);
						if (inR != null)
							return inR;
					}
				if (catchClauses != null)
					for (c in catchClauses) {
						var inC = findAssignedAccumulator(c.body, accVarNames, outerToAccAliases);
						if (inC != null)
							return inC;
					}
				if (afterBlock != null) {
					var inAfter = findAssignedAccumulator(afterBlock, accVarNames, outerToAccAliases);
					if (inAfter != null)
						return inAfter;
				}
				if (elseBlock != null) {
					var inElse = findAssignedAccumulator(elseBlock, accVarNames, outerToAccAliases);
					if (inElse != null)
						return inElse;
				}
				return null;
			default:
				return null;
		}
	}

	/**
	 * Extract the value being assigned from an assignment statement
	 */
	static function extractValueFromAssignment(node:ElixirAST, varName:String):ElixirAST {
		if (node == null)
			return null;

		switch (node.def) {
			case EMatch(PVar(name), value) if (name == varName):
				return value;
			case EBinary(Match, {def: EVar(name)}, value) if (name == varName):
				return value;
			case EBlock(exprs):
				// Preserve any prefix statements required to compute the assigned value.
				// We return a block that evaluates the prefix, then yields the RHS as the
				// final expression (or yields the accumulator var unchanged if no assignment).
				var prefix:Array<ElixirAST> = [];
				for (expr in exprs) {
					switch (expr.def) {
						case EMatch(PVar(name2), value2) if (name2 == varName):
							return makeAST(EBlock(prefix.concat([value2])));
						case EBinary(Match, {def: EVar(name3)}, value3) if (name3 == varName):
							return makeAST(EBlock(prefix.concat([value3])));
						default:
							prefix.push(expr);
					}
				}
				return makeAST(EBlock(prefix.concat([makeAST(EVar(varName))])));
			default:
				return node;
		}
	}
}
