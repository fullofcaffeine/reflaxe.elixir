package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WHAT
 * - Rewrites free structured variable references without crossing lexical binders.
 *
 * WHY
 * Binder-repair passes sometimes need to replace a known missing local with a
 * case payload. A flat AST walk is unsafe because the same spelling can be bound
 * by a nested `fn`, case pattern, comprehension, or sequential assignment.
 *
 * HOW
 * - Track binders introduced by functions, clauses, comprehensions, matches, and
 *   sequential statements.
 * - Rewrite only references absent from the active scope.
 * - Preserve node metadata and positions.
 * - Fail closed on opaque raw target code; quoted interpolation expressions are
 *   the only raw shape with enough structure for a token-safe rewrite.
 *
 * EXAMPLES
 * - Replacing missing `value` with `payload` changes a free `value + 1` but leaves
 *   `fn value -> value + 1 end` untouched.
 */
class ScopedVarRewriter {
	/** Rewrite mapped free references while preserving each nested lexical binder. */
	public static function rewrite(node:ElixirAST, replacements:Map<String, String>, ?initiallyBound:Map<String, Bool>):ElixirAST {
		if (replacements == null)
			return node;
		return rewriteNode(node, replacements, cloneScope(initiallyBound));
	}

	static function rewriteNode(node:ElixirAST, replacements:Map<String, String>, scope:Map<String, Bool>):ElixirAST {
		if (node == null || node.def == null)
			return node;

		return switch (node.def) {
			case EVar(name) if (replacements.exists(name) && !scope.exists(name)):
				makeASTWithMeta(EVar(replacements.get(name)), node.metadata, node.pos);

			case EString(value):
				var rewritten = rewriteInterpolations(value, replacements, scope);
				rewritten == value ? node : makeASTWithMeta(EString(rewritten), node.metadata, node.pos);

			case ERaw(code):
				var rewritten = rewriteQuotedRaw(code, replacements, scope);
				rewritten == code ? node : makeASTWithMeta(ERaw(rewritten), node.metadata, node.pos);

			case EMatch(pattern, rhs):
				makeASTWithMeta(EMatch(pattern, rewriteNode(rhs, replacements, scope)), node.metadata, node.pos);

			case EBinary(Match, lhs, rhs):
				makeASTWithMeta(EBinary(Match, lhs, rewriteNode(rhs, replacements, scope)), node.metadata, node.pos);

			case EBlock(statements):
				makeASTWithMeta(EBlock(rewriteStatements(statements, replacements, scope)), node.metadata, node.pos);

			case EDo(statements):
				makeASTWithMeta(EDo(rewriteStatements(statements, replacements, scope)), node.metadata, node.pos);

			case EDef(name, args, guards, body):
				var functionScope = scopeFromPatterns(args);
				makeASTWithMeta(EDef(name, args, guards != null ? rewriteNode(guards, replacements, functionScope) : null,
					rewriteNode(body, replacements, functionScope)),
					node.metadata, node.pos);

			case EDefp(name, args, guards, body):
				var functionScope = scopeFromPatterns(args);
				makeASTWithMeta(EDefp(name, args, guards != null ? rewriteNode(guards, replacements, functionScope) : null,
					rewriteNode(body, replacements, functionScope)),
					node.metadata, node.pos);

			case EDefmacro(name, args, guards, body):
				var functionScope = scopeFromPatterns(args);
				makeASTWithMeta(EDefmacro(name, args, guards != null ? rewriteNode(guards, replacements, functionScope) : null,
					rewriteNode(body, replacements, functionScope)),
					node.metadata, node.pos);

			case EDefmacrop(name, args, guards, body):
				var functionScope = scopeFromPatterns(args);
				makeASTWithMeta(EDefmacrop(name, args, guards != null ? rewriteNode(guards, replacements, functionScope) : null,
					rewriteNode(body, replacements, functionScope)),
					node.metadata, node.pos);

			case EFn(clauses):
				var rewritten = [];
				for (clause in clauses) {
					var functionScope = cloneScope(scope);
					for (arg in clause.args)
						bindPattern(arg, functionScope);
					rewritten.push({
						args: clause.args,
						guard: clause.guard != null ? rewriteNode(clause.guard, replacements, functionScope) : null,
						body: rewriteNode(clause.body, replacements, functionScope)
					});
				}
				makeASTWithMeta(EFn(rewritten), node.metadata, node.pos);

			case ECase(target, clauses):
				var rewritten = [];
				for (clause in clauses) {
					var clauseScope = cloneScope(scope);
					bindPattern(clause.pattern, clauseScope);
					rewritten.push({
						pattern: clause.pattern,
						guard: clause.guard != null ? rewriteNode(clause.guard, replacements, clauseScope) : null,
						body: rewriteNode(clause.body, replacements, clauseScope)
					});
				}
				makeASTWithMeta(ECase(rewriteNode(target, replacements, scope), rewritten), node.metadata, node.pos);

			case EReceive(clauses, afterClause):
				var rewritten = [];
				for (clause in clauses) {
					var clauseScope = cloneScope(scope);
					bindPattern(clause.pattern, clauseScope);
					rewritten.push({
						pattern: clause.pattern,
						guard: clause.guard != null ? rewriteNode(clause.guard, replacements, clauseScope) : null,
						body: rewriteNode(clause.body, replacements, clauseScope)
					});
				}
				var rewrittenAfter = afterClause == null ? null : {
					timeout: rewriteNode(afterClause.timeout, replacements, scope),
					body: rewriteNode(afterClause.body, replacements, scope)
				};
				makeASTWithMeta(EReceive(rewritten, rewrittenAfter), node.metadata, node.pos);

			case EWith(clauses, doBlock, elseBlock):
				var withScope = cloneScope(scope);
				var rewrittenClauses = [];
				for (clause in clauses) {
					rewrittenClauses.push({pattern: clause.pattern, expr: rewriteNode(clause.expr, replacements, withScope)});
					bindPattern(clause.pattern, withScope);
				}
				makeASTWithMeta(EWith(rewrittenClauses, rewriteNode(doBlock, replacements, withScope),
					elseBlock != null ? rewriteNode(elseBlock, replacements, scope) : null),
					node.metadata, node.pos);

			case EFor(generators, filters, body, into, uniq):
				var forScope = cloneScope(scope);
				var rewrittenGenerators = [];
				for (generator in generators) {
					rewrittenGenerators.push({pattern: generator.pattern, expr: rewriteNode(generator.expr, replacements, forScope)});
					bindPattern(generator.pattern, forScope);
				}
				makeASTWithMeta(EFor(rewrittenGenerators, filters.map(filter -> rewriteNode(filter, replacements, forScope)),
					rewriteNode(body, replacements, forScope), into != null ? rewriteNode(into, replacements, scope) : null, uniq),
					node.metadata, node.pos);

			case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
				var rewrittenRescue = [];
				if (rescueClauses != null)
					for (clause in rescueClauses) {
						var rescueScope = cloneScope(scope);
						bindPattern(clause.pattern, rescueScope);
						if (clause.varName != null)
							rescueScope.set(clause.varName, true);
						rewrittenRescue.push({pattern: clause.pattern, varName: clause.varName, body: rewriteNode(clause.body, replacements, rescueScope)});
					}
				var rewrittenCatch = [];
				if (catchClauses != null)
					for (clause in catchClauses) {
						var catchScope = cloneScope(scope);
						bindPattern(clause.pattern, catchScope);
						rewrittenCatch.push({kind: clause.kind, pattern: clause.pattern, body: rewriteNode(clause.body, replacements, catchScope)});
					}
				makeASTWithMeta(ETry(rewriteNode(body, replacements, scope), rewrittenRescue, rewrittenCatch,
					afterBlock != null ? rewriteNode(afterBlock, replacements, scope) : null,
					elseBlock != null ? rewriteNode(elseBlock, replacements, scope) : null),
					node.metadata, node.pos);

			default:
				ElixirASTTransformer.transformAST(node, child -> rewriteNode(child, replacements, scope));
		};
	}

	static function rewriteStatements(statements:Array<ElixirAST>, replacements:Map<String, String>, parentScope:Map<String, Bool>):Array<ElixirAST> {
		var scope = cloneScope(parentScope);
		var rewritten = [];
		for (statement in statements) {
			var next = rewriteNode(statement, replacements, scope);
			rewritten.push(next);
			bindStatement(next, scope);
		}
		return rewritten;
	}

	static function rewriteQuotedRaw(code:String, replacements:Map<String, String>, scope:Map<String, Bool>):String {
		if (code == null || !looksLikeDoubleQuotedStringLiteral(code))
			return code;

		var trimmed = StringTools.trim(code);
		var start = code.indexOf(trimmed);
		var inner = trimmed.substr(1, trimmed.length - 2);
		var rewritten = rewriteInterpolations(inner, replacements, scope);
		if (rewritten == inner)
			return code;
		return code.substr(0, start) + '"' + rewritten + '"' + code.substr(start + trimmed.length);
	}

	static function rewriteInterpolations(text:String, replacements:Map<String, String>, scope:Map<String, Bool>):String {
		if (text == null || text.indexOf("#{") == -1)
			return text;

		var output = new StringBuf();
		var offset = 0;
		var cursor = 0;
		while (cursor < text.length - 1) {
			var start = text.indexOf("#{", cursor);
			if (start == -1)
				break;
			if (isEscaped(text, start)) {
				cursor = start + 2;
				continue;
			}

			var end = interpolationEnd(text, start + 2);
			if (end == -1)
				break;
			output.add(text.substr(offset, start + 2 - offset));
			output.add(rewriteInterpolationCode(text.substr(start + 2, end - start - 2), replacements, scope));
			offset = end;
			cursor = end + 1;
		}
		if (offset == 0)
			return text;
		output.add(text.substr(offset));
		return output.toString();
	}

	static function rewriteInterpolationCode(code:String, replacements:Map<String, String>, scope:Map<String, Bool>):String {
		var output = new StringBuf();
		var cursor = 0;
		while (cursor < code.length) {
			var char = code.charAt(cursor);
			if (char == '"' || char == "'") {
				var end = quotedEnd(code, cursor, char);
				output.add(code.substr(cursor, end - cursor));
				cursor = end;
				continue;
			}
			if (!isIdentifierStart(char)) {
				output.add(char);
				cursor++;
				continue;
			}

			var start = cursor++;
			while (cursor < code.length && isIdentifierChar(code.charAt(cursor)))
				cursor++;
			var name = code.substr(start, cursor - start);
			var before = start > 0 ? code.charAt(start - 1) : "";
			var after = cursor < code.length ? code.charAt(cursor) : "";
			var next = nextNonSpace(code, cursor);
			var isLocalReference = before != ":" && before != "." && before != "@" && after != ":" && next != "(";
			if (isLocalReference && replacements.exists(name) && !scope.exists(name))
				output.add(replacements.get(name));
			else
				output.add(name);
		}
		return output.toString();
	}

	static function interpolationEnd(text:String, start:Int):Int {
		var depth = 1;
		var cursor = start;
		while (cursor < text.length) {
			var char = text.charAt(cursor);
			if (char == '"' || char == "'") {
				cursor = quotedEnd(text, cursor, char);
				continue;
			}
			if (char == "{")
				depth++;
			else if (char == "}") {
				depth--;
				if (depth == 0)
					return cursor;
			}
			cursor++;
		}
		return -1;
	}

	static function quotedEnd(code:String, start:Int, quote:String):Int {
		var cursor = start + 1;
		while (cursor < code.length) {
			if (code.charAt(cursor) == "\\") {
				cursor += 2;
				continue;
			}
			if (code.charAt(cursor) == quote)
				return cursor + 1;
			cursor++;
		}
		return code.length;
	}

	static function nextNonSpace(code:String, start:Int):String {
		var cursor = start;
		while (cursor < code.length) {
			var char = code.charAt(cursor);
			if (char != " " && char != "\t" && char != "\n" && char != "\r")
				return char;
			cursor++;
		}
		return "";
	}

	static function isEscaped(text:String, position:Int):Bool {
		var slashes = 0;
		var cursor = position - 1;
		while (cursor >= 0 && text.charAt(cursor) == "\\") {
			slashes++;
			cursor--;
		}
		return slashes % 2 == 1;
	}

	static inline function looksLikeDoubleQuotedStringLiteral(code:String):Bool {
		var trimmed = StringTools.trim(code);
		return trimmed.length >= 2 && StringTools.startsWith(trimmed, '"') && StringTools.endsWith(trimmed, '"');
	}

	static inline function isIdentifierStart(char:String):Bool {
		return (char >= "A" && char <= "Z") || (char >= "a" && char <= "z") || char == "_";
	}

	static inline function isIdentifierChar(char:String):Bool {
		return isIdentifierStart(char) || (char >= "0" && char <= "9");
	}

	static function scopeFromPatterns(patterns:Array<EPattern>):Map<String, Bool> {
		var scope = new Map<String, Bool>();
		if (patterns != null)
			for (pattern in patterns)
				bindPattern(pattern, scope);
		return scope;
	}

	static function cloneScope(scope:Map<String, Bool>):Map<String, Bool> {
		var copy = new Map<String, Bool>();
		if (scope != null)
			for (name in scope.keys())
				copy.set(name, true);
		return copy;
	}

	static function bindStatement(statement:ElixirAST, scope:Map<String, Bool>):Void {
		if (statement == null || statement.def == null)
			return;
		switch (statement.def) {
			case EMatch(pattern, _):
				bindPattern(pattern, scope);
			case EBinary(Match, lhs, _):
				bindLhs(lhs, scope);
			default:
		}
	}

	static function bindLhs(lhs:ElixirAST, scope:Map<String, Bool>):Void {
		if (lhs == null || lhs.def == null)
			return;
		switch (lhs.def) {
			case EVar(name) if (name != null && name.length > 0):
				scope.set(name, true);
			case ETuple(elements) | EList(elements):
				for (element in elements)
					bindLhs(element, scope);
			case EKeywordList(pairs):
				for (pair in pairs)
					bindLhs(pair.value, scope);
			case EMap(pairs):
				for (pair in pairs)
					bindLhs(pair.value, scope);
			case EStruct(_, fields):
				for (field in fields)
					bindLhs(field.value, scope);
			case EBinary(Match, left, right):
				bindLhs(left, scope);
				bindLhs(right, scope);
			case EPin(_):
			default:
		}
	}

	static function bindPattern(pattern:EPattern, scope:Map<String, Bool>):Void {
		if (pattern == null)
			return;
		switch (pattern) {
			case PVar(name) if (name != null && name.length > 0):
				scope.set(name, true);
			case PAlias(name, inner):
				if (name != null && name.length > 0)
					scope.set(name, true);
				bindPattern(inner, scope);
			case PTuple(elements) | PList(elements):
				for (element in elements)
					bindPattern(element, scope);
			case PCons(head, tail):
				bindPattern(head, scope);
				bindPattern(tail, scope);
			case PMap(pairs):
				for (pair in pairs)
					bindPattern(pair.value, scope);
			case PStruct(_, fields):
				for (field in fields)
					bindPattern(field.value, scope);
			case PBinary(segments):
				for (segment in segments)
					bindPattern(segment.pattern, scope);
			case PPin(_):
			default:
		}
	}
}
#end
