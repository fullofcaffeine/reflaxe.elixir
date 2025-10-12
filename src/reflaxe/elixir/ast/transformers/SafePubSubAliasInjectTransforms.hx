package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SafePubSubAliasInjectTransforms
 *
 * WHAT
 * - If a module references SafePubSub.* and alias not present, inject
 *   alias Phoenix.SafePubSub, as: SafePubSub at top to avoid undefined warnings.
 */
class SafePubSubAliasInjectTransforms {
    public static function injectPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    if (!moduleUsesSafePubSub(body)) return n;
                    var newBody = insertAlias(body);
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    if (!moduleUsesSafePubSub([doBlock])) return n;
                    var replaced = insertAlias([doBlock]);
                    var newDo = switch (replaced.length) { case 0: doBlock; case _: makeAST(EBlock(replaced)); }
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function moduleUsesSafePubSub(body: Array<ElixirAST>): Bool {
        var found = false;
        function scan(e: ElixirAST): Void {
            if (found || e == null || e.def == null) return;
            switch (e.def) {
                case ERemoteCall({def: EVar(m)}, _, _) if (m == "SafePubSub"): found = true;
                case EBlock(stmts): for (s in stmts) scan(s);
                case EIf(c,t,el): scan(c); scan(t); if (el != null) scan(el);
                case ECase(expr, cs): scan(expr); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                case EBinary(_, l, r): scan(l); scan(r);
                case EMatch(_, rhs): scan(rhs);
                case ECall(tgt, _, args): if (tgt != null) scan(tgt); for (a in args) scan(a);
                case ERemoteCall(tgt2, _, args2): scan(tgt2); for (a2 in args2) scan(a2);
                default:
            }
        }
        for (b in body) scan(b);
        return found;
    }

    static function insertAlias(body: Array<ElixirAST>): Array<ElixirAST> {
        // Prepend alias Phoenix.SafePubSub, as: SafePubSub
        var aliasNode = makeAST(EAlias("Phoenix.SafePubSub", "SafePubSub"));
        var out = [aliasNode];
        for (b in body) out.push(b);
        return out;
    }
}

#end

