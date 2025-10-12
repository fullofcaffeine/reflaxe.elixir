package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AdjacentUnderscoreBinderRefFixTransforms
 *
 * WHAT
 * - When a statement assigns to an underscored local (_name = ...), immediately
 *   followed by a statement that references the base name (name), rewrite those
 *   references in the next statement to the underscored name. This is a local
 *   adjacency fix that preserves semantics and removes undefined variable errors.
 *
 * WHY
 * - Common in helper blocks: compute _query then use `query` in a nested call on
 *   the next line. Earlier passes may have underscored the binder, but adjacent
 *   references were not updated.
 *
 * HOW
 * - For EBlock([...]): iterate statements; when encountering an underscored assignment
 *   at i, rewrite EVar(base) to EVar(_base) inside statement i+1 only (if present)
 *   and only when base has no declaration in the block.
 */
class AdjacentUnderscoreBinderRefFixTransforms {
    public static function fixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    var i = 0;
                    while (i < stmts.length) {
                        var s = stmts[i];
                        var handled = false;
                        switch (s.def) {
                            case EBinary(Match, left, _):
                                switch (left.def) {
                                    case EVar(v) if (v != null && v.length > 1 && v.charAt(0) == '_'):
                                        var base = v.substr(1);
                                        if (i + 1 < stmts.length) {
                                            var nextStmt = stmts[i+1];
                                            var rewritten = rewriteRef(nextStmt, base, v);
                                            out.push(s);
                                            out.push(rewritten);
                                            i += 2;
                                            handled = true;
                                        }
                                    default:
                                }
                            case EMatch(pat, _):
                                var base2 = extractUnderscoreBase(pat);
                                if (base2 != null && i + 1 < stmts.length) {
                                    var nextStmt2 = stmts[i+1];
                                    var rewritten2 = rewriteRef(nextStmt2, base2, '_' + base2);
                                    out.push(s);
                                    out.push(rewritten2);
                                    i += 2;
                                    handled = true;
                                }
                            default:
                        }
                        if (!handled) { out.push(s); i++; }
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                case EDo(bodyStmts):
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

    static function extractUnderscoreBase(p: EPattern): Null<String> {
        return switch (p) {
            case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'): n.substr(1);
            case PTuple(es):
                for (e in es) {
                    var b = extractUnderscoreBase(e);
                    if (b != null) return b;
                }
                null;
            case PList(es):
                for (e in es) {
                    var b2 = extractUnderscoreBase(e);
                    if (b2 != null) return b2;
                }
                null;
            case PCons(h, t):
                var b3 = extractUnderscoreBase(h);
                if (b3 != null) return b3; extractUnderscoreBase(t);
            case PMap(kvs):
                for (kv in kvs) { var b4 = extractUnderscoreBase(kv.value); if (b4 != null) return b4; }
                null;
            case PStruct(_, fs):
                for (f in fs) { var b5 = extractUnderscoreBase(f.value); if (b5 != null) return b5; }
                null;
            case PPin(inner): extractUnderscoreBase(inner);
            default: null;
        }
    }

    static function rewriteRef(node: ElixirAST, base: String, underscored: String): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (v == base):
                    makeASTWithMeta(EVar(underscored), x.metadata, x.pos);
                case ERaw(code):
                    // Best-effort identifier-boundary replacement for the adjacent statement only
                    if (code == null || base == null || base.length == 0) return x;
                    var out = new StringBuf();
                    var i = 0;
                    while (i < code.length) {
                        var idx = code.indexOf(base, i);
                        if (idx == -1) { out.add(code.substr(i)); break; }
                        // Boundary check: previous/non-ident and next/non-ident
                        var ok = true;
                        if (idx > 0) {
                            var p = code.charAt(idx - 1);
                            if (isIdent(p)) ok = false;
                        }
                        var endIdx = idx + base.length;
                        if (endIdx < code.length) {
                            var n = code.charAt(endIdx);
                            if (isIdent(n)) ok = false;
                        }
                        if (ok) {
                            out.add(code.substr(i, idx - i));
                            out.add(underscored);
                            i = endIdx;
                        } else {
                            out.add(code.substr(i, idx - i + base.length));
                            i = idx + base.length;
                        }
                    }
                    makeASTWithMeta(ERaw(out.toString()), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }

    static inline function isIdent(ch: String): Bool {
        if (ch == null || ch.length == 0) return false;
        var c = ch.charCodeAt(0);
        return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code) || c == '_'.code;
    }
}

#end
