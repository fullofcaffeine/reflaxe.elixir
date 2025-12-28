package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnLocalAssignDiscardTransforms
 *
 * WHAT
 * - Inside anonymous function bodies, replace local assignments `name = expr` with
 *   `_ = expr` when `name` is not referenced later in the same function body.
 *
 * WHY
 * - Prevent unused local variable warnings from closure-local rebinds that don't affect
 *   outer scope (common in lowered list-building patterns).

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class EFnLocalAssignDiscardTransforms {
    public static function discardPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        // Phase 1: collect assigned names and used names in the whole clause body
                        var assigned = new Map<String,Bool>();
                        var used = new Map<String,Bool>();
                        collectAssignedAndUsed(cl.body, assigned, used);
                        var dead = new Map<String,Bool>();
                        for (k in assigned.keys()) if (!used.exists(k)) dead.set(k, true);
                        // Phase 2a: rewrite dead assignments globally
                        var body1 = rewriteDeadAssignments(cl.body, dead);
                        // Phase 2b: within blocks, discard assignments whose name is not used later in the block
                        var newBody = discardPerBlockUnusedAssignments(body1);
                        newClauses.push({args: cl.args, guard: cl.guard, body: newBody});
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function collectAssignedAndUsed(n:ElixirAST, assigned:Map<String,Bool>, used:Map<String,Bool>):Void {
        if (n == null || n.def == null) return;
        switch (n.def) {
            case EBinary(Match, left, rhs):
                switch (left.def) {
                    case EVar(name): assigned.set(name, true);
                    default:
                }
                collectAssignedAndUsed(rhs, assigned, used);
            case EMatch(_, rhs): collectAssignedAndUsed(rhs, assigned, used);
            case EVar(name): used.set(name, true);
            case EBlock(stmts): for (s in stmts) collectAssignedAndUsed(s, assigned, used);
            case EDo(stmts2): for (s2 in stmts2) collectAssignedAndUsed(s2, assigned, used);
            case EIf(c,t,e): collectAssignedAndUsed(c, assigned, used); collectAssignedAndUsed(t, assigned, used); if (e != null) collectAssignedAndUsed(e, assigned, used);
            case ECase(expr, cs): collectAssignedAndUsed(expr, assigned, used); for (c in cs) collectAssignedAndUsed(c.body, assigned, used);
            case ECall(tgt, _, args): if (tgt != null) collectAssignedAndUsed(tgt, assigned, used); for (a in args) collectAssignedAndUsed(a, assigned, used);
            case ERemoteCall(t2, _, args2): collectAssignedAndUsed(t2, assigned, used); for (a in args2) collectAssignedAndUsed(a, assigned, used);
            case EBinary(_, l, r): collectAssignedAndUsed(l, assigned, used); collectAssignedAndUsed(r, assigned, used);
            case EField(t, _): collectAssignedAndUsed(t, assigned, used);
            case EMap(pairs): for (p in pairs) { collectAssignedAndUsed(p.key, assigned, used); collectAssignedAndUsed(p.value, assigned, used); }
            case EString(str):
                // Mark variables referenced in string interpolation as used
                var i = 0;
                while (str != null && i < str.length) {
                    var idx = str.indexOf("#{", i);
                    if (idx == -1) break;
                    var j = str.indexOf("}", idx + 2);
                    if (j == -1) break;
                    var inner = str.substr(idx + 2, j - (idx + 2));
                    // crude parse: split on non-identifier characters
                    var vars = inner.split(" ");
                    for (v in vars) if (v != null && v.length > 0) used.set(v, true);
                    i = j + 1;
                }
            default:
        }
    }

    static function rewriteDeadAssignments(n:ElixirAST, dead:Map<String,Bool>):ElixirAST {
        return ElixirASTTransformer.transformNode(n, function(x:ElixirAST):ElixirAST {
            return switch (x.def) {
                case EBinary(Match, left, rhs):
                    switch (left.def) {
                        case EVar(name) if (dead.exists(name) && name != null && name.length > 0 && name.charAt(0) == '_'):
                            // SAFETY: Do not discard accumulator initializations (e.g., g = [])
                            // These are often used by subsequent concatenations in nested list-building
                            // patterns and turning them into `_ = []` yields invalid code later.
                            switch (rhs.def) {
                                case EList(_): x; // keep as-is
                                default:
                                    makeASTWithMeta(EMatch(PWildcard, rhs), x.metadata, x.pos);
                            }
                        default: x;
                    }
                default: x;
            }
        });
    }

    static function discardPerBlockUnusedAssignments(n:ElixirAST):ElixirAST {
        return ElixirASTTransformer.transformNode(n, function(x:ElixirAST):ElixirAST {
            return switch (x.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        var replaced = false;
                        switch (s.def) {
                            case EBinary(Match, left, rhs):
                                switch (left.def) {
                                    case EVar(name):
                                        if (!nameUsedLater(stmts, i+1, name)) {
                                            // SAFETY: Preserve accumulator initializations (rhs list literals)
                                            switch (rhs.def) {
                                                case EList(_): // keep as-is
                                                default:
                                                    out.push(makeASTWithMeta(EMatch(PWildcard, rhs), s.metadata, s.pos));
                                                    replaced = true;
                                            }
                                        }
                                    default:
                                }
                            default:
                        }
                        if (!replaced) out.push(s);
                    }
                    makeASTWithMeta(EBlock(out), x.metadata, x.pos);
                case EDo(stmts2):
                    var out2:Array<ElixirAST> = [];
                    for (i in 0...stmts2.length) {
                        var s2 = stmts2[i];
                        var replaced2 = false;
                        switch (s2.def) {
                            case EBinary(Match, left2, rhs2):
                                switch (left2.def) {
                                    case EVar(name2):
                                        if ((name2 != null && name2.length > 0 && name2.charAt(0) == '_') && !nameUsedLater(stmts2, i+1, name2)) {
                                            out2.push(makeASTWithMeta(EMatch(PWildcard, rhs2), s2.metadata, s2.pos));
                                            replaced2 = true;
                                        }
                                    default:
                                }
                            default:
                        }
                        if (!replaced2) out2.push(s2);
                    }
                    makeASTWithMeta(EDo(out2), x.metadata, x.pos);
                default: x;
            }
        });
    }

    static function nameUsedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (k in start...stmts.length) if (statementUsesName(stmts[k], name)) return true;
        return false;
    }

    static function statementUsesName(s: ElixirAST, name: String): Bool {
        var found = false;
        function visit(e: ElixirAST): Void {
            if (found || e == null || e.def == null) return;
            switch (e.def) {
                case EVar(n) if (n == name): found = true;
                case EBlock(ss): for (x in ss) visit(x);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case ECase(expr, cs): visit(expr); for (c in cs) { if (c.guard != null) visit(c.guard); visit(c.body);} 
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(tgt2, _, args2): visit(tgt2); for (a in args2) visit(a);
                case EList(els): for (el in els) visit(el);
                case ETuple(els): for (el in els) visit(el);
                case EMap(pairs): for (p in pairs) { visit(p.key); visit(p.value); }
                case EKeywordList(pairs): for (p in pairs) visit(p.value);
                case EStructUpdate(base, fields): visit(base); for (f in fields) visit(f.value);
                case EFn(clauses): for (cl in clauses) visit(cl.body);
                case EString(str):
                    var k = 0;
                    while (!found && str != null && k < str.length) {
                        var idx2 = str.indexOf("#{", k);
                        if (idx2 == -1) break;
                        var j2 = str.indexOf("}", idx2 + 2);
                        if (j2 == -1) break;
                        var inner = str.substr(idx2 + 2, j2 - (idx2 + 2));
                        if (inner.indexOf(name) != -1) { found = true; break; }
                        k = j2 + 1;
                    }
                default:
            }
        }
        visit(s);
        return found;
    }
}

#end
