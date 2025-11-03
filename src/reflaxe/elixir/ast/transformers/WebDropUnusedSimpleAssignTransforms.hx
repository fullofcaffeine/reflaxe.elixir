package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WebDropUnusedSimpleAssignTransforms
 *
 * WHAT
 * - In Web modules (controllers and LiveView), drop simple local assignments
 *   `name = <pure RHS>` when `name` is not used later in the same block/do/arm.
 *
 * WHY
 * - Haxe → Elixir can introduce harmless aliasing that triggers warnings-as-errors.
 *   Dropping provably-unused simple assigns eliminates noise without behavior change.
 *
 * HOW
 * - Walk EBlock/EDo statement lists: if a statement is `EMatch(PVar(name), rhs)` and
 *   `rhs` is pure (EVar/ELiteral/EMap/EKeywordList/EAtom/ENil/ETuple/List/Struct) and
 *   `name` does not appear in any statement that follows in that list, drop it.
 */
class WebDropUnusedSimpleAssignTransforms {
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

  static function filter(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      // EMatch(PVar(name), rhs)
      switch (s.def) {
        case EMatch(PVar(nm), rhs) if (isAliasName(nm) && isPure(rhs) && !usedLater(stmts, i+1, nm)):
          // drop
        case EBinary(Match, {def:EVar(nm2)}, rhs2) if (isAliasName(nm2) && isPure(rhs2) && !usedLater(stmts, i+1, nm2)):
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

  static inline function isAliasName(n:String):Bool {
    return n == "json" || n == "data" || n == "conn";
  }

  static function usedLater(stmts:Array<ElixirAST>, from:Int, name:String): Bool {
    for (j in from...stmts.length) {
      var found = false;
      reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(n:ElixirAST){
        switch (n.def) { case EVar(v) if (v == name): found = true; default: }
      });
      if (found) return true;
    }
    return false;
  }
}

#end
