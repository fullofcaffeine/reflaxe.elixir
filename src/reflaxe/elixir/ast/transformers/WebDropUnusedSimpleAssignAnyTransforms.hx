package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * WebDropUnusedSimpleAssignAnyTransforms
 *
 * WHAT
 * - In Web.* modules (controllers, LiveView, components), drop simple local
 *   assignments `name = <pure RHS>` when `name` is not used in any subsequent
 *   statement in the same block/do/arm.
 *
 * WHY
 * - Codegen sometimes emits harmless aliasing (this1 = nil, value = socket, tag = socket)
 *   that triggers WAE. Dropping provably-unused pure assigns eliminates noise
 *   without changing behavior.
 */
class WebDropUnusedSimpleAssignAnyTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isWeb(name)):
          var out = [for (b in body) cleanse(b)];
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        case EDefmodule(moduleName, doBlock) if (isWeb(moduleName)):
          makeASTWithMeta(EDefmodule(moduleName, cleanse(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isWeb(name:String):Bool {
    return name != null && name.indexOf("Web.") > 0;
  }

  static function cleanse(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EDef(functionName, parameters, guards, body): makeASTWithMeta(EDef(functionName, parameters, guards, drop(body)), n.metadata, n.pos);
        case EDefp(functionName, parameters, guards, body): makeASTWithMeta(EDefp(functionName, parameters, guards, drop(body)), n.metadata, n.pos);
        case ECase(expr, clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: drop(cl.body) });
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function drop(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(statements): makeASTWithMeta(EBlock(filter(statements)), body.metadata, body.pos);
      case EDo(statements): makeASTWithMeta(EDo(filter(statements)), body.metadata, body.pos);
      default: body;
    }
  }

  static function filter(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      switch (s.def) {
        case EBinary(Match, {def:EVar(binder)}, rhs) if (isPure(rhs) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binder)):
          // drop
        case EMatch(PVar(binder), rhs) if (isPure(rhs) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binder)):
          // drop
        default:
          out.push(s);
      }
    }
    return out;
  }

  static function isPure(e: ElixirAST): Bool {
    return switch (e.def) {
      case EVar(_)|EString(_)|EInteger(_)|EFloat(_)|EBoolean(_)|ENil|EAtom(_): true;
      case EMap(_)|EKeywordList(_)|ETuple(_)|EList(_)|EStruct(_, _): true;
      default: false;
    }
  }
}

#end
