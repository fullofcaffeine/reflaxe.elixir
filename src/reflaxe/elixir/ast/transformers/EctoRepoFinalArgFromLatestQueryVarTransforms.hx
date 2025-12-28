package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoRepoFinalArgFromLatestQueryVarTransforms
 *
 * WHAT
 * - When a block builds successive query refinements into fresh binders
 *   (q1/q2/...), but the final Repo.all/Repo.one still calls with the base
 *   `query` variable, rewrite the Repo call argument to the latest refinement.
 *
 * WHY
 * - Compiler-generated code may form a chain:
 *     query = from(...)
 *     q1 = if cond1, do: where(query, ...), else: query
 *     q2 = if cond2, do: where(query, ...), else: q1
 *     Repo.all(query)
 *   This leaves `q2` unused and warns. Using the latest refinement is idiomatic.
 *
 * HOW
 * - Scan EBlock/EDo statements keeping track of the last binder that is assigned
 *   from an if-branch returning either `where(query, ...)` or a previous binder
 *   eventually rooted at `query`. When a call `Repo.all(query)` or `Repo.one(query)`
 *   is encountered, replace the argument with that latest binder.
 * - Conservative: only triggers when the call arg is exactly `EVar("query")` and
 *   a later refinement exists in the same block.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class EctoRepoFinalArgFromLatestQueryVarTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewriteSeq(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewriteSeq(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteSeq(stmts: Array<ElixirAST>): Array<ElixirAST> {
    var latest:String = null;
    var roots = new Map<String,Bool>();
    roots.set("query", true);

    inline function isWhereOnQueryExpr(e:ElixirAST):Bool {
      return switch (e.def) {
        case ERemoteCall({def: EVar(m)}, fn, args) if (m == "Ecto.Query" && fn == "where" && args != null && args.length >= 1):
          switch (args[0].def) { case EVar(v): roots.exists(v); default: false; }
        default: false;
      }
    }

    inline function isVarOrRoot(e:ElixirAST):Bool {
      return switch (e?.def) { case EVar(v): roots.exists(v); default: false; }
    }
    inline function lastExpr(e:ElixirAST):ElixirAST {
      return switch (e?.def) {
        case EBlock(ss) if (ss.length > 0): ss[ss.length-1];
        case EDo(ss2) if (ss2.length > 0): ss2[ss2.length-1];
        default: e;
      }
    }
    inline function isWhereOnQueryStmt(e:ElixirAST):Bool {
      var x = lastExpr(e);
      return switch (x.def) {
        case ERemoteCall(_,_,_): isWhereOnQueryExpr(x);
        case EMatch(_, rhs): isWhereOnQueryExpr(rhs);
        case EBinary(Match, _, rhs2): isWhereOnQueryExpr(rhs2);
        default: false;
      }
    }

    inline function updateRootsFromIf(e:ElixirAST, binder:String):Void {
      switch (e.def) {
        case EIf(_, thenE, elseE):
          var tOk = isWhereOnQueryStmt(thenE);
          var eOk = isVarOrRoot(lastExpr(elseE));
          if (tOk && eOk) {
            latest = binder; roots.set(binder, true);
          }
        default:
      }
    }

    var out:Array<ElixirAST> = [];
    for (s in stmts) {
      switch (s.def) {
        case EMatch(PVar(b), rhs): updateRootsFromIf(rhs, b); out.push(s);
        case EBinary(Match, {def: EVar(b2)}, rhs2): updateRootsFromIf(rhs2, b2); out.push(s);
        case ERemoteCall(mod, fn, args) if ((fn == "all" || fn == "one") && args != null && args.length >= 1 && latest != null):
          // Only when first arg is exactly `query`
          switch (args[0].def) {
            case EVar(v) if (v == "query"):
              var newArgs = args.copy(); newArgs[0] = makeAST(EVar(latest));
              out.push(makeASTWithMeta(ERemoteCall(mod, fn, newArgs), s.metadata, s.pos));
            default:
              out.push(s);
          }
        default:
          out.push(s);
      }
    }
    return out;
  }
}

#end
