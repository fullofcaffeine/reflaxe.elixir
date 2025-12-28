package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * BlockUnderscoreReferenceFixTransforms
 *
 * WHAT
 * - Within a block, if a local binder is declared as _name and there is no
 *   declaration of name in the same block scope, rewrite references to name
 *   to _name. This prevents undefined variable errors when subsequent code
 *   (e.g. closures) refer to the base name.
 *
 * WHY
 * - Hygiene passes may underscore local assignments while nested code still
 *   references the base name. This shape-based fix keeps references consistent
 *   within the block without app-specific heuristics.
 *
 * HOW
 * - For each EBlock([...]):
 *   1) Collect underscored declarations: _name = ... or match with PVar("_name").
 *   2) Collect base declarations: name = ... or match with PVar("name").
 *   3) For each base that has only underscored declaration and no base decl,
 *      rewrite EVar("name") in this block subtree to EVar("_name").

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class BlockUnderscoreReferenceFixTransforms {
    public static function fixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var underscored = new Map<String, Bool>();
                    var baseDecl = new Map<String, Bool>();
                    for (s in stmts) collectDecls(s, underscored, baseDecl);
                    // Build rename map for bases with only underscored decls
                    var rename = new Map<String, String>();
                    for (k in underscored.keys()) {
                        if (!baseDecl.exists(k)) rename.set(k, '_' + k);
                    }
                    if (Lambda.count(rename) == 0) return n;
                    // Rewrite references inside the block
                    var newStmts: Array<ElixirAST> = [];
                    for (s in stmts) newStmts.push(rewriteRefs(s, rename));
                    makeASTWithMeta(EBlock(newStmts), n.metadata, n.pos);
                case EDo(bodyStmts):
                    // Treat do/end blocks similarly
                    var block = makeAST(EBlock(bodyStmts));
                    var fixed = fixPass(block);
                    switch (fixed.def) {
                        case EBlock(xs): makeASTWithMeta(EDo(xs), n.metadata, n.pos);
                        default: n;
                    }
                default:
                    n;
            }
        });
    }

    static function collectDecls(node: ElixirAST, underscored: Map<String, Bool>, baseDecl: Map<String, Bool>): Void {
        if (node == null || node.def == null) return;
        switch (node.def) {
            case EMatch(pat, rhs):
                collectPatternDecls(pat, underscored, baseDecl);
            case EBinary(Match, left, right):
                switch (left.def) {
                    case EVar(v) if (v != null && v.length > 0):
                        if (v.charAt(0) == '_') underscored.set(v.substr(1), true) else baseDecl.set(v, true);
                    default:
                }
            case EBlock(stmts): for (s in stmts) collectDecls(s, underscored, baseDecl);
            case EIf(c,t,e): collectDecls(c, underscored, baseDecl); collectDecls(t, underscored, baseDecl); if (e != null) collectDecls(e, underscored, baseDecl);
            case ECase(expr, cs): collectDecls(expr, underscored, baseDecl); for (cl in cs) { if (cl.guard != null) collectDecls(cl.guard, underscored, baseDecl); collectDecls(cl.body, underscored, baseDecl);} 
            case ECall(t,_,as): if (t != null) collectDecls(t, underscored, baseDecl); if (as != null) for (a in as) collectDecls(a, underscored, baseDecl);
            case ERemoteCall(m,_,as): collectDecls(m, underscored, baseDecl); if (as != null) for (a in as) collectDecls(a, underscored, baseDecl);
            default:
        }
    }

    static function collectPatternDecls(p: EPattern, underscored: Map<String, Bool>, baseDecl: Map<String, Bool>): Void {
        switch (p) {
            case PVar(n) if (n != null && n.length > 0):
                if (n.charAt(0) == '_') underscored.set(n.substr(1), true) else baseDecl.set(n, true);
            case PTuple(es): for (e in es) collectPatternDecls(e, underscored, baseDecl);
            case PList(es): for (e in es) collectPatternDecls(e, underscored, baseDecl);
            case PCons(h,t): collectPatternDecls(h, underscored, baseDecl); collectPatternDecls(t, underscored, baseDecl);
            case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, underscored, baseDecl);
            case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, underscored, baseDecl);
            case PPin(inner): collectPatternDecls(inner, underscored, baseDecl);
            default:
        }
    }

    static function rewriteRefs(node: ElixirAST, rename: Map<String,String>): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v):
                    var base = v;
                    if (rename.exists(base)) makeASTWithMeta(EVar(rename.get(base)), x.metadata, x.pos) else x;
                case ERaw(code):
                    if (code == null) return x;
                    var out = code;
                    // Apply simple identifier-boundary replacements for each base->underscored
                    for (b in rename.keys()) {
                        var u = rename.get(b);
                        out = replaceIdent(out, b, u);
                    }
                    out != code ? makeASTWithMeta(ERaw(out), x.metadata, x.pos) : x;
                default:
                    x;
            }
        });
    }

    static function replaceIdent(s: String, from: String, to: String): String {
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var idx = s.indexOf(from, i);
            if (idx == -1) { out.add(s.substr(i)); break; }
            var ok = true;
            if (idx > 0) {
                var p = s.charAt(idx - 1);
                if (isIdent(p)) ok = false;
            }
            var endIdx = idx + from.length;
            if (endIdx < s.length) {
                var n = s.charAt(endIdx);
                if (isIdent(n)) ok = false;
            }
            if (ok) {
                out.add(s.substr(i, idx - i));
                out.add(to);
                i = endIdx;
            } else {
                out.add(s.substr(i, idx - i + from.length));
                i = idx + from.length;
            }
        }
        return out.toString();
    }

    static inline function isIdent(ch: String): Bool {
        if (ch == null || ch.length == 0) return false;
        var c = ch.charCodeAt(0);
        return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code) || c == '_'.code;
    }
}

#end
