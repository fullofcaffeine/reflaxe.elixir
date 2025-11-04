package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StrictBlockDiscardUnusedTransforms
 *
 * WHAT
 * - Late, conservative pass to rewrite `var = expr` to `_ = expr` in simple
 *   block/`do` contexts when `var` is not referenced later in the same block.
 *
 * WHY
 * - Some earlier hygiene passes intentionally skip rewrites around ~H or complex
 *   templates. This ultra-late pass re-scans simple cases to eliminate noisy
 *   warnings without altering semantics.
 */
class StrictBlockDiscardUnusedTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts):
          makeASTWithMeta(EBlock(discardInSeq(stmts)), n.metadata, n.pos);
        case EDo(stmts2):
          makeASTWithMeta(EDo(discardInSeq(stmts2)), n.metadata, n.pos);
        case EDef(name, args, guards, body):
          makeASTWithMeta(EDef(name, args, guards, pass(body)), n.metadata, n.pos);
        case EDefp(name, args, guards, body):
          makeASTWithMeta(EDefp(name, args, guards, pass(body)), n.metadata, n.pos);
        case EFn(clauses):
          var out = [];
          for (c in clauses) out.push({ args: c.args, guard: c.guard, body: pass(c.body) });
          makeASTWithMeta(EFn(out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function discardInSeq(stmts:Array<ElixirAST>):Array<ElixirAST> {
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      switch (s.def) {
        case EBinary(Match, left, rhs):
          switch (left.def) {
            case EVar(nm):
              if (!isUsedLater(stmts, i + 1, nm)) {
                out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("_"), left.metadata, left.pos), rhs), s.metadata, s.pos));
                continue;
              }
            default:
          }
        case EMatch(pat, rhs2):
          switch (pat) {
            case PVar(nm2):
              if (!isUsedLater(stmts, i + 1, nm2)) {
                out.push(makeASTWithMeta(EMatch(PVar("_"), rhs2), s.metadata, s.pos));
                continue;
              }
            default:
          }
        default:
      }
      out.push(s);
    }
    return out;
  }

  static function isUsedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
    var found = false;
    for (i in start...stmts.length) {
      ElixirASTTransformer.transformNode(stmts[i], function(x: ElixirAST): ElixirAST {
        if (found) return x;
        switch (x.def) {
          case EVar(v) if (v == name): found = true; return x;
          default: return x;
        }
      });
      if (found) break;
    }
    return found;
  }
}

#end

