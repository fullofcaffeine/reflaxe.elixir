package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import haxe.ds.StringMap;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.ElixirCodeVarRefTokenizer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

private typedef NameBindingFlow = {
	var readsPrior:Bool;
	var definitelyBound:Bool;
}

/**
 * ShadowedInitAssignPruneTransforms
 *
 * WHAT
 * - Drops trivial initializer assignments in a block when they are overwritten later
 *   at the same block level without being read in between.
 *
 * WHY
 * - Haxe commonly declares locals without initialization and assigns them later in control flow:
 *     var median: Float;
 *     if (cond) median = a else median = b;
 *   The compiler often emits an initializer like `median = nil` (or an empty map) to satisfy
 *   Elixir binding rules. When the variable is then assigned unconditionally later, that
 *   initializer becomes a dead store and triggers --warnings-as-errors:
 *     warning: variable "median" is unused
 *
 * HOW
 * - In each EBlock/EDo statement list, track assignments of the form `name = <literal>`
 *   where <literal> is side-effect-free (nil, literals, empty list/map, and nested literals).
 * - If `name` is not referenced by any statement before a subsequent top-level assignment to `name`,
 *   prune the earlier initializer.
 *
 * EXAMPLES
 * Before:
 *   median = nil
 *   mid = trunc(length(sorted) / 2)
 *   median = if cond do a else b end
 * After:
 *   mid = trunc(length(sorted) / 2)
 *   median = if cond do a else b end
 */
class ShadowedInitAssignPruneTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EBlock(stmts):
					makeASTWithMeta(EBlock(pruneStatements(stmts)), n.metadata, n.pos);
				case EDo(stmts):
					makeASTWithMeta(EDo(pruneStatements(stmts)), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function pruneStatements(stmts:Array<ElixirAST>):Array<ElixirAST> {
		if (stmts == null || stmts.length == 0)
			return stmts;

		var out:Array<Null<ElixirAST>> = [];
		var pendingInit = new StringMap<Int>(); // name -> index in out

		for (stmt in stmts) {
			// Any read of a pending var commits its initializer (we must keep it).
			for (name in pendingInit.keys()) {
				if (statementReadsName(stmt, name)) {
					pendingInit.remove(name);
				}
			}

			var assignedName = assignedVarName(stmt);
			if (assignedName != null) {
				// If this assignment reads the previous binding, treat as a use and keep the initializer.
				if (statementReadsName(stmt, assignedName)) {
					pendingInit.remove(assignedName);
				} else if (pendingInit.exists(assignedName)) {
					var idx = pendingInit.get(assignedName);
					if (idx != null && idx >= 0 && idx < out.length)
						out[idx] = null;
					pendingInit.remove(assignedName);
				} else {
					pendingInit.remove(assignedName);
				}
			}

			var outIndex = out.length;
			out.push(stmt);

			// Record a new initializer candidate.
			if (assignedName != null && isPrunableInitializer(stmt, assignedName) && !pendingInit.exists(assignedName)) {
				pendingInit.set(assignedName, outIndex);
			}
		}

		// Any remaining pending initializer was never read nor overwritten; drop it to avoid WAE warnings.
		for (name in pendingInit.keys()) {
			var idx = pendingInit.get(name);
			if (idx != null && idx >= 0 && idx < out.length)
				out[idx] = null;
		}

		var compact:Array<ElixirAST> = [];
		for (s in out)
			if (s != null)
				compact.push(s);
		return compact;
	}

	static function assignedVarName(stmt:ElixirAST):Null<String> {
		if (stmt == null || stmt.def == null)
			return null;
		return switch (stmt.def) {
			case EMatch(PVar(name), _):
				name;
			case EBinary(Match, left, _):
				switch (left.def) {
					case EVar(name): name;
					case EParen(inner):
						switch (inner.def) {
							case EVar(varName): varName;
							default: null;
						}
					default:
						null;
				}
			default:
				null;
		};
	}

	static function isPrunableInitializer(stmt:ElixirAST, name:String):Bool {
		if (name == null || name == "_" || StringTools.startsWith(name, "_"))
			return false;
		var rhs = switch (stmt.def) {
			case EMatch(_, value): value;
			case EBinary(Match, _, value): value;
			default: null;
		};
		return rhs != null && isLiteral(rhs);
	}

	static function isLiteral(expr:ElixirAST):Bool {
		if (expr == null || expr.def == null)
			return false;
		return switch (expr.def) {
			case ENil | EBoolean(_) | EInteger(_) | EFloat(_) | EString(_) | EAtom(_):
				true;
			case EList(els):
				for (e in els)
					if (!isLiteral(e))
						return false;
				true;
			case ETuple(els):
				for (e in els)
					if (!isLiteral(e))
						return false;
				true;
			case EMap(pairs):
				for (p in pairs) {
					if (!isLiteral(p.key))
						return false;
					if (!isLiteral(p.value))
						return false;
				}
				true;
			case EKeywordList(pairs):
				for (p in pairs)
					if (!isLiteral(p.value))
						return false;
				true;
			case EParen(inner):
				isLiteral(inner);
			default:
				false;
		};
	}

	static function statementReadsName(stmt:ElixirAST, name:String):Bool {
		if (stmt == null || stmt.def == null)
			return false;
		return switch (stmt.def) {
			// Do not treat assignment LHS as a "read" of the name.
			case EBinary(Match, _l, r):
				exprReadsName(r, name);
			case EMatch(_pat, rhs):
				exprReadsName(rhs, name);
			default:
				exprReadsName(stmt, name);
		};
	}

	static function exprReadsName(expr:ElixirAST, name:String):Bool {
		return analyzeNameBindingFlow(expr, name, false).readsPrior;
	}

	/**
	 * Determine whether evaluating an expression reads a binding before replacing it.
	 *
	 * WHAT
	 * - Tracks an exact local name through source-order matches and nested anonymous functions.
	 *
	 * WHY
	 * - A closure may read an outer initializer directly, or it may bind the same name before every
	 *   read. A set-based collector cannot distinguish those cases: keeping the latter initializer
	 *   creates an unused-variable warning, while dropping the former creates undefined Elixir.
	 *
	 * HOW
	 * - Uses the shared closure-aware collector for subtrees with no relevant binding.
	 * - Performs flow-sensitive evaluation only when the subtree can bind the name, threading definite
	 *   bindings through sequential expressions and joining conditional branches conservatively.
	 *
	 * EXAMPLES
	 * - `fn -> use(target_id) end` reads the prior `target_id` binding.
	 * - `fn -> last = read_byte(); use(last) end` does not read the prior `last` binding.
	 */
	static function analyzeNameBindingFlow(expr:ElixirAST, name:String, definitelyBound:Bool):NameBindingFlow {
		if (expr == null || expr.def == null)
			return {readsPrior: false, definitelyBound: definitelyBound};
		if (definitelyBound)
			return {readsPrior: false, definitelyBound: true};
		if (!subtreeBindsName(expr, name))
			return {readsPrior: conservativelyReadsName(expr, name), definitelyBound: false};

		return switch (expr.def) {
			case EBlock(statements) | EDo(statements):
				analyzeNameBindingSequence(statements, name, false);

			case EBinary(Match, left, right):
				var rhs = analyzeNameBindingFlow(right, name, false);
				{
					readsPrior: rhs.readsPrior,
					definitelyBound: rhs.definitelyBound || astMatchBindsName(left, name)
				};
			case EMatch(pattern, right):
				var rhs = analyzeNameBindingFlow(right, name, false);
				{
					readsPrior: rhs.readsPrior || (!rhs.definitelyBound && pinnedPatternReadsName(pattern, name)),
					definitelyBound: rhs.definitelyBound || patternBindsName(pattern, name)
				};

			case EBinary(_, left, right) | EPipe(left, right):
				analyzeNameBindingSequence([left, right], name, false);
			case EUnary(_, inner) | EParen(inner) | EPin(inner) | ECapture(inner, _) | EThrow(inner) | EUnquote(inner) | EUnquoteSplicing(inner):
				analyzeNameBindingFlow(inner, name, false);

			case EIf(condition, thenBranch, elseBranch) | EUnless(condition, thenBranch, elseBranch):
				var conditionFlow = analyzeNameBindingFlow(condition, name, false);
				var thenFlow = analyzeNameBindingFlow(thenBranch, name, conditionFlow.definitelyBound);
				var elseFlow = elseBranch == null ? null : analyzeNameBindingFlow(elseBranch, name, conditionFlow.definitelyBound);
				{
					readsPrior: conditionFlow.readsPrior || thenFlow.readsPrior || (elseFlow != null && elseFlow.readsPrior),
					definitelyBound: conditionFlow.definitelyBound
					|| (elseFlow != null && thenFlow.definitelyBound && elseFlow.definitelyBound)};

			case ECase(subject, clauses):
				var subjectFlow = analyzeNameBindingFlow(subject, name, false);
				var readsPrior = subjectFlow.readsPrior;
				var everyClauseBinds = clauses.length > 0;
				for (clause in clauses) {
					var clauseBound = subjectFlow.definitelyBound || patternBindsName(clause.pattern, name);
					if (!clauseBound && pinnedPatternReadsName(clause.pattern, name))
						readsPrior = true;
					var clauseExpressions:Array<ElixirAST> = [];
					if (clause.guard != null)
						clauseExpressions.push(clause.guard);
					clauseExpressions.push(clause.body);
					var clauseFlow = analyzeNameBindingSequence(clauseExpressions, name, clauseBound);
					readsPrior = readsPrior || clauseFlow.readsPrior;
					everyClauseBinds = everyClauseBinds && clauseFlow.definitelyBound;
				}
				{
					readsPrior: readsPrior,
					definitelyBound: subjectFlow.definitelyBound || everyClauseBinds};

			case EFn(clauses):
				var readsPrior = false;
				for (clause in clauses) {
					var clauseBound = false;
					for (argument in clause.args)
						clauseBound = clauseBound || patternBindsName(argument, name);
					var clauseExpressions:Array<ElixirAST> = [];
					if (clause.guard != null)
						clauseExpressions.push(clause.guard);
					clauseExpressions.push(clause.body);
					readsPrior = readsPrior || analyzeNameBindingSequence(clauseExpressions, name, clauseBound).readsPrior;
				}
				{readsPrior: readsPrior, definitelyBound: false};

			case ECall(target, _, arguments):
				var expressions = arguments.copy();
				if (target != null)
					expressions.unshift(target);
				analyzeNameBindingSequence(expressions, name, false);
			case ERemoteCall(module, _, arguments):
				var expressions = [module];
				for (argument in arguments)
					expressions.push(argument);
				analyzeNameBindingSequence(expressions, name, false);
			case EMacroCall(_, arguments, doBlock):
				var expressions = arguments.copy();
				expressions.push(doBlock);
				analyzeNameBindingSequence(expressions, name, false);

			case EList(elements) | ETuple(elements):
				analyzeNameBindingSequence(elements, name, false);
			case EMap(pairs):
				var expressions:Array<ElixirAST> = [];
				for (pair in pairs) {
					expressions.push(pair.key);
					expressions.push(pair.value);
				}
				analyzeNameBindingSequence(expressions, name, false);
			case EKeywordList(pairs):
				analyzeNameBindingSequence([for (pair in pairs) pair.value], name, false);
			case EStruct(_, fields):
				analyzeNameBindingSequence([for (field in fields) field.value], name, false);
			case EStructUpdate(base, fields):
				var expressions = [base];
				for (field in fields)
					expressions.push(field.value);
				analyzeNameBindingSequence(expressions, name, false);
			case EBitstring(segments):
				var expressions:Array<ElixirAST> = [];
				for (segment in segments) {
					expressions.push(segment.value);
					if (segment.size != null)
						expressions.push(segment.size);
				}
				analyzeNameBindingSequence(expressions, name, false);
			case EField(target, _):
				analyzeNameBindingFlow(target, name, false);
			case EAccess(target, key):
				analyzeNameBindingSequence([target, key], name, false);
			case ERange(start, end, _, step):
				var expressions = [start, end];
				if (step != null)
					expressions.push(step);
				analyzeNameBindingSequence(expressions, name, false);
			case EReceiverEffect(effect):
				analyzeNameBindingFlow(effect.operation, name, false);

			case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
				var readsPrior = analyzeNameBindingFlow(body, name, false).readsPrior;
				for (clause in rescueClauses) {
					var clauseBound = patternBindsName(clause.pattern, name) || clause.varName == name;
					readsPrior = readsPrior || analyzeNameBindingFlow(clause.body, name, clauseBound).readsPrior;
				}
				for (clause in catchClauses) {
					var clauseBound = patternBindsName(clause.pattern, name);
					readsPrior = readsPrior || analyzeNameBindingFlow(clause.body, name, clauseBound).readsPrior;
				}
				if (afterBlock != null)
					readsPrior = readsPrior || analyzeNameBindingFlow(afterBlock, name, false).readsPrior;
				if (elseBlock != null)
					readsPrior = readsPrior || analyzeNameBindingFlow(elseBlock, name, false).readsPrior;
				// Bindings created inside try/rescue/catch do not establish a safe outer value.
				{readsPrior: readsPrior, definitelyBound: false};

			default:
				// Unknown binding-bearing shapes stay conservative: retain the initializer.
				{readsPrior: conservativelyReadsName(expr, name), definitelyBound: false};
		};
	}

	static function analyzeNameBindingSequence(expressions:Array<ElixirAST>, name:String, initialBound:Bool):NameBindingFlow {
		var result:NameBindingFlow = {readsPrior: false, definitelyBound: initialBound};
		for (expression in expressions) {
			var next = analyzeNameBindingFlow(expression, name, result.definitelyBound);
			result.readsPrior = result.readsPrior || next.readsPrior;
			result.definitelyBound = next.definitelyBound;
		}
		return result;
	}

	static function subtreeBindsName(expr:ElixirAST, name:String):Bool {
		if (expr == null || expr.def == null)
			return false;

		var direct = switch (expr.def) {
			case EBinary(Match, left, _): astMatchBindsName(left, name);
			case EMatch(pattern, _): patternBindsName(pattern, name);
			case EFn(clauses):
				var found = false;
				for (clause in clauses)
					for (argument in clause.args)
						found = found || patternBindsName(argument, name);
				found;
			case ECase(_, clauses) | EReceive(clauses, _):
				var found = false;
				for (clause in clauses)
					found = found || patternBindsName(clause.pattern, name);
				found;
			case EFor(generators, _, _, _, _):
				var found = false;
				for (generator in generators)
					found = found || patternBindsName(generator.pattern, name);
				found;
			case EWith(clauses, _, _):
				var found = false;
				for (clause in clauses)
					found = found || patternBindsName(clause.pattern, name);
				found;
			case ETry(_, rescueClauses, catchClauses, _, _):
				var found = false;
				for (clause in rescueClauses)
					found = found || clause.varName == name || patternBindsName(clause.pattern, name);
				for (clause in catchClauses)
					found = found || patternBindsName(clause.pattern, name);
				found;
			default: false;
		};
		if (direct)
			return true;

		var found = false;
		ElixirASTTransformer.iterateAST(expr, function(child:ElixirAST):Void {
			if (!found && subtreeBindsName(child, name))
				found = true;
		});
		return found;
	}

	static function astMatchBindsName(expr:ElixirAST, name:String):Bool {
		if (expr == null || expr.def == null)
			return false;
		return switch (expr.def) {
			case EVar(candidate): candidate == name;
			case EParen(inner): astMatchBindsName(inner, name);
			case ETuple(elements) | EList(elements):
				var found = false;
				for (element in elements)
					found = found || astMatchBindsName(element, name);
				found;
			default: false;
		};
	}

	static function patternBindsName(pattern:EPattern, name:String):Bool {
		return switch (pattern) {
			case PVar(candidate): candidate == name;
			case PAlias(candidate, inner): candidate == name || patternBindsName(inner, name);
			case PTuple(elements) | PList(elements):
				var found = false;
				for (element in elements)
					found = found || patternBindsName(element, name);
				found;
			case PCons(head, tail): patternBindsName(head, name) || patternBindsName(tail, name);
			case PMap(pairs):
				var found = false;
				for (pair in pairs)
					found = found || patternBindsName(pair.value, name);
				found;
			case PStruct(_, fields):
				var found = false;
				for (field in fields)
					found = found || patternBindsName(field.value, name);
				found;
			case PBinary(segments):
				var found = false;
				for (segment in segments)
					found = found || patternBindsName(segment.pattern, name);
				found;
			case PPin(_) | PLiteral(_) | PWildcard: false;
		};
	}

	static function pinnedPatternReadsName(pattern:EPattern, name:String):Bool {
		return switch (pattern) {
			case PPin(PVar(candidate)): candidate == name;
			case PPin(inner): pinnedPatternReadsName(inner, name);
			case PAlias(_, inner): pinnedPatternReadsName(inner, name);
			case PTuple(elements) | PList(elements):
				var found = false;
				for (element in elements)
					found = found || pinnedPatternReadsName(element, name);
				found;
			case PCons(head, tail): pinnedPatternReadsName(head, name) || pinnedPatternReadsName(tail, name);
			case PMap(pairs):
				var found = false;
				for (pair in pairs)
					found = found || pinnedPatternReadsName(pair.value, name);
				found;
			case PStruct(_, fields):
				var found = false;
				for (field in fields)
					found = found || pinnedPatternReadsName(field.value, name);
				found;
			case PBinary(segments):
				var found = false;
				for (segment in segments)
					found = found || pinnedPatternReadsName(segment.pattern, name);
				found;
			default: false;
		};
	}

	static function conservativelyReadsName(expr:ElixirAST, name:String):Bool {
		if (VariableUsageCollector.usedInFunctionScope(expr, name))
			return true;

		// Raw target snippets deliberately remain outside the shared structured
		// analyzer. Keep this destructive pass conservative by scanning only the
		// raw leaves that occur anywhere below the expression.
		var rawRefs = new Map<String, Bool>();
		function visitRaw(e:ElixirAST):Void {
			if (e == null || e.def == null || rawRefs.exists(name))
				return;
			switch (e.def) {
				case ERaw(code):
					ElixirCodeVarRefTokenizer.collectFromElixirCode(code, rawRefs);
				case EModule(_, attributes, body):
					for (attribute in attributes)
						visitRaw(attribute.value);
					for (statement in body)
						visitRaw(statement);
				case EDefmacro(_, _, guards, body) | EDefmacrop(_, _, guards, body):
					if (guards != null)
						visitRaw(guards);
					visitRaw(body);
				case EReceiverEffect(effect):
					visitRaw(effect.operation);
				case EPin(inner) | ECapture(inner, _) | EUnquote(inner) | EUnquoteSplicing(inner):
					visitRaw(inner);
				case EQuote(options, quoted):
					for (option in options)
						visitRaw(option);
					visitRaw(quoted);
				case ESend(target, message):
					visitRaw(target);
					visitRaw(message);
				default:
					ElixirASTTransformer.iterateAST(e, visitRaw);
			}
		}

		visitRaw(expr);
		return rawRefs.exists(name);
	}
}
#end
