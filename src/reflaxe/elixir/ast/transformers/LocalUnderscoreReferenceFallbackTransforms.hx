package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ASTUtils;

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

        // Collect from match patterns and simple lhs matches
        ASTUtils.walk(body, function(n: ElixirAST) {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(p, _):
                    collectPattern(p, declared);
                case EBinary(Match, left, _):
                    switch (left.def) {
                        case EVar(lhsName): declared.set(lhsName, true);
                        default:
                    }
                default:
            }
        });

        // Build direct rename mapping: name -> _name if _name declared and name not declared
        var rename = new Map<String, String>();
        for (k in declared.keys()) {
            if (StringTools.startsWith(k, "_") && k.length > 1) {
                var base = k.substr(1);
                if (!declared.exists(base)) rename.set(base, k);
            }
        }

        // Apply only to references (EVar)
        function tx(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (rename.exists(v)):
                    makeASTWithMeta(EVar(rename.get(v)), n.metadata, n.pos);
                default:
                    n;
            }
        }
        return ElixirASTTransformer.transformNode(body, tx);
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
}

#end
