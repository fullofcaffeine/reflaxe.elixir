package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import StringTools;

/**
 * PresenceEFnShadowedBinderRenameTransforms
 *
 * WHAT
 * - In Presence modules, rename anonymous function first-arg binders when they are
 *   clearly shadowed/repurposed inside the body (e.g., assigning to the same name),
 *   which triggers warnings about unused/shadowed variables.
 *
 * WHY
 * - Codegen artifacts may reuse the same short name (e.g., `item`) for both the
 *   iteration binder and a map variable in the enclosing scope, causing warnings
 *   and confusion. Renaming the binder to a neutral name (entry) removes the clash.
 *
 * HOW
 * - Scope: Modules whose name ends with ".Presence" or contains "Web.Presence".
 * - For EFn clauses, if the first arg is PVar(name) and the body contains an
 *   assignment to EVar(name) (i.e., `name = ...`) or the body references both the
 *   binder name and a different local with the same name (detected by prior match
 *   to EVar(name) on LHS), rename the binder to `entry` (or `entry2` if occupied).
 */
class PresenceEFnShadowedBinderRenameTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (looksLikePresence(name)):
                    makeASTWithMeta(EModule(name, attrs, [for (b in body) renameInNode(b)]), n.metadata, n.pos);
                case EDefmodule(name2, doBlock) if (looksLikePresence(name2)):
                    makeASTWithMeta(EDefmodule(name2, renameInNode(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function looksLikePresence(name: String): Bool {
        return name != null && (StringTools.endsWith(name, ".Presence") || name.indexOf("Web.Presence") >= 0);
    }

    static function renameInNode(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EFn(clauses):
                    var out = [];
                    for (cl in clauses) {
                        var newArgs = cl.args;
                        var needRename = false;
                        var binder: Null<String> = null;
                        if (cl.args != null && cl.args.length > 0) switch (cl.args[0]) {
                            case PVar(nm): binder = nm;
                            default:
                        }
                        if (binder != null) {
                            // Detect assignment to binder inside body: binder = expr
                            var assigned = false;
                            ElixirASTTransformer.transformNode(cl.body, function(t: ElixirAST): ElixirAST {
                                switch (t.def) {
                                    case EBinary(Match, left, _):
                                        switch (left.def) { case EVar(v) if (v == binder): assigned = true; default: }
                                    default:
                                }
                                return t;
                            });
                            needRename = assigned;
                        }
                        if (needRename && binder != null) {
                            var target = chooseTargetName(cl.body, "entry");
                            // Rename binder in args and body references
                            var newFirst = PVar(target);
                            newArgs = cl.args.copy();
                            newArgs[0] = newFirst;
                            var newBody = ElixirASTTransformer.transformNode(cl.body, function(t2: ElixirAST): ElixirAST {
                                return switch (t2.def) {
                                    case EVar(v2) if (v2 == binder): makeASTWithMeta(EVar(target), t2.metadata, t2.pos);
                                    default: t2;
                                }
                            });
                            out.push({ args: newArgs, guard: cl.guard, body: newBody });
                        } else {
                            out.push(cl);
                        }
                    }
                    makeASTWithMeta(EFn(out), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }

    static function chooseTargetName(body: ElixirAST, base: String): String {
        var target = base;
        var idx = 2;
        while (nameExists(body, target)) {
            target = base + idx; idx++;
        }
        return target;
    }

    static function nameExists(body: ElixirAST, name: String): Bool {
        var found = false;
        ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case EVar(v) if (v == name): found = true;
                default:
            }
            return n;
        });
        return found;
    }
}

#end

