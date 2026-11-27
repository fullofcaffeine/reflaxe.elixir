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
					case EModule(otherName, otherAttributes, otherBody): name == otherName && sameAttributes(attributes,
							otherAttributes) && sameNodes(body, otherBody);
					default: false;
				}
			case EDefmodule(name, doBlock): switch (right) {
					case EDefmodule(otherName, otherDoBlock): name == otherName && doBlock == otherDoBlock;
					default: false;
				}
			case EDef(name, args, guards, body): switch (right) {
					case EDef(otherName, otherArgs, otherGuards, otherBody): name == otherName && samePatterns(args,
							otherArgs) && guards == otherGuards && body == otherBody;
					default: false;
				}
			case EDefp(name, args, guards, body): switch (right) {
					case EDefp(otherName, otherArgs, otherGuards, otherBody): name == otherName && samePatterns(args,
							otherArgs) && guards == otherGuards && body == otherBody;
					default: false;
				}
			case EDefmacro(name, args, guards, body): switch (right) {
					case EDefmacro(otherName, otherArgs, otherGuards, otherBody): name == otherName && samePatterns(args,
							otherArgs) && guards == otherGuards && body == otherBody;
					default: false;
				}
			case EDefmacrop(name, args, guards, body): switch (right) {
					case EDefmacrop(otherName, otherArgs, otherGuards, otherBody): name == otherName && samePatterns(args,
							otherArgs) && guards == otherGuards && body == otherBody;
					default: false;
				}
			case ECase(expr, clauses): switch (right) {
					case ECase(otherExpr, otherClauses): expr == otherExpr && sameCaseClauses(clauses, otherClauses);
					default: false;
				}
			case ECond(clauses): switch (right) {
					case ECond(otherClauses): sameCondClauses(clauses, otherClauses);
					default: false;
				}
			case EMatch(pattern, expr): switch (right) {
					case EMatch(otherPattern, otherExpr): pattern == otherPattern && expr == otherExpr;
					default: false;
				}
			case EWith(clauses, doBlock, elseBlock): switch (right) {
					case EWith(otherClauses, otherDoBlock, otherElseBlock): sameWithClauses(clauses,
							otherClauses) && doBlock == otherDoBlock && elseBlock == otherElseBlock;
					default: false;
				}
			case EIf(condition, thenBranch, elseBranch): switch (right) {
					case EIf(otherCondition, otherThenBranch, otherElseBranch): condition == otherCondition && thenBranch == otherThenBranch && elseBranch == otherElseBranch;
					default: false;
				}
			case EUnless(condition, body, elseBranch): switch (right) {
					case EUnless(otherCondition, otherBody, otherElseBranch): condition == otherCondition && body == otherBody && elseBranch == otherElseBranch;
					default: false;
				}
			case ETry(body, rescue, catchClauses, afterBlock, elseBlock): switch (right) {
					case ETry(otherBody, otherRescue, otherCatchClauses, otherAfterBlock, otherElseBlock):
						body == otherBody
						&& sameRescueClauses(rescue, otherRescue)
						&& sameCatchClauses(catchClauses, otherCatchClauses)
						&& afterBlock == otherAfterBlock
						&& elseBlock == otherElseBlock;
					default: false;
				}
			case ERaise(exception, attributes): switch (right) {
					case ERaise(otherException, otherAttributes): exception == otherException && attributes == otherAttributes;
					default: false;
				}
			case EThrow(value): switch (right) {
					case EThrow(otherValue): value == otherValue;
					default: false;
				}
			case EList(elements): switch (right) {
					case EList(otherElements): sameNodes(elements, otherElements);
					default: false;
				}
			case ECons(head, tail): switch (right) {
					case ECons(otherHead, otherTail): head == otherHead && tail == otherTail;
					default: false;
				}
			case ETuple(elements): switch (right) {
					case ETuple(otherElements): sameNodes(elements, otherElements);
					default: false;
				}
			case EMap(pairs): switch (right) {
					case EMap(otherPairs): sameMapPairs(pairs, otherPairs);
					default: false;
				}
			case EStruct(module, fields): switch (right) {
					case EStruct(otherModule, otherFields): module == otherModule && sameStructFields(fields, otherFields);
					default: false;
				}
			case EStructUpdate(struct, fields): switch (right) {
					case EStructUpdate(otherStruct, otherFields): struct == otherStruct && sameStructFields(fields, otherFields);
					default: false;
				}
			case EKeywordList(pairs): switch (right) {
					case EKeywordList(otherPairs): sameKeywordPairs(pairs, otherPairs);
					default: false;
				}
			case EBitstring(segments): switch (right) {
					case EBitstring(otherSegments): sameSegments(segments, otherSegments);
					default: false;
				}
			case ECall(target, funcName, args): switch (right) {
					case ECall(otherTarget, otherFuncName, otherArgs): target == otherTarget && funcName == otherFuncName && sameNodes(args, otherArgs);
					default: false;
				}
			case EMacroCall(macroName, args, doBlock): switch (right) {
					case EMacroCall(otherMacroName, otherArgs, otherDoBlock): macroName == otherMacroName && sameNodes(args,
							otherArgs) && doBlock == otherDoBlock;
					default: false;
				}
			case ERemoteCall(module, funcName, args): switch (right) {
					case ERemoteCall(otherModule, otherFuncName, otherArgs): module == otherModule && funcName == otherFuncName && sameNodes(args, otherArgs);
					default: false;
				}
			case EPipe(leftExpr, rightExpr): switch (right) {
					case EPipe(otherLeftExpr, otherRightExpr): leftExpr == otherLeftExpr && rightExpr == otherRightExpr;
					default: false;
				}
			case EBinary(op, leftExpr, rightExpr): switch (right) {
					case EBinary(otherOp, otherLeftExpr, otherRightExpr): op == otherOp && leftExpr == otherLeftExpr && rightExpr == otherRightExpr;
					default: false;
				}
			case EUnary(op, expr): switch (right) {
					case EUnary(otherOp, otherExpr): op == otherOp && expr == otherExpr;
					default: false;
				}
			case EField(target, field): switch (right) {
					case EField(otherTarget, otherField): target == otherTarget && field == otherField;
					default: false;
				}
			case EAccess(target, key): switch (right) {
					case EAccess(otherTarget, otherKey): target == otherTarget && key == otherKey;
					default: false;
				}
			case ERange(start, end, exclusive, step): switch (right) {
					case ERange(otherStart, otherEnd, otherExclusive, otherStep): start == otherStart && end == otherEnd && exclusive == otherExclusive && step == otherStep;
					default: false;
				}
			case EReceiverEffect(effect): switch (right) {
					case EReceiverEffect(otherEffect): effect == otherEffect || (effect != null
							&& otherEffect != null
							&& effect.receiver == otherEffect.receiver
							&& effect.operation == otherEffect.operation
							&& effect.resultShape == otherEffect.resultShape
							&& effect.valueProjection == otherEffect.valueProjection
							&& effect.writeback == otherEffect.writeback);
					default: false;
				}
			case EAtom(value): switch (right) {
					case EAtom(otherValue): value == otherValue;
					default: false;
				}
			case EString(value): switch (right) {
					case EString(otherValue): value == otherValue;
					default: false;
				}
			case EStringLiteral(value): switch (right) {
					case EStringLiteral(otherValue): value == otherValue;
					default: false;
				}
			case EInteger(value): switch (right) {
					case EInteger(otherValue): value == otherValue;
					default: false;
				}
			case EFloat(_):
				// `==` cannot tell `-0.0` from `0.0` (or match NaN), and the printer writes them
				// differently. A float copy therefore always counts as a change.
				false;
			case EBoolean(value): switch (right) {
					case EBoolean(otherValue): value == otherValue;
					default: false;
				}
			case ENil: switch (right) {
					case ENil: true;
					default: false;
				}
			case ECharlist(value): switch (right) {
					case ECharlist(otherValue): value == otherValue;
					default: false;
				}
			case EVar(name): switch (right) {
					case EVar(otherName): name == otherName;
					default: false;
				}
			case EPin(expr): switch (right) {
					case EPin(otherExpr): expr == otherExpr;
					default: false;
				}
			case EUnderscore: switch (right) {
					case EUnderscore: true;
					default: false;
				}
			case EFor(generators, filters, body, into, uniq): switch (right) {
					case EFor(otherGenerators, otherFilters, otherBody, otherInto, otherUniq):
						sameGenerators(generators, otherGenerators)
						&& sameNodes(filters, otherFilters)
						&& body == otherBody
						&& into == otherInto
						&& uniq == otherUniq;
					default: false;
				}
			case EFn(clauses): switch (right) {
					case EFn(otherClauses): sameFnClauses(clauses, otherClauses);
					default: false;
				}
			case ECapture(expr, arity): switch (right) {
					case ECapture(otherExpr, otherArity): expr == otherExpr && arity == otherArity;
					default: false;
				}
			case EAlias(module, as): switch (right) {
					case EAlias(otherModule, otherAs): module == otherModule && as == otherAs;
					default: false;
				}
			case EImport(module, only, except, warn): switch (right) {
					case EImport(otherModule, otherOnly, otherExcept, otherWarn):
						module == otherModule
						&& sameImportOptions(only, otherOnly)
						&& sameImportOptions(except, otherExcept)
						&& warn == otherWarn;
					default: false;
				}
			case EUse(module, options): switch (right) {
					case EUse(otherModule, otherOptions): module == otherModule && sameNodes(options, otherOptions);
					default: false;
				}
			case ERequire(module, as): switch (right) {
					case ERequire(otherModule, otherAs): module == otherModule && as == otherAs;
					default: false;
				}
			case EQuote(options, expr): switch (right) {
					case EQuote(otherOptions, otherExpr): sameNodes(options, otherOptions) && expr == otherExpr;
					default: false;
				}
			case EUnquote(expr): switch (right) {
					case EUnquote(otherExpr): expr == otherExpr;
					default: false;
				}
			case EUnquoteSplicing(expr): switch (right) {
					case EUnquoteSplicing(otherExpr): expr == otherExpr;
					default: false;
				}
			case EReceive(clauses, after): switch (right) {
					case EReceive(otherClauses, otherAfter): sameCaseClauses(clauses,
							otherClauses) && (after == otherAfter
							|| (after != null && otherAfter != null && after.timeout == otherAfter.timeout && after.body == otherAfter.body));
					default: false;
				}
			case ESend(target, message): switch (right) {
					case ESend(otherTarget, otherMessage): target == otherTarget && message == otherMessage;
					default: false;
				}
			case EBlock(expressions): switch (right) {
					case EBlock(otherExpressions): sameNodes(expressions, otherExpressions);
					default: false;
				}
			case EParen(expr): switch (right) {
					case EParen(otherExpr): expr == otherExpr;
					default: false;
				}
			case EDo(body): switch (right) {
					case EDo(otherBody): sameNodes(body, otherBody);
					default: false;
				}
			case EModuleAttribute(name, value): switch (right) {
					case EModuleAttribute(otherName, otherValue): name == otherName && value == otherValue;
					default: false;
				}
			case EModuledoc(content): switch (right) {
					case EModuledoc(otherContent): content == otherContent;
					default: false;
				}
			case EDoc(content): switch (right) {
					case EDoc(otherContent): content == otherContent;
					default: false;
				}
			case ESpec(signature): switch (right) {
					case ESpec(otherSignature): signature == otherSignature;
					default: false;
				}
			case ETypeDef(name, definition): switch (right) {
					case ETypeDef(otherName, otherDefinition): name == otherName && definition == otherDefinition;
					default: false;
				}
			case ESigil(type, content, modifiers): switch (right) {
					case ESigil(otherType, otherContent, otherModifiers): type == otherType && content == otherContent && modifiers == otherModifiers;
					default: false;
				}
			case ERaw(code): switch (right) {
					case ERaw(otherCode): code == otherCode;
					default: false;
				}
			case EAssign(name): switch (right) {
					case EAssign(otherName): name == otherName;
					default: false;
				}
			case EFragment(tag, attributes, children): switch (right) {
					case EFragment(otherTag, otherAttributes, otherChildren): tag == otherTag && sameAttributes(attributes,
							otherAttributes) && sameNodes(children, otherChildren);
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
