package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceRewriteGetUsersEditingTodoToReduceTransforms
 *
 * WHAT
 * - In Presence modules, rewrites get_users_editing_todo/2 to an idiomatic
 *   Enum.reduce(Map.values(all_users), [], fn entry, acc -> ... end) shape.
 *
 * WHY
 * - Avoids shadowed-accumulator warnings and ensures clean, deterministic code.
 */
class PresenceRewriteGetUsersEditingTodoToReduceTransforms {
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

  static function applyToDefs(node:ElixirAST):ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(x:ElixirAST):ElixirAST {
      return switch (x.def) {
        case EDef("get_users_editing_todo", args, guards, body) if (args != null && args.length == 2):
          // Align inner references to the actual second-arg binder name
          var todoIdVar = switch (args[1]) {
            case PVar(nm) if (nm != null && nm.length > 0): (nm.charAt(0) == '_' && nm.length > 1) ? nm.substr(1) : nm;
            default: "todo_id";
          };
          // Build: all_users = __MODULE__.list("users")
          var listCall = makeAST(ERemoteCall(makeAST(EVar("__MODULE__")), "list", [makeAST(EString("users"))]));
          var initAll = makeAST(EBinary(Match, makeAST(EVar("all_users")), listCall));
          // Build reduce: Enum.reduce(Map.values(all_users), [], fn entry, acc -> ... end)
          var values = makeAST(ERemoteCall(makeAST(EVar("Map")), "values", [makeAST(EVar("all_users"))]));
          var entryField = makeAST(EField(makeAST(EVar("entry")), "metas"));
          var lenCall = makeAST(ECall(null, "length", [entryField]));
          var metaIndex0 = makeAST(EAccess(entryField, makeAST(EInteger(0))));
          var initMeta = makeAST(EBinary(Match, makeAST(EVar("meta")), metaIndex0));
          var condEq = makeAST(EBinary(EBinaryOp.Equal,
            makeAST(EField(makeAST(EVar("meta")), "editing_todo_id")),
            makeAST(EVar(todoIdVar))
          ));
          var append = makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar("acc")), makeAST(EList([makeAST(EVar("meta"))]))]));
          var thenInner = makeAST(EIf(condEq, append, makeAST(EVar("acc"))));
          var thenBlock = makeAST(EBlock([initMeta, thenInner]));
          var reduceBody = makeAST(EIf(makeAST(EBinary(EBinaryOp.Greater, lenCall, makeAST(EInteger(0)))), thenBlock, makeAST(EVar("acc"))));
          var fnClause = { args: [PVar("entry"), PVar("acc")], guard: null, body: reduceBody };
          var reducer = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce", [values, makeAST(EList([])), makeAST(EFn([fnClause]))]));
          var newBody = makeAST(EBlock([initAll, reducer]));
          // Promote underscored second arg to base when referenced
          var newArgs = args;
          switch (args[1]) {
            case PVar(nm2) if (nm2 != null && nm2.length > 1 && nm2.charAt(0) == '_'):
              newArgs = [args[0], PVar(nm2.substr(1))];
            default:
          }
          makeASTWithMeta(EDef("get_users_editing_todo", newArgs, guards, newBody), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end
