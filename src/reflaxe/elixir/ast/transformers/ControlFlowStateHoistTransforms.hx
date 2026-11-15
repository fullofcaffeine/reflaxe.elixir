package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControlFlowStateHoistTransforms
 *
 * WHAT
 * - Hoists mutable-style updates inside control-flow statements (`if`/`unless`/`case`/`cond`)
 *   into an outer pattern match so updated values survive Elixir branch scoping.
 *
 * WHY
 * - In Elixir, rebinding inside `if`/`case`/`cond` does not update the outer scope:
 *     x = 0
 *     if cond, do: x = 1
 *     x # => 0 (and a warning)
 *   Haxe code frequently relies on imperative updates in these constructs. When we compile to Elixir,
 *   we must convert those updates into an expression result and bind it outside the control-flow.
 * - This pass fixes both semantics and the associated "variable is unused (same name in context)"
 *   warnings that become fatal under `--warnings-as-errors`.
 *
 * HOW
 * - For each function body (EDef/EDefp) and anonymous function clause (EFn):
 *   - Track which variables are already bound (params + prior assignments in the current block).
 *   - In statement position within a block/do list (all but the last expression):
 *     - If an `if`/`unless`/`case`/`cond` branch body assigns to any already-bound variable(s),
 *       rewrite the statement into a single outer match that binds the updated value(s):
 *         var = if cond do ... end
 *         {a, b} = case expr do ... end
 *     - Ensure each branch/clause returns the updated variable value(s) by appending the return
 *       expression (or tuple) to the end of each branch body.
 *   - A match that keeps the value of such a control flow (`r = case ... end`) needs both the
 *     value and the updates. See `maybeHoistControlFlowValue`.
 * - A branch may have another variable under the name of an updated one: a pattern binder
 *   (`case Ok(value):`) or its own `var`. Haxe keeps the two apart; in Elixir they share a name.
 *   Two rules follow:
 *   - Which writes count. A `var` statement is never an update. An assignment is judged by the
 *     Haxe variable it targets, read from the typed expression that the builder keeps on the
 *     node (`sourceLocal`). A write that the compiler built has no such identity, for example
 *     a loop result match or the rebind of `items.push(v)`; it is judged by name, from the
 *     `var` statements before it in its own branch (`writesOuterVariable`).
 *   - What a branch returns. Where the name belongs to the other variable, the branch returns
 *     the outer value from a capture, `reflaxe_outer_<name>_<n>`, made before the control flow
 *     (pattern binder) or just before the `var` (`readsBehindBinders`, `readsAfterStatements`).
 *   The capture name is one that the function does not use (`freshCaptureName`).
 *   Limits: this depends on the builder's metadata reaching this pass; without it a `var` looks
 *   like an assignment. It follows the statements of the branch and of plain blocks among them
 *   (an unrolled loop body, a `case` arm body), not a `var` inside a nested control flow.
 * - Assignment patterns may bind several values, as in a loop reducer's
 *   `{left, right} = Enum.reduce(...)`. Inspect every binding in the pattern,
 *   not only a single variable. Pinned values are reads, not new bindings.
 *
 * EXAMPLES
 * Haxe:
 *   var min = nums[0];
 *   if (n < min) min = n;
 *
 * Elixir (before):
 *   min = nums[0]
 *   if n < min do
 *     min = n
 *   end
 *
 * Elixir (after):
 *   min = nums[0]
 *   min = if n < min do
 *     min = n
 *     min
 *   else
 *     min
 *   end
 */
/**
 * What the write search knows about Haxe locals at one point of a branch.
 * - `ids`: every local that the control flow declares somewhere inside.
 * - `names`: the Elixir names that, at this point, belong to such a local,
 *   because its `var` statement came earlier in an enclosing statement list.
 */
private typedef BranchLocals = {ids:Map<Int, Bool>, names:Map<String, Bool>};

/**
 * For each updated variable, the name that holds its outer value at one
 * point of a branch: the variable itself, or the temporary that captured it
 * before a pattern binder or a `var` of the same name took the name over.
 */
private typedef OuterReads = Map<String, String>;

/**
 * State of one hoist.
 * - `localIds`: every Haxe local that the control flow declares inside.
 * - `prelude`: captures to run before the control flow starts.
 * - `captured`: the capture temporary of each name whose capture is in `prelude`.
 */
private typedef HoistScope = {localIds:Map<Int, Bool>, prelude:Array<ElixirAST>, captured:Map<String, String>};

/** The Haxe local that a match writes, and whether the match is its `var` declaration. */
private typedef SourceLocal = {declares:Bool, id:Int};

class ControlFlowStateHoistTransforms {
	/** Numbers the `reflaxe_outer_*` temporaries of one module. */
	static var captureCounter:Int = 0;

	/** The function or closure that is being rewritten. `captureOuter` searches it for names in use. */
	static var scopeRoot:Null<ElixirAST> = null;

	/** Names that `scopeRoot` uses, and its string and raw-code texts. Filled on the first capture. */
	static var scopeNames:Null<Map<String, Bool>> = null;

	static var scopeTexts:Null<Array<String>> = null;

	public static function pass(ast:ElixirAST):ElixirAST {
		captureCounter = 0;
		return ElixirASTTransformer.transformNode(ast, function(node:ElixirAST):ElixirAST {
			if (node == null || node.def == null)
				return node;

			return switch (node.def) {
				case EDef(name, args, guards, body):
					enterScope(node);
					var bound = collectBoundFromArgs(args);
					var newGuards = guards != null ? rewriteInScope(guards, bound, true) : null;
					var newBody = rewriteInScope(body, bound, true, true);
					makeASTWithMeta(EDef(name, args, newGuards, newBody), node.metadata, node.pos);

				case EDefp(name, args, guards, body):
					enterScope(node);
					var bound = collectBoundFromArgs(args);
					var newGuards = guards != null ? rewriteInScope(guards, bound, true) : null;
					var newBody = rewriteInScope(body, bound, true, true);
					makeASTWithMeta(EDefp(name, args, newGuards, newBody), node.metadata, node.pos);

				case EFn(clauses):
					enterScope(node);
					var newClauses = [];
					for (cl in clauses) {
						var clauseBound = collectBoundFromArgs(cl.args);
						var newGuard = cl.guard != null ? rewriteInScope(cl.guard, clauseBound, true) : null;
						var newClauseBody = rewriteInScope(cl.body, clauseBound, true, true);
						newClauses.push({args: cl.args, guard: newGuard, body: newClauseBody});
					}
					makeASTWithMeta(EFn(newClauses), node.metadata, node.pos);

				default:
					node;
			};
		});
	}

	// -------------------- Scope rewrite (carries bound-set) --------------------

	/**
	 * Rewrites one node with the bindings that are visible at that point.
	 *
	 * `scopeEnd` is true only for the body of a function or closure: when its
	 * statement list ends, every local binding ends too. `rewriteSeq` uses
	 * that to skip a hoist whose result nothing can read.
	 */
	static function rewriteInScope(node:ElixirAST, bound:Map<String, Bool>, valueUsed:Bool, scopeEnd:Bool = false):ElixirAST {
		if (node == null || node.def == null)
			return node;

		return switch (node.def) {
			case EBlock(stmts):
				makeASTWithMeta(EBlock(rewriteSeq(stmts, bound, valueUsed, scopeEnd)), node.metadata, node.pos);
			case EDo(stmts):
				makeASTWithMeta(EDo(rewriteSeq(stmts, bound, valueUsed, scopeEnd)), node.metadata, node.pos);

			case EIf(cond, thenB, elseB):
				var newCond = rewriteInScope(cond, bound, true);
				var newThen = rewriteInScope(thenB, clone(bound), true);
				var newElse = elseB != null ? rewriteInScope(elseB, clone(bound), true) : null;
				makeASTWithMeta(EIf(newCond, newThen, newElse), node.metadata, node.pos);

			case EUnless(cond, body, elseBranch):
				var newCond = rewriteInScope(cond, bound, true);
				var newBody = rewriteInScope(body, clone(bound), true);
				var newElse = elseBranch != null ? rewriteInScope(elseBranch, clone(bound), true) : null;
				makeASTWithMeta(EUnless(newCond, newBody, newElse), node.metadata, node.pos);

			case ECase(expr, clauses):
				var newExpr = rewriteInScope(expr, bound, true);
				var newClauses = [];
				for (cl in clauses) {
					var newGuard = cl.guard != null ? rewriteInScope(cl.guard, clone(bound), true) : null;
					var newBody = rewriteInScope(cl.body, clone(bound), true);
					newClauses.push({pattern: cl.pattern, guard: newGuard, body: newBody});
				}
				makeASTWithMeta(ECase(newExpr, newClauses), node.metadata, node.pos);

			case ECond(clauses):
				var newClauses = [];
				for (cl in clauses) {
					newClauses.push({
						condition: rewriteInScope(cl.condition, bound, true),
						body: rewriteInScope(cl.body, clone(bound), true)
					});
				}
				makeASTWithMeta(ECond(newClauses), node.metadata, node.pos);

			case EWith(clauses, doBlock, elseBlock):
				var newClauses = [];
				for (c in clauses)
					newClauses.push({pattern: c.pattern, expr: rewriteInScope(c.expr, bound, true)});
				var newDo = rewriteInScope(doBlock, clone(bound), true);
				var newElse = elseBlock != null ? rewriteInScope(elseBlock, clone(bound), true) : null;
				makeASTWithMeta(EWith(newClauses, newDo, newElse), node.metadata, node.pos);

			case ETry(body, rescue, catchClauses, afterBlock, elseBlock):
				// Loop break/continue lowering wraps its reducer in try. Branch updates
				// must survive within that body, without leaking bindings between handlers
				// or changing the try's result and exception behavior.
				var newRescue:Array<ERescueClause> = [];
				for (cl in rescue) {
					var handlerBound = clone(bound);
					bindFromPattern(cl.pattern, handlerBound);
					if (cl.varName != null && isBindableName(cl.varName))
						handlerBound.set(cl.varName, true);
					var rewritten:ERescueClause = {pattern: cl.pattern, body: rewriteInScope(cl.body, handlerBound, true)};
					if (cl.varName != null)
						rewritten.varName = cl.varName;
					newRescue.push(rewritten);
				}
				var newCatch:Array<ECatchClause> = [];
				for (cl in catchClauses) {
					var handlerBound = clone(bound);
					bindFromPattern(cl.pattern, handlerBound);
					newCatch.push({kind: cl.kind, pattern: cl.pattern, body: rewriteInScope(cl.body, handlerBound, true)});
				}
				makeASTWithMeta(ETry(rewriteInScope(body, clone(bound), true), newRescue, newCatch,
					afterBlock != null ? rewriteInScope(afterBlock, clone(bound), false) : null,
					elseBlock != null ? rewriteInScope(elseBlock, clone(bound), true) : null),
					node.metadata, node.pos);

			case EBinary(op, left, right):
				makeASTWithMeta(EBinary(op, rewriteInScope(left, bound, true), rewriteInScope(right, bound, true)), node.metadata, node.pos);
			case EMatch(p, rhs):
				makeASTWithMeta(EMatch(p, rewriteInScope(rhs, bound, true)), node.metadata, node.pos);
			case EUnary(opU, eU):
				makeASTWithMeta(EUnary(opU, rewriteInScope(eU, bound, true)), node.metadata, node.pos);
			case EParen(inner):
				makeASTWithMeta(EParen(rewriteInScope(inner, bound, valueUsed)), node.metadata, node.pos);
			case EPipe(l, r):
				makeASTWithMeta(EPipe(rewriteInScope(l, bound, true), rewriteInScope(r, bound, true)), node.metadata, node.pos);
			case ECall(tgt, fnName, args):
				makeASTWithMeta(ECall(tgt != null ? rewriteInScope(tgt, bound, true) : null, fnName, [for (a in args) rewriteInScope(a, bound, true)]),
					node.metadata, node.pos);
			case ERemoteCall(target, functionName, args):
				makeASTWithMeta(ERemoteCall(rewriteInScope(target, bound, true), functionName, [for (a in args) rewriteInScope(a, bound, true)]),
					node.metadata, node.pos);
			case EField(obj, fieldName):
				makeASTWithMeta(EField(rewriteInScope(obj, bound, true), fieldName), node.metadata, node.pos);
			case EAccess(obj, key):
				makeASTWithMeta(EAccess(rewriteInScope(obj, bound, true), rewriteInScope(key, bound, true)), node.metadata, node.pos);
			case EKeywordList(pairs):
				makeASTWithMeta(EKeywordList([for (p in pairs) {key: p.key, value: rewriteInScope(p.value, bound, true)}]), node.metadata, node.pos);
			case EMap(pairs):
				makeASTWithMeta(EMap([
					for (p in pairs)
						{key: rewriteInScope(p.key, bound, true), value: rewriteInScope(p.value, bound, true)}
				]), node.metadata, node.pos);
			case EStructUpdate(base, fields):
				makeASTWithMeta(EStructUpdate(rewriteInScope(base, bound, true), [for (f in fields) {key: f.key, value: rewriteInScope(f.value, bound, true)}]),
					node.metadata, node.pos);
			case ETuple(elems):
				makeASTWithMeta(ETuple([for (e in elems) rewriteInScope(e, bound, true)]), node.metadata, node.pos);
			case EList(elems):
				makeASTWithMeta(EList([for (e in elems) rewriteInScope(e, bound, true)]), node.metadata, node.pos);
			case ERange(start, end, exclusive, step):
				makeASTWithMeta(ERange(rewriteInScope(start, bound, true), rewriteInScope(end, bound, true), exclusive,
					step != null ? rewriteInScope(step, bound, true) : null),
					node.metadata, node.pos);
			case EPin(inner):
				makeASTWithMeta(EPin(rewriteInScope(inner, bound, true)), node.metadata, node.pos);

			// Nested scopes are handled by the outer transformNode walk.
			case EDef(_, _, _, _) | EDefp(_, _, _, _) | EFn(_):
				node;

			default:
				node;
		};
	}

	static function rewriteSeq(stmts:Array<ElixirAST>, bound:Map<String, Bool>, blockValueUsed:Bool, scopeEnd:Bool = false):Array<ElixirAST> {
		if (stmts == null)
			return stmts;

		var localBound = clone(bound);
		var out:Array<ElixirAST> = [];

		for (i in 0...stmts.length) {
			var stmt = stmts[i];
			var stmtValueUsed = blockValueUsed && (i == stmts.length - 1);
			var newStmt = rewriteInScope(stmt, localBound, stmtValueUsed);

			// Hoist only in statement position:
			// - In value-used blocks, that's "all but last".
			// - In statement-only blocks, even the last statement's value is unused.
			// A statement such as `r = case ... end` keeps the value of the control
			// flow, so its branch updates must leave together with that value.
			if (!stmtValueUsed) {
				// A hoist may need the outer value of a variable that a branch
				// shadows. It captures that value in statements that run first.
				var prelude:Array<ElixirAST> = [];
				newStmt = maybeHoistControlFlowStatement(newStmt, localBound, prelude);
				newStmt = maybeHoistControlFlowValue(newStmt, localBound, prelude, scopeEnd
					&& i == stmts.length - 2 ? stmts[i + 1] : null);
				for (capture in prelude)
					out.push(capture);
			}

			out.push(newStmt);
			bindFromStatement(newStmt, localBound);
		}

		return out;
	}

	// -------------------- Hoisting logic --------------------

	static function maybeHoistControlFlowStatement(stmt:ElixirAST, bound:Map<String, Bool>, prelude:Array<ElixirAST>):ElixirAST {
		if (stmt == null || stmt.def == null)
			return stmt;

		return switch (stmt.def) {
			case EParen(inner):
				// Parentheses are frequently introduced by other passes for consistent printing.
				// If the inner expression is a hoistable control-flow statement, hoist it.
				maybeHoistControlFlowStatement(inner, bound, prelude);

			// Some pipelines materialize statement-position control-flow as `_ = <expr>`.
			// Only exact `_` discards. Named underscore bindings can be read later.
			case EBinary(Match, left, rhs) if (isDiscardVar(left) && isControlFlowExpr(rhs)):
				maybeHoistControlFlowStatement(rhs, bound, prelude);
			case EMatch(PVar("_"), rhs) if (isControlFlowExpr(rhs)):
				maybeHoistControlFlowStatement(rhs, bound, prelude);

			case EIf(cond, thenB, elseB):
				var updates = collectAssignedToBoundVars([thenB, elseB], bound);
				if (updates.length == 0)
					return stmt;
				var scope = hoistScope([thenB, elseB], prelude);
				var reads = outerReads(updates);

				var newThen = ensureReturns(thenB, updates, reads, scope, null);
				var newElse = ensureReturns(elseB, updates, reads, scope, null);

				// Hoisting the outer `if` can change inner statement positions (e.g. the previous last
				// expression becomes a statement once we append the return expr). Re-run scope rewrite
				// on the new control-flow expression so nested hoists apply.
				var newIf = makeASTWithMeta(EIf(cond, newThen, newElse), stmt.metadata, stmt.pos);
				var rewrittenIf = rewriteInScope(newIf, clone(bound), true);
				makeHoistMatch(updates, rewrittenIf, stmt);

			case EUnless(cond, body, elseBranch):
				var updates = collectAssignedToBoundVars([body, elseBranch], bound);
				if (updates.length == 0)
					return stmt;
				var scope = hoistScope([body, elseBranch], prelude);
				var reads = outerReads(updates);

				var newBody = ensureReturns(body, updates, reads, scope, null);
				var newElse = ensureReturns(elseBranch, updates, reads, scope, null);

				var newUnless = makeASTWithMeta(EUnless(cond, newBody, newElse), stmt.metadata, stmt.pos);
				var rewrittenUnless = rewriteInScope(newUnless, clone(bound), true);
				makeHoistMatch(updates, rewrittenUnless, stmt);

			case ECase(expr, clauses):
				var updates = collectAssignedToBoundVars([stmt], bound);
				if (updates.length == 0)
					return stmt;
				var scope = hoistScope([stmt], prelude);
				var reads = outerReads(updates);

				var newClauses = [];
				for (c in clauses) {
					var binders = patternNames(c.pattern);
					newClauses.push({
						pattern: c.pattern,
						guard: c.guard,
						body: ensureReturns(c.body, updates, readsBehindBinders(binders, reads, scope), scope, binders)
					});
				}
				var newCase = makeASTWithMeta(ECase(expr, newClauses), stmt.metadata, stmt.pos);
				var rewrittenCase = rewriteInScope(newCase, clone(bound), true);
				makeHoistMatch(updates, rewrittenCase, stmt);

			case ECond(clauses):
				var bodies:Array<ElixirAST> = [for (c in clauses) c.body];
				var updates = collectAssignedToBoundVars(bodies, bound);
				if (updates.length == 0)
					return stmt;
				var scope = hoistScope(bodies, prelude);
				var reads = outerReads(updates);

				var newClauses = [];
				for (c in clauses) {
					newClauses.push({condition: c.condition, body: ensureReturns(c.body, updates, reads, scope, null)});
				}
				var newCond = makeASTWithMeta(ECond(newClauses), stmt.metadata, stmt.pos);
				var rewrittenCond = rewriteInScope(newCond, clone(bound), true);
				makeHoistMatch(updates, rewrittenCond, stmt);

			case ETry(body, rescue, catchClauses, null, null):
				// A normally completed try or handler must export its updated locals,
				// just like an if/case branch. Appending the state also makes a final
				// handler case a statement, so the existing nested hoist can export it.
				// Native after/else forms have different scopes and are not handled here.
				// This does not transport writes from a throwing body into its handler.
				var updates = collectAssignedToBoundVars([stmt], bound);
				if (updates.length == 0)
					return stmt;
				var scope = hoistScope([stmt], prelude);
				var reads = outerReads(updates);
				var newRescue:Array<ERescueClause> = [];
				for (cl in rescue) {
					var binders = patternNames(cl.pattern, cl.varName);
					var rewritten:ERescueClause = {
						pattern: cl.pattern,
						body: ensureReturns(cl.body, updates, readsBehindBinders(binders, reads, scope), scope, binders)
					};
					if (cl.varName != null)
						rewritten.varName = cl.varName;
					newRescue.push(rewritten);
				}
				var newCatch:Array<ECatchClause> = [];
				for (cl in catchClauses) {
					var binders = patternNames(cl.pattern);
					newCatch.push({
						kind: cl.kind,
						pattern: cl.pattern,
						body: ensureReturns(cl.body, updates, readsBehindBinders(binders, reads, scope), scope, binders)
					});
				}
				var newTry = makeASTWithMeta(ETry(ensureReturns(body, updates, reads, scope, null), newRescue, newCatch, null, null), stmt.metadata, stmt.pos);
				makeHoistMatch(updates, rewriteInScope(newTry, clone(bound), true), stmt);

			default:
				stmt;
		};
	}

	/**
	 * Hoists branch updates out of a control flow whose value a match keeps.
	 *
	 * WHAT
	 * - Rewrites `r = <if/unless/case/cond>` when a branch assigns a variable
	 *   that was bound before the statement. Each branch then returns a tuple
	 *   of its value and the updated variables, and the match binds them all.
	 *
	 * WHY
	 * - A binding made inside an Elixir branch ends with that branch. The
	 *   statement form (`maybeHoistControlFlowStatement`) returns the updated
	 *   variables as the branch value. Here the branch value is already in
	 *   use, so the updates travel beside it in a tuple. Without this, later
	 *   passes drop the assignment as dead code and the program reads a stale
	 *   value. In a loop reducer the stale value is the loop state.
	 *
	 * HOW
	 * - `r = E` becomes `{r, a, b} = E'`. In `E'`, a branch that ended with
	 *   `value` ends with `{value, a, b}`. Names that the match itself binds
	 *   are not updates, because the match overwrites them.
	 * - `E` may be a block of statements, such as `_g = find(k)` followed by
	 *   `case _g do ... end`. The builder emits one when the switch subject
	 *   needs a temporary, and the printer turns a block that is still there
	 *   into `(fn -> ... end).()`. Receiver-effect lowering builds the same
	 *   closure itself for a block that declares locals. A closure cannot
	 *   rebind an outer variable, so both forms are treated as a control flow
	 *   with one branch.
	 * - The rewritten control flow goes through `rewriteInScope` again, so a
	 *   statement inside a branch that now needs the same rule gets it.
	 * - `scopeResult` is set when only one more statement follows and the
	 *   function or closure ends there. If that statement is a plain variable
	 *   or a constant, an update it does not read is dead and is left out.
	 *   This keeps `return switch e { case A: socket = f(socket); socket; ... }`
	 *   as it was: the compiler emits it as `r = case ... end` followed by
	 *   `r`, and nothing reads `socket` after that.
	 *
	 * EXAMPLES
	 * Haxe:
	 *   var out = "d";
	 *   var r = switch o { case Some(v): out = v; 1; case None: 0; };
	 *
	 * Elixir (before):
	 *   r = case o do
	 *     {:some, v} ->
	 *       out = v
	 *       1
	 *     {:none} -> 0
	 *   end
	 *
	 * Elixir (after):
	 *   {r, out} = case o do
	 *     {:some, v} ->
	 *       out = v
	 *       {1, out}
	 *     {:none} -> {0, out}
	 *   end
	 */
	static function maybeHoistControlFlowValue(stmt:ElixirAST, bound:Map<String, Bool>, prelude:Array<ElixirAST>, ?scopeResult:ElixirAST):ElixirAST {
		if (stmt == null || stmt.def == null)
			return stmt;

		var targetPattern:EPattern;
		var rhs:ElixirAST;
		switch (stmt.def) {
			case EMatch(pat, value):
				targetPattern = pat;
				rhs = value;
			case EBinary(Match, {def: EVar(name)}, value) if (isBindableName(name)):
				targetPattern = PVar(name);
				rhs = value;
			default:
				return stmt;
		}
		if (targetPattern == null || rhs == null || rhs.def == null)
			return stmt;

		var bodies = valueBranchBodies(rhs);
		if (bodies == null)
			return stmt;

		// The match overwrites its own targets after the branch ends, so a
		// branch write to one of them is never visible and is not an update.
		var targets = new Map<String, Bool>();
		bindFromPattern(targetPattern, targets);
		var updates = [
			for (name in collectAssignedToBoundVars(bodies, bound))
				if (!targets.exists(name) && !endsUnread(name, scopeResult)) name
		];
		if (updates.length == 0)
			return stmt;

		var scope = hoistScope(bodies, prelude);
		var newRhs = rewriteValueScopes(returnValueWithUpdates(rhs, updates, outerReads(updates), scope, null), bound);
		var pattern = PTuple([targetPattern].concat([for (name in updates) PVar(name)]));
		return makeASTWithMeta(EMatch(pattern, newRhs), stmt.metadata, stmt.pos);
	}

	/**
	 * True when the scope ends with `scopeResult` and that statement cannot
	 * read `name`: it is a different plain variable or a constant. Any other
	 * statement counts as a possible read.
	 */
	static function endsUnread(name:String, scopeResult:Null<ElixirAST>):Bool {
		if (scopeResult == null || scopeResult.def == null)
			return false;
		return switch (scopeResult.def) {
			case EParen(inner): endsUnread(name, inner);
			case EVar(other): other != name;
			case ENil | EAtom(_) | EInteger(_) | EFloat(_) | EBoolean(_): true;
			default: false;
		}
	}

	/**
	 * Returns the branch bodies of a value-position control flow, or null when
	 * `expr` is not one. Branch bodies are the places where a binding ends
	 * with the branch. A `case` returns itself, because its clause patterns
	 * decide which names a clause can update.
	 */
	static function valueBranchBodies(expr:ElixirAST):Null<Array<ElixirAST>> {
		if (expr == null || expr.def == null)
			return null;
		return switch (expr.def) {
			case EParen(inner): valueBranchBodies(inner);
			case EIf(_, thenB, elseB): [thenB, elseB];
			case EUnless(_, body, elseBranch): [body, elseBranch];
			case ECase(_, _): [expr];
			case ECond(clauses): [for (c in clauses) c.body];
			case EBlock(stmts) | EDo(stmts) if (stmts != null && stmts.length > 0): [expr];
			default:
				var body = immediateClosureBody(expr);
				body != null ? [body] : null;
		}
	}

	/**
	 * Returns the body of `(fn -> body end).()`, or null for any other node.
	 *
	 * The closure takes no argument and runs once, in place. For this pass it
	 * is a branch, not a callback: a write inside it is a write of the
	 * enclosing function that the closure scope would otherwise hide.
	 */
	static function immediateClosureBody(expr:ElixirAST):Null<ElixirAST> {
		if (expr == null || expr.def == null)
			return null;
		return switch (expr.def) {
			case ECall(target, "", []) if (target != null && target.def != null):
				switch (target.def) {
					case EFn([{args: [], guard: null, body: body}]): body;
					case EParen({def: EFn([{args: [], guard: null, body: body}])}): body;
					default: null;
				}
			default: null;
		}
	}

	/** Rebuilds `(fn -> ... end).()` around a new body; keeps the wrappers of `expr`. */
	static function withImmediateClosureBody(expr:ElixirAST, body:ElixirAST):ElixirAST {
		return switch (expr.def) {
			case ECall(target, name, args):
				var closure = switch (target.def) {
					case EParen(inner):
						makeASTWithMeta(EParen(makeASTWithMeta(EFn([{args: [], guard: null, body: body}]), inner.metadata, inner.pos)), target.metadata,
							target.pos);
					default:
						makeASTWithMeta(EFn([{args: [], guard: null, body: body}]), target.metadata, target.pos);
				};
				makeASTWithMeta(ECall(closure, name, args), expr.metadata, expr.pos);
			default: expr;
		}
	}

	/**
	 * Runs the scope rewrite on a control flow that `returnValueWithUpdates`
	 * built. `rewriteInScope` does not enter a closure, so the body of an
	 * immediate closure is rewritten here with the bindings of the enclosing
	 * scope, which it can read.
	 */
	static function rewriteValueScopes(expr:ElixirAST, bound:Map<String, Bool>):ElixirAST {
		return switch (expr.def) {
			case EParen(inner):
				makeASTWithMeta(EParen(rewriteValueScopes(inner, bound)), expr.metadata, expr.pos);
			default:
				var body = immediateClosureBody(expr);
				body != null ? withImmediateClosureBody(expr, rewriteInScope(body, clone(bound), true)) : rewriteInScope(expr, clone(bound), true);
		}
	}

	/**
	 * Rebuilds a value-position control flow so that every branch returns
	 * `{value, update1, update2, ...}`. `expr` must satisfy `valueBranchBodies`.
	 */
	static function returnValueWithUpdates(expr:ElixirAST, updates:Array<String>, reads:OuterReads, scope:HoistScope,
			binders:Null<Map<String, Bool>>):ElixirAST {
		inline function branch(body:ElixirAST):ElixirAST
			return ensureValueReturns(body, updates, reads, scope, binders);
		return switch (expr.def) {
			case EParen(inner):
				makeASTWithMeta(EParen(returnValueWithUpdates(inner, updates, reads, scope, binders)), expr.metadata, expr.pos);
			case EIf(cond, thenB, elseB):
				makeASTWithMeta(EIf(cond, branch(thenB), branch(elseB)), expr.metadata, expr.pos);
			case EUnless(cond, body, elseBranch):
				makeASTWithMeta(EUnless(cond, branch(body), branch(elseBranch)), expr.metadata, expr.pos);
			case ECase(subject, clauses):
				makeASTWithMeta(ECase(subject, [
					for (c in clauses) {
						var clauseBinders = patternNames(c.pattern, null, binders);
						{
							pattern: c.pattern,
							guard: c.guard,
							body: ensureValueReturns(c.body, updates, readsBehindBinders(clauseBinders, reads, scope), scope, clauseBinders)
						};
					}
				]), expr.metadata, expr.pos);
			case ECond(clauses):
				makeASTWithMeta(ECond([for (c in clauses) {condition: c.condition, body: branch(c.body)}]), expr.metadata, expr.pos);
			case EBlock(_) | EDo(_):
				// A block of statements is its own single branch.
				branch(expr);
			default:
				withImmediateClosureBody(expr, branch(immediateClosureBody(expr)));
		}
	}

	/**
	 * Returns a branch body that ends with `{value, update1, update2, ...}`.
	 *
	 * The branch value is the last expression of the body; an empty or absent
	 * body has the value `nil`, as in Elixir.
	 * - A control flow in that last position gets the tuple in each of its own
	 *   branches, so `a ? x : (b ? y : z)` needs no temporary.
	 * - A body that ends with `raise` or `throw` has no value and stays as it
	 *   is. `{raise Module, [value: x], out}` is also not valid Elixir.
	 * - Tuple elements cannot see each other's bindings. A value that itself
	 *   binds an update is therefore bound first: `v = 2` stays a statement
	 *   and the tuple reads `v`; any other such value goes through
	 *   `reflaxe_branch_value`. That temporary is read by the next expression
	 *   only, so nested branches can reuse the name.
	 */
	static function ensureValueReturns(body:ElixirAST, updates:Array<String>, reads:OuterReads, scope:HoistScope, binders:Null<Map<String, Bool>>):ElixirAST {
		var stmts:Array<ElixirAST> = [];
		var isDo = false;
		if (body != null && body.def != null) {
			switch (body.def) {
				case EBlock(inner):
					stmts = inner == null ? [] : inner.copy();
				case EDo(inner):
					stmts = inner == null ? [] : inner.copy();
					isDo = true;
				default:
					stmts = [body];
			}
		}

		var value:ElixirAST = stmts.length > 0 ? stmts.pop() : makeAST(ENil);
		if (neverReturns(value))
			return body;
		var here = readsAfterStatements(stmts, reads, scope, binders);
		stmts = here.stmts;
		if (valueBranchBodies(value) != null) {
			// A `case` in last position may bind a name that this branch must
			// return. Its captures run here, just before it.
			var inner:HoistScope = {localIds: scope.localIds, prelude: [], captured: new Map<String, String>()};
			var nested = returnValueWithUpdates(value, updates, here.reads, inner, binders);
			for (capture in inner.prelude)
				stmts.push(capture);
			stmts.push(nested);
		} else {
			var valueRead:ElixirAST = switch (value.def) {
				case EMatch(PVar(name), _) | EBinary(Match, {def: EVar(name)}, _) if (isBindableName(name)):
					here = readsAfterStatements([value], here.reads, scope, binders);
					for (stmt in here.stmts)
						stmts.push(stmt);
					makeAST(EVar(name));
				case _ if (bindsAny(value, updates)):
					stmts.push(makeAST(EMatch(PVar(BRANCH_VALUE_NAME), value)));
					makeAST(EVar(BRANCH_VALUE_NAME));
				default:
					value;
			};
			stmts.push(makeAST(ETuple([valueRead].concat([for (name in updates) makeAST(EVar(here.reads.get(name)))]))));
		}

		if (body == null || body.def == null)
			return makeAST(EBlock(stmts));
		return makeASTWithMeta(isDo ? EDo(stmts) : EBlock(stmts), body.metadata, body.pos);
	}

	/** True when `expr` leaves the branch by `raise` or `throw`, so it has no value to pair with updates. */
	static function neverReturns(expr:ElixirAST):Bool {
		return switch (expr.def) {
			case EParen(inner) if (inner != null && inner.def != null): neverReturns(inner);
			case ERaise(_, _) | EThrow(_): true;
			case ECall(null, "throw" | "raise" | "reraise" | "exit", _): true;
			default: false;
		}
	}

	/** Temporary that holds a branch value while the branch builds its result tuple. */
	static inline var BRANCH_VALUE_NAME = "reflaxe_branch_value";

	/** True when `node` binds one of `names` outside an inner closure. */
	static function bindsAny(node:ElixirAST, names:Array<String>):Bool {
		var wanted = new Map<String, Bool>();
		for (name in names)
			wanted.set(name, true);
		return collectAssignedToBoundVars([node], wanted).length > 0;
	}

	static inline function isDiscardVar(lhs:ElixirAST):Bool {
		if (lhs == null || lhs.def == null)
			return false;
		return switch (lhs.def) {
			case EVar("_"): true;
			default: false;
		}
	}

	static function isControlFlowExpr(e:ElixirAST):Bool {
		if (e == null || e.def == null)
			return false;
		var cur = e;
		while (true) {
			switch (cur.def) {
				case EParen(inner):
					cur = inner;
					continue;
				default:
					break;
			}
		}
		return switch (cur.def) {
			case EIf(_, _, _) | EUnless(_, _, _) | ECase(_, _) | ECond(_) | ETry(_, _, _, null, null): true;
			default: false;
		}
	}

	static function makeHoistMatch(updates:Array<String>, rhs:ElixirAST, originalStmt:ElixirAST):ElixirAST {
		if (updates.length == 1) {
			return makeASTWithMeta(EMatch(PVar(updates[0]), rhs), originalStmt.metadata, originalStmt.pos);
		}
		var pat = PTuple([for (n in updates) PVar(n)]);
		return makeASTWithMeta(EMatch(pat, rhs), originalStmt.metadata, originalStmt.pos);
	}

	/**
	 * Returns a branch body that ends with the outer value of each update: one
	 * variable, or a tuple of them. An absent body is just that result.
	 */
	static function ensureReturns(body:ElixirAST, updates:Array<String>, reads:OuterReads, scope:HoistScope, binders:Null<Map<String, Bool>>):ElixirAST {
		if (body == null || body.def == null)
			return makeReturnExpr([for (name in updates) reads.get(name)]);

		var isDo = false;
		var stmts:Array<ElixirAST> = switch (body.def) {
			case EBlock(inner): inner == null ? [] : inner;
			case EDo(inner):
				isDo = true;
				inner == null ? [] : inner;
			default: [body];
		};
		var here = readsAfterStatements(stmts, reads, scope, binders);
		here.stmts.push(makeReturnExpr([for (name in updates) here.reads.get(name)]));
		return makeASTWithMeta(isDo ? EDo(here.stmts) : EBlock(here.stmts), body.metadata, body.pos);
	}

	// -------------------- Outer values behind a shadow --------------------

	/** Starts one hoist: finds the locals that `bodies` declare; captures go to `prelude`. */
	static function hoistScope(bodies:Array<ElixirAST>, prelude:Array<ElixirAST>):HoistScope {
		var localIds = new Map<Int, Bool>();
		for (body in bodies)
			if (body != null)
				collectDeclaredLocals(body, localIds);
		return {localIds: localIds, prelude: prelude, captured: new Map<String, String>()};
	}

	/** At the start of a branch, each updated variable holds its own outer value. */
	static function outerReads(updates:Array<String>):OuterReads {
		var reads = new Map<String, String>();
		for (name in updates)
			reads.set(name, name);
		return reads;
	}

	/** Appends `temporary = name` to `into` and returns the new temporary. */
	static function captureOuter(name:String, into:Array<ElixirAST>):String {
		var temporary = freshCaptureName(name);
		into.push(makeAST(EMatch(PVar(temporary), makeAST(EVar(name)))));
		return temporary;
	}

	/** Starts the rewrite of one function or closure; its names are collected only if a capture needs them. */
	static function enterScope(root:ElixirAST):Void {
		scopeRoot = root;
		scopeNames = null;
		scopeTexts = null;
	}

	/**
	 * Returns a capture name, `reflaxe_outer_<name>_<n>`, that the function
	 * being rewritten does not use.
	 *
	 * A program may have a variable with exactly such a name. Binding the
	 * capture would overwrite it. The search covers every variable node and
	 * every pattern of the function, closures included. A variable can also
	 * appear only inside the text of an interpolated string or of raw Elixir
	 * code; a candidate that occurs anywhere in such a text is skipped.
	 */
	static function freshCaptureName(name:String):String {
		if (scopeNames == null) {
			var names = new Map<String, Bool>();
			var texts:Array<String> = [];
			if (scopeRoot != null)
				collectScopeNames(scopeRoot, names, texts);
			scopeNames = names;
			scopeTexts = texts;
		}
		while (true) {
			var candidate = 'reflaxe_outer_${name}_${++captureCounter}';
			var taken = scopeNames.exists(candidate);
			if (!taken) {
				for (text in scopeTexts) {
					if (text.indexOf(candidate) != -1) {
						taken = true;
						break;
					}
				}
			}
			if (!taken) {
				scopeNames.set(candidate, true);
				return candidate;
			}
		}
	}

	/** Collects the variable names and the text fragments of `root`, at any depth. */
	static function collectScopeNames(root:ElixirAST, names:Map<String, Bool>, texts:Array<String>):Void {
		ElixirASTTransformer.transformNode(root, function(node:ElixirAST):ElixirAST {
			if (node == null || node.def == null)
				return node;
			switch (node.def) {
				case EVar(name):
					names.set(name, true);
				case EString(text) | ERaw(text):
					if (text != null)
						texts.push(text);
				case EMatch(pattern, _):
					bindFromPattern(pattern, names);
				case ECase(_, clauses):
					for (clause in clauses)
						bindFromPattern(clause.pattern, names);
				case EDef(_, args, _, _) | EDefp(_, args, _, _):
					for (arg in args)
						bindFromPattern(arg, names);
				case EFn(clauses):
					for (clause in clauses)
						for (arg in clause.args)
							bindFromPattern(arg, names);
				default:
			}
			return node;
		});
	}

	/**
	 * Returns the names that a clause binds for its whole body: those of its
	 * `pattern`, the rescue variable `extraName`, and the binders of the
	 * clauses around it (`enclosing`).
	 */
	static function patternNames(pattern:EPattern, ?extraName:String, ?enclosing:Map<String, Bool>):Map<String, Bool> {
		var names = enclosing != null ? clone(enclosing) : new Map<String, Bool>();
		bindFromPattern(pattern, names);
		if (extraName != null && isBindableName(extraName))
			names.set(extraName, true);
		return names;
	}

	/**
	 * Returns where a clause reads the outer values, given the names its
	 * pattern binds.
	 *
	 * WHY
	 * - A hoisted clause ends with the value of each updated variable. A clause
	 *   whose pattern binds that name would return the pattern value instead:
	 *     var value = 100;
	 *     switch r { case Ok(value): ...; case Error(_): value = value + 1; }
	 *   The `Ok` clause must give back 100, not its payload.
	 *
	 * HOW
	 * - The outer value is captured once, before the control flow
	 *   (`reflaxe_outer_value_1 = value`), and the clause returns the capture.
	 */
	static function readsBehindBinders(binders:Map<String, Bool>, reads:OuterReads, scope:HoistScope):OuterReads {
		var result = reads;
		for (name => read in reads) {
			if (read != name || !binders.exists(name))
				continue;
			if (!scope.captured.exists(name))
				scope.captured.set(name, captureOuter(name, scope.prelude));
			if (result == reads)
				result = reads.copy();
			result.set(name, scope.captured.get(name));
		}
		return result;
	}

	/**
	 * Follows the statements of a branch and returns where the outer value of
	 * each update is at the end, with the statements to use.
	 *
	 * WHY
	 * - A `var` in a branch may reuse the name of an updated outer variable:
	 *     var v = 1;
	 *     if (c) { var v = id(5); r = v + 1; } else { v = 2; }
	 *   Both are `v` in Elixir. After `v = id(5)` the name holds the local, so
	 *   returning `v` from that branch would overwrite the outer variable.
	 *
	 * HOW
	 * - Just before such a `var`, the branch captures the outer value
	 *   (`reflaxe_outer_v_1 = v`) and returns the capture. Earlier writes of
	 *   the same branch to the outer variable are in it.
	 * - If a later statement assigns the outer variable again, the name holds
	 *   the outer value again and the branch returns the name. That needs the
	 *   Haxe identity of the write (`sourceLocal`). A name that the clause
	 *   pattern binds (`binders`) never goes back.
	 * - A plain block that is itself a statement, such as the body of an
	 *   unrolled loop or the body of a `case` arm behind its binder aliases,
	 *   prints inline and shares the scope of the branch. A `var` inside it
	 *   keeps the name after the block ends, so such blocks are followed too.
	 *   The capture still goes just before the `var`; the block that holds it
	 *   is merged into the statement list around it (see `followStatements`).
	 * - A `var` inside a nested control flow or closure ends with that Elixir
	 *   scope and is not followed here; a nested hoist handles it.
	 */
	static function readsAfterStatements(stmts:Array<ElixirAST>, reads:OuterReads, scope:HoistScope,
			binders:Null<Map<String, Bool>>):{stmts:Array<ElixirAST>, reads:OuterReads} {
		var current = reads.copy();
		return {stmts: followStatements(stmts, current, scope, binders), reads: current};
	}

	/** Does the work of `readsAfterStatements`; updates `current` in place and returns the statements to use. */
	static function followStatements(stmts:Array<ElixirAST>, current:OuterReads, scope:HoistScope, binders:Null<Map<String, Bool>>):Array<ElixirAST> {
		var out:Array<ElixirAST> = [];
		for (stmt in stmts) {
			if (stmt != null && stmt.def != null) {
				switch (stmt.def) {
					case EBlock(inner) | EDo(inner) if (inner != null):
						var capturesBefore = captureCounter;
						var followed = followStatements(inner, current, scope, binders);
						if (captureCounter == capturesBefore) {
							out.push(stmt);
						} else {
							// The block got a capture that the end of the branch reads.
							// Later cleanup passes look for the reads of a binding in
							// its own statement list, and would drop the capture as
							// unused. The block prints inline anyway, so its statements
							// move into this list.
							for (inlined in followed)
								out.push(inlined);
						}
						continue;
					default:
				}
			}
			var binder = stmt != null && stmt.def != null ? sourceBinderName(stmt) : null;
			var source = binder != null && current.exists(binder) ? sourceLocal(stmt) : null;
			if (source != null) {
				if (source.declares) {
					if (current.get(binder) == binder)
						current.set(binder, captureOuter(binder, out));
				} else if (!scope.localIds.exists(source.id) && (binders == null || !binders.exists(binder))) {
					current.set(binder, binder);
				}
			}
			out.push(stmt);
		}
		return out;
	}

	static function makeReturnExpr(names:Array<String>):ElixirAST {
		if (names.length == 1)
			return makeAST(EVar(names[0]));
		return makeAST(ETuple([for (n in names) makeAST(EVar(n))]));
	}

	static function collectAssignedToBoundVars(bodies:Array<ElixirAST>, bound:Map<String, Bool>):Array<String> {
		var found = new Map<String, Bool>();
		var ids = new Map<Int, Bool>();
		for (b in bodies)
			if (b != null)
				collectDeclaredLocals(b, ids);
		for (b in bodies)
			if (b != null)
				collectAssignedVars(b, bound, found, {ids: ids, names: new Map<String, Bool>()});

		var out = [];
		for (k in found.keys())
			out.push(k);
		out.sort(Reflect.compare);
		return out;
	}

	static function collectAssignedVars(node:ElixirAST, bound:Map<String, Bool>, out:Map<String, Bool>, locals:BranchLocals):Void {
		if (node == null || node.def == null)
			return;

		switch (node.def) {
			// Stop at inner closures; they are separate scopes.
			case EFn(_):
				return;

			// A closure that runs in place is a branch of this scope.
			case ECall(_, "", []) if (immediateClosureBody(node) != null):
				collectAssignedVars(immediateClosureBody(node), bound, out, locals);

			// A `var` takes its name over for the statements that follow it,
			// here and in nested blocks, but not in a sibling branch.
			case EBlock(stmts) | EDo(stmts):
				var scope = locals;
				if (stmts != null) {
					for (stmt in stmts) {
						collectAssignedVars(stmt, bound, out, scope);
						var declared = declaredName(stmt);
						if (declared != null && !scope.names.exists(declared)) {
							var names = clone(scope.names);
							names.set(declared, true);
							scope = {ids: scope.ids, names: names};
						}
					}
				}

			case ECase(expr, clauses):
				collectAssignedVars(expr, bound, out, locals);
				for (cl in clauses)
					collectAssignedVars(cl.body, withoutPatternBindings(bound, cl.pattern), out, locals);

			case ETry(body, rescue, catchClauses, null, null):
				collectAssignedVars(body, bound, out, locals);
				for (cl in rescue) {
					var handlerBound = withoutPatternBindings(bound, cl.pattern);
					if (cl.varName != null)
						handlerBound.remove(cl.varName);
					collectAssignedVars(cl.body, handlerBound, out, locals);
				}
				for (cl in catchClauses)
					collectAssignedVars(cl.body, withoutPatternBindings(bound, cl.pattern), out, locals);

			case EMatch(pat, rhs):
				var assigned = new Map<String, Bool>();
				bindFromPattern(pat, assigned);
				var binder = sourceBinderName(node);
				for (name in assigned.keys()) {
					if (bound.exists(name) && writesOuterVariable(name, name == binder ? sourceLocal(node) : null, locals))
						out.set(name, true);
				}
				collectAssignedVars(rhs, bound, out, locals);

			case EBinary(Match, left, rhs):
				switch (left.def) {
					case EVar(name) if (isBindableName(name)
						&& bound.exists(name)
						&& writesOuterVariable(name, sourceLocal(node), locals)):
						out.set(name, true);
					default:
				}
				collectAssignedVars(rhs, bound, out, locals);

			default:
				reflaxe.elixir.ast.ElixirASTTransformer.transformAST(node, function(n:ElixirAST):ElixirAST {
					collectAssignedVars(n, bound, out, locals);
					return n;
				});
		}
	}

	// -------------------- Branch-local variables --------------------

	/**
	 * Decides whether a branch write to `name` targets the variable that was
	 * bound before the control flow.
	 *
	 * WHY
	 * - Haxe lets a branch declare a local with the name of an outer variable:
	 *     var v = 1;
	 *     var r = if (c) { var v = id(5); v + 1; } else 0;   // outer v stays 1
	 *   Both become `v` in Elixir, where the branch scope keeps them apart.
	 *   Hoisting the inner `v` would overwrite the outer one.
	 *
	 * HOW
	 * - When the write still knows its Haxe variable (`source`), compare
	 *   identities: a declaration is never an outer write, and an assignment
	 *   is one unless it targets a local that the same branch declares.
	 * - A write without that knowledge was built by the compiler, for example
	 *   a loop result match or the rebind of `items.push(v)`. It writes
	 *   whatever its name means at that point: the local if a `var` of that
	 *   name came earlier in an enclosing statement list (`locals.names`),
	 *   the outer variable otherwise. A `var` in a sibling branch, or later
	 *   in the same branch, does not change that.
	 */
	static function writesOuterVariable(name:String, source:Null<SourceLocal>, locals:BranchLocals):Bool {
		if (source != null)
			return !source.declares && !locals.ids.exists(source.id);
		return !locals.names.exists(name);
	}

	/** Records the ids of the Haxe locals that `node` declares outside an inner closure. */
	static function collectDeclaredLocals(node:ElixirAST, ids:Map<Int, Bool>):Void {
		if (node == null || node.def == null)
			return;
		switch (node.def) {
			case EFn(_):
				return;
			case ECall(_, "", []) if (immediateClosureBody(node) != null):
				collectDeclaredLocals(immediateClosureBody(node), ids);
				return;
			case EMatch(_, _) | EBinary(Match, _, _):
				var source = sourceLocal(node);
				if (source != null && source.declares && sourceBinderName(node) != null)
					ids.set(source.id, true);
			default:
		}
		reflaxe.elixir.ast.ElixirASTTransformer.transformAST(node, function(n:ElixirAST):ElixirAST {
			collectDeclaredLocals(n, ids);
			return n;
		});
	}

	/** Returns the Elixir name that `stmt` declares as a Haxe `var`, or null. */
	static function declaredName(stmt:ElixirAST):Null<String> {
		if (stmt == null || stmt.def == null)
			return null;
		return switch (stmt.def) {
			case EMatch(_, _) | EBinary(Match, _, _): var source = sourceLocal(stmt); source != null && source.declares ? sourceBinderName(stmt) : null;
			default: null;
		}
	}

	/**
	 * Returns the Haxe local that a match writes, read from the typed
	 * expression the builder kept on the node, or null when the node has no
	 * such source (the compiler built it) or writes something else.
	 */
	static function sourceLocal(node:ElixirAST):Null<SourceLocal> {
		if (node.metadata == null || node.metadata.sourceExpr == null)
			return null;
		return switch (node.metadata.sourceExpr.expr) {
			case TVar(v, _): {declares: true, id: v.id};
			case TBinop(OpAssign, lhs, _) | TBinop(OpAssignOp(_), lhs, _) | TUnop(OpIncrement | OpDecrement, _, lhs):
				var target = lhs;
				while (true) {
					switch (target.expr) {
						case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _):
							target = inner;
							continue;
						default:
					}
					break;
				}
				switch (target.expr) {
					case TLocal(v): {declares: false, id: v.id};
					default: null;
				}
			default: null;
		}
	}

	/**
	 * Returns the Elixir name that the source of a match refers to. For
	 * `name = value` that is `name`. For `{name, update, ...} = value`, the
	 * form `maybeHoistControlFlowValue` builds, it is the first element.
	 */
	static function sourceBinderName(node:ElixirAST):Null<String> {
		return switch (node.def) {
			case EMatch(PVar(name), _) | EBinary(Match, {def: EVar(name)}, _): name;
			case EMatch(PTuple(items), _) if (items.length > 1):
				switch (items[0]) {
					case PVar(name): name;
					default: null;
				}
			default: null;
		}
	}

	// -------------------- Bound tracking --------------------

	/** Handler and case binders shadow outer names; their writes are not outer updates. */
	static function withoutPatternBindings(bound:Map<String, Bool>, pattern:EPattern):Map<String, Bool> {
		var local = clone(bound);
		var introduced = new Map<String, Bool>();
		bindFromPattern(pattern, introduced);
		for (name in introduced.keys())
			local.remove(name);
		return local;
	}

	static function bindFromStatement(stmt:ElixirAST, bound:Map<String, Bool>):Void {
		if (stmt == null || stmt.def == null)
			return;
		switch (stmt.def) {
			case EMatch(pat, _):
				bindFromPattern(pat, bound);
			case EBinary(Match, left, _):
				switch (left.def) {
					case EVar(name): if (isBindableName(name)) bound.set(name, true);
					default:
				}
			default:
		}
	}

	static function collectBoundFromArgs(args:Array<EPattern>):Map<String, Bool> {
		var m = new Map<String, Bool>();
		if (args == null)
			return m;
		for (a in args)
			bindFromPattern(a, m);
		return m;
	}

	static function bindFromPattern(p:EPattern, out:Map<String, Bool>):Void {
		if (p == null)
			return;
		switch (p) {
			case PVar(name):
				if (isBindableName(name))
					out.set(name, true);
			case PAlias(aliasName, pat):
				if (isBindableName(aliasName))
					out.set(aliasName, true);
				bindFromPattern(pat, out);
			case PTuple(items) | PList(items):
				for (i in items)
					bindFromPattern(i, out);
			case PCons(h, t):
				bindFromPattern(h, out);
				bindFromPattern(t, out);
			case PMap(fields):
				for (f in fields)
					bindFromPattern(f.value, out);
			case PStruct(_, structFields):
				for (f in structFields)
					bindFromPattern(f.value, out);
			case PBinary(segs):
				for (s in segs)
					bindFromPattern(s.pattern, out);
			case PPin(_):
				// A pin matches a prior value; it cannot introduce or update a binding.
			default:
		}
	}

	static inline function isBindableName(name:String):Bool {
		return name != null && name.length > 0 && name != "_";
	}

	static function clone(m:Map<String, Bool>):Map<String, Bool> {
		var out = new Map<String, Bool>();
		if (m != null)
			for (k in m.keys())
				out.set(k, true);
		return out;
	}
}
#end
