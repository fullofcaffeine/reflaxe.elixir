package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.PhoenixMapper;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import StringTools;

/**
 * PhoenixComponentModuleNormalizeTransforms
 *
 * WHAT
 * - Normalizes ambiguous `Component.*` module targets to `Phoenix.Component.*` in the emitted Elixir AST
 *   for known Phoenix.Component functions (`assign/2..3`, `assign_new/3`, `update/3`).
 *
 * WHY
 * - Some compiler stages (or upstream shapes) can yield calls whose module target is a bare `Component`
 *   identifier. Late qualification logic (including printer fallbacks) can then incorrectly qualify it
 *   to `<App>.Component`, producing non-existent module references like `TodoApp.Component.assign/3`.
 * - Phoenix.Component is a framework module and must never be treated as an app-local module.
 *
 * HOW
 * - Derive the application prefix (best-effort) to recognize already-qualified `<App>.Component` that
 *   might have been produced by late qualification.
 * - Rewrite ERemoteCall and ECall targets whose module is `Component` or `<App>.Component` to
 *   `Phoenix.Component`, but only for the known Phoenix.Component functions listed above.
 *
 * EXAMPLES
 * Elixir (before):
 *   socket |> Component.assign("editing_todo", nil)
 *   socket |> MyApp.Component.assign("editing_todo", nil)
 * Elixir (after):
 *   socket |> Phoenix.Component.assign("editing_todo", nil)
 */
class PhoenixComponentModuleNormalizeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        var appPrefix: Null<String> = null;
        try {
            appPrefix = PhoenixMapper.getAppModuleName();
        } catch (_e) {}

        #if macro
        if (appPrefix == null) {
            try {
                var defineApp = haxe.macro.Compiler.getDefine("app_name");
                if (defineApp != null && defineApp.length > 0) appPrefix = defineApp;
            } catch (_e) {}
        }
        #end

        var appComponentModule = (appPrefix != null && appPrefix.length > 0) ? (appPrefix + ".Component") : null;
        var appWebComponentModule = (appPrefix != null && appPrefix.length > 0) ? (appPrefix + "Web.Component") : null;

        function extractModuleName(moduleExpr: ElixirAST): Null<String> {
            if (moduleExpr == null || moduleExpr.def == null) return null;
            return switch (moduleExpr.def) {
                case EVar(name):
                    name;
                case EParen(inner):
                    extractModuleName(inner);
                case EBlock(exprs) if (exprs.length == 1):
                    extractModuleName(exprs[0]);
                case EField(left, field):
                    var leftName = extractModuleName(left);
                    leftName != null ? (leftName + "." + field) : null;
                default:
                    null;
            }
        }

        inline function isPhoenixComponentFunction(funcName: String): Bool {
            return funcName == "assign" || funcName == "assign_new" || funcName == "update";
        }

        inline function extractPhoenixComponentFuncFromCompound(funcName: String): Null<String> {
            if (funcName == null) return null;
            if (StringTools.startsWith(funcName, "Component.")) {
                return funcName.substr("Component.".length);
            }
            return null;
        }

        inline function splitQualifiedCallName(qualified: String): Null<{ moduleName: String, funcName: String }> {
            if (qualified == null) return null;
            var lastDot = qualified.lastIndexOf(".");
            if (lastDot <= 0 || lastDot >= qualified.length - 1) return null;
            return {
                moduleName: qualified.substr(0, lastDot),
                funcName: qualified.substr(lastDot + 1)
            };
        }

        inline function isAmbiguousComponentModule(moduleName: String): Bool {
            return moduleName == "Component"
                || (appComponentModule != null && moduleName == appComponentModule)
                || (appWebComponentModule != null && moduleName == appWebComponentModule);
        }

        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            if (node == null || node.def == null) return node;

            return switch (node.def) {
                case ERemoteCall(moduleExpr, funcName, args):
                    var moduleName = extractModuleName(moduleExpr);
                    var compound = extractPhoenixComponentFuncFromCompound(funcName);
                    #if debug_component_normalize
                    if ((moduleName != null && moduleName.indexOf("Component") != -1) || (funcName != null && funcName.indexOf("Component") != -1)) {
                        Sys.println('[ComponentNormalize] ERemoteCall module=' + moduleName + ' func=' + funcName);
                        Sys.stdout().flush();
                    }
                    if (moduleName == null && isPhoenixComponentFunction(funcName)) {
                        Sys.println('[ComponentNormalize] ERemoteCall moduleDef=' + Std.string(moduleExpr.def) + ' func=' + funcName);
                        Sys.stdout().flush();
                    }
                    #end
                    if (compound != null && isPhoenixComponentFunction(compound)) {
                        makeASTWithMeta(
                            ERemoteCall(makeAST(EVar("Phoenix.Component")), compound, args),
                            node.metadata,
                            node.pos
                        );
                    } else if (isPhoenixComponentFunction(funcName) && moduleName != null && isAmbiguousComponentModule(moduleName)) {
                    makeASTWithMeta(
                        ERemoteCall(makeAST(EVar("Phoenix.Component")), funcName, args),
                        node.metadata,
                        node.pos
                    );
                    } else {
                        node;
                    }

                case ECall(target, funcName, args) if (target != null):
                    var moduleName = extractModuleName(target);
                    var compound = extractPhoenixComponentFuncFromCompound(funcName);
                    #if debug_component_normalize
                    if ((moduleName != null && moduleName.indexOf("Component") != -1) || (funcName != null && funcName.indexOf("Component") != -1)) {
                        Sys.println('[ComponentNormalize] ECall(target) module=' + moduleName + ' func=' + funcName);
                        Sys.stdout().flush();
                    }
                    if (moduleName == null && isPhoenixComponentFunction(funcName)) {
                        Sys.println('[ComponentNormalize] ECall(target) targetDef=' + Std.string(target.def) + ' func=' + funcName);
                        Sys.stdout().flush();
                    }
                    #end
                    if (compound != null && isPhoenixComponentFunction(compound)) {
                        makeASTWithMeta(
                            ERemoteCall(makeAST(EVar("Phoenix.Component")), compound, args),
                            node.metadata,
                            node.pos
                        );
                    } else if (isPhoenixComponentFunction(funcName) && moduleName != null && isAmbiguousComponentModule(moduleName)) {
                        // Represent as an explicit remote call to avoid any module qualification fallbacks.
                        makeASTWithMeta(
                            ERemoteCall(makeAST(EVar("Phoenix.Component")), funcName, args),
                            node.metadata,
                            node.pos
                        );
                    } else {
                        node;
                    }

                case ECall(null, funcName, args):
                    var compound = extractPhoenixComponentFuncFromCompound(funcName);
                    var split = splitQualifiedCallName(funcName);
                    #if debug_component_normalize
                    if ((funcName != null && funcName.indexOf("Component") != -1)) {
                        Sys.println('[ComponentNormalize] ECall(null) func=' + funcName);
                        Sys.stdout().flush();
                    }
                    #end
                    if (compound != null && isPhoenixComponentFunction(compound)) {
                        makeASTWithMeta(
                            ERemoteCall(makeAST(EVar("Phoenix.Component")), compound, args),
                            node.metadata,
                            node.pos
                        );
                    } else if (split != null && isPhoenixComponentFunction(split.funcName) && isAmbiguousComponentModule(split.moduleName)) {
                        makeASTWithMeta(
                            ERemoteCall(makeAST(EVar("Phoenix.Component")), split.funcName, args),
                            node.metadata,
                            node.pos
                        );
                    } else {
                        node;
                    }

                default:
                    node;
            }
        });
    }
}

#end
