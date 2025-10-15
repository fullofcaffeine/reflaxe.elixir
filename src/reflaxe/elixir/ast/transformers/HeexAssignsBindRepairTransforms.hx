package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexAssignsBindRepairTransforms
 *
 * WHAT
 * - In render/1, repair wildcard assignments of Phoenix.Component.assign/2 to
 *   bind to the "assigns" variable so that ~H can use @content (or other assigns).
 *
 * WHY
 * - Late hygiene may convert `assigns = Phoenix.Component.assign(assigns, map)`
 *   into `_ = Phoenix.Component.assign(assigns, map)` when the local "assigns"
 *   variable is not referenced textually after injection. HEEx relies on assigns
 *   being updated; wildcard discards the new map, leading to KeyError at runtime.
 *
 * HOW
 * - Targets only functions named "render". Looks for assignments where LHS is a
 *   wildcard (`_`) and RHS is Phoenix.Component.assign(first, second). Rewrites
 *   LHS to bind the first argument variable name when it is a simple variable.
 * - Supports both EMatch(PWildcard, ...) and EBinary(Match, EVar("_"), ...).
 */
class HeexAssignsBindRepairTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "render"):
                    var fixed = fixBody(body);
                    makeASTWithMeta(EDef(name, args, guards, fixed), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function fixBody(body: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                // _ = Phoenix.Component.assign(first, second)
                case EBinary(Match, {def: EVar(lv)} , { def: ERemoteCall({def: EVar(mod)}, "assign", [firstArg, secondArg]) }) if (lv == "_" && mod == "Phoenix.Component"):
                    switch (firstArg.def) {
                        case EVar(firstName):
                            makeASTWithMeta(EBinary(Match, makeAST(EVar(firstName)), makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [firstArg, secondArg]))), x.metadata, x.pos);
                        default:
                            x;
                    }
                // _ = ... (pattern form)
                case EMatch(PWildcard, { def: ERemoteCall({def: EVar(mod2)}, "assign", [fa2, sa2]) }) if (mod2 == "Phoenix.Component"):
                    switch (fa2.def) {
                        case EVar(firstName2):
                            makeASTWithMeta(EMatch(PVar(firstName2), makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [fa2, sa2]))), x.metadata, x.pos);
                        default:
                            x;
                    }
                default:
                    x;
            }
        });
    }
}

#end

