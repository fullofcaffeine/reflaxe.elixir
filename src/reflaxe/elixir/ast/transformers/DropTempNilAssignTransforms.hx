package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
	* DropTempNilAssignTransforms
	*
	* WHAT
	* - Drop assignments of the form `thisN = nil` and `_thisN = nil` in any block/EFn bodies.
	* - Drop `name = nil` when a later statement of the same block binds `name` again
	*   and nothing reads the nil value before that.
	*
	* WHY
	* - These are compiler-generated sentinels that trigger unused-variable warnings.
	* - Haxe `var whole:String;` followed by an `if` that assigns it in every branch
	*   becomes `whole = nil` and then `{fraction, whole} = cond do ... end`. Elixir
	*   warns that the first `whole` is unused, which fails a warnings-as-errors build.
	*   Regression fixture: `regression/declared_then_assigned_in_branches`.

	*
	* HOW
	* - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

	*
	* EXAMPLES
	* - Covered by snapshot tests under `test/snapshot/**`.
 */
class DropTempNilAssignTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EBlock(stmts):
					makeASTWithMeta(EBlock(filter(stmts)), n.metadata, n.pos);
				case EDo(stmts2):
					makeASTWithMeta(EDo(filter(stmts2)), n.metadata, n.pos);
				case EFn(clauses):
					var newClauses = [];
					for (cl in clauses) {
						var b = cl.body;
						var nb = switch (b.def) {
							case EBlock(ss):
								makeASTWithMeta(EBlock(filter(ss)), b.metadata, b.pos);
							case EDo(ss2):
								makeASTWithMeta(EDo(filter(ss2)), b.metadata, b.pos);
							default:
								b;
						};
						newClauses.push({args: cl.args, guard: cl.guard, body: nb});
					}
					makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function filter(stmts:Array<ElixirAST>):Array<ElixirAST> {
		var out:Array<ElixirAST> = [];
		for (index in 0...stmts.length) {
			var s = stmts[index];
			var assignedName:Null<String> = switch (s.def) {
				case EBinary(Match, {def: EVar(nm)}, rhs) if (isNilValue(rhs)): nm;
				case EMatch(PVar(nm), rhs) if (isNilValue(rhs)): nm;
				default: null;
			};
			if (assignedName != null && (isTempName(assignedName) || isOverwrittenBeforeRead(stmts, index, assignedName)))
				continue;
			out.push(s);
		}
		return out;
	}

	/**
	 * True when a later statement of the same block binds `name` again and nothing
	 * reads the nil value before that.
	 *
	 * WHY: Haxe `var whole:String;` becomes `whole = nil`. When every branch of the
	 * next `if` assigns it, the branches return the new values and one statement
	 * binds them: `{fraction, whole} = cond do ... end`. Elixir then warns that the
	 * first `whole` is unused.
	 * HOW: Find the first later statement after which a read of `name` is no
	 * longer free, which means that the statement binds it. Each statement is
	 * analyzed once. The statements up to and including that one must not read
	 * the nil value. A statement that reads
	 * it, such as `text = if c, do: "some", else: text`, keeps the assignment.
	 * Raw code fragments are opaque to the analysis, so any of them keeps it too.
	 */
	static function isOverwrittenBeforeRead(stmts:Array<ElixirAST>, index:Int, name:String):Bool {
		var probe = makeAST(EVar(name));
		for (later in (index + 1)...stmts.length) {
			var statement = stmts[later];
			if (containsRawCode(statement))
				return false;
			// No statement before this one binds the name, so a free read here is a
			// read of the nil value.
			if (VarUseAnalyzer.freeVarNames(statement).exists(name))
				return false;
			var bindsAgain = !VarUseAnalyzer.freeVarNames(makeAST(EBlock([statement, probe]))).exists(name);
			if (bindsAgain)
				return true;
		}
		return false;
	}

	static function containsRawCode(node:ElixirAST):Bool {
		var found = false;
		reflaxe.elixir.ast.ASTUtils.walk(node, function(n:ElixirAST):Void {
			switch (n.def) {
				case ERaw(_):
					found = true;
				default:
			}
		});
		return found;
	}

	// Check for nil in both ENil and EAtom("nil") representations
	static function isNilValue(ast:ElixirAST):Bool {
		if (ast == null || ast.def == null)
			return false;
		return switch (ast.def) {
			case ENil: true;
			case EAtom(a): a == "nil";
			default: false;
		};
	}

	static function isTempName(nm:String):Bool {
		if (nm == null)
			return false;
		if (nm.indexOf("this") == 0)
			return true;
		if (nm.indexOf("_this") == 0)
			return true;
		return false;
	}
}
#end
