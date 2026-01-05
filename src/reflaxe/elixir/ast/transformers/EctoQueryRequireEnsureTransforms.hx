package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoQueryRequireEnsureTransforms
 *
 * WHAT
 * - Absolute-final sweep to ensure `require Ecto.Query` is present in any
 *   module that calls `Ecto.Query.*` macros via remote call.
 *
 * WHY
 * - Some earlier passes may introduce Ecto.Query calls late (e.g., IIFE inlining).
 *   This guarantees macro availability.
 *
 * HOW
 * - For EDefmodule/EModule, scan children for ERemoteCall(EVar("Ecto.Query"), ...).
 * - If found and no existing ERequire("Ecto.Query"), prepend one.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class EctoQueryRequireEnsureTransforms {
    static function moduleNeedsRequire(blockOrBody: ElixirAST): {needs:Bool, has:Bool} {
        var res = {needs:false, has:false};
        function scan(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case ERequire(mod, _): if (mod == "Ecto.Query") res.has = true;
                case ERemoteCall(mod, _, args):
                    switch (mod.def) { case EVar(m) if (m == "Ecto.Query"): res.needs = true; default: }
                    if (args != null) for (a in args) scan(a);
                case ERaw(code):
                    if (code != null && (code.indexOf("Ecto.Query.") != -1 || code.indexOf(" fragment(") != -1 || code.indexOf(" join(") != -1)) res.needs = true;
                case ECall(t,_,as):
                    // Detect bare fragment()/join() which rely on `require Ecto.Query`
                    switch (t?.def) {
                        case EVar(fn) if (fn == "fragment" || fn == "join"): res.needs = true;
                        default:
                    }
                    if (t != null) scan(t);
                    if (as != null) for (a in as) scan(a);
                case EBlock(es): for (e in es) scan(e);
                case EDo(es2): for (e in es2) scan(e);
                // Remote-only gating: do NOT infer from pin operator alone
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case ECase(e, cs): scan(e); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                case EBinary(_, l, r): scan(l); scan(r);
                case EFn(cs): for (cl in cs) scan(cl.body);
                case EDef(_,_,_,b): scan(b);
                case EDefp(_,_,_,b2): scan(b2);
                default:
            }
        }
        scan(blockOrBody);
        return res;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDefmodule(name, doBlock):
                    switch (doBlock.def) {
                        case EBlock(stmts) | EDo(stmts):
                            var status = moduleNeedsRequire(doBlock);
                            #if debug_ecto_query_require
                            #end
                            if (status.needs && !status.has) {
                            #if debug_ecto_query_require
                            #end
                                var req = makeAST(ERequire("Ecto.Query", null));
                                var newDo: ElixirAST = switch (doBlock.def) {
                                    case EBlock(_): makeASTWithMeta(EBlock([req].concat(stmts)), doBlock.metadata, doBlock.pos);
                                    case EDo(_): makeASTWithMeta(EDo([req].concat(stmts)), doBlock.metadata, doBlock.pos);
                                    default: doBlock;
                                };
                                return makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                            } else n;
                        default: n;
                    }
                case EModule(name, attrs, body):
                    var composed = makeAST(EBlock(body));
                    var status2 = moduleNeedsRequire(composed);
                    #if debug_ecto_query_require
                    #end
                    if (status2.needs && !status2.has) {
                        #if debug_ecto_query_require
                        #end
                        var req2 = makeAST(ERequire("Ecto.Query", null));
                        return makeASTWithMeta(EModule(name, attrs, [req2].concat(body)), n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }
}

#end
