package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
using StringTools;

/**
 * ModuleNewToStructLiteral
 *
 * WHAT
 * - Rewrites zero-arity `Module.new()` constructor calls to struct literals `%<App>.Module{}`.
 * - Handles both remote and call forms in all expression positions (call targets, args, interpolation, etc.).
 *
 * WHY
 * - Ecto schemas and data modules in Phoenix code should be instantiated as structs, not via `new/0`.
 * - Using `%<App>.Module{}` avoids `__struct__/1 undefined` warnings on atoms/tables and matches idiomatic Elixir.
 * - Prevents warnings in Phoenix apps compiled with `--warnings-as-errors`.
 *
 * HOW
 * - Derive the application prefix conservatively from the surrounding module name:
 *   - If inside `<App>Web.*`, prefix is `<App>` (substring before `Web`).
 *   - If printing within `<App>.Repo` or nested below, prefix is substring before `.Repo`.
 *   - Otherwise, do not qualify (keeps non-Phoenix/core snapshots stable).
 * - Transform patterns:
 *   - `ERemoteCall(EVar(name), "new", [])` → `EStruct(<qualified name>, [])`
 *   - `ECall(EVar(name), "new", [])`      → `EStruct(<qualified name>, [])`
 * - Skip if `name` already qualified (contains `.`).
 *
 * EXAMPLES
 * Haxe:
 *   var todo = new Todo();
 * Elixir (before):
 *   Todo.new()
 * Elixir (after inside TodoAppWeb.*):
 *   %TodoApp.Todo{}
 * Elixir (after outside Phoenix context):
 *   %Todo{}
 */
class ModuleNewToStructLiteral {
    public static function moduleNewToStructLiteralPass(ast: ElixirAST): ElixirAST {
        // Helper: derive app prefix from an Elixir module name
        inline function derivePrefix(modName: String): Null<String> {
            var iWeb = modName.indexOf("Web");
            if (iWeb > 0) return modName.substring(0, iWeb);
            var iRepo = modName.indexOf(".Repo");
            if (iRepo > 0) return modName.substring(0, iRepo);
            return null;
        }

        // Rewriter for a subtree with a fixed appPrefix in scope
        function rewrite(node: ElixirAST, appPrefix: Null<String>): ElixirAST {
            return ElixirASTTransformer.transformNode(node, function(n) {
                return switch (n.def) {
                    case EStruct(modName, fields) if (appPrefix != null && modName.indexOf('.') == -1):
                        // Qualify bare struct literals inside <App>Web.* to %<App>.Module{}
                        makeASTWithMeta(EStruct(appPrefix + "." + modName, fields), n.metadata, n.pos);
                    case ERemoteCall(module, funcName, args) if (funcName == "new" && args.length == 0 && appPrefix != null):
                        switch (module.def) {
                            case EVar(name):
                                // Only rewrite when prefix is known (Web/Repo/Schema contexts)
                                var full = (name.indexOf('.') == -1) ? appPrefix + "." + name : name;
                                makeASTWithMeta(EStruct(full, []), n.metadata, n.pos);
                            default:
                                n; // Leave other module expressions as-is
                        }
                    case ECall(target, funcName, args) if (funcName == "new" && args.length == 0 && appPrefix != null):
                        switch (target.def) {
                            case EVar(name):
                                var full = (name.indexOf('.') == -1) ? appPrefix + "." + name : name;
                                makeASTWithMeta(EStruct(full, []), n.metadata, n.pos);
                            default:
                                n;
                        }
                    default:
                        n;
                }
            });
        }

        // Walk top-level to capture module context and apply the rewriter inside
        return ElixirASTTransformer.transformNode(ast, function(n) {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var prefix = derivePrefix(name);
                    var newBody: Array<ElixirAST> = [];
                    for (b in body) newBody.push(rewrite(b, prefix));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var prefix = derivePrefix(name);
                    var newDo = rewrite(doBlock, prefix);
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    // Outside module context: do not qualify, but still allow local rewrite (no prefix)
                    rewrite(n, null);
            }
        });
    }
}

#end
