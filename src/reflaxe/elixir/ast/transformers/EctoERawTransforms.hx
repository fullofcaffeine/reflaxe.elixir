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
    static inline function toSnakeAtom(s: String): String {
        if (s == null || s.length == 0) return s;
        var out = new StringBuf();
        for (i in 0...s.length) {
            var ch = s.charAt(i);
            var isUpper = ch.toUpperCase() == ch && ch.toLowerCase() != ch;
            if (isUpper && i > 0) out.add("_");
            out.add(ch.toLowerCase());
        }
        return out.toString();
    }

    static function atomizeValidateRequired(code: String): String {
        // Replace all occurrences of Enum.map(["a","b"], &String.to_atom/1) → [:a, :b]
        var out = new StringBuf();
        var i = 0;
        while (i < code.length) {
            // Find start of Enum.map([
            var idx = code.indexOf("Enum.map([", i);
            if (idx == -1) {
                out.add(code.substr(i));
                break;
            }
            // Copy up to idx
            out.add(code.substr(i, idx - i));
            var start = idx + "Enum.map([".length;
            var endBracket = code.indexOf("]", start);
            if (endBracket == -1) { out.add(code.substr(idx)); break; }
            // Expect "," then optional spaces then &String.to_atom/1 before next ')'
            var limit = endBracket + 40;
            if (limit > code.length) limit = code.length;
            var afterList = code.substring(endBracket + 1, limit);
            if (afterList.indexOf("&String.to_atom/1") == -1 && afterList.indexOf("&String.to_existing_atom/1") == -1) {
                // Not our pattern; copy and continue
                out.add(code.substr(idx, endBracket + 1 - idx));
                i = endBracket + 1;
                continue;
            }
            // Extract items between [ and ]
            var listStr = code.substring(start, endBracket);
            var items = [];
            var p = 0;
            while (p < listStr.length) {
                var ch = listStr.charAt(p);
                if (ch == ' ' || ch == ',') { p++; continue; }
                if (ch == '"') {
                    var j = p + 1;
                    var buf = new StringBuf();
                    while (j < listStr.length) {
                        var c = listStr.charAt(j);
                        if (c == '"') break;
                        buf.add(c);
                        j++;
                    }
                    items.push(":" + toSnakeAtom(buf.toString()));
                    p = j + 1;
                } else {
                    // Non-literal entry; abort replacement for this occurrence
                    items = null;
                    break;
                }
            }
            if (items == null) {
                out.add(code.substr(idx, endBracket + 1 - idx));
                i = endBracket + 1;
                continue;
            }
            // Skip to closing ')' of Enum.map
            var close = code.indexOf(")", endBracket);
            if (close == -1) { out.add(code.substr(idx)); break; }
            out.add("[" + items.join(", ") + "]");
            i = close + 1;
        }
        return out.toString();
    }

    static function atomizeStringToAtomCalls(code: String): String {
        // Replace String.to_atom("Field") with :field (snake)
        var out = new StringBuf();
        var i = 0;
        while (i < code.length) {
            if (i + 17 < code.length && code.substr(i, 17) == "String.to_atom(\"") {
                var j = i + 17;
                var buf = new StringBuf();
                while (j < code.length) {
                    var c = code.charAt(j);
                    if (c == '"') break;
                    buf.add(c);
                    j++;
                }
                if (j < code.length && code.charAt(j) == '"') {
                    var val = ":" + toSnakeAtom(buf.toString());
                    // Expect closing ")
                    var k = j + 2; // skip ")
                    out.add(val);
                    i = k;
                    continue;
                }
            }
            out.add(code.charAt(i));
            i++;
        }
        return out.toString();
    }

    /**
     * normalizeOptsComparisons
     *
     * WHAT
     * - Normalize all occurrences of opts.<key> ==/!= nil to Kernel.is_nil(Map.get(opts, :<key>))
     *   and rewrite bare opts.<key> and opts[:key] to Map.get(opts, :key) within ERaw strings.
     *
     * WHY
     * - Guard-safe, idiomatic comparisons and consistent Map.get usage across all shapes
     *   (dot access, bracket atom access) even when emitted as ERaw by late injections.
     */
    static function normalizeOptsComparisons(code: String): String {
        var out = new StringBuf();
        var i = 0;
        inline function isIdentChar(c:String):Bool return ~/^[A-Za-z0-9_]$/.match(c);
        while (i < code.length) {
            // Handle opts.<ident>
            if (i + 5 < code.length && code.substr(i, 5) == 'opts.' ) {
                var j = i + 5;
                var key = new StringBuf();
                // parse identifier
                if (j < code.length && (~/^[A-Za-z_]$/.match(code.charAt(j)))) {
                    while (j < code.length && isIdentChar(code.charAt(j))) {
                        key.add(code.charAt(j));
                        j++;
                    }
                    var k = key.toString();
                    // Peek ahead for == nil / != nil
                    var look = code.substr(j).ltrim();
                    if (look.startsWith('== nil')) {
                        out.add('Kernel.is_nil(Map.get(opts, :' + k + '))');
                        // advance i to after 'opts.key' then skip matched '== nil'
                        var skip = j - i;
                        i += skip;
                        // skip whitespace then '== nil'
            var t = i;
            while (t < code.length) {
                var ch = code.charAt(t);
                if (ch == ' ' || ch == '\n' || ch == '\t' || ch == '\r') t++; else break;
            }
                        if (t + 6 <= code.length && code.substr(t, 6) == '== nil') { i = t + 6; } else { i = t; }
                        continue;
                    } else if (look.startsWith('!= nil')) {
                        out.add('not Kernel.is_nil(Map.get(opts, :' + k + '))');
                        var skip2 = j - i;
                        i += skip2;
            var t2 = i;
            while (t2 < code.length) {
                var ch2 = code.charAt(t2);
                if (ch2 == ' ' || ch2 == '\n' || ch2 == '\t' || ch2 == '\r') t2++; else break;
            }
                        if (t2 + 6 <= code.length && code.substr(t2, 6) == '!= nil') { i = t2 + 6; } else { i = t2; }
                        continue;
                    } else {
                        out.add('Map.get(opts, :' + k + ')');
                        i = j;
                        continue;
                    }
                }
            }
            // Handle opts[:key]
            if (i + 6 < code.length && code.substr(i, 6) == 'opts:[') {
                var j2 = i + 6;
                // Expect atom-like key: key]
                if (j2 < code.length && code.charAt(j2) == ':') j2++;
                var key2 = new StringBuf();
                while (j2 < code.length && isIdentChar(code.charAt(j2))) {
                    key2.add(code.charAt(j2));
                    j2++;
                }
                if (j2 < code.length && code.charAt(j2) == ']') {
                    j2++;
                    var k2 = key2.toString();
                    var look2 = code.substr(j2).ltrim();
                    if (look2.startsWith('== nil')) {
                        out.add('Kernel.is_nil(Map.get(opts, :' + k2 + '))');
                        i = j2;
                    var t3 = i;
                    while (t3 < code.length) {
                        var ch3 = code.charAt(t3);
                        if (ch3 == ' ' || ch3 == '\n' || ch3 == '\t' || ch3 == '\r') t3++; else break;
                    }
                        if (t3 + 6 <= code.length && code.substr(t3, 6) == '== nil') { i = t3 + 6; } else { i = t3; }
                        continue;
                    } else if (look2.startsWith('!= nil')) {
                        out.add('not Kernel.is_nil(Map.get(opts, :' + k2 + '))');
                        i = j2;
                    var t4 = i;
                    while (t4 < code.length) {
                        var ch4 = code.charAt(t4);
                        if (ch4 == ' ' || ch4 == '\n' || ch4 == '\t' || ch4 == '\r') t4++; else break;
                    }
                        if (t4 + 6 <= code.length && code.substr(t4, 6) == '!= nil') { i = t4 + 6; } else { i = t4; }
                        continue;
                    } else {
                        out.add('Map.get(opts, :' + k2 + ')');
                        i = j2;
                        continue;
                    }
                }
            }
            out.add(code.charAt(i));
            i++;
        }
        return out.toString();
    }

    /**
     * atomizeValidateLengthFieldArg
     *
     * WHAT
     * - In ERaw code, rewrite validate_length(..., "field", ...) to use a literal atom :field
     *   as the second argument, preserving the first argument (changeset expression) even when
     *   it contains nested calls.
     *
     * HOW
     * - Scan for validate_length(, parse the first argument with paren depth, then if the next
     *   token is a string literal, replace it by :snake_case(field).
     */
    static function atomizeValidateLengthFieldArg(code: String): String {
        var out = new StringBuf();
        var i = 0;
        inline function toSnake(s:String):String {
            var b = new StringBuf();
            for (k in 0...s.length) {
                var ch = s.charAt(k);
                var isUpper = ch.toUpperCase() == ch && ch.toLowerCase() != ch;
                if (isUpper && k > 0) b.add('_');
                b.add(ch.toLowerCase());
            }
            return b.toString();
        }
        while (i < code.length) {
            var idx = code.indexOf('validate_length(', i);
            if (idx == -1) { out.add(code.substr(i)); break; }
            // copy prefix
            out.add(code.substr(i, idx - i));
            out.add('validate_length(');
            var j = idx + 'validate_length('.length;
            // parse first argument respecting nested parens
            var depth = 0;
            var consumed = new StringBuf();
            var doneFirst = false;
            while (j < code.length && !doneFirst) {
                var ch = code.charAt(j);
                if (ch == '(') depth++;
                if (ch == ')') depth--;
                if (ch == ',' && depth == 0) { doneFirst = true; j++; break; }
                consumed.add(ch);
                j++;
            }
            // emit first arg
            out.add(consumed.toString());
            out.add(', ');
            // skip whitespace
            while (j < code.length) {
                var sch = code.charAt(j);
                if (sch == ' ' || sch == '\n' || sch == '\t' || sch == '\r') j++; else break;
            }
            // if next is string literal, atomize
            if (j < code.length && code.charAt(j) == '"') {
                var q = j + 1;
                var sb = new StringBuf();
                while (q < code.length) {
                    var c = code.charAt(q);
                    if (c == '"') break;
                    sb.add(c);
                    q++;
                }
                var lit = ':' + toSnake(sb.toString());
                out.add(lit);
                j = q + 1;
            } else {
                // no change
                out.add(code.charAt(j));
                j++;
            }
            i = j;
        }
        return out.toString();
    }
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
     * ERawValidateAtomNormalize
     *
     * WHAT
     * - Normalize ERaw validate_required/validate_length snippets to use literal atoms
     *   when lists/strings are static.
     *
     * HOW
     * - For validate_required: Enum.map(["a","b"], &String.to_atom/1) => [:a, :b]
     * - For String.to_atom("Field") => :field (snake case)
     */
    public static function erawEctoValidateAtomNormalizePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERaw(code):
                    var c1 = atomizeValidateRequired(code);
                    var c2 = atomizeStringToAtomCalls(c1);
                    var c2b = atomizeValidateLengthFieldArg(c2);
                    var c3 = normalizeOptsComparisons(c2b);
                    c3 != code ? makeASTWithMeta(ERaw(c3), n.metadata, n.pos) : n;
                default:
                    n;
            }
        });
    }

    /**
     * ERawEctoQueryableToSchema
     *
     * WHAT
     * - Rewrite ERaw occurrences of Ecto.Queryable.to_query(:atom) to <App>.<CamelCase(atom)
     *
     * WHY
     * - Passing bare atoms to to_query is invalid; ensure schema module is used even in ERaw code.
     */
    public static function erawEctoQueryableToSchemaPass(ast: ElixirAST): ElixirAST {
        inline function camelize(s: String): String {
            var parts = s.split("_");
            var out = [];
            for (p in parts) if (p.length > 0) out.push(p.charAt(0).toUpperCase() + p.substr(1));
            return out.join("");
        }
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var app = name != null && name.indexOf("Web") > 0 ? name.substring(0, name.indexOf("Web")) : reflaxe.elixir.PhoenixMapper.getAppModuleName();
                    var newBody = [for (b in body) ElixirASTTransformer.transformNode(b, function(x: ElixirAST): ElixirAST {
                        return switch (x.def) {
                            case ERaw(code):
                                var out = code;
                                var pattern = "Ecto.Queryable.to_query(:";
                                var idx = out.indexOf(pattern);
                                if (idx != -1 && app != null) {
                                    var start = idx + pattern.length;
                                    var j = start;
                                    var nameBuf = new StringBuf();
                                    while (j < out.length) {
                                        var ch = out.charAt(j);
                                        if (!~/^[A-Za-z0-9_]$/.match(ch)) break;
                                        nameBuf.add(ch);
                                        j++;
                                    }
                                    if (j < out.length && out.charAt(j) == ')') {
                                        var atom = nameBuf.toString();
                                        var repl = "Ecto.Queryable.to_query(" + app + "." + camelize(atom) + ")";
                                        out = out.substring(0, idx) + repl + out.substring(j + 1);
                                    }
                                }
                                out != code ? makeASTWithMeta(ERaw(out), x.metadata, x.pos) : x;
                            default:
                                x;
                        }
                    })];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var app2 = name != null && name.indexOf("Web") > 0 ? name.substring(0, name.indexOf("Web")) : reflaxe.elixir.PhoenixMapper.getAppModuleName();
                    var newDo = ElixirASTTransformer.transformNode(doBlock, function(x: ElixirAST): ElixirAST {
                        return switch (x.def) {
                            case ERaw(code):
                                var out = code;
                                var pattern = "Ecto.Queryable.to_query(:";
                                var idx = out.indexOf(pattern);
                                if (idx != -1 && app2 != null) {
                                    var start = idx + pattern.length;
                                    var j = start;
                                    var nameBuf = new StringBuf();
                                    while (j < out.length) {
                                        var ch = out.charAt(j);
                                        if (!~/^[A-Za-z0-9_]$/.match(ch)) break;
                                        nameBuf.add(ch);
                                        j++;
                                    }
                                    if (j < out.length && out.charAt(j) == ')') {
                                        var atom = nameBuf.toString();
                                        var repl = "Ecto.Queryable.to_query(" + app2 + "." + camelize(atom) + ")";
                                        out = out.substring(0, idx) + repl + out.substring(j + 1);
                                    }
                                }
                                out != code ? makeASTWithMeta(ERaw(out), x.metadata, x.pos) : x;
                            default:
                                x;
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
