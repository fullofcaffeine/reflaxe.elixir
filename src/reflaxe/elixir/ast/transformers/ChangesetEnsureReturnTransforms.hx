package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
	* ChangesetEnsureReturnTransforms
	*
	* WHAT
	* - Ensure functions that build/modify an Ecto.Changeset return the last assigned changeset variable.
	*
	* WHY
	* - Without returning the built changeset, bound variables like `cs` appear unused and trigger warnings.
	*
	* HOW
	* - For each EDef body, detect if the body contains calls to Ecto.Changeset.* and assignments to a variable.
	* - If the final statement is already an Ecto.Changeset call, preserve it: Elixir returns the value of a bare
	*   final call, so appending an earlier local would replace the authored result.
	* - Otherwise, if the last statement is not a reference to an assigned variable, append the last assigned
	*   variable as the final expression of the block.

	*
	* EXAMPLES
	* Haxe:
	*   return changeset.validateNumber(field, options);
	*
	* Elixir:
	*   Ecto.Changeset.validate_number(changeset, field, options)
	*
	* The bare call remains the tail expression; this pass must not append an earlier `opts` or `this1` local.
	* Covered by `ecto/changeset_validation_options` and `ecto/validate_length_options` snapshots.
 */
class ChangesetEnsureReturnTransforms {
	public static function pass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EDef(name, args, guards, body):
					var info = analyzeBody(body);
					#if debug_hygiene
					if (info.hasChangeset) // DEBUG: Sys.println('[ChangesetEnsureReturn] def ' + name + ' lastAssigned=' + (info.lastAssigned == null ? 'null' : info.lastAssigned));
					#end
					if (!info.hasChangeset || info.lastAssigned == null)
						return n;
					var newBody = ensureTrailingVar(body, info.lastAssigned);
					makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function analyzeBody(body:ElixirAST):{hasChangeset:Bool, lastAssigned:Null<String>} {
		var has = false;
		var last:Null<String> = null;
		function visit(x:ElixirAST):Void {
			if (x == null || x.def == null)
				return;
			switch (x.def) {
				case ERemoteCall(mod, func, _):
					switch (mod.def) {
						case EVar(nm) if (nm == "Ecto.Changeset"): has = true;
						default:
					}
				case EBinary(Match, left, _):
					switch (left.def) {
						case EVar(n): last = n;
						default:
					}
				case EMatch(pat, _):
					switch (pat) {
						case PVar(n2): last = n2;
						default:
					}
				case EBlock(ss):
					for (s in ss)
						visit(s);
				case EIf(c, t, e):
					visit(c);
					visit(t);
					if (e != null)
						visit(e);
				case ECase(expr, cs):
					visit(expr);
					for (c in cs)
						visit(c.body);
				case ECall(tgt, _, args):
					if (tgt != null)
						visit(tgt);
					if (args != null)
						for (a in args)
							visit(a);
				default:
			}
		}
		visit(body);
		return {hasChangeset: has, lastAssigned: last};
	}

	static function ensureTrailingVar(body:ElixirAST, varName:String):ElixirAST {
		return switch (body.def) {
			case EBlock(stmts):
				var lastStmt = stmts.length > 0 ? stmts[stmts.length - 1] : null;
				if (isChangesetCall(lastStmt)) body else {
					var alreadyReturns = (lastStmt != null) && switch (lastStmt.def) {
						case EVar(nm) if (nm == varName): true;
						default: false;
					};
					if (alreadyReturns)
						body
					else
						makeASTWithMeta(EBlock(stmts.concat([makeAST(EVar(varName))])), body.metadata, body.pos);
				}
			default:
				if (isChangesetCall(body)) body else {
					var already = switch (body.def) {
						case EVar(nm) if (nm == varName): true;
						default: false;
					};
					already ? body : makeAST(EBlock([body, makeAST(EVar(varName))]));
				}
		}
	}

	static function isChangesetCall(node:Null<ElixirAST>):Bool {
		if (node == null || node.def == null)
			return false;
		return switch (node.def) {
			case ERemoteCall({def: EVar("Ecto.Changeset")}, _, _): true;
			case EParen(inner): isChangesetCall(inner);
			default: false;
		};
	}
}
#end
