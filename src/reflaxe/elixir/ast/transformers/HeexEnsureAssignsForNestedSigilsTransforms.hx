package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexEnsureAssignsForNestedSigilsTransforms
 *
 * WHAT
 * - Ensures functions that contain ~H sigils but do not take an `assigns` param
 *   have a local `assigns = %{}` binding in scope so HEEx compiles.
 *
 * WHY
 * - Some helpers render small HEEx fragments (for example, a checkmark span) inside
 *   branches. When those helpers don't take `assigns`, Phoenix requires a local
 *   `assigns` map. This pass guarantees that requirement without changing
 *   public signatures.
 *
 * HOW
 * - For each EDef/EDefp:
 *   - If no param named `assigns` or `_assigns`, and body subtree contains
 *     ESigil("H", ...), wrap body in a leading block:
 *       assigns = %{}
 *       <original body>
 */
class HeexEnsureAssignsForNestedSigilsTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) | EDefp(name, args, guards, body):
                    var hasAssigns = false;
                    for (a in args) switch (a) {
                        case PVar(p) if (p == "assigns" || p == "_assigns"): hasAssigns = true;
                        default:
                    }
                    if (hasAssigns || !containsHSigilAST(body)) {
                        n;
                    } else {
                        var wrapped = makeAST(EBlock([
                            makeAST(EMatch(PVar("assigns"), makeAST(EMap([])))),
                            body
                        ]));
                        var def = Type.enumConstructor(n.def) == "EDef"
                            ? EDef(name, args, guards, wrapped)
                            : EDefp(name, args, guards, wrapped);
                        makeASTWithMeta(def, n.metadata, n.pos);
                    }
                default:
                    n;
            }
        });
    }

    static function containsHSigilAST(node: ElixirAST):Bool {
        var found = false;
        function walk(n: ElixirAST):Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case ESigil(type, _, _) if (type == "H"): found = true; return;
                case EBlock(es): for (e in es) walk(e);
                case EIf(c, t, e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(e, cs): walk(e); for (cl in cs) walk(cl.body);
                case EDo(b): for (e in b) walk(e);
                case EParen(inner): walk(inner);
                case ECall(t, _, as): if (t != null) walk(t); for (a in as) walk(a);
                case ERemoteCall(m, _, as): walk(m); for (a in as) walk(a);
                case EBinary(_, l, r): walk(l); walk(r);
                case EList(el): for (e in el) walk(e);
                case ETuple(el): for (e in el) walk(e);
                case EMap(p): for (kv in p) { walk(kv.key); walk(kv.value);} 
                case EStruct(_, fs): for (f in fs) walk(f.value);
                case EFn(cs): for (cl in cs) walk(cl.body);
                default:
            }
        }
        walk(node);
        return found;
    }
}

#end
