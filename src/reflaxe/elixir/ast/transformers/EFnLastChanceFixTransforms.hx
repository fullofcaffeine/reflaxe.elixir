package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnLastChanceFixTransforms
 *
 * WHAT
 * - Absolute last-chance repair for anonymous function binder/body alignment
 *   in simple, single-argument EFns. Ensures `_binder` references are rewritten
 *   to `binder` and, when exactly one other free variable name is used in the
 *   body, rewrites it to the binder (shape-based, no app coupling).
 *
 * WHY
 * - Some earlier/later passes can still emit EFn bodies referencing `_elem` or
 *   `todo` while binder is `elem`. This pass conservatively repairs those to
 *   avoid undefined variables and preserve idiomatic Enum.* patterns.
 *
 * HOW
 * - For each EFn clause with a single PVar binder `b`:
 *   1) Rename EVar("_" + b) -> EVar(b) inside body.
 *   2) Collect body variable names (shallow, includes nested) and remove b and _b.
 *   3) If exactly one remaining lower_snake identifier exists and contains no dots,
 *      rewrite that free var to `b`.
 */
class EFnLastChanceFixTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var binderOrig: Null<String> = null;
                        if (cl.args != null && cl.args.length == 1) switch (cl.args[0]) {
                            case PVar(name): binderOrig = name;
                            default:
                        }
                        if (binderOrig == null) {
                            newClauses.push(cl);
                            continue;
                        }
                        // Normalize binder to base if underscored
                        var binderBase = (binderOrig.length > 1 && binderOrig.charAt(0) == '_') ? binderOrig.substr(1) : binderOrig;
                        var outArg:EPattern = PVar(binderBase);
                        var b = binderBase;
                        var newBody = renameVarInNode(cl.body, '_' + b, b);
                        #if debug_last_chance
                        trace('[EFnLastChance] binder=' + b + ' applied _' + b + ' -> ' + b);
                        #end
                        var used = collectUsedVars(newBody);
                        used.remove(b);
                        used.remove('_' + b);
                        // If there is exactly one underscored free var (e.g., _elem), rewrite it to binder
                        var unders:Array<String> = [];
                        for (k in used.keys()) if (k != null && k.length > 1 && k.charAt(0) == '_' && looksLikeVar(k.substr(1))) unders.push(k);
                        if (unders.length == 1) {
                            var uv = unders[0];
                            newBody = renameVarInNode(newBody, uv, b);
                            #if debug_last_chance
                            trace('[EFnLastChance] Rewriting underscored free var ' + uv + ' -> ' + b);
                            #end
                            used = collectUsedVars(newBody);
                            used.remove(b);
                            used.remove('_' + b);
                        }
                        // Prefer victim that is used as field receiver
                        var victims:Array<String> = [];
                        for (k in used.keys()) if (looksLikeVar(k)) victims.push(k);
                        var recvVictims = [];
                        for (v in victims) if (varUsedAsFieldReceiver(newBody, v)) recvVictims.push(v);
                        if (recvVictims.length == 1) {
                            var victim = recvVictims[0];
                            newBody = renameVarInNode(newBody, victim, b);
                            #if debug_last_chance
                            trace('[EFnLastChance] Rewriting field-receiver var ' + victim + ' -> ' + b);
                            #end
                        } else if (victims.length == 1) {
                            var victim2 = victims[0];
                            newBody = renameVarInNode(newBody, victim2, b);
                            #if debug_last_chance
                            trace('[EFnLastChance] Rewriting single free var ' + victim2 + ' -> ' + b);
                            #end
                        }
                        newClauses.push({args: [outArg], guard: cl.guard, body: newBody});
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function looksLikeVar(name:String):Bool {
        if (name == null || name.length == 0) return false;
        var c = name.charAt(0);
        if (c == '_' || c.toLowerCase() != c) return false;
        return name.indexOf('.') == -1;
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

    static function varUsedAsFieldReceiver(node: ElixirAST, varName: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case EField(target, _):
                    switch (target.def) {
                        case EVar(v) if (v == varName): found = true;
                        default: walk(target);
                    }
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, cls): walk(expr); for (cl in cls) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base, fs): walk(base); for (f in fs) walk(f.value);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(node);
        return found;
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
}

#end
