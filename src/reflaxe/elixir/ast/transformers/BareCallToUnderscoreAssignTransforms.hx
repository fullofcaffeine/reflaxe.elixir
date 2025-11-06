package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * BareCallToUnderscoreAssignTransforms
 *
 * WHAT
 * - In statement lists (EBlock/EDo), convert bare function calls into
 *   underscore assignments: `call(args)` → `_ = call(args)`; similarly for
 *   `Mod.call(args)`.
 *
 * WHY
 * - Idiomatic Elixir avoids bare effectful calls in statement position when
 *   the result is unused; `_ =` communicates intent and aligns with snapshot
 *   expectations in guard/pattern suites.
 *
 * HOW
 * - Visits EBlock/EDo and rewrites top-level items that are ECall/ERemoteCall
 *   into EBinary(Match, EVar("_"), <call>). Does not touch calls nested inside
 *   expressions or control flow.
 */
class BareCallToUnderscoreAssignTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts):
          var out:Array<ElixirAST> = [];
          for (s in stmts) out.push(rewriteStmt(s));
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        case EDo(stmts2):
          var out2:Array<ElixirAST> = [];
          for (s2 in stmts2) out2.push(rewriteStmt(s2));
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteStmt(s: ElixirAST): ElixirAST {
    return switch (s.def) {
      case ECall(target, fname, args):
        makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("_"), s.metadata, s.pos), makeASTWithMeta(ECall(target, fname, args), s.metadata, s.pos)), s.metadata, s.pos);
      case ERemoteCall(mod, fname2, args2):
        makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("_"), s.metadata, s.pos), makeASTWithMeta(ERemoteCall(mod, fname2, args2), s.metadata, s.pos)), s.metadata, s.pos);
      default:
        s;
    }
  }
}

#end

