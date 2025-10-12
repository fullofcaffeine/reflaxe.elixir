package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

/**
 * LocalVarReferenceFixTransforms
 *
 * WHAT
 * - Aligns EVar references to declared local names when builder/optimizer phases
 *   introduced underscore/numeric variants.
 *
 * WHY
 * - Prevents undefined local errors and reduces naming noise, especially after
 *   hygiene passes and temp alias rewrites.
 *
 * HOW
 * - Build a map of declared locals per scope and normalize references accordingly.
 *
 * EXAMPLES
 * Before: len = 0; ...; l3 -> align to len
 */
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalVarReferenceFixTransforms
 *
 * WHY: Certain builder/extraction steps may introduce minor name drift between
 * declarations and references (e.g., declare `_changeset` but later reference
 * `changeset`; or declare `query2` but reference `query`). This pass normalizes
 * references to the closest declared local in the same function scope.
 *
 * WHAT: Within each EDef/EDefp, collect all declared local variable names from
 * patterns and assignment LHS. Then rewrite EVar references if an obvious
 * corresponding declared name exists following simple heuristics:
 * - If `_name` is declared and `name` is referenced (and not declared), map to `_name`.
 * - If `nameN` (e.g., query2) is declared and `name` is referenced (and not declared), map to `nameN`.
 * Only remap when the target name is unique to avoid ambiguity.
 *
 * NOTE: This is a local, scoped normalization to avoid cross-scope renames.
 */
class LocalVarReferenceFixTransforms {
    public static function localVarReferenceFixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var newBody = normalizeBody(body);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var newBody = normalizeBody(body);
                    makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function normalizeBody(body: ElixirAST): ElixirAST {
        // Collect declared names in this function body
        var declared = new Map<String, Bool>();

        function collectPattern(p: EPattern): Void {
            switch (p) {
                case PVar(n): declared.set(n, true);
                case PTuple(es) | PList(es): for (e in es) collectPattern(e);
                case PCons(h, t): collectPattern(h); collectPattern(t);
                case PMap(kvs): for (kv in kvs) collectPattern(kv.value);
                case PStruct(_, fs): for (f in fs) collectPattern(f.value);
                case PPin(inner): collectPattern(inner);
                default:
            }
        }

        // Single traversal to collect declarations
        reflaxe.elixir.ast.ASTUtils.walk(body, function(n: ElixirAST) {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(pattern, _):
                    collectPattern(pattern);
                case EBinary(Match, left, _):
                    // Collect declarations from nested match chains: a = b = c = rhs
                    function collectLhsVars(lhs: ElixirAST): Void {
                        switch (lhs.def) {
                            case EVar(lhsName):
                                declared.set(lhsName, true);
                            case EBinary(Match, l2, r2):
                                collectLhsVars(l2);
                                collectLhsVars(r2);
                            default:
                        }
                    }
                    collectLhsVars(left);
                default:
            }
        });

        // Build a simple, unambiguous rename map
        var rename = new Map<String, String>();

        // Helper to test uniqueness of candidate
        function uniqueCandidate(base: String, candidates: Array<String>): Null<String> {
            return candidates.length == 1 ? candidates[0] : null;
        }

        // Precompute declared lists for matching
        var declaredKeys = [for (k in declared.keys()) k];

        // Rule 1: name -> _name when _name declared and name not declared
        for (k in declaredKeys) {
            if (StringTools.startsWith(k, "_") && k.length > 1) {
                var base = k.substr(1);
                if (!declared.exists(base)) {
                    // Map base -> k only if not already mapped
                    rename.set(base, k);
                }
            }
        }

        // Rule 2: name -> nameN when nameN declared and name not declared (single numeric suffix)
        // Build index by base name
        var groups = new Map<String, Array<String>>();
        for (k in declaredKeys) {
            // Split trailing digits
            var i = k.length - 1;
            while (i >= 0 && k.charCodeAt(i) >= '0'.code && k.charCodeAt(i) <= '9'.code) i--;
            var base = k.substr(0, i + 1);
            var suffix = k.substr(i + 1);
            if (suffix.length > 0) {
                var arr = groups.exists(base) ? groups.get(base) : [];
                arr.push(k);
                groups.set(base, arr);
            }
        }
        for (base in groups.keys()) {
            if (!declared.exists(base)) {
                var cand = uniqueCandidate(base, groups.get(base));
                if (cand != null) {
                    rename.set(base, cand);
                }
            }
        }

        // Rule 3: nameN -> name when base declared and nameN not declared
        var referenced = new Map<String, Bool>();
        reflaxe.elixir.ast.ASTUtils.walk(body, function(n: ElixirAST) {
            switch (n.def) {
                case EVar(v): referenced.set(v, true);
                default:
            }
        });

        for (k in referenced.keys()) {
            // Detect numeric variant like base + digits
            var i = k.length - 1;
            while (i >= 0 && k.charCodeAt(i) >= '0'.code && k.charCodeAt(i) <= '9'.code) i--;
            if (i < k.length - 1) {
                var base = k.substr(0, i + 1);
                var suffix = k.substr(i + 1);
                if (suffix.length > 0 && declared.exists(base) && !declared.exists(k)) {
                    rename.set(k, base);
                }
            }
        }

        // Apply renaming only to references (EVar), not to declarations
        function transform(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                case EVar(name) if (rename.exists(name)):
                    makeASTWithMeta(EVar(rename.get(name)), n.metadata, n.pos);
                default:
                    n;
            }
        }

        return ElixirASTTransformer.transformNode(body, transform);
    }
}

#end
