package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DefParamUsedBaseNamePromotionFinalTransforms
 *
 * WHAT
 * - Absolute-final pass: if a function parameter is underscored (e.g., `_socket`)
 *   but the body references the base name (`socket`), promote the parameter to
 *   the base name to ensure the binder exists and avoid undefined-variable errors.
 *
 * WHY
 * - Conservative underscore passes may incorrectly mark parameters as unused in
 *   Web contexts. If the body clearly uses the base name, the parameter must
 *   match that binder.
 *
 * HOW
 * - For every def/defp, scan params; for each `PVar(name)` starting with `_`,
 *   let `base = name.substr(1)`. If the body contains `EVar(base)`, rename the
 *   parameter binder to `base`.
 */
class DefParamUsedBaseNamePromotionFinalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var changed = false;
                    var newArgs = if (args != null) args.copy() else null;
                    if (newArgs != null) {
                        for (i in 0...newArgs.length) switch (newArgs[i]) {
                            case PVar(pn) if (pn != null && pn.length > 1 && pn.charAt(0) == '_'):
                                var base = pn.substr(1);
                                var hit = containsVar(body, base);
#if debug_final_promotion
                                Sys.println('[FinalPromotion][scan] def ' + name + ' param ' + pn + ' base=' + base + ' used=' + hit);
#end
                                if (hit) { newArgs[i] = PVar(base); changed = true; }
                            default:
                        }
                    }
#if debug_final_promotion
                    if (changed) {
                        Sys.println('[FinalPromotion] Renamed underscored param(s) in def ' + name);
                    }
#end
                    changed ? makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos) : n;
                case EDefp(name2, args2, guards2, body2):
                    var changed2 = false;
                    var newArgs2 = if (args2 != null) args2.copy() else null;
                    if (newArgs2 != null) {
                        for (i in 0...newArgs2.length) switch (newArgs2[i]) {
                            case PVar(pn2) if (pn2 != null && pn2.length > 1 && pn2.charAt(0) == '_'):
                                var base2 = pn2.substr(1);
                                if (containsVar(body2, base2)) { newArgs2[i] = PVar(base2); changed2 = true; }
                            default:
                        }
                    }
#if debug_final_promotion
                    if (changed2) {
                        Sys.println('[FinalPromotion] Renamed underscored param(s) in defp ' + name2);
                    }
#end
                    changed2 ? makeASTWithMeta(EDefp(name2, newArgs2, guards2, body2), n.metadata, n.pos) : n;
                default:
                    n;
            }
        });
    }

    static function containsVar(body: ElixirAST, name: String): Bool {
        if (name == null || name.length == 0) return false;
        var found = false;
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= '0'.code && ch <= '9'.code)
                || (ch >= 'A'.code && ch <= 'Z'.code)
                || (ch >= 'a'.code && ch <= 'z'.code)
                || c == "_" || c == ".";
        }
        function walk(x: ElixirAST) {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EVar(v) if (v == name): found = true;
                case ERaw(code):
                    if (code != null && name.charAt(0) != '_') {
                        var start = 0;
                        while (!found) {
                            var i = code.indexOf(name, start);
                            if (i == -1) break;
                            var before = i > 0 ? code.substr(i - 1, 1) : null;
                            var afterIdx = i + name.length;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            if (!isIdentChar(before) && !isIdentChar(after)) { found = true; break; }
                            start = i + name.length;
                        }
                    }
                    if (!found && x.metadata != null) {
                        var provided:Array<String> = cast Reflect.field(x.metadata, "rawVarRefs");
                        if (provided != null) for (v in provided) if (v == name) { found = true; break; }
                    }
                case EBinary(_, l, r): walk(l); walk(r);
                case EMatch(_, rhs): walk(rhs);
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case EUnary(_, expr): walk(expr);
                case ECase(e2, cs): walk(e2); for (c in cs) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(cls, doBlock, elseBlock): for (wc in cls) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(tg, _, as): if (tg != null) walk(tg); if (as != null) for (a in as) walk(a);
                case ERemoteCall(tg2, _, as2): walk(tg2); if (as2 != null) for (a2 in as2) walk(a2);
                case EField(obj,_): walk(obj);
                case EAccess(obj2,key): walk(obj2); walk(key);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(body); return found;
    }
}

#end
