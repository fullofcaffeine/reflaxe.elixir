package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
#if debug_map_keys_reduce_while
import reflaxe.elixir.ast.ElixirASTPrinter;
#end

/**
 * MapKeysIteratorReduceWhileRewriteTransforms
 *
 * WHAT
 * - Rewrites the "iterator-driven" reduce_while lowering used for `for (k in map.keys())`
 *   into a direct `Enum.reduce_while(Map.keys(map), ...)` over the keys list.
 *
 * WHY
 * - `Map.keys/1` returns a list in Elixir. Driving it via `has_next/next` closures is invalid
 *   and causes runtime failures. It also produces brittle patterns that are hard for later
 *   transforms to optimize and frequently triggers `--warnings-as-errors` in examples.
 *
 * HOW
 * - Inside EBlock/EDo statement lists, detect the pair:
 *   1) `iter = Map.keys(map)` (or `iter = _ = Map.keys(map)`)
 *   2) `Enum.reduce_while(Stream.iterate(...), acc, fn _, acc -> try do if iter.has_next.() do iter = iter.next.(); ... {:cont, acc} else {:halt, acc} end catch ... end end)`
 * - Replace it with:
 *   `Enum.reduce_while(Map.keys(map), acc, fn iter, acc -> <then-branch-without-next> end)`
 * - When the reduce_while result is used only via an outer accumulator variable, rebind
 *   `{outer} = Enum.reduce_while(...)` so the mutation survives.
 *
 * ORDERING
 * - This pass must run after late match-chain normalization (notably `MatchBlockRhsExtractLast_Final`)
 *   so `Map.keys(map)` appears in a stable assignment shape (`iter = _ = Map.keys(map)`), rather than
 *   being buried in a nested statement block. See `CollectionsAndLoops` registry for the ordering.
 *
 * EXAMPLES
 * Elixir (before):
 *   key = Map.keys(m)
 *   _ = Enum.reduce_while(Stream.iterate(0, ...), :ok, fn _, acc ->
 *     if key.has_next.() do
 *       key = key.next.()
 *       do_stuff(key)
 *       {:cont, acc}
 *     else
 *       {:halt, acc}
 *     end
 *   end)
 * Elixir (after):
 *   _ = Enum.reduce_while(Map.keys(m), :ok, fn key, acc ->
 *     do_stuff(key)
 *     {:cont, acc}
 *   end)
 */
class MapKeysIteratorReduceWhileRewriteTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EBlock(stmts):
					var rewritten = rewriteStatementList(stmts);
					rewritten == stmts ? n : makeASTWithMeta(EBlock(rewritten), n.metadata, n.pos);
				case EDo(stmts):
					var rewrittenDo = rewriteStatementList(stmts);
					rewrittenDo == stmts ? n : makeASTWithMeta(EDo(rewrittenDo), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static inline function isModuleName(mod:ElixirAST, name:String):Bool {
		if (mod == null || mod.def == null)
			return false;
		return switch (mod.def) {
			case EVar(n): n == name;
			case EAtom(a):
				var s:String = a;
				s == name;
			default:
				false;
		};
	}

	static function rewriteStatementList(stmts:Array<ElixirAST>):Array<ElixirAST> {
		if (stmts == null || stmts.length < 2)
			return stmts;

		var out:Array<ElixirAST> = [];
		var i = 0;

		while (i < stmts.length) {
			#if debug_map_keys_reduce_while
			var printedStmt = ElixirASTPrinter.print(stmts[i], 0);
			if (printedStmt != null && printedStmt.indexOf("has_next") != -1 && printedStmt.indexOf("Stream.iterate") != -1) {
				var escapedStmt = printedStmt.split("\n").join("\\n");
				#if sys
				Sys.println('[MapKeysReduceWhile] candidate stmt: ' + escapedStmt);
				#else
				trace('[MapKeysReduceWhile] candidate stmt: ' + escapedStmt);
				#end
			}
			if (printedStmt != null && printedStmt.indexOf("Map.keys") != -1 && i + 1 < stmts.length) {
				var nextPrinted = ElixirASTPrinter.print(stmts[i + 1], 0);
				var escapedSelf = printedStmt.split("\n").join("\\n");
				var escapedNext = nextPrinted != null ? nextPrinted.split("\n").join("\\n") : "<null>";
				#if sys
				Sys.println('[MapKeysReduceWhile] stmt has Map.keys; next=' + escapedNext);
				Sys.println('[MapKeysReduceWhile] stmt=' + escapedSelf);
				#else
				trace('[MapKeysReduceWhile] stmt has Map.keys; next=' + escapedNext);
				trace('[MapKeysReduceWhile] stmt=' + escapedSelf);
				#end
			}
			#end

			// Nested-block variant:
			// Some passes temporarily wrap multiple sequential statements into an EBlock statement.
			// When that block ends with `_ = Map.keys(...)` and the *next* statement is the iterator-driven
			// reduce_while, we can still do the rewrite by hoisting the Map.keys expression out of the block.
			var nestedTail = extractTrailingMapKeysDiscardFromStmtBlock(stmts[i]);
			if (nestedTail != null && i + 1 < stmts.length) {
				var reduceAny0 = extractIteratorReduceWhileAnyIter(stmts[i + 1]);
				if (reduceAny0 != null) {
					var newFnNested = makeAST(EFn([
						{
							args: [PVar(reduceAny0.iterVar), reduceAny0.accPattern],
							guard: null,
							body: reduceAny0.thenBody
						}
					]));
					var newReduceNested = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce_while",
						[nestedTail.keysExpr, reduceAny0.initialAcc, newFnNested]));

					var trimmedBlockStmt = nestedTail.rebuildWithoutKeysDiscard();
					if (trimmedBlockStmt != null)
						out.push(trimmedBlockStmt);

					out.push(rebuildWrapper(stmts[i + 1], newReduceNested, reduceAny0.maybeOuterTupleBind));
					i += 2;
					continue;
				}
			}

			// Nested-block variant (init assignment):
			// Some lowering sequences wrap iterator initialization in a nested block statement, e.g.:
			//   (begin) this1 = assigns.online_users; presence_key = _ = Map.keys(this1) (end)
			//   Enum.reduce_while(Stream.iterate(...), ...)
			//
			// In that shape the init isn't a top-level statement, so hoist it here.
			var nestedInit = extractTrailingMapKeysInitFromStmtBlock(stmts[i]);
			if (nestedInit != null && i + 1 < stmts.length) {
				var reduce0 = extractIteratorReduceWhile(stmts[i + 1], nestedInit.iterVar);
				if (reduce0 != null) {
					var newFn0 = makeAST(EFn([
						{
							args: [PVar(nestedInit.iterVar), reduce0.accPattern],
							guard: null,
							body: reduce0.thenBody
						}
					]));
					var newReduce0 = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce_while", [nestedInit.keysExpr, reduce0.initialAcc, newFn0]));

					var trimmedBlockStmt0 = nestedInit.rebuildWithoutKeysInit();
					if (trimmedBlockStmt0 != null)
						out.push(trimmedBlockStmt0);

					out.push(rebuildWrapper(stmts[i + 1], newReduce0, reduce0.maybeOuterTupleBind));
					i += 2;
					continue;
				}
			}

			var init = extractMapKeysInit(stmts[i]);
			if (init != null && i + 1 < stmts.length) {
				var reduce = extractIteratorReduceWhile(stmts[i + 1], init.iterVar);
				if (reduce != null) {
					#if debug_map_keys_reduce_while
					#if sys
					Sys.println('[MapKeysReduceWhile] rewrite via init iterVar=' + init.iterVar);
					#else
					trace('[MapKeysReduceWhile] rewrite via init iterVar=' + init.iterVar);
					#end
					#end
					// Build new reduce_while over Map.keys(mapExpr)
					var newFn = makeAST(EFn([
						{
							args: [PVar(init.iterVar), reduce.accPattern],
							guard: null,
							body: reduce.thenBody
						}
					]));
					var newReduceCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce_while", [init.keysExpr, reduce.initialAcc, newFn]));

					var wrappedStmt = rebuildWrapper(stmts[i + 1], newReduceCall, reduce.maybeOuterTupleBind);
					out.push(wrappedStmt);
					i += 2;
					continue;
				}
			}

			// Variant: `_ = Map.keys(map)` directly followed by the iterator-driven reduce_while.
			// This shape can appear transiently while other hygiene/assignment passes are still
			// normalizing chained matches. We still want to rewrite the reduce_while to iterate
			// directly over the keys list and drop the now-redundant discard.
			var keysDiscard = extractMapKeysDiscard(stmts[i]);
			if (keysDiscard != null && i + 1 < stmts.length) {
				var reduceAny = extractIteratorReduceWhileAnyIter(stmts[i + 1]);
				if (reduceAny != null) {
					#if debug_map_keys_reduce_while
					#if sys
					Sys.println('[MapKeysReduceWhile] rewrite via discard iterVar=' + reduceAny.iterVar);
					#else
					trace('[MapKeysReduceWhile] rewrite via discard iterVar=' + reduceAny.iterVar);
					#end
					#end
					var newFn2 = makeAST(EFn([
						{
							args: [PVar(reduceAny.iterVar), reduceAny.accPattern],
							guard: null,
							body: reduceAny.thenBody
						}
					]));
					var newReduceCall2 = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce_while", [keysDiscard, reduceAny.initialAcc, newFn2]));

					var wrappedStmt2 = rebuildWrapper(stmts[i + 1], newReduceCall2, reduceAny.maybeOuterTupleBind);
					out.push(wrappedStmt2);
					i += 2;
					continue;
				}
			}

			out.push(stmts[i]);
			i++;
		}

		return out;
	}

	private static function rebuildWrapper(originalStmt:ElixirAST, rewrittenReduce:ElixirAST, outerTupleBind:Null<EPattern>):ElixirAST {
		// Preserve `_ = ...` wrappers for call statements to keep surrounding shapes stable.
		if (outerTupleBind != null) {
			return makeASTWithMeta(EMatch(outerTupleBind, rewrittenReduce), originalStmt.metadata, originalStmt.pos);
		}
		return switch (originalStmt.def) {
			case EMatch(PWildcard, _):
				makeASTWithMeta(EMatch(PWildcard, rewrittenReduce), originalStmt.metadata, originalStmt.pos);
			case EMatch(PVar("_"), _):
				makeASTWithMeta(EMatch(PVar("_"), rewrittenReduce), originalStmt.metadata, originalStmt.pos);
			case EMatch(pat, _):
				makeASTWithMeta(EMatch(pat, rewrittenReduce), originalStmt.metadata, originalStmt.pos);
			case EBinary(Match, left, _):
				switch (left.def) {
					case EVar("_"):
						makeASTWithMeta(EBinary(Match, left, rewrittenReduce), originalStmt.metadata, originalStmt.pos);
					default:
						makeASTWithMeta(EBinary(Match, left, rewrittenReduce), originalStmt.metadata, originalStmt.pos);
				}
			default:
				// Bare reduce_while call statement.
				makeASTWithMeta(rewrittenReduce.def, originalStmt.metadata, originalStmt.pos);
		};
	}

	private static function extractMapKeysInit(stmt:ElixirAST):Null<{iterVar:String, keysExpr:ElixirAST}> {
		if (stmt == null || stmt.def == null)
			return null;

		var lhs:Null<String> = null;
		var rhs:Null<ElixirAST> = null;

		switch (stmt.def) {
			case EMatch(PVar(name), value):
				lhs = name;
				rhs = value;
			case EBinary(Match, left, value):
				switch (left.def) {
					case EVar(varName):
						lhs = varName;
						rhs = value;
					default:
				}
			default:
		}

		if (lhs == null || rhs == null)
			return null;

		// Unwrap `iter = _ = Map.keys(m)`
		var keysCandidate = unwrapNestedDiscard(unwrapParen(rhs));
		if (isMapKeysCall(keysCandidate)) {
			return {iterVar: lhs, keysExpr: keysCandidate};
		}
		return null;
	}

	private static function extractMapKeysDiscard(stmt:ElixirAST):Null<ElixirAST> {
		if (stmt == null || stmt.def == null)
			return null;
		return switch (stmt.def) {
			case EMatch(PWildcard, rhs):
				var candidate = unwrapNestedDiscard(unwrapParen(rhs));
				isMapKeysCall(candidate) ? candidate : null;
			case EBinary(Match, left, rhs):
				switch (left.def) {
					case EVar("_") | EUnderscore:
						var candidate2 = unwrapNestedDiscard(unwrapParen(rhs));
						isMapKeysCall(candidate2) ? candidate2 : null;
					default:
						null;
				}
			default:
				null;
		};
	}

	private static function extractTrailingMapKeysDiscardFromStmtBlock(stmt:ElixirAST):Null<{
		keysExpr:ElixirAST,
		rebuildWithoutKeysDiscard:Void->Null<ElixirAST>
	}> {
		if (stmt == null || stmt.def == null)
			return null;

		function mk(blockKind:String, inner:Array<ElixirAST>):Null<{
			keysExpr:ElixirAST,
			rebuildWithoutKeysDiscard:Void->Null<ElixirAST>
		}> {
			if (inner == null || inner.length == 0)
				return null;
			var last = inner[inner.length - 1];
			var keysExpr = extractMapKeysDiscard(last);
			if (keysExpr == null)
				return null;
			var prefix = inner.slice(0, inner.length - 1);
			return {
				keysExpr: keysExpr,
				rebuildWithoutKeysDiscard: function() {
					if (prefix.length == 0)
						return null;
					return switch (blockKind) {
						case "block":
							makeASTWithMeta(EBlock(prefix), stmt.metadata, stmt.pos);
						case "do":
							makeASTWithMeta(EDo(prefix), stmt.metadata, stmt.pos);
						default:
							makeASTWithMeta(EBlock(prefix), stmt.metadata, stmt.pos);
					};
				}
			};
		}

		return switch (stmt.def) {
			case EBlock(inner):
				mk("block", inner);
			case EDo(innerDo):
				mk("do", innerDo);
			default:
				null;
		};
	}

	private static function extractTrailingMapKeysInitFromStmtBlock(stmt:ElixirAST):Null<{
		iterVar:String,
		keysExpr:ElixirAST,
		rebuildWithoutKeysInit:Void->Null<ElixirAST>
	}> {
		if (stmt == null || stmt.def == null)
			return null;

		function mk(blockKind:String, inner:Array<ElixirAST>):Null<{
			iterVar:String,
			keysExpr:ElixirAST,
			rebuildWithoutKeysInit:Void->Null<ElixirAST>
		}> {
			if (inner == null || inner.length == 0)
				return null;
			var last = inner[inner.length - 1];
			var init = extractMapKeysInit(last);
			if (init == null)
				return null;
			var prefix = inner.slice(0, inner.length - 1);
			return {
				iterVar: init.iterVar,
				keysExpr: init.keysExpr,
				rebuildWithoutKeysInit: function() {
					if (prefix.length == 0)
						return null;
					return switch (blockKind) {
						case "block":
							makeASTWithMeta(EBlock(prefix), stmt.metadata, stmt.pos);
						case "do":
							makeASTWithMeta(EDo(prefix), stmt.metadata, stmt.pos);
						default:
							makeASTWithMeta(EBlock(prefix), stmt.metadata, stmt.pos);
					};
				}
			};
		}

		return switch (stmt.def) {
			case EBlock(inner):
				mk("block", inner);
			case EDo(innerDo):
				mk("do", innerDo);
			default:
				null;
		};
	}

	private static function unwrapNestedDiscard(expr:ElixirAST):ElixirAST {
		if (expr == null || expr.def == null)
			return expr;
		var unwrapped = unwrapParen(expr);
		return switch (unwrapped.def) {
			case EParen(inner):
				unwrapNestedDiscard(inner);
			case EBinary(Match, left, rhs):
				switch (left.def) {
					case EVar("_") | EUnderscore: rhs;
					default: unwrapped;
				}
			case EMatch(PWildcard, rhs):
				rhs;
			case EMatch(PVar("_"), rhs):
				rhs;
			default:
				unwrapped;
		};
	}

	private static function isMapKeysCall(expr:ElixirAST):Bool {
		if (expr == null || expr.def == null)
			return false;
		return switch (expr.def) {
			// NOTE: Some ultra-late passes temporarily downcase remote-call module names (e.g. `map.keys/1`)
			// and normalize them back to aliases (e.g. `Map.keys/1`) at the absolute end.
			// Accept both spellings here so this rewrite can run before the final alias-normalization sweep.
			case ERemoteCall(mod, "keys", args) if (args != null
				&& args.length == 1
				&& (isModuleName(mod, "Map") || isModuleName(mod, "map"))):
				true;
			case ECall(target, "keys", args)
				if (target != null && args != null && args.length == 1 && (isModuleName(target, "Map") || isModuleName(target, "map"))):
				true;
			default:
				false;
		};
	}

	private static function extractIteratorReduceWhile(stmt:ElixirAST, iterVar:String):Null<{
		initialAcc:ElixirAST,
		accPattern:EPattern,
		thenBody:ElixirAST,
		maybeOuterTupleBind:Null<EPattern>
	}> {
		if (stmt == null || stmt.def == null)
			return null;

		var callNode:Null<ElixirAST> = null;
		// Unwrap common wrappers: `_ = Enum.reduce_while(...)` or bare call.
		switch (stmt.def) {
			case EMatch(pat, rhs):
				callNode = rhs;
			case EBinary(Match, left, rhs):
				switch (left.def) {
					case EVar("_") | EUnderscore: callNode = rhs;
					default: callNode = stmt;
				}
			default:
				callNode = stmt;
		}

		if (callNode == null || callNode.def == null)
			return null;
		// Some passes wrap statements in parens or single-statement blocks.
		callNode = unwrapSingleStatementBlock(callNode);

		// Expect Enum.reduce_while(Stream.iterate(...), acc, fn _, accPat -> try do if iter.has_next.() do ... end catch ... end end)
		var initialAcc:Null<ElixirAST> = null;
		var fnNode:Null<ElixirAST> = null;

		switch (unwrapParen(callNode).def) {
			case ERemoteCall(mod, "reduce_while", args) if (isEnum(mod) && args != null && args.length == 3):
				if (!isStreamIterate(args[0]))
					return null;
				initialAcc = args[1];
				fnNode = args[2];
			case ECall(target, "reduce_while", args) if (target != null && isEnum(target) && args != null && args.length == 3):
				if (!isStreamIterate(args[0]))
					return null;
				initialAcc = args[1];
				fnNode = args[2];
			default:
				return null;
		}

		fnNode = fnNode != null ? unwrapSingleStatementBlock(fnNode) : fnNode;

		var accPattern:Null<EPattern> = null;
		var thenBody:Null<ElixirAST> = null;

		switch (fnNode.def) {
			case EFn(clauses) if (clauses != null && clauses.length == 1):
				var clause = clauses[0];
				if (clause.args == null || clause.args.length != 2)
					return null;
				accPattern = clause.args[1];

				var extracted = extractTryIfThenBody(clause.body, iterVar);
				if (extracted == null)
					return null;
				thenBody = extracted;
			default:
				return null;
		}

		// If the reduce_while call is used as a bare statement and initialAcc is `{outer}`,
		// bind it so mutations persist: `{outer} = Enum.reduce_while(...)`.
		var outerTupleBind:Null<EPattern> = null;
		var wrapperIsDiscard = switch (stmt.def) {
			case EMatch(pattern, _):
				switch (pattern) {
					case PWildcard | PVar("_"): true;
					default: false;
				}
			case EBinary(Match, left, _):
				switch (left.def) {
					case EVar("_") | EUnderscore: true;
					default: false;
				}
			default:
				false;
		};
		var isWrapped = switch (stmt.def) {
			case EMatch(_, _) | EBinary(Match, _, _): true;
			default: false;
		};
		// Bind when the reduce_while is a bare statement *or* wrapped in a discard assignment.
		if (!isWrapped || wrapperIsDiscard)
			outerTupleBind = extractSingleVarTuplePattern(initialAcc);

		return {
			initialAcc: initialAcc,
			accPattern: accPattern,
			thenBody: thenBody,
			maybeOuterTupleBind: outerTupleBind
		};
	}

	private static function extractSingleVarTuplePattern(initialAcc:ElixirAST):Null<EPattern> {
		if (initialAcc == null || initialAcc.def == null)
			return null;
		return switch (initialAcc.def) {
			case ETuple([{def: EVar(name)}]):
				PTuple([PVar(name)]);
			default:
				null;
		};
	}

	private static function extractTryIfThenBody(body:ElixirAST, iterVar:String):Null<ElixirAST> {
		if (body == null || body.def == null)
			return null;

		// Expect: try do if iter.has_next.() do <then> else <else> end catch ... end
		var root = unwrapSingleStatementBlock(body);
		switch (root.def) {
			case ETry(tryBody, rescue, catchClauses, afterBlock, elseBlock):
				var inner = unwrapSingleStatementBlock(tryBody);
				switch (inner.def) {
					case EIf(cond, thenBranch, _elseBranch):
						if (!isHasNextCall(cond, iterVar))
							return null;
						var cleanedThen = dropLeadingNextAdvance(thenBranch, iterVar);
						return makeAST(ETry(cleanedThen, rescue, catchClauses, afterBlock, elseBlock));
					default:
						return null;
				}
			default:
				return null;
		}
	}

	private static function extractIteratorReduceWhileAnyIter(stmt:ElixirAST):Null<{
		iterVar:String,
		initialAcc:ElixirAST,
		accPattern:EPattern,
		thenBody:ElixirAST,
		maybeOuterTupleBind:Null<EPattern>
	}> {
		if (stmt == null || stmt.def == null)
			return null;

		var callNode:Null<ElixirAST> = null;
		switch (stmt.def) {
			case EMatch(_, rhs):
				callNode = rhs;
			case EBinary(Match, left, rhs):
				switch (left.def) {
					case EVar("_") | EUnderscore: callNode = rhs;
					default: callNode = stmt;
				}
			default:
				callNode = stmt;
		}

		if (callNode == null || callNode.def == null)
			return null;
		callNode = unwrapSingleStatementBlock(callNode);

		var initialAcc:Null<ElixirAST> = null;
		var fnNode:Null<ElixirAST> = null;
		switch (unwrapParen(callNode).def) {
			case ERemoteCall(mod, "reduce_while", args) if (isEnum(mod) && args != null && args.length == 3):
				if (!isStreamIterate(args[0]))
					return null;
				initialAcc = args[1];
				fnNode = args[2];
			case ECall(target, "reduce_while", args) if (target != null && isEnum(target) && args != null && args.length == 3):
				if (!isStreamIterate(args[0]))
					return null;
				initialAcc = args[1];
				fnNode = args[2];
			default:
				return null;
		}

		fnNode = fnNode != null ? unwrapSingleStatementBlock(fnNode) : fnNode;

		var accPattern:Null<EPattern> = null;
		var thenBody:Null<ElixirAST> = null;
		var iterVar:Null<String> = null;

		switch (fnNode.def) {
			case EFn(clauses) if (clauses != null && clauses.length == 1):
				var clause = clauses[0];
				if (clause.args == null || clause.args.length != 2)
					return null;
				accPattern = clause.args[1];

				var extracted = extractTryIfThenBodyAnyIter(clause.body);
				if (extracted == null)
					return null;
				iterVar = extracted.iterVar;
				thenBody = extracted.thenBody;
			default:
				return null;
		}

		var outerTupleBind:Null<EPattern> = null;
		var wrapperIsDiscard = switch (stmt.def) {
			case EMatch(pattern, _):
				switch (pattern) {
					case PWildcard | PVar("_"): true;
					default: false;
				}
			case EBinary(Match, left, _):
				switch (left.def) {
					case EVar("_") | EUnderscore: true;
					default: false;
				}
			default:
				false;
		};
		var isWrapped = switch (stmt.def) {
			case EMatch(_, _) | EBinary(Match, _, _): true;
			default: false;
		};
		if (!isWrapped || wrapperIsDiscard)
			outerTupleBind = extractSingleVarTuplePattern(initialAcc);

		return {
			iterVar: iterVar,
			initialAcc: initialAcc,
			accPattern: accPattern,
			thenBody: thenBody,
			maybeOuterTupleBind: outerTupleBind
		};
	}

	private static function extractTryIfThenBodyAnyIter(body:ElixirAST):Null<{iterVar:String, thenBody:ElixirAST}> {
		if (body == null || body.def == null)
			return null;

		var root = unwrapSingleStatementBlock(body);
		switch (root.def) {
			case ETry(tryBody, rescue, catchClauses, afterBlock, elseBlock):
				var inner = unwrapSingleStatementBlock(tryBody);
				switch (inner.def) {
					case EIf(cond, thenBranch, _elseBranch):
						var iterVar = extractHasNextVar(cond);
						if (iterVar == null)
							return null;
						var cleanedThen = dropLeadingNextAdvance(thenBranch, iterVar);
						return {iterVar: iterVar, thenBody: makeAST(ETry(cleanedThen, rescue, catchClauses, afterBlock, elseBlock))};
					default:
						return null;
				}
			default:
				return null;
		}
	}

	private static function extractHasNextVar(expr:ElixirAST):Null<String> {
		if (expr == null || expr.def == null)
			return null;
		return switch (unwrapParen(expr).def) {
			case ECall(target, "", args) if (args != null && args.length == 0):
				switch (unwrapParen(target).def) {
					case EField({def: EVar(v)}, "has_next"):
						v;
					default:
						null;
				}
			default:
				null;
		};
	}

	private static function unwrapParen(e:ElixirAST):ElixirAST {
		return switch (e.def) {
			case EParen(inner): unwrapParen(inner);
			default: e;
		};
	}

	private static function unwrapSingleStatementBlock(e:ElixirAST):ElixirAST {
		var unwrapped = unwrapParen(e);
		return switch (unwrapped.def) {
			case EBlock(stmts) if (stmts != null && stmts.length == 1):
				unwrapSingleStatementBlock(stmts[0]);
			case EDo(stmts) if (stmts != null && stmts.length == 1):
				unwrapSingleStatementBlock(stmts[0]);
			default:
				unwrapped;
		};
	}

	private static function dropLeadingNextAdvance(thenBranch:ElixirAST, iterVar:String):ElixirAST {
		if (thenBranch == null || thenBranch.def == null)
			return thenBranch;
		var stmts:Array<ElixirAST> = switch (unwrapParen(thenBranch).def) {
			case EBlock(ss): ss;
			case EDo(ss): ss;
			default: [thenBranch];
		};
		if (stmts.length == 0)
			return thenBranch;

		var startIndex = 0;
		// Drop the loop's "advance" statement if it is the first statement:
		// - `iter = iter.next.()`
		// - `_ = iter.next.()`
		// - `iter.next.()` (statement position)
		if (isNextAdvanceStmt(stmts[0], iterVar))
			startIndex = 1;

		var outStmts = stmts.slice(startIndex);
		return makeAST(EBlock(outStmts));
	}

	private static function isHasNextCall(expr:ElixirAST, iterVar:String):Bool {
		if (expr == null || expr.def == null)
			return false;
		return switch (unwrapParen(expr).def) {
			case ECall(target, "", args) if (args != null && args.length == 0):
				switch (unwrapParen(target).def) {
					case EField({def: EVar(v)}, "has_next") if (v == iterVar):
						true;
					default:
						false;
				}
			default:
				false;
		};
	}

	private static function isNextAssign(stmt:ElixirAST, iterVar:String):Bool {
		if (stmt == null || stmt.def == null)
			return false;
		return switch (stmt.def) {
			case EMatch(PVar(name), rhs) if (name == iterVar):
				isNextCall(rhs, iterVar);
			case EBinary(Match, left, rhs):
				switch (left.def) {
					case EVar(varName) if (varName == iterVar):
						isNextCall(rhs, iterVar);
					default:
						false;
				}
			default:
				false;
		};
	}

	private static function isNextDiscard(stmt:ElixirAST, iterVar:String):Bool {
		if (stmt == null || stmt.def == null)
			return false;
		return switch (stmt.def) {
			case EMatch(PWildcard, rhs):
				isNextCall(rhs, iterVar);
			case EMatch(PVar("_"), rhs):
				isNextCall(rhs, iterVar);
			case EBinary(Match, left, rhs):
				switch (left.def) {
					case EVar("_") | EUnderscore:
						isNextCall(rhs, iterVar);
					default:
						false;
				}
			default:
				false;
		};
	}

	private static function isNextAdvanceStmt(stmt:ElixirAST, iterVar:String):Bool {
		if (stmt == null || stmt.def == null)
			return false;
		if (isNextAssign(stmt, iterVar))
			return true;
		if (isNextDiscard(stmt, iterVar))
			return true;
		// Bare call expression in statement position.
		if (isNextCall(stmt, iterVar))
			return true;
		return false;
	}

	private static function isNextCall(expr:ElixirAST, iterVar:String):Bool {
		if (expr == null || expr.def == null)
			return false;
		return switch (unwrapParen(expr).def) {
			case ECall(target, "", args) if (args != null && args.length == 0):
				switch (unwrapParen(target).def) {
					case EField({def: EVar(v)}, "next") if (v == iterVar):
						true;
					default:
						false;
				}
			default:
				false;
		};
	}

	private static function isEnum(mod:ElixirAST):Bool {
		return switch (mod.def) {
			case EVar("Enum"): true;
			case EAtom(a):
				var s:String = a;
				s == "Enum";
			default: false;
		};
	}

	private static function isStreamIterate(expr:ElixirAST):Bool {
		if (expr == null || expr.def == null)
			return false;
		var unwrapped = unwrapParen(expr);
		return switch (unwrapped.def) {
			case ERemoteCall(mod, "iterate", args) if (args != null && args.length == 2 && isModuleName(mod, "Stream")):
				true;
			case ECall(target, "iterate", args) if (target != null && args != null && args.length == 2 && isModuleName(target, "Stream")):
				true;
			default:
				false;
		};
	}
}
#end
