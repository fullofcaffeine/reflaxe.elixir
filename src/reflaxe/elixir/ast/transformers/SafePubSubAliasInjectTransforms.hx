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
                    // Do not inject alias inside the Phoenix.SafePubSub module itself
                    if (name == "Phoenix.SafePubSub") return n;
                    if (!(moduleUsesSafePubSub(body) || moduleQualifiedUsed(body, "Phoenix.SafePubSub"))) return n;
                    var newBody = insertAlias(body);
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    // Do not inject alias inside the Phoenix.SafePubSub module itself
                    if (name == "Phoenix.SafePubSub") return n;
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
                case EVar(v) if (v == "SafePubSub"): found = true;
                case ERaw(code): if (code != null && code.indexOf("SafePubSub.") != -1) found = true;
                case ECall(tgt, _, args):
                    if (tgt != null) switch (tgt.def) { case EVar(m) if (m == "SafePubSub"): found = true; default: }
                    if (tgt != null) scan(tgt);
                    if (args != null) for (a in args) scan(a);
                case ERemoteCall(remoteTarget, _, remoteArgs):
                    switch (remoteTarget.def) { case EVar(m) if (m == "SafePubSub"): found = true; default: }
                    scan(remoteTarget);
                    if (remoteArgs != null) for (arg in remoteArgs) scan(arg);
                case EDef(_, _, _, b): scan(b);
                case EDefp(_, _, _, privateBody): scan(privateBody);
                case EBlock(stmts): for (s in stmts) scan(s);
                case EIf(c,t,el): scan(c); scan(t); if (el != null) scan(el);
                case ECase(expr, cs): scan(expr); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                case EBinary(_, l, r): scan(l); scan(r);
                case EMatch(_, rhs): scan(rhs);
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
                case ERemoteCall(mod, _, args):
                    switch (mod.def) { case EVar(m) if (m == moduleName): used = true; default: }
                    scan(mod);
                    if (args != null) for (a in args) scan(a);
                case ECall(tgt, _, argsList):
                    if (tgt != null) switch (tgt.def) { case EVar(moduleVar) if (moduleVar == moduleName): used = true; default: }
                    if (tgt != null) scan(tgt);
                    if (argsList != null) for (a in argsList) scan(a);
                case ERaw(code): if (code != null && code.indexOf(moduleName + ".") != -1) used = true;
                case EDef(_, _, _, b): scan(b);
                case EDefp(_, _, _, privateBody): scan(privateBody);
                case EBlock(stmts): for (s in stmts) scan(s);
                case EIf(c,t,el): scan(c); scan(t); if (el != null) scan(el);
                case ECase(expr, cs): scan(expr); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                case EBinary(_, l, r): scan(l); scan(r);
                case EMatch(_, rhs): scan(rhs);
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
