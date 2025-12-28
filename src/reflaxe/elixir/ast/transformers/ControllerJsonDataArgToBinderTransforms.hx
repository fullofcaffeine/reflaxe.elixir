package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControllerJsonDataArgToBinderTransforms
 *
 * WHAT
 * - In controllers, within case arms `{:ok, binder}` or `{:error, binder}`,
 *   if encountering `Phoenix.Controller.json(conn, data)`, rewrite second arg
 *   to the case binder. Generic safety net to eliminate undefined `data` aliases.

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
class ControllerJsonDataArgToBinderTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isController(name)):
          var out = [for (b in body) cleanse(b)];
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (isController(name2)):
          makeASTWithMeta(EDefmodule(name2, cleanse(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isController(name:String):Bool {
    return name != null && name.indexOf("Web.") > 0 && StringTools.endsWith(name, "Controller");
  }

  static function cleanse(node:ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EDef(fn, args, g, body):
          makeASTWithMeta(EDef(fn, args, g, cleanse(body)), n.metadata, n.pos);
        case EDefp(fn2, args2, g2, body2):
          makeASTWithMeta(EDefp(fn2, args2, g2, cleanse(body2)), n.metadata, n.pos);
        case EBlock(stmts):
          var out:Array<ElixirAST> = [];
          for (s in stmts) out.push(cleanse(s));
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        case EDo(stmts2):
          var out2:Array<ElixirAST> = [];
          for (s2 in stmts2) out2.push(cleanse(s2));
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
        case ECase(expr, clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push(rewriteArm(cl));
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteArm(cl:{pattern:EPattern, guard:Null<ElixirAST>, body:ElixirAST}):{pattern:EPattern, guard:Null<ElixirAST>, body:ElixirAST} {
    var binder:Null<String> = null;
    switch (cl.pattern) {
      case PTuple(es) if (es.length == 2): switch (es[1]) { case PVar(n): binder = n; default: }
      default:
    }
    if (binder == null) return cl;
    var newBody = ElixirASTTransformer.transformNode(cl.body, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ERemoteCall(t, fnName, args) if (fnName == "json" && args != null && args.length == 2):
          switch (args[1].def) { case EVar(v) if (v == "data"): makeASTWithMeta(ERemoteCall(t, fnName, [args[0], makeAST(EVar(binder))]), n.metadata, n.pos); default: n; }
        default: n;
      }
    });
    return { pattern: cl.pattern, guard: cl.guard, body: newBody };
  }
}

#end
