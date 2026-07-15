package reflaxe.elixir.ast.analyzers;

#if (macro || reflaxe_runtime)
import Lambda;
import reflaxe.elixir.ast.ElixirAST;

/**
 * VarUseAnalyzer
 *
 * WHAT
 * - Shared variable usage analyzer for hygiene transforms. Determines if a
 *   variable is referenced within a node or later in a statement list.
 *
 * WHY
 * - Multiple passes maintained ad-hoc usage scanners with inconsistent coverage
 *   (missed EFn closures, string interpolation, ERaw, map/keyword fields, etc.).
 *   This caused discarding variables that are actually used in closures or
 *   interpolations, leading to undefined-variable errors at runtime.
 *
 * HOW
 * - Provides stmtUsesVar(node, name) and usedLater(stmts, startIdx, name).
 * - Traverses common AST constructs and scans:
 *   - EFn(clauses): walks each clause body
 *   - EString: scans "#{...}" interpolations for name occurrence
 *   - ERaw: token-boundary search to avoid substring false positives
 *   - EMap/EKeywordList/EStructUpdate/EAccess/EField/ETuple
 *   - ECase: expr and clause bodies
 */
class VarUseAnalyzer {
	static inline function looksLikeDoubleQuotedStringLiteral(code:String):Bool {
		if (code == null)
			return false;
		var trimmed = StringTools.trim(code);
		return trimmed.length >= 2 && StringTools.startsWith(trimmed, "\"") && StringTools.endsWith(trimmed, "\"");
	}

	static inline function stripOuterQuotes(code:String):String {
		var trimmed = StringTools.trim(code);
		if (looksLikeDoubleQuotedStringLiteral(trimmed)) {
			return trimmed.substr(1, trimmed.length - 2);
		}
		return trimmed;
	}

	public static function usedLater(stmts:Array<ElixirAST>, startIdx:Int, name:String):Bool {
		if (name == null || name.length == 0)
			return false;
		for (j in startIdx...stmts.length)
			if (stmtUsesVar(stmts[j], name))
				return true;
		return false;
	}

	/**
	 * Collect references that are free relative to `initiallyBound`.
	 *
	 * Unlike the broad hygiene checks above, this method follows lexical binders:
	 * anonymous-function arguments, case/receive patterns, with/for generators, and
	 * sequential assignments. Binder-repair passes use it to distinguish a genuinely
	 * missing reference from a same-named local inside a nested closure. Opaque `ERaw`
	 * fragments are deliberately excluded because they do not expose lexical scope;
	 * a raw node that is only a quoted interpolated string remains safe to inspect.
	 */
	public static function freeVarNames(n:ElixirAST, ?initiallyBound:Map<String, Bool>):Map<String, Bool> {
		var names = new Map<String, Bool>();
		for (name in freeVarUseCounts(n, initiallyBound).keys())
			names.set(name, true);
		return names;
	}

	/**
	 * Count references that are free relative to `initiallyBound`.
	 *
	 * This is the frequency-preserving counterpart to `freeVarNames`. Passes that
	 * must choose among several missing locals use these centralized counts rather
	 * than flattening the AST and accidentally counting nested binders as uses.
	 */
	public static function freeVarUseCounts(n:ElixirAST, ?initiallyBound:Map<String, Bool>):Map<String, Int> {
		var refs = new Map<String, Int>();

		function recordReference(name:String):Void {
			if (name == null || name.length == 0)
				return;
			refs.set(name, refs.exists(name) ? refs.get(name) + 1 : 1);
		}

		function cloneScope(scope:Map<String, Bool>):Map<String, Bool> {
			var copy = new Map<String, Bool>();
			if (scope != null)
				for (name in scope.keys())
					copy.set(name, true);
			return copy;
		}

		function bindPattern(pattern:EPattern, scope:Map<String, Bool>):Void {
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
					// A pin reads an existing binding; it does not create one.
				default:
			}
		}

		function bindLhs(lhs:ElixirAST, scope:Map<String, Bool>):Void {
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
					// Pinned values are references, not new bindings.
				default:
			}
		}

		function bindStatement(statement:ElixirAST, scope:Map<String, Bool>):Void {
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

		function recordPatternPins(pattern:EPattern, scope:Map<String, Bool>, pinned:Bool = false):Void {
			if (pattern == null)
				return;
			switch (pattern) {
				case PVar(name) if (pinned && !scope.exists(name)):
					recordReference(name);
				case PPin(inner):
					recordPatternPins(inner, scope, true);
				case PAlias(_, inner):
					recordPatternPins(inner, scope, pinned);
				case PTuple(elements) | PList(elements):
					for (element in elements)
						recordPatternPins(element, scope, pinned);
				case PCons(head, tail):
					recordPatternPins(head, scope, pinned);
					recordPatternPins(tail, scope, pinned);
				case PMap(pairs):
					for (pair in pairs)
						recordPatternPins(pair.value, scope, pinned);
				case PStruct(_, fields):
					for (field in fields)
						recordPatternPins(field.value, scope, pinned);
				case PBinary(segments):
					for (segment in segments)
						recordPatternPins(segment.pattern, scope, pinned);
				default:
			}
		}

		function recordLhsPins(lhs:ElixirAST, scope:Map<String, Bool>, pinned:Bool = false):Void {
			if (lhs == null || lhs.def == null)
				return;
			switch (lhs.def) {
				case EVar(name) if (pinned && !scope.exists(name)):
					recordReference(name);
				case EPin(inner):
					recordLhsPins(inner, scope, true);
				case ETuple(elements) | EList(elements):
					for (element in elements)
						recordLhsPins(element, scope, pinned);
				case EKeywordList(pairs):
					for (pair in pairs)
						recordLhsPins(pair.value, scope, pinned);
				case EMap(pairs):
					for (pair in pairs)
						recordLhsPins(pair.value, scope, pinned);
				case EStruct(_, fields):
					for (field in fields)
						recordLhsPins(field.value, scope, pinned);
				case EBinary(Match, left, right):
					recordLhsPins(left, scope, pinned);
					recordLhsPins(right, scope, pinned);
				default:
			}
		}

		function recordInterpolated(code:String, scope:Map<String, Bool>):Void {
			var names = new Map<String, Bool>();
			ElixirCodeVarRefTokenizer.collectFromInterpolatedStringText(code, names);
			for (name in names.keys())
				if (!scope.exists(name))
					recordReference(name);
		}

		function walk(node:ElixirAST, scope:Map<String, Bool>):Void {
			if (node == null || node.def == null)
				return;
			switch (node.def) {
				case EVar(name):
					if (!scope.exists(name))
						recordReference(name);

				case EString(value):
					recordInterpolated(value, scope);
				case ERaw(code) if (looksLikeDoubleQuotedStringLiteral(code)):
					recordInterpolated(stripOuterQuotes(code), scope);
				case ERaw(_):
					// Binder synthesis must fail closed on opaque target code. The broad
					// stmtUsesVar APIs still scan ERaw for discard/underscore hygiene.

				case EMatch(pattern, rhs):
					recordPatternPins(pattern, scope);
					walk(rhs, scope);
				case EBinary(Match, lhs, rhs):
					recordLhsPins(lhs, scope);
					walk(rhs, scope);

				case EBlock(statements) | EDo(statements):
					var blockScope = cloneScope(scope);
					for (statement in statements) {
						walk(statement, blockScope);
						bindStatement(statement, blockScope);
					}

				case EDef(_, args, guards, body) | EDefp(_, args, guards, body) | EDefmacro(_, args, guards, body) | EDefmacrop(_, args, guards, body):
					var functionScope = new Map<String, Bool>();
					for (arg in args) {
						recordPatternPins(arg, functionScope);
						bindPattern(arg, functionScope);
					}
					if (guards != null)
						walk(guards, functionScope);
					walk(body, functionScope);

				case EFn(clauses):
					for (clause in clauses) {
						var functionScope = cloneScope(scope);
						for (arg in clause.args) {
							recordPatternPins(arg, functionScope);
							bindPattern(arg, functionScope);
						}
						if (clause.guard != null)
							walk(clause.guard, functionScope);
						walk(clause.body, functionScope);
					}

				case ECase(target, clauses):
					walk(target, scope);
					for (clause in clauses) {
						var clauseScope = cloneScope(scope);
						recordPatternPins(clause.pattern, clauseScope);
						bindPattern(clause.pattern, clauseScope);
						if (clause.guard != null)
							walk(clause.guard, clauseScope);
						walk(clause.body, clauseScope);
					}

				case EReceive(clauses, afterClause):
					for (clause in clauses) {
						var clauseScope = cloneScope(scope);
						recordPatternPins(clause.pattern, clauseScope);
						bindPattern(clause.pattern, clauseScope);
						if (clause.guard != null)
							walk(clause.guard, clauseScope);
						walk(clause.body, clauseScope);
					}
					if (afterClause != null) {
						walk(afterClause.timeout, scope);
						walk(afterClause.body, scope);
					}

				case EWith(clauses, doBlock, elseBlock):
					var withScope = cloneScope(scope);
					for (clause in clauses) {
						walk(clause.expr, withScope);
						recordPatternPins(clause.pattern, withScope);
						bindPattern(clause.pattern, withScope);
					}
					walk(doBlock, withScope);
					if (elseBlock != null)
						walk(elseBlock, scope);

				case EFor(generators, filters, body, into, _):
					var forScope = cloneScope(scope);
					for (generator in generators) {
						walk(generator.expr, forScope);
						recordPatternPins(generator.pattern, forScope);
						bindPattern(generator.pattern, forScope);
					}
					for (filter in filters)
						walk(filter, forScope);
					walk(body, forScope);
					if (into != null)
						walk(into, scope);

				case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
					walk(body, scope);
					if (rescueClauses != null)
						for (clause in rescueClauses) {
							var rescueScope = cloneScope(scope);
							recordPatternPins(clause.pattern, rescueScope);
							bindPattern(clause.pattern, rescueScope);
							if (clause.varName != null)
								rescueScope.set(clause.varName, true);
							walk(clause.body, rescueScope);
						}
					if (catchClauses != null)
						for (clause in catchClauses) {
							var catchScope = cloneScope(scope);
							recordPatternPins(clause.pattern, catchScope);
							bindPattern(clause.pattern, catchScope);
							walk(clause.body, catchScope);
						}
					if (afterBlock != null)
						walk(afterBlock, scope);
					if (elseBlock != null)
						walk(elseBlock, scope);

				default:
					reflaxe.elixir.ast.ElixirASTTransformer.transformAST(node, child -> {
						walk(child, scope);
						child;
					});
			}
		}

		walk(n, cloneScope(initiallyBound));
		return refs;
	}

	/** Return whether `name` has a reference that is free in the supplied lexical scope. */
	public static function usesFreeVarExact(n:ElixirAST, name:String, ?initiallyBound:Map<String, Bool>):Bool {
		return name != null && name.length > 0 && freeVarNames(n, initiallyBound).exists(name);
	}

	/**
	 * Strict variable-use check that matches only the exact name provided.
	 *
	 * WHY
	 * - Some transforms (e.g. case-binder underscore alignment) must distinguish
	 *   between `value` and `_value`. The general-purpose `stmtUsesVar/2`
	 *   intentionally considers underscore/case variants, which can produce
	 *   false positives for these shape-sensitive passes.
	 */
	public static function stmtUsesVarExact(n:ElixirAST, name:String):Bool {
		if (name == null || name.length == 0)
			return false;
		var found = false;
		inline function isIdentChar(c:String):Bool {
			if (c == null || c.length == 0)
				return false;
			var ch = c.charCodeAt(0);
			return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_" || c == ".";
		}
		function scanStringInterpolation(str:String):Void {
			var i = 0;
			while (!found && str != null && i < str.length) {
				var idx = str.indexOf("#{", i);
				if (idx == -1)
					break;
				var j = str.indexOf("}", idx + 2);
				if (j == -1)
					break;
				var inner = str.substr(idx + 2, j - (idx + 2));
				var start = 0;
				while (!found && inner != null) {
					var pos = inner.indexOf(name, start);
					if (pos == -1)
						break;
					var before = pos > 0 ? inner.substr(pos - 1, 1) : null;
					var afterIdx = pos + name.length;
					var after = afterIdx < inner.length ? inner.substr(afterIdx, 1) : null;
					if (!isIdentChar(before) && !isIdentChar(after)) {
						found = true;
						break;
					}
					start = pos + name.length;
				}
				i = j + 1;
			}
		}
		function walk(x:ElixirAST, inPattern:Bool):Void {
			if (x == null || found)
				return;
			switch (x.def) {
				case EVar(v) if (!inPattern && v == name):
					found = true;
				case EPin(inner):
					walk(inner, false);
				case ERaw(code):
					if (code != null && looksLikeDoubleQuotedStringLiteral(code)) {
						scanStringInterpolation(stripOuterQuotes(code));
					} else {
						var start = 0;
						while (!found && code != null) {
							var pos = code.indexOf(name, start);
							if (pos == -1)
								break;
							var before = pos > 0 ? code.substr(pos - 1, 1) : null;
							var afterIdx = pos + name.length;
							var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
							if (!isIdentChar(before) && !isIdentChar(after)) {
								found = true;
								break;
							}
							start = pos + name.length;
						}
					}
				case EString(str):
					scanStringInterpolation(str);
				case EBinary(Match, _left, rhs):
					walk(rhs, false);
				case EBinary(_, leftAny, rightAny):
					walk(leftAny, false);
					walk(rightAny, false);
				case EMatch(_pat, rhsExpr):
					walk(rhsExpr, false);
				case EBlock(ss):
					for (s in ss)
						walk(s, false);
				case EDo(statements):
					for (s in statements)
						walk(s, false);
				case EIf(c, t, e):
					walk(c, false);
					walk(t, false);
					if (e != null)
						walk(e, false);
				case ECase(expr, clauses):
					walk(expr, false);
					for (c in clauses) {
						if (c.guard != null)
							walk(c.guard, false);
						walk(c.body, false);
					}
				case EWith(clauses, doBlock, elseBlock):
					for (wc in clauses)
						walk(wc.expr, false);
					walk(doBlock, false);
					if (elseBlock != null)
						walk(elseBlock, false);
				case ECall(tgt, _, args):
					if (tgt != null)
						walk(tgt, false);
					for (a in args)
						walk(a, false);
				case ERemoteCall(targetExpr, _, argsList):
					walk(targetExpr, false);
					for (a in argsList)
						walk(a, false);
				case EField(obj, _):
					walk(obj, false);
				case EAccess(objectExpr, key):
					walk(objectExpr, false);
					walk(key, false);
				case EKeywordList(pairs):
					for (p in pairs)
						walk(p.value, false);
				case EMap(pairs):
					for (p in pairs) {
						walk(p.key, false);
						walk(p.value, false);
					}
				case EStructUpdate(base, fields):
					walk(base, false);
					for (f in fields)
						walk(f.value, false);
				case ETuple(elems) | EList(elems):
					for (e in elems)
						walk(e, false);
				case EFn(clauses):
					for (cl in clauses)
						walk(cl.body, false);
				case ECond(condClauses):
					for (cl in condClauses) {
						walk(cl.condition, false);
						walk(cl.body, false);
					}
				case ERange(startExpr, endExpr, _, step):
					walk(startExpr, false);
					walk(endExpr, false);
					if (step != null)
						walk(step, false);
				case EUnary(_, innerExpr):
					walk(innerExpr, false);
				case EParen(innerExpr):
					walk(innerExpr, false);
				case EPipe(pipeLeft, pipeRight):
					walk(pipeLeft, false);
					walk(pipeRight, false);
				case EUnless(unlessCond, unlessBody, unlessElse):
					walk(unlessCond, false);
					walk(unlessBody, false);
					if (unlessElse != null)
						walk(unlessElse, false);
				case EFor(generators, filters, body, into, _uniq):
					for (gen in generators)
						walk(gen.expr, false);
					for (filter in filters)
						walk(filter, false);
					if (body != null)
						walk(body, false);
					if (into != null)
						walk(into, false);
				case ECapture(capturedExpr, _):
					walk(capturedExpr, false);
				default:
			}
		}
		walk(n, false);
		return found;
	}

	public static function stmtUsesVar(n:ElixirAST, name:String):Bool {
		var found = false;
		inline function isIdentChar(c:String):Bool {
			if (c == null || c.length == 0)
				return false;
			var ch = c.charCodeAt(0);
			return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_" || c == ".";
		}
		inline function snakeCase(s:String):String {
			if (s == null || s.length == 0)
				return s;
			var out = new StringBuf();
			for (i in 0...s.length) {
				var ch = s.charAt(i);
				var isUpper = (ch.toUpperCase() == ch && ch.toLowerCase() != ch);
				if (isUpper && i > 0)
					out.add("_");
				out.add(ch.toLowerCase());
			}
			return out.toString();
		}
		inline function camelCase(s:String):String {
			if (s == null || s.length == 0)
				return s;
			var parts = s.split("_");
			if (parts.length == 1)
				return s;
			var out = new StringBuf();
			for (i in 0...parts.length) {
				var p = parts[i];
				if (p.length == 0)
					continue;
				if (i == 0)
					out.add(p);
				else
					out.add(p.charAt(0).toUpperCase() + p.substr(1));
			}
			return out.toString();
		}
		var candidates = new Array<String>();
		if (name != null && name.length > 0) {
			candidates.push(name);
			var sn = snakeCase(name);
			if (sn != name)
				candidates.push(sn);
			var cc = camelCase(name);
			if (cc != name && cc != sn)
				candidates.push(cc);
			// Also check base name without underscore prefix for underscore-prefixed inputs
			if (name.charAt(0) == '_' && name.length > 1) {
				var baseName = name.substr(1);
				if (!Lambda.exists(candidates, function(c) return c == baseName)) {
					candidates.push(baseName);
				}
				var snBase = snakeCase(baseName);
				if (snBase != baseName && !Lambda.exists(candidates, function(c) return c == snBase)) {
					candidates.push(snBase);
				}
			}
			// Also check underscore-prefixed variant for non-underscore inputs
			if (name.charAt(0) != '_') {
				var underscored = '_' + name;
				if (!Lambda.exists(candidates, function(c) return c == underscored)) {
					candidates.push(underscored);
				}
			}
		}
		function scanStringInterpolation(str:String):Void {
			var i = 0;
			while (!found && str != null && i < str.length) {
				var idx = str.indexOf("#{", i);
				if (idx == -1)
					break;
				var j = str.indexOf("}", idx + 2);
				if (j == -1)
					break;
				var inner = str.substr(idx + 2, j - (idx + 2));
				if (inner != null) {
					var start = 0;
					while (!found) {
						var chosen:String = null;
						var pos = -1;
						for (c in candidates) {
							var idx2 = inner.indexOf(c, start);
							if (idx2 != -1 && (pos == -1 || idx2 < pos)) {
								pos = idx2;
								chosen = c;
							}
						}
						if (pos == -1 || chosen == null)
							break;
						var before = pos > 0 ? inner.substr(pos - 1, 1) : null;
						var afterIdx = pos + chosen.length;
						var after = afterIdx < inner.length ? inner.substr(afterIdx, 1) : null;
						if (!isIdentChar(before) && !isIdentChar(after)) {
							found = true;
							break;
						}
						start = pos + chosen.length;
					}
				}
				i = j + 1;
			}
		}
		function walk(x:ElixirAST, inPattern:Bool):Void {
			if (x == null || found)
				return;
			switch (x.def) {
				case EVar(v) if (!inPattern):
					for (c in candidates)
						if (v == c) {
							found = true;
							break;
						}
				case EPin(inner):
					// Pin operator holds an expression; traverse to detect variable usage
					walk(inner, false);
				case ERaw(code):
					if (code != null && looksLikeDoubleQuotedStringLiteral(code)) {
						scanStringInterpolation(stripOuterQuotes(code));
					} else {
						// NOTE: We MUST check underscore-prefixed variables too!
						// FinalUnderscoreRepairTransforms needs to detect _this usage in ERaw like String.downcase(_this)
						if (name != null && name.length > 0 && code != null) {
							var start = 0;
							while (!found) {
								var chosen:String = null;
								var pos = -1;
								for (c in candidates) {
									var idx = code.indexOf(c, start);
									if (idx != -1 && (pos == -1 || idx < pos)) {
										pos = idx;
										chosen = c;
									}
								}
								if (pos == -1 || chosen == null)
									break;
								var before = pos > 0 ? code.substr(pos - 1, 1) : null;
								var afterIdx = pos + chosen.length;
								var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
								if (!isIdentChar(before) && !isIdentChar(after)) {
									found = true;
									break;
								}
								start = pos + chosen.length;
							}
						}
					}
				case EString(str):
					scanStringInterpolation(str);
				case EBinary(Match, left, rhs):
					// Only RHS can reference the name in expression position for pattern match
					walk(rhs, false);
				case EBinary(_, leftAny, rightAny):
					// For non-match binary operators, both sides are expressions
					walk(leftAny, false);
					walk(rightAny, false);
				case EMatch(pat, rhsExpr):
					// Only RHS can reference the name in expression position
					walk(rhsExpr, false);
				case EBlock(ss):
					for (s in ss)
						walk(s, false);
				case EDo(statements):
					for (s in statements)
						walk(s, false);
				case EIf(c, t, e):
					walk(c, false);
					walk(t, false);
					if (e != null)
						walk(e, false);
				case ECase(expr, clauses):
					walk(expr, false);
					for (c in clauses) {
						// c.pattern binds names; do not treat as use
						if (c.guard != null)
							walk(c.guard, false);
						walk(c.body, false);
					}
				case EWith(clauses, doBlock, elseBlock):
					for (wc in clauses)
						walk(wc.expr, false);
					walk(doBlock, false);
					if (elseBlock != null)
						walk(elseBlock, false);
				case ECall(tgt, _, args):
					if (tgt != null)
						walk(tgt, false);
					for (a in args)
						walk(a, false);
				case ERemoteCall(targetExpr, _, argsList):
					walk(targetExpr, false);
					for (a in argsList)
						walk(a, false);
				case EField(obj, _):
					walk(obj, false);
				case EAccess(objectExpr, key):
					walk(objectExpr, false);
					walk(key, false);
				case EKeywordList(pairs):
					for (p in pairs)
						walk(p.value, false);
				case EMap(pairs):
					for (p in pairs) {
						walk(p.key, false);
						walk(p.value, false);
					}
				case EStructUpdate(base, fields):
					walk(base, false);
					for (f in fields)
						walk(f.value, false);
				case ETuple(elems) | EList(elems):
					for (e in elems)
						walk(e, false);
				case EFn(clauses):
					for (cl in clauses)
						walk(cl.body, false);
				case ECond(condClauses):
					// Walk through cond clauses - both condition and body can use variables
					for (cl in condClauses) {
						walk(cl.condition, false);
						walk(cl.body, false);
					}
				case ERange(startExpr, endExpr, _, step):
					// Range expressions can use variables
					walk(startExpr, false);
					walk(endExpr, false);
					if (step != null)
						walk(step, false);
				case EUnary(_, innerExpr):
					// Unary operators wrap expressions
					walk(innerExpr, false);
				case EParen(innerExpr):
					// Parentheses are transparent for usage analysis
					walk(innerExpr, false);
				case EPipe(pipeLeft, pipeRight):
					// Pipeline operator - both sides can use variables
					walk(pipeLeft, false);
					walk(pipeRight, false);
				case EUnless(unlessCond, unlessBody, unlessElse):
					// Unless is like if - condition and both branches
					walk(unlessCond, false);
					walk(unlessBody, false);
					if (unlessElse != null)
						walk(unlessElse, false);
				case EFor(generators, filters, body, into, _uniq):
					// For comprehensions - walk generators, filters, and body
					for (gen in generators) {
						walk(gen.expr, false);
						// Note: gen.pattern binds names, don't treat as use
					}
					for (filter in filters)
						walk(filter, false);
					if (body != null)
						walk(body, false);
					if (into != null)
						walk(into, false);
				case ECapture(capturedExpr, _):
					// Capture expressions can reference variables
					walk(capturedExpr, false);
				default:
			}
		}
		walk(n, false);
		return found;
	}
}
#end
