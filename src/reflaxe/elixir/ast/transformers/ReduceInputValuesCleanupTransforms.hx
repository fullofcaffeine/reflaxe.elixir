package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceInputValuesCleanupTransforms
 *
 * WHAT
 * - Rewrites `Enum.reduce(Map.values(coll), init, fn binder, acc -> ... end)` to
 *   `Enum.reduce(coll, init, fn binder, acc -> ... end)` when the reducer body does
 *   not use Presence-specific entry metadata (`binder.metas`). This prevents
 *   incorrect `Map.values/1` wrapping when iterating plain lists.
 *
 * WHY
 * - Earlier rewrites intended for Phoenix Presence maps can conservatively wrap
 *   the reduce input with `Map.values/1`. When the collection is actually a list,
 *   `Map.values([])` raises `BadMapError` at runtime. This pass removes the
 *   wrapping in non-Presence shapes to restore correct list iteration.
 *
 * HOW
 * - Targets only `ERemoteCall(Enum, "reduce", [ERemoteCall(Map, "values", [coll]), init, fn])`.
 * - Inspects the reducer anonymous function to determine if the first argument
 *   (binder) is used with a `metas` field access anywhere in the body. If not,
 *   replace the input with `coll` directly.
 * - Shape-based and name-agnostic: uses the declared binder parameter, not
 *   specific variable names.
 *
 * EXAMPLES
 * Before:
 *   Enum.reduce(Map.values(tags), [], fn tag, acc ->
 *     acc = Enum.concat(acc, [render(tag)])
 *     acc
 *   end)
 * After:
 *   Enum.reduce(tags, [], fn tag, acc ->
 *     acc = Enum.concat(acc, [render(tag)])
 *     acc
 *   end)
 */
class ReduceInputValuesCleanupTransforms {
    static inline function reducerUsesPresenceMetas(fnNode: ElixirAST): Bool {
        return switch (fnNode.def) {
            case EFn(clauses) if (clauses.length == 1):
                var cl = clauses[0];
                var binderName: Null<String> = switch (cl.args.length > 0 ? cl.args[0] : null) { case PVar(n): n; default: null; };
                if (binderName == null) return false;
                var uses = false;
                function walk(n: ElixirAST): Void {
                    if (uses || n == null) return;
                    switch (n.def) {
                        case EField({def: EVar(v)}, field) if (v == binderName && field == "metas"): uses = true;
                        case EAccess({def: EField({def: EVar(v2)}, f2)}, _)
                            if (v2 == binderName && f2 == "metas"): uses = true;
                        case EBlock(ss): for (s in ss) walk(s);
                        case EDo(ss2): for (s in ss2) walk(s);
                        case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                        case EBinary(_, l, r): walk(l); walk(r);
                        case EMatch(_, rhs): walk(rhs);
                        case ECall(t,_,args): if (t != null) walk(t); for (a in args) walk(a);
                        case ERemoteCall(t2,_,args2): walk(t2); for (a2 in args2) walk(a2);
                        case EKeywordList(pairs): for (p in pairs) walk(p.value);
                        case EMap(pairs2): for (p2 in pairs2) { walk(p2.key); walk(p2.value); }
                        case EList(els): for (el in els) walk(el);
                        case ETuple(els2): for (el2 in els2) walk(el2);
                        default:
                    }
                }
                walk(cl.body);
                uses;
            default:
                false;
        };
    }

    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall({def: EVar(enumMod)}, "reduce", args) if (enumMod == "Enum" && args != null && args.length == 3):
                    switch (args[0].def) {
                        case ERemoteCall({def: EVar(mapMod)}, "values", [coll]) if (mapMod == "Map"):
                            // Only unwrap when reducer body does not use binder.metas (non-Presence loop)
                            var usesMetas = reducerUsesPresenceMetas(args[2]);
                            if (!usesMetas) makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "reduce", [coll, args[1], args[2]]), n.metadata, n.pos) else n;
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
}

#end

