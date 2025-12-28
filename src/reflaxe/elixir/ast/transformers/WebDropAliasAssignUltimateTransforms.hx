package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WebDropAliasAssignUltimateTransforms
 *
 * WHAT
 * - Ultimate safety net for Web.* modules: drop alias assignments to json/data/conn
 *   regardless of position. These are frequently introduced by earlier normalizers
 *   and are not required when we call Phoenix.Controller.json/2 directly.

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class WebDropAliasAssignUltimateTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isWeb(name)):
          var out = [for (b in body) cleanse(b)];
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (isWeb(name2)):
          makeASTWithMeta(EDefmodule(name2, cleanse(doBlock)), n.metadata, n.pos);
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
        case EDef(fn, args, g, body): makeASTWithMeta(EDef(fn, args, g, drop(body)), n.metadata, n.pos);
        case EDefp(fn2, args2, g2, body2): makeASTWithMeta(EDefp(fn2, args2, g2, drop(body2)), n.metadata, n.pos);
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
      case EBlock(stmts): makeASTWithMeta(EBlock(filter(stmts)), body.metadata, body.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(filter(stmts2)), body.metadata, body.pos);
      default: body;
    }
  }

  static inline function isAssignTo(name:String, stmt:ElixirAST): Bool {
    return switch (stmt.def) {
      case EBinary(Match, {def:EVar(nm)}, _): nm == name;
      case EMatch(PVar(nm2), _): nm2 == name;
      default: false;
    }
  }

  static function filter(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (s in stmts) {
      if (isAssignTo("json", s) || isAssignTo("data", s) || isAssignTo("conn", s)) continue;
      out.push(s);
    }
    return out;
  }
}

#end

