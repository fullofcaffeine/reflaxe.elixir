package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LiveMountNormalizeTransforms
 *
 * WHAT
 * - Normalizes common LiveView mount/3 flows to ensure required binders are present
 *   and properly assigned:
 *   - Promote wildcard assignments to named binders when names are used later
 *   - Bind `updated_socket` to Phoenix.Component.assign/2 when returned
 *   - Replace undeclared first arg in assign/2 with `socket`
 *
 * WHY
 * - Late hygiene passes can discard binders that are required later in mount (e.g.,
 *   `now`, `todos`, `assigns`, `updated_socket`), causing undefined-variable errors.
 *   This pass restores the minimal, idiomatic flow in a shape-based manner.
 */
class LiveMountNormalizeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name != null && StringTools.endsWith(name, "Live")):
                    var newBody = body.map(normalizeInNode);
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name != null && StringTools.endsWith(name, "Live")):
                    makeASTWithMeta(EDefmodule(name, normalizeInNode(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function normalizeInNode(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(e: ElixirAST): ElixirAST {
            return switch (e.def) {
                case EDef(fname, args, guards, body) if (fname == "mount"):
                    var b = body;
                    switch (b.def) {
                        case EBlock(stmts):
                            var declared = new Map<String, Bool>();
                            // Collect declared names in this function
                            for (s in stmts) switch (s.def) {
                                case EMatch(PVar(n), _): declared.set(n, true);
                                case EBinary(Match, left, _):
                                    switch (left.def) { case EVar(n2): declared.set(n2, true); default: }
                                default:
                            }

                            // Helper: laterUses(name)
                            function laterUses(i:Int, name:String):Bool {
                                for (k in i+1...stmts.length) if (usesName(stmts[k], name)) return true; return false;
                            }

                            var out:Array<ElixirAST> = [];
                            for (i in 0...stmts.length) {
                                var s = stmts[i];
                                switch (s.def) {
                                    // Promote wildcard to `now` when used later
                                    case EMatch(PWildcard, rhs) if (laterUses(i, "now")):
                                        out.push(makeASTWithMeta(EMatch(PVar("now"), rhs), s.metadata, s.pos));
                                    // Promote wildcard to `todos` when used later
                                    case EMatch(PWildcard, rhs2) if (laterUses(i, "todos")):
                                        out.push(makeASTWithMeta(EMatch(PVar("todos"), rhs2), s.metadata, s.pos));
                                    // Promote wildcard to `assigns` when used later
                                    case EMatch(PWildcard, rhs3) if (laterUses(i, "assigns")):
                                        out.push(makeASTWithMeta(EMatch(PVar("assigns"), rhs3), s.metadata, s.pos));
                                    // EBinary variant: _ = rhs → name = rhs
                                    case EBinary(Match, left, rhs4):
                                        var isWild = switch (left.def) {
                                            case EVar(vn) if (vn == "_"): true;
                                            case EUnderscore: true;
                                            default: false;
                                        };
                                        if (isWild && laterUses(i, "now")) {
                                            out.push(makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar("now")), rhs4), s.metadata, s.pos));
                                        } else if (isWild && laterUses(i, "todos")) {
                                            out.push(makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar("todos")), rhs4), s.metadata, s.pos));
                                        } else if (isWild && laterUses(i, "assigns")) {
                                            out.push(makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar("assigns")), rhs4), s.metadata, s.pos));
                                        } else if (isWild && laterUses(i, "presence_socket")) {
                                            out.push(makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar("presence_socket")), rhs4), s.metadata, s.pos));
                                        } else {
                                            out.push(s);
                                        }
                                    default:
                                        out.push(s);
                                }
                            }

                            // Second pass: ensure updated_socket assignment present and first arg is socket when undeclared
                            for (i in 0...out.length) switch (out[i].def) {
                                case ERemoteCall({def: EVar(mod)}, "assign", [firstArg, secArg]) if (mod == "Phoenix.Component"):
                                    var firstVar: Null<String> = switch (firstArg.def) { case EVar(v): v; default: null; };
                                    if (firstVar != null && !declared.exists(firstVar)) {
                                        firstArg = makeAST(ElixirASTDef.EVar("socket"));
                                    }
                                    // Find later return {:ok, updated_socket}
                                    var needsBinding = false;
                                    for (k in i+1...out.length) switch (out[k].def) {
                                        case ETuple(elems) if (elems.length == 2):
                                            var okAtom = switch (elems[0].def) { case EAtom(a): true; default: false; };
                                            var isUpd = switch (elems[1].def) { case EVar(vn) if (vn == "updated_socket"): true; default: false; };
                                            if (okAtom && isUpd) needsBinding = true;
                                        default:
                                    }
                                    if (needsBinding && !declared.exists("updated_socket")) {
                                        // updated_socket = Phoenix.Component.assign(...)
                                        out[i] = makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar("updated_socket")), makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [firstArg, secArg]))), out[i].metadata, out[i].pos);
                                        declared.set("updated_socket", true);
                                    } else {
                                        out[i] = makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [firstArg, secArg]), out[i].metadata, out[i].pos);
                                    }
                                default:
                            }
                            return makeASTWithMeta(EDef(fname, args, guards, makeAST(EBlock(out))), e.metadata, e.pos);
                        default:
                            return e;
                    }
                default:
                    e;
            }
        });
    }

    static function usesName(n: ElixirAST, name: String): Bool {
        var found = false;
        function walk(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EVar(v) if (v == name): found = true;
                case EBlock(ss): for (s in ss) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case EBinary(_, l, r): walk(l); walk(r);
                case EMatch(_, rhs): walk(rhs);
                case ECall(tgt, _, args): if (tgt != null) walk(tgt); for (a in args) walk(a);
                case ERemoteCall(tgt2, _, args2): walk(tgt2); for (a2 in args2) walk(a2);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EStructUpdate(base, fields): walk(base); for (f in fields) walk(f.value);
                case ETuple(elems): for (e in elems) walk(e);
                case EString(str):
                    if (str != null) {
                        var i = 0;
                        while (!found && i < str.length) {
                            var idx = str.indexOf("#{", i);
                            if (idx == -1) break;
                            var j = str.indexOf('}', idx + 2);
                            if (j == -1) break;
                            var inner = str.substr(idx + 2, j - (idx + 2));
                            if (inner != null && inner.indexOf(name) != -1) { found = true; break; }
                            i = j + 1;
                        }
                    }
                case ERaw(code):
                    if (code != null && code.indexOf(name) != -1) found = true;
                default:
            }
        }
        walk(n);
        return found;
    }
}

#end
