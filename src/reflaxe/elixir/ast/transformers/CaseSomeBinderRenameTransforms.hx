package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseSomeBinderRenameTransforms
 *
 * WHAT
 * - Renames the binder in `{:some, g}` case patterns to a descriptive name
 *   (`value`) and rewrites references in the corresponding clause body.
 *
 * WHY
 * - Haxe frequently emits temporary variables named `g` for intermediate values.
 *   When combined with `case` expressions, patterns like `{:some, g}` can collide
 *   with an outer local `g = case ... end`, causing the inner `case g do` to
 *   unintentionally reference the outer `g` value. This leads to runtime
 *   CaseClauseError mismatches.
 *
 * HOW
 * - Traverse ECase clauses; whenever a pattern matches `{:some, PVar("g")}`:
 *   - Replace the binder with `PVar("value")` in the pattern
 *   - Rewrite `EVar("g")` occurrences to `EVar("value")` in the clause body
 * - Scope: only within the affected clause body to avoid cross‑clause changes

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class CaseSomeBinderRenameTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(target, clauses):
          var out:Array<ElixirAST.ECaseClause> = [];
          var changed = false;
          for (cl in clauses) {
            var renamed = cl;
            switch (cl.pattern) {
              case PTuple(items) if (items.length == 2):
                var first = items[0];
                var second = items[1];
                var isSome = switch (first) {
                  case PLiteral({def: EAtom(a)}): (a : String) == "some";
                  default: false;
                };
                switch (second) {
                  case PVar(vn) if (isSome && vn == "g"):
                    // Only rename when clause body contains a nested case on the same binder.
                    // This avoids rewriting after later transforms (e.g., flatten) where no nested case remains.
                    var hasInnerCaseOnBinder = false;
                    // Lightweight scan: look for ECase whose scrutinee is EVar(vn)
                    function scan(e: ElixirAST): Void {
                      if (e == null || e.def == null) return;
                      switch (e.def) {
                        case ECase(scrut, _):
                          switch (scrut.def) { case EVar(v) if (v == vn): hasInnerCaseOnBinder = true; default: }
                          // continue scanning inner bodies only if not found yet
                          if (!hasInnerCaseOnBinder) switch (e.def) { case ECase(_, cls): for (c in cls) scan(c.body); default: }
                        case EBlock(stmts) | EDo(stmts): for (s in stmts) scan(s);
                        case EIf(c,t,el): scan(c); scan(t); if (el != null) scan(el);
                        default:
                      }
                    }
                    scan(cl.body);
                    if (hasInnerCaseOnBinder) {
                      // Build new pattern with descriptive binder
                      var newPattern = PTuple([ first, PVar("value") ]);
                      // Rewrite references to the old binder only within this clause body
                      var newBody = ElixirASTTransformer.transformNode(cl.body, function(b:ElixirAST):ElixirAST {
                        return switch (b.def) {
                          case EVar(name) if (name == vn): makeASTWithMeta(EVar("value"), b.metadata, b.pos);
                          default: b;
                        }
                      });
                      renamed = { pattern: newPattern, guard: cl.guard, body: newBody };
                      changed = true;
                    } else {
                      // No nested case on the binder; leave clause untouched.
                    }
                  default:
                }
              default:
            }
            out.push(renamed);
          }
          return changed ? makeASTWithMeta(ECase(target, out), n.metadata, n.pos) : n;
        default:
          n;
      }
    });
  }
}

#end
