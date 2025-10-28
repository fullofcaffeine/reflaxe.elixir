package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * InlineTrailingReturnVarTransforms
 *
 * WHAT
 * - Inlines a simple trailing return variable by replacing it with its
 *   last assignment expression within the same block.
 *
 * WHY
 * - Hygiene/cleanup passes may drop local assignments in some shapes,
 *   leaving only a trailing variable reference that becomes undefined.
 *   Inlining the assignment into the return position preserves semantics
 *   and removes the undefined variable.
 *
 * HOW
 * - For each def/defp body that is a block ending with EVar(name):
 *   - Scan backward to find the last assignment to `name` (EMatch/EBinary Match).
 *   - Remove that assignment statement and replace the trailing EVar with the RHS.
 */
class InlineTrailingReturnVarTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, inlineBody(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, inlineBody(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function inlineBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts) if (stmts != null && stmts.length >= 2):
                var last = stmts[stmts.length - 1];
                var retName: Null<String> = switch (last.def) { case EVar(v): v; default: null; };
                if (retName == null) return body;
                // Keep consistent production shape: allow inlining for switch_result_* too
                // Safety: only inline if retName is NOT referenced in any prior statement
                // to avoid removing a needed binding used in guards or checks.
                var referenced = false;
                function containsVar(e: ElixirAST, name:String): Bool {
                    if (e == null) return false;
                    return switch (e.def) {
                        case EVar(v) if (v == name): true;
                        case EBlock(es): for (x in es) if (containsVar(x, name)) return true; false;
                        case EIf(c,t,el): containsVar(c, name) || containsVar(t, name) || (el != null && containsVar(el, name));
                        case ECase(ex, cs): containsVar(ex, name) || (function(){ for (c in cs) if (containsVar(c.body, name)) return true; return false; })();
                        case EBinary(_, l, r): containsVar(l, name) || containsVar(r, name);
                        case EMatch(_, r2): containsVar(r2, name);
                        case ECall(tgt, _, args): (tgt != null && containsVar(tgt, name)) || (function(){ for (a in args) if (containsVar(a, name)) return true; return false; })();
                        case ERemoteCall(tgt2, _, args2): containsVar(tgt2, name) || (function(){ for (a in args2) if (containsVar(a, name)) return true; return false; })();
                        default: false;
                    };
                }
                for (i in 0...stmts.length - 1) if (containsVar(stmts[i], retName)) { referenced = true; break; }
                if (referenced) return body;
                var idx = -1;
                var rhs: ElixirAST = null;
                for (i in 0...stmts.length - 1) {
                    switch (stmts[i].def) {
                        case EBinary(Match, {def: EVar(v1)}, r) if (v1 == retName): idx = i; rhs = r;
                        case EMatch(PVar(v2), r2) if (v2 == retName): idx = i; rhs = r2;
                        default:
                    }
                }
                if (idx == -1 || rhs == null) return body;
                // Safety: avoid inlining when RHS is a trivial literal that would degrade semantics
                switch (rhs.def) {
                    case EString(_) | EInteger(_) | EFloat(_) | EAtom(_) | ENil:
                        return body;
                    default:
                }
                var out = [];
                for (i in 0...stmts.length - 1) if (i != idx) out.push(stmts[i]);
                out.push(rhs);
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }
}

#end
