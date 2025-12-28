package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DropTempNilAssignTransforms
 *
 * WHAT
 * - Drop assignments of the form `thisN = nil` and `_thisN = nil` in any block/EFn bodies.
 *
 * WHY
 * - These are compiler-generated sentinels that trigger unused-variable warnings.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class DropTempNilAssignTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    makeASTWithMeta(EBlock(filter(stmts)), n.metadata, n.pos);
                case EDo(stmts2):
                    makeASTWithMeta(EDo(filter(stmts2)), n.metadata, n.pos);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var b = cl.body;
                        var nb = switch (b.def) {
                            case EBlock(ss):
                                makeASTWithMeta(EBlock(filter(ss)), b.metadata, b.pos);
                            case EDo(ss2):
                                makeASTWithMeta(EDo(filter(ss2)), b.metadata, b.pos);
                            default:
                                b;
                        };
                        newClauses.push({ args: cl.args, guard: cl.guard, body: nb });
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function filter(stmts:Array<ElixirAST>): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        for (s in stmts) switch (s.def) {
            case EBinary(Match, left, rhs):
                var isTemp = switch (left.def) { case EVar(nm): isTempName(nm); default: false; };
                var isNil = isNilValue(rhs);
                if (!(isTemp && isNil)) out.push(s);
            case EMatch(pat, rhs2):
                var isTemp2 = switch (pat) { case PVar(n2): isTempName(n2); default: false; };
                var isNil2 = isNilValue(rhs2);
                if (!(isTemp2 && isNil2)) out.push(s);
            default:
                out.push(s);
        }
        return out;
    }

    // Check for nil in both ENil and EAtom("nil") representations
    static function isNilValue(ast:ElixirAST):Bool {
        if (ast == null || ast.def == null) return false;
        return switch (ast.def) {
            case ENil: true;
            case EAtom(a): a == "nil";
            default: false;
        };
    }

    static function isTempName(nm:String):Bool {
        if (nm == null) return false;
        if (nm.indexOf("this") == 0) return true;
        if (nm.indexOf("_this") == 0) return true;
        return false;
    }
}

#end

