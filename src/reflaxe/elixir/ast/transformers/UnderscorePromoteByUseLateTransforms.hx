package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ASTUtils;

/**
	* UnderscorePromoteByUseLateTransforms
	*
	* WHAT
	* - Late, linear pass that promotes underscored locals ("_foo") to their
	*   base name ("foo") when the base is referenced in the same function body.
	*
	* WHY
	* - Some hygiene passes underscore unused binds, but later rewrites introduce
	*   references to the base name. Without promotion, Elixir ends up with
	*   undefined variables (e.g., `_users` bound, but `users` referenced).
	* - Previous O(n²) RefDeclAlignment caused hangs; this provides a focused,
	*   O(n) safety net for the common underscored-decl/used-base shape.
	*
	* HOW
	* - For each def/defp:
	*   1) Collect referenced identifiers (EVar) in the body; record their bases
	*      (strip leading underscore and trailing digits).
	*   2) Rewrite decls and refs:
	*      - If a name starts with "_" and its base is in the referenced set,
	*        drop the underscore.
	*      - Applies to vars in match LHS, patterns, and references.
	* - Ignores atoms/module aliases by requiring lowercase initial char.

	*
	* EXAMPLES
	* - Covered by snapshot tests under `test/snapshot/**`.
 */
class UnderscorePromoteByUseLateTransforms {
	public static function resultBinderPass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(node:ElixirAST):ElixirAST {
			return switch (node.def) {
				case EBlock(statements):
					makeASTWithMeta(EBlock(promoteResultBindersUsedLater(statements)), node.metadata, node.pos);
				case EDo(statements):
					makeASTWithMeta(EDo(promoteResultBindersUsedLater(statements)), node.metadata, node.pos);
				default:
					node;
			};
		});
	}

	public static function promotePass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(node:ElixirAST):ElixirAST {
			return switch (node.def) {
				case EBlock(statements):
					makeASTWithMeta(EBlock(promoteResultBindersUsedLater(statements)), node.metadata, node.pos);
				case EDo(statements):
					makeASTWithMeta(EDo(promoteResultBindersUsedLater(statements)), node.metadata, node.pos);
				case EDef(name, params, guards, body):
					var refs = collectRefs(body);
					var newBody = rewrite(body, refs);
					makeASTWithMeta(EDef(name, params, guards, newBody), node.metadata, node.pos);
				case EDefp(name, params, guards, body):
					var refs = collectRefs(body);
					var newBody = rewrite(body, refs);
					makeASTWithMeta(EDefp(name, params, guards, newBody), node.metadata, node.pos);
				default:
					node;
			}
		});
	}

	/**
	 * Restore an underscored result binder when a later statement reads its exact base name.
	 *
	 * Loop-result hygiene can see only the loop expression and rename `{items, index}` to
	 * `{_items, _index}`. A surrounding expression can still return `items`. Elixir then reads
	 * the stale pre-loop value. This block-local check promotes only binders with a later exact
	 * reference, so genuine unused tuple results remain underscored.
	 */
	static function promoteResultBindersUsedLater(statements:Array<ElixirAST>):Array<ElixirAST> {
		if (statements == null || statements.length < 2)
			return statements;

		var output = statements.copy();
		var remove = new Map<Int, Bool>();
		for (index in 0...output.length - 1) {
			var statement = output[index];
			output[index] = switch (statement.def) {
				case EMatch(pattern, rhs):
					var alias = emptyArrayReducerAlias(pattern, rhs, output, index);
					if (alias != null)
						remove.set(index + 1, true);
					var rewritten = alias != null ? replaceFirstCompilerTemp(pattern, alias) : promotePatternByLaterUse(pattern, output, index + 1);
					if (index > 0 && reduceWhileStartsWithEmptyList(rhs)) {
						var resultName = firstPatternName(rewritten);
						var seedIndex = findRedundantEmptySeed(output, index, resultName);
						if (seedIndex >= 0)
							remove.set(seedIndex, true);
					}
					rewritten == pattern ? statement : makeASTWithMeta(EMatch(rewritten, rhs), statement.metadata, statement.pos);
				default:
					statement;
			};
		}
		return [for (index in 0...output.length) if (!remove.exists(index)) output[index]];
	}

	/**
	 * Recover a named array-comprehension result from Haxe's reused `g` temp.
	 *
	 * Haxe can lower `var values = [for (...) value]` to an empty `g`, a reducer
	 * result bound as `_g`, and then `values = []`. The last assignment aliases
	 * the initializer instead of the reducer result. This repair applies only to
	 * an adjacent empty-list alias that is read later and to the exact `_g` tuple
	 * binder shape.
	 */
	static function emptyArrayReducerAlias(pattern:EPattern, rhs:ElixirAST, statements:Array<ElixirAST>, index:Int):Null<String> {
		if (!patternHasCompilerTemp(pattern) || !reduceWhileStartsWithEmptyList(rhs) || index + 1 >= statements.length)
			return null;
		return switch (statements[index + 1].def) {
			case EMatch(PVar(alias), value) if (isEmptyList(value) && isExactVarUsedLater(statements, index + 2, alias)):
				alias;
			default:
				null;
		};
	}

	static function patternHasCompilerTemp(pattern:EPattern):Bool {
		return switch (pattern) {
			case PVar("_g"): true;
			case PTuple(items): Lambda.exists(items, patternHasCompilerTemp);
			default: false;
		};
	}

	static function firstPatternName(pattern:EPattern):Null<String> {
		return switch (pattern) {
			case PVar(name): name;
			case PTuple(items) if (items != null && items.length > 0): firstPatternName(items[0]);
			default: null;
		};
	}

	static function findRedundantEmptySeed(statements:Array<ElixirAST>, reducerIndex:Int, name:Null<String>):Int {
		if (name == null)
			return -1;
		var index = reducerIndex - 1;
		while (index >= 0) {
			var statement = statements[index];
			switch (statement.def) {
				case EMatch(PVar(seedName), seed) if (seedName == name):
					return isEmptyList(seed) ? index : -1;
				default:
			}
			if (astUsesExactVar(statement, name))
				return -1;
			index--;
		}
		return -1;
	}

	static function replaceFirstCompilerTemp(pattern:EPattern, alias:String):EPattern {
		return switch (pattern) {
			case PVar("_g"): PVar(alias);
			case PTuple(items):
				var replaced = false;
				PTuple(items.map(item -> {
					if (!replaced && patternHasCompilerTemp(item)) {
						replaced = true;
						return replaceFirstCompilerTemp(item, alias);
					}
					return item;
				}));
			default: pattern;
		};
	}

	static function reduceWhileStartsWithEmptyList(expression:ElixirAST):Bool {
		return switch (expression.def) {
			case ERemoteCall(_, "reduce_while", args) if (args != null && args.length >= 2):
				switch (args[1].def) {
					case ETuple(items) if (items != null && items.length > 0): isEmptyList(items[0]);
					default: false;
				};
			default: false;
		};
	}

	static function isEmptyList(expression:ElixirAST):Bool {
		return switch (expression.def) {
			case EList(items): items != null && items.length == 0;
			default: false;
		};
	}

	static function promotePatternByLaterUse(pattern:EPattern, statements:Array<ElixirAST>, startIndex:Int):EPattern {
		return switch (pattern) {
			case PVar(name) if (name != null && name.length > 1 && name.charAt(0) == "_"):
				var plain = name.substr(1);
				isExactVarUsedLater(statements, startIndex, plain) ? PVar(plain) : pattern;
			case PTuple(items):
				PTuple(items.map(item -> promotePatternByLaterUse(item, statements, startIndex)));
			case PList(items):
				PList(items.map(item -> promotePatternByLaterUse(item, statements, startIndex)));
			case PCons(head, tail):
				PCons(promotePatternByLaterUse(head, statements, startIndex), promotePatternByLaterUse(tail, statements, startIndex));
			case PAlias(name, inner):
				var promotedName = name != null
					&& name.length > 1
					&& name.charAt(0) == "_"
					&& isExactVarUsedLater(statements, startIndex, name.substr(1)) ? name.substr(1) : name;
				PAlias(promotedName, promotePatternByLaterUse(inner, statements, startIndex));
			default:
				pattern;
		};
	}

	static function isExactVarUsedLater(statements:Array<ElixirAST>, startIndex:Int, name:String):Bool {
		for (index in startIndex...statements.length) {
			var statement = statements[index];
			var valueExpression = switch (statement.def) {
				case EMatch(_, rhs): rhs;
				case EBinary(Match, _, rhs): rhs;
				default: statement;
			};
			if (astUsesExactVar(valueExpression, name))
				return true;

			var rebinds = switch (statement.def) {
				case EMatch(pattern, _): patternBindsExactVar(pattern, name);
				case EBinary(Match, left, _): astUsesExactVar(left, name);
				default: false;
			};
			if (rebinds)
				return false;
		}
		return false;
	}

	static function astUsesExactVar(expression:ElixirAST, name:String):Bool {
		var found = false;
		ASTUtils.walk(expression, function(node:ElixirAST) {
			if (found || node == null || node.def == null)
				return;
			switch (node.def) {
				case EVar(candidate) if (candidate == name):
					found = true;
				default:
			}
		});
		return found;
	}

	static function patternBindsExactVar(pattern:EPattern, name:String):Bool {
		return switch (pattern) {
			case PVar(candidate): candidate == name;
			case PTuple(items) | PList(items): Lambda.exists(items, item -> patternBindsExactVar(item, name));
			case PCons(head, tail): patternBindsExactVar(head, name) || patternBindsExactVar(tail, name);
			case PAlias(candidate, inner): candidate == name || patternBindsExactVar(inner, name);
			default: false;
		};
	}

	static function collectRefs(body:ElixirAST):Map<String, Bool> {
		var refs = new Map<String, Bool>();
		ASTUtils.walk(body, function(n:ElixirAST) {
			if (n == null || n.def == null)
				return;
			switch (n.def) {
				case EVar(v):
					var b = base(v);
					if (b != null)
						refs.set(b, true);
				default:
			}
		});
		return refs;
	}

	static function rewrite(body:ElixirAST, refs:Map<String, Bool>):ElixirAST {
		function promote(name:String):String {
			var b = base(name);
			if (b != null && refs.exists(b) && name.charAt(0) == "_")
				return b;
			return name;
		}

		function rewPat(p:EPattern):EPattern {
			return switch (p) {
				case PVar(v): PVar(promote(v));
				case PTuple(items): PTuple(items.map(rewPat));
				case PList(items): PList(items.map(rewPat));
				case PCons(h, t): PCons(rewPat(h), rewPat(t));
				case PMap(fields): PMap([for (f in fields) {key: f.key, value: rewPat(f.value)}]);
				case PStruct(mod, fields): PStruct(mod, [for (f in fields) {key: f.key, value: rewPat(f.value)}]);
				case PAlias(varName, pat): PAlias(promote(varName), rewPat(pat));
				default: p;
			}
		}

		function rewPatInLhs(lhs:ElixirAST):ElixirAST {
			if (lhs == null || lhs.def == null)
				return lhs;
			return switch (lhs.def) {
				case EVar(v):
					var nv = promote(v);
					(nv == v) ? lhs : makeASTWithMeta(EVar(nv), lhs.metadata, lhs.pos);
				case EMatch(p, rhs):
					makeASTWithMeta(EMatch(rewPat(p), rhs), lhs.metadata, lhs.pos);
				default:
					lhs;
			}
		}

		return ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
			if (n == null || n.def == null)
				return n;
			return switch (n.def) {
				case EVar(v):
					var nv = promote(v);
					(nv == v) ? n : makeASTWithMeta(EVar(nv), n.metadata, n.pos);
				case EMatch(p, rhs):
					makeASTWithMeta(EMatch(rewPat(p), rhs), n.metadata, n.pos);
				case EBinary(Match, left, rhs):
					makeASTWithMeta(EBinary(Match, rewPatInLhs(left), rhs), n.metadata, n.pos);
				case EFn(clauses):
					var newClauses = [
						for (c in clauses)
							{
								args: [for (a in c.args) rewPat(a)],
								guard: c.guard,
								body: c.body
							}
					];
					makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function base(name:String):String {
		if (name == null || name.length == 0)
			return null;
		var s = stripLeadingUnderscores(name);
		if (s == null || s.length == 0)
			return null;
		var i = s.length - 1;
		while (i >= 0 && s.charAt(i) >= "0" && s.charAt(i) <= "9")
			i--;
		var b = s.substr(0, i + 1);
		if (b == "" || b.charAt(0) != b.charAt(0).toLowerCase() || b.charAt(0) == "_")
			return null;
		return b;
	}

	static function stripLeadingUnderscores(name:String):String {
		var i = 0;
		while (i < name.length && name.charAt(i) == "_")
			i++;
		return name.substr(i);
	}
}
#end
