package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WHAT
 * DeadAssignmentElimination: Remove pure alias assignments that are never read.
 *
 * WHY
 * During extraction or normalization phases, temporary aliases can be introduced at
 * function or module scope. When these aliases are never read, they generate warnings
 * and clutter output. Eliminate them safely when RHS is pure and no subsequent reads occur.
 *
 * HOW
 * - Within each EBlock, scan statements linearly.
 * - For EMatch(PVar(name), rhs) where rhs is pure and name matches infra/alias patterns,
 *   check subsequent statements for variable usage. If not used, drop the assignment.
 * - Conservative purity: literals, tuples, lists, maps, keywords, structs, parentheses.
 * - Do not touch effectful expressions or matches with complex LHS patterns.
 */
class DeadAssignmentElimination {
    static inline function isInfraAliasName(n:String):Bool {
        return n == "g" || n == "_g" || ~/^_?g\d+$/.match(n) || n == "temp_result" || n == "temp";
    }

    static function isPure(e: ElixirAST): Bool {
        return switch (e.def) {
            case EVar(_): true;
            case EAtom(_): true;
            case EString(_): true;
            case EInteger(_): true;
            case EFloat(_): true;
            case EBoolean(_): true;
            case ENil: true;
            case ECharlist(_): true;
            case EParen(inner): isPure(inner);
            case ETuple(items): var ok = true; for (i in items) if (!isPure(i)) { ok = false; break; } ok;
            case EList(items): var ok = true; for (i in items) if (!isPure(i)) { ok = false; break; } ok;
            case EMap(pairs): var ok = true; for (p in pairs) if (!isPure(p.value)) { ok = false; break; } ok;
            case EKeywordList(pairs): var ok = true; for (p in pairs) if (!isPure(p.value)) { ok = false; break; } ok;
            case EStruct(_, fields): var ok = true; for (f in fields) if (!isPure(f.value)) { ok = false; break; } ok;
            default: false;
        };
    }

    static function containsVar(node: ElixirAST, name: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (n == null || found) return;
            switch (n.def) {
                case EVar(v) if (v == name):
                    found = true;
                case EBlock(exprs): for (e in exprs) walk(e);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(target, clauses):
                    walk(target);
                    for (cl in clauses) walk(cl.body);
                case ECond(clauses): for (cl in clauses) { walk(cl.condition); walk(cl.body); }
                case ECall(target, _, args): if (target != null) walk(target); for (a in args) walk(a);
                case ERemoteCall(mod, _, args): walk(mod); for (a in args) walk(a);
                case ETuple(items): for (i in items) walk(i);
                case EList(items): for (i in items) walk(i);
                case EMap(pairs): for (p in pairs) walk(p.value);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EStruct(_, fields): for (f in fields) walk(f.value);
                case EParen(inner): walk(inner);
                case EMatch(_, expr): walk(expr);
                default:
            }
        }
        walk(node);
        return found;
    }

    public static function deadAssignmentEliminationPass(ast: ElixirAST): ElixirAST {
        function process(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    var i = 0;
                    while (i < stmts.length) {
                        var s = stmts[i];
                        var removed = false;
                        switch (s.def) {
                            case EMatch(PVar(name), rhs) if (isInfraAliasName(name) && isPure(rhs)):
                                // Check if 'name' is used in any subsequent statement in this block
                                var usedLater = false;
                                var j = i + 1;
                                while (j < stmts.length && !usedLater) {
                                    if (containsVar(stmts[j], name)) usedLater = true;
                                    j++;
                                }
                                if (!usedLater) {
                                    removed = true; // drop this dead assignment
                                }
                            default:
                        }
                        if (!removed) out.push(process(s));
                        i++;
                    }
                    makeAST(EBlock(out));
                default:
                    ElixirASTTransformer.transformAST(node, process);
            };
        }
        return process(ast);
    }
}

#end
