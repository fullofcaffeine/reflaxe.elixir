package reflaxe.elixir.ast.analyzers;

#if (macro || reflaxe_runtime)

import Lambda;
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
        inline function snakeCase(s:String):String {
            if (s == null || s.length == 0) return s;
            var out = new StringBuf();
            for (i in 0...s.length) {
                var ch = s.charAt(i);
                var isUpper = (ch.toUpperCase() == ch && ch.toLowerCase() != ch);
                if (isUpper && i > 0) out.add("_");
                out.add(ch.toLowerCase());
            }
            return out.toString();
        }
        inline function camelCase(s:String):String {
            if (s == null || s.length == 0) return s;
            var parts = s.split("_");
            if (parts.length == 1) return s;
            var out = new StringBuf();
            for (i in 0...parts.length) {
                var p = parts[i];
                if (p.length == 0) continue;
                if (i == 0) out.add(p);
                else out.add(p.charAt(0).toUpperCase() + p.substr(1));
            }
            return out.toString();
        }
        var candidates = new Array<String>();
        if (name != null && name.length > 0) {
            candidates.push(name);
            var sn = snakeCase(name);
            if (sn != name) candidates.push(sn);
            var cc = camelCase(name);
            if (cc != name && cc != sn) candidates.push(cc);
            // Also check base name without underscore prefix for underscore-prefixed inputs
            if (name.charAt(0) == '_' && name.length > 1) {
                var baseName = name.substr(1);
                if (!Lambda.exists(candidates, function(c) return c == baseName)) {
                    candidates.push(baseName);
                }
                var snBase = snakeCase(baseName);
                if (snBase != baseName && !Lambda.exists(candidates, function(c) return c == snBase)) {
                    candidates.push(snBase);
                }
            }
            // Also check underscore-prefixed variant for non-underscore inputs
            if (name.charAt(0) != '_') {
                var underscored = '_' + name;
                if (!Lambda.exists(candidates, function(c) return c == underscored)) {
                    candidates.push(underscored);
                }
            }
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
                case EVar(v) if (!inPattern):
                    for (c in candidates) if (v == c) { found = true; break; }
                case EPin(inner):
                    // Pin operator holds an expression; traverse to detect variable usage
                    walk(inner, false);
                case ERaw(code):
                    // NOTE: We MUST check underscore-prefixed variables too!
                    // FinalUnderscoreRepairTransforms needs to detect _this usage in ERaw like String.downcase(_this)
                    if (name != null && name.length > 0 && code != null) {
                        var start = 0;
                        while (!found) {
                            var chosen:String = null;
                            var pos = -1;
                            for (c in candidates) {
                                var idx = code.indexOf(c, start);
                                if (idx != -1 && (pos == -1 || idx < pos)) { pos = idx; chosen = c; }
                            }
                            if (pos == -1 || chosen == null) break;
                            var before = pos > 0 ? code.substr(pos - 1, 1) : null;
                            var afterIdx = pos + chosen.length;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            if (!isIdentChar(before) && !isIdentChar(after)) { found = true; break; }
                            start = pos + chosen.length;
                        }
                    }
                case EString(str):
                    scanStringInterpolation(str);
                case EBinary(Match, left, rhs):
                    // Only RHS can reference the name in expression position for pattern match
                    walk(rhs, false);
                case EBinary(_, leftAny, rightAny):
                    // For non-match binary operators, both sides are expressions
                    walk(leftAny, false);
                    walk(rightAny, false);
                case EMatch(pat, rhsExpr):
                    // Only RHS can reference the name in expression position
                    walk(rhsExpr, false);
                case EBlock(ss):
                    for (s in ss) walk(s, false);
                case EDo(statements):
                    for (s in statements) walk(s, false);
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
                case ERemoteCall(targetExpr, _, argsList):
                    walk(targetExpr, false);
                    for (a in argsList) walk(a, false);
                case EField(obj, _):
                    walk(obj, false);
                case EAccess(objectExpr, key):
                    walk(objectExpr, false); walk(key, false);
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
                case ECond(condClauses):
                    // Walk through cond clauses - both condition and body can use variables
                    for (cl in condClauses) {
                        walk(cl.condition, false);
                        walk(cl.body, false);
                    }
                case ERange(startExpr, endExpr, _):
                    // Range expressions can use variables
                    walk(startExpr, false);
                    walk(endExpr, false);
                case EUnary(_, innerExpr):
                    // Unary operators wrap expressions
                    walk(innerExpr, false);
                case EPipe(pipeLeft, pipeRight):
                    // Pipeline operator - both sides can use variables
                    walk(pipeLeft, false);
                    walk(pipeRight, false);
                case EUnless(unlessCond, unlessBody, unlessElse):
                    // Unless is like if - condition and both branches
                    walk(unlessCond, false);
                    walk(unlessBody, false);
                    if (unlessElse != null) walk(unlessElse, false);
                case EFor(generators, filters, body, into, _uniq):
                    // For comprehensions - walk generators, filters, and body
                    for (gen in generators) {
                        walk(gen.expr, false);
                        // Note: gen.pattern binds names, don't treat as use
                    }
                    for (filter in filters) walk(filter, false);
                    if (body != null) walk(body, false);
                    if (into != null) walk(into, false);
                case ECapture(capturedExpr, _):
                    // Capture expressions can reference variables
                    walk(capturedExpr, false);
                default:
            }
        }
        walk(n, false);
        return found;
    }
}

#end
