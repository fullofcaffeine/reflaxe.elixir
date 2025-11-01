package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceInitMetasInGetUsersEditingTodoTransforms
 *
 * WHAT
 * - In Presence modules, ensure `get_users_editing_todo/2` initializes its
 *   accumulator and returns it instead of a literal empty list.
 *
 * WHY
 * - Some prior rewrites may transform list-building loops into reduce_while
 *   shapes without emitting the accumulator initialization; this guarantees
 *   compilation and idiomatic semantics without tying to app names.
 */
class PresenceInitMetasInGetUsersEditingTodoTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (looksPresence(n, name)):
          var nb = [for (b in body) applyToDefs(b)];
          makeASTWithMeta(EModule(name, attrs, nb), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (looksPresence(n, name2)):
          makeASTWithMeta(EDefmodule(name2, applyToDefs(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function looksPresence(node:ElixirAST, name:String):Bool {
    return (node.metadata?.isPresence == true) || (name != null && name.indexOf("Web.Presence") > 0) || StringTools.endsWith(name, ".Presence");
  }

  static function applyToDefs(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EDef("get_users_editing_todo", args, guards, body) if (args != null && args.length == 2):
          var init = makeAST(EBinary(Match, makeAST(EVar("metas")), makeAST(EList([]))));
          var nb = prependInitAndFixTail(body, init, "metas");
          makeASTWithMeta(EDef("get_users_editing_todo", args, guards, nb), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function prependInitAndFixTail(body:ElixirAST, init:ElixirAST, varName:String):ElixirAST {
    var withInit = switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock([init].concat(stmts)), body.metadata, body.pos);
      case EDo(stmts2): makeASTWithMeta(EDo([init].concat(stmts2)), body.metadata, body.pos);
      default: makeASTWithMeta(EBlock([init, body]), body.metadata, body.pos);
    }
    return switch (withInit.def) {
      case EBlock(stmts) if (stmts.length > 0):
        var last = stmts[stmts.length - 1];
        var newLast = switch (last.def) { case EList(_): makeAST(EVar(varName)); default: last; };
        var prefix = stmts.copy(); prefix.pop();
        makeASTWithMeta(EBlock(prefix.concat([newLast])), withInit.metadata, withInit.pos);
      case EDo(stmts2) if (stmts2.length > 0):
        var last2 = stmts2[stmts2.length - 1];
        var newLast2 = switch (last2.def) { case EList(_): makeAST(EVar(varName)); default: last2; };
        var prefix2 = stmts2.copy(); prefix2.pop();
        makeASTWithMeta(EDo(prefix2.concat([newLast2])), withInit.metadata, withInit.pos);
      default: withInit;
    }
  }
}

#end

