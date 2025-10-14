package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * GettextArityAndParamRepairTransforms
 *
 * WHAT
 * - For modules ending with ".Gettext":
 *   1) Add arity-1 wrappers for gettext/2 and arity-2 for dgettext/3, arity-3 for ngettext/4 and dngettext/5
 *      to accept calls without the optional bindings map.
 *   2) Repair parameters that were underscored despite being used in the body (e.g., `_count` → `count`).
 *
 * WHY
 * - Generated code may define only the arity that includes bindings; Phoenix code often calls
 *   arity without bindings. Param underscore passes may also incorrectly underscore used params.
 *
 * HOW
 * - Detect EModule/EDefmodule with name ending in ".Gettext". For each body function:
 *   - Record existing function names and arities.
 *   - If gettext/2 exists and gettext/1 missing, insert wrapper calling gettext/2 with %{}.
 *   - Similar for dgettext/3→/2, ngettext/4→/3, dngettext/5→/4.
 *   - For each defp/def, rename `_name` pattern binder to `name` when the body references `name`.
 */
class GettextArityAndParamRepairTransforms {
    static inline function endsWithGettext(name:String):Bool {
        return name != null && StringTools.endsWith(name, ".Gettext");
    }

    static function bodyUsesName(body:ElixirAST, name:String):Bool {
        var found = false;
        if (name == null || name.length == 0) return false;
        ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
            if (found) return n;
            switch (n.def) {
                case EVar(v) if (v == name): found = true; return n;
                case ERaw(code):
                    if (code != null && code.indexOf(name) != -1) {
                        // Basic token-boundary check
                        var i = 0; inline function isIdent(c:String):Bool {
                            if (c == null || c.length == 0) return false;
                            var ch = c.charCodeAt(0);
                            return (ch >= '0'.code && ch <= '9'.code) || (ch >= 'A'.code && ch <= 'Z'.code) || (ch >= 'a'.code && ch <= 'z'.code) || c == "_";
                        }
                        while (true) {
                            var idx = code.indexOf(name, i); if (idx == -1) break;
                            var before = idx > 0 ? code.substr(idx - 1, 1) : null;
                            var afterIdx = idx + name.length;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            if (!isIdent(before) && !isIdent(after)) { found = true; break; }
                            i = idx + name.length;
                        }
                    }
                    return n;
                default: return n;
            }
        });
        return found;
    }

    static function repairParams(args:Array<EPattern>, body:ElixirAST):Array<EPattern> {
        if (args == null) return args;
        return [for (a in args) switch (a) {
            case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_' && bodyUsesName(body, nm.substr(1))): PVar(nm.substr(1));
            default: a;
        }];
    }

    static function functionSigSet(body:Array<ElixirAST>):Map<String, Map<Int,Bool>> {
        var map = new Map<String, Map<Int,Bool>>();
        for (b in body) switch (b.def) {
            case EDef(nm, args, _, _):
                var m = map.exists(nm) ? map.get(nm) : new Map<Int,Bool>();
                m.set(args != null ? args.length : 0, true); map.set(nm, m);
            case EDefp(nm2, args2, _, _):
                var m2 = map.exists(nm2) ? map.get(nm2) : new Map<Int,Bool>();
                m2.set(args2 != null ? args2.length : 0, true); map.set(nm2, m2);
            default:
        }
        return map;
    }

    static function insertArityShims(body:Array<ElixirAST>):Array<ElixirAST> {
        var sigs = functionSigSet(body);
        var out = body.copy();
        inline function has(name:String, ar:Int):Bool { return sigs.exists(name) && sigs.get(name).exists(ar); }
        // gettext
        if (has("gettext", 2) && !has("gettext", 1)) {
            out.unshift(makeAST(EDef("gettext", [PVar("msgid")], null, makeAST(ECall(null, "gettext", [makeAST(EVar("msgid")), makeAST(EMap([]))])))));
        }
        // dgettext
        if (has("dgettext", 3) && !has("dgettext", 2)) {
            out.unshift(makeAST(EDef("dgettext", [PVar("domain"), PVar("msgid")], null, makeAST(ECall(null, "dgettext", [makeAST(EVar("domain")), makeAST(EVar("msgid")), makeAST(EMap([]))])))));
        }
        // ngettext
        if (has("ngettext", 4) && !has("ngettext", 3)) {
            out.unshift(makeAST(EDef("ngettext", [PVar("msgid"), PVar("msgid_plural"), PVar("count")], null, makeAST(ECall(null, "ngettext", [makeAST(EVar("msgid")), makeAST(EVar("msgid_plural")), makeAST(EVar("count")), makeAST(EMap([]))])))));
        }
        // dngettext
        if (has("dngettext", 5) && !has("dngettext", 4)) {
            out.unshift(makeAST(EDef("dngettext", [PVar("domain"), PVar("msgid"), PVar("msgid_plural"), PVar("count")], null, makeAST(ECall(null, "dngettext", [makeAST(EVar("domain")), makeAST(EVar("msgid")), makeAST(EVar("msgid_plural")), makeAST(EVar("count")), makeAST(EMap([]))])))));
        }
        return out;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (endsWithGettext(name)):
                    var repaired = [for (b in body) switch (b.def) {
                        case EDef(nm, args, guards, bd):
                            var newArgs = repairParams(args, bd);
                            var newBody = (nm == "error" && newArgs != null && newArgs.length == 2) ?
                                (function() {
                                    // Rewrite gettext(msgid) -> gettext(msgid, %{}) inside error/2
                                    return ElixirASTTransformer.transformNode(bd, function(x:ElixirAST):ElixirAST {
                                        return switch (x.def) {
                                            case ECall(null, fn, callArgs) if (fn == "gettext" && callArgs != null && callArgs.length == 1):
                                                makeAST(ERemoteCall(makeAST(EVar(name)), "gettext", [callArgs[0], makeAST(EMap([]))]));
                                            default: x;
                                        }
                                    });
                                })() : bd;
                            makeAST(EDef(nm, newArgs, guards, newBody));
                        case EDefp(nm2, args2, guards2, bd2): makeAST(EDefp(nm2, repairParams(args2, bd2), guards2, bd2));
                        default: b;
                    }];
                    var withShims = insertArityShims(repaired);
                    makeASTWithMeta(EModule(name, attrs, withShims), n.metadata, n.pos);
                case EDefmodule(name2, doBlock) if (endsWithGettext(name2)):
                    var stmts:Array<ElixirAST> = switch (doBlock.def) { case EBlock(ss): ss; case EDo(ss2): ss2; default: [doBlock]; };
                    var repaired2 = [for (b in stmts) switch (b.def) {
                        case EDef(nm, args, guards, bd):
                            var newArgs = repairParams(args, bd);
                            var newBody = (nm == "error" && newArgs != null && newArgs.length == 2) ?
                                (function() {
                                    return ElixirASTTransformer.transformNode(bd, function(x:ElixirAST):ElixirAST {
                                        return switch (x.def) {
                                            case ECall(null, fn, callArgs) if (fn == "gettext" && callArgs != null && callArgs.length == 1):
                                                makeAST(ERemoteCall(makeAST(EVar(name2)), "gettext", [callArgs[0], makeAST(EMap([]))]));
                                            default: x;
                                        }
                                    });
                                })() : bd;
                            makeAST(EDef(nm, newArgs, guards, newBody));
                        case EDefp(nm2, args2, guards2, bd2): makeAST(EDefp(nm2, repairParams(args2, bd2), guards2, bd2));
                        default: b;
                    }];
                    var withShims2 = insertArityShims(repaired2);
                    var newDo: ElixirAST = switch (doBlock.def) {
                        case EBlock(_): makeASTWithMeta(EBlock(withShims2), doBlock.metadata, doBlock.pos);
                        case EDo(_): makeASTWithMeta(EDo(withShims2), doBlock.metadata, doBlock.pos);
                        default: doBlock;
                    };
                    makeASTWithMeta(EDefmodule(name2, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end
