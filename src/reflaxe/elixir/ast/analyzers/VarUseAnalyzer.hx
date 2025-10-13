package reflaxe.elixir.ast.analyzers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * VarUseAnalyzer
 *
 * WHAT
 * - Shared variable usage analyzer for hygiene transforms. Determines if a
 *   variable is referenced within a node or later in a statement list.
 *
 * WHY
 * - Multiple passes maintained ad-hoc usage scanners with inconsistent coverage
 *   (missed EFn closures, string interpolation, ERaw, map/keyword fields, etc.).
 *   This caused discarding variables that are actually used in closures or
 *   interpolations, leading to undefined-variable errors at runtime.
 *
 * HOW
 * - Provides stmtUsesVar(node, name) and usedLater(stmts, startIdx, name).
 * - Traverses common AST constructs and scans:
 *   - EFn(clauses): walks each clause body
 *   - EString: scans "#{...}" interpolations for name occurrence
 *   - ERaw: token-boundary search to avoid substring false positives
 *   - EMap/EKeywordList/EStructUpdate/EAccess/EField/ETuple
 *   - ECase: expr and clause bodies
 */
class VarUseAnalyzer {
    public static function usedLater(stmts:Array<ElixirAST>, startIdx:Int, name:String):Bool {
        if (name == null || name.length == 0) return false;
        for (j in startIdx...stmts.length) if (stmtUsesVar(stmts[j], name)) return true;
        return false;
    }

    public static function stmtUsesVar(n:ElixirAST, name:String):Bool {
        var found = false;
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_" || c == ".";
        }
        function scanStringInterpolation(str:String):Void {
            var i = 0;
            while (!found && str != null && i < str.length) {
                var idx = str.indexOf("#{", i);
                if (idx == -1) break;
                var j = str.indexOf("}", idx + 2);
                if (j == -1) break;
                var inner = str.substr(idx + 2, j - (idx + 2));
                if (inner.indexOf(name) != -1) { found = true; break; }
                i = j + 1;
            }
        }
        function walk(x:ElixirAST, inPattern:Bool):Void {
            if (x == null || found) return;
            switch (x.def) {
                case EVar(v) if (!inPattern && v == name):
                    found = true;
                case ERaw(code):
                    if (name != null && name.length > 0 && name.charAt(0) != '_' && code != null) {
                        var start = 0;
                        while (!found) {
                            var i = code.indexOf(name, start);
                            if (i == -1) break;
                            var before = i > 0 ? code.substr(i - 1, 1) : null;
                            var afterIdx = i + name.length;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            if (!isIdentChar(before) && !isIdentChar(after)) { found = true; break; }
                            start = i + name.length;
                        }
                    }
                case EString(str):
                    scanStringInterpolation(str);
                case EBinary(Match, left, rhs):
                    // Only RHS can reference the name in expression position
                    walk(rhs, false);
                case EMatch(pat, rhs2):
                    // Only RHS can reference the name in expression position
                    walk(rhs2, false);
                case EBlock(ss):
                    for (s in ss) walk(s, false);
                case EDo(ss2):
                    for (s in ss2) walk(s, false);
                case EIf(c,t,e):
                    walk(c, false); walk(t, false); if (e != null) walk(e, false);
                case ECase(expr, clauses):
                    walk(expr, false);
                    for (c in clauses) {
                        // c.pattern binds names; do not treat as use
                        if (c.guard != null) walk(c.guard, false);
                        walk(c.body, false);
                    }
                case EWith(clauses, doBlock, elseBlock):
                    for (wc in clauses) walk(wc.expr, false);
                    walk(doBlock, false);
                    if (elseBlock != null) walk(elseBlock, false);
                case ECall(tgt, _, args):
                    if (tgt != null) walk(tgt, false);
                    for (a in args) walk(a, false);
                case ERemoteCall(tgt2, _, args2):
                    walk(tgt2, false);
                    for (a in args2) walk(a, false);
                case EField(obj, _):
                    walk(obj, false);
                case EAccess(tgt3, key):
                    walk(tgt3, false); walk(key, false);
                case EKeywordList(pairs):
                    for (p in pairs) walk(p.value, false);
                case EMap(pairs):
                    for (p in pairs) { walk(p.key, false); walk(p.value, false); }
                case EStructUpdate(base, fields):
                    walk(base, false); for (f in fields) walk(f.value, false);
                case ETuple(elems) | EList(elems):
                    for (e in elems) walk(e, false);
                case EFn(clauses):
                    for (cl in clauses) walk(cl.body, false);
                default:
            }
        }
        walk(n, false);
        return found;
    }
}

#end

