package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleEventPruneHelperBindsTransforms
 *
 * WHAT
 * - LiveView-specific hygiene: in handle_event/3, keep at most one binding for
 *   `value` and one for `sort_by`, and drop them entirely if unused in the body.
 *
 * WHY
 * - Upstream helper passes may inject repetitive `value = params` and
 *   `sort_by = Map.get(...)` statements. When unused, they only create warnings.
 *   This pass prunes those injected helpers without suppressing warnings
 *   globally or changing semantics.
 *
 * HOW
 * - For each handle_event/3 definition:
 *   1) Detect whether `value` and/or `sort_by` are referenced in the body.
 *   2) Remove all helper statements that assign `value = ...` or `sort_by = ...`
 *      when the respective variable is not referenced.
 *   3) If referenced, keep only the first binding; drop duplicates to avoid
 *      warning spam.
 * - Only touches handle_event/3; no app-specific names beyond `value`/`sort_by`.
 */
class HandleEventPruneHelperBindsTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var cleaned = prune(body);
          makeASTWithMeta(EDef(name, args, guards, cleaned), n.metadata, n.pos);
        case EDefp(name, args, guards, body) if (isHandleEvent3(name, args)):
          var cleaned2 = prune(body);
          makeASTWithMeta(EDefp(name, args, guards, cleaned2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }

  static function prune(body: ElixirAST): ElixirAST {
    var usesValue = usesVar(body, "value");
    var usesSort = usesVar(body, "sort_by");
    var valueKept = false;
    var sortKept = false;

    return switch (body.def) {
      case EBlock(stmts):
        var out:Array<ElixirAST> = [];
        for (s in stmts) {
          if (isHelperAssign(s, "value")) {
            if (!usesValue) continue;
            if (valueKept) continue;
            valueKept = true;
            out.push(s);
            continue;
          }
          if (isHelperAssign(s, "sort_by")) {
            if (!usesSort) continue;
            if (sortKept) continue;
            sortKept = true;
            out.push(s);
            continue;
          }
          out.push(s);
        }
        makeASTWithMeta(EBlock(out), body.metadata, body.pos);
      default:
        body; // not a block, leave untouched
    }
  }

  static function isHelperAssign(stmt: ElixirAST, name:String):Bool {
    if (stmt == null || stmt.def == null) return false;
    return switch (stmt.def) {
      case EBinary(Match, lhs, _):
        switch (lhs.def) { case EVar(v) if (v == name): true; default: false; }
      default: false;
    }
  }

  static function usesVar(body: ElixirAST, name:String):Bool {
    var found = false;
    ASTUtils.walk(body, function(x:ElixirAST) {
      if (found || x == null || x.def == null) return;
      switch (x.def) {
        // Ignore the helper binding itself (value = ..., sort_by = ...)
        case EBinary(Match, lhs, _) if (isHelperLhs(lhs, name)):
          // skip
        case EVar(v) if (v == name):
          found = true;
        default:
      }
    });
    return found;
  }

  static function isHelperLhs(lhs: ElixirAST, name:String):Bool {
    return switch (lhs.def) {
      case EVar(v) if (v == name): true;
      default: false;
    }
  }
}
#end
