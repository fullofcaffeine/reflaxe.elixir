package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseUnderscoreBinderPromoteByUseTransforms
 *
 * WHAT
 * - In ECase clauses, promote binders that start with underscore (e.g., _reason)
 *   to their trimmed variant (reason) when the trimmed name is used in the clause body
 *   and there is no conflicting binder named "reason" in the pattern.
 *
 * WHY
 * - Prevents undefined-variable errors where body interpolations or references use
 *   the non-underscored name while the pattern binds only the underscored variant.
 */
class CaseUnderscoreBinderPromoteByUseTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(expr, clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var used = collectUsedRefs(cl.body);
                        var binders = collectPatternBinders(cl.pattern);
                        var patNames = new Map<String,Bool>();
                        for (b in binders) patNames.set(b, true);
                        // Try usage-driven rename for underscored second binder in tuples with additional fields.
                        var rewritten = usageDrivenRenameSecondBinder(cl.pattern, used, patNames);
                        var newPat = promoteBinders(rewritten, used, patNames);
                        newClauses.push({pattern: newPat, guard: cl.guard, body: cl.body});
                    }
                    makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
                default: n;
            }
        });
    }

    static function collectUsedRefs(body: ElixirAST): Map<String,Bool> {
        var used = new Map<String,Bool>();
        function visit(e: ElixirAST): Void {
            if (e == null || e.def == null) return;
            switch (e.def) {
                case EVar(name): used.set(name, true);
                case EString(v):
                    if (v != null) markInterpolations(v, used);
                case ERaw(code):
                    if (code != null) markInterpolations(code, used);
                case EField(t, _): visit(t);
                case EBlock(ss): for (s in ss) visit(s);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(t2, _, args2): visit(t2); for (a in args2) visit(a);
                case ECase(expr, cs): visit(expr); for (c in cs) visit(c.body);
                default:
            }
        }
        visit(body);
        return used;
    }

    static inline function toSnake(s:String):String {
        if (s == null || s.length == 0) return s;
        var buf = new StringBuf();
        for (i in 0...s.length) {
            var c = s.substr(i, 1);
            var lower = c.toLowerCase();
            var upper = c.toUpperCase();
            if (c == upper && c != lower) {
                if (i != 0) buf.add("_");
                buf.add(lower);
            } else {
                buf.add(c);
            }
        }
        return buf.toString();
    }

    // If pattern is a tuple with at least two elements and the second element is an underscored
    // variable, and the clause body uses exactly one undefined local name U (lowercase), rename the
    // binder to snake(U). This is shape-based and avoids tag/name heuristics.
    static function usageDrivenRenameSecondBinder(p:EPattern, used:Map<String,Bool>, patNames:Map<String,Bool>):EPattern {
        return switch (p) {
            case PTuple(es) if (es.length >= 2):
                var changed = false;
                var es2 = es.copy();
                // Try to rename the second element if it's an underscored PVar
                // Only for common tagged tuples like {:ok, v} or {:error, v, ctx}
                var firstIsTag = switch (es2[0]) { case PLiteral(_): true; default: false; };
                switch (es2[1]) {
                    case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
                        if (firstIsTag) {
                            var undefined:Array<String> = [];
                            for (k in used.keys()) if (!patNames.exists(k) && k.charAt(0).toLowerCase() == k.charAt(0)) undefined.push(k);
                            undefined = undefined.filter(k -> k != "socket" && !StringTools.endsWith(k, "socket") && !StringTools.endsWith(k, "Socket"));
                            if (undefined.length == 1) {
                                var target = toSnake(undefined[0]);
                                // Avoid collision with an existing pattern name
                                if (!patNames.exists(target)) { es2[1] = PVar(target); changed = true; }
                            }
                        }
                    default:
                        // Do not recurse on the second element to avoid accidental renames
                        es2[1] = es2[1];
                }
                PTuple(es2);
            case PList(items): PList([for (e in items) usageDrivenRenameSecondBinder(e, used, patNames)]);
            case PCons(h, t): PCons(usageDrivenRenameSecondBinder(h, used, patNames), usageDrivenRenameSecondBinder(t, used, patNames));
            case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: usageDrivenRenameSecondBinder(kv.value, used, patNames) }]);
            case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: usageDrivenRenameSecondBinder(f.value, used, patNames) }]);
            case PPin(inner): PPin(usageDrivenRenameSecondBinder(inner, used, patNames));
            default: p;
        }
    }

    static function markInterpolations(s:String, used:Map<String,Bool>):Void {
        // Heuristic: collect words following "#{" up to non-identifier
        var i = 0;
        while (true) {
            var idx = s.indexOf("#{", i);
            if (idx == -1) break;
            var j = idx + 2;
            var name = "";
            while (j < s.length) {
                var ch = s.charAt(j);
                var cc = ch.charCodeAt(0);
                var isIdent = (cc >= 'a'.code && cc <= 'z'.code) || (cc >= 'A'.code && cc <= 'Z'.code) || (cc >= '0'.code && cc <= '9'.code) || cc == '_'.code;
                if (!isIdent) break;
                name += ch; j++;
            }
            if (name != null && name.length > 0) {
                var k = j;
                while (k < s.length && StringTools.isSpace(s, k)) k++;
                var isCall = (k < s.length && s.charAt(k) == '(');
                if (!isCall) used.set(name, true);
            }
            i = j + 1;
        }
    }

    static function collectPatternBinders(p: EPattern): Array<String> {
        var out: Array<String> = [];
        function walk(px: EPattern) {
            switch (px) {
                case PVar(n): out.push(n);
                case PTuple(es): for (e in es) walk(e);
                case PList(es): for (e in es) walk(e);
                case PCons(h, t): walk(h); walk(t);
                case PMap(kvs): for (kv in kvs) walk(kv.value);
                case PStruct(_, fs): for (f in fs) walk(f.value);
                case PPin(inner): walk(inner);
                case PAlias(nm, pat): out.push(nm); walk(pat);
                default:
            }
        }
        walk(p);
        return out;
    }

    static function promoteBinders(p: EPattern, used: Map<String,Bool>, patNames: Map<String,Bool>): EPattern {
        return switch (p) {
            case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
                var trimmed = n.substr(1);
                if (used.exists(trimmed) && !patNames.exists(trimmed)) PVar(trimmed) else p;
            case PAlias(nm, pat) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
                var trimmed2 = nm.substr(1);
                if (used.exists(trimmed2) && !patNames.exists(trimmed2)) PAlias(trimmed2, promoteBinders(pat, used, patNames)) else PAlias(nm, promoteBinders(pat, used, patNames));
            case PTuple(es): PTuple(es.map(e -> promoteBinders(e, used, patNames)));
            case PList(es): PList(es.map(e -> promoteBinders(e, used, patNames)));
            case PCons(h, t): PCons(promoteBinders(h, used, patNames), promoteBinders(t, used, patNames));
            case PMap(kvs): PMap(kvs.map(kv -> { key: kv.key, value: promoteBinders(kv.value, used, patNames) }));
            case PStruct(nm, fs): PStruct(nm, fs.map(f -> { key: f.key, value: promoteBinders(f.value, used, patNames) }));
            case PPin(inner): PPin(promoteBinders(inner, used, patNames));
            default: p;
        }
    }
}

#end
