package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseSuccessVarRenameCollisionFixTransforms
 *
 * WHAT
 * - Prevents accidental shadowing of function parameters (notably `socket`) by
 *   the success binder in `{:ok, var}` case patterns.
 *
 * WHY
 * - Patterns like `{:ok, socket}` can shadow the LiveView `socket` argument,
 *   causing subsequent calls to receive the wrong value. This is non-idiomatic
 *   and leads to subtle runtime bugs.
 *
 * HOW
 * - For each case clause with pattern `{:ok, PVar(name)}`, if `name` collides
 *   with any function argument (e.g., `socket`), rename the binder to a safe
 *   identifier (e.g., `ok_value`) and rewrite references in the clause body.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class CaseSuccessVarRenameCollisionFixTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var argNames = argNameSet(args);
                    var newBody = fixCollisionsInBody(body, argNames);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var argNames2 = argNameSet(args);
                    var newBody2 = fixCollisionsInBody(body, argNames2);
                    makeASTWithMeta(EDefp(name, args, guards, newBody2), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function argNameSet(args: Array<EPattern>): Map<String, Bool> {
        var s = new Map<String, Bool>();
        for (a in args) collectNames(a, s);
        return s;
    }

    static function collectNames(p: EPattern, acc: Map<String,Bool>): Void {
        switch (p) {
            case PVar(n) if (n != null): acc.set(n, true);
            case PTuple(es) | PList(es): for (e in es) collectNames(e, acc);
            case PCons(h, t): collectNames(h, acc); collectNames(t, acc);
            case PMap(kvs): for (kv in kvs) collectNames(kv.value, acc);
            case PStruct(_, fs): for (f in fs) collectNames(f.value, acc);
            case PPin(inner): collectNames(inner, acc);
            default:
        }
    }

    static function fixCollisionsInBody(body: ElixirAST, args: Map<String,Bool>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(expr, clauses):
                    var out = [];
                    for (c in clauses) {
                        var renamed = c;
                        switch (c.pattern) {
                            case PTuple(els) if (els.length == 2):
                                switch (els[0]) {
                                    case PLiteral({def: EAtom(a)}) if ((a : String) == ":ok" || (a : String) == "ok"):
                                        switch (els[1]) {
                                            case PVar(vname) if (vname != null && args.exists(vname)):
                                                var replacement = safeName(vname);
                                                var newPat = PTuple([els[0], PVar(replacement)]);
                                                // Also rewrite body references from the old binder to the replacement
                                                var newBody = renameVarInBody(c.body, vname, replacement);
                                                renamed = { pattern: newPat, guard: c.guard, body: newBody };
                                            default:
                                        }
                                    default:
                                }
                            default:
                        }
                        out.push(renamed);
                    }
                    makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function renameVarInBody(body: ElixirAST, from:String, to:String): ElixirAST {
        if (from == null || to == null || from == to) return body;
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (v == from): makeASTWithMeta(EVar(to), n.metadata, n.pos);
                default: n;
            }
        });
    }

    static inline function safeName(colliding: String): String {
        // Prefer a neutral, idiomatic binder name without ok_* prefix to avoid leaks
        return "value";
    }

    // No body rewriting: avoid capturing function args like `socket`.
}

#end
