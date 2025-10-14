package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StructUpdateListAppendRewriteTransforms
 *
 * WHAT
 * - Rewrites standalone struct-update list appends of the form:
 *     %{struct | field: struct.field ++ RHS}
 *   into an assignment that appends to the local list variable:
 *     field = field ++ RHS
 *
 * WHY
 * - Some immutability transforms emit a non-returned struct update whose semantic
 *   intent is to append to a local accumulator list used shortly after (e.g., for params).
 *   Rewriting preserves semantics without requiring a full struct rewrite.
 *
 * HOW
 * - Detect EStructUpdate with exactly one field where the value is a concat of
 *   EField(EVar(base), fieldName) ++ RHS and the key matches fieldName. Replace the
 *   entire expression with EMatch(PVar(fieldName), EBinary(Concat, EVar(fieldName), RHS)).
 */
class StructUpdateListAppendRewriteTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case EStructUpdate(structExpr, fields) if (fields != null && fields.length == 1):
                    var f = fields[0];
                    var keyName = f.key;
                    var baseName = extractBaseVarName(structExpr);
                    var out: ElixirAST = switch (f.value.def) {
                        case EBinary(op, left, right) if (op == Concat && baseName != null && keyName != null):
                            if (isStructFieldRef(left, baseName, keyName)) {
                                // Build: keyName = keyName ++ right
                                var assign = makeAST(EMatch(PVar(keyName), makeAST(EBinary(Concat, makeAST(EVar(keyName)), right))));
                                makeASTWithMeta(assign.def, n.metadata, n.pos);
                            } else n;
                        default: n;
                    }
                    return out;
                default:
                    return n;
            }
        });
    }

    static function extractBaseVarName(e: ElixirAST): Null<String> {
        return switch (e.def) {
            case EVar(name): name;
            default: null;
        }
    }

    static function isStructFieldRef(e: ElixirAST, base: String, field: String): Bool {
        return switch (e.def) {
            case EField(left, fname):
                switch (left.def) {
                    case EVar(v) if (v == base && fname == field): true;
                    default: false;
                }
            default: false;
        }
    }
}

#end
