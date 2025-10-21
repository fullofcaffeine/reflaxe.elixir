package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseResultAssignmentMergeTransforms
 *
 * WHAT
 * - Merges adjacent assignment + case patterns of the form:
 *   x = INIT;
 *   case x do ... end
 *   into a single assignment of the case result:
 *   x = case INIT do ... end
 *
 * WHY
 * - Haxe→Elixir lowering can separate `var x = switch(expr)` into two statements:
 *   `x = expr` followed by `case x do ... end`, leaving `x` bound to the original
 *   INIT rather than the case result. This produces incorrect values (e.g., "medium"
 *   instead of "border-yellow-500").
 *
 * HOW
 * - Scan blocks (function bodies and nested blocks) for the two-statement pattern:
 *   - First statement: EMatch(PVar(name) | EBinary(Match, EVar(name), _), init)
 *   - Second statement: ECase(EVar(name), clauses)
 *   - Rewrite into a single EMatch(name, ECase(init, clauses)) and remove the ECase.
 * - Safe and general: does not rely on application-specific names or domains.
 *
 * EXAMPLES
 * Haxe:
 *   var c = switch(todo.priority) {
 *     case "high": "border-red-500";
 *     case "medium": "border-yellow-500";
 *     case "low": "border-green-500";
 *     case _: "border-gray-300";
 *   }
 *
 * Elixir (before):
 *   c = todo.priority
 *   case c do
 *     "high" -> "border-red-500"
 *     "medium" -> "border-yellow-500"
 *     ...
 *   end
 *
 * Elixir (after):
 *   c = case todo.priority do
 *     "high" -> "border-red-500"
 *     "medium" -> "border-yellow-500"
 *     ...
 *   end
 */
class CaseResultAssignmentMergeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, rewriteBlock(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, rewriteBlock(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteBlock(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts) if (stmts != null && stmts.length >= 2):
                var out:Array<ElixirAST> = [];
                var i = 0;
                function extractInit(e: ElixirAST): ElixirAST {
                    return switch (e.def) {
                        case EBinary(Match, _left, rhs): extractInit(rhs);
                        case EMatch(_pat, rhs2): extractInit(rhs2);
                        default: e;
                    }
                }
                while (i < stmts.length) {
                    if (i + 1 < stmts.length) {
                        var s1 = stmts[i];
                        var s2 = stmts[i + 1];
                        var name:Null<String> = null;
                        var init:Null<ElixirAST> = null;
                        // Match assignment: name = init
                        switch (s1.def) {
                            case EMatch(pat, rhs):
                                switch (pat) { case PVar(n): name = n; default: }
                                init = extractInit(rhs);
                            case EBinary(Match, left, rhs2):
                                switch (left.def) { case EVar(n2): name = n2; default: }
                                init = extractInit(rhs2);
                            default:
                        }
                        if (name != null && init != null) {
                            // Second statement must be case on that var
                            switch (s2.def) {
                                case ECase(target, clauses):
                                    switch (target.def) {
                                        case EVar(v) if (v == name):
                                            var merged = makeASTWithMeta(EMatch(PVar(name), makeASTWithMeta(ECase(init, clauses), s2.metadata, s2.pos)), s1.metadata, s1.pos);
                                            out.push(merged);
                                            i += 2; // Skip the case we merged
                                            continue;
                                        default:
                                    }
                                default:
                            }
                        }
                    }
                    // default: push original stmt
                    out.push(stmts[i]);
                    i++;
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }
}

#end
