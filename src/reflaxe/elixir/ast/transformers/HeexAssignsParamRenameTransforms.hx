package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexAssignsParamRenameTransforms
 *
 * WHAT
 * - Renames `_assigns` function parameter to `assigns` when the function body contains
 *   a `~H` sigil. HEEx macros require a parameter literally named `assigns`.
 *
 * WHY
 * - Earlier hygiene passes may underscore unused params, but when we introduce ~H later
 *   (via HXX or string→~H conversion), the param name must be corrected.
 *
 * HOW
 * - For each EDef/EDefp with args containing `PVar("_assigns")` and body subtree containing
 *   `ESigil("H", ...)`, rewrite that arg to `PVar("assigns")`.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HeexAssignsParamRenameTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) | EDefp(name, args, guards, body):
                    var hasUnderscoreAssigns = false;
                    var hasHSigil = containsHSigilAST(body);
                    if (!hasHSigil) return n;
                    var newArgs = [];
                    for (a in args) switch (a) {
                        case PVar(p) if (p == "_assigns"):
                            hasUnderscoreAssigns = true;
                            newArgs.push(PVar("assigns"));
                        default:
                            newArgs.push(a);
                    }
                    if (!hasUnderscoreAssigns) return n;
                    var def = reflaxe.elixir.util.EnumReflection.enumConstructor(n.def) == "EDef"
                        ? EDef(name, newArgs, guards, body)
                        : EDefp(name, newArgs, guards, body);
                    makeASTWithMeta(def, n.metadata, n.pos);
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

