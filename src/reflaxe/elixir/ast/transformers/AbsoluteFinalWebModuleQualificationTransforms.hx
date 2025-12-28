package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AbsoluteFinalWebModuleQualificationTransforms
 *
 * WHAT
 * - Absolute-final safety net to qualify single-segment CamelCase module calls inside
 *   <App>Web.* modules to <App>.<Module> when that module exists in the compiled set.
 *
 * WHY
 * - Earlier builder/transformer passes can still synthesize ERemoteCall targets like
 *   `Todo.changeset/2` in Web contexts after the regular ModuleQualification passes ran.
 *   This leads to runtime warnings and missing function errors. This late pass ensures
 *   final emitted code uses fully qualified application modules.
 *
 * HOW
 * - Collect defined module names (EModule/EDefmodule) once.
 * - For any Web module (<App>Web.*), derive app prefix (<App>).
 * - Rewrite ERemoteCall/ECall targets that are single-segment CamelCase and not whitelisted
 *   (Kernel/Enum/Map/etc.) to <App>.<Target> if such a module exists in the set.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class AbsoluteFinalWebModuleQualificationTransforms {
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

        inline function isSingleSegmentModule(name:String):Bool {
            return name != null && name.length > 0 && name.indexOf(".") == -1;
        }
        inline function isUpperCamel(name:String):Bool {
            var c = name.charAt(0);
            return c.toUpperCase() == c && c.toLowerCase() != c;
        }
        inline function isWhitelisted(name:String):Bool {
            return reflaxe.elixir.ast.StdModuleWhitelist.isWhitelistedRoot(name);
        }
        inline function appPrefix(moduleName:String):Null<String> {
            if (moduleName == null) return null;
            var i = moduleName.indexOf("Web");
            return i > 0 ? moduleName.substring(0, i) : null;
        }

        function qualify(subtree: ElixirAST, app:String):ElixirAST {
            return ElixirASTTransformer.transformNode(subtree, function(n: ElixirAST): ElixirAST {
                return switch (n.def) {
                    case ERemoteCall(mod, func, args):
                        switch (mod.def) {
                            case EVar(m) if (isSingleSegmentModule(m) && isUpperCamel(m) && !isWhitelisted(m)):
                                var fq = (app != null) ? (app + "." + m) : null;
                                if (fq != null && defined.exists(fq)) {
                                    makeASTWithMeta(ERemoteCall(makeAST(ElixirASTDef.EVar(fq)), func, args), n.metadata, n.pos);
                                } else n;
                            default: n;
                        }
                    case ECall(target, func, args) if (target != null):
                        switch (target.def) {
                            case EVar(m) if (isSingleSegmentModule(m) && isUpperCamel(m) && !isWhitelisted(m)):
                                var fq2 = (app != null) ? (app + "." + m) : null;
                                if (fq2 != null && defined.exists(fq2)) {
                                    makeASTWithMeta(ERemoteCall(makeAST(ElixirASTDef.EVar(fq2)), func, args), n.metadata, n.pos);
                                } else n;
                            default: n;
                        }
                    default:
                        n;
                }
            });
        }

        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EModule(name, attrs, body) if (name.indexOf("Web") != -1):
                    var app = appPrefix(name);
                    var newBody:Array<ElixirAST> = [];
                    for (b in body) newBody.push(qualify(b, app));
                    makeASTWithMeta(EModule(name, attrs, newBody), node.metadata, node.pos);
                case EDefmodule(name, doBlock) if (name.indexOf("Web") != -1):
                    var app2 = appPrefix(name);
                    var newDo = qualify(doBlock, app2);
                    makeASTWithMeta(EDefmodule(name, newDo), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }
}

#end
