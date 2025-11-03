package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * LocalAssignUnusedUnderscoreGlobalFinalTransforms
 *
 * WHAT
 * - As an absolute-final cleanup, underscore binders of local assignments that
 *   are not referenced in any subsequent statement of the same block/do or fn
 *   body. Excludes binder name `socket`.
 */
  class LocalAssignUnusedUnderscoreGlobalFinalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      // Gate: skip inside LiveView modules to avoid renaming locals that are referenced
      // from interpolated strings and lifted closures in HEEx. LiveView modules are
      // marked with metadata.isLiveView by the annotation/builder pipeline.
      switch (n.def) {
        case EModule(_, _, _) | EDefmodule(_, _):
          if (n.metadata != null && (Reflect.field(n.metadata, "isLiveView") == true)) {
            return n; // Do not rewrite inside LiveView modules
          }
        default:
      }
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        case EFn(clauses):
          var newClauses = [];
          for (c in clauses) newClauses.push({args:c.args, guard:c.guard, body: pass(c.body)});
          makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var s1 = switch (s.def) {
        case EBinary(Match, {def: EVar(b)}, rhs) if (shouldUnderscore(b) && !usedLater(stmts, i+1, b)):
          makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b)), rhs), s.metadata, s.pos);
        case EMatch(PVar(b2), rhs2) if (shouldUnderscore(b2) && !usedLater(stmts, i+1, b2)):
          makeASTWithMeta(EMatch(PVar('_' + b2), rhs2), s.metadata, s.pos);
        default: s;
      }
      out.push(s1);
    }
    return out;
  }

  static function shouldUnderscore(name:String): Bool {
    // Exclude common, semantically meaningful binders that may be read later via patterns we don’t detect well
    return switch (name) {
      case "socket" | "conn" | "children" | "live" | "live_socket" | "parsed" | "next_sort": false;
      default: true;
    }
  }

  static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
    var found = false;
    for (j in start...stmts.length) if (!found) {
      reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(x:ElixirAST){
        switch (x.def) { case EVar(v) if (v == name): found = true; default: }
      });
    }
    return found;
  }
}

#end
