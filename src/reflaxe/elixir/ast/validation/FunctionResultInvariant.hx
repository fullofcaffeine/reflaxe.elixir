package reflaxe.elixir.ast.validation;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.FunctionResultContract;

using StringTools;

typedef FunctionResultState = {
	var signature:String;
	var problem:Null<String>;
	var node:ElixirAST;
	var degradedAt:Null<String>;
}

/**
 * Validates source-level non-Void function results at AST pass boundaries.
 *
 * WHAT
 * - Checks authored EDef/EDefp nodes carrying FunctionResultContract.Value.
 * - Detects transitions from a valid result carrier to a missing target tail,
 *   non-nullable nil tail, or source numeric tail placed in EBlock/EDo shapes
 *   that the printer treats as sentinels.
 *
 * WHY
 * - Cleanup passes can accidentally move a scalar return into statement-only
 *   context or remove its carrier. Elixir then returns nil (or the wrong prior
 *   expression) even though Haxe typed the function as non-Void.
 *
 * HOW
 * - ElixirCompiler attaches the source contract to authored definitions.
 * - ElixirASTTransformer captures the initial state, then validates each named
 *   pass transition when `-D reflaxe_elixir_validate_results` is enabled.
 * - The analysis stays on ElixirAST. It does not print or compare target text.
 *
 * LIMITS
 * - Compiler-synthesized definitions and extern declarations have no authored
 *   contract and are intentionally skipped.
 * - An authored function may start invalid when upstream stdlib source contains
 *   a target-replaced placeholder body. It becomes protected as soon as target
 *   semantic shaping produces a valid result carrier.
 * - ERaw is opaque and counts as a value unless empty; target injection owns
 *   the semantics inside that raw expression.
 */
class FunctionResultInvariant {
	public static function capture(ast:ElixirAST, moduleName:String):Map<String, FunctionResultState> {
		var states = new Map<String, FunctionResultState>();
		if (ast != null && ast.def != null)
			visitModuleLevel(ast, moduleName != null ? moduleName : "<module>", states);
		return states;
	}

	public static function validateTransition(ast:ElixirAST, moduleName:String, phaseName:String,
			previous:Map<String, FunctionResultState>):Map<String, FunctionResultState> {
		var current = capture(ast, moduleName);
		if (previous != null) {
			for (contractId => state in current) {
				var prior = previous.get(contractId);
				if (state.problem == null) {
					state.degradedAt = null;
				} else if (prior != null) {
					state.degradedAt = prior.problem == null ? phaseName : prior.degradedAt;
				}
			}
		}
		return current;
	}

	public static function assertNoDegradedResults(states:Map<String, FunctionResultState>):Void {
		if (states == null)
			return;
		for (state in states) {
			if (state.problem != null && state.degradedAt != null)
				report(state, state.degradedAt);
		}
	}

	static function visitModuleLevel(node:ElixirAST, moduleName:String, states:Map<String, FunctionResultState>):Void {
		if (node == null || node.def == null)
			return;

		switch (node.def) {
			case EModule(name, _, body):
				var owner = name != null && name.length > 0 ? name : moduleName;
				if (body != null)
					for (statement in body)
						visitModuleLevel(statement, owner, states);

			case EDefmodule(name, doBlock):
				visitModuleLevel(doBlock, name != null && name.length > 0 ? name : moduleName, states);

			case EBlock(statements) | EDo(statements):
				if (statements != null)
					for (statement in statements)
						visitModuleLevel(statement, moduleName, states);

			case EDef(name, args, _, body) | EDefp(name, args, _, body):
				captureFunction(node, moduleName, name, args != null ? args.length : 0, body, states);

			default:
		}
	}

	static function captureFunction(node:ElixirAST, moduleName:String, functionName:String, arity:Int, body:ElixirAST,
			states:Map<String, FunctionResultState>):Void {
		if (node.metadata == null || node.metadata.functionResultContract != FunctionResultContract.Value)
			return;

		var signature = moduleName + "." + functionName + "/" + arity;
		var contractId = node.metadata.functionResultContractId != null ? node.metadata.functionResultContractId : signature;
		states.set(contractId, {
			signature: signature,
			problem: tailProblem(body, node.metadata.functionResultMayBeNil == true),
			node: node,
			degradedAt: null
		});
	}

	static function report(state:FunctionResultState, phaseName:String):Void {
		var message = 'Reflaxe.Elixir result invariant failed after phase "'
			+ phaseName
			+ '" for '
			+ state.signature
			+ ': '
			+ state.problem
			+ '. The Haxe function has a non-Void return contract; the named phase must preserve its value carrier.';

		#if macro
		haxe.macro.Context.error(message, state.node.pos != null ? state.node.pos : haxe.macro.Context.currentPos());
		#else
		throw message;
		#end
	}

	static function tailProblem(node:ElixirAST, mayBeNil:Bool):Null<String> {
		if (node == null || node.def == null)
			return "the function body has no target expression";

		return switch (node.def) {
			case EBlock(statements):
				blockTailProblem(statements, mayBeNil, "block");

			case EDo(statements):
				blockTailProblem(statements, mayBeNil, "do block");

			case EParen(inner):
				tailProblem(inner, mayBeNil);

			case ENil if (!mayBeNil):
				"the target tail is nil although the source return type is non-nullable";

			case EIf(_, thenBranch, elseBranch):
				var thenProblem = tailProblem(thenBranch, mayBeNil);
				if (thenProblem != null) {
					"the if true branch has no valid result: " + thenProblem;
				} else if (elseBranch == null) {
					mayBeNil ? null : "the final if expression has no else result";
				} else {
					var elseProblem = tailProblem(elseBranch, mayBeNil);
					elseProblem == null ? null : "the if false branch has no valid result: " + elseProblem;
				}

			case EUnless(_, unlessBody, elseBranch):
				var bodyProblem = tailProblem(unlessBody, mayBeNil);
				if (bodyProblem != null) {
					"the unless body has no valid result: " + bodyProblem;
				} else if (elseBranch == null) {
					mayBeNil ? null : "the final unless expression has no else result";
				} else {
					var elseProblem = tailProblem(elseBranch, mayBeNil);
					elseProblem == null ? null : "the unless else branch has no valid result: " + elseProblem;
				}

			case ECase(_, clauses):
				clauseTailProblem(clauses != null ? [for (clause in clauses) clause.body] : [], mayBeNil, "case");

			case ECond(clauses):
				clauseTailProblem(clauses != null ? [for (clause in clauses) clause.body] : [], mayBeNil, "cond");

			case EWith(_, doBlock, elseBlock):
				var doProblem = tailProblem(doBlock, mayBeNil);
				if (doProblem != null) {
					"the with success branch has no valid result: " + doProblem;
				} else if (elseBlock != null) {
					var elseProblem = tailProblem(elseBlock, mayBeNil);
					elseProblem == null ? null : "the with else branch has no valid result: " + elseProblem;
				} else {
					null;
				}

			case ETry(tryBody, rescueClauses, catchClauses, _, elseBlock):
				var tryProblem = tailProblem(tryBody, mayBeNil);
				if (tryProblem != null) {
					"the try body has no valid result: " + tryProblem;
				} else {
					var branchBodies:Array<ElixirAST> = [];
					if (rescueClauses != null)
						for (clause in rescueClauses)
							branchBodies.push(clause.body);
					if (catchClauses != null)
						for (clause in catchClauses)
							branchBodies.push(clause.body);
					if (elseBlock != null)
						branchBodies.push(elseBlock);
					clauseTailProblem(branchBodies, mayBeNil, "try branch", true);
				}

			case EReceive(clauses, afterClause):
				var branchBodies = clauses != null ? [for (clause in clauses) clause.body] : [];
				if (afterClause != null)
					branchBodies.push(afterClause.body);
				clauseTailProblem(branchBodies, mayBeNil, "receive");

			case EMatch(_, rhs):
				tailProblem(rhs, mayBeNil);

			case EBinary(Match, _, rhs):
				tailProblem(rhs, mayBeNil);

			case ERaw(code) if (code == null || code.trim().length == 0):
				"the target tail is an empty raw expression";

			case ERaise(_, _) | EThrow(_):
				null;

			default:
				null;
		};
	}

	static function blockTailProblem(statements:Array<ElixirAST>, mayBeNil:Bool, label:String):Null<String> {
		if (statements == null || statements.length == 0)
			return "the final " + label + " is empty";

		var tail = statements[statements.length - 1];
		if (isPrinterDiscardedSourceNumericTail(tail))
			return "a source numeric result was moved into a " + label + " shape where the printer discards it as a sentinel";

		return tailProblem(tail, mayBeNil);
	}

	static function clauseTailProblem(bodies:Array<ElixirAST>, mayBeNil:Bool, label:String, allowEmpty:Bool = false):Null<String> {
		if (bodies == null || bodies.length == 0)
			return allowEmpty ? null : "the final " + label + " expression has no clauses";

		for (index in 0...bodies.length) {
			var problem = tailProblem(bodies[index], mayBeNil);
			if (problem != null)
				return label + " branch " + (index + 1) + " has no valid result: " + problem;
		}
		return null;
	}

	static function isPrinterDiscardedSourceNumericTail(node:ElixirAST):Bool {
		if (node == null || node.def == null || node.metadata == null || node.metadata.sourceExpr == null)
			return false;

		return switch (node.def) {
			case EInteger(value) if (value == 0 || value == 1): true;
			case EFloat(value) if (value == 0.0): true;
			case ERaw(code) if (code != null && (code.trim() == "0" || code.trim() == "1")): true;
			default: false;
		};
	}
}
#end
