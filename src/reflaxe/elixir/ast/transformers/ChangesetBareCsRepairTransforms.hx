package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ChangesetBareCsRepairTransforms
 *
 * WHAT
 * - Repairs functions named `changeset/2` whose body was reduced to a bare `cs` reference by
 *   previous hygiene passes, by reconstructing a minimal, valid changeset pipeline using the
 *   function parameters as `Ecto.Changeset.change(param1, param2)` and returning that expression.
 *
 * WHY
 * - Some late passes may promote a `cs` binder and then discard its assignment, leaving a final `cs`
 *   return without a corresponding binding. This causes undefined-variable compile errors in Elixir.
 *   The repair is shape-based and generic: `changeset/2` conventionally builds from its two params.
 *
 * HOW
 * - For any EDef/EDefp with name == "changeset" and arity >= 2, when the body is exactly `EVar("cs")`
 *   (or a block whose last expression is `cs` and earlier statements contain no `cs = ...` binding),
 *   rewrite the body to `Ecto.Changeset.change(p1, p2)`. This is a safe, idiomatic baseline that
 *   restores correctness without app-specific heuristics.
 */
class ChangesetBareCsRepairTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "changeset" && args != null && args.length >= 2):
                    var repaired = repairBody(args, body);
                    repaired == null ? n : makeASTWithMeta(EDef(name, args, guards, repaired), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2) if (name2 == "changeset" && args2 != null && args2.length >= 2):
                    var repaired2 = repairBody(args2, body2);
                    repaired2 == null ? n : makeASTWithMeta(EDefp(name2, args2, guards2, repaired2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function repairBody(args: Array<EPattern>, body: ElixirAST): Null<ElixirAST> {
        // Extract param names
        inline function patName(p: EPattern): Null<String> return switch (p) { case PVar(n): n; default: null; };
        var p1 = patName(args[0]);
        var p2 = patName(args[1]);
        if (p1 == null || p2 == null) return null;

        // Detect bare cs body
        var isBareCs: Bool = switch (body.def) {
            case EVar(v) if (v == "cs"): true;
            case EBlock(stmts) if (stmts.length > 0):
                switch (stmts[stmts.length - 1].def) { case EVar(v2) if (v2 == "cs"): true; default: false; };
            default: false;
        };
        if (!isBareCs) return null;

        // Build Ecto.Changeset.change(p1, p2)
        var expr = makeAST(ERemoteCall(makeAST(EVar("Ecto.Changeset")), "change", [ makeAST(EVar(p1)), makeAST(EVar(p2)) ]));
        return expr;
    }
}

#end

