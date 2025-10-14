package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FilterPredicateInlineQueryTransforms
 *
 * WHAT
 * - Late pass to inline `query` references inside Enum.filter predicate EFns to
 *   `String.downcase(search_query)`. Used as a deterministic fallback when binder
 *   integrity is not guaranteed by earlier passes.
 *
 * WHY
 * - Ensures no runtime undefined `query` in predicates even if binder was removed
 *   by hygiene or reordering.
 */
class FilterPredicateInlineQueryTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        var repl = makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar("search_query"))]));
        function replaceInBody(body: ElixirAST): ElixirAST {
            return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
                return switch (x.def) {
                    case EVar(nm) if (nm == "query"): repl;
                    case ERaw(code) if (code != null && rawContainsIdent(code, "query")):
                        var newCode = replaceIdent(code, "query", "String.downcase(search_query)");
                        makeAST(ERaw(newCode));
                    default: x;
                };
            });
        }
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERaw(code) if (code != null && code.indexOf('Enum.filter(') != -1 && rawContainsIdent(code, 'query')):
                    var newCode = replaceIdent(code, 'query', 'String.downcase(search_query)');
                    #if debug_filter_query_consolidate
                    Sys.println('[FilterPredicateInlineQuery] Inlined query inside ERaw Enum.filter statement');
                    #end
                    makeAST(ERaw(newCode));
                case ERemoteCall(mod, "filter", args) if (args != null && args.length == 2):
                    #if debug_filter_query_consolidate
                    Sys.println('[FilterPredicateInlineQuery] Considering Enum.filter(remote)');
                    #end
                    switch (args[1].def) {
                        case EFn(cs) if (cs.length == 1):
                            var cl = cs[0];
                            var newBody = replaceInBody(cl.body);
                            var newFn = makeAST(EFn([{ args: cl.args, guard: cl.guard, body: newBody }]));
                            #if debug_filter_query_consolidate
                            Sys.println('[FilterPredicateInlineQuery] Inlined query in Enum.filter EFn');
                            #end
                            makeASTWithMeta(ERemoteCall(mod, "filter", [args[0], newFn]), n.metadata, n.pos);
                        default: n;
                    }
                case ECall(tgt, "filter", args2) if (args2 != null && args2.length >= 1):
                    #if debug_filter_query_consolidate
                    Sys.println('[FilterPredicateInlineQuery] Considering Enum.filter(call)');
                    #end
                    var predArg = args2[args2.length - 1];
                    switch (predArg.def) {
                        case EFn(cs2) if (cs2.length == 1):
                            var cl2 = cs2[0];
                            var newBody2 = replaceInBody(cl2.body);
                            var newFn2 = makeAST(EFn([{ args: cl2.args, guard: cl2.guard, body: newBody2 }]));
                            var prefix = args2.slice(0, args2.length - 1);
                            #if debug_filter_query_consolidate
                            Sys.println('[FilterPredicateInlineQuery] Inlined query in call.filter EFn');
                            #end
                            makeASTWithMeta(ECall(tgt, "filter", prefix.concat([newFn2])), n.metadata, n.pos);
                        default: n;
                    }
                default: n;
            }
        });
    }

    static inline function isIdentChar(c: String): Bool {
        if (c == null || c.length == 0) return false;
        var ch = c.charCodeAt(0);
        return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
    }
    static function rawContainsIdent(code: String, ident: String): Bool {
        if (code == null || ident == null || ident.length == 0) return false;
        var start = 0; var len = ident.length;
        while (true) {
            var i = code.indexOf(ident, start);
            if (i == -1) break;
            var before = i > 0 ? code.substr(i - 1, 1) : null;
            var afterIdx = i + len;
            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
            if (!isIdentChar(before) && !isIdentChar(after)) return true;
            start = i + len;
        }
        return false;
    }
    static function replaceIdent(code: String, ident: String, replacement: String): String {
        if (code == null || ident == null || ident.length == 0) return code;
        var sb = new StringBuf();
        var start = 0; var len = ident.length;
        while (true) {
            var i = code.indexOf(ident, start);
            if (i == -1) {
                sb.add(code.substr(start));
                break;
            }
            var before = i > 0 ? code.substr(i - 1, 1) : null;
            var afterIdx = i + len;
            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
            if (!isIdentChar(before) && !isIdentChar(after)) {
                sb.add(code.substr(start, i - start));
                sb.add(replacement);
                start = i + len;
            } else {
                sb.add(code.substr(start, (i + 1) - start));
                start = i + 1;
            }
        }
        return sb.toString();
    }
}

#end
