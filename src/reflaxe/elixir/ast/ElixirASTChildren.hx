package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.EAttribute;
import reflaxe.elixir.ast.ElixirAST.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * Exhaustive immediate-child contract for the structural Elixir AST.
 *
 * This mapper deliberately owns structure only. It preserves metadata without
 * entering it and traverses quoted structure just like any other child. Passes
 * that stop at functions, quoted code, raw authority, or another semantic
 * boundary must express that policy in a separate scoped traversal.
 *
 * There is intentionally no catch-all case. Adding an `ElixirASTDef`
 * constructor must make this switch non-exhaustive until its child behavior is
 * declared here and its printer/legalization contract is reviewed.
 */
class ElixirASTChildren {
	/** Rebuild a node after mapping each immediate AST and pattern child once. */
	public static function mapImmediate(node:ElixirAST, mapAstChild:ElixirAST->ElixirAST, mapPatternChild:EPattern->EPattern):ElixirAST {
		if (node == null || node.def == null)
			return node;

		var changed = false;
		function mapAst(child:ElixirAST):ElixirAST {
			var mapped = mapAstChild(child);
			if (mapped != child)
				changed = true;
			return mapped;
		}
		function mapPattern(pattern:EPattern):EPattern {
			var mapped = mapPatternChild(pattern);
			if (mapped != pattern)
				changed = true;
			return mapped;
		}

		var mappedDef:ElixirASTDef = switch (node.def) {
			case EModule(name, attributes, body):
				EModule(name, attributes.map(attribute -> mapAttribute(attribute, mapAst)), body.map(mapAst));

			case EDefmodule(name, doBlock):
				EDefmodule(name, mapAst(doBlock));

			case EDef(name, args, guards, body):
				EDef(name, args.map(mapPattern), mapOptionalAst(guards, mapAst), mapAst(body));

			case EDefp(name, args, guards, body):
				EDefp(name, args.map(mapPattern), mapOptionalAst(guards, mapAst), mapAst(body));

			case EDefmacro(name, args, guards, body):
				EDefmacro(name, args.map(mapPattern), mapOptionalAst(guards, mapAst), mapAst(body));

			case EDefmacrop(name, args, guards, body):
				EDefmacrop(name, args.map(mapPattern), mapOptionalAst(guards, mapAst), mapAst(body));

			case ECase(expr, clauses):
				ECase(mapAst(expr), clauses.map(clause -> {
					pattern: mapPattern(clause.pattern),
					guard: mapOptionalAst(clause.guard, mapAst),
					body: mapAst(clause.body)
				}));

			case ECond(clauses):
				ECond(clauses.map(clause -> {
					condition: mapAst(clause.condition),
					body: mapAst(clause.body)
				}));

			case EMatch(pattern, expr):
				EMatch(mapPattern(pattern), mapAst(expr));

			case EWith(clauses, doBlock, elseBlock):
				EWith(clauses.map(clause -> {
					pattern: mapPattern(clause.pattern),
					expr: mapAst(clause.expr)
				}), mapAst(doBlock), mapOptionalAst(elseBlock, mapAst));

			case EIf(condition, thenBranch, elseBranch):
				EIf(mapAst(condition), mapAst(thenBranch), mapOptionalAst(elseBranch, mapAst));

			case EUnless(condition, body, elseBranch):
				EUnless(mapAst(condition), mapAst(body), mapOptionalAst(elseBranch, mapAst));

			case ETry(body, rescue, catchClauses, afterBlock, elseBlock):
				ETry(mapAst(body), rescue.map(clause -> {
					pattern: mapPattern(clause.pattern),
					varName: clause.varName,
					body: mapAst(clause.body)
				}), catchClauses.map(clause -> {
					kind: clause.kind,
					pattern: mapPattern(clause.pattern),
					body: mapAst(clause.body)
				}), mapOptionalAst(afterBlock, mapAst), mapOptionalAst(elseBlock, mapAst));

			case ERaise(exception, attributes):
				ERaise(mapAst(exception), mapOptionalAst(attributes, mapAst));

			case EThrow(value):
				EThrow(mapAst(value));

			case EList(elements):
				EList(elements.map(mapAst));

			case ETuple(elements):
				ETuple(elements.map(mapAst));

			case EMap(pairs):
				EMap(pairs.map(pair -> {
					key: mapAst(pair.key),
					value: mapAst(pair.value)
				}));

			case EStruct(module, fields):
				EStruct(module, fields.map(field -> {
					key: field.key,
					value: mapAst(field.value)
				}));

			case EStructUpdate(struct, fields):
				EStructUpdate(mapAst(struct), fields.map(field -> {
					key: field.key,
					value: mapAst(field.value)
				}));

			case EKeywordList(pairs):
				EKeywordList(pairs.map(pair -> {
					key: pair.key,
					value: mapAst(pair.value)
				}));

			case EBitstring(segments):
				EBitstring(segments.map(segment -> {
					value: mapAst(segment.value),
					size: mapOptionalAst(segment.size, mapAst),
					type: segment.type,
					modifiers: segment.modifiers
				}));

			case ECall(target, funcName, args):
				ECall(mapOptionalAst(target, mapAst), funcName, args.map(mapAst));

			case EMacroCall(macroName, args, doBlock):
				EMacroCall(macroName, args.map(mapAst), mapAst(doBlock));

			case ERemoteCall(module, funcName, args):
				ERemoteCall(mapAst(module), funcName, args.map(mapAst));

			case EPipe(left, right):
				EPipe(mapAst(left), mapAst(right));

			case EBinary(op, left, right):
				EBinary(op, mapAst(left), mapAst(right));

			case EUnary(op, expr):
				EUnary(op, mapAst(expr));

			case EField(target, field):
				EField(mapAst(target), field);

			case EAccess(target, key):
				EAccess(mapAst(target), mapAst(key));

			case ERange(start, end, exclusive, step):
				ERange(mapAst(start), mapAst(end), exclusive, mapOptionalAst(step, mapAst));

			case EReceiverEffect(effect):
				EReceiverEffect({
					receiver: effect.receiver,
					operation: mapAst(effect.operation),
					resultShape: effect.resultShape,
					valueProjection: effect.valueProjection,
					writeback: effect.writeback
				});

			case EAtom(value):
				EAtom(value);

			case EString(value):
				EString(value);

			case EInteger(value):
				EInteger(value);

			case EFloat(value):
				EFloat(value);

			case EBoolean(value):
				EBoolean(value);

			case ENil:
				ENil;

			case ECharlist(value):
				ECharlist(value);

			case EVar(name):
				EVar(name);

			case EPin(expr):
				EPin(mapAst(expr));

			case EUnderscore:
				EUnderscore;

			case EFor(generators, filters, body, into, uniq):
				EFor(generators.map(generator -> {
					pattern: mapPattern(generator.pattern),
					expr: mapAst(generator.expr)
				}), filters.map(mapAst), mapAst(body), mapOptionalAst(into, mapAst), uniq);

			case EFn(clauses):
				EFn(clauses.map(clause -> {
					args: clause.args.map(mapPattern),
					guard: mapOptionalAst(clause.guard, mapAst),
					body: mapAst(clause.body)
				}));

			case ECapture(expr, arity):
				ECapture(mapAst(expr), arity);

			case EAlias(module, as):
				EAlias(module, as);

			case EImport(module, only, except, warn):
				EImport(module, only, except, warn);

			case EUse(module, options):
				EUse(module, options.map(mapAst));

			case ERequire(module, as):
				ERequire(module, as);

			case EQuote(options, expr):
				EQuote(options.map(mapAst), mapAst(expr));

			case EUnquote(expr):
				EUnquote(mapAst(expr));

			case EUnquoteSplicing(expr):
				EUnquoteSplicing(mapAst(expr));

			case EReceive(clauses, after):
				EReceive(clauses.map(clause -> {
					pattern: mapPattern(clause.pattern),
					guard: mapOptionalAst(clause.guard, mapAst),
					body: mapAst(clause.body)
				}), after != null ? {
					timeout: mapAst(after.timeout),
					body: mapAst(after.body)
				} : null);

			case ESend(target, message):
				ESend(mapAst(target), mapAst(message));

			case EBlock(expressions):
				EBlock(expressions.map(mapAst));

			case EParen(expr):
				EParen(mapAst(expr));

			case EDo(body):
				EDo(body.map(mapAst));

			case EModuleAttribute(name, value):
				EModuleAttribute(name, mapAst(value));

			case EModuledoc(content):
				EModuledoc(content);

			case EDoc(content):
				EDoc(content);

			case ESpec(signature):
				ESpec(signature);

			case ETypeDef(name, definition):
				ETypeDef(name, definition);

			case ESigil(type, content, modifiers):
				ESigil(type, content, modifiers);

			case ERaw(code):
				ERaw(code);

			case EAssign(name):
				EAssign(name);

			case EFragment(tag, attributes, children):
				EFragment(tag, attributes.map(attribute -> mapAttribute(attribute, mapAst)), children.map(mapAst));
		};

		return changed ? makeASTWithMeta(mappedDef, node.metadata, node.pos) : node;
	}

	/** Visit each immediate AST and pattern child in deterministic field order. */
	public static function forEachImmediate(node:ElixirAST, visitAst:ElixirAST->Void, ?visitPattern:EPattern->Void):Void {
		mapImmediate(node, child -> {
			if (child != null)
				visitAst(child);
			return child;
		}, pattern -> {
			if (pattern != null && visitPattern != null)
				visitPattern(pattern);
			return pattern;
		});
	}

	/**
	 * Map the complete structural tree in postorder.
	 *
	 * Pattern-contained AST values join the same structural walk. Metadata stays
	 * opaque; callers that need AST-valued metadata must use a dedicated policy.
	 */
	public static function mapTree(node:ElixirAST, mapAst:ElixirAST->ElixirAST):ElixirAST {
		if (node == null || node.def == null)
			return node;

		var mappedChildren = mapImmediate(node, child -> mapTree(child, mapAst), pattern -> {
			return ElixirPatternChildren.mapTree(pattern, child -> mapTree(child, mapAst));
		});
		return mapAst(mappedChildren);
	}

	/** Walk the complete structural tree in deterministic preorder. */
	public static function walk(node:ElixirAST, visitAst:ElixirAST->Void, ?visitPattern:EPattern->Void):Void {
		if (node == null || node.def == null)
			return;

		visitAst(node);
		forEachImmediate(node, child -> walk(child, visitAst, visitPattern), pattern -> {
			ElixirPatternChildren.walk(pattern, child -> walk(child, visitAst, visitPattern), visitPattern);
		});
	}

	static inline function mapOptionalAst(node:Null<ElixirAST>, mapAst:ElixirAST->ElixirAST):Null<ElixirAST> {
		return node != null ? mapAst(node) : null;
	}

	static inline function mapAttribute(attribute:EAttribute, mapAst:ElixirAST->ElixirAST):EAttribute {
		return {
			name: attribute.name,
			value: mapAst(attribute.value),
			nameSpanStart: attribute.nameSpanStart,
			nameSpanEnd: attribute.nameSpanEnd,
			valueSpanStart: attribute.valueSpanStart,
			valueSpanEnd: attribute.valueSpanEnd
		};
	}
}
#end
