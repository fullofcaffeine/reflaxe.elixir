package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControllerLocalUnusedUnderscoreTransforms
 *
 * WHAT
 * - In Phoenix Controller modules, underscore local assignment binders that are
 *   not referenced later in the same function body. This silences warnings like
 *   "variable \"data\" is unused", without changing behavior.
 *
 * SCOPE
 * - Modules detected as Controllers by metadata (AnnotationTransforms) or by
 *   module name ending in "Controller" under Web namespace.
 */
class ControllerLocalUnusedUnderscoreTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (isControllerModule(n, name)):
                    var out:Array<ElixirAST> = [];
                    for (b in body) out.push(applyToDefs(b));
                    makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
                case EDefmodule(modName, doBlock) if (isControllerDoBlock(n, doBlock)):
                    makeASTWithMeta(EDefmodule(modName, applyToDefs(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function applyToDefs(node:ElixirAST):ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, underscoreUnused(body)), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2):
                    makeASTWithMeta(EDefp(name2, args2, guards2, underscoreUnused(body2)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function underscoreUnused(body:ElixirAST):ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    var s1 = switch (s.def) {
                        case EMatch(PVar(b), rhs) if (!usedLater(stmts, i+1, b)):
                            makeASTWithMeta(EMatch(PVar('_' + b), rhs), s.metadata, s.pos);
                        case EBinary(Match, left, right):
                            switch (left.def) {
                                case EVar(b2) if (!usedLater(stmts, i+1, b2)):
                                    makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b2)), right), s.metadata, s.pos);
                                default: s;
                            }
                        case ECase(expr, clauses):
                            var newClauses = [];
                            for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: underscoreUnused(cl.body) });
                            makeASTWithMeta(ECase(expr, newClauses), s.metadata, s.pos);
                        default:
                            s;
                    };
                    out.push(s1);
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            case EDo(stmts2):
                var out2:Array<ElixirAST> = [];
                for (i in 0...stmts2.length) {
                    var s = stmts2[i];
                    var s1 = switch (s.def) {
                        case EMatch(PVar(b), rhs) if (!usedLater(stmts2, i+1, b)):
                            makeASTWithMeta(EMatch(PVar('_' + b), rhs), s.metadata, s.pos);
                        case EBinary(Match, left, right):
                            switch (left.def) {
                                case EVar(b2) if (!usedLater(stmts2, i+1, b2)):
                                    makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b2)), right), s.metadata, s.pos);
                                default: s;
                            }
                        case ECase(expr, clauses):
                            var newClauses = [];
                            for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: underscoreUnused(cl.body) });
                            makeASTWithMeta(ECase(expr, newClauses), s.metadata, s.pos);
                        default:
                            s;
                    };
                    out2.push(s1);
                }
                makeASTWithMeta(EDo(out2), body.metadata, body.pos);
            default:
                body;
        }
    }

    static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
        var found = false;
        function scan(n: ElixirAST, inLhs:Bool = false): Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case EVar(v) if (v == name && !inLhs): found = true;
                case EBinary(Match, l, r):
                    // Do not treat occurrences on LHS as a "use" (it's a binder)
                    scan(l, true); scan(r, false);
                case EMatch(pat, rhs):
                    // skip scanning pattern entirely; only consider RHS for usages
                    scan(rhs, false);
                case EBlock(ss): for (s in ss) scan(s);
                case EDo(ss2): for (s in ss2) scan(s);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case ECase(expr, clauses):
                    scan(expr, false);
                    for (cl in clauses) { if (cl.guard != null) scan(cl.guard, false); scan(cl.body, false); }
                case EWith(clauses, doBlock, elseBlock):
                    for (wc in clauses) scan(wc.expr, false);
                    scan(doBlock, false);
                    if (elseBlock != null) scan(elseBlock, false);
                case ECall(t,_,as): if (t != null) scan(t, false); if (as != null) for (a in as) scan(a, false);
                case ERemoteCall(t2,_,as2): scan(t2, false); if (as2 != null) for (a2 in as2) scan(a2, false);
                case EField(obj,_): scan(obj, false);
                case EAccess(obj2,key): scan(obj2, false); scan(key, false);
                case EKeywordList(pairs): for (p in pairs) scan(p.value, false);
                case EMap(pairs): for (p in pairs) { scan(p.key, false); scan(p.value, false); }
                case EStructUpdate(base, fs): scan(base, false); for (f in fs) scan(f.value, false);
                case ETuple(es) | EList(es): for (e in es) scan(e, false);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) scan(cl.guard, false); scan(cl.body, false); }
                default:
            }
        }
        for (j in start...stmts.length) if (!found) scan(stmts[j], false);
        return found;
    }

    static inline function isControllerModule(node:ElixirAST, name:String):Bool {
        if (node.metadata?.isPhoenixWeb == true && node.metadata?.phoenixContext == PhoenixContext.Controller) return true;
        return name != null && name.indexOf("Web.") >= 0 && StringTools.endsWith(name, "Controller");
    }

    static inline function isControllerDoBlock(node:ElixirAST, doBlock:ElixirAST):Bool {
        // Rely on bubbled metadata when available
        return node.metadata?.phoenixContext == PhoenixContext.Controller;
    }
}

#end
