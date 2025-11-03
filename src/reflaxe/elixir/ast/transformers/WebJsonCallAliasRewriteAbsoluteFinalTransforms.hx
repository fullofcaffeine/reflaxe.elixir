package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WebJsonCallAliasRewriteAbsoluteFinalTransforms
 *
 * WHAT
 * - In Web.* modules, for Phoenix.Controller.json(conn, data) calls preceded by
 *   simple alias assignments to json/data/conn, drop those alias lines and
 *   rewrite the call’s second argument to the RHS var of the alias chain.
 *
 * WHY
 * - Guarantees removal of alias artifacts at the absolute final stage even if
 *   earlier controller-specific passes did not trigger due to ordering.
 */
class WebJsonCallAliasRewriteAbsoluteFinalTransforms {
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
        case EDef(fn, args, g, body): makeASTWithMeta(EDef(fn, args, g, dropAliases(body)), n.metadata, n.pos);
        case EDefp(fn2, args2, g2, body2): makeASTWithMeta(EDefp(fn2, args2, g2, dropAliases(body2)), n.metadata, n.pos);
        case ECase(expr, clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: dropAliases(cl.body) });
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function dropAliases(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), body.metadata, body.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), body.metadata, body.pos);
      default: body;
    }
  }

  static function rewrite(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    var i = 0;
    while (i < stmts.length) {
      var s = stmts[i];
      if (isJsonCall(s)) {
        // scan backwards for alias chain
        var k = out.length - 1;
        var rhs:Null<String> = null;
        while (k >= 0 && (isAssignTo("json", out[k]) || isAssignTo("data", out[k]) || isAssignTo("conn", out[k]))) {
          var rv = rhsVar(out[k]);
          if (rv != null) rhs = rv;
          out.splice(k, 1); // drop alias line
          k--;
        }
        // rewrite json second arg if we found rhs var
        var call = s;
        if (rhs != null) {
          call = ElixirASTTransformer.transformNode(call, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
              case ERemoteCall(t, fnName, args) if (fnName == "json" && args.length == 2):
                makeASTWithMeta(ERemoteCall(t, fnName, [args[0], makeAST(EVar(rhs))]), n.metadata, n.pos);
              default: n;
            }
          });
        }
        out.push(call); i++;
        continue;
      }
      out.push(s); i++;
    }
    return out;
  }

  static inline function isAssignTo(name:String, stmt:ElixirAST): Bool {
    return switch (stmt.def) {
      case EBinary(Match, {def:EVar(nm)}, _): nm == name;
      case EMatch(PVar(nm2), _): nm2 == name;
      default: false;
    }
  }
  static inline function rhsVar(stmt:ElixirAST): Null<String> {
    return switch (stmt.def) {
      case EBinary(Match, _, {def: EVar(v)}): v;
      case EMatch(_, {def: EVar(v2)}): v2;
      default: null;
    }
  }
  static inline function isJsonCall(e: ElixirAST): Bool {
    return switch (e.def) {
      case ERemoteCall(target, fnName, args):
        if (fnName != "json" || args == null || args.length != 2) return false;
        switch (target.def) { case EVar(m) if (m == "Phoenix.Controller"): true; default: false; }
      default: false;
    }
  }
}

#end

