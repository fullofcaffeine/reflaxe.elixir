package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

/**
 * RefDeclAlignmentTransforms
 *
 * WHAT
 * - Aligns variable declarations and references to a canonical spelling
 *   (underscore prefixing, numeric suffixes) within the same scope.
 *
 * WHY
 * - Ensures consistent naming after transformations that introduce variants
 *   like _var, var1, var_2, avoiding confusion and undefined references.
 *
 * HOW
 * - Compute canonical base name per variable and rewrite both decls and refs.
 *
 * EXAMPLES
 * Before: var; _var referenced -> After: either var or _var consistently
 */
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * RefDeclAlignmentTransforms
 *
 * WHAT
 * - Align local declarations and references within a function scope so that
 *   underscored and numeric-suffixed variants converge to a single canonical
 *   name that matches actual usage. This fixes mismatches like `_key` declared
 *   but `key` referenced, or `query2` declared but `query` referenced.
 *
 * WHY
 * - Generic hygiene passes may prefix truly unused locals with underscores, but
 *   subsequent rewrites can introduce references to the base names. Without
 *   alignment, this results in undefined variables at compile time.
 *
 * HOW
 * - For each EDef/EDefp:
 *   1) Collect declared locals (from patterns and assignment LHS).
 *   2) Collect referenced locals (EVar occurrences).
 *   3) Build a canonical mapping per base name:
 *      - Prefer plain `name` if it is referenced anywhere.
 *      - Else if numeric-suffixed variants of `name` are declared and unique,
 *        choose that variant as canonical when `name` is referenced.
 *      - Else if only `_name` is declared and `name` or `_name` is referenced,
 *        choose plain `name` as canonical.
 *   4) Rewrite both declarations (patterns and LHS) and references (EVar) to
 *      the canonical spelling.
 */
class RefDeclAlignmentTransforms {
    public static function alignLocalsPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, params, guards, body):
                    var newBody = align(body, params);
                    makeASTWithMeta(EDef(name, params, guards, newBody), node.metadata, node.pos);
                case EDefp(name, params, guards, body):
                    var newBody = align(body, params);
                    makeASTWithMeta(EDefp(name, params, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function align(body: ElixirAST, ?params:Array<EPattern>): ElixirAST {
        var declared = new Map<String, Bool>();
        var referenced = new Map<String, Bool>();

        // Collect declared from function parameters as well
        if (params != null) {
            for (p in params) collectPatternDecls(p, declared);
        }

        // Collect declarations
        ASTUtils.walk(body, function(n: ElixirAST) {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(p, _): collectPatternDecls(p, declared);
                case EBinary(Match, left, _): collectLhsDecls(left, declared);
                default:
            }
        });

        // Collect references
        ASTUtils.walk(body, function(n: ElixirAST) {
            switch (n.def) {
                case EVar(v): referenced.set(v, true);
                default:
            }
        });

        // Build groups by base name: base -> [declared variants]
        var groups = new Map<String, Array<String>>();
        for (k in declared.keys()) {
            var info = splitBase(k);
            var arr = groups.exists(info.base) ? groups.get(info.base) : [];
            arr.push(k);
            groups.set(info.base, arr);
        }

        // Determine canonical name per base
        var canonical = new Map<String, String>();
        for (base in groups.keys()) {
            var variants = groups.get(base);
            var hasPlainRef = referenced.exists(base);
            // Check underscore declaration explicitly
            var hasUnderscoreDecl = false;
            for (v in variants) if (v == "_" + base) { hasUnderscoreDecl = true; break; }
            var numericDecls = variants.filter(v -> isNumericVariantOf(v, base));
            var pick: String = null;

            if (hasPlainRef) {
                pick = base;
            } else if (numericDecls.length == 1 && referenced.exists(base)) {
                pick = numericDecls[0];
            } else if (hasUnderscoreDecl && (referenced.exists(base) || referenced.exists("_" + base))) {
                pick = base;
            }

            if (pick != null) canonical.set(base, pick);
        }

        if (Lambda.count(canonical) == 0) return body;

        // Apply canonicalization to declarations and references
        function tx(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                case EMatch(p, rhs):
                    makeASTWithMeta(EMatch(renamePatternToCanonical(p, canonical), rhs), n.metadata, n.pos);
                case EBinary(Match, left, rhs):
                    makeASTWithMeta(EBinary(Match, renameLhsToCanonical(left, canonical), rhs), n.metadata, n.pos);
                case EVar(v):
                    var nb = splitBase(v).base;
                    if (canonical.exists(nb)) {
                        var target = canonical.get(nb);
                        if (v != target) makeASTWithMeta(EVar(target), n.metadata, n.pos) else n;
                    } else n;
                default:
                    n;
            }
        }

        return ElixirASTTransformer.transformNode(body, tx);
    }

    static function splitBase(name: String): { base: String, kind: String } {
        if (name == null || name.length == 0) return { base: name, kind: "plain" };
        if (name.charAt(0) == "_") return { base: name.substr(1), kind: "underscored" };
        // numeric suffix detection
        var i = name.length - 1;
        while (i >= 0 && name.charCodeAt(i) >= '0'.code && name.charCodeAt(i) <= '9'.code) i--;
        var suffix = name.substr(i + 1);
        if (suffix.length > 0) return { base: name.substr(0, i + 1), kind: "numeric" };
        return { base: name, kind: "plain" };
    }

    static function isNumericVariantOf(name: String, base: String): Bool {
        if (name == null || base == null) return false;
        if (!StringTools.startsWith(name, base)) return false;
        var rest = name.substr(base.length);
        if (rest.length == 0) return false;
        for (i in 0...rest.length) {
            var c = rest.charCodeAt(i);
            if (c < '0'.code || c > '9'.code) return false;
        }
        return true;
    }

    static function collectPatternDecls(p: EPattern, declared: Map<String, Bool>): Void {
        switch (p) {
            case PVar(n): declared.set(n, true);
            case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, declared);
            case PCons(h, t): collectPatternDecls(h, declared); collectPatternDecls(t, declared);
            case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, declared);
            case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, declared);
            case PPin(inner): collectPatternDecls(inner, declared);
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

    static function renamePatternToCanonical(p: EPattern, canonical: Map<String, String>): EPattern {
        return switch (p) {
            case PVar(n):
                var nb = splitBase(n).base;
                if (canonical.exists(nb)) PVar(canonical.get(nb)) else p;
            case PTuple(es): PTuple([for (e in es) renamePatternToCanonical(e, canonical)]);
            case PList(es): PList([for (e in es) renamePatternToCanonical(e, canonical)]);
            case PCons(h, t): PCons(renamePatternToCanonical(h, canonical), renamePatternToCanonical(t, canonical));
            case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: renamePatternToCanonical(kv.value, canonical) }]);
            case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: renamePatternToCanonical(f.value, canonical) }]);
            case PPin(inner): PPin(renamePatternToCanonical(inner, canonical));
            default: p;
        }
    }

    static function renameLhsToCanonical(lhs: ElixirAST, canonical: Map<String, String>): ElixirAST {
        return switch (lhs.def) {
            case EVar(v):
                var nb = splitBase(v).base;
                if (canonical.exists(nb)) makeASTWithMeta(EVar(canonical.get(nb)), lhs.metadata, lhs.pos) else lhs;
            case EBinary(Match, l2, r2):
                makeASTWithMeta(EBinary(Match, renameLhsToCanonical(l2, canonical), renameLhsToCanonical(r2, canonical)), lhs.metadata, lhs.pos);
            default: lhs;
        }
    }
}

#end
