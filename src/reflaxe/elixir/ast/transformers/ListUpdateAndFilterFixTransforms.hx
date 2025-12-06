package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ListUpdateAndFilterFixTransforms
 *
 * WHAT
 * - Repairs two common list-handling logic shapes that can arise during codegen:
 *   1) Update-by-id map: Enum.map(list, fn v -> if v.id == x.id, do: v, else: v end)
 *      → should return x in the then-branch (replace), not v.
 *   2) Remove-by-id filter: Enum.filter(list, fn v -> v.id != v end)
 *      → should compare against function arg id (id/_id), not the element itself.
 *
 * WHY
 * - Correct layer: These are late, structural issues that surface after hygiene/renaming
 *   passes (success-var unification, local reference fixes). Fixing them here preserves a
 *   clean builder (TypedExpr→ElixirAST) and keeps the printer string‑free.
 * - Deterministic shape: When both branches return the map binder despite an equality on
 *   the same field, the only sensible fix is to return the other value. When a filter
 *   compares a field to the element itself, the only sensible comparator is the function's
 *   argument that carries the key (id/_id). The transformations are idempotent and generic.
 * - Scope‑safe: No app names, atoms, or module heuristics. Decisions are made purely from
 *   AST shape (same-field equality, self‑compare) and function head parameters.
 *
 * HOW
 * - Pass 1 (map fix): Detect EIf with condition v.id == x.id inside an Enum.map
 *   anonymous function where both branches return v; replace then-branch with x.
 * - Pass 2 (filter fix): Inside Enum.filter anonymous function, detect v.id != v;
 *   if the enclosing function has an id/_id parameter, replace RHS with that id.
 * - Fallback: Also rewrite anonymous fn bodies with the exact self‑compare shape anywhere
 *   inside these functions so variations in call wrapping still converge to the correct form.
 *
 * SCOPE
 * - Shape-based only; no app-specific names. Works for any v/x identifiers.
 */
class ListUpdateAndFilterFixTransforms {
    static inline function baseName(n:String):String {
        return (n != null && n.length > 0 && n.charAt(0) == '_') ? n.substr(1) : n;
    }

    static function unwrapFnArg(a: ElixirAST): Null<Array<EFnClause>> {
        return switch (a.def) {
            case EFn(clauses): clauses;
            case EParen(inner): unwrapFnArg(inner);
            case EDo(body) if (body != null && body.length == 1): unwrapFnArg(body[0]);
            default: null;
        }
    }

    static function isVarNamed(e: ElixirAST, name:String): Bool {
        return switch (e.def) {
            case EVar(v): v == name;
            case EParen(inner): isVarNamed(inner, name);
            case EDo(body) if (body != null && body.length == 1): isVarNamed(body[0], name);
            case EBlock(exprs) if (exprs != null && exprs.length == 1): isVarNamed(exprs[0], name);
            default: false;
        }
    }

    static function fixMapThenBranch(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case ERemoteCall({def: EVar(m)}, "map", args) if (m == "Enum" && args != null && args.length == 2):
                    var clauses = unwrapFnArg(args[1]);
                    switch (clauses) {
                        case _ if (clauses != null && clauses.length == 1):
                            var cl = clauses[0];
                            var vName: Null<String> = null;
                            if (cl.args != null && cl.args.length == 1) switch (cl.args[0]) { case PVar(nm): vName = nm; default: }
                            var newBody = cl.body;
                            switch (cl.body.def) {
                                case EIf(cond, thenB, elseB):
                                    // cond must be (v.id == x.id) or (x.id == v.id)
                                    var left = null; var right = null;
                                    switch (cond.def) {
                                        case EBinary(Equal | StrictEqual, l, r): left = l; right = r;
                                        default:
                                    }
                                    var aName: Null<String> = null; var bName: Null<String> = null;
                                    inline function fieldIsId(e: ElixirAST): Null<String> {
                                        return switch (e.def) {
                                            case EField({def: EVar(v)}, fld) if (fld == "id"): v;
                                            default: null;
                                        }
                                    }
                                    if (left != null && right != null) {
                                        aName = fieldIsId(left);
                                        bName = fieldIsId(right);
                                    }
                                    if (vName != null && aName != null && bName != null && (aName == vName || bName == vName)) {
                                        #if debug_list_fix
                                        // DISABLED: trace('[ListFix] Detected map-if replace pattern: v=' + vName + ', other=' + ((aName == vName) ? bName : aName));
                                        #end
                                        // both branches currently return v? If so, replace then-branch with the non-v variable
                                        if (isVarNamed(thenB, vName) && isVarNamed(elseB, vName)) {
                                            var other = (aName == vName) ? bName : aName;
                                            var fixedThen = makeAST(EVar(other));
                                            var rebuiltFn = makeAST(EFn([{ args: cl.args, guard: cl.guard, body: makeAST(EIf(cond, fixedThen, elseB)) }]));
                                            return makeAST(ERemoteCall(makeAST(EVar("Enum")), "map", [args[0], rebuiltFn]));
                                        }
                                    }
                                default:
                            }
                            return n;
                        default:
                            return n;
                    }
                default:
                    return n;
            }
        });
    }

    static function fixFilterCompareToId(node: ElixirAST): ElixirAST {
        // Capture enclosing function parameters to find id/_id
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case EDef(fname, fargs, fguards, fbody):
                    var idParam: Null<String> = null;
                    if (fargs != null) for (p in fargs) switch (p) { case PVar(nm) if (baseName(nm) == "id"): idParam = nm; default: }
                    #if debug_list_fix
                    if (idParam != null) trace('[ListFix] EDef ' + fname + ' has id param: ' + idParam);
                    #end
                    if (idParam == null) return n;
                    // Traverse body to fix v.id != v → v.id != idParam
                    var newBody = ElixirASTTransformer.transformNode(fbody, function(x: ElixirAST): ElixirAST {
                        return switch (x.def) {
                            case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length == 2):
                                var filterFnClauses = unwrapFnArg(args[1]);
                                switch (filterFnClauses) {
                                    case _ if (filterFnClauses != null && filterFnClauses.length == 1):
                                        var cl = filterFnClauses[0];
                                        #if debug_list_fix
                                        try {
                                            var predStr = reflaxe.elixir.ast.ElixirASTPrinter.print(cl.body, 0);
                                            // DISABLED: trace('[ListFix] (EDef ' + fname + ') filter predicate: ' + predStr);
                                        } catch (e: Dynamic) {}
                                        #end
                                        // match body: v.id != v
                                        var fixedBody = switch (cl.body.def) {
                                            case EBinary(NotEqual | StrictNotEqual, l, r):
                                                inline function isElemId(e: ElixirAST): Bool {
                                                    return switch (e.def) { case EField({def: EVar(_)}, fld) if (fld == "id"): true; default: false; }
                                                }
                                                function isSelfVar(e: ElixirAST): Bool {
                                                    return switch (e.def) {
                                                        case EVar(_): true;
                                                        case EParen(inner): isSelfVar(inner);
                                                        case EDo(body) if (body != null && body.length == 1): isSelfVar(body[0]);
                                                        case EBlock(exprs) if (exprs != null && exprs.length == 1): isSelfVar(exprs[0]);
                                                        default: false;
                                                    }
                                                }
                                                if (isElemId(l) && isSelfVar(r)) makeAST(EBinary(NotEqual, l, makeAST(EVar(idParam)))) else cl.body;
                                            default: cl.body;
                                        };
                                        if (fixedBody != cl.body) {
                                            #if debug_list_fix
                                            // DISABLED: trace('[ListFix] Detected filter compare self; replacing RHS with ' + idParam);
                                            #end
                                            var rebuiltFn = makeAST(EFn([{ args: cl.args, guard: cl.guard, body: fixedBody }]));
                                            makeAST(ERemoteCall(makeAST(EVar("Enum")), "filter", [args[0], rebuiltFn]));
                                        } else x;
                                    default: x;
                                }
                            // Fallback: fix anonymous fn bodies matching self-compare shape anywhere inside this function
                            case EFn(clauses) if (clauses.length == 1):
                                var cl2 = clauses[0];
                                var binder: Null<String> = switch (cl2.args.length == 1 ? cl2.args[0] : null) { case PVar(nm): nm; default: null; };
                                if (binder == null) return x;
                                switch (cl2.body.def) {
                                    case EBinary(NotEqual | StrictNotEqual, l2, r2):
                                        inline function isBinder(e: ElixirAST): Bool return switch (e.def) { case EVar(nm) if (nm == binder): true; default: false; };
                                        inline function isIdFieldOfBinder(e: ElixirAST): Bool return switch (e.def) { case EField({def: EVar(nm)}, fld) if (fld == "id" && nm == binder): true; default: false; };
                                        if (isIdFieldOfBinder(l2) && isBinder(r2)) {
                                            var nb = makeAST(EBinary(NotEqual, l2, makeAST(EVar(idParam))));
                                            makeASTWithMeta(EFn([{ args: cl2.args, guard: cl2.guard, body: nb }]), x.metadata, x.pos);
                                        } else x;
                                    default: x;
                                }
                            default:
                                x;
                        }
                    });
                    return makeASTWithMeta(EDef(fname, fargs, fguards, newBody), n.metadata, n.pos);
                case EDefp(fnamep, fargsp, fguardsp, fbodyp):
                    var idParamP: Null<String> = null;
                    if (fargsp != null) for (p in fargsp) switch (p) { case PVar(nm) if (baseName(nm) == "id"): idParamP = nm; default: }
                    #if debug_list_fix
                    if (idParamP != null) trace('[ListFix] EDefp ' + fnamep + ' has id param: ' + idParamP);
                    #end
                    if (idParamP == null) return n;
                    var newBodyP = ElixirASTTransformer.transformNode(fbodyp, function(x: ElixirAST): ElixirAST {
                        return switch (x.def) {
                            case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length == 2):
                                var filterFnClauses = unwrapFnArg(args[1]);
                                switch (filterFnClauses) {
                                    case _ if (filterFnClauses != null && filterFnClauses.length == 1):
                                        var cl = filterFnClauses[0];
                                        #if debug_list_fix
                                        try {
                                            var printed = reflaxe.elixir.ast.ElixirASTPrinter.print(cl.body, 0);
                                            // DISABLED: trace('[ListFix] (EDefp ' + fnamep + ') filter predicate: ' + printed);
                                        } catch (e: Dynamic) {}
                                        #end
                                        var fixedBody = switch (cl.body.def) {
                                            case EBinary(NotEqual | StrictNotEqual, l, r):
                                                inline function isElemId(e: ElixirAST): Bool {
                                                    return switch (e.def) { case EField({def: EVar(_)}, fld) if (fld == "id"): true; default: false; }
                                                }
                                                function isSelfVar(e: ElixirAST): Bool {
                                                    return switch (e.def) {
                                                        case EVar(_): true;
                                                        case EParen(inner): isSelfVar(inner);
                                                        case EDo(body) if (body != null && body.length == 1): isSelfVar(body[0]);
                                                        case EBlock(exprs) if (exprs != null && exprs.length == 1): isSelfVar(exprs[0]);
                                                        default: false;
                                                    }
                                                }
                                                if (isElemId(l) && isSelfVar(r)) makeAST(EBinary(NotEqual, l, makeAST(EVar(idParamP)))) else cl.body;
                                            default: cl.body;
                                        };
                                        if (fixedBody != cl.body) {
                                            #if debug_list_fix
                                            // DISABLED: trace('[ListFix] (EDefp) Rewriting Enum.filter predicate to compare with ' + idParamP);
                                            #end
                                            var rebuiltFn = makeAST(EFn([{ args: cl.args, guard: cl.guard, body: fixedBody }]));
                                            makeAST(ERemoteCall(makeAST(EVar("Enum")), "filter", [args[0], rebuiltFn]));
                                        } else x;
                                    default: x;
                                }
                            // Fallback: fix anonymous fn bodies matching self-compare shape anywhere inside this function
                            case EFn(clauses) if (clauses.length == 1):
                                var clb = clauses[0];
                                var binder2: Null<String> = switch (clb.args.length == 1 ? clb.args[0] : null) { case PVar(nmb): nmb; default: null; };
                                if (binder2 == null) return x;
                                switch (clb.body.def) {
                                    case EBinary(NotEqual | StrictNotEqual, lB, rB):
                                        inline function isBinder(e: ElixirAST): Bool return switch (e.def) { case EVar(nm2) if (nm2 == binder2): true; default: false; };
                                        inline function isIdFieldOfBinder(e: ElixirAST): Bool return switch (e.def) { case EField({def: EVar(nm3)}, fld) if (fld == "id" && nm3 == binder2): true; default: false; };
                                        if (isIdFieldOfBinder(lB) && isBinder(rB)) {
                                            var nbp = makeAST(EBinary(NotEqual, lB, makeAST(EVar(idParamP))));
                                            makeASTWithMeta(EFn([{ args: clb.args, guard: clb.guard, body: nbp }]), x.metadata, x.pos);
                                        } else x;
                                    default: x;
                                }
                            default:
                                x;
                        }
                    });
                    return makeASTWithMeta(EDefp(fnamep, fargsp, fguardsp, newBodyP), n.metadata, n.pos);
                default:
                    return n;
            }
        });
    }

    static function fixGenericIfReplace(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var nb = cl.body;
                        switch (cl.body.def) {
                            case EIf(cond, thenB, elseB):
                                inline function fieldVar(e: ElixirAST): Null<String> {
                                    return switch (e.def) { case EField({def: EVar(v)}, fld) if (fld == "id"): v; default: null; }
                                }
                                inline function sameVar(e: ElixirAST, name:String): Bool {
                                    return switch (e.def) { case EVar(v) if (v == name): true; default: false; }
                                }
                                var a:ElixirAST = null; var b:ElixirAST = null;
                                switch (cond.def) { case EBinary(Equal, l, r): a = l; b = r; default: }
                                var va = a != null ? fieldVar(a) : null;
                                var vb = b != null ? fieldVar(b) : null;
                                if (va != null && vb != null) {
                                    // if both branches return the left var, replace then with the right var
                                    if (sameVar(thenB, va) && sameVar(elseB, va)) {
                                        nb = makeAST(EIf(cond, makeAST(EVar(vb)), elseB));
                                    } else if (sameVar(thenB, vb) && sameVar(elseB, vb)) {
                                        nb = makeAST(EIf(cond, makeAST(EVar(va)), elseB));
                                    }
                                }
                            default:
                        }
                        newClauses.push({ args: cl.args, guard: cl.guard, body: nb });
                    }
                    return makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    return n;
            }
        });
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        var a = fixMapThenBranch(ast);
        var b = fixFilterCompareToId(a);
        var c = fixGenericIfReplace(b);
        return c;
    }
}

#end
