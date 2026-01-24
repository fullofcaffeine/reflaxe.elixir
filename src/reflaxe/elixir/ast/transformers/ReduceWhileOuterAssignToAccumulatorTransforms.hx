package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import haxe.ds.StringMap;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceWhileOuterAssignToAccumulatorTransforms
 *
 * WHAT
 * - Detects `Enum.reduce_while/3` loops whose reducer body assigns to variables that are
 *   bound in the surrounding statement list and referenced afterwards (i.e. attempted
 *   cross-scope mutation).
 * - Rewrites those reduce_while calls to thread the variables through the accumulator tuple,
 *   and rebind the updated values after the reduce_while call.
 *
 * WHY
 * - In Elixir, assignments inside anonymous functions do not mutate outer variables. Patterns like:
 *     buf = BytesBuffer.new()
 *     _ = Enum.reduce_while(..., :ok, fn _, acc ->
 *       buf = %{buf | ...}
 *       {:cont, acc}
 *     end)
 *     buf
 *   leave `buf` unchanged and also trigger `--warnings-as-errors` (“variable is unused (there is a
 *   variable with the same name in the context...)”).
 *
 * HOW
 * - In EBlock/EDo statement lists, track:
 *   - `boundSoFar`: variables bound earlier in the list
 *   - `usedLater`: variables referenced after the current statement (including outer follow-through)
 * - For reduce_while statements whose reducer body assigns to `boundSoFar` variables that are `usedLater`:
 *   - Extend the reduce_while accumulator to include those variables
 *   - Rewrite `{:cont, acc}` / `{:halt, acc}` return tuples to return the extended accumulator
 *   - Bind the final accumulator and rebind the outer variables after the call
 *
 * EXAMPLES
 * Elixir (before):
 *   buf = BytesBuffer.new()
 *   _ = Enum.reduce_while(stream, :ok, fn _, acc ->
 *     buf = %{buf | byte_length: buf.byte_length + 1}
 *     {:cont, acc}
 *   end)
 *   buf
 *
 * Elixir (after):
 *   buf = BytesBuffer.new()
 *   {_, updated_buf} = Enum.reduce_while(stream, {:ok, buf}, fn _, {acc, buf} ->
 *     buf = %{buf | byte_length: buf.byte_length + 1}
 *     {:cont, {acc, buf}}
 *   end)
 *   buf = updated_buf
 *   buf
 */
class ReduceWhileOuterAssignToAccumulatorTransforms {
	public static function pass(ast: ElixirAST): ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
			return switch (n.def) {
				case EBlock(stmts):
					var rewritten = rewriteStatements(stmts);
					makeASTWithMeta(EBlock(rewritten), n.metadata, n.pos);
				case EDo(stmts):
					var rewrittenDo = rewriteStatements(stmts);
					makeASTWithMeta(EDo(rewrittenDo), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function rewriteStatements(stmts: Array<ElixirAST>): Array<ElixirAST> {
		var boundSoFar: StringMap<Bool> = new StringMap();
		return rewriteStatementsWithContext(stmts, boundSoFar, []);
	}

	static function rewriteStatementsWithContext(
		stmts: Array<ElixirAST>,
		boundSoFar: StringMap<Bool>,
		followStmts: Array<ElixirAST>
	): Array<ElixirAST> {
		if (stmts == null || stmts.length == 0) return stmts;

		var out: Array<ElixirAST> = [];

		for (index in 0...stmts.length) {
			var stmt = stmts[index];

			// Nested statement-position blocks are scope-transparent; process with the same sequential context.
			switch (stmt.def) {
				case EBlock(innerStmts):
					var innerFollow = stmts.slice(index + 1).concat(followStmts);
					var rewrittenInner = rewriteStatementsWithContext(innerStmts, boundSoFar, innerFollow);
					var rewrittenStmt = makeASTWithMeta(EBlock(rewrittenInner), stmt.metadata, stmt.pos);
					out.push(rewrittenStmt);
					continue;
				case EDo(innerDoStmts):
					var innerFollowDo = stmts.slice(index + 1).concat(followStmts);
					var rewrittenInnerDo = rewriteStatementsWithContext(innerDoStmts, boundSoFar, innerFollowDo);
					var rewrittenStmtDo = makeASTWithMeta(EDo(rewrittenInnerDo), stmt.metadata, stmt.pos);
					out.push(rewrittenStmtDo);
					continue;
				default:
			}

			var reduceInfo = extractEnumReduceWhileStatement(stmt);
			if (reduceInfo == null) {
				out.push(stmt);
				bindFromStatement(stmt, boundSoFar);
				continue;
			}

			var reduceCall = reduceInfo.reduceCall;
			var args = reduceInfo.args;
			if (args == null || args.length < 3) {
				out.push(stmt);
				bindFromStatement(stmt, boundSoFar);
				continue;
			}

			var collectionExpr = args[0];
			var initialAccExpr = args[1];
			var fnArg = args[2];

			var fnClause = extractSingleClauseFn(fnArg);
			if (fnClause == null) {
				out.push(stmt);
				bindFromStatement(stmt, boundSoFar);
				continue;
			}

			var follow = stmts.slice(index + 1).concat(followStmts);

			// Collect assignment binders inside the reducer body that correspond to already-bound outer vars.
			var assignedNames = collectAssignedNames(fnClause.body);
			var outerAssignedAndUsedLater: Array<String> = [];
			for (name in assignedNames) {
				if (!boundSoFar.exists(name)) continue;
				if (!anyStatementUsesVar(follow, name)) continue;
				outerAssignedAndUsedLater.push(name);
			}

			if (outerAssignedAndUsedLater.length == 0) {
				out.push(stmt);
				bindFromStatement(stmt, boundSoFar);
				continue;
			}

			// Only rewrite when the accumulator pattern is something we can extend (var or tuple of vars).
			var oldAccPatternElems = flattenAccPattern(fnClause.accPattern);
			var oldAccExprElems = flattenAccExpr(initialAccExpr);
			if (oldAccPatternElems == null || oldAccExprElems == null) {
				out.push(stmt);
				bindFromStatement(stmt, boundSoFar);
				continue;
			}
			if (!allPatternVars(oldAccPatternElems)) {
				out.push(stmt);
				bindFromStatement(stmt, boundSoFar);
				continue;
			}

			// Avoid duplicating vars already in the accumulator.
			var existingAccVarNames = collectAccVarNames(oldAccPatternElems);
			var extraVarNames: Array<String> = [];
			for (name in outerAssignedAndUsedLater) {
				if (!existingAccVarNames.exists(name)) extraVarNames.push(name);
			}
			if (extraVarNames.length == 0) {
				out.push(stmt);
				bindFromStatement(stmt, boundSoFar);
				continue;
			}

			var newAccPatternElems: Array<EPattern> = oldAccPatternElems.concat([for (name in extraVarNames) PVar(name)]);
			var newAccExprElems: Array<ElixirAST> = oldAccExprElems.concat([for (name in extraVarNames) makeAST(EVar(name))]);

			var newAccPattern: EPattern = PTuple(newAccPatternElems);
			var newInitialAcc = makeAST(ETuple(newAccExprElems));

			var newReturnAccExpr = makeAST(ETuple([for (name in (collectPatternVarNames(newAccPatternElems))) makeAST(EVar(name))]));
			var rewrittenBody = rewriteReturnTuples(
				fnClause.body,
				oldAccPatternElems,
				newReturnAccExpr
			);

			var newFn = makeAST(EFn([{
				args: [fnClause.binderPattern, newAccPattern],
				guard: null,
				body: rewrittenBody
			}]));

			var newReduceCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce_while", [
				collectionExpr,
				newInitialAcc,
				newFn
			]));

			// Bind the final accumulator and rebind outer vars from the returned tuple.
			var usedNames: StringMap<Bool> = new StringMap();
			for (k in boundSoFar.keys()) usedNames.set(k, true);
			for (name in extraVarNames) usedNames.set(name, true);

			var tempNames: Array<String> = [];
			for (name in extraVarNames) {
				var temp = freshTempName(name, usedNames);
				usedNames.set(temp, true);
				tempNames.push(temp);
			}

			var resultPatternElems: Array<EPattern> = [];
			for (_ in 0...oldAccExprElems.length) resultPatternElems.push(PWildcard);
			for (temp in tempNames) resultPatternElems.push(PVar(temp));

			var bindResult = makeAST(EMatch(PTuple(resultPatternElems), newReduceCall));
			out.push(bindResult);
			bindFromStatement(bindResult, boundSoFar);
			for (i in 0...extraVarNames.length) {
				var rebind = makeAST(EMatch(PVar(extraVarNames[i]), makeAST(EVar(tempNames[i]))));
				out.push(rebind);
				bindFromStatement(rebind, boundSoFar);
			}
		}

		return out;
	}

	private static function extractEnumReduceWhileStatement(stmt: ElixirAST): Null<{ reduceCall: ElixirAST, args: Array<ElixirAST> }> {
		if (stmt == null || stmt.def == null) return null;
		var direct = extractEnumReduceWhileCall(stmt);
		if (direct != null) return direct;

		return switch (stmt.def) {
			case EMatch(PVar("_"), rhs):
				extractEnumReduceWhileCall(rhs);
			case EMatch(PWildcard, rhs):
				extractEnumReduceWhileCall(rhs);
			case EBinary(Match, left, rhs):
				switch (unwrapParen(left).def) {
					case EVar("_"):
						extractEnumReduceWhileCall(rhs);
					default:
						null;
				}
			default:
				null;
		};
	}

	private static function extractEnumReduceWhileCall(expr: ElixirAST): Null<{ reduceCall: ElixirAST, args: Array<ElixirAST> }> {
		if (expr == null || expr.def == null) return null;
		return switch (expr.def) {
			case ERemoteCall({ def: EVar("Enum") }, "reduce_while", args):
				{ reduceCall: expr, args: args };
			case ECall({ def: EVar("Enum") }, "reduce_while", args):
				{ reduceCall: expr, args: args };
			default:
				null;
		};
	}

	private static function extractSingleClauseFn(fnNode: ElixirAST): Null<{ binderPattern: EPattern, accPattern: EPattern, body: ElixirAST }> {
		if (fnNode == null || fnNode.def == null) return null;
		return switch (fnNode.def) {
			case EFn(clauses) if (clauses != null && clauses.length == 1):
				var clause = clauses[0];
				if (clause.args == null || clause.args.length != 2) return null;
				{
					binderPattern: clause.args[0],
					accPattern: clause.args[1],
					body: clause.body
				};
			default:
				null;
		};
	}

	private static function collectAssignedNames(expr: ElixirAST): Array<String> {
		var out: Array<String> = [];
		var seen: StringMap<Bool> = new StringMap();

		ElixirASTTransformer.transformAST(expr, function(n: ElixirAST): ElixirAST {
			if (n == null || n.def == null) return n;
			switch (n.def) {
				case EFn(_):
					// Nested closures do not contribute assignments to the outer reducer.
					return n;
				case EMatch(PVar(name), _):
					if (name != null && name.length > 0 && !seen.exists(name) && name.charAt(0) != '_') {
						seen.set(name, true);
						out.push(name);
					}
				case EBinary(Match, left, _):
					switch (unwrapParen(left).def) {
						case EVar(name):
							if (name != null && name.length > 0 && !seen.exists(name) && name.charAt(0) != '_') {
								seen.set(name, true);
								out.push(name);
							}
						default:
					}
				default:
			}
			return n;
		});

		return out;
	}

	private static function flattenAccPattern(p: EPattern): Null<Array<EPattern>> {
		if (p == null) return null;
		return switch (p) {
			case PTuple(items): items;
			case PVar(_): [p];
			default: null;
		};
	}

	private static function flattenAccExpr(e: ElixirAST): Null<Array<ElixirAST>> {
		if (e == null || e.def == null) return null;
		return switch (e.def) {
			case ETuple(items): items;
			default: [e];
		};
	}

	private static function collectAccVarNames(patternElems: Array<EPattern>): StringMap<Bool> {
		var out: StringMap<Bool> = new StringMap();
		for (p in patternElems) {
			switch (p) {
				case PVar(name):
					out.set(name, true);
				default:
			}
		}
		return out;
	}

	private static function allPatternVars(patternElems: Array<EPattern>): Bool {
		for (p in patternElems) {
			switch (p) {
				case PVar(_):
				default:
					return false;
			}
		}
		return true;
	}

	private static function collectPatternVarNames(patternElems: Array<EPattern>): Array<String> {
		var out: Array<String> = [];
		for (p in patternElems) {
			switch (p) {
				case PVar(name): out.push(name);
				default:
			}
		}
		return out;
	}

	private static function isOldAccumulatorExpr(accExpr: ElixirAST, oldAccPatternElems: Array<EPattern>): Bool {
		if (accExpr == null || accExpr.def == null) return false;
		var oldNames = collectPatternVarNames(oldAccPatternElems);

		return switch (accExpr.def) {
			case EVar(name):
				oldNames.length == 1 && oldNames[0] == name;
			case ETuple(elems):
				if (elems == null || elems.length != oldNames.length) return false;
				for (i in 0...elems.length) {
					switch (elems[i].def) {
						case EVar(n) if (n == oldNames[i]):
						default:
							return false;
					}
				}
				true;
			default:
				false;
		};
	}

	private static function rewriteReturnTuples(body: ElixirAST, oldAccPatternElems: Array<EPattern>, newAccExpr: ElixirAST): ElixirAST {
		return ElixirASTTransformer.transformAST(body, function(n: ElixirAST): ElixirAST {
			if (n == null || n.def == null) return n;
			return switch (n.def) {
				case ETuple([tag, acc]):
					var isContOrHalt = switch (tag.def) {
						case EAtom(a):
							var s: String = a;
							s == "cont" || s == "halt";
						default:
							false;
					};
					if (!isContOrHalt || !isOldAccumulatorExpr(acc, oldAccPatternElems)) n;
					else makeAST(ETuple([tag, newAccExpr]));
				case EFn(_):
					// Do not rewrite nested closures.
					n;
				default:
					n;
			};
		});
	}

	private static function freshTempName(baseName: String, used: StringMap<Bool>): String {
		var candidates = [
			"updated_" + baseName,
			baseName + "_updated",
			baseName + "_after",
			"updated_" + baseName + "_value",
			"updated_" + baseName + "_tmp"
		];
		for (c in candidates) if (!used.exists(c)) return c;
		// Fall back to a stable prefix; avoid numeric suffixes.
		var fallback = "reflaxe_updated_" + baseName;
		if (!used.exists(fallback)) return fallback;
		return "reflaxe_updated_" + baseName + "_value";
	}

	private static function unwrapParen(e: ElixirAST): ElixirAST {
		return switch (e.def) {
			case EParen(inner): unwrapParen(inner);
			default: e;
		};
	}

	private static function bindFromStatement(stmt: ElixirAST, out: StringMap<Bool>): Void {
		if (stmt == null || stmt.def == null) return;
		switch (stmt.def) {
			case EMatch(PVar(name), _):
				out.set(name, true);
			case EBinary(Match, left, _):
				switch (unwrapParen(left).def) {
					case EVar(varName): out.set(varName, true);
					default:
				}
			default:
		}
	}

	private static function anyStatementUsesVar(stmts: Array<ElixirAST>, name: String): Bool {
		if (stmts == null || stmts.length == 0) return false;
		for (s in stmts) if (exprUsesVar(s, name)) return true;
		return false;
	}

	private static function exprUsesVar(expr: ElixirAST, name: String): Bool {
		if (expr == null || expr.def == null) return false;
		var found = false;

		function visit(e: ElixirAST): Void {
			if (found || e == null || e.def == null) return;

			switch (e.def) {
				case EVar(v) if (v == name):
					found = true;
					return;
				case EFn(_):
					return;
				case EBinary(Match, _left, rhs):
					visit(rhs);
				case EMatch(_pat, rhs):
					visit(rhs);
				default:
			}

			ElixirASTTransformer.transformAST(e, function(child: ElixirAST) {
				visit(child);
				return child;
			});
		}

		visit(expr);
		return found;
	}
}

#end
