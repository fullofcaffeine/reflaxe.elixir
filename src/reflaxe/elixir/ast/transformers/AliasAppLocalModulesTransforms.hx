package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AliasAppLocalModulesTransforms
 *
 * WHAT
 * - Insert `alias <App>.<Name>` statements at the top of <App>Web.* modules for any
 *   single-segment CamelCase module `<Name>` referenced in remote calls when a
 *   corresponding `<App>.<Name>` module exists.
 *
 * WHY
 * - Some builder paths may emit bare module calls (e.g., `Todo.changeset/2`) late.
 *   Rather than over-qualify prints, provide explicit aliases that are idiomatic in
 *   Phoenix contexts and silence undefined module warnings.
 *
 * HOW
 * - Collect defined modules and referenced CamelCase roots in each Web module.
 * - If `<App>.<Name>` exists, add `alias <App>.<Name>` attribute into the module header.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class AliasAppLocalModulesTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        var defined = new Map<String,Bool>();
        function collect(n: ElixirAST):Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EModule(name, _, body): defined.set(name, true); for (b in body) collect(b);
                case EDefmodule(name, doBlock): defined.set(name, true); collect(doBlock);
                default:
                    switch (n.def) {
                        case EBlock(es): for (e in es) collect(e);
                        case EIf(c,t,e): collect(c); collect(t); if (e != null) collect(e);
                        case ECase(ex, cs): collect(ex); for (c in cs) { if (c.guard != null) collect(c.guard); collect(c.body);} 
                        case EFn(cs): for (cl in cs) collect(cl.body);
                        case ECall(t,_,as): if (t != null) collect(t); if (as != null) for (a in as) collect(a);
                        case ERemoteCall(m,_,as): collect(m); if (as != null) for (a in as) collect(a);
                        default:
                    }
            }
        }
        collect(ast);

        inline function isCamel(name:String):Bool {
            if (name == null || name.length == 0) return false;
            var c = name.charAt(0);
            return c.toUpperCase() == c && c.toLowerCase() != c && name.indexOf(".") == -1;
        }
        inline function appPrefix(moduleName:String):Null<String> {
            if (moduleName == null) return null;
            var i = moduleName.indexOf("Web");
            return i > 0 ? moduleName.substring(0, i) : null;
        }
        inline function whitelisted(name:String):Bool {
            return reflaxe.elixir.ast.StdModuleWhitelist.isWhitelistedRoot(name);
        }

        function moduleAlreadyAliased(stmts:Array<ElixirAST>, fq:String):Bool {
            for (s in stmts) switch (s.def) {
                case EAlias(m, _): if (m == fq) return true;
                default:
            }
            return false;
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name.indexOf("Web") != -1):
                    var app = appPrefix(name);
                    var referenced = new Map<String,Bool>();
                    // Walk body to collect bare module roots used in calls
                    ElixirASTTransformer.transformNode(makeASTWithMeta(EBlock(body), n.metadata, n.pos), function(x:ElixirAST):ElixirAST {
                        switch (x.def) {
                            case ERemoteCall(mod, _, _):
                                switch (mod.def) {
                                    case EVar(m) if (isCamel(m) && !whitelisted(m)): referenced.set(m, true);
                                    default:
                                }
                            case ECall(target, _, _) if (target != null):
                                switch (target.def) {
                                    case EVar(moduleRoot) if (isCamel(moduleRoot) && !whitelisted(moduleRoot)): referenced.set(moduleRoot, true);
                                    default:
                                }
                            default:
                        }
                        return x;
                    });
                    // Build alias attribute list additions
                    var newBody = body.copy();
                    for (mname in referenced.keys()) {
                        var fq = (app != null) ? (app + "." + mname) : null;
                        if (fq != null && defined.exists(fq)) {
                            if (!moduleAlreadyAliased(newBody, fq)) {
                                newBody.unshift(makeASTWithMeta(EAlias(fq, null), n.metadata, n.pos));
                            }
                        }
                    }
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name.indexOf("Web") != -1):
                    var app = appPrefix(name);
                    var referenced = new Map<String,Bool>();
                    ElixirASTTransformer.transformNode(doBlock, function(x:ElixirAST):ElixirAST {
                        switch (x.def) {
                            case ERemoteCall(mod, _, _):
                                switch (mod.def) {
                                    case EVar(m) if (isCamel(m) && !whitelisted(m)): referenced.set(m, true);
                                    default:
                                }
                            case ECall(target, _, _) if (target != null):
                                switch (target.def) {
                                    case EVar(moduleRoot) if (isCamel(moduleRoot) && !whitelisted(moduleRoot)): referenced.set(moduleRoot, true);
                                    default:
                                }
                            default:
                        }
                        return x;
                    });
                    var newDo = doBlock;
                    var aliasNodes:Array<ElixirAST> = [];
                    for (moduleRoot in referenced.keys()) {
                        var qualifiedName = (app != null) ? (app + "." + moduleRoot) : null;
                        if (qualifiedName != null && defined.exists(qualifiedName)) {
                            aliasNodes.push(makeASTWithMeta(EAlias(qualifiedName, null), n.metadata, n.pos));
                        }
                    }
                    if (aliasNodes.length > 0) {
                        // Prepend @alias attributes into the do block
                        switch (newDo.def) {
                            case EDo(stmts):
                                var merged = aliasNodes.concat(stmts);
                                newDo = makeASTWithMeta(EDo(merged), newDo.metadata, newDo.pos);
                            case EBlock(statements):
                                var mergedStatements = aliasNodes.concat(statements);
                                newDo = makeASTWithMeta(EBlock(mergedStatements), newDo.metadata, newDo.pos);
                            default:
                        }
                    }
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end
