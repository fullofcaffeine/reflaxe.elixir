package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControllerCaseRenameBinderIfBodyRefsBaseTransforms
 *
 * WHAT
 * - In controller case arms `{:tag, _name}` where the body references `name`,
 *   rename the binder to `name`. Usage-driven; avoids WAE from underscored vars used.
 */
class ControllerCaseRenameBinderIfBodyRefsBaseTransforms {
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

  static function cleanse(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push(adjust(cl));
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        case EDef(fn, args, g, body): makeASTWithMeta(EDef(fn, args, g, cleanse(body)), n.metadata, n.pos);
        case EDefp(fn2, args2, g2, body2): makeASTWithMeta(EDefp(fn2, args2, g2, cleanse(body2)), n.metadata, n.pos);
        case EBlock(stmts):
          var out = [];
          for (s in stmts) out.push(cleanse(s));
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        case EDo(stmts2):
          var out2 = [];
          for (s2 in stmts2) out2.push(cleanse(s2));
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function adjust(cl:{pattern:EPattern, guard:Null<ElixirAST>, body:ElixirAST}):{pattern:EPattern, guard:Null<ElixirAST>, body:ElixirAST} {
    var binder:Null<String> = null;
    switch (cl.pattern) {
      case PTuple(es) if (es.length == 2):
        switch (es[1]) { case PVar(n): binder = n; default: }
      default:
    }
    if (binder == null || binder.charAt(0) != '_') return cl;
    var base = binder.substr(1);
    var usedBase = false;
    reflaxe.elixir.ast.ASTUtils.walk(cl.body, function(n:ElixirAST){
      switch (n.def) { case EVar(v) if (v == base): usedBase = true; default: }
    });
    if (!usedBase) return cl;
    var newPat = switch (cl.pattern) {
      case PTuple(es2) if (es2.length == 2): PTuple([es2[0], PVar(base)]);
      default: cl.pattern;
    };
    // Also rewrite body references to the old underscored binder to the base name
    var newBody = reflaxe.elixir.ast.ElixirASTTransformer.transformNode(cl.body, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EVar(v) if (v == binder): makeASTWithMeta(EVar(base), n.metadata, n.pos);
        default: n;
      }
    });
    return { pattern: newPat, guard: cl.guard, body: newBody };
  }
}

#end
