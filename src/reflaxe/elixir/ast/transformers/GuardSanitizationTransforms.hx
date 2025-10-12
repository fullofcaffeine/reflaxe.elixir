package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.EUnaryOp;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * GuardSanitizationTransforms
 *
 * WHY: Elixir guards allow only a restricted set of functions. Calls such as
 *      Map.get/2 are not guard-safe and cause compile errors when generated
 *      in `when` clauses.
 * WHAT: Rewrite non-guard-safe constructs in guard positions into guard-safe
 *       equivalents. For now:
 *       - Map.get(map, key) != nil → is_map_key(map, key)
 *       - Map.get(map, key) == nil → not is_map_key(map, key)
 * HOW: Traverse function/anonymous-function guards and replace matching
 *      Binary(Equal|NotEqual, Map.get(...), nil) patterns.
 */
class GuardSanitizationTransforms {
    public static function guardSanitizePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            if (node == null || node.def == null) return node;
            return switch(node.def) {
                case EDef(name, args, guards, body):
                    var newGuards = guards != null ? sanitizeGuardExpr(guards) : null;
                    makeASTWithMeta(EDef(name, args, newGuards, body), node.metadata, node.pos);

                case EDefp(name, args, guards, body):
                    var newGuards = guards != null ? sanitizeGuardExpr(guards) : null;
                    makeASTWithMeta(EDefp(name, args, newGuards, body), node.metadata, node.pos);

                case EFn(clauses):
                    var newClauses = clauses.map(c -> {
                        var g = c.guard != null ? sanitizeGuardExpr(c.guard) : null;
                        return { args: c.args, guard: g, body: c.body };
                    });
                    makeASTWithMeta(EFn(newClauses), node.metadata, node.pos);

                case ECase(target, clauses):
                    var newClauses2 = clauses.map(c -> {
                        var g = c.guard != null ? sanitizeGuardExpr(c.guard) : null;
                        return { pattern: c.pattern, guard: g, body: c.body };
                    });
                    makeASTWithMeta(ECase(target, newClauses2), node.metadata, node.pos);

                default:
                    node;
            }
        });
    }

    static function sanitizeGuardExpr(expr: ElixirAST): ElixirAST {
        if (expr == null || expr.def == null) return expr;
        return sanitizeGuardExprRecursive(expr);
    }

    static function sanitizeGuardExprRecursive(expr: ElixirAST): ElixirAST {
        if (expr == null || expr.def == null) return expr;

        return switch(expr.def) {
            case EBinary(op, left, right):
                var l = sanitizeGuardExprRecursive(left);
                var r = sanitizeGuardExprRecursive(right);

                var leftGet = extractMapGet2(l);
                var rightGet = extractMapGet2(r);
                var isNilLeft = isNil(l);
                var isNilRight = isNil(r);

                if (leftGet != null && isNilRight) {
                    var call = makeIsMapKey(leftGet.mapExpr, leftGet.keyExpr, expr.metadata, expr.pos);
                    switch(op) {
                        case NotEqual: call;
                        case Equal: makeASTWithMeta(EUnary(Not, call), expr.metadata, expr.pos);
                        default: makeASTWithMeta(EBinary(op, l, r), expr.metadata, expr.pos);
                    }
                } else if (rightGet != null && isNilLeft) {
                    var call = makeIsMapKey(rightGet.mapExpr, rightGet.keyExpr, expr.metadata, expr.pos);
                    switch(op) {
                        case NotEqual: call;
                        case Equal: makeASTWithMeta(EUnary(Not, call), expr.metadata, expr.pos);
                        default: makeASTWithMeta(EBinary(op, l, r), expr.metadata, expr.pos);
                    }
                } else {
                    makeASTWithMeta(EBinary(op, l, r), expr.metadata, expr.pos);
                }

            case EUnary(uop, sub):
                var s = sanitizeGuardExprRecursive(sub);
                makeASTWithMeta(EUnary(uop, s), expr.metadata, expr.pos);

            case ECall(target, name, args):
                var t = target != null ? sanitizeGuardExprRecursive(target) : null;
                var a = args != null ? args.map(sanitizeGuardExprRecursive) : [];
                makeASTWithMeta(ECall(t, name, a), expr.metadata, expr.pos);

            case ERemoteCall(mod, name, args):
                var m = sanitizeGuardExprRecursive(mod);
                var a = args != null ? args.map(sanitizeGuardExprRecursive) : [];
                makeASTWithMeta(ERemoteCall(m, name, a), expr.metadata, expr.pos);

            case EList(items):
                makeASTWithMeta(EList(items.map(sanitizeGuardExprRecursive)), expr.metadata, expr.pos);

            case EParen(inner):
                makeASTWithMeta(EParen(sanitizeGuardExprRecursive(inner)), expr.metadata, expr.pos);

            default:
                expr;
        }
    }

    static function makeIsMapKey(mapExpr: ElixirAST, keyExpr: ElixirAST, meta: Dynamic, pos: haxe.macro.Expr.Position): ElixirAST {
        return makeASTWithMeta(ERemoteCall(makeAST(EVar("Kernel")), "is_map_key", [mapExpr, keyExpr]), meta, pos);
    }

    static function isNil(expr: ElixirAST): Bool {
        return switch(expr.def) {
            case EAtom(atom): atom == "nil";
            case ENil: true;
            default: false;
        }
    }

    static function extractMapGet2(expr: ElixirAST): Null<{mapExpr: ElixirAST, keyExpr: ElixirAST}> {
        return switch(expr.def) {
            case ERemoteCall(module, funcName, args):
                switch(module.def) {
                    case EVar(modName) if (modName == "Map" && funcName == "get" && args != null && args.length == 2):
                        { mapExpr: args[0], keyExpr: args[1] };
                    default: null;
                }
            default: null;
        }
    }
}

#end
/**
 * GuardSanitizationTransforms
 *
 * WHAT
 * - Rewrites problematic guard expressions into safe alternatives
 *   (e.g., Map.get(map, key) != nil ⇒ is_map_key(map, key)).
 *
 * WHY
 * - Elixir warns on cross-type comparisons in guards and disallows some constructs.
 *   Sanitizing guards preserves intent while avoiding warnings.
 *
 * HOW
 * - Matches Binary(Equal|NotEqual, Map.get(...), nil) and replaces with
 *   is_map_key/2 or not is_map_key/2 depending on operator.
 *
 * EXAMPLES
 * Before: Map.get(m, :a) != nil
 * After:  is_map_key(m, :a)
 */
