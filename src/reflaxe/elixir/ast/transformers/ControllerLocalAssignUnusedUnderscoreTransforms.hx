package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControllerLocalAssignUnusedUnderscoreTransforms
 *
 * WHAT
 * - In functions whose first parameter is named `conn` (common Phoenix
 *   controller/actions pattern), underscore local assignment binders that are
 *   not referenced later in the same block/arm.
 *
 * WHY
 * - Eliminates WAE warnings for throwaway locals introduced during lowering
 *   (e.g., data/json/user/changeset), without relying on specific names.
 */
class ControllerLocalAssignUnusedUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (args != null && args.length >= 1 && isConnParam(args[0])):
          var nb = rewriteBlocks(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isConnParam(pat: reflaxe.elixir.ast.EPattern): Bool {
    return switch (pat) { case PVar(n) if (n == "conn"): true; default: false; }
  }

  static function rewriteBlocks(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), x.metadata, x.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var s1 = switch (s.def) {
        case EBinary(Match, {def: EVar(b)}, rhs) if (!usedLater(stmts, i+1, b) && isSimple(rhs)):
          makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b)), rhs), s.metadata, s.pos);
        case EMatch(PVar(b2), rhs2) if (!usedLater(stmts, i+1, b2) && isSimple(rhs2)):
          makeASTWithMeta(EMatch(PVar('_' + b2), rhs2), s.metadata, s.pos);
        default: s;
      }
      out.push(s1);
    }
    return out;
  }

  static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
    var found = false;
    for (j in start...stmts.length) if (!found) {
      reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(x:ElixirAST){
        switch (x.def) { case EVar(v) if (v == name): found = true; default: }
      });
    }
    return found;
  }

  static function isSimple(e: ElixirAST): Bool {
    return switch (e.def) {
      case EVar(_): true;
      case EString(_): true;
      case EInteger(_): true;
      case EFloat(_): true;
      case EBoolean(_): true;
      case ENil: true;
      default: false;
    }
  }
}

#end
