package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.EBinaryOp;
import reflaxe.elixir.ast.ElixirAST.ReceiverResultShape;
import reflaxe.elixir.ast.ElixirAST.ReceiverValueProjection;
import reflaxe.elixir.ast.ElixirAST.ReceiverWriteback;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

private enum ExpressionUse {
	Value;
	Discarded;
	AssignmentRhs;
}

private typedef ExprPlan = {
	prelude:Array<ElixirAST>,
	value:ElixirAST
};

/**
 * ReceiverEffectLoweringTransforms
 *
 * WHAT
 * - Legalizes persistent receiver updates before ordinary AST cleanup/IIFE passes.
 *
 * WHY
 * - Haxe mutation against a map-like receiver has two distinct semantics on Elixir:
 *   the operation produces an updated persistent value, and statement position may
 *   need to rebind the original receiver in the caller scope. Encoding that as an
 *   ordinary block lets later IIFE repair isolate the rebind and lose mutation.
 *
 * HOW
 * - Builders emit `EReceiverEffect` while they still know the receiver l-value.
 * - This pass composes strict expression contexts left-to-right and materializes
 *   receiver rebind preludes in the nearest statement scope.
 *
 * EXAMPLE
 * - Haxe: `(map["foo"] = 1) == 1`
 * - Legalized: `map = ReflectSet(...); 1 == 1` after the inlined setter's final
 *   scalar expression remains the comparison operand.
 */
class ReceiverEffectLoweringTransforms {
	static var tempCounter:Int = 0;

	public static function pass(ast:ElixirAST):ElixirAST {
		tempCounter = 0;
		return lowerStatementScope(ast, Value);
	}

	public static function contextualPass(ast:ElixirAST, context:reflaxe.elixir.CompilationContext):ElixirAST {
		return pass(ast);
	}

	static function lowerStatementScope(node:ElixirAST, use:ExpressionUse):ElixirAST {
		if (node == null)
			return node;

		return switch (node.def) {
			case EModule(name, attributes, body):
				makeASTWithMeta(EModule(name, attributes, body.map(function(statement) return lowerStatementScope(statement, Discarded))), node.metadata,
					node.pos);
			case EDefmodule(name, doBlock):
				makeASTWithMeta(EDefmodule(name, lowerStatementScope(doBlock, Value)), node.metadata, node.pos);
			case EDef(name, args, guards, body):
				makeASTWithMeta(EDef(name, args, guards != null ? lowerExpression(guards, Value).value : null, lowerStatementScope(body, Value)),
					node.metadata, node.pos);
			case EDefp(name, args, guards, body):
				makeASTWithMeta(EDefp(name, args, guards != null ? lowerExpression(guards, Value).value : null, lowerStatementScope(body, Value)),
					node.metadata, node.pos);
			case EDefmacro(name, args, guards, body):
				makeASTWithMeta(EDefmacro(name, args, guards != null ? lowerExpression(guards, Value).value : null, lowerStatementScope(body, Value)),
					node.metadata, node.pos);
			case EDefmacrop(name, args, guards, body):
				makeASTWithMeta(EDefmacrop(name, args, guards != null ? lowerExpression(guards, Value).value : null, lowerStatementScope(body, Value)),
					node.metadata, node.pos);
			case EBlock(statements):
				makeASTWithMeta(EBlock(lowerStatementList(statements, use)), node.metadata, node.pos);
			case EDo(statements):
				makeASTWithMeta(EDo(lowerStatementList(statements, use)), node.metadata, node.pos);
			case EFn(clauses):
				makeASTWithMeta(EFn(clauses.map(function(clause) {
					return {
						args: clause.args,
						guard: clause.guard != null ? lowerExpression(clause.guard, Value).value : null,
						body: lowerStatementScope(clause.body, Value)
					};
				})), node.metadata, node.pos);
			case ECase(expr, clauses):
				var exprPlan = lowerExpression(expr, Value);
				var rebuilt = makeASTWithMeta(ECase(exprPlan.value, clauses.map(function(clause) {
					return {
						pattern: clause.pattern,
						guard: clause.guard != null ? lowerExpression(clause.guard, Value).value : null,
						body: lowerStatementScope(clause.body, Value)
					};
				})), node.metadata, node.pos);
				materialize(exprPlan.prelude, rebuilt, node);
			case EIf(condition, thenBranch, elseBranch):
				var conditionPlan = lowerExpression(condition, Value);
				var rebuilt = makeASTWithMeta(EIf(conditionPlan.value, lowerStatementScope(thenBranch, Value),
					elseBranch != null ? lowerStatementScope(elseBranch, Value) : null),
					node.metadata, node.pos);
				materialize(conditionPlan.prelude, rebuilt, node);
			case EUnless(condition, body, elseBranch):
				var conditionPlan = lowerExpression(condition, Value);
				var rebuilt = makeASTWithMeta(EUnless(conditionPlan.value, lowerStatementScope(body, Value),
					elseBranch != null ? lowerStatementScope(elseBranch, Value) : null),
					node.metadata, node.pos);
				materialize(conditionPlan.prelude, rebuilt, node);
			case ECond(clauses):
				makeASTWithMeta(ECond(clauses.map(function(clause) {
					var conditionPlan = lowerExpression(clause.condition, Value);
					return {
						condition: materialize(conditionPlan.prelude, conditionPlan.value, clause.condition),
						body: lowerStatementScope(clause.body, Value)
					};
				})), node.metadata, node.pos);
			case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
				makeASTWithMeta(ETry(lowerStatementScope(body, Value), rescueClauses.map(function(clause) {
					return {
						pattern: clause.pattern,
						varName: clause.varName,
						body: lowerStatementScope(clause.body, Value)
					};
				}), catchClauses.map(function(clause) {
					return {
						kind: clause.kind,
						pattern: clause.pattern,
						body: lowerStatementScope(clause.body, Value)
					};
				}),
					afterBlock != null ? lowerStatementScope(afterBlock, Discarded) : null,
					elseBlock != null ? lowerStatementScope(elseBlock, Value) : null), node.metadata, node.pos);
			default:
				var plan = lowerExpression(node, use);
				materialize(plan.prelude, plan.value, node);
		}
	}

	static function lowerStatementList(statements:Array<ElixirAST>, finalUse:ExpressionUse):Array<ElixirAST> {
		var out:Array<ElixirAST> = [];
		for (i in 0...statements.length) {
			var statementUse = i == statements.length - 1 ? finalUse : Discarded;
			var plan = lowerExpression(statements[i], statementUse);
			for (preludeStatement in plan.prelude)
				out.push(preludeStatement);
			if (!(statementUse == Discarded && isNil(plan.value) && plan.prelude.length > 0))
				out.push(plan.value);
		}
		return out;
	}

	static function lowerExpression(node:ElixirAST, use:ExpressionUse):ExprPlan {
		if (node == null)
			return {prelude: [], value: node};

		return switch (node.def) {
			case EReceiverEffect(effect):
				lowerReceiverEffect(effect, use, node);
			case EParen(inner):
				var plan = lowerExpression(inner, use);
				plan.prelude.length == 0 ? {prelude: [], value: makeASTWithMeta(EParen(plan.value), node.metadata, node.pos)} : plan;
			case EBlock(statements):
				lowerBlockExpression(statements, use, function(lowered) return makeASTWithMeta(EBlock(lowered), node.metadata, node.pos));
			case EDo(statements):
				lowerBlockExpression(statements, use, function(lowered) return makeASTWithMeta(EDo(lowered), node.metadata, node.pos));
			case EMatch(pattern, expr):
				var exprPlan = lowerExpression(expr, AssignmentRhs);
				{prelude: exprPlan.prelude, value: makeASTWithMeta(EMatch(pattern, exprPlan.value), node.metadata, node.pos)};
			case EWith(clauses, doBlock, elseBlock):
				var prelude:Array<ElixirAST> = [];
				var loweredClauses = clauses.map(function(clause) {
					var plan = lowerExpression(clause.expr, Value);
					prelude = prelude.concat(plan.prelude);
					return {pattern: clause.pattern, expr: plan.value};
				});
				{
					prelude: prelude,
					value: makeASTWithMeta(EWith(loweredClauses, lowerStatementScope(doBlock, Value),
						elseBlock != null ? lowerStatementScope(elseBlock, Value) : null),
						node.metadata, node.pos)
				};
			case EBinary(op, left, right) if (isStrictBinary(op)):
				var leftPlan = lowerExpression(left, Value);
				var rightPlan = lowerExpression(right, Value);
				{
					prelude: leftPlan.prelude.concat(rightPlan.prelude),
					value: makeASTWithMeta(EBinary(op, leftPlan.value, rightPlan.value), node.metadata, node.pos)
				};
			case EBinary(op, left, right):
				var leftPlan = lowerExpression(left, Value);
				var rightPlan = lowerExpression(right, Value);
				{
					prelude: leftPlan.prelude,
					value: makeASTWithMeta(EBinary(op, leftPlan.value, materialize(rightPlan.prelude, rightPlan.value, right)), node.metadata, node.pos)
				};
			case EUnary(op, expr):
				var plan = lowerExpression(expr, Value);
				{prelude: plan.prelude, value: makeASTWithMeta(EUnary(op, plan.value), node.metadata, node.pos)};
			case EMacroCall(macroName, args, doBlock):
				var prelude:Array<ElixirAST> = [];
				var newArgs:Array<ElixirAST> = [];
				for (arg in args) {
					var argPlan = lowerExpression(arg, Value);
					prelude = prelude.concat(argPlan.prelude);
					newArgs.push(argPlan.value);
				}
				{prelude: prelude, value: makeASTWithMeta(EMacroCall(macroName, newArgs, lowerStatementScope(doBlock, Value)), node.metadata, node.pos)};
			case ECall({def: EFn(clauses)}, "", []) if (clauses.length == 1 && clauses[0].args.length == 0 && clauses[0].guard == null):
				var plan = lowerExpression(clauses[0].body, use);
				if (plan.prelude.length > 0) {
					plan;
				} else {
					{
						prelude: [],
						value: makeASTWithMeta(ECall(makeASTWithMeta(EFn([
							{
								args: [],
								guard: null,
								body: plan.value
							}
						]), node.metadata, node.pos), "", []), node.metadata, node.pos)
					};
				}
			case ECall(target, functionName, args):
				var prelude:Array<ElixirAST> = [];
				var newTarget:Null<ElixirAST> = null;
				if (target != null) {
					var targetPlan = lowerExpression(target, Value);
					prelude = prelude.concat(targetPlan.prelude);
					newTarget = targetPlan.value;
				}
				var newArgs:Array<ElixirAST> = [];
				for (arg in args) {
					var argPlan = lowerExpression(arg, Value);
					prelude = prelude.concat(argPlan.prelude);
					newArgs.push(argPlan.value);
				}
				{prelude: prelude, value: makeASTWithMeta(ECall(newTarget, functionName, newArgs), node.metadata, node.pos)};
			case ERemoteCall(module, functionName, args):
				var modulePlan = lowerExpression(module, Value);
				var prelude = modulePlan.prelude.copy();
				var newArgs:Array<ElixirAST> = [];
				for (arg in args) {
					var argPlan = lowerExpression(arg, Value);
					prelude = prelude.concat(argPlan.prelude);
					newArgs.push(argPlan.value);
				}
				{prelude: prelude, value: makeASTWithMeta(ERemoteCall(modulePlan.value, functionName, newArgs), node.metadata, node.pos)};
			case EPipe(left, right):
				var leftPlan = lowerExpression(left, Value);
				var rightPlan = lowerExpression(right, Value);
				{
					prelude: leftPlan.prelude.concat(rightPlan.prelude),
					value: makeASTWithMeta(EPipe(leftPlan.value, rightPlan.value), node.metadata, node.pos)
				};
			case EAccess(target, key):
				var targetPlan = lowerExpression(target, Value);
				var keyPlan = lowerExpression(key, Value);
				{
					prelude: targetPlan.prelude.concat(keyPlan.prelude),
					value: makeASTWithMeta(EAccess(targetPlan.value, keyPlan.value), node.metadata, node.pos)
				};
			case EField(target, field):
				var targetPlan = lowerExpression(target, Value);
				{prelude: targetPlan.prelude, value: makeASTWithMeta(EField(targetPlan.value, field), node.metadata, node.pos)};
			case EList(elements):
				lowerElementList(elements, function(values) return makeASTWithMeta(EList(values), node.metadata, node.pos));
			case ETuple(elements):
				lowerElementList(elements, function(values) return makeASTWithMeta(ETuple(values), node.metadata, node.pos));
			case EMap(pairs):
				var prelude:Array<ElixirAST> = [];
				var newPairs = [];
				for (pair in pairs) {
					var keyPlan = lowerExpression(pair.key, Value);
					var valuePlan = lowerExpression(pair.value, Value);
					prelude = prelude.concat(keyPlan.prelude).concat(valuePlan.prelude);
					newPairs.push({key: keyPlan.value, value: valuePlan.value});
				}
				{prelude: prelude, value: makeASTWithMeta(EMap(newPairs), node.metadata, node.pos)};
			case EStruct(module, fields):
				var prelude:Array<ElixirAST> = [];
				var newFields = [];
				for (field in fields) {
					var plan = lowerExpression(field.value, Value);
					prelude = prelude.concat(plan.prelude);
					newFields.push({key: field.key, value: plan.value});
				}
				{prelude: prelude, value: makeASTWithMeta(EStruct(module, newFields), node.metadata, node.pos)};
			case EStructUpdate(struct, fields):
				var structPlan = lowerExpression(struct, Value);
				var prelude = structPlan.prelude.copy();
				var newFields = [];
				for (field in fields) {
					var plan = lowerExpression(field.value, Value);
					prelude = prelude.concat(plan.prelude);
					newFields.push({key: field.key, value: plan.value});
				}
				{prelude: prelude, value: makeASTWithMeta(EStructUpdate(structPlan.value, newFields), node.metadata, node.pos)};
			case EKeywordList(pairs):
				var prelude:Array<ElixirAST> = [];
				var newPairs = [];
				for (pair in pairs) {
					var plan = lowerExpression(pair.value, Value);
					prelude = prelude.concat(plan.prelude);
					newPairs.push({key: pair.key, value: plan.value});
				}
				{prelude: prelude, value: makeASTWithMeta(EKeywordList(newPairs), node.metadata, node.pos)};
			case EBitstring(segments):
				var prelude:Array<ElixirAST> = [];
				var newSegments = [];
				for (segment in segments) {
					var valuePlan = lowerExpression(segment.value, Value);
					prelude = prelude.concat(valuePlan.prelude);
					var loweredSize = segment.size;
					if (segment.size != null) {
						var sizePlan = lowerExpression(segment.size, Value);
						prelude = prelude.concat(sizePlan.prelude);
						loweredSize = sizePlan.value;
					}
					newSegments.push({
						value: valuePlan.value,
						size: loweredSize,
						type: segment.type,
						modifiers: segment.modifiers
					});
				}
				{prelude: prelude, value: makeASTWithMeta(EBitstring(newSegments), node.metadata, node.pos)};
			case ERange(start, end, exclusive, step):
				var startPlan = lowerExpression(start, Value);
				var endPlan = lowerExpression(end, Value);
				var prelude = startPlan.prelude.concat(endPlan.prelude);
				var loweredStep = null;
				if (step != null) {
					var stepPlan = lowerExpression(step, Value);
					prelude = prelude.concat(stepPlan.prelude);
					loweredStep = stepPlan.value;
				}
				{prelude: prelude, value: makeASTWithMeta(ERange(startPlan.value, endPlan.value, exclusive, loweredStep), node.metadata, node.pos)};
			case EFor(generators, filters, body, into, uniq):
				var prelude:Array<ElixirAST> = [];
				var loweredGenerators = generators.map(function(generator) {
					var plan = lowerExpression(generator.expr, Value);
					prelude = prelude.concat(plan.prelude);
					return {pattern: generator.pattern, expr: plan.value};
				});
				var loweredFilters = [];
				for (filter in filters) {
					var plan = lowerExpression(filter, Value);
					prelude = prelude.concat(plan.prelude);
					loweredFilters.push(plan.value);
				}
				var loweredInto = into;
				if (into != null) {
					var intoPlan = lowerExpression(into, Value);
					prelude = prelude.concat(intoPlan.prelude);
					loweredInto = intoPlan.value;
				}
				{
					prelude: prelude,
					value: makeASTWithMeta(EFor(loweredGenerators, loweredFilters, lowerStatementScope(body, Value), loweredInto, uniq), node.metadata,
						node.pos)
				};
			case ECapture(expr, arity):
				var plan = lowerExpression(expr, Value);
				{prelude: plan.prelude, value: makeASTWithMeta(ECapture(plan.value, arity), node.metadata, node.pos)};
			case EQuote(options, expr):
				var optionsPlan = lowerElementList(options, function(values) return makeASTWithMeta(EList(values), node.metadata, node.pos));
				var exprPlan = lowerExpression(expr, Value);
				{
					prelude: optionsPlan.prelude.concat(exprPlan.prelude),
					value: makeASTWithMeta(EQuote(switch (optionsPlan.value.def) {
						case EList(values): values;
						default: options;
					}, exprPlan.value), node.metadata, node.pos)
				};
			case EUnquote(expr):
				var plan = lowerExpression(expr, Value);
				{prelude: plan.prelude, value: makeASTWithMeta(EUnquote(plan.value), node.metadata, node.pos)};
			case EUnquoteSplicing(expr):
				var plan = lowerExpression(expr, Value);
				{prelude: plan.prelude, value: makeASTWithMeta(EUnquoteSplicing(plan.value), node.metadata, node.pos)};
			case EReceive(clauses, afterClause):
				{
					prelude: [],
					value: makeASTWithMeta(EReceive(clauses.map(function(clause) {
						return {
							pattern: clause.pattern,
							guard: clause.guard != null ? lowerExpression(clause.guard, Value).value : null,
							body: lowerStatementScope(clause.body, Value)
						};
					}), afterClause != null ? {
						timeout: lowerExpression(afterClause.timeout, Value).value,
						body: lowerStatementScope(afterClause.body, Value)
					} : null), node.metadata, node.pos)
				};
			case ESend(target, message):
				var targetPlan = lowerExpression(target, Value);
				var messagePlan = lowerExpression(message, Value);
				{
					prelude: targetPlan.prelude.concat(messagePlan.prelude),
					value: makeASTWithMeta(ESend(targetPlan.value, messagePlan.value), node.metadata, node.pos)
				};
			case EModuleAttribute(name, value):
				var plan = lowerExpression(value, Value);
				{prelude: plan.prelude, value: makeASTWithMeta(EModuleAttribute(name, plan.value), node.metadata, node.pos)};
			case EFragment(tag, attributes, children):
				var prelude:Array<ElixirAST> = [];
				var loweredAttributes = attributes.map(function(attribute) {
					var plan = lowerExpression(attribute.value, Value);
					prelude = prelude.concat(plan.prelude);
					return {
						name: attribute.name,
						value: plan.value,
						nameSpanStart: attribute.nameSpanStart,
						nameSpanEnd: attribute.nameSpanEnd,
						valueSpanStart: attribute.valueSpanStart,
						valueSpanEnd: attribute.valueSpanEnd
					};
				});
				var loweredChildren = [];
				for (child in children) {
					var plan = lowerExpression(child, Value);
					prelude = prelude.concat(plan.prelude);
					loweredChildren.push(plan.value);
				}
				{prelude: prelude, value: makeASTWithMeta(EFragment(tag, loweredAttributes, loweredChildren), node.metadata, node.pos)};
			case EIf(_, _, _) | EUnless(_, _, _) | ECase(_, _) | ECond(_) | ETry(_, _, _, _, _) | EFn(_):
				{prelude: [], value: lowerStatementScope(node, Value)};
			default:
				{prelude: [], value: node};
		}
	}

	static function lowerReceiverEffect(effect:ReceiverEffectData, use:ExpressionUse, source:ElixirAST):ExprPlan {
		var operationPlan = lowerExpression(effect.operation, Value);
		var shouldWriteBack = switch (effect.writeback) {
			case Never: false;
			case Always: true;
			case WhenDiscarded: use == Discarded;
		};

		return switch (effect.resultShape) {
			case UpdatedReceiver:
				var prelude = operationPlan.prelude.copy();
				var receiverValue = operationPlan.value;
				if (shouldWriteBack) {
					prelude.push(makeASTWithMeta(EMatch(PVar(effect.receiver.name), receiverValue), source.metadata, source.pos));
					receiverValue = use == Discarded ? makeAST(ENil) : makeAST(EVar(effect.receiver.name));
				}
				{prelude: prelude, value: projectValue(effect.valueProjection, makeAST(EVar(effect.receiver.name)), receiverValue, makeAST(ENil))};
			case UpdatedReceiverAndValue:
				var prelude = operationPlan.prelude.copy();
				var tempId = tempCounter++;
				var updatedName = shouldWriteBack ? effect.receiver.name : 'reflaxe_receiver_updated_${tempId}';
				var companionName = 'reflaxe_receiver_value_${tempId}';
				prelude.push(makeASTWithMeta(EMatch(PTuple([PVar(updatedName), PVar(companionName)]), operationPlan.value), source.metadata, source.pos));
				var updatedValue = makeAST(EVar(updatedName));
				var companionValue = makeAST(EVar(companionName));
				{prelude: prelude, value: use == Discarded ? makeAST(ENil) : projectValue(effect.valueProjection, updatedValue, updatedValue, companionValue)};
		}
	}

	static function projectValue(projection:ReceiverValueProjection, updatedValue:ElixirAST, receiverValue:ElixirAST, companionValue:ElixirAST):ElixirAST {
		return switch (projection) {
			case ReceiverValue: receiverValue;
			case CompanionValue: companionValue;
			case NoValue: makeAST(ENil);
		}
	}

	static function lowerElementList(elements:Array<ElixirAST>, rebuild:Array<ElixirAST>->ElixirAST):ExprPlan {
		var prelude:Array<ElixirAST> = [];
		var values:Array<ElixirAST> = [];
		for (element in elements) {
			var plan = lowerExpression(element, Value);
			prelude = prelude.concat(plan.prelude);
			values.push(plan.value);
		}
		return {prelude: prelude, value: rebuild(values)};
	}

	static function lowerBlockExpression(statements:Array<ElixirAST>, finalUse:ExpressionUse, rebuild:Array<ElixirAST>->ElixirAST):ExprPlan {
		var flattened:Array<ElixirAST> = [];
		var sawPrelude = false;
		for (i in 0...statements.length) {
			var statementUse = i == statements.length - 1 ? finalUse : Discarded;
			var plan = lowerExpression(statements[i], statementUse);
			if (plan.prelude.length > 0)
				sawPrelude = true;
			for (preludeStatement in plan.prelude)
				flattened.push(preludeStatement);
			if (!(statementUse == Discarded && isNil(plan.value) && plan.prelude.length > 0))
				flattened.push(plan.value);
		}

		if (!sawPrelude || flattened.length == 0)
			return {prelude: [], value: rebuild(flattened)};

		return {
			prelude: flattened.slice(0, flattened.length - 1),
			value: flattened[flattened.length - 1]
		};
	}

	static function materialize(prelude:Array<ElixirAST>, value:ElixirAST, source:ElixirAST):ElixirAST {
		if (prelude == null || prelude.length == 0)
			return value;
		var statements = prelude.copy();
		statements.push(value);
		return makeASTWithMeta(EBlock(statements), source != null ? source.metadata : null, source != null ? source.pos : null);
	}

	static function isStrictBinary(op:EBinaryOp):Bool {
		return switch (op) {
			case AndAlso | OrElse | And | Or:
				false;
			default:
				true;
		}
	}

	static function isNil(node:ElixirAST):Bool {
		return node != null && switch (node.def) {
			case ENil: true;
			default: false;
		};
	}
}
#end
