package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * UnderscoreVarTransforms
 *
 * WHAT
 * - Renames local variables declared with a leading underscore to their
 *   non-underscored form when the non-underscored name is actually referenced.
 *
 * WHY
 * - An underscored name in Elixir indicates intentional non-use. If the code
 *   later references `name` while the declaration is `_name`, compilation fails
 *   (undefined variable) or emits warnings. This pass makes declarations match
 *   the actual usage to keep code idiomatic and warning-free.
 *
 * HOW
 * - For each function body:
 *   1) Collect declared locals from match patterns and simple lhs matches.
 *   2) Collect referenced locals (EVar) in the body.
 *   3) For any declaration `_foo` where `foo` is referenced and `foo` is not
 *      declared, rename the declaration to `foo` and rewrite any `_foo`
 *      references to `foo` as well.
 *
 * EXAMPLES
 * Elixir before:
 *   _meta = %{...}
 *   Phoenix.Presence.track(self(), "users", key, meta)
 *
 * Elixir after:
 *   meta = %{...}
 *   Phoenix.Presence.track(self(), "users", key, meta)
 */
class UnderscoreVarTransforms {
    public static function removeUnderscoreFromUsedLocalsPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, params, guards, body):
                    var newBody = normalize(body);
                    makeASTWithMeta(EDef(name, params, guards, newBody), node.metadata, node.pos);
                case EDefp(name, params, guards, body):
                    var newBody = normalize(body);
                    makeASTWithMeta(EDefp(name, params, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function normalize(body: ElixirAST): ElixirAST {
        var declared = new Map<String, Bool>();
        var referenced = new Map<String, Bool>();

        // Collect declared (including EFn clause arguments)
        ASTUtils.walk(body, function(n: ElixirAST) {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(p, _): collectPatternDecls(p, declared);
                case EBinary(Match, left, _):
                    // Collect all vars on the left side, including nested chains a = b = c
                    collectLhsDecls(left, declared);
                case EFn(clauses):
                    for (cl in clauses) for (a in cl.args) collectPatternDecls(a, declared);
                default:
            }
        });

        // Collect referenced (closure-aware): only references belonging to this
        // function scope, counting free uses in nested closures and excluding
        // names shadowed by EFn binders / pattern bindings.
        referenced = VariableUsageCollector.referencedInFunctionScope(body);

        // Build rename map: _name -> name when name is referenced OR _name is referenced, and name is not declared
        // Guard: never rename the canonical case-payload binder `_value` (set by payload canonicalization)
        var rename = new Map<String, String>();
        for (k in declared.keys()) {
            if (k.length > 1 && k.charAt(0) == "_") {
                var base = k.substr(1);
                if (k == "_value") continue; // preserve canonical payload binder
                if ((referenced.exists(base) || referenced.exists(k)) && !declared.exists(base)) {
                    rename.set(k, base);
                }
            }
        }

        #if true
        if (Lambda.count(rename) > 0) {
        }
        #end
        if (Lambda.count(rename) == 0) return body;

        // Rewrite declarations and references
        function tx(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                case EMatch(p, rhs):
                    var newP = renamePattern(p, rename);
                    makeASTWithMeta(EMatch(newP, rhs), n.metadata, n.pos);
                case EBinary(Match, left, rhs):
                    // Recursively rename all EVar occurrences on the LHS
                    var newLeft = renameLhs(left, rename);
                    makeASTWithMeta(EBinary(Match, newLeft, rhs), n.metadata, n.pos);
                case EVar(v) if (rename.exists(v)):
                    makeASTWithMeta(EVar(rename.get(v)), n.metadata, n.pos);
                default:
                    n;
            }
        }

        return ElixirASTTransformer.transformNode(body, tx);
    }

    static function collectPatternDecls(p: EPattern, declared: Map<String, Bool>): Void {
        switch (p) {
            case PVar(n): declared.set(n, true);
            case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, declared);
            case PCons(h, t): collectPatternDecls(h, declared); collectPatternDecls(t, declared);
            case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, declared);
            case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, declared);
            case PPin(inner): collectPatternDecls(inner, declared);
            default:
        }
    }

    static function collectLhsDecls(lhs: ElixirAST, declared: Map<String, Bool>): Void {
        switch (lhs.def) {
            case EVar(n): declared.set(n, true);
            case EBinary(Match, l2, r2):
                collectLhsDecls(l2, declared);
                collectLhsDecls(r2, declared);
            default:
        }
    }

    static function renameLhs(lhs: ElixirAST, rename: Map<String, String>): ElixirAST {
        return switch (lhs.def) {
            case EVar(v) if (rename.exists(v)):
                makeASTWithMeta(EVar(rename.get(v)), lhs.metadata, lhs.pos);
            case EBinary(Match, l2, r2):
                var nl = renameLhs(l2, rename);
                var nr = renameLhs(r2, rename);
                makeASTWithMeta(EBinary(Match, nl, nr), lhs.metadata, lhs.pos);
            default:
                lhs;
        }
    }

    static function renamePattern(p: EPattern, rename: Map<String, String>): EPattern {
        return switch (p) {
            case PVar(n) if (rename.exists(n)): PVar(rename.get(n));
            case PTuple(es): PTuple([for (e in es) renamePattern(e, rename)]);
            case PList(es): PList([for (e in es) renamePattern(e, rename)]);
            case PCons(h, t): PCons(renamePattern(h, rename), renamePattern(t, rename));
            case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: renamePattern(kv.value, rename) }]);
            case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: renamePattern(f.value, rename) }]);
            case PPin(inner): PPin(renamePattern(inner, rename));
            default: p;
        }
    }
}

#end
