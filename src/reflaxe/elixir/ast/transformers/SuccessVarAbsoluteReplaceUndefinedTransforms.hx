package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * SuccessVarAbsoluteReplaceUndefinedTransforms
 *
 * WHAT
 * - As a final safety net for success-clauses `{:ok, binder}`, replace any simple, lowercase
 *   undefined variable references in the clause body with the bound success `binder`.
 *
 * WHY
 * - Earlier usage-driven passes should align names; however, in complex pipelines some cases
 *   may remain. This absolute pass eliminates remaining undefined placeholder names without
 *   guessing domain-specific identifiers, keeping it shape- and scope-based.
 *
 * HOW
 * - For each case clause with pattern `{:ok, PVar(binder)}`:
 *   - Collect clause-local declared names (pattern binds, LHS assignments within the body).
 *   - Replace all `EVar(name)` where `name` is lowercase, not declared, and not an env name
 *     (socket/live_socket) with `EVar(binder)`.
 * - Runs at the absolute end of the pipeline.
 */
class SuccessVarAbsoluteReplaceUndefinedTransforms {
    public static function replacePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var newBody = process(body);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var newBody = process(body);
                    makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function process(body: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        // Respect canonical payload binder lock
                        if (isLockedPayload(cl)) { newClauses.push(cl); continue; }
                        var binder = extractOkBinder(cl.pattern);
                        if (binder != null) {
                            var declared = new Map<String,Bool>();
                            collectPatternDecls(cl.pattern, declared);
                            collectLhsDeclsInBody(cl.body, declared);
                            // Collect used simple var names in body
                            var used = new Map<String,Bool>();
                            ASTUtils.walk(cl.body, function(u: ElixirAST) {
                                switch (u.def) { case EVar(v): used.set(v, true); default: }
                            });
                            // Prefer binder promotion when body uses the trimmed name
                            if (binder.length > 1 && binder.charAt(0) == '_') {
                                var trimmed = binder.substr(1);
                                if (used.exists(trimmed) && !declared.exists(trimmed)) {
                                    var newPattern2 = rewriteOkBinder(cl.pattern, trimmed);
                                    newClauses.push({ pattern: newPattern2, guard: cl.guard, body: cl.body });
                                    continue;
                                }
                            }
                            // Otherwise, collect undefined lowercase vars
                            var undef:Array<String> = [];
                            for (k in used.keys()) if (isLower(k) && allowReplace(k) && !declared.exists(k)) undef.push(k);
                            // If binder is underscored and exactly one undefined exists, prefer renaming binder to that name
                            if (binder.length > 1 && binder.charAt(0) == '_' && undef.length == 1) {
                                var newName = undef[0];
                                var newPattern = rewriteOkBinder(cl.pattern, newName);
                                // Body already references newName; no need to map undefined refs
                                newClauses.push({ pattern: newPattern, guard: cl.guard, body: cl.body });
                                continue;
                            }
                            var undefinedSet = new Map<String,Bool>();
                            for (u in undef) undefinedSet.set(u, true);
                            var newBody = ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                                return switch (x.def) {
                                    case EVar(v) if (isLower(v) && allowReplace(v) && !declared.exists(v)):
                                        makeASTWithMeta(EVar(binder), x.metadata, x.pos);
                                    case ERaw(s) if (s != null):
                                        // Carefully replace undefined simple vars inside raw code fragments.
                                        var updated = s;
                                        for (k in undefinedSet.keys()) {
                                            var u = k;
                                            if (!allowReplace(u)) continue;
                                            // Match whole-word u not preceded by ':' (avoid atoms)
                                            var re = new EReg('(^|[^:A-Za-z0-9_])' + u + '([^A-Za-z0-9_]|$)', "g");
                                            // Haxe EReg lacks global replace with groups; do manual loop
                                            var buf = new StringBuf();
                                            var pos = 0;
                                            while (re.matchSub(updated, pos)) {
                                                var mp = re.matchedPos();
                                                var matchStr = re.matched(0);
                                                var startIdx = matchStr.indexOf(u);
                                                buf.add(updated.substr(pos, mp.pos - pos));
                                                buf.add(matchStr.substr(0, startIdx));
                                                buf.add(binder);
                                                buf.add(matchStr.substr(startIdx + u.length));
                                                pos = mp.pos + mp.len;
                                            }
                                            if (pos > 0) { buf.add(updated.substr(pos)); updated = buf.toString(); }
                                        }
                                        if (updated != s) makeASTWithMeta(ERaw(updated), x.metadata, x.pos) else x;
                                    default: x;
                                }
                            });
                            newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                            continue;
                        }
                        newClauses.push(cl);
                    }
                    makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function isLockedPayload(cl: ECaseClause): Bool {
        // If second slot is exactly _value or body flagged lock, skip
        var secondIsValue = false;
        switch (cl.pattern) {
            case PTuple(parts) if (parts.length == 2):
                switch (parts[1]) { case PVar(b) if (b == "_value"): secondIsValue = true; default: }
            default:
        }
        if (secondIsValue) return true;
        var locked = false;
        try {
            locked = untyped (cl.body != null && cl.body.metadata != null && (cl.body.metadata.lockPayloadBinder == true));
        } catch (e:Dynamic) {}
        return locked;
    }

    static function extractOkBinder(p: EPattern): Null<String> {
        return switch (p) {
            case PTuple(elements) if (elements.length == 2):
                switch (elements[0]) {
                    case PLiteral(l) if (isOkAtom(l)):
                        switch (elements[1]) { case PVar(n): n; default: null; }
                    default: null;
                }
            default: null;
        }
    }

    static inline function isOkAtom(ast: ElixirAST): Bool {
        return switch (ast.def) { case EAtom(v): v == ":ok" || v == "ok"; default: false; };
    }

    static function rewriteOkBinder(p: EPattern, newName: String): EPattern {
        return switch (p) {
            case PTuple(es) if (es.length == 2):
                switch (es[0]) {
                    case PLiteral(l) if (isOkAtom(l)):
                        switch (es[1]) {
                            case PVar(_): PTuple([es[0], PVar(newName)]);
                            default: p;
                        }
                    default: p;
                }
            default: p;
        }
    }

    static function collectPatternDecls(p: EPattern, vars: Map<String,Bool>): Void {
        switch (p) {
            case PVar(n): if (n != null && n.length > 0) vars.set(n, true);
            case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, vars);
            case PCons(h, t): collectPatternDecls(h, vars); collectPatternDecls(t, vars);
            case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, vars);
            case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, vars);
            case PPin(inner): collectPatternDecls(inner, vars);
            default:
        }
    }

    static function collectLhsDeclsInBody(body: ElixirAST, vars: Map<String,Bool>): Void {
        ASTUtils.walk(body, function(x: ElixirAST) {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case EMatch(p, _): collectPatternDecls(p, vars);
                case EBinary(Match, l, _): collectLhs(l, vars);
                case ECase(_, cs): for (c in cs) collectPatternDecls(c.pattern, vars);
                default:
            }
        });
    }

    static function collectLhs(lhs: ElixirAST, vars: Map<String,Bool>): Void {
        switch (lhs.def) { case EVar(n): vars.set(n, true); case EBinary(Match, l2, r2): collectLhs(l2, vars); collectLhs(r2, vars); default: }
    }

    static inline function isLower(s: String): Bool {
        if (s == null || s.length == 0) return false;
        var c = s.charAt(0);
        return c.toLowerCase() == c;
    }

    static inline function allowReplace(name: String): Bool {
        return name != "socket" && name != "live_socket" && name != "liveSocket";
    }
}

#end
