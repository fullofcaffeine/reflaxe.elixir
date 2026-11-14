package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LinearListAppendTransforms
 *
 * WHAT
 * - Makes "create an empty array, `push` in a loop, then use it" run in time
 *   proportional to the number of items.
 * - Inside the loop the list is kept newest-first and each `push` adds one cell
 *   in front (`[item | acc]`). The list is put back in order once, where the
 *   loop ends or where a `return` inside the loop reads it.
 *
 * WHY
 * - A Haxe `Array` is a BEAM list here, and `items.push(x)` lowers to
 *   `items = items ++ [x]`. `++` copies its whole left list, so a loop that
 *   collects N items costs N squared. A JSON parser written in Haxe took 2.6 s
 *   for an array of 16,000 numbers.
 * - Hand-written Elixir adds in front and calls `Enum.reverse/1` once.
 *
 * HOW
 * - Runs last, after `ReduceWhileAccumulator_Final`, so it sees the final
 *   reducer shape of every loop. It changes two shapes.
 * - While loop: `Enum.reduce_while(Stream.iterate(...), state, fn _, pattern -> body end)`.
 *   A state variable `acc` qualifies when all of this holds:
 *   1. Its start value is the literal `[]`, or a variable that the pass has
 *      seen bound to `[]` with no later statement that names it. The list is
 *      then known to be empty, so no earlier items need a first reversal.
 *   2. Every place in `body` that names `acc` is one of:
 *      - an append `acc = acc ++ [x]` or `acc = Enum.concat(acc, [x])`, also
 *        as the last expression of a branch: `acc = if cond, do: ..., else: acc`
 *        or `{other, acc} = if cond do ... {other, acc} else ... end`;
 *      - the slot of `acc` in a `{:cont, state}` or `throw({:continue, state})`;
 *      - any read inside `{:halt, ...}` or `throw({:break, ...})`. These end
 *        the loop, so each runs at most once. The read becomes
 *        `Enum.reverse(acc)`.
 *      Any other read (for example `acc` in a condition, as a call argument,
 *      or inside a nested function) leaves the loop unchanged.
 *   3. Position decides what a piece of code means. `{:cont, ...}` and
 *      `{:halt, ...}` are loop control only as the result of the reducer; a
 *      Haxe enum value `Cont(items)` passed to a function prints the same
 *      tuple and is a normal read. `acc = ...` is accepted only as a
 *      statement; as a value, as in `f(acc = acc ++ [x])`, it would hand the
 *      newest-first list to `f`, so it leaves the loop unchanged.
 *   The source must be `Stream.iterate`, which never ends: the loop then stops
 *   only through `:halt`, where the list is put back in order.
 * - For loop: `Enum.reduce(source, start, fn item, acc -> body end)` with the
 *   same start rule, where `body` names `acc` only in appends and as its
 *   result. It becomes `Enum.reverse(Enum.reduce(source, start, fn ... [x | acc] end))`.
 *   When the body is one append it becomes `Enum.map(source, fn item -> x end)`,
 *   if the start value is the literal `[]` or the statement is
 *   `items = Enum.reduce(source, items, ...)` right after `items = []`. The
 *   pass then removes `items = []`, which nothing reads any more.
 * - The check counts every mention of `acc` in the printed body and requires
 *   the same number of rewritten places. A mention the pass does not
 *   understand (raw Elixir text, a pattern, a string) makes the counts differ,
 *   and the loop stays as it was.
 * - Why this is safe: a BEAM list is an immutable value, so the only code that
 *   can see the list is code that names `acc`. Every such place is either
 *   rewritten to keep the newest-first form or reads `Enum.reverse(acc)`,
 *   which is the original list. Aliases behave exactly as before this pass.
 *
 * LIMITS
 * - Left unchanged, and still one copy per `push`: a loop that reads the array
 *   while it runs (`items.length`, `items[i]`), an array that is not known to
 *   be empty at the loop (a parameter, a field, a second loop on one array),
 *   a `for` loop with `break`, and a `push` to an outer array from a nested
 *   loop. Task: haxe.elixir.codex-sd6.
 * - Haxe alias semantics for arrays are not changed here. The managed array
 *   work (haxe.elixir.codex-0yn.10.3.14.1) owns them.
 *
 * EXAMPLES
 * Haxe:
 *   var items = [];
 *   var i = 0;
 *   while (i < n) {
 *     items.push(i);
 *     i++;
 *   }
 *   return items;
 * Elixir (before):
 *   if (acc_i < n) do
 *     acc_items = acc_items ++ [acc_i]
 *     acc_i = acc_i + 1
 *     {:cont, {acc_items, acc_i}}
 *   else
 *     {:halt, {acc_items, acc_i}}
 *   end
 * Elixir (after):
 *   if (acc_i < n) do
 *     acc_items = [acc_i | acc_items]
 *     acc_i = acc_i + 1
 *     {:cont, {acc_items, acc_i}}
 *   else
 *     {:halt, {Enum.reverse(acc_items), acc_i}}
 *   end
 *
 * Haxe:
 *   var items = [];
 *   for (i in 0...n) items.push(i * 2);
 * Elixir (before):
 *   items = Enum.reduce(0..(n - 1)//1, items, fn i, items_acc -> Enum.concat(items_acc, [i * 2]) end)
 * Elixir (after):
 *   items = Enum.map(0..(n - 1)//1, fn i -> i * 2 end)
 *
 * Tests: test/snapshot/regression/array_push_linear_loop (interpreter results,
 * unchanged shapes, and a 200,000-item time budget).
 */
@:nullSafety(Off)
class LinearListAppendTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return walk(ast, []);
	}

	/**
	 * Rewrites the loops under `node`.
	 *
	 * `empty` lists the variables known to hold `[]` when `node` starts to run.
	 */
	static function walk(node:ElixirAST, empty:Array<String>):ElixirAST {
		if (node == null || node.def == null)
			return node;
		return switch (node.def) {
			case EBlock(statements):
				makeASTWithMeta(EBlock(walkStatements(statements, empty)), node.metadata, node.pos);
			case EDo(statements):
				makeASTWithMeta(EDo(walkStatements(statements, empty)), node.metadata, node.pos);
			case EParen(inner):
				makeASTWithMeta(EParen(walk(inner, empty)), node.metadata, node.pos);
			case EMatch(pattern, value):
				makeASTWithMeta(EMatch(pattern, walk(value, empty)), node.metadata, node.pos);
			case EBinary(Match, target, value):
				makeASTWithMeta(EBinary(Match, target, walk(value, empty)), node.metadata, node.pos);
			case EIf(condition, thenBranch, elseBranch):
				// A match in the condition is visible in both branches.
				var inBranch = withoutMentioned(empty, condition);
				makeASTWithMeta(EIf(walk(condition, empty), walk(thenBranch, inBranch), elseBranch == null ? null : walk(elseBranch, inBranch)),
					node.metadata, node.pos);
			case ECase(subject, clauses):
				var afterSubject = withoutMentioned(empty, subject);
				var newClauses = [
					for (clause in clauses) {
						var inClause = withoutNamedIn(afterSubject, ElixirASTPrinter.printPattern(clause.pattern));
						if (clause.guard != null) inClause = withoutMentioned(inClause, clause.guard);
						var copy = Reflect.copy(clause);
						copy.body = walk(clause.body, inClause);
						copy;
					}
				];
				makeASTWithMeta(ECase(walk(subject, empty), newClauses), node.metadata, node.pos);
			case ERemoteCall(module, "reduce_while", [source, start, reducer]) if (isModule(module, "Enum")):
				var inner = walk(reducer, []);
				var rewritten = isModule(calledModule(source), "Stream") ? rewriteWhile(start, inner, empty) : null;
				makeASTWithMeta(ERemoteCall(module, "reduce_while", [walk(source, []), start, rewritten != null ? rewritten : inner]), node.metadata, node.pos);
			case ERemoteCall(module, "reduce", [source, start, reducer]) if (isModule(module, "Enum")):
				var inner = walk(reducer, []);
				var newSource = walk(source, []);
				var rewritten = rewriteReduce(module, newSource, start, inner, empty, node, isEmptyList(start));
				rewritten != null ? rewritten : makeASTWithMeta(ERemoteCall(module, "reduce", [newSource, start, inner]), node.metadata, node.pos);
			default:
				// Any other node: nothing is known about what its parts bind.
				ElixirASTTransformer.transformAST(node, child -> walk(child, []));
		}
	}

	/** Walks statements in order and tracks which variables are known to hold `[]`. */
	static function walkStatements(statements:Array<ElixirAST>, empty:Array<String>):Array<ElixirAST> {
		var known = empty.copy();
		// Where this list bound a known-empty variable: `name = []` at that index.
		var boundAt = new Map<String, Int>();
		var result:Array<Null<ElixirAST>> = [];
		for (statement in statements) {
			var mapped = mapOverFreshArray(statement, known, boundAt);
			if (mapped != null) {
				// `items = []` then `items = Enum.reduce(source, items, ...)` became
				// `items = Enum.map(source, ...)`: the first binding is now unused.
				result[boundAt.get(mapped.name)] = null;
				result.push(mapped.statement);
			} else {
				result.push(walk(statement, known));
			}
			var bound = emptyListBinding(statement);
			if (bound != null) {
				if (known.indexOf(bound) < 0)
					known.push(bound);
				boundAt.set(bound, result.length - 1);
			} else {
				known = withoutMentioned(known, statement);
			}
		}
		return [for (statement in result) if (statement != null) statement];
	}

	/**
	 * Rewrites `name = Enum.reduce(source, name, fn item, acc -> acc ++ [x] end)`
	 * to `name = Enum.map(source, fn item -> x end)` when `name = []` is an
	 * earlier statement of the same list and nothing between them names it.
	 *
	 * The caller then removes `name = []`. That is safe only in this shape: the
	 * statement binds `name` again in the same list, so no later code can read
	 * the removed binding.
	 */
	static function mapOverFreshArray(statement:ElixirAST, known:Array<String>, boundAt:Map<String, Int>):Null<{name:String, statement:ElixirAST}> {
		if (statement == null || statement.def == null)
			return null;
		var name:Null<String> = null;
		var value:Null<ElixirAST> = null;
		switch (statement.def) {
			case EMatch(PVar(found), right):
				name = found;
				value = right;
			case EBinary(Match, {def: EVar(found)}, right):
				name = found;
				value = right;
			default:
		}
		if (name == null || known.indexOf(name) < 0 || !boundAt.exists(name))
			return null;
		return switch (value.def) {
			case ERemoteCall(module, "reduce", [source, start = {def: EVar(startName)}, reducer]) if (isModule(module, "Enum") && startName == name):
				if (countMentions(ElixirASTPrinter.print(source, 0), name) != 0)
					return null;
				var rewritten = rewriteReduce(module, walk(source, []), start, walk(reducer, []), known, value, true);
				if (rewritten == null || countMentions(ElixirASTPrinter.print(rewritten, 0), name) != 0)
					return null;
				var newStatement = switch (statement.def) {
					case EMatch(pattern, _): makeASTWithMeta(EMatch(pattern, rewritten), statement.metadata, statement.pos);
					case EBinary(op, target, _): makeASTWithMeta(EBinary(op, target, rewritten), statement.metadata, statement.pos);
					default: return null;
				};
				{name: name, statement: newStatement};
			default:
				null;
		}
	}

	/** Returns `name` when `statement` is exactly `name = []`. */
	static function emptyListBinding(statement:ElixirAST):Null<String> {
		if (statement == null || statement.def == null)
			return null;
		return switch (statement.def) {
			case EMatch(PVar(name), {def: EList([])}): name;
			case EBinary(Match, {def: EVar(name)}, {def: EList([])}): name;
			default: null;
		}
	}

	/** Drops every name that `node` mentions: after `node` runs, it may hold another value. */
	static function withoutMentioned(names:Array<String>, node:ElixirAST):Array<String> {
		if (names.length == 0 || node == null)
			return names;
		return withoutNamedIn(names, ElixirASTPrinter.print(node, 0));
	}

	static function withoutNamedIn(names:Array<String>, text:String):Array<String> {
		if (names.length == 0)
			return names;
		return [for (name in names) if (countMentions(text, name) == 0) name];
	}

	/**
	 * Counts the places where `name` stands as a whole word in printed Elixir.
	 *
	 * This counts more than variable reads on purpose: an atom, a field or a
	 * word in a string also counts. A surplus makes a caller keep the original
	 * code, which is always correct.
	 */
	static function countMentions(text:String, name:String):Int {
		var count = 0;
		var from = 0;
		while (true) {
			var at = text.indexOf(name, from);
			if (at < 0)
				break;
			var end = at + name.length;
			if (!(at > 0 && isWordCode(text.charCodeAt(at - 1))) && !(end < text.length && isWordCode(text.charCodeAt(end))))
				count++;
			from = end;
		}
		return count;
	}

	static inline function isWordCode(code:Int):Bool {
		return (code >= "a".code && code <= "z".code)
			|| (code >= "A".code && code <= "Z".code)
			|| (code >= "0".code && code <= "9".code)
			|| code == "_".code;
	}

	static function isModule(node:ElixirAST, name:String):Bool {
		return node != null && switch (node.def) {
			case EVar(found): found == name;
			default: false;
		}}

	static function calledModule(node:ElixirAST):Null<ElixirAST> {
		return node == null ? null : switch (node.def) {
			case ERemoteCall(module, _, _): module;
			default: null;
		}
	}

	static function isEmptyList(node:ElixirAST):Bool {
		return node != null && switch (node.def) {
			case EList([]): true;
			default: false;
		}}

	static function isKnownEmpty(start:ElixirAST, empty:Array<String>):Bool {
		return start != null && switch (start.def) {
			case EList([]): true;
			case EVar(name): empty.indexOf(name) >= 0;
			default: false;
		}}

	/**
	 * Lists each variable of a reducer state pattern with its tuple path.
	 *
	 * `{:tag, {items, index}}` gives `items` at `[1, 0]` and `index` at `[1, 1]`.
	 */
	static function stateVariables(pattern:EPattern, path:Array<Int>, out:Array<{name:String, path:Array<Int>}>):Void {
		switch (pattern) {
			case PVar(name):
				out.push({name: name, path: path});
			case PTuple(elements):
				for (i in 0...elements.length)
					stateVariables(elements[i], path.concat([i]), out);
			default:
		}
	}

	static function stateAt(state:ElixirAST, path:Array<Int>):Null<ElixirAST> {
		var current = state;
		for (index in path) {
			switch (current.def) {
				case ETuple(elements) if (index < elements.length):
					current = elements[index];
				default:
					return null;
			}
		}
		return current;
	}

	/** Rewrites the reducer of a `while` loop, or returns null when no state variable qualifies. */
	static function rewriteWhile(start:ElixirAST, reducer:ElixirAST, empty:Array<String>):Null<ElixirAST> {
		var clause = switch (reducer.def) {
			case EFn([single]) if (single.guard == null && single.args.length == 2): single;
			default: return null;
		};
		var variables = [];
		stateVariables(clause.args[1], [], variables);
		var body = clause.body;
		var changed = false;
		for (variable in variables) {
			var startValue = stateAt(start, variable.path);
			if (startValue == null || !isKnownEmpty(startValue, empty))
				continue;
			if (countMentions(ElixirASTPrinter.printPattern(clause.args[1]), variable.name) != 1)
				continue;
			var rewrite = new AppendRewrite(variable.name, variable.path);
			var newBody = rewrite.tail(body);
			if (rewrite.accepted(body)) {
				body = newBody;
				changed = true;
			}
		}
		return changed ? makeASTWithMeta(EFn([{args: clause.args, guard: null, body: body}]), reducer.metadata, reducer.pos) : null;
	}

	/** Rewrites `Enum.reduce(source, start, fn item, acc -> ... end)`, or returns null. */
	static function rewriteReduce(module:ElixirAST, source:ElixirAST, start:ElixirAST, reducer:ElixirAST, empty:Array<String>, original:ElixirAST,
			allowMap:Bool):Null<ElixirAST> {
		if (!isKnownEmpty(start, empty))
			return null;
		var clause = switch (reducer.def) {
			case EFn([single]) if (single.guard == null && single.args.length == 2): single;
			default: return null;
		};
		var name = switch (clause.args[1]) {
			case PVar(found): found;
			default: return null;
		};
		if (countMentions(ElixirASTPrinter.printPattern(clause.args[0]), name) != 0)
			return null;
		var rewrite = new AppendRewrite(name, []);
		var newBody = rewrite.append(clause.body);
		if (!rewrite.accepted(clause.body))
			return null;
		var single = singleExpression(newBody);
		switch (single.def) {
			case ECons(item, {def: EVar(tail)}) if (allowMap && tail == name):
				// One append per item, in order: this is `Enum.map/2`.
				var mapper = makeASTWithMeta(EFn([{args: [clause.args[0]], guard: null, body: item}]), reducer.metadata, reducer.pos);
				return makeASTWithMeta(ERemoteCall(module, "map", [source, mapper]), original.metadata, original.pos);
			default:
		}
		var newReducer = makeASTWithMeta(EFn([{args: clause.args, guard: null, body: newBody}]), reducer.metadata, reducer.pos);
		var reduced = makeASTWithMeta(ERemoteCall(module, "reduce", [source, start, newReducer]), original.metadata, original.pos);
		return makeAST(ERemoteCall(makeAST(EVar("Enum")), "reverse", [reduced]), original.pos);
	}

	static function singleExpression(node:ElixirAST):ElixirAST {
		return switch (node.def) {
			case EBlock([single]) | EParen(single): singleExpression(single);
			default: node;
		}
	}
}

/**
 * One attempt to keep list variable `name` newest-first inside a reducer body.
 *
 * It rewrites every place it understands and counts them. `accepted` compares
 * that count with the number of mentions in the printed body; see the pass
 * documentation above.
 *
 * The rewrite follows where the value of each expression goes, because the
 * same text means different things in different places:
 * - `tail`: the expression is the result of the `reduce_while` reducer. Only
 *   here is `{:cont, state}` or `{:halt, state}` loop control. Elsewhere such
 *   a tuple is program data, for example a Haxe enum value `Cont(items)`.
 * - `discard`: a statement whose value nothing reads. Only here may
 *   `acc = ...` assign the list, because the value of an assignment is the
 *   newest-first list and must not reach other code.
 * - `value`: the value is read by other code. The list may appear only where
 *   the loop ends, as `Enum.reverse(acc)`.
 * - `append`: the value becomes the list itself.
 */
@:nullSafety(Off)
private class AppendRewrite {
	final name:String;

	/** Tuple path of the variable inside the reducer state. Empty when the state is the variable. */
	final path:Array<Int>;

	var handled = 0;
	var appends = 0;
	var failed = false;

	public function new(name:String, path:Array<Int>) {
		this.name = name;
		this.path = path;
	}

	/** True when every mention of the variable was rewritten and at least one was an append. */
	public function accepted(originalBody:ElixirAST):Bool {
		return !failed && appends > 0 && handled == mentions(ElixirASTPrinter.print(originalBody, 0));
	}

	function mentions(text:String):Int {
		return @:privateAccess LinearListAppendTransforms.countMentions(text, name);
	}

	function isName(node:ElixirAST):Bool {
		return node != null && switch (node.def) {
			case EVar(found): found == name;
			default: false;
		}}

	static function isAtom(node:ElixirAST, text:String):Bool {
		return node != null && switch (node.def) {
			case EAtom(atom): atom == text;
			default: false;
		}}

	/** Rewrites the body of a `reduce_while` reducer: its value is the loop control tuple. */
	public function tail(node:ElixirAST):ElixirAST {
		if (node == null || node.def == null)
			return node;
		return switch (node.def) {
			case ETuple([tag, state]) if (isAtom(tag, "cont")):
				makeASTWithMeta(ETuple([tag, slot(state, 0)]), node.metadata, node.pos);
			case ETuple([tag, state]) if (isAtom(tag, "halt")):
				// The loop ends here, so a read may pay for one `Enum.reverse/1`.
				makeASTWithMeta(ETuple([tag, value(state, true)]), node.metadata, node.pos);
			default:
				var control = loopThrow(node);
				control != null ? control : structure(node, tail, tail);
		}
	}

	/** Rewrites a statement whose value nothing reads. */
	function discard(node:ElixirAST):ElixirAST {
		if (node == null || node.def == null)
			return node;
		return switch (node.def) {
			case EMatch(PVar(found), right) if (found == name):
				handled++;
				makeASTWithMeta(EMatch(PVar(found), append(right)), node.metadata, node.pos);
			case EBinary(Match, target, right) if (isName(target)):
				handled++;
				makeASTWithMeta(EBinary(Match, target, append(right)), node.metadata, node.pos);
			case EMatch(pattern = PTuple(parts), right) if (tupleSlot(pattern) >= 0):
				handled++;
				makeASTWithMeta(EMatch(pattern, tuple(right, tupleSlot(pattern), parts.length)), node.metadata, node.pos);
			default:
				var control = loopThrow(node);
				control != null ? control : structure(node, discard, discard);
		}
	}

	/**
	 * Rewrites `throw({:break, state})` and `throw({:continue, state})`, which
	 * the loop's own `catch` turns into `:halt` and `:cont`. Returns null for
	 * any other node.
	 */
	function loopThrow(node:ElixirAST):Null<ElixirAST> {
		return switch (node.def) {
			case EThrow({def: ETuple([tag, state]), metadata: tupleMeta, pos: tuplePos}) if (isAtom(tag, "continue")):
				makeASTWithMeta(EThrow(makeASTWithMeta(ETuple([tag, slot(state, 0)]), tupleMeta, tuplePos)), node.metadata, node.pos);
			case EThrow({def: ETuple([tag, state]), metadata: tupleMeta, pos: tuplePos}) if (isAtom(tag, "break")):
				makeASTWithMeta(EThrow(makeASTWithMeta(ETuple([tag, value(state, true)]), tupleMeta, tuplePos)), node.metadata, node.pos);
			default:
				null;
		}
	}

	/**
	 * Rewrites a block, `if`, `case`, `cond` or `try`: `inner` handles each
	 * statement before the last one of a block, `last` handles the expression
	 * that gives the construct its value, and conditions are values. Any other
	 * node is a value.
	 */
	function structure(node:ElixirAST, inner:ElixirAST->ElixirAST, last:ElixirAST->ElixirAST):ElixirAST {
		return switch (node.def) {
			case EBlock(statements) if (statements.length > 0):
				makeASTWithMeta(EBlock(sequence(statements, last)), node.metadata, node.pos);
			case EDo(statements) if (statements.length > 0):
				makeASTWithMeta(EDo(sequence(statements, last)), node.metadata, node.pos);
			case EParen(inside):
				makeASTWithMeta(EParen(last(inside)), node.metadata, node.pos);
			case EIf(condition, thenBranch, elseBranch):
				makeASTWithMeta(EIf(value(condition, false), last(thenBranch), elseBranch == null ? null : last(elseBranch)), node.metadata, node.pos);
			case ECase(subject, clauses):
				var newSubject = value(subject, false);
				var newClauses = [
					for (clause in clauses) {
						var copy = Reflect.copy(clause);
						if (clause.guard != null) copy.guard = value(clause.guard, false);
						copy.body = last(clause.body);
						copy;
					}
				];
				makeASTWithMeta(ECase(newSubject, newClauses), node.metadata, node.pos);
			case ECond(clauses):
				makeASTWithMeta(ECond([
					for (clause in clauses)
						{condition: value(clause.condition, false), body: last(clause.body)}
				]), node.metadata, node.pos);
			case ETry(body, rescue, catchClauses, afterBlock, elseBlock):
				var newBody = last(body);
				var newRescue = [
					for (clause in rescue) {
						var copy = Reflect.copy(clause);
						copy.body = last(clause.body);
						copy;
					}
				];
				var newCatch = [
					for (clause in catchClauses) {
						var copy = Reflect.copy(clause);
						copy.body = last(clause.body);
						copy;
					}
				];
				makeASTWithMeta(ETry(newBody, newRescue, newCatch, afterBlock == null ? null : discard(afterBlock),
					elseBlock == null ? null : value(elseBlock, false)),
					node.metadata, node.pos);
			default:
				value(node, false);
		}
	}

	/** Statements of a block: every one but the last is discarded. */
	function sequence(statements:Array<ElixirAST>, last:ElixirAST->ElixirAST):Array<ElixirAST> {
		var lastIndex = statements.length - 1;
		return [
			for (i in 0...statements.length)
				i == lastIndex ? last(statements[i]) : discard(statements[i])
		];
	}

	/**
	 * Rewrites an expression whose value other code reads.
	 *
	 * `leaving` is true inside `{:halt, ...}` and `throw({:break, ...})`: the
	 * loop ends there, so a read becomes `Enum.reverse(acc)`. While the loop
	 * runs, a read is left alone and not counted, which refuses the attempt.
	 */
	function value(node:ElixirAST, leaving:Bool):ElixirAST {
		if (node == null || node.def == null)
			return node;
		return switch (node.def) {
			case EVar(found) if (found == name):
				if (!leaving)
					return node;
				handled++;
				makeAST(ERemoteCall(makeAST(EVar("Enum")), "reverse", [node]), node.pos);
			case EFn(_):
				// A nested function may run many times; a mention inside it refuses the attempt.
				node;
			case EBinary(Match, target, _) if (mentions(ElixirASTPrinter.print(target, 0)) > 0):
				// `f(acc = acc ++ [x])`: the assignment's value would be the newest-first list.
				failed = true;
				node;
			default:
				ElixirASTTransformer.transformAST(node, child -> value(child, leaving));
		}
	}

	/** Rewrites the next loop state: the slot of the variable keeps the newest-first list. */
	function slot(state:ElixirAST, depth:Int):ElixirAST {
		if (depth == path.length)
			return mentions(ElixirASTPrinter.print(state, 0)) == 0 ? state : append(state);
		return switch (state.def) {
			case ETuple(elements) if (path[depth] < elements.length):
				var index = path[depth];
				makeASTWithMeta(ETuple([
					for (i in 0...elements.length)
						i == index ? slot(elements[i], depth + 1) : value(elements[i], false)
				]), state.metadata, state.pos);
			default:
				value(state, false);
		}
	}

	/**
	 * Rewrites an expression whose value becomes the list: the variable itself,
	 * an append of one element, or a block, `if` or `case` whose last
	 * expressions are such values.
	 */
	public function append(node:ElixirAST):ElixirAST {
		if (node == null || node.def == null) {
			failed = true;
			return node;
		}
		return switch (node.def) {
			case EVar(found) if (found == name):
				handled++;
				node;
			case EBinary(Concat, list, {def: EList([item])}) if (isName(list)):
				cons(node, list, item);
			case ERemoteCall({def: EVar("Enum")}, "concat", [list, {def: EList([item])}]) if (isName(list)):
				cons(node, list, item);
			default:
				branches(node, append);
		}
	}

	/**
	 * Rewrites an expression whose value is a tuple that holds the list at
	 * `index`, as in `{other, acc} = if cond do ... {other, acc} else ... end`.
	 */
	function tuple(node:ElixirAST, index:Int, size:Int):ElixirAST {
		if (node == null || node.def == null) {
			failed = true;
			return node;
		}
		return switch (node.def) {
			case ETuple(elements) if (elements.length == size):
				makeASTWithMeta(ETuple([
					for (i in 0...size)
						i == index ? append(elements[i]) : value(elements[i], false)
				]), node.metadata, node.pos);
			default:
				branches(node, inner -> tuple(inner, index, size));
		}
	}

	/**
	 * Applies `last` to the final expression of each branch of a block, `if`
	 * or `case`. Every branch must give a value, so an `if` needs its `else`,
	 * and any other node refuses the attempt.
	 */
	function branches(node:ElixirAST, last:ElixirAST->ElixirAST):ElixirAST {
		return switch (node.def) {
			case EBlock(statements) | EDo(statements) if (statements.length > 0):
				structure(node, discard, last);
			case EParen(_) | ECase(_, _):
				structure(node, discard, last);
			case EIf(_, _, elseBranch) if (elseBranch != null):
				structure(node, discard, last);
			default:
				failed = true;
				node;
		}
	}

	/** Returns the place of the variable in a tuple pattern that names it once, or -1. */
	function tupleSlot(pattern:EPattern):Int {
		return switch (pattern) {
			case PTuple(parts): var slot = -1; for (i in 0...parts.length) {
					switch (parts[i]) {
						case PVar(found) if (found == name): slot = i;
						default:
					}
				} slot >= 0 && mentions(ElixirASTPrinter.printPattern(pattern)) == 1 ? slot : -1;
			default: -1;
		}
	}

	function cons(original:ElixirAST, list:ElixirAST, item:ElixirAST):ElixirAST {
		handled++;
		appends++;
		return makeASTWithMeta(ECons(value(item, false), list), original.metadata, original.pos);
	}
}
#end
