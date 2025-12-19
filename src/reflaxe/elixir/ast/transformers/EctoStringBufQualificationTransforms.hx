package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoStringBufQualificationTransforms
 *
 * WHAT
 * - Qualifies bare StringBuf module calls to <App>.StringBuf in modules that
 *   define local Ecto Query DSL shims (defp from/3 or defp where/3).
 *
 * WHY
 * - Ecto query snapshots expect application-qualified references to StringBuf
 *   when building dynamic fragments inside DSL-generated strings, ensuring
 *   consistency with app-local utility modules.
 *
 * HOW
 * - Detect module-level presence of defp from/3 or where/3 (Ecto DSL shims).
 * - Rewrite ERemoteCall/ECall targets that are exactly EVar("StringBuf") into
 *   EVar("<App>.StringBuf") using PhoenixMapper to derive <App> or -D app_name.
 * - Skip when already qualified (contains '.') or when app prefix cannot be derived.
 *
 * EXAMPLES
 * Before:
 *   def get_active_posters(min_posts) do
 *     from("users", "u", %{having: "count(p.id) >= " <> StringBuf.to_string(min_posts)})
 *   end
 * After:
 *   def get_active_posters(min_posts) do
 *     from("users", "u", %{having: "count(p.id) >= " <> MyApp.StringBuf.to_string(min_posts)})
 *   end
 */
class EctoStringBufQualificationTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var hasShims = hasEctoShims(body);
                    if (!hasShims) return n;
                    var app = deriveAppPrefix(name);
                    if (app == null || app.length == 0) {
                        try app = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e) {}
                    }
                    if (app == null || app.length == 0) return n;
                    var newBody = [for (b in body) qualifyStringBuf(b, app)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var stmts: Array<ElixirAST> = switch (doBlock.def) {
                        case EBlock(ss): ss;
                        case EDo(ss): ss;
                        default: [doBlock];
                    };
                    var hasShims2 = hasEctoShims(stmts);
                    if (!hasShims2) return n;
                    var app2 = deriveAppPrefix(name);
                    if (app2 == null || app2.length == 0) {
                        try app2 = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e) {}
                    }
                    if (app2 == null || app2.length == 0) return n;
                    var newDo = makeAST(EBlock([for (s in stmts) qualifyStringBuf(s, app2)]));
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function hasEctoShims(body: Array<ElixirAST>): Bool {
        for (b in body) switch (b.def) {
            case EDefp(fname, args, _, _) if (fname == "from" || fname == "where"):
                return true;
            default:
        }
        return false;
    }

    static function deriveAppPrefix(moduleName: String): Null<String> {
        if (moduleName == null) return null;
        // Prefer exact prefix before Web, but allow plain modules too
        var idx = moduleName.indexOf("Web");
        if (idx > 0) return moduleName.substring(0, idx);
        return null;
    }

    static function qualifyStringBuf(node: ElixirAST, app: String): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(m: ElixirAST): ElixirAST {
            return switch (m.def) {
                case ERemoteCall({def: EVar(mod)}, func, args) if (mod == "StringBuf"):
                    makeASTWithMeta(ERemoteCall(makeAST(EVar(app + ".StringBuf")), func, args), m.metadata, m.pos);
                case ECall({def: EVar(mod)}, func, args) if (mod == "StringBuf"):
                    makeASTWithMeta(ERemoteCall(makeAST(EVar(app + ".StringBuf")), func, args), m.metadata, m.pos);
                default:
                    m;
            }
        });
    }
}

#end
