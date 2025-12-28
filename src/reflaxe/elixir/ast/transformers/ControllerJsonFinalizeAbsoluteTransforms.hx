package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControllerJsonFinalizeAbsoluteTransforms
 *
 * WHAT
 * - Absolute-last controller cleanup: in {:ok, binder}/{:error, binder} case arms,
 *   rewrite Phoenix.Controller.json(conn, data) to use the case binder as the
 *   second argument, and drop simple alias assignments to json/data/conn within
 *   the arm body.

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
class ControllerJsonFinalizeAbsoluteTransforms {
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
        case EDef(fn, args, g, body): makeASTWithMeta(EDef(fn, args, g, scan(body)), n.metadata, n.pos);
        case EDefp(fn2, args2, g2, body2): makeASTWithMeta(EDefp(fn2, args2, g2, scan(body2)), n.metadata, n.pos);
        case ECase(expr, clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: fixArm(cl.pattern, cl.body) });
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function scan(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out = [];
          for (cl in clauses) out.push({ pattern: cl.pattern, guard: cl.guard, body: fixArm(cl.pattern, cl.body) });
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function fixArm(pat:EPattern, body:ElixirAST): ElixirAST {
    var binder:Null<String> = null;
    switch (pat) {
      case PTuple(es) if (es.length == 2):
        switch (es[1]) { case PVar(nm): binder = nm; default: }
      default:
    }
    var b = ensureBlock(body);
    var stmts = b.stmts;

    // Capture last RHS assigned to `data` inside this arm before dropping aliases.
    // This lets us inline complex payload maps that were previously routed via `data`.
    var lastDataRhs:Null<ElixirAST> = null;
    for (s in stmts) {
      switch (s.def) {
        case EBinary(Match, {def:EVar(nm)}, rhs) if (nm == "data"):
          lastDataRhs = rhs;
        case EMatch(PVar(nm2), rhs2) if (nm2 == "data"):
          lastDataRhs = rhs2;
        default:
      }
    }

    // Drop alias lines first
    var filtered:Array<ElixirAST> = [];
    for (s in stmts) {
      if (isAssignTo("json", s) || isAssignTo("data", s) || isAssignTo("conn", s)) continue;
      filtered.push(s);
    }
    // Rewrite json(conn, data) second arg to binder if available
    var rewritten:Array<ElixirAST> = [];
    for (s in filtered) {
      rewritten.push(rewriteJsonSecondArg(s, binder, lastDataRhs));
    }
    return makeASTWithMeta(EBlock(rewritten), body.metadata, body.pos);
  }

  static function ensureBlock(body:ElixirAST): {stmts:Array<ElixirAST>} {
    return switch (body.def) {
      case EBlock(stmts): {stmts: stmts};
      case EDo(stmts2): {stmts: stmts2};
      default: {stmts: [body]};
    }
  }

  static inline function isAssignTo(name:String, stmt:ElixirAST):Bool {
    return switch (stmt.def) {
      case EBinary(Match, {def:EVar(n)}, _): n == name;
      case EMatch(PVar(n2), _): n2 == name;
      default: false;
    }
  }

  static function rewriteJsonSecondArg(node:ElixirAST, binder:Null<String>, lastDataRhs:Null<ElixirAST>): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ERemoteCall(t, fnName, args) if (fnName == "json" && args != null && args.length == 2):
          switch (args[1].def) {
            case EVar(v) if (v == "data"):
              // Prefer inlining the captured payload expression when available;
              // fall back to case binder as a generic safety net.
              if (lastDataRhs != null) {
                #if debug_ast_transformer
                #end
                makeASTWithMeta(ERemoteCall(t, fnName, [args[0], lastDataRhs]), n.metadata, n.pos);
              } else if (binder != null) {
                #if debug_ast_transformer
                // DEBUG: Sys.println('[ControllerJsonFinalize] Rewriting Phoenix.Controller.json(conn, data) -> binder ' + binder);
                #end
                makeASTWithMeta(ERemoteCall(t, fnName, [args[0], makeAST(EVar(binder))]), n.metadata, n.pos);
              } else {
                n;
              }
            case EVar(v2) if (v2 == "json"):
              // Historical alias; rewrite to binder if present to avoid undefined var
              if (binder != null) {
                #if debug_ast_transformer
                // DEBUG: Sys.println('[ControllerJsonFinalize] Rewriting Phoenix.Controller.json(conn, json) -> binder ' + binder);
                #end
                makeASTWithMeta(ERemoteCall(t, fnName, [args[0], makeAST(EVar(binder))]), n.metadata, n.pos);
              } else n;
            default: n;
          }
        default: n;
      }
    });
  }
}

#end
