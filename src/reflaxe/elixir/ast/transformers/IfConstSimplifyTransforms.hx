package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * IfConstSimplifyTransforms
 *
 * WHAT
 * - Simplify conditionals with constant conditions:
 *   if true/1 do A else B end  -> A
 *   if false/0 do A else B end -> (B || nil)
 *
 * WHY
 * - Late passes may introduce sentinel literals in conditions; removing them yields
 *   clearer and warning-free output.
 *
 * HOW
 * - For EIf nodes, if the condition is a recognized truthy literal (true, :true, 1),
 *   replace the whole if with the then-branch; if falsey (false, :false, 0),
 *   replace with else-branch or nil when else is missing.
 *
 * EXAMPLES
 * Haxe:
 *   if (true) trace(1) else trace(0);
 * Elixir (before):
 *   if true do 1 else 0 end
 * Elixir (after):
 *   1
 */
class IfConstSimplifyTransforms {
	public static function transformPass(ast:ElixirAST):ElixirAST {
		return rewrite(ast, new Map<String, Bool>());
	}

	/** Follow literal Boolean aliases only through sequential blocks and if branches. */
	static function rewrite(node:ElixirAST, incoming:Map<String, Bool>):ElixirAST {
		if (node == null)
			return node;
		switch (node.def) {
			case EBlock(statements) | EDo(statements):
				var facts = incoming.copy();
				var output = [];
				for (statement in statements) {
					output.push(rewrite(statement, facts));
					switch (statement.def) {
						case EMatch(PVar(name), rhs) | EBinary(Match, {def: EVar(name)}, rhs):
							var known = booleanValue(rhs, facts);
							if (mayBind(rhs))
								facts.clear();
							facts.remove(name);
							if (known != null) facts.set(name, known);
						default:
							// Do not infer a join value after conditional or compound writes.
							if (mayBind(statement)) facts.clear();
					}
				}
				return makeASTWithMeta(switch (node.def) {
					case EDo(_): EDo(output);
					default: EBlock(output);
				}, node.metadata, node.pos);
			case EIf(condition, yes, no):
				var known = booleanValue(condition, incoming);
				if (known != null)
					return known ? rewrite(yes, incoming) : (no != null ? rewrite(no, incoming) : makeASTWithMeta(ENil, node.metadata, node.pos));
				var branchFacts = mayBind(condition) ? new Map<String, Bool>() : incoming;
				return simplifyLiteral(makeASTWithMeta(EIf(rewrite(condition, new Map<String, Bool>()), rewrite(yes, branchFacts),
					no != null ? rewrite(no, branchFacts) : null), node.metadata,
					node.pos));
			default:
				// Functions, patterns, loops and other scope boundaries establish their
				// own facts; inherited values must never bypass shadowing or rebinding.
				return simplifyLiteral(ElixirASTTransformer.transformAST(node, child -> rewrite(child, new Map<String, Bool>())));
		}
	}

	static function booleanValue(node:ElixirAST, facts:Map<String, Bool>):Null<Bool> {
		return switch (node.def) {
			case EBoolean(value): value;
			case EVar(name): facts.exists(name) ? facts.get(name) : null;
			case EParen(inner): booleanValue(inner, facts);
			case EUnary(Not, inner):
				var value = booleanValue(inner, facts);
				value == null ? null : !value;
			default: null;
		};
	}

	/** Unknown native code and nested writes invalidate facts, never establish them. */
	static function mayBind(node:ElixirAST):Bool {
		var found = false;
		ASTUtils.walk(node, child -> {
			switch (child.def) {
				case EMatch(_, _) | EBinary(Match, _, _) | ERaw(_) | EReceiverEffect(_): found = true;
				default:
			}
		});
		return found;
	}

	static function simplifyLiteral(n:ElixirAST):ElixirAST {
		return switch (n.def) {
			case EIf(cond, thenBr, elseBr):
				if (isTruth(cond)) thenBr else if (isFalsey(cond)) (elseBr != null ? elseBr : makeASTWithMeta(ENil, n.metadata, n.pos)) else n;
			case ECond(clauses):
				// Use native Boolean truth here: unlike legacy if sentinels, zero
				// is truthy in an Elixir cond. Keep an all-false cond's failure.
				var retained = clauses.filter(clause -> switch (clause.condition.def) {
					case EBoolean(false): false;
					case EAtom(atom) if (atom == "false"): false;
					default: true;
				});
				if (retained.length == 0 || retained.length == clauses.length) {
					n;
				} else {
					switch (retained[0].condition.def) {
						case EBoolean(true): retained[0].body;
						case EAtom(atom) if (atom == "true"): retained[0].body;
						default: makeASTWithMeta(ECond(retained), n.metadata, n.pos);
					}
				}
			default:
				n;
		}
	}

	static inline function isTruth(e:ElixirAST):Bool {
		return switch (e.def) {
			case EBoolean(true): true;
			case EAtom(a) if (a == "true"): true;
			case EInteger(v) if (v == 1): true;
			default: false;
		};
	}

	static inline function isFalsey(e:ElixirAST):Bool {
		return switch (e.def) {
			case EBoolean(false): true;
			case EAtom(a) if (a == "false"): true;
			case EInteger(v) if (v == 0): true;
			default: false;
		};
	}
}
#end
