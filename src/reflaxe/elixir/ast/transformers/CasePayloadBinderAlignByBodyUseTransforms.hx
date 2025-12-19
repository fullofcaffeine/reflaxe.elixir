package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * CasePayloadBinderAlignByBodyUseTransforms
 *
 * WHAT
 * - Late, usage-driven harmonization for two-tuple case patterns like {:tag, binder}.
 *   Renames the payload binder to the clause's sole undefined local used in the body.
 *
 * WHY
 * - Nested switch patterns often retain generic binders (value/_value) while the body uses
 *   a meaningful name (todo/id/message). Earlier passes may miss this when function-wide
 *   defined sets include names from nested patterns. This pass operates per clause, late
 *   in the pipeline, and uses only clause-local declarations to decide renames.
 *
 * HOW
 * - For each ECase clause:
 *   1) Match {:<atom>, PVar(binder)}
 *   2) Build clause-defined set from pattern vars + LHS binds inside the body
 *   3) Collect used simple lower-case names in the body
 *   4) Compute undefined = used − defined − {binder} − {socket/live_socket}
 *   5) If undefined.length == 1 AND the original binder is not referenced in the clause body,
 *      rename the binder to that undefined name. This is safe because renaming an unused binder
 *      cannot change semantics and avoids introducing binder/body mismatches.
 *
 * NOTE
 * - This pass intentionally does not rewrite clause bodies. Renaming a used binder without
 *   rewriting references is incorrect. When binders are used, the builder should emit the
 *   correct binder name (or other dedicated transforms should prefix-bind/alias safely).
 */
class CasePayloadBinderAlignByBodyUseTransforms {
    static function prefer(names:Array<String>): Null<String> {
        if (names == null || names.length == 0) return null;
        var order = ["todo", "id", "message", "params", "reason"];
        for (p in order) for (n in names) if (n == p) return n;
        return null;
    }
    public static function alignPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var outer = collectParamVars(args);
                    var newBody = alignInBody(body, outer);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var outer = collectParamVars(args);
                    var newBody = alignInBody(body, outer);
                    makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
                case ECase(target, clauses):
                    // DISABLED: trace('[CasePayloadAlign] Visiting ECase with ' + clauses.length + ' clause(s)');
                    var out = [];
                    for (cl in clauses) {
                        var payloadBinder = extractTagPayloadBinder(cl.pattern);
                        if (payloadBinder != null) {
                            // DISABLED: trace('[CasePayloadAlign] Found {:tag, ' + payloadBinder + '}');
                            var defined = new Map<String,Bool>();
                            collectPatternDecls(cl.pattern, defined);
                            collectLhsDeclsInBody(cl.body, defined);
                            // No outer function context at this ECase level
                            var used = collectUsedLowerNames(cl.body);
                            #if debug_transforms
                            // DEBUG: Sys.println('[CasePayloadAlign] body=' + ElixirASTPrinter.print(cl.body, 0));
                            #end
                            // candidates: unique undefined, excluding common env names
                            var cands:Array<String> = [];
                            for (u in used.keys()) if (u != payloadBinder && allow(u) && !defined.exists(u)) cands.push(u);
                            // DISABLED: trace('[CasePayloadAlign] candidates = ' + cands.join(','));
                            var chosen:Null<String> = null;
                            if (cands.length > 1) {
                                chosen = prefer(cands);
                                if (chosen != null) cands = [chosen];
                            }
                            if (cands.length == 1) {
                                var newName = cands[0];
                                var newPat = rewriteTagPayloadBinder(cl.pattern, newName);
                                if (newPat != cl.pattern) {
                                    // Only rename when the original binder is *not* referenced in this clause.
                                    // Renaming a used binder without rewriting body refs would be incorrect.
                                    if (!clauseUsesVar(cl.body, payloadBinder) && (cl.guard == null || !clauseUsesVar(cl.guard, payloadBinder))) {
                                        out.push({ pattern: newPat, guard: cl.guard, body: cl.body });
                                        continue;
                                    }
                                }
                            }
                        }
                        out.push(cl);
                    }
                    makeASTWithMeta(ECase(target, out), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function alignInBody(body: ElixirAST, outerDefined: Map<String,Bool>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(target, clauses):
                    var out = [];
                    for (cl in clauses) {
                        var payloadBinder = extractTagPayloadBinder(cl.pattern);
                        if (payloadBinder != null) {
                            var defined = new Map<String,Bool>();
                            collectPatternDecls(cl.pattern, defined);
                            collectLhsDeclsInBody(cl.body, defined);
                            if (outerDefined != null) for (k in outerDefined.keys()) defined.set(k, true);
                            var used = collectUsedLowerNames(cl.body);
                            var cands:Array<String> = [];
                            for (u in used.keys()) if (u != payloadBinder && allow(u) && !defined.exists(u)) cands.push(u);
                            if (cands.length == 1) {
                                var newName = cands[0];
                                var newPat = rewriteTagPayloadBinder(cl.pattern, newName);
                                if (newPat != cl.pattern) {
                                    if (!clauseUsesVar(cl.body, payloadBinder) && (cl.guard == null || !clauseUsesVar(cl.guard, payloadBinder))) {
                                        out.push({ pattern: newPat, guard: cl.guard, body: cl.body });
                                        continue;
                                    }
                                }
                            }
                        }
                        out.push(cl);
                    }
                    makeASTWithMeta(ECase(target, out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function allow(name:String):Bool {
        if (name == null || name.length == 0) return false;
        if (name == "socket" || name == "live_socket" || name == "liveSocket") return false;
        var c = name.charAt(0);
        return c.toLowerCase() == c;
    }

    static function replaceVar(body: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
                default: x;
            }
        });
    }

    static function collectLhsDeclsInBody(body: ElixirAST, vars: Map<String,Bool>): Void {
        ASTUtils.walk(body, function(x: ElixirAST) {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case EMatch(p, _): collectPatternDecls(p, vars);
                case EBinary(Match, l, _): collectLhsDecls(l, vars);
                case ECase(_, cs): for (c in cs) collectPatternDecls(c.pattern, vars);
                default:
            }
        });
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

    static function collectLhsDecls(lhs: ElixirAST, vars: Map<String,Bool>): Void {
        switch (lhs.def) {
            case EVar(n): vars.set(n, true);
            case EBinary(Match, l2, r2): collectLhsDecls(l2, vars); collectLhsDecls(r2, vars);
            default:
        }
    }

    static function collectUsedLowerNames(ast: ElixirAST): Map<String,Bool> {
        var names = new Map<String,Bool>();

        // Prefer metadata supplied by the builder (TypedExpr-derived)
        var arr = ast.metadata.usedLocalsFromTyped;
        if (arr != null) {
            for (n in arr) if (n != null && n.length > 0 && allow(n)) names.set(n, true);
        }

        // Also traverse the Elixir AST for any EVar occurrences
        ASTUtils.walk(ast, function(x: ElixirAST) {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case EVar(v):
                    var c = v.charAt(0);
                    if (c.toLowerCase() == c && allow(v)) names.set(v, true);
                case EString(s):
                    // Capture #{name} occurrences inside string interpolation
                    if (s != null && s.indexOf("#{") != -1) {
                        #if debug_transforms
                        #end
                        var block = new EReg("\\#\\{([^}]*)\\}", "g");
                        var pos = 0;
                        while (block.matchSub(s, pos)) {
                            var inner = block.matched(1);
                            // Extract all identifier-like tokens from within the interpolation
                            var tok = new EReg("[a-z_][a-z0-9_]*", "gi");
                            var tpos = 0;
                            while (tok.matchSub(inner, tpos)) {
                                var id = tok.matched(0);
                                if (allow(id)) names.set(id, true);
                                tpos = tok.matchedPos().pos + tok.matchedPos().len;
                            }
                            pos = block.matchedPos().pos + block.matchedPos().len;
                        }
                    }
                default:
            }
        });
        // Fallback: scan printed body text for interpolation identifiers
        if (!names.iterator().hasNext()) {
            try {
                var printed = ElixirASTPrinter.print(ast, 0);
                var block = new EReg("\\#\\{([^}]*)\\}", "g");
                var pos = 0;
                while (block.matchSub(printed, pos)) {
                    var inner = block.matched(1);
                    var tok = new EReg("[a-z_][a-z0-9_]*", "gi");
                    var tpos = 0;
                    while (tok.matchSub(inner, tpos)) {
                        var id = tok.matched(0);
                        if (allow(id)) names.set(id, true);
                        tpos = tok.matchedPos().pos + tok.matchedPos().len;
                    }
                    pos = block.matchedPos().pos + block.matchedPos().len;
                }
            } catch (e) {}
        }

        return names;
    }

    static function collectParamVars(args: Array<EPattern>): Map<String,Bool> {
        var out = new Map<String,Bool>();
        if (args == null) return out;
        for (a in args) collectPatternDecls(a, out);
        return out;
    }

    static function findFirstMeaningfulVar(ast: ElixirAST, exclude:haxe.ds.StringMap<Bool>): Null<String> {
        var chosen:Null<String> = null;
        ASTUtils.walk(ast, function(x: ElixirAST) {
            if (chosen != null || x == null || x.def == null) return;
            switch (x.def) {
                case EVar(v):
                    if (allow(v) && !exclude.exists(v)) chosen = v;
        default:
            }
        });
        return chosen;
    }

    static function clauseUsesVar(ast: ElixirAST, name: String): Bool {
        if (ast == null || name == null || name.length == 0) return false;
        var found = false;
        ASTUtils.walk(ast, function(n: ElixirAST) {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case EVar(v) if (v == name):
                    found = true;
                default:
            }
        });
        return found;
    }

    static function extractTagPayloadBinder(p: EPattern): Null<String> {
        return switch (p) {
            case PTuple(es) if (es.length == 2):
                switch (es[0]) {
                    case PLiteral(l):
                        // first must be an atom literal; guard does not inspect atom value
                        switch (es[1]) { case PVar(n): n; default: null; }
                    default: null;
                }
            default: null;
        }
    }

    static function rewriteTagPayloadBinder(p: EPattern, newName:String): EPattern {
        return switch (p) {
            case PTuple(es) if (es.length == 2):
                switch (es[0]) {
                    case PLiteral(l):
                        switch (es[1]) { case PVar(_): PTuple([es[0], PVar(newName)]); default: p; }
                    default: p;
                }
            default: p;
        }
    }
}

#end
