package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * LocalUnderscoreUsedPromotionTransforms
 *
 * WHAT
 * - Promotes local binders like `_this` to `this` when the binder is referenced
 *   in the same expression or subsequent statements. This eliminates warnings
 *   like "the underscored variable `_this` is used after being set" in LiveView helpers.
 *
 * SCOPE
 * - Applied within function bodies; conservative scan.
 */
class LocalUnderscoreUsedPromotionTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          makeASTWithMeta(EDef(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
        case EDefp(name, args, guards, body):
          makeASTWithMeta(EDefp(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
        case EFn(clauses):
          var outClauses = [];
          for (cl in clauses) outClauses.push({ args: cl.args, guard: cl.guard, body: rewriteBody(cl.body) });
          makeASTWithMeta(EFn(outClauses), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteBody(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts):
        makeASTWithMeta(EBlock(rewriteSeq(stmts)), body.metadata, body.pos);
      case EDo(statements):
        makeASTWithMeta(EDo(rewriteSeq(statements)), body.metadata, body.pos);
      default:
        body;
    }
  }

  static function rewriteSeq(stmts: Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var useIndex = OptimizedVarUseAnalyzer.build(stmts);
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var stmt = stmts[i];
      var rewrittenStmt = switch (stmt.def) {
        case EMatch(PVar(b), rhs) if (shouldPromote(b) && OptimizedVarUseAnalyzer.usedLater(useIndex, i, b)):
          makeASTWithMeta(EMatch(PVar(trim(b)), rhs), stmt.metadata, stmt.pos);
        case EBinary(Match, {def: EVar(binderName)}, rhs) if (shouldPromote(binderName) && OptimizedVarUseAnalyzer.usedLater(useIndex, i, binderName)):
          makeASTWithMeta(EBinary(Match, makeAST(EVar(trim(binderName))), rhs), stmt.metadata, stmt.pos);
        default:
          stmt;
      }
      out.push(rewrittenStmt);
    }
    return out;
  }

  static inline function isUnderscored(name:String):Bool {
    return name != null && name.length > 1 && name.charAt(0) == '_';
  }
  static inline function trim(name:String):String {
    return isUnderscored(name) ? name.substr(1) : name;
  }
  static inline function shouldPromote(name:String):Bool {
    // Promote any underscored local (e.g., _this, _reason) when its trimmed form is used later
    return isUnderscored(name);
  }
}

#end
