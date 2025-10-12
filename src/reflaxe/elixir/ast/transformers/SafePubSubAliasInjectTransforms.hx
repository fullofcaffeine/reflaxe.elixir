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
 *
 * WHY
 * - Some passes rewrite PubSub usage to SafePubSub but alias may be missing.
 *   Injecting the alias prevents undefined module warnings while keeping code idiomatic.
 *
 * HOW
 * - Detect any ERemoteCall whose module is "SafePubSub" within a module body.
 * - Prepend an EAlias("Phoenix.SafePubSub", "SafePubSub") declaration if missing.
 *
 * EXAMPLES
 * Before:
 *   SafePubSub.broadcast("topic", {:event, data})
 * After:
 *   alias Phoenix.SafePubSub, as: SafePubSub
 *   SafePubSub.broadcast("topic", {:event, data})
 */
class SafePubSubAliasInjectTransforms {
    public static function injectPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    if (!(moduleUsesSafePubSub(body) || moduleQualifiedUsed(body, "Phoenix.SafePubSub"))) return n;
                    var newBody = insertAlias(body);
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    // Flatten doBlock statements, prepend alias, and rebuild as EBlock
                    var stmts: Array<ElixirAST> = switch (doBlock.def) {
                        case EBlock(ss): ss;
                        case EDo(ss): ss;
                        default: [doBlock];
                    };
                    if (!(moduleUsesSafePubSub(stmts) || moduleQualifiedUsed(stmts, "Phoenix.SafePubSub"))) return n;
                    var replaced = insertAlias(stmts);
                    var newDo = makeAST(EBlock(replaced));
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
                case EVar(v) if (v == "SafePubSub"): found = true;
                case ECall(tgt, _, _):
                    if (tgt != null) switch (tgt.def) { case EVar(m) if (m == "SafePubSub"): found = true; default: }
                case ERaw(code): if (code != null && code.indexOf("SafePubSub.") != -1) found = true;
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

    static function moduleQualifiedUsed(body: Array<ElixirAST>, moduleName: String): Bool {
        var used = false;
        function scan(e: ElixirAST): Void {
            if (used || e == null || e.def == null) return;
            switch (e.def) {
                case ERemoteCall(mod, _, _):
                    switch (mod.def) { case EVar(m) if (m == moduleName): used = true; default: }
                case ECall(tgt, _, _): if (tgt != null) switch (tgt.def) { case EVar(m2) if (m2 == moduleName): used = true; default: }
                case ERaw(code): if (code != null && code.indexOf(moduleName + ".") != -1) used = true;
                case EBlock(stmts): for (s in stmts) scan(s);
                case EIf(c,t,el): scan(c); scan(t); if (el != null) scan(el);
                case ECase(expr, cs): scan(expr); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                case EBinary(_, l, r): scan(l); scan(r);
                case EMatch(_, rhs): scan(rhs);
                case ERemoteCall(m,_,args): scan(m); if (args != null) for (a in args) scan(a);
                case ECall(t,_,args2): if (t != null) scan(t); if (args2 != null) for (a in args2) scan(a);
                default:
            }
        }
        for (b in body) scan(b);
        return used;
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
