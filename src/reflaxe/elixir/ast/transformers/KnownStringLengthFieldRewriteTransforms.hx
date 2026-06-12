package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;

/**
 * KnownStringLengthFieldRewriteTransforms
 *
 * WHAT
 * - Rewrites `.length` field access on locals proven to hold Elixir strings into
 *   `String.length(local)` before printing.
 *
 * WHY
 * - Some inlined iterator shapes lose Haxe receiver type metadata before the AST
 *   reaches late hygiene passes. The common shape is:
 *     text = "Aé"
 *     g_s = text
 *     g_s.length
 *   `g_s.length` is invalid on BEAM strings; it must be `String.length(g_s)`.
 * - This keeps the printer generic and preserves struct fields such as `Bytes.length`.
 *
 * HOW
 * - Walk sequential blocks with a small lexical environment of locals known to be strings.
 * - Propagate only obvious bindings (`name = "literal"` and `alias = knownString`).
 * - Rewrite `.length` only when the target variable is in that environment.
 */
class KnownStringLengthFieldRewriteTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return rewrite(ast, new Map());
	}

	static function rewrite(node:ElixirAST, knownStrings:Map<String, Bool>):ElixirAST {
		if (node == null)
			return null;

		return switch (node.def) {
			case EBlock(stmts):
				var scoped = copyEnv(knownStrings);
				var out:Array<ElixirAST> = [];
				var changed = false;
				for (stmt in stmts) {
					var rewritten = rewrite(stmt, scoped);
					if (rewritten != stmt)
						changed = true;
					out.push(rewritten);
					updateKnownStringBinding(scoped, rewritten);
				}
				changed ? makeASTWithMeta(EBlock(out), node.metadata, node.pos) : node;

			case EDo(stmts):
				var scoped = copyEnv(knownStrings);
				var out:Array<ElixirAST> = [];
				var changed = false;
				for (stmt in stmts) {
					var rewritten = rewrite(stmt, scoped);
					if (rewritten != stmt)
						changed = true;
					out.push(rewritten);
					updateKnownStringBinding(scoped, rewritten);
				}
				changed ? makeASTWithMeta(EDo(out), node.metadata, node.pos) : node;

			case EModule(name, attributes, body):
				var changed = false;
				var rewrittenAttributes = attributes == null ? null : [
					for (attribute in attributes) {
						var value = rewrite(attribute.value, knownStrings);
						if (value != attribute.value) changed = true;
						{
							name: attribute.name,
							value: value,
							nameSpanStart: attribute.nameSpanStart,
							nameSpanEnd: attribute.nameSpanEnd,
							valueSpanStart: attribute.valueSpanStart,
							valueSpanEnd: attribute.valueSpanEnd
						}
					}
				];
				var rewrittenBody = [
					for (item in body) {
						var rewritten = rewrite(item, knownStrings);
						if (rewritten != item) changed = true;
						rewritten;
					}
				];
				changed ? makeASTWithMeta(EModule(name, rewrittenAttributes, rewrittenBody), node.metadata, node.pos) : node;

			case EDefmodule(name, doBlock):
				var rewritten = rewrite(doBlock, copyEnv(knownStrings));
				rewritten != doBlock ? makeASTWithMeta(EDefmodule(name, rewritten), node.metadata, node.pos) : node;

			case EFn(clauses):
				var changed = false;
				var rewrittenClauses = [
					for (clause in clauses) {
						var scoped = copyEnv(knownStrings);
						for (arg in clause.args)
							removePatternBindings(scoped, arg);
						var guard = clause.guard == null ? null : rewrite(clause.guard, scoped);
						var body = rewrite(clause.body, scoped);
						if (guard != clause.guard || body != clause.body) changed = true;
						{
							args: clause.args,
							guard: guard,
							body: body
						};
					}
				];
				changed ? makeASTWithMeta(EFn(rewrittenClauses), node.metadata, node.pos) : node;

			case EDef(name, args, guards, body):
				var scoped = copyEnv(knownStrings);
				for (arg in args)
					removePatternBindings(scoped, arg);
				var rewrittenGuards = guards == null ? null : rewrite(guards, scoped);
				var rewrittenBody = rewrite(body, scoped);
				(rewrittenGuards != guards || rewrittenBody != body) ? makeASTWithMeta(EDef(name, args, rewrittenGuards, rewrittenBody), node.metadata,
					node.pos) : node;

			case EDefp(name, args, guards, body):
				var scoped = copyEnv(knownStrings);
				for (arg in args)
					removePatternBindings(scoped, arg);
				var rewrittenGuards = guards == null ? null : rewrite(guards, scoped);
				var rewrittenBody = rewrite(body, scoped);
				(rewrittenGuards != guards || rewrittenBody != body) ? makeASTWithMeta(EDefp(name, args, rewrittenGuards, rewrittenBody), node.metadata,
					node.pos) : node;

			case EDefmacro(name, args, guards, body):
				var scoped = copyEnv(knownStrings);
				for (arg in args)
					removePatternBindings(scoped, arg);
				var rewrittenGuards = guards == null ? null : rewrite(guards, scoped);
				var rewrittenBody = rewrite(body, scoped);
				(rewrittenGuards != guards || rewrittenBody != body) ? makeASTWithMeta(EDefmacro(name, args, rewrittenGuards, rewrittenBody), node.metadata,
					node.pos) : node;

			case EDefmacrop(name, args, guards, body):
				var scoped = copyEnv(knownStrings);
				for (arg in args)
					removePatternBindings(scoped, arg);
				var rewrittenGuards = guards == null ? null : rewrite(guards, scoped);
				var rewrittenBody = rewrite(body, scoped);
				(rewrittenGuards != guards || rewrittenBody != body) ? makeASTWithMeta(EDefmacrop(name, args, rewrittenGuards, rewrittenBody), node.metadata,
					node.pos) : node;

			case ECase(expr, clauses):
				var rewrittenExpr = rewrite(expr, knownStrings);
				var changed = rewrittenExpr != expr;
				var rewrittenClauses = [
					for (clause in clauses) {
						var scoped = copyEnv(knownStrings);
						removePatternBindings(scoped, clause.pattern);
						var guard = clause.guard == null ? null : rewrite(clause.guard, scoped);
						var body = rewrite(clause.body, scoped);
						if (guard != clause.guard || body != clause.body) changed = true;
						{
							pattern: clause.pattern,
							guard: guard,
							body: body
						};
					}
				];
				changed ? makeASTWithMeta(ECase(rewrittenExpr, rewrittenClauses), node.metadata, node.pos) : node;

			case ECond(clauses):
				var changed = false;
				var rewrittenClauses = [
					for (clause in clauses) {
						var condition = rewrite(clause.condition, knownStrings);
						var body = rewrite(clause.body, copyEnv(knownStrings));
						if (condition != clause.condition || body != clause.body) changed = true;
						{
							condition: condition,
							body: body
						}
					}
				];
				changed ? makeASTWithMeta(ECond(rewrittenClauses), node.metadata, node.pos) : node;

			case EWith(clauses, doBlock, elseBlock):
				var scoped = copyEnv(knownStrings);
				var changed = false;
				var rewrittenClauses = [
					for (clause in clauses) {
						var expr = rewrite(clause.expr, scoped);
						if (expr != clause.expr) changed = true;
						removePatternBindings(scoped, clause.pattern);
						{pattern: clause.pattern, expr: expr};
					}
				];
				var rewrittenDoBlock = rewrite(doBlock, scoped);
				var rewrittenElseBlock = elseBlock == null ? null : rewrite(elseBlock, copyEnv(knownStrings));
				if (rewrittenDoBlock != doBlock || rewrittenElseBlock != elseBlock)
					changed = true;
				changed ? makeASTWithMeta(EWith(rewrittenClauses, rewrittenDoBlock, rewrittenElseBlock), node.metadata, node.pos) : node;

			case EIf(condition, thenBranch, elseBranch):
				var rewrittenCondition = rewrite(condition, knownStrings);
				var rewrittenThen = rewrite(thenBranch, copyEnv(knownStrings));
				var rewrittenElse = elseBranch == null ? null : rewrite(elseBranch, copyEnv(knownStrings));
					(rewrittenCondition != condition || rewrittenThen != thenBranch || rewrittenElse != elseBranch) ? makeASTWithMeta(EIf(rewrittenCondition,
						rewrittenThen, rewrittenElse), node.metadata, node.pos) : node;

			case EUnless(condition, body, elseBranch):
				var rewrittenCondition = rewrite(condition, knownStrings);
				var rewrittenBody = rewrite(body, copyEnv(knownStrings));
				var rewrittenElse = elseBranch == null ? null : rewrite(elseBranch, copyEnv(knownStrings));
					(rewrittenCondition != condition || rewrittenBody != body || rewrittenElse != elseBranch) ? makeASTWithMeta(EUnless(rewrittenCondition,
						rewrittenBody, rewrittenElse), node.metadata, node.pos) : node;

			case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
				var changed = false;
				var rewrittenBody = rewrite(body, copyEnv(knownStrings));
				if (rewrittenBody != body)
					changed = true;
				var rewrittenRescueClauses = [
					for (clause in rescueClauses) {
						var scoped = copyEnv(knownStrings);
						removePatternBindings(scoped, clause.pattern);
						if (clause.varName != null) scoped.remove(clause.varName);
						var clauseBody = rewrite(clause.body, scoped);
						if (clauseBody != clause.body) changed = true;
						{pattern: clause.pattern, varName: clause.varName, body: clauseBody};
					}
				];
				var rewrittenCatchClauses = [
					for (clause in catchClauses) {
						var scoped = copyEnv(knownStrings);
						removePatternBindings(scoped, clause.pattern);
						var clauseBody = rewrite(clause.body, scoped);
						if (clauseBody != clause.body) changed = true;
						{kind: clause.kind, pattern: clause.pattern, body: clauseBody};
					}
				];
				var rewrittenAfterBlock = afterBlock == null ? null : rewrite(afterBlock, copyEnv(knownStrings));
				var rewrittenElseBlock = elseBlock == null ? null : rewrite(elseBlock, copyEnv(knownStrings));
				if (rewrittenAfterBlock != afterBlock || rewrittenElseBlock != elseBlock)
					changed = true;
				changed ? makeASTWithMeta(ETry(rewrittenBody, rewrittenRescueClauses, rewrittenCatchClauses, rewrittenAfterBlock, rewrittenElseBlock),
					node.metadata, node.pos) : node;

			case ERaise(exception, attributes):
				var rewrittenException = rewrite(exception, knownStrings);
				var rewrittenAttributes = attributes == null ? null : rewrite(attributes, knownStrings);
					(rewrittenException != exception || rewrittenAttributes != attributes) ? makeASTWithMeta(ERaise(rewrittenException, rewrittenAttributes),
						node.metadata, node.pos) : node;

			case EThrow(value):
				var rewritten = rewrite(value, knownStrings);
				rewritten != value ? makeASTWithMeta(EThrow(rewritten), node.metadata, node.pos) : node;

			case EField(target, "length"):
				var rewrittenTarget = rewrite(target, knownStrings);
				switch (rewrittenTarget.def) {
					case EVar(name) if (knownStrings.exists(name)):
						makeASTWithMeta(ERemoteCall(makeAST(EVar("String")), "length", [rewrittenTarget]), node.metadata, node.pos);
					default:
						rewrittenTarget != target ? makeASTWithMeta(EField(rewrittenTarget, "length"), node.metadata, node.pos) : node;
				}

			case EMatch(pattern, expr):
				var rewritten = rewrite(expr, knownStrings);
				rewritten != expr ? makeASTWithMeta(EMatch(pattern, rewritten), node.metadata, node.pos) : node;

			case EBinary(Match, left, right):
				var rewrittenRight = rewrite(right, knownStrings);
				rewrittenRight != right ? makeASTWithMeta(EBinary(Match, left, rewrittenRight), node.metadata, node.pos) : node;

			case EBinary(op, left, right):
				var rewrittenLeft = rewrite(left, knownStrings);
				var rewrittenRight = rewrite(right, knownStrings);
				(rewrittenLeft != left || rewrittenRight != right) ? makeASTWithMeta(EBinary(op, rewrittenLeft, rewrittenRight), node.metadata,
					node.pos) : node;

			case EUnary(op, expr):
				var rewritten = rewrite(expr, knownStrings);
				rewritten != expr ? makeASTWithMeta(EUnary(op, rewritten), node.metadata, node.pos) : node;

			case EParen(expr):
				var rewritten = rewrite(expr, knownStrings);
				rewritten != expr ? makeASTWithMeta(EParen(rewritten), node.metadata, node.pos) : node;

			case ECall(target, funcName, args):
				var changed = false;
				var rewrittenTarget = target == null ? null : rewrite(target, knownStrings);
				if (rewrittenTarget != target)
					changed = true;
				var rewrittenArgs = [
					for (arg in args) {
						var rewrittenArg = rewrite(arg, knownStrings);
						if (rewrittenArg != arg) changed = true;
						rewrittenArg;
					}
				];
				changed ? makeASTWithMeta(ECall(rewrittenTarget, funcName, rewrittenArgs), node.metadata, node.pos) : node;

			case EMacroCall(macroName, args, doBlock):
				var changed = false;
				var rewrittenArgs = [
					for (arg in args) {
						var rewrittenArg = rewrite(arg, knownStrings);
						if (rewrittenArg != arg) changed = true;
						rewrittenArg;
					}
				];
				var rewrittenDoBlock = rewrite(doBlock, copyEnv(knownStrings));
				if (rewrittenDoBlock != doBlock)
					changed = true;
				changed ? makeASTWithMeta(EMacroCall(macroName, rewrittenArgs, rewrittenDoBlock), node.metadata, node.pos) : node;

			case ERemoteCall(module, funcName, args):
				var changed = false;
				var rewrittenModule = rewrite(module, knownStrings);
				if (rewrittenModule != module)
					changed = true;
				var rewrittenArgs = [
					for (arg in args) {
						var rewrittenArg = rewrite(arg, knownStrings);
						if (rewrittenArg != arg) changed = true;
						rewrittenArg;
					}
				];
				changed ? makeASTWithMeta(ERemoteCall(rewrittenModule, funcName, rewrittenArgs), node.metadata, node.pos) : node;

			case EPipe(left, right):
				var rewrittenLeft = rewrite(left, knownStrings);
				var rewrittenRight = rewrite(right, knownStrings);
				(rewrittenLeft != left || rewrittenRight != right) ? makeASTWithMeta(EPipe(rewrittenLeft, rewrittenRight), node.metadata, node.pos) : node;

			case EField(target, field):
				var rewritten = rewrite(target, knownStrings);
				rewritten != target ? makeASTWithMeta(EField(rewritten, field), node.metadata, node.pos) : node;

			case EAccess(target, key):
				var rewrittenTarget = rewrite(target, knownStrings);
				var rewrittenKey = rewrite(key, knownStrings);
				(rewrittenTarget != target || rewrittenKey != key) ? makeASTWithMeta(EAccess(rewrittenTarget, rewrittenKey), node.metadata, node.pos) : node;

			case ERange(start, end, exclusive, step):
				var rewrittenStart = rewrite(start, knownStrings);
				var rewrittenEnd = rewrite(end, knownStrings);
				var rewrittenStep = step == null ? null : rewrite(step, knownStrings);
					(rewrittenStart != start || rewrittenEnd != end || rewrittenStep != step) ? makeASTWithMeta(ERange(rewrittenStart, rewrittenEnd,
						exclusive, rewrittenStep), node.metadata, node.pos) : node;

			case EList(elements):
				var changed = false;
				var rewrittenElements = [
					for (element in elements) {
						var rewritten = rewrite(element, knownStrings);
						if (rewritten != element) changed = true;
						rewritten;
					}
				];
				changed ? makeASTWithMeta(EList(rewrittenElements), node.metadata, node.pos) : node;

			case ETuple(elements):
				var changed = false;
				var rewrittenElements = [
					for (element in elements) {
						var rewritten = rewrite(element, knownStrings);
						if (rewritten != element) changed = true;
						rewritten;
					}
				];
				changed ? makeASTWithMeta(ETuple(rewrittenElements), node.metadata, node.pos) : node;

			case EMap(pairs):
				var changed = false;
				var rewrittenPairs = [
					for (pair in pairs) {
						var key = rewrite(pair.key, knownStrings);
						var value = rewrite(pair.value, knownStrings);
						if (key != pair.key || value != pair.value) changed = true;
						{key: key, value: value};
					}
				];
				changed ? makeASTWithMeta(EMap(rewrittenPairs), node.metadata, node.pos) : node;

			case EStruct(module, fields):
				var changed = false;
				var rewrittenFields = [
					for (field in fields) {
						var value = rewrite(field.value, knownStrings);
						if (value != field.value) changed = true;
						{key: field.key, value: value};
					}
				];
				changed ? makeASTWithMeta(EStruct(module, rewrittenFields), node.metadata, node.pos) : node;

			case EStructUpdate(struct, fields):
				var changed = false;
				var rewrittenStruct = rewrite(struct, knownStrings);
				if (rewrittenStruct != struct)
					changed = true;
				var rewrittenFields = [
					for (field in fields) {
						var value = rewrite(field.value, knownStrings);
						if (value != field.value) changed = true;
						{key: field.key, value: value};
					}
				];
				changed ? makeASTWithMeta(EStructUpdate(rewrittenStruct, rewrittenFields), node.metadata, node.pos) : node;

			case EKeywordList(pairs):
				var changed = false;
				var rewrittenPairs = [
					for (pair in pairs) {
						var value = rewrite(pair.value, knownStrings);
						if (value != pair.value) changed = true;
						{key: pair.key, value: value};
					}
				];
				changed ? makeASTWithMeta(EKeywordList(rewrittenPairs), node.metadata, node.pos) : node;

			case EBitstring(segments):
				var changed = false;
				var rewrittenSegments = [
					for (segment in segments) {
						var value = rewrite(segment.value, knownStrings);
						var size = segment.size == null ? null : rewrite(segment.size, knownStrings);
						if (value != segment.value || size != segment.size) changed = true;
						{
							value: value,
							size: size,
							type: segment.type,
							modifiers: segment.modifiers
						}
					}
				];
				changed ? makeASTWithMeta(EBitstring(rewrittenSegments), node.metadata, node.pos) : node;

			case EFor(generators, filters, body, into, uniq):
				var scoped = copyEnv(knownStrings);
				var changed = false;
				var rewrittenGenerators = [
					for (generator in generators) {
						var expr = rewrite(generator.expr, scoped);
						if (expr != generator.expr) changed = true;
						removePatternBindings(scoped, generator.pattern);
						{pattern: generator.pattern, expr: expr};
					}
				];
				var rewrittenFilters = [
					for (filter in filters) {
						var rewritten = rewrite(filter, scoped);
						if (rewritten != filter) changed = true;
						rewritten;
					}
				];
				var rewrittenBody = rewrite(body, scoped);
				var rewrittenInto = into == null ? null : rewrite(into, knownStrings);
				if (rewrittenBody != body || rewrittenInto != into)
					changed = true;
				changed ? makeASTWithMeta(EFor(rewrittenGenerators, rewrittenFilters, rewrittenBody, rewrittenInto, uniq), node.metadata, node.pos) : node;

			case EPin(expr):
				var rewritten = rewrite(expr, knownStrings);
				rewritten != expr ? makeASTWithMeta(EPin(rewritten), node.metadata, node.pos) : node;

			case ECapture(expr, arity):
				var rewritten = rewrite(expr, knownStrings);
				rewritten != expr ? makeASTWithMeta(ECapture(rewritten, arity), node.metadata, node.pos) : node;

			case EUse(module, options):
				var changed = false;
				var rewrittenOptions = options == null ? [] : [
					for (option in options) {
						var rewritten = rewrite(option, knownStrings);
						if (rewritten != option) changed = true;
						rewritten;
					}
				];
				changed ? makeASTWithMeta(EUse(module, rewrittenOptions), node.metadata, node.pos) : node;

			case EModuleAttribute(name, value):
				var rewritten = rewrite(value, knownStrings);
				rewritten != value ? makeASTWithMeta(EModuleAttribute(name, rewritten), node.metadata, node.pos) : node;

			case EQuote(options, expr):
				var changed = false;
				var rewrittenOptions = options == null ? [] : [
					for (option in options) {
						var rewritten = rewrite(option, knownStrings);
						if (rewritten != option) changed = true;
						rewritten;
					}
				];
				var rewrittenExpr = rewrite(expr, knownStrings);
				if (rewrittenExpr != expr)
					changed = true;
				changed ? makeASTWithMeta(EQuote(rewrittenOptions, rewrittenExpr), node.metadata, node.pos) : node;

			case EUnquote(expr):
				var rewritten = rewrite(expr, knownStrings);
				rewritten != expr ? makeASTWithMeta(EUnquote(rewritten), node.metadata, node.pos) : node;

			case EUnquoteSplicing(expr):
				var rewritten = rewrite(expr, knownStrings);
				rewritten != expr ? makeASTWithMeta(EUnquoteSplicing(rewritten), node.metadata, node.pos) : node;

			case EReceive(clauses, after):
				var changed = false;
				var rewrittenClauses = [
					for (clause in clauses) {
						var scoped = copyEnv(knownStrings);
						removePatternBindings(scoped, clause.pattern);
						var guard = clause.guard == null ? null : rewrite(clause.guard, scoped);
						var body = rewrite(clause.body, scoped);
						if (guard != clause.guard || body != clause.body) changed = true;
						{
							pattern: clause.pattern,
							guard: guard,
							body: body
						};
					}
				];
				var rewrittenAfter = after == null ? null : {
					timeout: rewrite(after.timeout, knownStrings),
					body: rewrite(after.body, copyEnv(knownStrings))
				};
				if (after != null && (rewrittenAfter.timeout != after.timeout || rewrittenAfter.body != after.body))
					changed = true;
				changed ? makeASTWithMeta(EReceive(rewrittenClauses, rewrittenAfter), node.metadata, node.pos) : node;

			case ESend(target, message):
				var rewrittenTarget = rewrite(target, knownStrings);
				var rewrittenMessage = rewrite(message, knownStrings);
				(rewrittenTarget != target || rewrittenMessage != message) ? makeASTWithMeta(ESend(rewrittenTarget, rewrittenMessage), node.metadata,
					node.pos) : node;

			case EFragment(tag, attributes, children):
				var changed = false;
				var rewrittenAttributes = attributes == null ? [] : [
					for (attribute in attributes) {
						var value = rewrite(attribute.value, knownStrings);
						if (value != attribute.value) changed = true;
						{
							name: attribute.name,
							value: value,
							nameSpanStart: attribute.nameSpanStart,
							nameSpanEnd: attribute.nameSpanEnd,
							valueSpanStart: attribute.valueSpanStart,
							valueSpanEnd: attribute.valueSpanEnd
						}
					}
				];
				var rewrittenChildren = children == null ? [] : [
					for (child in children) {
						var rewritten = rewrite(child, knownStrings);
						if (rewritten != child) changed = true;
						rewritten;
					}
				];
				changed ? makeASTWithMeta(EFragment(tag, rewrittenAttributes, rewrittenChildren), node.metadata, node.pos) : node;

			default:
				node;
		}
	}

	static function updateKnownStringBinding(knownStrings:Map<String, Bool>, node:ElixirAST):Void {
		if (node == null)
			return;
		switch (node.def) {
			case EMatch(PVar(name), expr):
				setKnownString(knownStrings, name, isKnownStringExpr(expr, knownStrings));
			case EBinary(Match, {def: EVar(name)}, expr):
				setKnownString(knownStrings, name, isKnownStringExpr(expr, knownStrings));
			default:
		}
	}

	static function setKnownString(knownStrings:Map<String, Bool>, name:String, isString:Bool):Void {
		if (name == null || name == "_")
			return;
		if (isString)
			knownStrings.set(name, true);
		else
			knownStrings.remove(name);
	}

	static function isKnownStringExpr(expr:ElixirAST, knownStrings:Map<String, Bool>):Bool {
		if (expr == null)
			return false;
		return switch (expr.def) {
			case EString(_): true;
			case EVar(name): knownStrings.exists(name);
			case EBinary(StringConcat, left, right): isKnownStringExpr(left, knownStrings) || isKnownStringExpr(right, knownStrings);
			default: false;
		}
	}

	static function removePatternBindings(knownStrings:Map<String, Bool>, pattern:EPattern):Void {
		switch (pattern) {
			case PVar(name):
				knownStrings.remove(name);
			case PTuple(elements) | PList(elements):
				for (element in elements)
					removePatternBindings(knownStrings, element);
			case PCons(head, tail):
				removePatternBindings(knownStrings, head);
				removePatternBindings(knownStrings, tail);
			case PMap(pairs):
				for (pair in pairs)
					removePatternBindings(knownStrings, pair.value);
			case PStruct(_, fields):
				for (field in fields)
					removePatternBindings(knownStrings, field.value);
			case PPin(inner):
				removePatternBindings(knownStrings, inner);
			case PAlias(varName, inner):
				knownStrings.remove(varName);
				removePatternBindings(knownStrings, inner);
			case PBinary(_):
			case PLiteral(_) | PWildcard:
		}
	}

	static function copyEnv(source:Map<String, Bool>):Map<String, Bool> {
		var out = new Map();
		for (key in source.keys())
			out.set(key, source.get(key));
		return out;
	}
}
#end
