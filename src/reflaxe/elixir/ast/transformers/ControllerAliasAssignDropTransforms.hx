package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControllerAliasAssignDropTransforms
 *
 * WHAT
 * - Absolute-final sweep in controller modules to drop assignments to
 *   json/data/conn alias variables inside any block/do (including case arms).
 *
 * WHY
 * - These assignments are alias artifacts and trigger WAE unused-variable warnings.
 *   Removing them keeps the body clean and warning-free.
 */
class ControllerAliasAssignDropTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isController(name)):
          var out = [for (b in body) cleanse(b)];
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        case EDefmodule(moduleName, doBlock) if (isController(moduleName)):
          makeASTWithMeta(EDefmodule(moduleName, cleanse(doBlock)), n.metadata, n.pos);
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

  static function drop(b: ElixirAST): ElixirAST {
    return switch (b.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(filter(stmts)), b.metadata, b.pos);
      case EDo(stmts): makeASTWithMeta(EDo(filter(stmts)), b.metadata, b.pos);
      default: b;
    }
  }

  static inline function isAliasName(n:String):Bool {
    return n == "json" || n == "data" || n == "conn";
  }

  static function isAssignTo(stmt: ElixirAST, name:String): Bool {
    return switch (stmt.def) {
      case EBinary(Match, {def:EVar(nm)}, _): nm == name;
      case EMatch(PVar(binderName), _): binderName == name;
      default: false;
    }
  }

  static function filter(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (s in stmts) {
      if (isAssignTo(s, "json") || isAssignTo(s, "data") || isAssignTo(s, "conn")) continue;
      out.push(s);
    }
    return out;
  }
}

#end
