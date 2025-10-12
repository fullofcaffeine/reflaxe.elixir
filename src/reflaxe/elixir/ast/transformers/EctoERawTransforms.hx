package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
using StringTools;

/**
 * ERawEctoFromQualification
 *
 * WHAT
 * - Qualifies Ecto.Query.from/2 ERaw snippets that use table atoms like :user,
 *   rewriting `t in :user` to `t in <App>.User`.
 *
 * WHY
 * - Some builders emit `require Ecto.Query; Ecto.Query.from(t in :user, ...)` as ERaw.
 *   Elixir warns because `:user.__schema__/1` is undefined. Using the schema module
 *   (<App>.User) is idiomatic and removes warnings.
 *
 * HOW
 * - Within modules, derive application name from -D app_name via PhoenixMapper.
 * - Replace occurrences of ` in :user` with ` in <App>.User` in ERaw code segments
 *   when the snippet contains `Ecto.Query.from(`.
 * - Conservative single-token replacement to avoid unintended changes.
 *
 * EXAMPLES
 *   Ecto.Query.from(t in :user, [])      -> Ecto.Query.from(t in MyApp.User, [])
 */
class EctoERawTransforms {
    public static function erawEctoFromQualificationPass(ast: ElixirAST): ElixirAST {
        inline function qualify(code: String, app: String): String {
            if (code.indexOf("Ecto.Query.from(") == -1) return code;
            var out = new StringBuf();
            var i = 0;
            while (i < code.length) {
                if (i + 5 < code.length && code.substr(i, 5) == " in :") {
                    // capture atom name
                    var j = i + 5;
                    var name = new StringBuf();
                    while (j < code.length) {
                        var ch = code.charAt(j);
                        var isAlnum = ~/^[A-Za-z0-9_]$/.match(ch);
                        if (!isAlnum) break;
                        name.add(ch);
                        j++;
                    }
                    var raw = name.toString();
                    if (raw.length > 0) {
                        // PascalCase
                        var parts = raw.split("_");
                        var pas = [];
                        for (p in parts) if (p.length > 0) pas.push(p.charAt(0).toUpperCase() + p.substr(1));
                        out.add(" in "); out.add(app); out.add("."); out.add(pas.join(""));
                        i = j; continue;
                    }
                }
                out.add(code.charAt(i));
                i++;
            }
            return out.toString();
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var app = (function() {
                        #if macro
                        try {
                            var d = haxe.macro.Compiler.getDefine("app_name");
                            if (d != null && d.length > 0) return d; 
                        } catch (e:Dynamic) {}
                        #end
                        return reflaxe.elixir.PhoenixMapper.getAppModuleName();
                    })();
                    var newBody: Array<ElixirAST> = [];
                    for (b in body) newBody.push(ElixirASTTransformer.transformNode(b, function(x) {
                        return switch (x.def) {
                            case ERaw(code):
                                var q = qualify(code, app);
                                q != code ? makeASTWithMeta(ERaw(q), x.metadata, x.pos) : x;
                            default: x;
                        }
                    }));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var app = (function() {
                        #if macro
                        try {
                            var d = haxe.macro.Compiler.getDefine("app_name");
                            if (d != null && d.length > 0) return d; 
                        } catch (e:Dynamic) {}
                        #end
                        return reflaxe.elixir.PhoenixMapper.getAppModuleName();
                    })();
                    var newDo = ElixirASTTransformer.transformNode(doBlock, function(x) {
                        return switch (x.def) {
                            case ERaw(code):
                                var q = qualify(code, app);
                                q != code ? makeASTWithMeta(ERaw(q), x.metadata, x.pos) : x;
                            default: x;
                        }
                    });
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * FromInAtomQualification
     *
     * WHAT
     * - Rewrites Ecto.Query.from arguments of the shape `t in :table` to
     *   `t in <App>.CamelCase` when the right side is an atom table name.
     *
     * WHY
     * - Ecto expects `from t in SchemaModule` for schema queries. Using `:table`
     *   causes `:table.__schema__/1` undefined warnings and breaks WAE.
     * - Some builders do not emit ERaw for `from`, so the ERaw string pass does
     *   not catch these cases; this AST pass handles the structured form.
     *
     * HOW
     * - Walk ERemoteCall nodes where module is `Ecto.Query` and function is `from`.
     * - If an argument contains `EBinary(In, left, right)` and `right` is `EAtom(":name")`,
     *   replace `right` with a qualified module name `<App>.<CamelCase(name)>` using app_name.
     * - Conservative: only transform when right is a plain atom (no dots), and do not
     *   re-qualify if already an EVar with a dot.
     *
     * EXAMPLES
     *   Ecto.Query.from(t in :user, [])       -> Ecto.Query.from(t in MyApp.User, [])
     *   Ecto.Query.from(p in :blog_post, [])  -> Ecto.Query.from(p in MyApp.BlogPost, [])
     */
    public static function fromInAtomQualificationPass(ast: ElixirAST): ElixirAST {
        inline function camelize(s: String): String {
            var parts = s.split("_");
            var out = [];
            for (p in parts) if (p.length > 0) out.push(p.charAt(0).toUpperCase() + p.substr(1));
            return out.join("");
        }
        var app = (function() {
            #if macro
            try {
                var d = haxe.macro.Compiler.getDefine("app_name");
                if (d != null && d.length > 0) return d;
            } catch (e:Dynamic) {}
            #end
            return reflaxe.elixir.PhoenixMapper.getAppModuleName();
        })();
        if (app == null || app.length == 0) return ast;

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, fn, args) if (fn == "from" && args != null && args.length >= 1):
                    // Ensure module is Ecto.Query (string compare on printed module)
                    var modStr = switch (mod.def) {
                        case EVar(rn): rn;
                        default: reflaxe.elixir.ast.ElixirASTPrinter.printAST(mod);
                    };
                    if (modStr != "Ecto.Query") return n;

                    // Rewrite first arg if it's an `in` binary with atom on the right
                    var a0 = args[0];
                    switch (a0.def) {
                        case EBinary(In, left, right):
                            switch (right.def) {
                                case EAtom(atomVal):
                                    var raw = Std.string(atomVal);
                                    // Only plain atoms without dots
                                    if (raw.indexOf('.') == -1) {
                                        var qual = app + "." + camelize(raw);
                                        var newRight = makeAST(EVar(qual));
                                        var newA0 = makeAST(EBinary(In, left, newRight));
                                        var newArgs = args.copy();
                                        newArgs[0] = newA0;
                                        makeASTWithMeta(ERemoteCall(mod, fn, newArgs), n.metadata, n.pos);
                                    } else n;
                                default:
                                    n;
                            }
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
