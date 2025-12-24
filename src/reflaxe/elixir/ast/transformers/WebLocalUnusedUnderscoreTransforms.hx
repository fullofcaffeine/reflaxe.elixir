package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * WebLocalUnusedUnderscoreTransforms
 *
 * WHAT
 * - In modules under <App>Web.*, underscore local assignment binders that are
 *   not referenced later in the same body. This removes Phoenix compile warnings
 *   without changing behavior (RHS is preserved).
 *
 * WHY
 * - LiveView and Controller code often bind intermediate locals (data/json/etc.).
 *   When not used later, Elixir warns. We fix shape-based, not by names.
 */
class WebLocalUnusedUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isWeb(name)):
          var out = [for (b in body) applyToDefs(b)];
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        case EDefmodule(moduleName, doBlock) if (isWeb(moduleName)):
          makeASTWithMeta(EDefmodule(moduleName, applyToDefs(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isWeb(name:String):Bool {
    if (name == null) return false;
    var isWeb = name.indexOf("Web.") > 0;
    // Never touch Presence modules
    if (name.indexOf("Web.Presence") > 0 || StringTools.endsWith(name, ".Presence")) return false;
    return isWeb;
  }

  static function applyToDefs(node:ElixirAST):ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EDef(fn, args, guards, body):
          makeASTWithMeta(EDef(fn, args, guards, underscoreUnused(body)), n.metadata, n.pos);
        case EDefp(fn, args, guards, body):
          makeASTWithMeta(EDefp(fn, args, guards, underscoreUnused(body)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function underscoreUnused(body:ElixirAST):ElixirAST {
    return switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), body.metadata, body.pos);
      case EDo(statements): makeASTWithMeta(EDo(rewrite(statements)), body.metadata, body.pos);
      default: body;
    }
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var stmt = stmts[i];
      var rewrittenStmt = switch (stmt.def) {
        case EMatch(PVar(b), rhs) if (canUnderscoreBinder(b) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, b)):
          makeASTWithMeta(EMatch(PVar('_' + b), rhs), stmt.metadata, stmt.pos);
        case EBinary(Match, {def: EVar(binderName)}, rhs) if (canUnderscoreBinder(binderName) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binderName)):
          makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + binderName)), rhs), stmt.metadata, stmt.pos);
        case ECase(expr, clauses):
          var nc = [];
          for (cl in clauses) nc.push({ pattern: cl.pattern, guard: cl.guard, body: underscoreUnused(cl.body) });
          makeASTWithMeta(ECase(expr, nc), stmt.metadata, stmt.pos);
        default:
          stmt;
      }
      out.push(rewrittenStmt);
    }
    return out;
  }

  static inline function canUnderscoreBinder(name: String): Bool {
    return name != null && name.length > 0 && name != "_" && name.charAt(0) != '_';
  }
}

#end
