package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
 * WHAT
 * - Repairs one genuinely missing local reference in a one-argument anonymous function.
 *
 * WHY
 * Late lowering can occasionally leave `fn item -> entry.field end`, where `entry`
 * was meant to be the sole binder. A flat repair can overwrite an intentional outer
 * capture or a same-named binder in a nested callback.
 *
 * HOW
 * - Carry function, case, anonymous-function, and sequential block scope.
 * - Ask `VarUseAnalyzer` for genuinely free references.
 * - Rewrite only that free reference through `ScopedVarRewriter`.
 *
 * EXAMPLES
 * - `fn item -> entry.id end` can become `fn item -> item.id end` when `entry` is
 *   the sole missing local.
 * - `fn _ignored -> payload end` keeps the surrounding `payload` capture unchanged.
 */
class EFnUndefinedRefToArgTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return transformWithScope(ast, new Map());
	}

	static function transformWithScope(node:ElixirAST, inScope:Map<String, Bool>):ElixirAST {
		if (node == null || node.def == null)
			return node;

		return switch (node.def) {
			case EDef(name, args, guards, body):
				var scope = scopeFromPatterns(args);
				makeASTWithMeta(EDef(name, args, guards != null ? transformWithScope(guards, scope) : null, transformWithScope(body, scope)), node.metadata,
					node.pos);

			case EDefp(name, args, guards, body):
				var scope = scopeFromPatterns(args);
				makeASTWithMeta(EDefp(name, args, guards != null ? transformWithScope(guards, scope) : null, transformWithScope(body, scope)), node.metadata,
					node.pos);

			case EFn(clauses):
				var rewritten = [];
				for (clause in clauses) {
					var clauseScope = cloneScope(inScope);
					for (arg in clause.args)
						bindPattern(arg, clauseScope);
					var nextClause = {
						args: clause.args,
						guard: clause.guard != null ? transformWithScope(clause.guard, clauseScope) : null,
						body: transformWithScope(clause.body, clauseScope)
					};
					rewritten.push(repairClause(nextClause, clauseScope));
				}
				makeASTWithMeta(EFn(rewritten), node.metadata, node.pos);

			case EBlock(statements):
				makeASTWithMeta(EBlock(transformStatements(statements, inScope)), node.metadata, node.pos);

			case EDo(statements):
				makeASTWithMeta(EDo(transformStatements(statements, inScope)), node.metadata, node.pos);

			case ECase(target, clauses):
				var rewritten = [];
				for (clause in clauses) {
					var clauseScope = cloneScope(inScope);
					bindPattern(clause.pattern, clauseScope);
					rewritten.push({
						pattern: clause.pattern,
						guard: clause.guard != null ? transformWithScope(clause.guard, clauseScope) : null,
						body: transformWithScope(clause.body, clauseScope)
					});
				}
				makeASTWithMeta(ECase(transformWithScope(target, inScope), rewritten), node.metadata, node.pos);

			default:
				ElixirASTTransformer.transformAST(node, child -> transformWithScope(child, inScope));
		};
	}

	static function repairClause(clause:EFnClause, clauseScope:Map<String, Bool>):EFnClause {
		if (clause.args == null || clause.args.length != 1)
			return clause;
		var argName = switch (clause.args[0]) {
			case PVar(name): name;
			default: null;
		};
		if (argName == null || VarUseAnalyzer.stmtUsesVarExact(clause.body, argName))
			return clause;

		var undefined = [];
		for (name in VarUseAnalyzer.freeVarNames(clause.body, clauseScope).keys())
			if (isLocalVarName(name))
				undefined.push(name);
		if (undefined.length != 1)
			return clause;

		var replacements = new Map<String, String>();
		replacements.set(undefined[0], argName);
		return {
			args: clause.args,
			guard: clause.guard,
			body: ScopedVarRewriter.rewrite(clause.body, replacements, clauseScope)
		};
	}

	static function transformStatements(statements:Array<ElixirAST>, parentScope:Map<String, Bool>):Array<ElixirAST> {
		var scope = cloneScope(parentScope);
		var rewritten = [];
		for (statement in statements) {
			var next = transformWithScope(statement, scope);
			rewritten.push(next);
			bindStatement(next, scope);
		}
		return rewritten;
	}

	static inline function isLocalVarName(name:String):Bool {
		if (name == null || name.length == 0 || name.indexOf(".") != -1)
			return false;
		var first = name.charAt(0);
		return first == "_" || (first.toLowerCase() == first && first.toUpperCase() != first);
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
