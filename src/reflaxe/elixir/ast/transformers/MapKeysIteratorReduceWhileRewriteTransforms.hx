package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.ElixirCodeVarRefTokenizer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;
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
 *   2) `Enum.reduce_while(Stream.iterate(...), acc, fn _, acc -> try do if iter.has_next.() do x = iter.next.(); ... {:cont, acc} else {:halt, acc} end catch ... end end)`
 * - Replace it with:
 *   `Enum.reduce_while(Map.keys(map), acc, fn x, acc -> <then-branch-without-next> end)`
 * - When the reduce_while result is used only via an outer accumulator variable, rebind
 *   `{outer} = Enum.reduce_while(...)` so the mutation survives.
 *
 * HOW THE ITERATOR AND THE LOOP VARIABLE ARE PAIRED (by shape, not by name)
 * - Haxe lowers `for (x in it)` to `while (it.hasNext()) { var x = it.next(); ... }`.
 *   The iterator is the receiver of `has_next` in the loop condition. The loop variable is
 *   whatever the first statement of the loop body binds to `iterator.next.()`. Its name
 *   can differ from the iterator's name: Haxe names the iterator `g1` and the loop
 *   variable `g` when an outer `g` is still read, and a hand-written loop uses any names.
 *   The loop variable becomes the argument of the new `fn`.
 * - When the names differ and the rest of the body still reads the iterator, the rewrite
 *   would leave that read unbound, so the loop is left unchanged.
 * - The iterator can also be held by the program (`var it = m.keys(); ... for (x in it)`).
 *   Haxe then copies it into a loop iterator first (`g = it`). The pass follows that copy
 *   back to an earlier `it = Map.keys(m)` in the same statement list and iterates `it`,
 *   which holds the keys list. It rewrites only when nothing else reads or rebinds the
 *   iterator between its binding and the loop, and nothing reads it after the loop: the
 *   list is not consumed as the Haxe iterator is, so a later read would see other values.
 * - The rewrite drops the iterator's init statement (`it = Map.keys(m)`), so it runs only
 *   when no later statement in the same list reads the iterator before rebinding it.
 *   Otherwise that read would see an older binding with the same name (an argument `it`)
 *   and compute a wrong value without an error.
 * - The loop body must start with an advance statement (`x = it.next.()`, `_ = it.next.()`
 *   or a bare `it.next.()`). A loop that does not take one key per step is left unchanged.
 * - Inside a closure (a Haxe function expression, or any `fn` that is not a loop lowering's
 *   `Enum` callback), only the shape that main rewrote is rewritten: a loop variable named
 *   like its iterator. A write from a closure to a captured local can be lost
 *   (haxe.elixir.codex-rrsr item 5); a loop that the pass leaves alone throws instead.
 * - The same name in two places counts as the same variable only inside one statement
 *   list with no rebinding in between, so it identifies an Elixir binding.
 *
 * EXAMPLES (pairing)
 * Haxe: `for (g in m.keys()) { for (g in n.keys()) acc += g; acc += g * 100; }`
 * Elixir (inner loop, before): `g1 = Map.keys(n)`, then `if g1.has_next.() do g_2 = g1.next.(); acc = acc + g_2 ...`
 * Elixir (after): `Enum.reduce_while(Map.keys(n), {acc}, fn g_2, {acc} -> acc = acc + g_2 ... end)`
 * Haxe: `var it = m.keys(); var acc = 0; for (x in it) acc += x;`
 * Elixir (after): `it = Map.keys(m)`, `acc = 0`, `{acc} = Enum.reduce_while(it, {acc}, fn x, {acc} -> ... end)`
 * Covered by test/differential/r16_keys_loop_pairs.
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
/**
 * One iterator-driven loop statement, split into the parts that the keys rewrite needs.
 * `iterVar` is the `has_next` receiver; `loopVar` is the name that the loop body binds to
 * `iterVar.next.()` (the same name when Haxe names them alike); `thenBody` is the loop body
 * without that advance statement.
 */
private typedef IteratorLoop = {
	iterVar:String,
	loopVar:String,
	initialAcc:ElixirAST,
	accPattern:EPattern,
	thenBody:ElixirAST,
	maybeOuterTupleBind:Null<EPattern>
};

class MapKeysIteratorReduceWhileRewriteTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return visit(ast, false);
	}

	/**
	 * Rewrites every statement list under `node`, children first (as `transformNode` does),
	 * and tracks whether the list is inside a closure.
	 *
	 * A closure here is any `fn` except the callback that a loop lowering passes to an
	 * `Enum` function (`Enum.reduce_while(..., fn _, acc -> ... end)`), which threads its
	 * state through the accumulator. A Haxe function expression (`function() {...}`,
	 * `x -> ...`) is a closure even when it is passed to `Enum`; the builder records it as
	 * the `fn`'s source expression. A write from a closure to a captured local can be lost
	 * (haxe.elixir.codex-rrsr item 5), so inside a closure the pass keeps to the rewrites
	 * that main made (`rewriteStatementList`): a loop that it leaves alone throws instead of
	 * computing a wrong value.
	 */
	static function visit(node:ElixirAST, inClosure:Bool):ElixirAST {
		if (node == null || node.def == null)
			return node;
		var rebuilt = switch (node.def) {
			case ERemoteCall(mod, _, args) if (args != null && isEnum(mod)):
				ElixirASTTransformer.transformAST(node,
					child -> isLoopCallback(child) ? ElixirASTTransformer.transformAST(child,
						grandchild -> visit(grandchild, inClosure)) : visit(child, inClosure));
			case EFn(_):
				ElixirASTTransformer.transformAST(node, child -> visit(child, true));
			default:
				ElixirASTTransformer.transformAST(node, child -> visit(child, inClosure));
		};
		return switch (rebuilt.def) {
			case EBlock(stmts):
				makeASTWithMeta(EBlock(rewriteStatementList(stmts, inClosure)), rebuilt.metadata, rebuilt.pos);
			case EDo(stmts):
				makeASTWithMeta(EDo(rewriteStatementList(stmts, inClosure)), rebuilt.metadata, rebuilt.pos);
			default:
				rebuilt;
		};
	}

	/** True for an `fn` argument of an `Enum` call that did not come from a Haxe function expression. */
	static function isLoopCallback(arg:ElixirAST):Bool {
		if (arg == null || arg.def == null)
			return false;
		return switch (arg.def) {
			case EFn(_): !isHaxeFunctionExpression(arg);
			default: false;
		};
	}

	/** True when the builder recorded a Haxe function expression (`TFunction`) as this node's source. */
	static function isHaxeFunctionExpression(node:ElixirAST):Bool {
		if (node.metadata == null || node.metadata.sourceExpr == null)
			return false;
		return switch (node.metadata.sourceExpr.expr) {
			case TFunction(_): true;
			default: false;
		};
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

	/**
	 * Rewrites the iterator loops over map keys in one statement list.
	 *
	 * Inside a closure (`inClosure`, see `visit`) it makes only the rewrites that main made:
	 * the loop variable must have the iterator's name, and the program-held iterator variant
	 * is off. Outside a closure, the loop variable can have another name, and a program-held
	 * iterator is followed back to its keys list.
	 */
	static function rewriteStatementList(stmts:Array<ElixirAST>, inClosure:Bool):Array<ElixirAST> {
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
				var reduceAny0 = extractIteratorLoop(stmts[i + 1]);
				if (reduceAny0 != null && allowedIn(reduceAny0, inClosure)) {
					var trimmedBlockStmt = nestedTail.rebuildWithoutKeysDiscard();
					if (trimmedBlockStmt != null)
						out.push(trimmedBlockStmt);

					out.push(rebuildWrapper(stmts[i + 1], keysReduceWhile(nestedTail.keysExpr, reduceAny0), reduceAny0.maybeOuterTupleBind));
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
			// The init binds `iter` and the very next statement reads `iter.has_next`, so the
			// same name is the same Elixir variable (no rebinding can come in between).
			// The rewrite drops the init, so it runs only when no later statement reads `iter`
			// before rebinding it (`deadFrom`). Otherwise that read would see an older binding
			// with the same name, such as an argument `it`, instead of the iterator: a silent
			// wrong value. Then the loop stays as it is.
			var nestedInit = extractTrailingMapKeysInitFromStmtBlock(stmts[i]);
			if (nestedInit != null && i + 1 < stmts.length) {
				var reduce0 = extractIteratorLoop(stmts[i + 1]);
				if (reduce0 != null
					&& reduce0.iterVar == nestedInit.iterVar
					&& allowedIn(reduce0, inClosure)
					&& deadFrom(stmts, i + 2, nestedInit.iterVar, reduce0.loopVar != reduce0.iterVar)) {
					var trimmedBlockStmt0 = nestedInit.rebuildWithoutKeysInit();
					if (trimmedBlockStmt0 != null)
						out.push(trimmedBlockStmt0);

					out.push(rebuildWrapper(stmts[i + 1], keysReduceWhile(nestedInit.keysExpr, reduce0), reduce0.maybeOuterTupleBind));
					i += 2;
					continue;
				}
			}

			var init = extractMapKeysInit(stmts[i]);
			if (init != null && i + 1 < stmts.length) {
				var reduce = extractIteratorLoop(stmts[i + 1]);
				if (reduce != null
					&& reduce.iterVar == init.iterVar
					&& allowedIn(reduce, inClosure)
					&& deadFrom(stmts, i + 2, init.iterVar, reduce.loopVar != reduce.iterVar)) {
					#if debug_map_keys_reduce_while
					#if sys
					Sys.println('[MapKeysReduceWhile] rewrite via init iterVar=' + init.iterVar);
					#else
					trace('[MapKeysReduceWhile] rewrite via init iterVar=' + init.iterVar);
					#end
					#end
					out.push(rebuildWrapper(stmts[i + 1], keysReduceWhile(init.keysExpr, reduce), reduce.maybeOuterTupleBind));
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
				var reduceAny = extractIteratorLoop(stmts[i + 1]);
				if (reduceAny != null && allowedIn(reduceAny, inClosure)) {
					#if debug_map_keys_reduce_while
					#if sys
					Sys.println('[MapKeysReduceWhile] rewrite via discard iterVar=' + reduceAny.iterVar);
					#else
					trace('[MapKeysReduceWhile] rewrite via discard iterVar=' + reduceAny.iterVar);
					#end
					#end
					out.push(rebuildWrapper(stmts[i + 1], keysReduceWhile(keysDiscard, reduceAny), reduceAny.maybeOuterTupleBind));
					i += 2;
					continue;
				}
			}

			// Variant: the program holds the iterator. `it = Map.keys(m)` comes earlier, and
			// the loop drives `it` itself or a copy of it (`g = it`) bound before the loop.
			var held = inClosure ? null : extractIteratorLoop(stmts[i]);
			if (held != null) {
				var source = resolveHeldKeysSource(out, held, stmts, i + 1);
				if (source != null) {
					if (source.copyIndex >= 0)
						out.splice(source.copyIndex, 1);
					out.push(rebuildWrapper(stmts[i], keysReduceWhile(makeAST(EVar(source.keysVar)), held), held.maybeOuterTupleBind));
					i++;
					continue;
				}
			}

			out.push(stmts[i]);
			i++;
		}

		return out;
	}

	/** Inside a closure, only a loop variable named like its iterator (the shape main rewrote). */
	static function allowedIn(loop:IteratorLoop, inClosure:Bool):Bool {
		return !inClosure || loop.loopVar == loop.iterVar;
	}

	/** Builds `Enum.reduce_while(keys, acc, fn loopVar, accPattern -> body end)` for a matched loop. */
	static function keysReduceWhile(keysExpr:ElixirAST, loop:IteratorLoop):ElixirAST {
		var fn = makeAST(EFn([
			{
				args: [PVar(loop.loopVar), loop.accPattern],
				guard: null,
				body: loop.thenBody
			}
		]));
		return makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce_while", [keysExpr, loop.initialAcc, fn]));
	}

	/**
	 * Finds the keys list that a loop over a program-held iterator can iterate instead.
	 *
	 * Returns the name of the variable bound to `Map.keys(m)`, and the index in `out` of the
	 * copy `loopIter = it` to drop (-1 when the loop drives `it` itself). Returns null unless:
	 * - the last binding of the loop's iterator in `out` is `loopIter = Map.keys(m)`, or the
	 *   copy `loopIter = it` of an earlier `it = Map.keys(m)`;
	 * - no statement between that binding and the loop reads or rebinds those names;
	 * - the loop body does not read the keys variable, unless the loop variable shadows it;
	 * - no later statement reads the iterator or the keys variable before it is bound again.
	 *
	 * Example: `it = Map.keys(m)`, `acc = 0`, `g = it`, loop on `g` -> keys variable `it`,
	 * copy index 2.
	 */
	static function resolveHeldKeysSource(out:Array<ElixirAST>, loop:IteratorLoop, stmts:Array<ElixirAST>, after:Int):Null<{keysVar:String, copyIndex:Int}> {
		var iterVar = loop.iterVar;
		var bindIndex = lastBindingIndex(out, iterVar, out.length);
		if (bindIndex < 0 || touchedIn(out, bindIndex + 1, out.length, iterVar))
			return null;
		var value = simpleAssignedValue(out[bindIndex], iterVar);
		if (value == null)
			return null;
		value = unwrapNestedDiscard(unwrapParen(value));

		var keysVar = iterVar;
		var copyIndex = -1;
		if (!isMapKeysCall(value)) {
			var copied = switch (value.def) {
				case EVar(name) if (name != iterVar && name != "_"): name;
				default: null;
			};
			if (copied == null)
				return null;
			var keysIndex = lastBindingIndex(out, copied, bindIndex);
			if (keysIndex < 0)
				return null;
			var keysValue = simpleAssignedValue(out[keysIndex], copied);
			if (keysValue == null || !isMapKeysCall(unwrapNestedDiscard(unwrapParen(keysValue))))
				return null;
			if (touchedIn(out, keysIndex + 1, bindIndex, copied) || touchedIn(out, bindIndex + 1, out.length, copied))
				return null;
			if (!deadFrom(stmts, after, iterVar, true))
				return null;
			keysVar = copied;
			copyIndex = bindIndex;
		}
		if (keysVar != loop.loopVar && VarUseAnalyzer.stmtUsesVarExact(loop.thenBody, keysVar))
			return null;
		if (!deadFrom(stmts, after, keysVar, true))
			return null;
		return {keysVar: keysVar, copyIndex: copyIndex};
	}

	/** Index of the last statement before `end` that binds `name`, or -1. */
	static function lastBindingIndex(stmts:Array<ElixirAST>, name:String, end:Int):Int {
		var k = end - 1;
		while (k >= 0) {
			if (BinderTransforms.statementBindsName(stmts[k], name))
				return k;
			k--;
		}
		return -1;
	}

	/** True when a statement in `stmts[start...end]` reads or binds `name`. */
	static function touchedIn(stmts:Array<ElixirAST>, start:Int, end:Int, name:String):Bool {
		for (k in start...end)
			if (VarUseAnalyzer.stmtUsesVarExact(stmts[k], name) || BinderTransforms.statementBindsName(stmts[k], name))
				return true;
		return false;
	}

	/**
	 * True when no statement from `start` on reads `name` before a plain `name = value`
	 * (whose value does not read it) or another binding replaces it.
	 *
	 * A read counts only when it can see the outer binding (`readsOuter`). Example: in
	 * `show((fn -> k = Map.keys(m); ... k ... end).())` the function binds its own `k`
	 * before it reads it, so that statement does not read the outer `k`.
	 *
	 * `scanRaw` also counts a variable reference inside opaque raw Elixir code. Callers pass
	 * false for a loop variable named like its iterator: the program cannot name such an
	 * iterator (Haxe named it after the loop variable), and main rewrote that shape without
	 * any check.
	 */
	static function deadFrom(stmts:Array<ElixirAST>, start:Int, name:String, scanRaw:Bool):Bool {
		for (k in start...stmts.length) {
			var rebound = simpleAssignedValue(stmts[k], name);
			if (rebound != null)
				return !readsOuter(rebound, name, scanRaw);
			if (readsOuter(stmts[k], name, scanRaw))
				return false;
			if (BinderTransforms.statementBindsName(stmts[k], name))
				return true;
		}
		return true;
	}

	/**
	 * True when `node` reads `name` from the enclosing scope: a free reference that no
	 * binder inside `node` shadows (`VarUseAnalyzer.usesFreeVarExact`), or, with `scanRaw`,
	 * a variable reference in opaque raw Elixir code, which the lexical analysis cannot
	 * see into. Raw code is read with `ElixirCodeVarRefTokenizer`, which skips quoted
	 * strings, atoms and keyword keys: `Map.get(o, "key")` or `%d` in a format string does
	 * not read a variable `key` or `d`.
	 */
	static function readsOuter(node:ElixirAST, name:String, scanRaw:Bool):Bool {
		if (VarUseAnalyzer.usesFreeVarExact(node, name))
			return true;
		if (!scanRaw)
			return false;
		var mentioned = false;
		function scan(n:ElixirAST):ElixirAST {
			if (mentioned || n == null || n.def == null)
				return n;
			switch (n.def) {
				case ERaw(code):
					var refs = new Map<String, Bool>();
					ElixirCodeVarRefTokenizer.collectFromElixirCode(code, refs);
					if (refs.exists(name))
						mentioned = true;
				default:
					ElixirASTTransformer.transformAST(n, scan);
			}
			return n;
		}
		scan(node);
		return mentioned;
	}

	/** The value of `name = value` (either match form); null for any other statement. */
	static function simpleAssignedValue(stmt:ElixirAST, name:String):Null<ElixirAST> {
		if (stmt == null || stmt.def == null)
			return null;
		return switch (stmt.def) {
			case EMatch(PVar(bound), value) if (bound == name): value;
			case EBinary(Match, {def: EVar(bound)}, value) if (bound == name): value;
			default: null;
		};
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

	/**
	 * Matches the iterator-driven loop statement
	 * `Enum.reduce_while(Stream.iterate(...), acc, fn _, acc -> try do if iter.has_next.() do ... end ... end end)`,
	 * optionally wrapped in `_ = ...` or `{outer} = ...`, and returns its parts: the iterator
	 * (`has_next` receiver), the loop variable, and the body without the `x = iter.next.()` advance.
	 * Returns null for any other statement, and when the loop cannot be rewritten safely
	 * (see `splitLeadingNextAdvance`).
	 */
	private static function extractIteratorLoop(stmt:ElixirAST):Null<IteratorLoop> {
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
		var loopVar:Null<String> = null;

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
				loopVar = extracted.loopVar;
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
			loopVar: loopVar,
			initialAcc: initialAcc,
			accPattern: accPattern,
			thenBody: thenBody,
			maybeOuterTupleBind: outerTupleBind
		};
	}

	private static function extractTryIfThenBodyAnyIter(body:ElixirAST):Null<{iterVar:String, loopVar:String, thenBody:ElixirAST}> {
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
						var split = splitLeadingNextAdvance(thenBranch, iterVar);
						if (split == null)
							return null;
						return {
							iterVar: iterVar,
							loopVar: split.loopVar,
							thenBody: makeAST(ETry(split.body, rescue, catchClauses, afterBlock, elseBlock))
						};
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
		var structuralReceiver = extractStructuralCallReceiver(expr, "has_next");
		if (structuralReceiver != null)
			return structuralReceiver;
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

	/**
	 * Splits the loop's advance statement from the rest of the `has_next` branch.
	 *
	 * Returns the loop variable and the remaining statements. The loop variable is the name
	 * that the first statement binds to `iter.next.()` (`x = iter.next.()` gives `x`; the
	 * name can differ from `iter`). For `_ = iter.next.()` or a bare `iter.next.()`, it is
	 * `iter`, as before.
	 *
	 * Returns null, so the loop is left unchanged, when:
	 * - the branch does not start with one of these advance statements. Such a loop does not
	 *   take one key per step (`while (it.hasNext()) { n++; if (n > 5) break; }` never
	 *   advances, and `if (rare) it.next();` advances only sometimes), so a loop over the
	 *   keys list would compute another result;
	 * - the loop variable differs from `iter` and a later statement still reads `iter`: the
	 *   new `fn` binds only the loop variable, so that read would be lost.
	 */
	private static function splitLeadingNextAdvance(thenBranch:ElixirAST, iterVar:String):Null<{loopVar:String, body:ElixirAST}> {
		if (thenBranch == null || thenBranch.def == null)
			return null;
		var stmts:Array<ElixirAST> = switch (unwrapParen(thenBranch).def) {
			case EBlock(ss): ss;
			case EDo(ss): ss;
			default: [thenBranch];
		};
		if (stmts.length == 0)
			return null;

		var first = stmts[0];
		if (isNextDiscard(first, iterVar) || isNextCall(first, iterVar))
			return {loopVar: iterVar, body: makeAST(EBlock(stmts.slice(1)))};
		var bound = nextAssignTarget(first, iterVar);
		if (bound == null)
			return null;
		var rest = stmts.slice(1);
		if (bound != iterVar && Lambda.exists(rest, s -> VarUseAnalyzer.stmtUsesVarExact(s, iterVar)))
			return null;
		return {loopVar: bound, body: makeAST(EBlock(rest))};
	}

	/** Returns `x` when `stmt` is `x = iter.next.()` (either match form, `x` not `_`); null otherwise. */
	private static function nextAssignTarget(stmt:ElixirAST, iterVar:String):Null<String> {
		if (stmt == null || stmt.def == null)
			return null;
		return switch (stmt.def) {
			case EMatch(PVar(name), rhs) if (name != "_" && isNextCall(rhs, iterVar)): name;
			case EBinary(Match, {def: EVar(name)}, rhs) if (name != "_" && isNextCall(rhs, iterVar)): name;
			default: null;
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

	private static function isNextCall(expr:ElixirAST, iterVar:String):Bool {
		if (expr == null || expr.def == null)
			return false;
		if (extractStructuralCallReceiver(expr, "next") == iterVar)
			return true;
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

	/**
	 * Recognize the exact zero-argument structural dispatch emitted by CallExprBuilder.
	 * The surrounding rewrite separately proves that this receiver is Map.keys output.
	 * Check both branches and every receiver reference: extra effects, arguments, or
	 * changed dispatch semantics must not be erased along with iterator scaffolding.
	 */
	private static function extractStructuralCallReceiver(expr:ElixirAST, method:String):Null<String> {
		if (expr == null)
			return null;
		return switch (unwrapParen(expr).def) {
			case ECase({def: EVar(receiver)}, [{pattern: PVar(bound), guard: null, body: dispatch}]):
				switch (unwrapParen(dispatch).def) {
					case ECase({def: ERemoteCall({def: EVar("Map")}, "fetch", [{def: EVar(lookupReceiver)}, {def: EAtom(lookupMethod)}])},
						[
							{pattern: PTuple([PLiteral({def: EAtom(ok)}), PVar(callback)]), guard: null, body: {def: ECall({def: EVar(called)}, "", [])}},
							{
								pattern: PLiteral({def: EAtom(error)}),
								guard: null,
								body: {
									def: ECall(null, "apply", [
										module,
										{def: EAtom(fallbackMethod)},
										{def: EList([{def: EVar(fallbackReceiver)}])}
									])
								}
							}
						])
						if (ok == "ok" && error == "error" && lookupReceiver == bound && lookupMethod == method && called == callback
							&& fallbackMethod == method && fallbackReceiver == bound):
						switch (module.def) {
							case EBinary(OrElse, {def: ERemoteCall({def: EVar("Map")}, "get", [{def: EVar(classReceiver)}, {def: EAtom(classKey)}])},
								{def: ERemoteCall({def: EVar("Map")}, "get", [{def: EVar(structReceiver)}, {def: EAtom(structKey)}])})
								if (classReceiver == bound && structReceiver == bound && classKey == "__reflaxe_class__" && structKey == "__struct__"): receiver;
							default: null;
						}
					default: null;
				}
			default: null;
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
