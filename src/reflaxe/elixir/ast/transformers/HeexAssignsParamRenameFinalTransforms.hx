package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexAssignsParamRenameFinalTransforms
 *
 * WHAT
 * - Absolute-final safety net: rename `_assigns` → `assigns` in def/defp whose
 *   bodies contain HEEx (~H) usage in any recognized shape.
 *
 * WHY
 * - Earlier passes may miss renaming if ~H is introduced late or represented as
 *   ERemoteCall(Phoenix.Component.sigil_H/2) or even ERaw fragments in snapshots.
 *   Phoenix requires a parameter literally named `assigns` for ~H.
 *
 * HOW
 * - For each def/defp, if args include PVar("_assigns") and body contains:
 *     - ESigil("H", ...), or
 *     - ERemoteCall(_, "sigil_H", _), or
 *     - ERaw with token-bounded "~H" substring,
 *   then rename that param to PVar("assigns"). No body rewrite needed.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HeexAssignsParamRenameFinalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    if (!hasUnderscoreAssigns(args) || !containsHSigilAny(body)) return n;
                    makeASTWithMeta(EDef(name, rename(args), guards, body), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2):
                    if (!hasUnderscoreAssigns(args2) || !containsHSigilAny(body2)) return n;
                    makeASTWithMeta(EDefp(name2, rename(args2), guards2, body2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function hasUnderscoreAssigns(args:Array<EPattern>):Bool {
        if (args == null) return false;
        for (a in args) switch (a) { case PVar(p) if (p == "_assigns"): return true; default: }
        return false;
    }

    static inline function rename(args:Array<EPattern>):Array<EPattern> {
        var out:Array<EPattern> = [];
        for (a in args) switch (a) { case PVar(p) if (p == "_assigns"): out.push(PVar("assigns")); default: out.push(a); }
        return out;
    }

    static function containsHSigilAny(node: ElixirAST):Bool {
        var found = false;
        inline function isIdentChar(c:String):Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= '0'.code && ch <= '9'.code) || (ch >= 'A'.code && ch <= 'Z'.code) || (ch >= 'a'.code && ch <= 'z'.code) || c == "_";
        }
        function walk(n: ElixirAST):Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case ESigil(t, _, _) if (t == "H"): found = true;
                case ERemoteCall(mod, funcName, _):
                    if (funcName == "sigil_H") { found = true; }
                    walk(mod);
                case ERaw(code):
                    if (code != null) {
                        var i = code.indexOf("~H");
                        if (i != -1) {
                            // basic token boundary: previous char not letter and next is letter/quote start
                            var before = i > 0 ? code.substr(i - 1, 1) : null;
                            var after = i + 2 < code.length ? code.substr(i + 2, 1) : null;
                            if (!isIdentChar(before)) { found = true; }
                        }
                    }
                case EBlock(es): for (e in es) walk(e);
                case EIf(c, t, e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(e, cs): walk(e); for (cl in cs) walk(cl.body);
                case EDo(b): for (e in b) walk(e);
                case EParen(inner): walk(inner);
                case ECall(t, _, as): if (t != null) walk(t); for (a in as) walk(a);
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
