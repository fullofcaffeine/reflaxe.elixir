package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControllerResultBinderNormalizeTransforms
 *
 * WHAT
 * - In controller modules, normalize {:ok, _x}/{:error, _y} payload binders to
 *   value/reason respectively when the binder is underscored.
 *
 * WHY
 * - Prevents “underscored variable used after being set” warnings and aligns with
 *   common naming for Result payloads without coupling to app names.
 *
 * HOW
 * - For each ECase clause pattern PTuple([PLiteral(:ok), PVar(_x)]) → PVar("value")
 *   PTuple([PLiteral(:error), PVar(_y)]) → PVar("reason"). Body unchanged.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ControllerResultBinderNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isController(name)):
          var out = [for (b in body) normalize(b)];
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (isController(name2)):
          makeASTWithMeta(EDefmodule(name2, normalize(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isController(name:String):Bool {
    return name != null && name.indexOf("Web.") > 0 && StringTools.endsWith(name, "Controller");
  }

  static function normalize(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push(normalizeClause(cl));
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function normalizeClause(cl:{pattern:EPattern, guard:ElixirAST, body:ElixirAST}):{pattern:EPattern, guard:ElixirAST, body:ElixirAST} {
    var pat2 = rewritePattern(cl.pattern);
    return { pattern: pat2, guard: cl.guard, body: cl.body };
  }

  static function bodyDoesNotUse(body: ElixirAST, name:String): Bool {
    var used = false;
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST){ switch (n.def) { case EVar(v) if (v == name): used = true; default: }});
    return !used;
  }

  static function rewritePattern(p:EPattern):EPattern {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) {
          case PLiteral(lit) if (isAtom(lit, ":ok")):
            switch (es[1]) { case PVar(n) if (n != null && n.length > 0 && n.charAt(0) == '_'): PTuple([es[0], PVar("value")]); default: p; }
          case PLiteral(lit2) if (isAtom(lit2, ":error")):
            switch (es[1]) { case PVar(n2) if (n2 != null && n2.length > 0 && n2.charAt(0) == '_'): PTuple([es[0], PVar("reason")]); default: p; }
          default: p;
        }
      default: p;
    }
  }

  static inline function isAtom(ast: ElixirAST, name:String):Bool {
    return switch (ast.def) { case EAtom(v): v == name || v == name.substr(1); default: false; };
  }
}

#end
