package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceResultUnusedUnderscoreTransforms
 *
 * WHAT
 * - When a reduce/reduce_while result is rebound to local variables but those
 *   variables are not used later in the same block, underscore the binders to
 *   eliminate warnings (e.g., `{_all_users} = Enum.reduce_while(...)`).
 *
 * WHY
 * - While/loop lowerings may bind the reduce result just to keep shape. If the
 *   bound names are unused, Elixir warns. Underscoring the binders is the
 *   idiomatic fix.
 *
 * HOW
 * - For each EBlock([...]) statement list, look for EMatch(PVar/PTuple, ERemoteCall(Enum, ...))
 *   and scan subsequent statements for any usage of the bound names.
 *   - For unused PVar(name) → PVar("_" + name)
 *   - For PTuple([... PVar(name) ...]) → replace those fields with PWildcard when unused
 */
class ReduceResultUnusedUnderscoreTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        switch (s.def) {
                            case EMatch(pat, rhs) if (isEnumReduceOrWhile(rhs)):
                                var names = extractNames(pat);
                                if (names.length > 0) {
                                    var unused = names.filter(nm -> !usedLater(stmts, i + 1, nm));
                                    if (unused.length > 0) {
                                        var newPat = underscoreUnusedInPattern(pat, unused);
                                        out.push(makeASTWithMeta(EMatch(newPat, rhs), s.metadata, s.pos));
                                    } else out.push(s);
                                } else out.push(s);
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

    static function isEnumReduceOrWhile(rhs: ElixirAST): Bool {
        return switch (rhs.def) {
            case ERemoteCall({def: EVar("Enum")}, fn, _): (fn == "reduce" || fn == "reduce_while");
            default: false;
        }
    }

    static function extractNames(pat: EPattern): Array<String> {
        return switch (pat) {
            case PVar(n): [n];
            case PTuple(elems):
                var out:Array<String> = [];
                for (p in elems) switch (p) { case PVar(nm): out.push(nm); default: }
                out;
            default: [];
        }
    }

    static function underscoreUnusedInPattern(pat: EPattern, unused: Array<String>): EPattern {
        return switch (pat) {
            case PVar(n):
                if (unused.indexOf(n) >= 0) PVar('_' + n) else pat;
            case PTuple(elems):
                var outElems:Array<EPattern> = [];
                for (p in elems) switch (p) {
                    case PVar(nm):
                        if (unused.indexOf(nm) >= 0) outElems.push(PWildcard) else outElems.push(p);
                    default: outElems.push(p);
                }
                PTuple(outElems);
            default:
                pat;
        }
    }

    static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (j in start...stmts.length) if (stmtUsesVar(stmts[j], name)) return true; return false;
    }

    static function stmtUsesVar(n:ElixirAST, name:String):Bool {
        var found = false;
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
        }
        function walk(x:ElixirAST):Void {
            if (x == null || found) return;
            switch (x.def) {
                case EVar(v) if (v == name): found = true;
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
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s2 in ss2) walk(s2);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case EBinary(_, l, r): walk(l); walk(r);
                case ECall(tgt, _, args): if (tgt != null) walk(tgt); for (a in args) walk(a);
                case ERemoteCall(tgt2, _, args2): walk(tgt2); for (a2 in args2) walk(a2);
                case ECase(expr, cs): walk(expr); for (c in cs) walk(c.body);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base, fields): walk(base); for (f in fields) walk(f.value);
                case EField(obj, _): walk(obj);
                case EAccess(tgt3, key): walk(tgt3); walk(key);
                case EString(str):
                    var i2 = 0;
                    while (!found && str != null && i2 < str.length) {
                        var idx2 = str.indexOf("#{", i2);
                        if (idx2 == -1) break;
                        var j2 = str.indexOf("}", idx2 + 2);
                        if (j2 == -1) break;
                        var inner = str.substr(idx2 + 2, j2 - (idx2 + 2));
                        if (inner.indexOf(name) != -1) { found = true; break; }
                        i2 = j2 + 1;
                    }
                case ETuple(elems): for (e in elems) walk(e);
                default:
            }
        }
        walk(n);
        return found;
    }
}

#end

