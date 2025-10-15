package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ListMapFilterFixTransforms
 *
 * WHAT
 * - Structural, target-agnostic fixes for two common list-manipulation bugs in
 *   generated LiveView code (but applicable everywhere):
 *   1) Enum.map replacement no-op: both branches return the mapping var (v),
 *      never returning the intended replacement value (o).
 *   2) Enum.filter self-compare: predicate compares v.id != v instead of
 *      v.id != id (outer parameter), producing an always-true/false bug.
 *
 * WHY
 * - Earlier hygiene/renaming steps may drift binder names inside anonymous
 *   functions, especially around success-variable unification and local
 *   reference fixes. These two shapes lead to functional no-ops when updating
 *   and removing items by id in lists (e.g., LiveView todo lists).
 *
 * HOW
 * - mapReplaceFixPass:
 *   Detect Enum.map(list, fn v -> if v.id == o.id, do: v, else: v end) and
 *   rewrite the then-branch to return `o` (the non-parameter var from the id
 *   equality), preserving else as `v`. Works with reversed equality operands.
 *
 * - filterRemoveFixPass:
 *   Detect Enum.filter(list, fn v -> v.id != v end) within a surrounding
 *   function whose parameters include `id` or `_id`. Rewrite the self-compare
 *   side to use that outer id parameter so it becomes `v.id != id`.
 *
 * EXAMPLES
 * Haxe:
 *   todos.map(t -> t.id == todo.id ? todo : t);
 *   todos.filter(t -> t.id != id);
 *
 * Elixir (before - buggy):
 *   Enum.map(todos, fn t -> if t.id == todo.id, do: t, else: t end)
 *   Enum.filter(todos, fn t -> t.id != t end)
 *
 * Elixir (after - fixed):
 *   Enum.map(todos, fn t -> if t.id == todo.id, do: todo, else: t end)
 *   Enum.filter(todos, fn t -> t.id != id end)
 */
class ListMapFilterFixTransforms {
    // Public API
    public static function mapReplaceFixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case ERemoteCall(module, func, args) if (isEnumCall(module, func, "map", args, 2)):
                    var listExpr = args[0];
                    var anon = args[1];
                    var fnNode = unwrapToFnNode(anon);
                    var fixedAnon = fnNode != null ? fixMapAnon(fnNode) : null;
                    if (fixedAnon == null) node else makeASTWithMeta(ERemoteCall(module, func, [listExpr, fixedAnon]), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    public static function filterRemoveFixPass(ast: ElixirAST): ElixirAST {
        // Carry enclosing function param names (to locate id/_id)
        var transformWithParams: (ElixirAST, Array<String>) -> ElixirAST = null;
        var transformChildren: (ElixirAST, Array<String>) -> ElixirAST = null;

        transformWithParams = function(n: ElixirAST, fnParams: Array<String>): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var params = extractParamNames(args);
                    makeASTWithMeta(EDef(name, args, guards, transformWithParams(body, params)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    var params = extractParamNames(args);
                    makeASTWithMeta(EDefp(name, args, guards, transformWithParams(body, params)), n.metadata, n.pos);
                case ERemoteCall(module, func, callArgs) if (isEnumCall(module, func, "filter", callArgs, 2)):
                    var listExpr = callArgs[0];
                    var anon = callArgs[1];
                    var fnNode = unwrapToFnNode(anon);
                    var fixedAnon = fnNode != null ? fixFilterAnon(fnNode, fnParams) : null;
                    if (fixedAnon == null) n else makeASTWithMeta(ERemoteCall(module, func, [listExpr, fixedAnon]), n.metadata, n.pos);
                default:
                    // Manual shallow transform to propagate params into children
                    return transformChildren(n, fnParams);
            }
        };

        transformChildren = function(node: ElixirAST, fnParams: Array<String>): ElixirAST {
            return switch (node.def) {
                case EIf(c, t, e): makeASTWithMeta(EIf(transformWithParams(c, fnParams), transformWithParams(t, fnParams), e != null ? transformWithParams(e, fnParams) : null), node.metadata, node.pos);
                case ECase(expr, clauses):
                    var newClauses = [];
                    for (c in clauses) newClauses.push({ pattern: c.pattern, guard: c.guard != null ? transformWithParams(c.guard, fnParams) : null, body: transformWithParams(c.body, fnParams) });
                    makeASTWithMeta(ECase(transformWithParams(expr, fnParams), newClauses), node.metadata, node.pos);
                case ECall(t, f, as): makeASTWithMeta(ECall(t != null ? transformWithParams(t, fnParams) : null, f, [for (a in as) transformWithParams(a, fnParams)]), node.metadata, node.pos);
                case ERemoteCall(m, f, as): makeASTWithMeta(ERemoteCall(transformWithParams(m, fnParams), f, [for (a in as) transformWithParams(a, fnParams)]), node.metadata, node.pos);
                case EList(es): makeASTWithMeta(EList([for (e in es) transformWithParams(e, fnParams)]), node.metadata, node.pos);
                case ETuple(es): makeASTWithMeta(ETuple([for (e in es) transformWithParams(e, fnParams)]), node.metadata, node.pos);
                case EMap(ps): makeASTWithMeta(EMap([for (p in ps) { key: transformWithParams(p.key, fnParams), value: transformWithParams(p.value, fnParams) }]), node.metadata, node.pos);
                case EBinary(op, l, r): makeASTWithMeta(EBinary(op, transformWithParams(l, fnParams), transformWithParams(r, fnParams)), node.metadata, node.pos);
                case EUnary(op, ex): makeASTWithMeta(EUnary(op, transformWithParams(ex, fnParams)), node.metadata, node.pos);
                case EFn(cs): makeASTWithMeta(EFn([for (cl in cs) { args: cl.args, guard: cl.guard != null ? transformWithParams(cl.guard, fnParams) : null, body: transformWithParams(cl.body, fnParams) }]), node.metadata, node.pos);
                case EDo(bs): makeASTWithMeta(EDo([for (b in bs) transformWithParams(b, fnParams)]), node.metadata, node.pos);
                case EBlock(bs): makeASTWithMeta(EBlock([for (b in bs) transformWithParams(b, fnParams)]), node.metadata, node.pos);
                case EParen(inner): makeASTWithMeta(EParen(transformWithParams(inner, fnParams)), node.metadata, node.pos);
                default: node;
            }
        };

        return transformWithParams(ast, []);
    }

    // --- Implementation helpers ------------------------------------------------

    static inline function isEnumCall(module: ElixirAST, func: String, expected: String, args: Array<ElixirAST>, arity: Int): Bool {
        return func == expected && args != null && args.length == arity && switch(module.def) {
            case EVar(m): m == "Enum";
            default: false;
        };
    }

    static function extractParamNames(args: Array<EPattern>): Array<String> {
        var names: Array<String> = [];
        for (a in args) switch (a) {
            case PVar(n): names.push(n);
            case PTuple(es): for (e in es) switch(e) { case PVar(n2): names.push(n2); default: }
            default:
        }
        return names;
    }

    // (transformChildren is localized inside filterRemoveFixPass)

    static function fixMapAnon(anon: ElixirAST): Null<ElixirAST> {
        return switch (anon.def) {
            case EFn(clauses) if (clauses.length == 1):
                var cl = clauses[0];
                var param = extractSingleParamName(cl.args);
                if (param == null) return null;
                switch (cl.body.def) {
                    case EIf(cond, thenB, elseB):
                        var otherVar = extractOtherIdVarFromEquality(cond, param);
                        if (otherVar == null) return null;
                        var thenIsParam = varNameEquals(thenB, param);
                        var elseIsParam = varNameEquals(elseB, param);
                        if (thenIsParam && elseIsParam) {
                            #if debug_list_fix
                            Sys.println('[ListMapFilterFix] mapReplace: param=' + param + ', other=' + otherVar);
                            #end
                            var newThen = makeAST(EVar(otherVar));
                            return makeAST(EFn([ { args: cl.args, guard: cl.guard, body: makeAST(EIf(cond, newThen, elseB)) } ]));
                        }
                        return null;
                    default:
                        return null;
                }
            default:
                null;
        }
    }

    static function fixFilterAnon(anon: ElixirAST, enclosingParams: Array<String>): Null<ElixirAST> {
        return switch (anon.def) {
            case EFn(clauses) if (clauses.length == 1):
                var cl = clauses[0];
                var param = extractSingleParamName(cl.args);
                if (param == null) return null;
                var outerId = resolveOuterIdParam(enclosingParams);
                if (outerId == null) return null;
                switch (cl.body.def) {
                    case EBinary(NotEqual | StrictNotEqual, left, right):
                        // Match v.id != v  OR  v != v.id
                        if (isFieldIdOfVar(left, param) && varNameEquals(right, param)) {
                            var newRight = makeAST(EVar(outerId));
                            #if debug_list_fix
                            Sys.println('[ListMapFilterFix] filterRemove: replace RHS self with ' + outerId);
                            #end
                            return makeAST(EFn([ { args: cl.args, guard: cl.guard, body: makeAST(EBinary(NotEqual, left, newRight)) } ]));
                        } else if (varNameEquals(left, param) && isFieldIdOfVar(right, param)) {
                            var newLeft = makeAST(EVar(outerId));
                            #if debug_list_fix
                            Sys.println('[ListMapFilterFix] filterRemove: replace LHS self with ' + outerId);
                            #end
                            return makeAST(EFn([ { args: cl.args, guard: cl.guard, body: makeAST(EBinary(NotEqual, newLeft, right)) } ]));
                        } else {
                            return null;
                        }
                    default:
                        return null;
                }
            default:
                null;
        }
    }

    static function extractSingleParamName(args: Array<EPattern>): Null<String> {
        if (args == null || args.length != 1) return null;
        return switch (args[0]) { case PVar(n): n; default: null; };
    }

    static function varNameEquals(ast: ElixirAST, name: String): Bool {
        // Unwrap simple containers to get at EVar
        return switch (ast.def) {
            case EVar(n): n == name;
            case EParen(inner): varNameEquals(inner, name);
            case EDo(body):
                if (body != null && body.length == 1) varNameEquals(body[0], name) else false;
            case EBlock(exprs):
                if (exprs != null && exprs.length == 1) varNameEquals(exprs[0], name) else false;
            default: false;
        };
    }

    static function isFieldIdOfVar(ast: ElixirAST, varName: String): Bool {
        return switch (ast.def) {
            case EField(target, field) if (field == "id"):
                switch (target.def) { case EVar(n) if (n == varName): true; default: false; }
            default: false;
        };
    }

    static function extractOtherIdVarFromEquality(cond: ElixirAST, param: String): Null<String> {
        return switch (cond.def) {
            case EBinary(Equal | StrictEqual, l, r):
                var lOther = otherVarFromIdField(l, param);
                var rOther = otherVarFromIdField(r, param);
                if (lOther != null && rOther == null) lOther
                else if (rOther != null && lOther == null) rOther
                else null; // Require exactly one side to be the param.id and the other to be other.id
            default:
                null;
        }
    }

    static function unwrapToFnNode(n: ElixirAST): Null<ElixirAST> {
        return switch (n.def) {
            case EFn(_): n;
            case EParen(inner): unwrapToFnNode(inner);
            case EDo(body) if (body != null && body.length == 1): unwrapToFnNode(body[0]);
            default: null;
        }
    }

    static function otherVarFromIdField(ast: ElixirAST, param: String): Null<String> {
        return switch (ast.def) {
            case EField(target, field) if (field == "id"):
                switch (target.def) {
                    case EVar(n) if (n != param): n;
                    default: null;
                }
            default:
                null;
        }
    }

    static function resolveOuterIdParam(fnParams: Array<String>): Null<String> {
        if (fnParams == null) return null;
        for (n in fnParams) if (n == "id") return n;
        for (n in fnParams) if (n == "_id") return n; // allow underscored variant
        return null;
    }
}

#end
