package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleEventDropUnusedHelperBindsTransforms
 *
 * WHAT
 * - Drops synthetic helper bindings inserted for LiveView params (value=params,
 *   sort_by=Map.get(params,"sort_by")) when those identifiers are never used in
 *   the remainder of the handle_event/3 body.
 *
 * WHY
 * - Binding helpers are injected early to prevent undefined-variable errors, but
 *   many callbacks don't use them, leading to noisy Elixir warnings. This pass
 *   removes the dead binds without affecting semantics.
 *
 * HOW
 * - For each handle_event/3 definition, if the body is a block/"do" list, scan
 *   statements in order. When a statement is a binding to `value` from params
 *   or to `sort_by` via Map.get(params,"sort_by"), check if the bound identifier
 *   is referenced in any subsequent statement. If not, drop that binding.
 */
class HandleEventDropUnusedHelperBindsTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var paramsVar = extractParamsVar(args);
          var nb = dropUnused(body, paramsVar);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var paramsVar2 = extractParamsVar(args2);
          var nb2 = dropUnused(body2, paramsVar2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }

  static inline function extractParamsVar(args:Array<EPattern>):String {
    if (args != null && args.length >= 2) {
      return switch (args[1]) { case PVar(n): n; default: "params"; }
    }
    return "params";
  }

  static function dropUnused(body:ElixirAST, paramsVar:String):ElixirAST {
    return switch (body.def) {
      case EBlock(stmts):
        makeASTWithMeta(EBlock(filter(stmts, paramsVar)), body.metadata, body.pos);
      case EDo(stmts2):
        makeASTWithMeta(EDo(filter(stmts2, paramsVar)), body.metadata, body.pos);
      default:
        body;
    }
  }

  static function filter(stmts:Array<ElixirAST>, paramsVar:String):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var drop = false;
      switch (s.def) {
        case EBinary(Match, lhs, rhs):
          drop = isValueAssign(lhs, rhs, paramsVar, stmts, i + 1) || isSortByAssign(lhs, rhs, paramsVar, stmts, i + 1);
        case EMatch(PVar(n), rhs2):
          drop = isValueAssignVar(n, rhs2, paramsVar, stmts, i + 1) || isSortByAssignVar(n, rhs2, paramsVar, stmts, i + 1);
        default:
      }
      if (!drop) out.push(s);
    }
    return out;
  }

  static inline function isValueAssign(lhs:ElixirAST, rhs:ElixirAST, paramsVar:String, stmts:Array<ElixirAST>, start:Int):Bool {
    return switch (lhs.def) {
      case EVar(v):
        v == "value" && isParamsVar(rhs, paramsVar) && !usedLater(stmts, start, "value");
      default: false;
    };
  }

  static inline function isValueAssignVar(name:String, rhs:ElixirAST, paramsVar:String, stmts:Array<ElixirAST>, start:Int):Bool {
    return name == "value" && isParamsVar(rhs, paramsVar) && !usedLater(stmts, start, "value");
  }

  static inline function isSortByAssign(lhs:ElixirAST, rhs:ElixirAST, paramsVar:String, stmts:Array<ElixirAST>, start:Int):Bool {
    return switch (lhs.def) {
      case EVar(v):
        v == "sort_by" && isSortByGet(rhs, paramsVar) && !usedLater(stmts, start, "sort_by");
      default: false;
    };
  }

  static inline function isSortByAssignVar(name:String, rhs:ElixirAST, paramsVar:String, stmts:Array<ElixirAST>, start:Int):Bool {
    return name == "sort_by" && isSortByGet(rhs, paramsVar) && !usedLater(stmts, start, "sort_by");
  }

  static inline function isParamsVar(rhs:ElixirAST, paramsVar:String):Bool {
    return switch (rhs.def) { case EVar(v) if (v == paramsVar): true; default: false; }
  }

  static inline function isSortByGet(rhs:ElixirAST, paramsVar:String):Bool {
    return switch (rhs.def) {
      case ERemoteCall({def: EVar("Map")}, "get", args):
        if (args != null && args.length == 2) {
          switch (args[0].def) {
            case EVar(v) if (v == paramsVar):
              switch (args[1].def) { case EString(s) if (s == "sort_by"): true; default: false; }
            default: false;
          }
        } else false;
      default: false;
    };
  }

  static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
    var found = false;
    for (j in start...stmts.length) {
      if (found) break;
      ASTUtils.walk(stmts[j], function(x:ElixirAST){
        switch (x.def) { case EVar(v) if (v == name): found = true; default: }
      });
    }
    return found;
  }
}

#end
