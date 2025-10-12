package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnArgCleanupTransforms
 *
 * WHAT
 * - Final normalization for anonymous function arguments and body references:
 *   for each binder argument name, ensure any body references to its underscored
 *   variant (e.g., _name) are rewritten to the non-underscore form. Also, if an
 *   argument binder itself starts with an underscore and is used in the body,
 *   rename the binder to the trimmed variant and update the body.
 *
 * WHY
 * - Prevents warnings like "underscored variable used" and fixes late pipeline
 *   cases that earlier passes didn't catch.
 *
 * HOW
 * - For each EFn clause, collect simple PVar/PAlias binders and normalize the body.
 */
class EFnArgCleanupTransforms {
    public static function cleanupPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var argNames:Array<{orig:String, trimmed:String, idx:Int}> = [];
                        var newArgs:Array<EPattern> = [];
                        var idx = 0;
                        for (a in cl.args) {
                            switch (a) {
                                case PVar(name):
                                    var trimmed = (name != null && name.length > 1 && name.charAt(0) == '_') ? name.substr(1) : name;
                                    argNames.push({orig: name, trimmed: trimmed, idx: idx});
                                    // If underscored and used later, rename binder now; body will be rewritten below
                                    if (name != null && name.length > 1 && name.charAt(0) == '_') newArgs.push(PVar(trimmed)) else newArgs.push(a);
                                case PAlias(name, pat):
                                    var trimmed2 = (name != null && name.length > 1 && name.charAt(0) == '_') ? name.substr(1) : name;
                                    argNames.push({orig: name, trimmed: trimmed2, idx: idx});
                                    if (name != null && name.length > 1 && name.charAt(0) == '_') newArgs.push(PAlias(trimmed2, pat)) else newArgs.push(a);
                                default:
                                    newArgs.push(a);
                            }
                            idx++;
                        }
                        var newBody = cl.body;
                        // For each collected name, rewrite _trimmed -> trimmed in body when present
                        for (an in argNames) {
                            var underscored = (an.trimmed != null && an.trimmed.length > 0) ? ("_" + an.trimmed) : null;
                            if (underscored != null) {
                                newBody = renameVarInNode(newBody, underscored, an.trimmed);
                            }
                        }
                        newClauses.push({args: newArgs, guard: cl.guard, body: newBody});
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function bodyUsesVar(body: ElixirAST, name: String): Bool {
        var used = false;
        function visit(n: ElixirAST): Void {
            if (used || n == null || n.def == null) return;
            switch (n.def) {
                case EVar(nm) if (nm == name): used = true;
                case EField(target, _): visit(target);
                case EBlock(sts): for (s in sts) visit(s);
                case EIf(c,t,e): visit(c); visit(t); if (e != null) visit(e);
                case EBinary(_, l, r): visit(l); visit(r);
                case EUnary(_, e1): visit(e1);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(tgt2, _, args2): visit(tgt2); for (a in args2) visit(a);
                case ETuple(els): for (el in els) visit(el);
                case EMap(pairs): for (p in pairs) { visit(p.key); visit(p.value); }
                case EFn(clauses): for (cl in clauses) visit(cl.body);
                default:
            }
        }
        visit(body);
        return used;
    }

    static function renameVarInNode(node: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(name) if (name == from): makeASTWithMeta(EVar(to), n.metadata, n.pos);
                case ERaw(_): n; // do not rewrite raw strings
                default: n;
            }
        });
    }
}

#end
