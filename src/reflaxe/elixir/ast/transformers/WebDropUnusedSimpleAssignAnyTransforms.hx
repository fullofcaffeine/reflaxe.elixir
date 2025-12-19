package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

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
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      switch (s.def) {
        case EBinary(Match, {def:EVar(binder)}, rhs) if (isPure(rhs) && !usedLater(stmts, i+1, binder)):
          // drop
        case EMatch(PVar(binder), rhs) if (isPure(rhs) && !usedLater(stmts, i+1, binder)):
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

  static function usedLater(stmts:Array<ElixirAST>, from:Int, name:String): Bool {
    for (j in from...stmts.length) {
      var found = false;
      reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(n:ElixirAST){
        switch (n.def) {
          case EVar(v) if (v == name):
            found = true;
          case ERaw(code) if (rawUsesVarName(code, name)):
            found = true;
          default:
        }
      });
      if (found) return true;
    }
    return false;
  }

  /**
   * Detect variable name usage inside ERaw code.
   *
   * WHY
   * - __elixir__() placeholder substitution produces ERaw strings like
   *   `Phoenix.Component.assign(socket, %{...})`.
   * - Late cleanup passes that rely on EVar-only scanning must treat ERaw as a use-site,
   *   otherwise they can incorrectly drop required binders (leading to undefined vars).
   *
   * HOW
   * - Scan for `name` occurrences that are token-bounded (not part of a longer identifier).
   * - Exclude atom occurrences like `:name` to avoid false positives.
   */
  static function rawUsesVarName(code: String, name: String): Bool {
    if (code == null || name == null || name.length == 0) return false;
    var idx = -1;
    while (true) {
      idx = code.indexOf(name, idx + 1);
      if (idx == -1) return false;
      var before = idx == 0 ? "" : code.charAt(idx - 1);
      var afterIndex = idx + name.length;
      var after = afterIndex >= code.length ? "" : code.charAt(afterIndex);
      if (isTokenBoundary(before) && isTokenBoundary(after) && before != ":") {
        return true;
      }
    }
    return false;
  }

  static inline function isTokenBoundary(ch: String): Bool {
    if (ch == null || ch.length == 0) return true;
    if (ch == "_") return false;
    var c = ch.charCodeAt(0);
    return !((c >= 'A'.code && c <= 'Z'.code)
      || (c >= 'a'.code && c <= 'z'.code)
      || (c >= '0'.code && c <= '9'.code));
  }
}

#end
