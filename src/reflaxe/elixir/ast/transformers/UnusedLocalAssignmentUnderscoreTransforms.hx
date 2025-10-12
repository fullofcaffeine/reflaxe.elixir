package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * UnusedLocalAssignmentUnderscoreTransforms
 *
 * WHAT
 * - In block contexts, rename local assignment binders to underscore-prefixed
 *   when the variable is never referenced in the block.
 * - Example: filtered_todos = Enum.reduce_while(...) when filtered_todos unused
 *   becomes _filtered_todos = ...
 *
 * WHY
 * - Silence warnings-as-errors in LiveView render helpers without changing logic.
 *
 * HOW
 * - For EBlock([...]) compute a global set of referenced variable names.
 * - Rewrite EMatch(PVar(name), rhs) where name not in referenced set and
 *   does not already start with underscore, to PVar("_" + name).
 */
class UnusedLocalAssignmentUnderscoreTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        // Only apply inside LiveView modules (<App>Web.*Live)
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name != null && name.indexOf("Live") != -1):
                    var newBody = body.map(applyToBlocks);
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name != null && name.indexOf("Live") != -1):
                    makeASTWithMeta(EDefmodule(name, applyToBlocks(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function applyToBlocks(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var refs = collectRefs(stmts);
                    // Also mark names that appear in ERaw strings
                    markNamesInRaw(stmts, refs);
                    var out = [];
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        switch (s.def) {
                            case EMatch(PVar(name), rhs) if (shouldRenameFuture(name, refs, stmts, i)):
                                out.push(makeASTWithMeta(EMatch(PVar('_' + name), rhs), s.metadata, s.pos));
                            default:
                                out.push(s);
                        }
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function collectRefs(stmts: Array<ElixirAST>): Map<String, Bool> {
        var refs = new Map<String, Bool>();
        function visit(e: ElixirAST): Void {
            if (e == null || e.def == null) return;
            switch (e.def) {
                case EVar(name): refs.set(name, true);
                case EBlock(ss): for (s in ss) visit(s);
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
        for (s in stmts) visit(s);
        return refs;
    }

    static function markNamesInRaw(stmts: Array<ElixirAST>, refs: Map<String, Bool>): Void {
        function collectCandidates(ss: Array<ElixirAST>): Array<String> {
            var names = new Map<String, Bool>();
            function visit(e: ElixirAST): Void {
                if (e == null || e.def == null) return;
                switch (e.def) {
                    case EMatch(PVar(n), _): names.set(n, true);
                    case EBlock(bs): for (b in bs) visit(b);
                    default:
                }
            }
            for (s in ss) visit(s);
            var out: Array<String> = [];
            for (k in names.keys()) out.push(k);
            return out;
        }
        var candidates = collectCandidates(stmts);
        function scanRaw(e: ElixirAST): Void {
            if (e == null || e.def == null) return;
            switch (e.def) {
                case ERaw(code):
                    for (n in candidates) {
                        if (!refs.exists(n) && code != null && code.indexOf(n) != -1) refs.set(n, true);
                    }
                case EBlock(bs): for (b in bs) scanRaw(b);
                case EIf(c,t,el): scanRaw(c); scanRaw(t); if (el != null) scanRaw(el);
                case ECase(expr, cs): scanRaw(expr); for (c in cs) { if (c.guard != null) scanRaw(c.guard); scanRaw(c.body); }
                case EBinary(_, l, r): scanRaw(l); scanRaw(r);
                case EMatch(_, rhs): scanRaw(rhs);
                case ECall(tgt, _, args): if (tgt != null) scanRaw(tgt); for (a in args) scanRaw(a);
                case ERemoteCall(tgt2, _, args2): scanRaw(tgt2); for (a2 in args2) scanRaw(a2);
                default:
            }
        }
        for (s in stmts) scanRaw(s);
    }

    static inline function shouldRename(name: String, refs: Map<String, Bool>): Bool {
        if (name == null || name.length == 0) return false;
        if (name.charAt(0) == '_') return false;
        // Do not rename common LiveView binders used later
        if (name == "assigns" || StringTools.endsWith(name, "_socket") || StringTools.startsWith(name, "current_") || StringTools.startsWith(name, "complete_")) return false;
        return !refs.exists(name);
    }

    static function shouldRenameFuture(name: String, refs: Map<String, Bool>, stmts: Array<ElixirAST>, idx: Int): Bool {
        if (!shouldRename(name, refs)) return false;
        // Only rename if not referenced in any subsequent statement
        for (j in idx+1...stmts.length) if (statementUsesName(stmts[j], name)) return false;
        return true;
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
        visit(s);
        return found;
    }
}

#end
