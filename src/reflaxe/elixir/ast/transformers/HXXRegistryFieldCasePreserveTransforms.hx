package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HXXRegistryFieldCasePreserveTransforms
 *
 * WHAT
 * - Preserves camelCase field names used by the HXX component registry
 *   (compiler-owned module) by undoing generic snake_case conversion for
 *   specific registry fields inside HXXComponentRegistry.
 *
 * WHY
 * - The HXX registry stores metadata with camelCase keys (e.g., allowedAttributes)
 *   to reflect source attribute names. Generic field snake-casing produces
 *   invalid keys (allowed_attributes) and diverges from intended snapshot shapes.
 *   This transform enforces the registry’s canonical field names without
 *   introducing app-specific heuristics.
 *
 * HOW
 * - Scope: only within module `HXXComponentRegistry`.
 * - Rewrites EField(_, "allowed_attributes") → EField(_, "allowedAttributes").
 * - Extendable: add additional field mappings as needed for registry internals.
 */
class HXXRegistryFieldCasePreserveTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name == "HXXComponentRegistry"):
                    var newBody = [for (b in body) transformInRegistry(b)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name == "HXXComponentRegistry"):
                    makeASTWithMeta(EDefmodule(name, transformInRegistry(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function transformInRegistry(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EField(target, fieldName):
                    var mapped = mapField(fieldName);
                    if (mapped != fieldName) makeASTWithMeta(EField(target, mapped), x.metadata, x.pos) else x;
                default:
                    x;
            }
        });
    }

    static inline function mapField(name: String): String {
        return switch (name) {
            case "allowed_attributes": "allowedAttributes";
            default: name;
        }
    }
}

#end

