package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST.EAttribute;
import reflaxe.elixir.ast.ElixirAST.EBinarySegment;
import reflaxe.elixir.ast.ElixirAST.ECaseClause;
import reflaxe.elixir.ast.ElixirAST.ECatchClause;
import reflaxe.elixir.ast.ElixirAST.ECondClause;
import reflaxe.elixir.ast.ElixirAST.EFnClause;
import reflaxe.elixir.ast.ElixirAST.EGenerator;
import reflaxe.elixir.ast.ElixirAST.EImportOption;
import reflaxe.elixir.ast.ElixirAST.EKeywordPair;
import reflaxe.elixir.ast.ElixirAST.EMapPair;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.ERescueClause;
import reflaxe.elixir.ast.ElixirAST.EStructField;
import reflaxe.elixir.ast.ElixirAST.EWithClause;
import reflaxe.elixir.ast.ElixirAST.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;

/**
 * Tells whether a rebuilt AST node is only a copy of the node it replaces.
 *
 * WHAT
 * - `sameNode(original, candidate)` returns true when `candidate` has the same
 *   constructor as `original`, the same child objects, the same scalar values,
 *   the same metadata object, and the same source position.
 * - It looks one level deep only. Child nodes, patterns, and metadata must be the
 *   very same objects; arrays and clause records may be new, but each of their
 *   entries and fields must be the same object or the same scalar value.
 *
 * WHY
 * - Many transform passes rebuild every node they visit, for example
 *   `makeASTWithMeta(EBlock(statements.map(rewrite)), n.metadata, n.pos)`, even
 *   when `rewrite` changes nothing. The shared traversal engine
 *   (`ElixirASTTransformer.transformNode`) then sees a new child object and
 *   rebuilds every ancestor too. On the todo-app's `TodoLive` module, most pass
 *   runs rebuilt the whole tree this way without changing it.
 * - When this check says "only a copy", the engine keeps the original node. Its
 *   parent then sees an unchanged child and is not rebuilt either.
 *
 * HOW
 * - One exhaustive switch over `ElixirASTDef`, with no catch-all for the first
 *   node, so a new constructor fails to compile until its fields are compared.
 * - The answer can only err toward "different": a metadata record copied with
 *   equal values, an attribute record that drops an optional span, or a pattern
 *   rebuilt with equal content all count as different, and so does every
 *   `EFloat` copy (`-0.0 == 0.0` is true in Haxe, but they print differently).
 *   A false "different" only costs the rebuild that happens today.
 * - New arrays and clause records count as the same when every entry is the same
 *   object or value. This is safe only while no pass changes a payload array or a
 *   clause record in place: the kept node is the input node, so a pass that edits
 *   the arrays of a returned node, expecting its own fresh copy, would also edit
 *   the input tree.
 *
 * Why keeping the original is safe: every field a later reader can see (`def`
 * values, the metadata object, `pos`) is the same in both nodes. Only object
 * identity differs. Metadata is the same object in both, so an in-place metadata
 * write lands in the same place either way. A null metadata never matches,
 * because a later `node.metadata = {}` would then write to a node that the input
 * tree also holds.
 *
 * EXAMPLE
 * - `makeASTWithMeta(ECall(target, "put", [a, b]), n.metadata, n.pos)` built from
 *   the `target`, `a`, and `b` of `n` is a copy: `sameNode(n, copy)` is true.
 * - The same call with `"push"`, or with `makeAST(...)` (fresh, empty metadata),
 *   is not a copy.
 */
class ElixirASTShallowEquality {
	/**
	 * Returns true when `candidate` is a one-level copy of `original` that no
	 * reader can tell apart from it, except by object identity.
	 */
	public static function sameNode(original:ElixirAST, candidate:ElixirAST):Bool {
		if (original == candidate)
			return true;
		if (original == null || candidate == null)
			return false;
		if (original.metadata == null || original.metadata != candidate.metadata || original.pos != candidate.pos)
			return false;
		final left = original.def;
		final right = candidate.def;
		if (left == null || right == null)
			return false;
		return switch (left) {
			case EModule(name, attributes, body): switch (right) {
					case EModule(name2, attributes2, body2): name == name2 && sameAttributes(attributes, attributes2) && sameNodes(body, body2);
					default: false;
				}
			case EDefmodule(name, doBlock): switch (right) {
					case EDefmodule(name2, doBlock2): name == name2 && doBlock == doBlock2;
					default: false;
				}
			case EDef(name, args, guards, body): switch (right) {
					case EDef(name2, args2, guards2, body2): name == name2 && samePatterns(args, args2) && guards == guards2 && body == body2;
					default: false;
				}
			case EDefp(name, args, guards, body): switch (right) {
					case EDefp(name2, args2, guards2, body2): name == name2 && samePatterns(args, args2) && guards == guards2 && body == body2;
					default: false;
				}
			case EDefmacro(name, args, guards, body): switch (right) {
					case EDefmacro(name2, args2, guards2, body2): name == name2 && samePatterns(args, args2) && guards == guards2 && body == body2;
					default: false;
				}
			case EDefmacrop(name, args, guards, body): switch (right) {
					case EDefmacrop(name2, args2, guards2, body2): name == name2 && samePatterns(args, args2) && guards == guards2 && body == body2;
					default: false;
				}
			case ECase(expr, clauses): switch (right) {
					case ECase(expr2, clauses2): expr == expr2 && sameCaseClauses(clauses, clauses2);
					default: false;
				}
			case ECond(clauses): switch (right) {
					case ECond(clauses2): sameCondClauses(clauses, clauses2);
					default: false;
				}
			case EMatch(pattern, expr): switch (right) {
					case EMatch(pattern2, expr2): pattern == pattern2 && expr == expr2;
					default: false;
				}
			case EWith(clauses, doBlock, elseBlock): switch (right) {
					case EWith(clauses2, doBlock2, elseBlock2): sameWithClauses(clauses, clauses2) && doBlock == doBlock2 && elseBlock == elseBlock2;
					default: false;
				}
			case EIf(condition, thenBranch, elseBranch): switch (right) {
					case EIf(condition2, thenBranch2, elseBranch2): condition == condition2 && thenBranch == thenBranch2 && elseBranch == elseBranch2;
					default: false;
				}
			case EUnless(condition, body, elseBranch): switch (right) {
					case EUnless(condition2, body2, elseBranch2): condition == condition2 && body == body2 && elseBranch == elseBranch2;
					default: false;
				}
			case ETry(body, rescue, catchClauses, afterBlock, elseBlock): switch (right) {
					case ETry(body2, rescue2, catchClauses2, afterBlock2, elseBlock2):
						body == body2
						&& sameRescueClauses(rescue, rescue2)
						&& sameCatchClauses(catchClauses, catchClauses2)
						&& afterBlock == afterBlock2
						&& elseBlock == elseBlock2;
					default: false;
				}
			case ERaise(exception, attributes): switch (right) {
					case ERaise(exception2, attributes2): exception == exception2 && attributes == attributes2;
					default: false;
				}
			case EThrow(value): switch (right) {
					case EThrow(value2): value == value2;
					default: false;
				}
			case EList(elements): switch (right) {
					case EList(elements2): sameNodes(elements, elements2);
					default: false;
				}
			case ECons(head, tail): switch (right) {
					case ECons(head2, tail2): head == head2 && tail == tail2;
					default: false;
				}
			case ETuple(elements): switch (right) {
					case ETuple(elements2): sameNodes(elements, elements2);
					default: false;
				}
			case EMap(pairs): switch (right) {
					case EMap(pairs2): sameMapPairs(pairs, pairs2);
					default: false;
				}
			case EStruct(module, fields): switch (right) {
					case EStruct(module2, fields2): module == module2 && sameStructFields(fields, fields2);
					default: false;
				}
			case EStructUpdate(struct, fields): switch (right) {
					case EStructUpdate(struct2, fields2): struct == struct2 && sameStructFields(fields, fields2);
					default: false;
				}
			case EKeywordList(pairs): switch (right) {
					case EKeywordList(pairs2): sameKeywordPairs(pairs, pairs2);
					default: false;
				}
			case EBitstring(segments): switch (right) {
					case EBitstring(segments2): sameSegments(segments, segments2);
					default: false;
				}
			case ECall(target, funcName, args): switch (right) {
					case ECall(target2, funcName2, args2): target == target2 && funcName == funcName2 && sameNodes(args, args2);
					default: false;
				}
			case EMacroCall(macroName, args, doBlock): switch (right) {
					case EMacroCall(macroName2, args2, doBlock2): macroName == macroName2 && sameNodes(args, args2) && doBlock == doBlock2;
					default: false;
				}
			case ERemoteCall(module, funcName, args): switch (right) {
					case ERemoteCall(module2, funcName2, args2): module == module2 && funcName == funcName2 && sameNodes(args, args2);
					default: false;
				}
			case EPipe(leftExpr, rightExpr): switch (right) {
					case EPipe(leftExpr2, rightExpr2): leftExpr == leftExpr2 && rightExpr == rightExpr2;
					default: false;
				}
			case EBinary(op, leftExpr, rightExpr): switch (right) {
					case EBinary(op2, leftExpr2, rightExpr2): op == op2 && leftExpr == leftExpr2 && rightExpr == rightExpr2;
					default: false;
				}
			case EUnary(op, expr): switch (right) {
					case EUnary(op2, expr2): op == op2 && expr == expr2;
					default: false;
				}
			case EField(target, field): switch (right) {
					case EField(target2, field2): target == target2 && field == field2;
					default: false;
				}
			case EAccess(target, key): switch (right) {
					case EAccess(target2, key2): target == target2 && key == key2;
					default: false;
				}
			case ERange(start, end, exclusive, step): switch (right) {
					case ERange(start2, end2, exclusive2, step2): start == start2 && end == end2 && exclusive == exclusive2 && step == step2;
					default: false;
				}
			case EReceiverEffect(effect): switch (right) {
					case EReceiverEffect(effect2): effect == effect2 || (effect != null
							&& effect2 != null
							&& effect.receiver == effect2.receiver
							&& effect.operation == effect2.operation
							&& effect.resultShape == effect2.resultShape
							&& effect.valueProjection == effect2.valueProjection
							&& effect.writeback == effect2.writeback);
					default: false;
				}
			case EAtom(value): switch (right) {
					case EAtom(value2): value == value2;
					default: false;
				}
			case EString(value): switch (right) {
					case EString(value2): value == value2;
					default: false;
				}
			case EStringLiteral(value): switch (right) {
					case EStringLiteral(value2): value == value2;
					default: false;
				}
			case EInteger(value): switch (right) {
					case EInteger(value2): value == value2;
					default: false;
				}
			case EFloat(_):
				// `==` cannot tell `-0.0` from `0.0` (or match NaN), and the printer writes them
				// differently. A float copy therefore always counts as a change.
				false;
			case EBoolean(value): switch (right) {
					case EBoolean(value2): value == value2;
					default: false;
				}
			case ENil: switch (right) {
					case ENil: true;
					default: false;
				}
			case ECharlist(value): switch (right) {
					case ECharlist(value2): value == value2;
					default: false;
				}
			case EVar(name): switch (right) {
					case EVar(name2): name == name2;
					default: false;
				}
			case EPin(expr): switch (right) {
					case EPin(expr2): expr == expr2;
					default: false;
				}
			case EUnderscore: switch (right) {
					case EUnderscore: true;
					default: false;
				}
			case EFor(generators, filters, body, into, uniq): switch (right) {
					case EFor(generators2, filters2, body2, into2, uniq2):
						sameGenerators(generators, generators2)
						&& sameNodes(filters, filters2)
						&& body == body2
						&& into == into2
						&& uniq == uniq2;
					default: false;
				}
			case EFn(clauses): switch (right) {
					case EFn(clauses2): sameFnClauses(clauses, clauses2);
					default: false;
				}
			case ECapture(expr, arity): switch (right) {
					case ECapture(expr2, arity2): expr == expr2 && arity == arity2;
					default: false;
				}
			case EAlias(module, as): switch (right) {
					case EAlias(module2, as2): module == module2 && as == as2;
					default: false;
				}
			case EImport(module, only, except, warn): switch (right) {
					case EImport(module2, only2, except2, warn2): module == module2 && sameImportOptions(only,
							only2) && sameImportOptions(except, except2) && warn == warn2;
					default: false;
				}
			case EUse(module, options): switch (right) {
					case EUse(module2, options2): module == module2 && sameNodes(options, options2);
					default: false;
				}
			case ERequire(module, as): switch (right) {
					case ERequire(module2, as2): module == module2 && as == as2;
					default: false;
				}
			case EQuote(options, expr): switch (right) {
					case EQuote(options2, expr2): sameNodes(options, options2) && expr == expr2;
					default: false;
				}
			case EUnquote(expr): switch (right) {
					case EUnquote(expr2): expr == expr2;
					default: false;
				}
			case EUnquoteSplicing(expr): switch (right) {
					case EUnquoteSplicing(expr2): expr == expr2;
					default: false;
				}
			case EReceive(clauses, after): switch (right) {
					case EReceive(clauses2, after2): sameCaseClauses(clauses,
							clauses2) && (after == after2
							|| (after != null && after2 != null && after.timeout == after2.timeout && after.body == after2.body));
					default: false;
				}
			case ESend(target, message): switch (right) {
					case ESend(target2, message2): target == target2 && message == message2;
					default: false;
				}
			case EBlock(expressions): switch (right) {
					case EBlock(expressions2): sameNodes(expressions, expressions2);
					default: false;
				}
			case EParen(expr): switch (right) {
					case EParen(expr2): expr == expr2;
					default: false;
				}
			case EDo(body): switch (right) {
					case EDo(body2): sameNodes(body, body2);
					default: false;
				}
			case EModuleAttribute(name, value): switch (right) {
					case EModuleAttribute(name2, value2): name == name2 && value == value2;
					default: false;
				}
			case EModuledoc(content): switch (right) {
					case EModuledoc(content2): content == content2;
					default: false;
				}
			case EDoc(content): switch (right) {
					case EDoc(content2): content == content2;
					default: false;
				}
			case ESpec(signature): switch (right) {
					case ESpec(signature2): signature == signature2;
					default: false;
				}
			case ETypeDef(name, definition): switch (right) {
					case ETypeDef(name2, definition2): name == name2 && definition == definition2;
					default: false;
				}
			case ESigil(type, content, modifiers): switch (right) {
					case ESigil(type2, content2, modifiers2): type == type2 && content == content2 && modifiers == modifiers2;
					default: false;
				}
			case ERaw(code): switch (right) {
					case ERaw(code2): code == code2;
					default: false;
				}
			case EAssign(name): switch (right) {
					case EAssign(name2): name == name2;
					default: false;
				}
			case EFragment(tag, attributes, children): switch (right) {
					case EFragment(tag2, attributes2, children2): tag == tag2 && sameAttributes(attributes, attributes2) && sameNodes(children, children2);
					default: false;
				}
		};
	}

	static function sameNodes(left:Null<Array<ElixirAST>>, right:Null<Array<ElixirAST>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length)
			if (left[i] != right[i])
				return false;
		return true;
	}

	static function samePatterns(left:Null<Array<EPattern>>, right:Null<Array<EPattern>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length)
			if (left[i] != right[i])
				return false;
		return true;
	}

	static function sameStrings(left:Null<Array<String>>, right:Null<Array<String>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length)
			if (left[i] != right[i])
				return false;
		return true;
	}

	static function sameAttributes(left:Null<Array<EAttribute>>, right:Null<Array<EAttribute>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b
				&& (a == null
					|| b == null
					|| a.name != b.name
					|| a.value != b.value
					|| a.nameSpanStart != b.nameSpanStart
					|| a.nameSpanEnd != b.nameSpanEnd
					|| a.valueSpanStart != b.valueSpanStart
					|| a.valueSpanEnd != b.valueSpanEnd))
				return false;
		}
		return true;
	}

	static function sameCaseClauses(left:Null<Array<ECaseClause>>, right:Null<Array<ECaseClause>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b && (a == null || b == null || a.pattern != b.pattern || a.guard != b.guard || a.body != b.body))
				return false;
		}
		return true;
	}

	static function sameCondClauses(left:Null<Array<ECondClause>>, right:Null<Array<ECondClause>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b && (a == null || b == null || a.condition != b.condition || a.body != b.body))
				return false;
		}
		return true;
	}

	static function sameWithClauses(left:Null<Array<EWithClause>>, right:Null<Array<EWithClause>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b && (a == null || b == null || a.pattern != b.pattern || a.expr != b.expr))
				return false;
		}
		return true;
	}

	static function sameRescueClauses(left:Null<Array<ERescueClause>>, right:Null<Array<ERescueClause>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b && (a == null || b == null || a.pattern != b.pattern || a.varName != b.varName || a.body != b.body))
				return false;
		}
		return true;
	}

	static function sameCatchClauses(left:Null<Array<ECatchClause>>, right:Null<Array<ECatchClause>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b && (a == null || b == null || a.kind != b.kind || a.pattern != b.pattern || a.body != b.body))
				return false;
		}
		return true;
	}

	static function sameFnClauses(left:Null<Array<EFnClause>>, right:Null<Array<EFnClause>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b && (a == null || b == null || !samePatterns(a.args, b.args) || a.guard != b.guard || a.body != b.body))
				return false;
		}
		return true;
	}

	static function sameMapPairs(left:Null<Array<EMapPair>>, right:Null<Array<EMapPair>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b && (a == null || b == null || a.key != b.key || a.value != b.value))
				return false;
		}
		return true;
	}

	static function sameStructFields(left:Null<Array<EStructField>>, right:Null<Array<EStructField>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b && (a == null || b == null || a.key != b.key || a.value != b.value))
				return false;
		}
		return true;
	}

	static function sameKeywordPairs(left:Null<Array<EKeywordPair>>, right:Null<Array<EKeywordPair>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b && (a == null || b == null || a.key != b.key || a.value != b.value))
				return false;
		}
		return true;
	}

	static function sameSegments(left:Null<Array<EBinarySegment>>, right:Null<Array<EBinarySegment>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b
				&& (a == null || b == null || a.value != b.value || a.size != b.size || a.type != b.type || !sameStrings(a.modifiers, b.modifiers)))
				return false;
		}
		return true;
	}

	static function sameGenerators(left:Null<Array<EGenerator>>, right:Null<Array<EGenerator>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b && (a == null || b == null || a.pattern != b.pattern || a.expr != b.expr))
				return false;
		}
		return true;
	}

	static function sameImportOptions(left:Null<Array<EImportOption>>, right:Null<Array<EImportOption>>):Bool {
		if (left == right)
			return true;
		if (left == null || right == null || left.length != right.length)
			return false;
		for (i in 0...left.length) {
			final a = left[i];
			final b = right[i];
			if (a != b && (a == null || b == null || a.name != b.name || a.arity != b.arity))
				return false;
		}
		return true;
	}
}
#end
