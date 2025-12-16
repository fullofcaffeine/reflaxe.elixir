package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirNaming;

/**
 * LocalVarNameNormalizeTransforms
 *
 * WHAT
 * - Normalizes local variable names and pattern binders that contain camelCase
 *   segments into idiomatic Elixir `snake_case`.
 *
 * WHY
 * - Some builder/transform paths can accidentally reintroduce camelCase locals
 *   (e.g. `invalidEmail`) even though Elixir locals should be snake_case
 *   (e.g. `invalid_email`). This drift can:
 *   - create undefined variable references when a declaration is snake_case but a
 *     reference is camelCase
 *   - confuse binder alignment passes (which may attempt to "fix" by renaming
 *     unrelated binders)
 *
 * HOW
 * - Traverse the ElixirAST and:
 *   - Rewrite `EVar(name)` when `name` starts lower/underscore and contains any
 *     uppercase letter → `ElixirNaming.toVarName(name)`
 *   - Rewrite `PVar(name)` similarly (patterns are not visited by transformNode,
 *     so we normalize them explicitly for nodes that carry patterns)
 * - Module references (UpperCamel) are left untouched.
 *
 * EXAMPLES
 * Before:
 *   invalid_email = invalid_emails[0]
 *   Log.trace("bad \"" <> invalidEmail <> "\"", meta)
 * After:
 *   invalid_email = invalid_emails[0]
 *   Log.trace("bad \"" <> invalid_email <> "\"", meta)
 */
class LocalVarNameNormalizeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        function normalizeTree(node:ElixirAST):ElixirAST {
            if (node == null || node.def == null) return node;

            // First normalize children (including ERaw nodes) using transformAST recursion.
            var withChildren = ElixirASTTransformer.transformAST(node, normalizeTree);
            if (withChildren == null || withChildren.def == null) return withChildren;

            // Then normalize this node (and any patterns it carries).
            return switch (withChildren.def) {
                case EVar(name) if (shouldNormalizeLocal(name)):
                    makeASTWithMeta(EVar(ElixirNaming.toVarName(name)), withChildren.metadata, withChildren.pos);

                // Some paths represent interpolation expressions as ERaw identifiers.
                // When the ERaw is a single identifier token, normalize it like a local variable.
                case ERaw(code) if (isSimpleIdent(code) && shouldNormalizeLocal(code)):
                    makeASTWithMeta(EVar(ElixirNaming.toVarName(code)), withChildren.metadata, withChildren.pos);

                case EDef(name, args, guards, body):
                    makeASTWithMeta(
                        EDef(name, args.map(normalizePattern), guards, body),
                        withChildren.metadata,
                        withChildren.pos
                    );

                case EDefp(name, args, guards, body):
                    makeASTWithMeta(
                        EDefp(name, args.map(normalizePattern), guards, body),
                        withChildren.metadata,
                        withChildren.pos
                    );

                case EFn(clauses):
                    makeASTWithMeta(
                        EFn(clauses.map(cl -> {
                            args: cl.args.map(normalizePattern),
                            guard: cl.guard,
                            body: cl.body
                        })),
                        withChildren.metadata,
                        withChildren.pos
                    );

                case EMatch(pat, expr):
                    makeASTWithMeta(EMatch(normalizePattern(pat), expr), withChildren.metadata, withChildren.pos);

                case EFor(generators, filters, body, into, uniq):
                    makeASTWithMeta(
                        EFor(
                            generators.map(g -> { pattern: normalizePattern(g.pattern), expr: g.expr }),
                            filters,
                            body,
                            into,
                            uniq
                        ),
                        withChildren.metadata,
                        withChildren.pos
                    );

                case ECase(expr, clauses):
                    makeASTWithMeta(
                        ECase(
                            expr,
                            clauses.map(cl -> {
                                pattern: normalizePattern(cl.pattern),
                                guard: cl.guard,
                                body: cl.body
                            })
                        ),
                        withChildren.metadata,
                        withChildren.pos
                    );

                case EWith(clauses, doBlock, elseBlock):
                    makeASTWithMeta(
                        EWith(
                            clauses.map(c -> { pattern: normalizePattern(c.pattern), expr: c.expr }),
                            doBlock,
                            elseBlock
                        ),
                        withChildren.metadata,
                        withChildren.pos
                    );

                case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
                    makeASTWithMeta(
                        ETry(
                            body,
                            rescueClauses.map(r -> {
                                pattern: normalizePattern(r.pattern),
                                varName: r.varName,
                                body: r.body
                            }),
                            catchClauses.map(c -> {
                                kind: c.kind,
                                pattern: normalizePattern(c.pattern),
                                body: c.body
                            }),
                            afterBlock,
                            elseBlock
                        ),
                        withChildren.metadata,
                        withChildren.pos
                    );

                case EReceive(clauses, afterClause):
                    makeASTWithMeta(
                        EReceive(
                            clauses.map(cl -> {
                                pattern: normalizePattern(cl.pattern),
                                guard: cl.guard,
                                body: cl.body
                            }),
                            afterClause
                        ),
                        withChildren.metadata,
                        withChildren.pos
                    );

                default:
                    withChildren;
            }
        }

        return normalizeTree(ast);
    }

    static function shouldNormalizeLocal(name: String): Bool {
        if (name == null || name.length == 0) return false;
        var first = name.charAt(0);
        // Only locals (lowercase/underscore) — module references are UpperCamel.
        var isLocalLike = (first.toLowerCase() == first) || first == "_";
        return isLocalLike && hasUppercase(name);
    }

    static function hasUppercase(name: String): Bool {
        for (i in 0...name.length) {
            var c = name.charCodeAt(i);
            if (c >= 'A'.code && c <= 'Z'.code) return true;
        }
        return false;
    }

    static function isSimpleIdent(code: String): Bool {
        if (code == null || code.length == 0) return false;
        // Reject any whitespace or obvious operators.
        for (i in 0...code.length) {
            var ch = code.charAt(i);
            if (ch == " " || ch == "\t" || ch == "\n" || ch == "\r") return false;
            if (ch == "(" || ch == ")" || ch == "," || ch == "." || ch == ":" || ch == "[" || ch == "]") return false;
            if (ch == "+" || ch == "-" || ch == "*" || ch == "/" || ch == "<" || ch == ">" || ch == "=" || ch == "|") return false;
        }
        // Must start with letter or underscore and contain only identifier chars.
        var first = code.charCodeAt(0);
        var startsOk = (first >= 'A'.code && first <= 'Z'.code) || (first >= 'a'.code && first <= 'z'.code) || first == '_'.code;
        if (!startsOk) return false;
        for (i in 0...code.length) {
            var c = code.charCodeAt(i);
            var ok = (c >= 'A'.code && c <= 'Z'.code)
                || (c >= 'a'.code && c <= 'z'.code)
                || (c >= '0'.code && c <= '9'.code)
                || c == '_'.code;
            if (!ok) return false;
        }
        return true;
    }

    static function normalizePattern(p: EPattern): EPattern {
        return switch (p) {
            case PVar(name) if (shouldNormalizeLocal(name)):
                PVar(ElixirNaming.toVarName(name));
            case PTuple(parts):
                PTuple(parts.map(normalizePattern));
            case PList(parts2):
                PList(parts2.map(normalizePattern));
            case PCons(h, t):
                PCons(normalizePattern(h), normalizePattern(t));
            case PMap(kvs):
                PMap([for (kv in kvs) { key: kv.key, value: normalizePattern(kv.value) }]);
            case PStruct(mod, fields):
                PStruct(mod, [for (f in fields) { key: f.key, value: normalizePattern(f.value) }]);
            case PAlias(name2, inner) if (shouldNormalizeLocal(name2)):
                PAlias(ElixirNaming.toVarName(name2), normalizePattern(inner));
            case PAlias(name3, inner3):
                PAlias(name3, normalizePattern(inner3));
            case PPin(inner4):
                PPin(normalizePattern(inner4));
            default:
                p;
        }
    }
}

#end
