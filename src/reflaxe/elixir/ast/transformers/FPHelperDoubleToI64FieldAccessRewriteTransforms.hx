package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import haxe.ds.StringMap;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import StringTools;

/**
 * FPHelperDoubleToI64FieldAccessRewriteTransforms
 *
 * WHAT
 * - Rewrites `.high` / `.low` field accesses on variables bound from `FPHelper.double_to_i64/1`
 *   into integer bit operations (`Bitwise.bsr/2` and `Bitwise.band/2`).
 *
 * WHY
 * - On the Elixir target, `haxe.Int64` is represented as a BEAM integer (arbitrary precision).
 * - Haxe stdlib code (notably `haxe.io.Output.writeDouble`) reads `i64.high` / `i64.low`, which
 *   would print as `i64.high` in Elixir and triggers `--warnings-as-errors` (“expected a map or struct”).
 *
 * HOW
 * - In each EBlock/EDo statement list:
 *   1) Track variables assigned from `FPHelper.double_to_i64(...)`.
 *   2) For subsequent statements in the same list (excluding nested anonymous functions),
 *      rewrite `var.high` → `Bitwise.bsr(var, 32)` and `var.low` → `Bitwise.band(var, 0xFFFFFFFF)`.
 *
 * EXAMPLES
 * Elixir (before):
 *   i64 = FPHelper.double_to_i64(x)
 *   write_int32(struct, i64.high)
 *   write_int32(struct, i64.low)
 *
 * Elixir (after):
 *   i64 = FPHelper.double_to_i64(x)
 *   write_int32(struct, Bitwise.bsr(i64, 32))
 *   write_int32(struct, Bitwise.band(i64, 4294967295))
 */
class FPHelperDoubleToI64FieldAccessRewriteTransforms {
	public static function pass(ast: ElixirAST): ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
			return switch (n.def) {
				case EBlock(stmts):
					var rewritten = rewriteStatementList(stmts);
					rewritten == stmts ? n : makeASTWithMeta(EBlock(rewritten), n.metadata, n.pos);
				case EDo(stmts):
					var rewrittenDo = rewriteStatementList(stmts);
					rewrittenDo == stmts ? n : makeASTWithMeta(EDo(rewrittenDo), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	static function rewriteStatementList(stmts: Array<ElixirAST>): Array<ElixirAST> {
		if (stmts == null || stmts.length == 0) return stmts;

		var tracked: StringMap<Bool> = new StringMap();
		var out: Array<ElixirAST> = [];

		for (stmt in stmts) {
			// Update tracking first (so "var = FPHelper.double_to_i64(...)" doesn't rewrite itself).
			updateTracking(stmt, tracked);
			out.push(rewriteFields(stmt, tracked));
		}

		return out;
	}

	static function updateTracking(stmt: ElixirAST, tracked: StringMap<Bool>): Void {
		if (stmt == null || stmt.def == null) return;
		switch (stmt.def) {
			case EMatch(PVar(name), rhs):
				if (isFPHelperDoubleToI64(unwrapParen(rhs))) tracked.set(name, true);
				else tracked.remove(name);
			case EBinary(Match, left, rhs):
				switch (unwrapParen(left).def) {
					case EVar(name):
						if (isFPHelperDoubleToI64(unwrapParen(rhs))) tracked.set(name, true);
						else tracked.remove(name);
					default:
				}
			default:
		}
	}

	static function isFPHelperDoubleToI64(expr: ElixirAST): Bool {
		if (expr == null || expr.def == null) return false;
		return switch (expr.def) {
			case ERemoteCall(moduleExpr, fnName, _args):
				isFPHelperModule(moduleExpr) && (fnName == "double_to_i64" || fnName == "doubleToI64");
			case ECall(targetExpr, fnName, _args):
				isFPHelperModule(targetExpr) && (fnName == "double_to_i64" || fnName == "doubleToI64");
			default: false;
		};
	}

	static function isFPHelperModule(expr: ElixirAST): Bool {
		if (expr == null || expr.def == null) return false;
		var unwrapped = unwrapParen(expr);
		return switch (unwrapped.def) {
			case EVar(name):
				name == "FPHelper" || StringTools.endsWith(name, ".FPHelper");
			default:
				false;
		};
	}

	static function rewriteFields(stmt: ElixirAST, tracked: StringMap<Bool>): ElixirAST {
		if (stmt == null || stmt.def == null) return stmt;
		function visit(node: ElixirAST): ElixirAST {
			if (node == null || node.def == null) return node;

			// Prune nested closures: do not rewrite inside them.
			switch (node.def) {
				case EFn(_):
					return node;
				default:
			}

			// First recurse into children.
			var withChildren = ElixirASTTransformer.transformAST(node, visit);
			if (withChildren == null || withChildren.def == null) return withChildren;

			// Then rewrite at this node.
			return switch (withChildren.def) {
				case EField(target, "high"):
					switch (unwrapParen(target).def) {
						case EVar(name) if (tracked.exists(name)):
							makeAST(ERemoteCall(makeAST(EVar("Bitwise")), "bsr", [makeAST(EVar(name)), makeAST(EInteger(32))]));
						default:
							withChildren;
					}
				case EField(target, "low"):
					switch (unwrapParen(target).def) {
						case EVar(name) if (tracked.exists(name)):
							makeAST(ERemoteCall(makeAST(EVar("Bitwise")), "band", [makeAST(EVar(name)), mask32Expr()]));
						default:
							withChildren;
					}
				default:
					withChildren;
			};
		}

		return visit(stmt);
	}

	static function mask32Expr(): ElixirAST {
		// 0xFFFFFFFF as an expression that fits in Haxe Int: (1 <<< 32) - 1
		var one = makeAST(EInteger(1));
		var shift = makeAST(ERemoteCall(makeAST(EVar("Bitwise")), "bsl", [one, makeAST(EInteger(32))]));
		return makeAST(EBinary(Subtract, shift, one));
	}

	static function unwrapParen(e: ElixirAST): ElixirAST {
		return switch (e.def) {
			case EParen(inner): unwrapParen(inner);
			default: e;
		};
	}
}

#end
