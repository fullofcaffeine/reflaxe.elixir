package reflaxe.elixir.ast.analyzers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
 * OptimizedVarUseAnalyzer
 *
 * WHAT
 * - Single-pass suffix usage index for statement lists to answer
 *   `usedLater(stmts, idx, name)` in O(1) after an O(N) build.
 *
 * WHY
 * - Hygiene passes repeatedly call VarUseAnalyzer.usedLater/stmtUsesVar, causing
 *   quadratic behaviour on large modules. Centralizing a cached suffix map
 *   keeps semantics while reducing cost.
 *
 * HOW
 * - build(stmts) walks the statement list once from the end, accumulating a
 *   map of variable names (and canonical variants) seen at-or-after each index.
 * - usedLater(index, startIdx, name) checks membership in the prebuilt suffix map.
 * - stmtUsesVar delegates to VarUseAnalyzer for per-node checks when needed.
 *
 * NOTES
 * - Variable collection is conservative: it tokenizes ERaw and string
 *   interpolations to avoid missing uses; adds underscore/base/camel/snake
 *   variants so callers that pass either form still match.
 */
typedef OptimizedUsageIndex = {
    var suffix:Array<Map<String,Bool>>;
}

class OptimizedVarUseAnalyzer {

    public static function build(stmts:Array<ElixirAST>):OptimizedUsageIndex {
        var suffix:Array<Map<String,Bool>> = [];
        if (stmts == null) {
            suffix.push(new Map());
            return { suffix: suffix };
        }
        // suffix[len] = empty set sentinel
        suffix[stmts.length] = new Map<String,Bool>();
        var i = stmts.length - 1;
        while (i >= 0) {
            var nextMap = suffix[i + 1];
            var current = new Map<String,Bool>();
            for (k in nextMap.keys()) current.set(k, true);
            collectVars(stmts[i], current);
            suffix[i] = current;
            i--;
        }
        return { suffix: suffix };
    }

    /**
     * buildExact
     *
     * WHAT
     * - Build a suffix usage index like `build/1`, but only tracks *exact* variable
     *   names (no underscore/base/camel/snake variants).
     *
     * WHY
     * - Some hygiene passes must distinguish between `name` and `_name` to avoid
     *   suppressing legitimate warnings or missing real uses.
     */
    public static function buildExact(stmts: Array<ElixirAST>): OptimizedUsageIndex {
        var suffix:Array<Map<String,Bool>> = [];
        if (stmts == null) {
            suffix.push(new Map());
            return { suffix: suffix };
        }
        suffix[stmts.length] = new Map<String,Bool>();
        var i = stmts.length - 1;
        while (i >= 0) {
            var nextMap = suffix[i + 1];
            var current = new Map<String,Bool>();
            for (k in nextMap.keys()) current.set(k, true);
            collectVarsExact(stmts[i], current);
            suffix[i] = current;
            i--;
        }
        return { suffix: suffix };
    }

    public static inline function usedLater(idx:OptimizedUsageIndex, startIdx:Int, name:String):Bool {
        if (idx == null || idx.suffix == null || name == null || name.length == 0) return false;
        var pos = startIdx;
        if (pos < 0) pos = 0;
        if (pos >= idx.suffix.length) return false;
        return idx.suffix[pos].exists(name);
    }

    public static inline function stmtUsesVar(n:ElixirAST, name:String):Bool {
        return VarUseAnalyzer.stmtUsesVar(n, name);
    }

    // --- helpers ---

    static function collectVars(n:ElixirAST, out:Map<String,Bool>):Void {
        if (n == null || n.def == null) return;
        switch (n.def) {
            case EVar(v): addName(out, v);
            case ERaw(code): if (code != null) for (t in tokenize(code)) addName(out, t);
            case EString(str): if (str != null) for (t in tokenizeInterpolations(str)) addName(out, t);
            // Match operator: LHS is a pattern binder; only RHS can reference vars.
            case EBinary(Match, _left, rhs):
                collectVars(rhs, out);
            case EBinary(_, l, r):
                collectVars(l, out);
                collectVars(r, out);
            // Match expression: pattern binds names; only RHS can reference vars (except pins).
            case EMatch(pat, rhs):
                collectVars(rhs, out);
                collectPinnedPatternUses(pat, out, false);
            case EBlock(stmts): for (s in stmts) collectVars(s, out);
            case EDo(stmts): for (s in stmts) collectVars(s, out);
            case EIf(c,t,e): collectVars(c, out); collectVars(t, out); if (e != null) collectVars(e, out);
            case EUnless(c,t,e): collectVars(c,out); collectVars(t,out); if (e!=null) collectVars(e,out);
            case ECase(expr, clauses):
                collectVars(expr, out);
                for (c in clauses) {
                    // c.pattern binds names; do not treat as a use (except pins).
                    if (c.guard != null) collectVars(c.guard, out);
                    collectVars(c.body, out);
                    collectPinnedPatternUses(c.pattern, out, false);
                }
            case EWith(clauses, doBlock, elseBlock):
                for (wc in clauses) {
                    collectVars(wc.expr, out);
                    collectPinnedPatternUses(wc.pattern, out, false);
                }
                collectVars(doBlock, out);
                if (elseBlock != null) collectVars(elseBlock, out);
            case ECall(t, _, args):
                if (t != null) collectVars(t, out);
                for (a in args) collectVars(a, out);
            case ERemoteCall(m, _, args):
                collectVars(m, out); for (a in args) collectVars(a, out);
            case EField(obj, _): collectVars(obj, out);
            case EAccess(obj, key): collectVars(obj, out); collectVars(key, out);
            case EKeywordList(pairs): for (p in pairs) collectVars(p.value, out);
            case EMap(pairs): for (p in pairs) { collectVars(p.key, out); collectVars(p.value, out); }
            case EStructUpdate(base, fields): collectVars(base, out); for (f in fields) collectVars(f.value, out);
            case ETuple(elems) | EList(elems): for (e in elems) collectVars(e, out);
            case EFn(clauses): for (cl in clauses) collectVars(cl.body, out);
            case ECond(condClauses): for (cl in condClauses) { collectVars(cl.condition, out); collectVars(cl.body, out); }
            case ERange(s,e,_): collectVars(s,out); collectVars(e,out);
            case EUnary(_, inner): collectVars(inner, out);
            case EParen(inner): collectVars(inner, out);
            case EPipe(l,r): collectVars(l,out); collectVars(r,out);
            case EFor(gens, filters, body, into, _uniq):
                for (g in gens) {
                    collectVars(g.expr, out);
                    collectPinnedPatternUses(g.pattern, out, false);
                }
                for (f in filters) collectVars(f, out);
                if (body != null) collectVars(body, out);
                if (into != null) collectVars(into, out);
            case ECapture(expr, _): collectVars(expr, out);
            default:
        }
    }

    static function addName(out: Map<String, Bool>, raw: String): Void {
        if (out == null || raw == null || raw.length == 0) return;
        inline function addOnce(s: String): Void {
            if (s != null && s.length > 0 && !out.exists(s)) out.set(s, true);
        }
        addOnce(raw);
        if (raw.charAt(0) == '_' && raw.length > 1) {
            addOnce(raw.substr(1));
        } else {
            addOnce('_' + raw);
        }
        var sn = toSnake(raw);
        addOnce(sn);
        var cc = toCamel(raw);
        addOnce(cc);
    }

    /**
     * Collect uses inside pinned patterns (`^var`) without counting binders.
     *
     * WHY
     * - `^var` in patterns references an existing binding; treating it as a binder
     *   causes false positives/negatives for `usedLater` checks.
     */
    static function collectPinnedPatternUses(pat: ElixirAST.EPattern, out: Map<String, Bool>, inPin: Bool): Void {
        if (pat == null) return;
        switch (pat) {
            case PPin(inner):
                collectPinnedPatternUses(inner, out, true);
            case PVar(v) if (inPin):
                addName(out, v);
            case PTuple(ps) | PList(ps):
                for (p in ps) collectPinnedPatternUses(p, out, inPin);
            case PCons(h, t):
                collectPinnedPatternUses(h, out, inPin);
                collectPinnedPatternUses(t, out, inPin);
            case PMap(pairs):
                for (p in pairs) collectPinnedPatternUses(p.value, out, inPin);
            case PStruct(_, fields):
                for (f in fields) collectPinnedPatternUses(f.value, out, inPin);
            case PBinary(segs):
                for (s in segs) collectPinnedPatternUses(s.pattern, out, inPin);
            case PAlias(_alias, inner):
                collectPinnedPatternUses(inner, out, inPin);
            default:
        }
    }

    static inline function addExact(out: Map<String, Bool>, raw: String): Void {
        if (out == null || raw == null || raw.length == 0) return;
        if (!out.exists(raw)) out.set(raw, true);
    }

    static function collectVarsExact(n: ElixirAST, out: Map<String, Bool>): Void {
        if (n == null || n.def == null) return;
        switch (n.def) {
            case EVar(v):
                addExact(out, v);
            case ERaw(code):
                if (code != null) for (t in tokenize(code)) addExact(out, t);
            case EString(str):
                if (str != null) for (t in tokenizeInterpolations(str)) addExact(out, t);
            case EBinary(Match, _left, rhs):
                collectVarsExact(rhs, out);
            case EBinary(_, l, r):
                collectVarsExact(l, out);
                collectVarsExact(r, out);
            case EMatch(pat, rhs):
                collectVarsExact(rhs, out);
                collectPinnedPatternUsesExact(pat, out, false);
            case EBlock(stmts):
                for (s in stmts) collectVarsExact(s, out);
            case EDo(stmts):
                for (s in stmts) collectVarsExact(s, out);
            case EIf(c, t, e):
                collectVarsExact(c, out);
                collectVarsExact(t, out);
                if (e != null) collectVarsExact(e, out);
            case EUnless(c, t, e):
                collectVarsExact(c, out);
                collectVarsExact(t, out);
                if (e != null) collectVarsExact(e, out);
            case ECase(expr, clauses):
                collectVarsExact(expr, out);
                for (c in clauses) {
                    if (c.guard != null) collectVarsExact(c.guard, out);
                    collectVarsExact(c.body, out);
                    collectPinnedPatternUsesExact(c.pattern, out, false);
                }
            case EWith(clauses, doBlock, elseBlock):
                for (wc in clauses) {
                    collectVarsExact(wc.expr, out);
                    collectPinnedPatternUsesExact(wc.pattern, out, false);
                }
                collectVarsExact(doBlock, out);
                if (elseBlock != null) collectVarsExact(elseBlock, out);
            case ECall(t, _, args):
                if (t != null) collectVarsExact(t, out);
                for (a in args) collectVarsExact(a, out);
            case ERemoteCall(m, _, args):
                collectVarsExact(m, out);
                for (a in args) collectVarsExact(a, out);
            case EField(obj, _):
                collectVarsExact(obj, out);
            case EAccess(obj, key):
                collectVarsExact(obj, out);
                collectVarsExact(key, out);
            case EKeywordList(pairs):
                for (p in pairs) collectVarsExact(p.value, out);
            case EMap(pairs):
                for (p in pairs) {
                    collectVarsExact(p.key, out);
                    collectVarsExact(p.value, out);
                }
            case EStructUpdate(base, fields):
                collectVarsExact(base, out);
                for (f in fields) collectVarsExact(f.value, out);
            case ETuple(elems) | EList(elems):
                for (e in elems) collectVarsExact(e, out);
            case EFn(clauses):
                for (cl in clauses) collectVarsExact(cl.body, out);
            case ECond(condClauses):
                for (cl in condClauses) {
                    collectVarsExact(cl.condition, out);
                    collectVarsExact(cl.body, out);
                }
            case ERange(s, e, _):
                collectVarsExact(s, out);
                collectVarsExact(e, out);
            case EUnary(_, inner):
                collectVarsExact(inner, out);
            case EParen(inner):
                collectVarsExact(inner, out);
            case EPipe(l, r):
                collectVarsExact(l, out);
                collectVarsExact(r, out);
            case EFor(gens, filters, body, into, _uniq):
                for (g in gens) {
                    collectVarsExact(g.expr, out);
                    collectPinnedPatternUsesExact(g.pattern, out, false);
                }
                for (f in filters) collectVarsExact(f, out);
                if (body != null) collectVarsExact(body, out);
                if (into != null) collectVarsExact(into, out);
            case EPin(expr):
                collectVarsExact(expr, out);
            case ECapture(expr, _):
                collectVarsExact(expr, out);
            default:
        }
    }

    static function collectPinnedPatternUsesExact(pat: ElixirAST.EPattern, out: Map<String, Bool>, inPin: Bool): Void {
        if (pat == null) return;
        switch (pat) {
            case PPin(inner):
                collectPinnedPatternUsesExact(inner, out, true);
            case PVar(v) if (inPin):
                addExact(out, v);
            case PTuple(ps) | PList(ps):
                for (p in ps) collectPinnedPatternUsesExact(p, out, inPin);
            case PCons(h, t):
                collectPinnedPatternUsesExact(h, out, inPin);
                collectPinnedPatternUsesExact(t, out, inPin);
            case PMap(pairs):
                for (p in pairs) collectPinnedPatternUsesExact(p.value, out, inPin);
            case PStruct(_, fields):
                for (f in fields) collectPinnedPatternUsesExact(f.value, out, inPin);
            case PBinary(segs):
                for (s in segs) collectPinnedPatternUsesExact(s.pattern, out, inPin);
            case PAlias(_alias, inner):
                collectPinnedPatternUsesExact(inner, out, inPin);
            default:
        }
    }

    static function tokenizeInterpolations(str:String):Array<String> {
        var tokens:Array<String> = [];
        var i = 0;
        while (i < str.length) {
            var start = str.indexOf("#{", i);
            if (start == -1) break;
            var end = str.indexOf("}", start + 2);
            if (end == -1) break;
            var inner = str.substr(start + 2, end - (start + 2));
            for (t in tokenize(inner)) tokens.push(t);
            i = end + 1;
        }
        return tokens;
    }

    static function tokenize(code:String):Array<String> {
        var out:Array<String> = [];
        if (code == null) return out;
        var start = -1;
        var i = 0;
		while (i <= code.length) {
			var ch = i < code.length ? code.charAt(i) : null;
			var isIdent = false;
			if (ch != null && ch.length > 0) {
				isIdent = (ch >= "A" && ch <= "Z") || (ch >= "a" && ch <= "z") || (ch >= "0" && ch <= "9") || ch == "_";
			}
			if (isIdent) {
				if (start == -1) start = i;
			} else if (start != -1) {
				var token = code.substr(start, i - start);
				var beforeChar = start > 0 ? code.charAt(start - 1) : "";
				var beforePrevChar = start > 1 ? code.charAt(start - 2) : "";
				var afterChar = i < code.length ? code.charAt(i) : "";
				var afterNextChar = i + 1 < code.length ? code.charAt(i + 1) : "";

				// Exclude atoms `:token` and keyword keys `token:` which are not variable uses.
				// Keep `token::spec` (bitstring specs) where the token is a real variable.
				var isAtom = (beforeChar == ":" && beforePrevChar != ":");
				var isBitstringSpec = (beforeChar == ":" && beforePrevChar == ":");
				var isKeywordKey = (afterChar == ":" && afterNextChar != ":");
				if (!isAtom && !isBitstringSpec && !isKeywordKey) out.push(token);
				start = -1;
			}
			i++;
		}
        return out;
    }

    static inline function toSnake(s:String):String {
        if (s == null) return s;
        var out = new StringBuf();
        for (i in 0...s.length) {
            var ch = s.charAt(i);
            var isUpper = (ch.toUpperCase() == ch && ch.toLowerCase() != ch);
            if (isUpper && i > 0) out.add("_");
            out.add(ch.toLowerCase());
        }
        return out.toString();
    }

    static inline function toCamel(s:String):String {
        if (s == null) return s;
        var parts = s.split("_");
        if (parts.length <= 1) return s;
        var out = new StringBuf();
        for (i in 0...parts.length) {
            var p = parts[i];
            if (p.length == 0) continue;
            if (i == 0) out.add(p); else out.add(p.charAt(0).toUpperCase() + p.substr(1));
        }
        return out.toString();
    }
}

#end
