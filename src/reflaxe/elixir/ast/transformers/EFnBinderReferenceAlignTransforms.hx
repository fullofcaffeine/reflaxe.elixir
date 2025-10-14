package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnBinderReferenceAlignTransforms
 *
 * WHAT
 * - Ensures anonymous function (EFn) binder names and body references are aligned:
 *   replaces EVar("_" + name) with EVar(name) when a corresponding binder `name`
 *   exists in the clause args. Also normalizes binder PVar/PAlias names by
 *   trimming the leading underscore if the body references the trimmed variant.
 *
 * WHY
 * - Late-stage hygiene/cleanup passes can leave bodies referencing underscored
 *   variants (e.g., `_elem`) while the binder is non-underscored (`elem`), causing
 *   undefined variable errors or "underscored variable used" warnings. This pass
 *   aligns references to match the declared binder names.
 *
 * HOW
 * - For each EFn clause:
 *   1) Collect binder names (base = trim leading underscore).
 *   2) If body references the trimmed variant, normalize binder to trimmed form.
 *   3) Rewrite EVar("_" + base) occurrences in the body to EVar(base).
 * - ERaw nodes are untouched.
 *
 * EXAMPLES
 * Before:
 *   Enum.reduce(items, [], fn elem, acc -> Enum.concat(acc, [render(_elem)]) end)
 * After:
 *   Enum.concat(acc, [render(elem)])
 */
class EFnBinderReferenceAlignTransforms {
    public static function fixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        // Collect binder bases and current names
                        var binders:Array<{orig:String, base:String, pat:EPattern}> = [];
                        var used = collectUsedVars(cl.body);
                        var newArgs:Array<EPattern> = [];
                        for (a in cl.args) {
                            switch (a) {
                                case PVar(name):
                                    var base = (name != null && name.length > 1 && name.charAt(0) == '_') ? name.substr(1) : name;
                                    var newName = name;
                                    // If body references either base or _base, normalize binder to base
                                    if (base != null && (used.exists(base) || used.exists('_' + base))) newName = base;
                                    binders.push({orig: name, base: base, pat: PVar(newName)});
                                    newArgs.push(PVar(newName));
                                case PAlias(name, pat):
                                    var base2 = (name != null && name.length > 1 && name.charAt(0) == '_') ? name.substr(1) : name;
                                    var newName2 = name;
                                    if (base2 != null && (used.exists(base2) || used.exists('_' + base2))) newName2 = base2;
                                    binders.push({orig: name, base: base2, pat: PAlias(newName2, pat)});
                                    newArgs.push(PAlias(newName2, pat));
                                default:
                                    newArgs.push(a);
                            }
                        }
                        // Rewrite underscored body refs _base -> base when base is a binder
                        var newBody = cl.body;
                        for (b in binders) {
                            var underscored = (b.base != null && b.base.length > 0) ? ("_" + b.base) : null;
                            if (underscored != null) {
                                newBody = renameVarInNode(newBody, underscored, b.base);
                            }
                        }
                        // Also fix ERaw tokens: replace _base with base with token boundaries
                        newBody = renameUnderscoredTokensInERaw(newBody, [for (b in binders) b.base]);
                        newClauses.push({args: newArgs, guard: cl.guard, body: newBody});
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function collectUsedVars(node: ElixirAST): Map<String, Bool> {
        var used = new Map<String, Bool>();
        function visit(e: ElixirAST): Void {
            if (e == null || e.def == null) return;
            switch (e.def) {
                case EVar(name): used.set(name, true);
                case EField(target, _): visit(target);
                case EBlock(stmts): for (s in stmts) visit(s);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case ECase(expr, clauses): visit(expr); for (c in clauses) { if (c.guard != null) visit(c.guard); visit(c.body); }
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(tgt2, _, args2): visit(tgt2); for (a2 in args2) visit(a2);
                case EList(els): for (el in els) visit(el);
                case ETuple(els): for (el in els) visit(el);
                case EMap(pairs): for (p in pairs) { visit(p.key); visit(p.value); }
                case EKeywordList(pairs): for (p in pairs) visit(p.value);
                case EStructUpdate(base, fields): visit(base); for (f in fields) visit(f.value);
                case EFn(clauses): for (cl in clauses) visit(cl.body);
                default:
            }
        }
        visit(node);
        return used;
    }

    static function renameVarInNode(node: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(name) if (name == from): makeASTWithMeta(EVar(to), n.metadata, n.pos);
                case ERaw(_): n; // do not touch raw strings/HEEx
                default: n;
            }
        });
    }

    static function renameUnderscoredTokensInERaw(node: ElixirAST, bases: Array<String>): ElixirAST {
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= '0'.code && ch <= '9'.code) || (ch >= 'A'.code && ch <= 'Z'.code) || (ch >= 'a'.code && ch <= 'z'.code) || c == "_" || c == ".";
        }
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERaw(code):
                    if (code == null || bases == null || bases.length == 0) return n;
                    var out = code;
                    for (b in bases) {
                        if (b == null || b.length == 0) continue;
                        var needle = "_" + b;
                        var start = 0;
                        var sb = new StringBuf();
                        var changed = false;
                        while (start < out.length) {
                            var i = out.indexOf(needle, start);
                            if (i == -1) {
                                sb.add(out.substr(start));
                                break;
                            }
                            var before = i > 0 ? out.substr(i - 1, 1) : null;
                            var afterIdx = i + needle.length;
                            var after = afterIdx < out.length ? out.substr(afterIdx, 1) : null;
                            if (!isIdentChar(before) && !isIdentChar(after)) {
                                // boundary-ok replacement
                                sb.add(out.substr(start, i - start));
                                sb.add(b);
                                start = i + needle.length;
                                changed = true;
                            } else {
                                // not a standalone token; keep and continue
                                sb.add(out.substr(start, (i - start) + 1));
                                start = i + 1;
                            }
                        }
                        if (changed) out = sb.toString();
                    }
                    // Only update ERaw if actual change happened
                    if (out != code) makeASTWithMeta(ERaw(out), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }
}

#end
