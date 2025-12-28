package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SelfCompareToParamFixTransforms
 *
 * WHAT
 * - Inside functions with an id/_id parameter, rewrite anonymous fn predicates that
 *   compare a field of the binder to the binder itself, or compare the binder to itself,
 *   to instead compare against the id param. This generically fixes shapes like
 *   fn t -> t.id != t end and, conservatively, fn t -> t != t end when no other value
 *   is available.
 *
 * WHY
 * - Some late lowerings/hygiene leave self-compare artifacts in removal predicates.
 *   This pass corrects them at a structural level without app-specific names.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class SelfCompareToParamFixTransforms {
    public static function paramSelfCompareFixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var idName: Null<String> = null;
                    for (a in args) switch (a) { case PVar(nm) if (nm == "id" || nm == "_id"): idName = nm; default: }
                    if (idName == null) n else makeASTWithMeta(EDef(name, args, guards, fixBody(body, idName)), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2):
                    var idName2: Null<String> = null;
                    for (a2 in args2) switch (a2) { case PVar(nm2) if (nm2 == "id" || nm2 == "_id"): idName2 = nm2; default: }
                    if (idName2 == null) n else makeASTWithMeta(EDefp(name2, args2, guards2, fixBody(body2, idName2)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function fixBody(body: ElixirAST, idParam: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EFn(clauses) if (clauses.length == 1):
                    var cl = clauses[0];
                    var binder: Null<String> = switch (cl.args.length == 1 ? cl.args[0] : null) { case PVar(nm): nm; default: null; };
                    if (binder == null) x else {
                        var bodyExpr = unwrapSingleExpr(cl.body);
                        switch (bodyExpr.def) {
                            // t.id != t  → t.id != id
                            case EBinary(NotEqual | StrictNotEqual, l, r):
                                inline function isBinderVar(e: ElixirAST): Bool return switch (unwrapSingleExpr(e).def) { case EVar(n) if (n == binder): true; default: false; };
                                inline function isBinderIdField(e: ElixirAST): Bool return switch (unwrapSingleExpr(e).def) { case EField({def: EVar(n2)}, fld) if (n2 == binder && fld == "id"): true; default: false; };
                                if (isBinderIdField(l) && isBinderVar(r)) {
                                    var nb = makeAST(EBinary(NotEqual, l, makeAST(EVar(idParam))));
                                    makeASTWithMeta(EFn([{ args: cl.args, guard: cl.guard, body: nb }]), x.metadata, x.pos);
                                } else if (isBinderVar(l) && isBinderVar(r)) {
                                    // conservative: t != t  → t != id
                                    var nb2 = makeAST(EBinary(NotEqual, l, makeAST(EVar(idParam))));
                                    makeASTWithMeta(EFn([{ args: cl.args, guard: cl.guard, body: nb2 }]), x.metadata, x.pos);
                                } else x;
                            // t.id == t  → t.id == id   (covers Enum.find-by-id drift)
                            case EBinary(Equal | StrictEqual, l2, r2):
                                inline function isBinderVar2(e: ElixirAST): Bool return switch (unwrapSingleExpr(e).def) { case EVar(n) if (n == binder): true; default: false; };
                                inline function isBinderIdField2(e: ElixirAST): Bool return switch (unwrapSingleExpr(e).def) { case EField({def: EVar(n2)}, fld) if (n2 == binder && fld == "id"): true; default: false; };
                                var eqOp = switch (bodyExpr.def) { case EBinary(StrictEqual, _, _): StrictEqual; default: Equal; };
                                // v.id == v  → v.id == id
                                if (isBinderIdField2(l2) && isBinderVar2(r2)) {
                                    #if debug_self_compare_fix
                                    Sys.println('[SelfCompareFix] rewriting ' + binder + '.id == ' + binder + ' to compare with ' + idParam);
                                    #end
                                    var nbEq = makeAST(EBinary(eqOp, l2, makeAST(EVar(idParam))));
                                    makeASTWithMeta(EFn([{ args: cl.args, guard: cl.guard, body: nbEq }]), x.metadata, x.pos);
                                } else if (isBinderVar2(l2) && isBinderIdField2(r2)) {
                                    #if debug_self_compare_fix
                                    Sys.println('[SelfCompareFix] rewriting ' + binder + ' == ' + binder + '.id to compare with ' + idParam);
                                    #end
                                    var nbEq2 = makeAST(EBinary(eqOp, makeAST(EVar(idParam)), r2));
                                    makeASTWithMeta(EFn([{ args: cl.args, guard: cl.guard, body: nbEq2 }]), x.metadata, x.pos);
                                } else x;
                            default:
                                x;
                        }
                    }
                default:
                    x;
            }
        });
    }

    static function unwrapSingleExpr(n: ElixirAST): ElixirAST {
        if (n == null || n.def == null) return n;
        return switch (n.def) {
            case EParen(inner): unwrapSingleExpr(inner);
            case EDo(body) if (body != null && body.length == 1): unwrapSingleExpr(body[0]);
            case EBlock(exprs) if (exprs != null && exprs.length == 1): unwrapSingleExpr(exprs[0]);
            default: n;
        };
    }
}

#end
