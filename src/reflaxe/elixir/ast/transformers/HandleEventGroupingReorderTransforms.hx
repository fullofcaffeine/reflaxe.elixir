package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventGroupingReorderTransforms
 *
 * WHAT
 * - Reorders def handle_event/3 definitions so that all event-specific heads are
 *   grouped contiguously, followed immediately by a single catch-all
 *   def handle_event(_event, _params, socket), eliminating the grouping warning.
 *
 * WHY
 * - Phoenix warns when clauses with the same name/arity are not grouped together.
 *   Our LiveEventCaseToCallbacks pass can emit clauses separated by other defs.
 *   This pass fixes ordering structurally without changing bodies.
 *
 * HOW
 * - For EModule/EDefmodule bodies, collect EDef/EDefp named "handle_event" with arity 3.
 *   Partition into specific (first arg is a literal) and catch-alls (first arg is a var).
 *   Rebuild module body with: preDefs ++ specific ++ catchalls ++ postDefs, preserving
 *   relative order inside each partition.
 *
 * NOTES
 * - Shape-only; no app heuristics. Idempotent.
 */
class HandleEventGroupingReorderTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body):
          makeASTWithMeta(EModule(name, attrs, reorderHandleEvent(body)), n.metadata, n.pos);
        case EDefmodule(name2, doBlock):
          makeASTWithMeta(EDefmodule(name2, reorderHandleEventBlock(doBlock)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function reorderHandleEventBlock(block: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(block, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(stmts):
          makeASTWithMeta(EBlock(reorderHandleEvent(stmts)), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function reorderHandleEvent(stmts: Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null || stmts.length == 0) return stmts;
    var pre:Array<ElixirAST> = [];
    var post:Array<ElixirAST> = [];
    var specifics:Array<ElixirAST> = [];
    var catchalls:Array<ElixirAST> = [];
    for (s in stmts) {
      switch (s.def) {
        case EDef(fname, args, _, _) if (fname == "handle_event" && args != null && args.length == 3):
          if (isLiteral(args[0])) specifics.push(s) else catchalls.push(s);
        default:
          // Temporarily collect into pre; we will later append post as well preserving order
          pre.push(s);
      }
    }
    if (specifics.length == 0 && catchalls.length == 0) return stmts;
    // Remove original handle_event defs from pre
    var filtered:Array<ElixirAST> = [];
    for (s in pre) switch (s.def) {
      case EDef(fname, _, _, _) if (fname == "handle_event"): // skip
      default: filtered.push(s);
    }
    // Rebuild in order: everything else, then specifics, then catchalls
    var out = filtered.concat(specifics).concat(catchalls);
    return out;
  }

  static function isLiteral(p: EPattern): Bool {
    return switch (p) {
      case PLiteral(_): true;
      default: false;
    }
  }
}

#end

