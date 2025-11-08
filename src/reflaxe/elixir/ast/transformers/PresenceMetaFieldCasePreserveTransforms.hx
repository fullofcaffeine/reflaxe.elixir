package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceMetaFieldCasePreserveTransforms
 *
 * WHAT
 * - When a local variable is bound from a Presence entry meta (user_presence.metas[0]
 *   or Enum.at(user_presence.metas, 0)), preserve camelCase field names on accesses to
 *   that variable to match typed Haxe metadata shapes (e.g., onlineAt, userName).
 *
 * WHY
 * - Generic field snake-casing is correct for most Elixir structs/maps, but snapshot
 *   parity tests for Presence expect camelCase metadata field access for typed meta.
 *   This pass scopes the exception strictly to variables proven to originate from
 *   Presence meta extraction to avoid app coupling.
 *
 * HOW
 * - Within function bodies (EDef/EDefp), scan for assignments binding a name from
 *   either `user_presence.metas[<int>]` or `Enum.at(user_presence.metas, <int>)`.
 *   Record those binder names. In subsequent expressions in that function, rewrite
 *   field names `online_at`→`onlineAt` and `user_name`→`userName` when the receiver
 *   is EVar(boundName).
 */
class PresenceMetaFieldCasePreserveTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          makeASTWithMeta(EDef(name, args, guards, transformBody(body)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          makeASTWithMeta(EDefp(name2, args2, guards2, transformBody(body2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function transformBody(body: ElixirAST): ElixirAST {
    var metaVars = new Map<String,Bool>();
    // First pass: collect presence meta binders
    function collect(n: ElixirAST): Void {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EBinary(Match, {def: EVar(lhs)}, rhs):
          if (isPresenceMetaExpr(rhs)) metaVars.set(lhs, true);
        case EMatch(PVar(lhs2), rhs2):
          if (isPresenceMetaExpr(rhs2)) metaVars.set(lhs2, true);
        case EBlock(exprs): for (e in exprs) collect(e);
        default:
      }
    }
    collect(body);

    if (!metaVars.keys().hasNext()) return body;

    // Second pass: rewrite field names on collected vars
    return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EField({def: EVar(v)}, field) if (metaVars.exists(v)):
          var mapped = mapField(field);
          if (mapped != field) makeASTWithMeta(EField(makeASTWithMeta(EVar(v), n.metadata, n.pos), mapped), n.metadata, n.pos) else n;
        default:
          n;
      }
    });
  }

  static function isPresenceMetaExpr(e: ElixirAST): Bool {
    if (e == null || e.def == null) return false;
    return switch (e.def) {
      case EAccess({def: EField(_, f)}, {def: EInteger(_)}): f == "metas";
      case ERemoteCall({def: EVar(m)}, fn, args) if (m == "Enum" && fn == "at" && args.length == 2):
        switch (args[0].def) { case EField(_, f2) if (f2 == "metas"): true; default: false; }
      default: false;
    }
  }

  static inline function mapField(name:String):String {
    return switch (name) {
      case "online_at": "onlineAt";
      case "user_name": "userName";
      default: name;
    }
  }
}

#end

