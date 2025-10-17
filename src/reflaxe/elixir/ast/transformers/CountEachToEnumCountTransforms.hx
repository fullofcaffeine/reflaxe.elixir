package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CountEachToEnumCountTransforms
 *
 * WHAT
 * - Rewrites patterns of the form `Enum.each(list, fn binder -> if cond, do: binder = binder + 1 end)`
 *   into `Enum.count(list, fn binder -> cond end)`.
 *
 * WHY
 * - Some compiler paths emit counting loops using Enum.each with a local increment on the element binder,
 *   which is semantically wrong and causes compile errors (struct vs integer). The idiomatic form is
 *   Enum.count with a predicate.
 *
 * HOW
 * - Detect `Enum.each(list, fn binder -> body end)` where body is an if with a then-branch that increments
 *   the binder (binder = binder + 1). Replace with `Enum.count(list, fn binder -> normalizedCond end)`.
 * - Normalizes the predicate to use the binder by replacing any single free, lowercase variable name
 *   in the condition with the binder (handles cases like `todo.completed`).
 */
class CountEachToEnumCountTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, func, args) if (isEnumEach(mod, func, args)):
                    var x = rewriteEachToCount(n, mod, func, args);
                    x == null ? n : x;
                case EMatch(pat, rhs):
                    var rewritten: Null<ElixirAST> = null;
                    switch (rhs.def) {
                        case ERemoteCall(mod2, func2, args2) if (isEnumEach(mod2, func2, args2)):
                            rewritten = rewriteEachToCount(rhs, mod2, func2, args2);
                        default:
                    }
                    rewritten == null ? n : makeASTWithMeta(EMatch(pat, rewritten), n.metadata, n.pos);
                case EBinary(Match, left, rhs2):
                    var rewritten2: Null<ElixirAST> = null;
                    switch (rhs2.def) {
                        case ERemoteCall(mod3, func3, args3) if (isEnumEach(mod3, func3, args3)):
                            rewritten2 = rewriteEachToCount(rhs2, mod3, func3, args3);
                        default:
                    }
                    rewritten2 == null ? n : makeASTWithMeta(EBinary(Match, left, rewritten2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function isEnumEach(mod: ElixirAST, func: String, args: Array<ElixirAST>): Bool {
        if (func != "each" || args == null || args.length != 2) return false;
        var isEnum = switch (mod.def) { case EVar(m) if (m == "Enum"): true; default: false; };
        var isFn = switch (args[1].def) { case EFn(clauses) if (clauses.length == 1): true; default: false; };
        return isEnum && isFn;
    }

    static function rewriteEachToCount(node: ElixirAST, mod: ElixirAST, func: String, args: Array<ElixirAST>): Null<ElixirAST> {
        var listExpr = args[0];
        var binderName: String = "_elem";
        var predicate: Null<ElixirAST> = null;
        switch (args[1].def) {
            case EFn(clauses) if (clauses.length == 1):
                var cl = clauses[0];
                switch (cl.args.length > 0 ? cl.args[0] : null) { case PVar(n): binderName = n; default: }
                var bodyStmts: Array<ElixirAST> = switch (cl.body.def) { case EBlock(ss): ss; default: [cl.body]; };
                for (bs in bodyStmts) switch (bs.def) {
                    case EIf(cond, thenBr, _):
                        if (thenContainsBinderIncrement(thenBr, binderName)) predicate = normalizeCond(cond, binderName);
                    default:
                }
            default:
        }
        if (predicate == null) return null;
        var safeBinder = safeBinderName(binderName);
        predicate = replaceVar(predicate, binderName, safeBinder);
        var fnNode = makeAST(EFn([{ args: [PVar(safeBinder)], guard: null, body: predicate }]));
        #if sys Sys.println('[CountEachToEnumCount] Rewriting Enum.each -> Enum.count'); #end
        return makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "count", [listExpr, fnNode]), node.metadata, node.pos);
    }

    static function thenContainsBinderIncrement(thenBr: ElixirAST, binder: String): Bool {
        var found = false;
        function walk(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EBinary(Match, left, rhs):
                    var lhs = switch (left.def) { case EVar(n): n; default: null; };
                    if (lhs == binder) switch (rhs.def) {
                        case EBinary(Add, l, r):
                            switch (l.def) { case EVar(n2) if (n2 == binder):
                                switch (r.def) { case EInteger(v) if (v == 1): found = true; default: }
                            default: }
                        default:
                    }
                case EMatch(pat, expr):
                    var lhs2 = switch (pat) { case PVar(nm): nm; default: null; };
                    if (lhs2 == binder) switch (expr.def) {
                        case EBinary(Add, l2, r2):
                            switch (l2.def) { case EVar(n3) if (n3 == binder):
                                switch (r2.def) { case EInteger(v2) if (v2 == 1): found = true; default: }
                            default: }
                        default:
                    }
                case EBlock(ss): for (s in ss) walk(s);
                default:
            }
        }
        walk(thenBr);
        return found;
    }

    static function normalizeCond(cond: ElixirAST, binder: String): ElixirAST {
        // Replace any single free lower-case variable with binder; leave fields on it intact
        var free = collectFreeLowerVars(cond, [binder]);
        if (free.length == 1) return replaceVar(cond, free[0], binder);
        return cond;
    }

    static function collectFreeLowerVars(n: ElixirAST, exclude:Array<String>): Array<String> {
        var names = new Map<String, Bool>();
        function add(name:String):Void {
            if (name == null || name.length == 0) return;
            if (exclude.indexOf(name) != -1) return;
            var c = name.charAt(0);
            if (c == '_' || c.toLowerCase() != c) return;
            if (name.indexOf('.') != -1) return; // module-like
            names.set(name, true);
        }
        function walkPattern(p:EPattern):Void {
            switch (p) {
                case PVar(_):
                case PTuple(es): for (e in es) walkPattern(e);
                case PList(es): for (e in es) walkPattern(e);
                case PCons(h,t): walkPattern(h); walkPattern(t);
                case PMap(kvs): for (kv in kvs) walkPattern(kv.value);
                case PStruct(_, fs): for (f in fs) walkPattern(f.value);
                case PPin(inner): walkPattern(inner);
                default:
            }
        }
        function walk(x: ElixirAST, inPattern:Bool): Void {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case EVar(nm) if (!inPattern): add(nm);
                case EField(obj, _): walk(obj, false);
                case EAccess(obj2, key): walk(obj2, false); walk(key, false);
                case EBlock(ss): for (s in ss) walk(s, false);
                case EIf(c,t,e): walk(c, false); walk(t, false); if (e != null) walk(e, false);
                case EBinary(_, l, r): walk(l, false); walk(r, false);
                case EMatch(pat, rhs): walk(rhs, false); walkPattern(pat);
                case ECase(expr, cs): walk(expr, false); for (c in cs) { walkPattern(c.pattern); walk(c.body, false); }
                case EFn(clauses): for (cl in clauses) { for (a in cl.args) walkPattern(a); walk(cl.body, false);} 
                case ERaw(_):
                case EString(_):
                default:
            }
        }
        walk(n, false);
        var out:Array<String> = [];
        for (k in names.keys()) out.push(k);
        return out;
    }

    static function replaceVar(n: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(name) if (name == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
                default: x;
            }
        });
    }

    static function safeBinderName(b: String): String {
        if (b == null || b.length == 0) return "elem";
        if (b.charAt(0) == '_') return b.substr(1) != null && b.substr(1).length > 0 ? b.substr(1) : "elem";
        return b;
    }
}

#end
