package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * WebDropUnusedPureAssignTransforms
 *
 * WHAT
 * - In <App>Web.* modules, drop local assignments whose RHS is a pure variable
 *   (EVar) when the LHS binder is never referenced later in the same body.
 *
 * WHY
 * - Cleans up compiler-introduced binders (json/data/user/etc.) that are not used,
 *   removing warnings without affecting side effects (pure var copies only).
 */
class WebDropUnusedPureAssignTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EDef(functionName, parameters, guards, body):
          makeASTWithMeta(EDef(functionName, parameters, guards, dropUnused(body)), n.metadata, n.pos);
        case EDefp(functionName, parameters, guards, body):
          makeASTWithMeta(EDefp(functionName, parameters, guards, dropUnused(body)), n.metadata, n.pos);
        default: dropUnused(n);
      }
    });
  }

  static function dropUnused(body:ElixirAST):ElixirAST {
    return switch (body.def) {
      case EBlock(statements): makeASTWithMeta(EBlock(rewrite(statements)), body.metadata, body.pos);
      case EDo(statements): makeASTWithMeta(EDo(rewrite(statements)), body.metadata, body.pos);
      default: body;
    }
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var keep = true;
      switch (s.def) {
        case EBinary(Match, {def: EVar(b)}, rhs) if (!isSocketBinder(b) && isDropCandidate(rhs) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, b)):
          keep = false; // drop pure var copy or empty init
        case EMatch(PVar(binder), rhs) if (!isSocketBinder(binder) && isDropCandidate(rhs) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binder)):
          keep = false;
        default:
      }
      if (keep) out.push(s);
    }
    return out;
  }

  static inline function isSocketBinder(name:String): Bool {
    if (name == null) return false;
    return name == "socket" || name == "live_socket" || name == "liveSocket" || StringTools.endsWith(name, "_socket");
  }

  static inline function isDropCandidate(e: ElixirAST): Bool {
    return switch (e.def) {
      case EVar(_): true;
      case EList(es) if (es != null && es.length == 0): true;
      case ENil: true;
      default: false;
    }
  }
}

#end
