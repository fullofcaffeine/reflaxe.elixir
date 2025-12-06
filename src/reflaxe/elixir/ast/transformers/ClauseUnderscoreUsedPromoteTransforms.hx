package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * ClauseUnderscoreUsedPromoteTransforms
 *
 * WHAT
 * - In case clauses where a payload binder starts with an underscore (e.g., _value)
 *   and that underscored name is referenced in the clause body, promote the binder
 *   to its base name (value) and rewrite all body references accordingly.
 *
 * WHY
 * - Elixir warns if underscored variables are used after being set. Some earlier
 *   hygiene passes may underscore binders conservatively; if the binder is actually
 *   used in the body, we should restore the base name to silence warnings while
 *   preserving clarity.
 *
 * HOW
 * - For each ECase clause:
 *   - Collect pattern binders; if exactly one payload binder exists and starts with '_',
 *     and the body references that exact underscored name, rewrite the pattern binder
 *     to its trimmed base and replace EVar("_name") with EVar("name") in the body.
 */
class ClauseUnderscoreUsedPromoteTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var binder = extractSingleBinder(cl.pattern);
                        if (binder != null && binder.length > 1 && binder.charAt(0) == '_') {
                            // Preserve canonical {:tag, _value} + alias lines; do not promote _value
                            if (binder == "_value") { newClauses.push(cl); continue; }
                            var base = binder.substr(1);
                            if ((bodyUsesVar(cl.body, binder) || bodyUsesVar(cl.body, base)) && !patternHasName(cl.pattern, base)) {
                                #if debug_ast_transformer
                                #end
                                var newPattern = renameBinder(cl.pattern, binder, base);
                                var newBody = replaceVar(cl.body, binder, base);
                                newClauses.push({ pattern: newPattern, guard: cl.guard, body: newBody });
                                continue;
                            }
                        }
                        newClauses.push(cl);
                    }
                    makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function extractSingleBinder(p: EPattern): Null<String> {
        return switch (p) {
            case PTuple(es) if (es.length == 2):
                switch (es[1]) { case PVar(n): n; default: null; }
            default: null;
        }
    }

    static function bodyUsesVar(body: ElixirAST, name: String): Bool {
        var found = false;
        // AST-level variable reads
        ASTUtils.walk(body, function(e: ElixirAST) {
            if (found || e == null || e.def == null) return;
            switch (e.def) {
                case EVar(v) if (v == name): found = true;
                case EString(s):
                    if (!found && containsInterpolatedIdent(s, name)) found = true;
                case ERaw(code):
                    if (!found && containsInterpolatedIdent(code, name)) found = true;
                default:
            }
        });
        return found;
    }

    static function containsInterpolatedIdent(src:String, ident:String):Bool {
        if (src == null || ident == null || ident.length == 0) return false;
        // Scan #{...} blocks and look for the identifier token inside
        var reBlock = new EReg("\\#\\{([^}]*)\\}", "g");
        var pos = 0;
        while (reBlock.matchSub(src, pos)) {
            var inner = reBlock.matched(1);
            // token scan
            var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
            var tpos = 0;
            while (tok.matchSub(inner, tpos)) {
                var id = tok.matched(0);
                if (id == ident) return true;
                tpos = tok.matchedPos().pos + tok.matchedPos().len;
            }
            pos = reBlock.matchedPos().pos + reBlock.matchedPos().len;
        }
        return false;
    }

    static function patternHasName(p: EPattern, name: String): Bool {
        var found = false;
        function walk(px: EPattern): Void {
            if (found) return;
            switch (px) {
                case PVar(n) if (n == name): found = true;
                case PTuple(es): for (e in es) walk(e);
                case PList(es): for (e in es) walk(e);
                case PCons(h, t): walk(h); walk(t);
                case PMap(kvs): for (kv in kvs) walk(kv.value);
                case PStruct(_, fs): for (f in fs) walk(f.value);
                case PPin(inner): walk(inner);
                default:
            }
        }
        walk(p);
        return found;
    }

    static function renameBinder(p: EPattern, from: String, to: String): EPattern {
        return switch (p) {
            case PTuple(es) if (es.length == 2):
                var left = es[0];
                var right = es[1];
                switch (right) {
                    case PVar(n) if (n == from): PTuple([left, PVar(to)]);
                    default: PTuple([left, renameBinder(right, from, to)]);
                }
            case PVar(n) if (n == from): PVar(to);
            case PTuple(es2): PTuple(es2.map(e -> renameBinder(e, from, to)));
            case PList(es3): PList(es3.map(e -> renameBinder(e, from, to)));
            case PCons(h, t): PCons(renameBinder(h, from, to), renameBinder(t, from, to));
            case PMap(kvs): PMap(kvs.map(kv -> { key: kv.key, value: renameBinder(kv.value, from, to) }));
            case PStruct(nm, fs): PStruct(nm, fs.map(f -> { key: f.key, value: renameBinder(f.value, from, to) }));
            case PPin(inner): PPin(renameBinder(inner, from, to));
            default: p;
        }
    }

    static function replaceVar(body: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
                default: x;
            }
        });
    }
}

#end
