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
        inline function addName(raw:String):Void {
            if (raw == null || raw.length == 0) return;
            function addOnce(s:String) {
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
        switch (n.def) {
            case EVar(v): addName(v);
            case ERaw(code): if (code != null) for (t in tokenize(code)) addName(t);
            case EString(str): if (str != null) for (t in tokenizeInterpolations(str)) addName(t);
            case EBinary(_, l, r): collectVars(l, out); collectVars(r, out);
            case EMatch(pat, rhs): collectVars(rhs, out); collectPattern(pat, out);
            case EBlock(stmts): for (s in stmts) collectVars(s, out);
            case EDo(stmts): for (s in stmts) collectVars(s, out);
            case EIf(c,t,e): collectVars(c, out); collectVars(t, out); if (e != null) collectVars(e, out);
            case EUnless(c,t,e): collectVars(c,out); collectVars(t,out); if (e!=null) collectVars(e,out);
            case ECase(expr, clauses):
                collectVars(expr, out);
                for (c in clauses) { if (c.guard != null) collectVars(c.guard, out); collectVars(c.body, out); collectPattern(c.pattern, out); }
            case EWith(clauses, doBlock, elseBlock):
                for (wc in clauses) { collectVars(wc.expr, out); collectPattern(wc.pattern, out); }
                collectVars(doBlock, out); if (elseBlock != null) collectVars(elseBlock, out);
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
            case EPipe(l,r): collectVars(l,out); collectVars(r,out);
            case EFor(gens, filters, body, into, _uniq):
                for (g in gens) { collectVars(g.expr, out); collectPattern(g.pattern, out); }
                for (f in filters) collectVars(f, out);
                if (body != null) collectVars(body, out);
                if (into != null) collectVars(into, out);
            case ECapture(expr, _): collectVars(expr, out);
            default:
        }
    }

    static function collectPattern(pat:ElixirAST.EPattern, out:Map<String,Bool>):Void {
        if (pat == null) return;
        switch (pat) {
            case PVar(v): addNameInner(out, v);
            case PTuple(ps):
                for (p in ps) collectPattern(p, out);
            case PStruct(_, fields):
                for (f in fields) collectPattern(f.value, out);
            case PMap(pairs):
                for (p in pairs) collectPattern(p.value, out);
            case PCons(h, t):
                collectPattern(h, out); collectPattern(t, out);
            case PList(elems):
                for (p in elems) collectPattern(p, out);
            default:
        }
    }

    static inline function addNameInner(out:Map<String,Bool>, n:String):Void {
        if (n == null || n.length == 0) return;
        if (!out.exists(n)) out.set(n, true);
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
        var buf = new StringBuf();
        inline function flush() {
            if (buf.length > 0) {
                out.push(buf.toString());
                buf = new StringBuf();
            }
        }
        for (i in 0...code.length) {
            var ch = code.charAt(i);
            if ((ch >= "A" && ch <= "Z") || (ch >= "a" && ch <= "z") || (ch >= "0" && ch <= "9") || ch == "_") {
                buf.add(ch);
            } else {
                flush();
            }
        }
        flush();
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
