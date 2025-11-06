package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * LocalUnderscoreReferenceFallbackTransforms
 *
 * WHAT
 * - Rewrites EVar(name) → EVar(_name) within a function when `_name` is declared
 *   but `name` is not. Operates only on references, not declarations.
 *
 * WHY
 * - Complements LocalVarReferenceFixTransforms to handle edge emission patterns
 *   (e.g., while→reduce_while) where declarations are found but some uses are not.
 *
 * HOW
 * - Collect declared names from patterns and simple `lhs = ...` matches.
 * - Build a map for name→_name when only `_name` is present; rewrite EVar uses.
 *
 * EXAMPLES
 * Elixir before:
 *   _len = l - r
 *   if Kernel.is_nil(len), do: ... # len undefined
 *
 * Elixir after:
 *   _len = l - r
 *   if Kernel.is_nil(_len), do: ...
 */
class LocalUnderscoreReferenceFallbackTransforms {
    public static function fallbackUnderscoreReferenceFixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var newBody = normalize(body);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var newBody = normalize(body);
                    makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function normalize(body: ElixirAST): ElixirAST {
        // Collect declared names in this function body (both plain and underscored)
        var declared = new Map<String, Bool>();
        var referenced = VariableUsageCollector.referencedInFunctionScope(body);

        // Collect from match patterns, simple lhs matches, and EFn clause arguments
        ASTUtils.walk(body, function(n: ElixirAST) {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(p, _):
                    collectPattern(p, declared);
                case EBinary(Match, left, _):
                    // Collect all vars on the left side, including nested chains a = b = c
                    collectLhsDecls(left, declared);
                case EFn(clauses):
                    // Treat anonymous function binders as local declarations
                    for (cl in clauses) for (a in cl.args) collectPattern(a, declared);
                case ERaw(code):
                    // Heuristic: mark base names referenced when they appear in raw code
                    for (dk in declared.keys()) markBaseReferenceInString(referenced, dk, code);
                case EString(s):
                    // Also handle string-literal interpolations (#{...})
                    for (dk in declared.keys()) markBaseReferenceInString(referenced, dk, s);
                default:
            }
        });

        // Build direct rename mapping for references: name -> _name if only _name declared
        var refFallback = new Map<String, String>();
        for (k in declared.keys()) {
            if (StringTools.startsWith(k, "_") && k.length > 1) {
                var base = k.substr(1);
                if (!declared.exists(base)) refFallback.set(base, k);
            }
        }

        // Build declaration normalization: _name -> name if base is referenced and not declared
        var declNormalize = new Map<String, String>();
        for (k in declared.keys()) {
            if (StringTools.startsWith(k, "_") && k.length > 1) {
                var base = k.substr(1);
                if (referenced.exists(base) && !declared.exists(base)) {
                    declNormalize.set(k, base);
                }
            }
        }

        // Apply renaming to declarations and references
        function renamePattern(p: EPattern): EPattern {
            return switch (p) {
                case PVar(n) if (declNormalize.exists(n)):
                    PVar(declNormalize.get(n));
                case PTuple(es): PTuple([for (e in es) renamePattern(e)]);
                case PList(es): PList([for (e in es) renamePattern(e)]);
                case PCons(h, t): PCons(renamePattern(h), renamePattern(t));
                case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: renamePattern(kv.value) }]);
                case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: renamePattern(f.value) }]);
                case PPin(inner): PPin(renamePattern(inner));
                default: p;
            }
        }

        function renameLhs(lhs: ElixirAST): ElixirAST {
            return switch (lhs.def) {
                case EVar(v) if (declNormalize.exists(v)):
                    makeASTWithMeta(EVar(declNormalize.get(v)), lhs.metadata, lhs.pos);
                case EBinary(Match, l2, r2):
                    makeASTWithMeta(EBinary(Match, renameLhs(l2), renameLhs(r2)), lhs.metadata, lhs.pos);
                default: lhs;
            }
        }

        function tx(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                // Declarations: normalize _name -> name when base referenced
                case EMatch(p, rhs):
                    makeASTWithMeta(EMatch(renamePattern(p), rhs), n.metadata, n.pos);
                case EBinary(Match, left, rhs):
                    makeASTWithMeta(EBinary(Match, renameLhs(left), rhs), n.metadata, n.pos);
                // Case clauses: normalize patterns within each clause
                case ECase(expr, clauses):
                    var cls:Array<ElixirAST.ECaseClause> = [];
                    for (cl in clauses) cls.push({ pattern: renamePattern(cl.pattern), guard: cl.guard, body: tx(cl.body) });
                    makeASTWithMeta(ECase(tx(expr), cls), n.metadata, n.pos);
                // References: fallback name -> _name when only _name declared
                case EVar(v) if (refFallback.exists(v)):
                    makeASTWithMeta(EVar(refFallback.get(v)), n.metadata, n.pos);
                default:
                    n;
            }
        }
        return ElixirASTTransformer.transformNode(body, tx);
    }

    static inline function isIdent(ch: String): Bool {
        if (ch == null || ch.length == 0) return false;
        var c = ch.charCodeAt(0);
        // a..z, A..Z, 0..9, underscore
        return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code) || c == '_'.code;
    }

    static inline function baseOf(declaredName:String): String {
        return (StringTools.startsWith(declaredName, "_") && declaredName.length > 1) ? declaredName.substr(1) : declaredName;
    }

    static function markBaseReferenceInString(referenced: Map<String,Bool>, declaredName:String, code:String): Void {
        var base = baseOf(declaredName);
        if (code == null || base == null || base.length == 0) return;
        if (code.indexOf(base) == -1) return;
        // Quick boundary checks to reduce false positives
        var idx = code.indexOf(base);
        var isBoundary = true;
        if (idx > 0) {
            var prev = code.charAt(idx - 1);
            if (isIdent(prev)) isBoundary = false;
        }
        var endIdx = idx + base.length;
        if (endIdx < code.length) {
            var nxt = code.charAt(endIdx);
            if (isIdent(nxt)) isBoundary = false;
        }
        if (isBoundary) referenced.set(base, true);
    }

    static function collectPattern(p: EPattern, declared: Map<String, Bool>): Void {
        switch (p) {
            case PVar(n): declared.set(n, true);
            case PTuple(es) | PList(es): for (e in es) collectPattern(e, declared);
            case PCons(h, t): collectPattern(h, declared); collectPattern(t, declared);
            case PMap(kvs): for (kv in kvs) collectPattern(kv.value, declared);
            case PStruct(_, fs): for (f in fs) collectPattern(f.value, declared);
            case PPin(inner): collectPattern(inner, declared);
            default:
        }
    }

    static function collectLhsDecls(lhs: ElixirAST, declared: Map<String, Bool>): Void {
        switch (lhs.def) {
            case EVar(n): declared.set(n, true);
            case EBinary(Match, l2, r2):
                collectLhsDecls(l2, declared);
                collectLhsDecls(r2, declared);
            default:
        }
    }
}

#end
