package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControllerJsonDataArgPickSingleVarTransforms
 *
 * WHAT
 * - In controllers, when encountering Phoenix.Controller.json(conn, data),
 *   if the surrounding clause/function body references exactly one lower-case
 *   variable (excluding conn/params/socket), rewrite arg2 to that variable.
 */
class ControllerJsonDataArgPickSingleVarTransforms {
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
        case EDef(fn, args, g, body): makeASTWithMeta(EDef(fn, args, g, rewriteInBody(body)), n.metadata, n.pos);
        case EDefp(fn2, args2, g2, body2): makeASTWithMeta(EDefp(fn2, args2, g2, rewriteInBody(body2)), n.metadata, n.pos);
        case ECase(expr, clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: rewriteInBody(cl.body) });
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteInBody(body: ElixirAST): ElixirAST {
    var used = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST){
      switch (n.def) { case EVar(v): if (isCandidate(v)) used.set(v, true); default: }
    });
    var cands:Array<String> = []; for (k in used.keys()) cands.push(k);
    if (cands.length != 1) return body;
    var varName = cands[0];
    return ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ERemoteCall(t, fnName, args) if (fnName == "json" && args != null && args.length == 2):
          switch (args[1].def) { case EVar(v) if (v == "data"): makeASTWithMeta(ERemoteCall(t, fnName, [args[0], makeAST(EVar(varName))]), n.metadata, n.pos); default: n; }
        default: n;
      }
    });
  }

  static inline function isCandidate(v:String): Bool {
    if (v == null || v.length == 0) return false;
    if (v == "conn" || v == "params" || v == "socket" || v == "live_socket") return false;
    var c = v.charAt(0);
    return c.toLowerCase() == c;
  }
}

#end

