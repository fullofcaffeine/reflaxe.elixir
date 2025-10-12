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
 * - Scoped to <App>Web.*Live modules; ERaw substrings are scanned to prevent
 *   false-positive renames when names appear inside template fragments.
 *
 * EXAMPLES
 * Before (in <App>Web.TodoLive):
 *   filtered = Enum.reduce_while(todos, {[]}, fn todo, {acc} -> {:cont, {acc ++ [todo]}} end)
 *   assigns = assign(assigns, :filtered, filtered)
 * After (when `filtered` is never referenced later):
 *   _filtered = Enum.reduce_while(todos, {[]}, fn todo, {acc} -> {:cont, {acc ++ [todo]}} end)
 *   assigns = assign(assigns, :filtered, _filtered)
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
                    // Precompute for ERaw-aware future checks
                    var out = [];
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        // Helper to decide rename based on future usage (AST + ERaw)
                        function futureUses(name:String):Bool {
                            if (name == null || name.length == 0) return false;
                            for (j in i+1...stmts.length) if (statementUsesName(stmts[j], name) || statementContainsNameInRaw(stmts[j], name)) return true;
                            return false;
                        }
                        function canRename(name:String):Bool {
                            if (name == null || name.length == 0) return false;
                            if (name.charAt(0) == '_') return false;
                            if (name == "assigns" || StringTools.endsWith(name, "_socket") || StringTools.startsWith(name, "current_") || StringTools.startsWith(name, "complete_")) return false;
                            return !futureUses(name);
                        }
                        switch (s.def) {
                            case EMatch(pattern, rhs):
                                var newPat = underscoreUnusedInPattern(pattern, canRename);
                                if (newPat == pattern) {
                                    out.push(s);
                                } else {
                                    out.push(makeASTWithMeta(EMatch(newPat, rhs), s.metadata, s.pos));
                                }
                            case EBinary(Match, left, rhs):
                                // If LHS is a local never used later, convert to `_ = rhs` to avoid WAE
                                switch (left.def) {
                                    case EVar(n) if (canRename(n)):
                                        out.push(makeASTWithMeta(EMatch(PWildcard, rhs), s.metadata, s.pos));
                                    default:
                                        out.push(s);
                                }
                            default:
                                out.push(s);
                        }
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                case EDo(stmts):
                    var block = makeAST(EBlock(stmts));
                    var transformed = applyToBlocks(block);
                    switch (transformed.def) {
                        case EBlock(xs): makeASTWithMeta(EDo(xs), n.metadata, n.pos);
                        default: n;
                    }
                case EIf(cond, thenBr, elseBr):
                    // Handle unused assignment in then-branch: if cond, do: var = expr
                    var newThen = thenBr;
                    switch (thenBr.def) {
                        case EBinary(Match, left, rhs):
                            switch (left.def) {
                                case EVar(n):
                                    // In absence of parent context, conservatively underscore
                                    newThen = makeASTWithMeta(EMatch(PWildcard, rhs), thenBr.metadata, thenBr.pos);
                                default:
                            }
                        default:
                    }
                    makeASTWithMeta(EIf(cond, newThen, elseBr), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function statementContainsNameInRaw(s: ElixirAST, name: String): Bool {
        var found = false;
        function visit(e: ElixirAST): Void {
            if (found || e == null || e.def == null) return;
            switch (e.def) {
                case ERaw(code): if (code != null && code.indexOf(name) != -1) found = true;
                case EBlock(ss): for (x in ss) visit(x);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case ECase(expr, cs): visit(expr); for (c in cs) { if (c.guard != null) visit(c.guard); visit(c.body);} 
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(tgt2, _, args2): visit(tgt2); for (a2 in args2) visit(a2);
                default:
            }
        }
        visit(s);
        return found;
    }

    static function underscoreUnusedInPattern(p: EPattern, canRename: String->Bool): EPattern {
        return switch (p) {
            case PVar(name): canRename(name) ? PVar('_' + name) : p;
            case PTuple(els): PTuple(els.map(e -> underscoreUnusedInPattern(e, canRename)));
            case PList(els): PList(els.map(e -> underscoreUnusedInPattern(e, canRename)));
            case PCons(h, t): PCons(underscoreUnusedInPattern(h, canRename), underscoreUnusedInPattern(t, canRename));
            case PMap(pairs): PMap(pairs.map(pa -> { key: pa.key, value: underscoreUnusedInPattern(pa.value, canRename) }));
            case PStruct(m, fields): PStruct(m, fields.map(f -> { key: f.key, value: underscoreUnusedInPattern(f.value, canRename) }));
            case PAlias(name, pat):
                var newName = canRename(name) ? '_' + name : name;
                PAlias(newName, underscoreUnusedInPattern(pat, canRename));
            case PPin(inner): PPin(underscoreUnusedInPattern(inner, canRename));
            case PBinary(segs): PBinary(segs.map(s -> { pattern: underscoreUnusedInPattern(s.pattern, canRename), size: s.size, type: s.type, modifiers: s.modifiers }));
            case PWildcard | PLiteral(_): p;
        }
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
