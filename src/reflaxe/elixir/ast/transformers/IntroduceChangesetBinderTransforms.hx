package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * IntroduceChangesetBinderTransforms
 *
 * WHAT
 * - Introduces a canonical `cs` binding for Ecto.Changeset validations when
 *   validations reference `cs` before it is bound. Specifically, rewrites a
 *   preceding expression (often a nested wildcard assignment) to `cs = <expr>`
 *   so subsequent calls like `Ecto.Changeset.validate_required(cs, ...)` compile.
 *
 * WHY
 * - Some builder paths emit a nested wildcard assignment chain like
 *     `_ = _ = _ = _ = Ecto.Changeset.cast(data, params, fields)`
 *   followed by validations referencing `cs` without a prior binding. This yields
 *   "undefined variable cs" compilation errors. Establishing a `cs` binding from
 *   the immediately preceding expression restores a clean, idiomatic pipeline.
 *
 * HOW
 * - Within function bodies (def/defp), scan statement lists. When a statement
 *   referencing `cs` in the first argument of `Ecto.Changeset.validate_*` appears
 *   and `cs` has not yet been declared in the current body, rewrite the closest
 *   preceding statement into an assignment `cs = <rhs>`.
 *   - If the preceding statement is a nested assignment chain with wildcard
 *     left-hand sides (e.g., `_ = (_ = (expr))`), peel to the innermost RHS.
 *   - If the preceding statement is a pure expression, convert it to
 *     `cs = <expression>`.
 * - Shape-only; no app- or name-specific assumptions beyond Changeset API.
 *
 * EXAMPLES
 * Elixir before:
 *   _ = _ = _ = _ = Ecto.Changeset.cast(data, normalized_params, Map.keys(normalized_params))
 *   Ecto.Changeset.validate_required(cs, [:title])
 *
 * Elixir after:
 *   cs = Ecto.Changeset.cast(data, normalized_params, Map.keys(normalized_params))
 *   Ecto.Changeset.validate_required(cs, [:title])
 */
class IntroduceChangesetBinderTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                // Pre-scan: detect if body contains validations referencing cs
                var usesCs = false;
                for (si in 0...stmts.length) if (isValidateCallReferencingCs(stmts[si])) { usesCs = true; break; }
                if (!usesCs) return body;
                // Determine source expression to bind: prefer a nested wildcard assignment; else an ERaw cast IIFE
                var sourceIdx = -1;
                var sourceExpr: Null<ElixirAST> = null;
                for (wi in 0...stmts.length) {
                    if (isNestedWildcardAssign(stmts[wi])) { sourceIdx = wi; sourceExpr = bindCsFrom(stmts[wi]); break; }
                }
                if (sourceExpr == null) {
                    for (wi in 0...stmts.length) {
                        switch (stmts[wi].def) {
                            case ERaw(code) if (code != null && code.indexOf("Ecto.Changeset.cast(") != -1):
                                // Bind cs directly to the expression
                                sourceIdx = wi; sourceExpr = makeASTWithMeta(EBinary(Match, makeAST(EVar("cs")), stmts[wi]), stmts[wi].metadata, stmts[wi].pos);
                                break;
                            default:
                        }
                        if (sourceExpr != null) break;
                    }
                }
                if (sourceExpr == null) return body; // nothing to do
                // Rebuild statements: insert cs binding once; drop original source stmt if it was a wildcard assign or ERaw expr
                var out:Array<ElixirAST> = [];
                var inserted = false;
                for (i in 0...stmts.length) {
                    if (!inserted) {
                        out.push(sourceExpr);
                        inserted = true;
                        // Skip original source line if it matches sourceIdx
                        if (i == sourceIdx) continue;
                    }
                    if (i == sourceIdx) {
                        // Skip the redundant original source line
                        continue;
                    }
                    out.push(stmts[i]);
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            case EDo(stmts2):
                var tmp = makeAST(EBlock(stmts2));
                var res = rewriteBody(tmp);
                switch (res.def) {
                    case EBlock(os): makeASTWithMeta(EDo(os), body.metadata, body.pos);
                    default: res;
                }
            default:
                body;
        }
    }

    static function collectDeclsFromStmt(s: ElixirAST, declared: Map<String,Bool>):Void {
        if (s == null || s.def == null) return;
        switch (s.def) {
            case EMatch(p, _):
                collectPatternDecls(p, declared);
            case EBinary(Match, left, _):
                collectLhsDecls(left, declared);
            default:
        }
    }

    static function collectPatternDecls(p: EPattern, declared: Map<String,Bool>):Void {
        switch (p) {
            case PVar(n): declared.set(n, true);
            case PTuple(es): for (e in es) collectPatternDecls(e, declared);
            case PList(es): for (e in es) collectPatternDecls(e, declared);
            case PCons(h, t): collectPatternDecls(h, declared); collectPatternDecls(t, declared);
            case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, declared);
            case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, declared);
            case PPin(inner): collectPatternDecls(inner, declared);
            default:
        }
    }

    static function collectLhsDecls(lhs: ElixirAST, declared: Map<String,Bool>):Void {
        if (lhs == null || lhs.def == null) return;
        switch (lhs.def) {
            case EVar(n): declared.set(n, true);
            case EBinary(Match, l2, r2):
                collectLhsDecls(l2, declared);
                collectLhsDecls(r2, declared);
            default:
        }
    }

    static function isValidateCallReferencingCs(s: ElixirAST): Bool {
        return switch (s.def) {
            case ECall(_, _, _):
                false; // We only care about ERemoteCall(Ecto.Changeset, validate_*) forms
            case ERemoteCall(mod, func, args):
                var isChangeset = switch (mod.def) { case EVar(m) if (m == "Ecto.Changeset"): true; default: false; };
                var isValidate = (func != null && StringTools.startsWith(func, "validate_"));
                var csFirstArg = (args != null && args.length > 0) && switch (args[0].def) { case EVar(v) if (v == "cs"): true; default: false; };
                isChangeset && isValidate && csFirstArg;
            case ERaw(code):
                if (code == null) false else {
                    // Heuristic: look for Ecto.Changeset.validate_* starting with cs as first arg
                    // We avoid regex to keep macro-safety; simple index checks suffice.
                    if (code.indexOf("Ecto.Changeset.validate_") != -1) {
                        // ensure it looks like validate_*(cs, ...)
                        var idx = code.indexOf("Ecto.Changeset.validate_");
                        if (idx >= 0) {
                            var after = code.substr(idx);
                            // find opening paren and check next non-space chars equal to 'cs'
                            var p = after.indexOf("(");
                            if (p > 0) {
                                var rest = StringTools.trim(after.substr(p + 1));
                                // Accept forms starting with cs or (cs)
                                if (StringTools.startsWith(rest, "cs") || StringTools.startsWith(rest, "(cs")) return true;
                            }
                        }
                    }
                    false;
                }
            default:
                false;
        }
    }

    static function bindCsFrom(prev: ElixirAST): ElixirAST {
        if (prev == null || prev.def == null) return prev;
        // If prev is a nested assignment chain, peel to RHS expression.
        var rhs: ElixirAST = null;
        switch (prev.def) {
            case EBinary(Match, _, r):
                rhs = peelNestedAssignRhs(r);
            case EMatch(_, r2):
                rhs = r2;
            default:
                // Any other expression: turn into cs = <expr>
                rhs = prev;
        }
        return makeASTWithMeta(EBinary(Match, makeAST(EVar("cs")), rhs), prev.metadata, prev.pos);
    }

    static function isNestedWildcardAssign(s: ElixirAST): Bool {
        if (s == null || s.def == null) return false;
        return switch (s.def) {
            case EBinary(Match, left, _):
                lhsHasWildcard(left);
            case EMatch(pat, _):
                patternHasWildcard(pat);
            default:
                false;
        }
    }

    static function lhsHasWildcard(lhs: ElixirAST): Bool {
        return switch (lhs.def) {
            case EVar(v) if (v == "_" || (v != null && v.length > 1 && v.charAt(0) == '_')): true;
            case EBinary(Match, l2, r2): lhsHasWildcard(l2) || lhsHasWildcard(r2);
            default: false;
        }
    }

    static function patternHasWildcard(p: EPattern): Bool {
        return switch (p) {
            case PVar(n) if (n == "_" || (n != null && n.length > 1 && n.charAt(0) == '_')): true;
            case PTuple(es): var any = false; for (e in es) any = any || patternHasWildcard(e); any;
            case PList(es): var any2 = false; for (e in es) any2 = any2 || patternHasWildcard(e); any2;
            case PCons(h, t): patternHasWildcard(h) || patternHasWildcard(t);
            default: false;
        }
    }

    static function peelNestedAssignRhs(n: ElixirAST): ElixirAST {
        var cur = n;
        while (cur != null && cur.def != null) {
            switch (cur.def) {
                case EBinary(Match, left, inner):
                    // Only peel when left side looks like a throwaway (underscore); otherwise stop.
                    var isUnderscore = switch (left.def) { case EVar(v) if (v == "_" || (v != null && v.length > 1 && v.charAt(0) == '_')): true; default: false; };
                    if (isUnderscore) cur = inner; else return cur;
                case EMatch(PVar(p), inner2):
                    var isUnderscorePat = (p == "_" || (p != null && p.length > 1 && p.charAt(0) == '_'));
                    if (isUnderscorePat) cur = inner2; else return cur;
                default:
                    return cur;
            }
        }
        return cur == null ? n : cur;
    }
}

#end
