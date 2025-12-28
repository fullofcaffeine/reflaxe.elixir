package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

#if debug_count_each_to_count_ext
import reflaxe.elixir.ast.ElixirASTPrinter;
#end

private typedef EnumEachInfo = { listExpr: ElixirAST, fnArg: ElixirAST };
private typedef EachFnInfo = { binder: String, body: ElixirAST };

/**
 * CountEachToEnumCountTransforms
 *
 * WHAT
 * - Rewrites patterns of the form `Enum.each(list, fn binder -> if cond, do: binder = binder + 1 end)`
 *   into `Enum.count(list, fn binder -> cond end)`.
 * - Also rewrites common "external counter" loop patterns emitted from Haxe `count++` inside `for` loops:
 *   `count = 0; _ = Enum.each(list, fn binder -> if cond, do: count = count + 1 end end); count`
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

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class CountEachToEnumCountTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var rewrittenBlock = rewriteExternalCounterBlock(n, stmts);
                    rewrittenBlock == null ? n : rewrittenBlock;
                case EDo(stmts):
                    var rewrittenDo = rewriteExternalCounterBlock(n, stmts);
                    rewrittenDo == null ? n : rewrittenDo;
                case ERemoteCall(mod, func, args) if (isEnumEachFn(mod, func, args)):
                    var x = rewriteEachToCount(n, mod, func, args);
                    x == null ? n : x;
                case EMatch(pat, rhs):
                    var rewritten: Null<ElixirAST> = null;
                    switch (rhs.def) {
                        case ERemoteCall(remoteModule, remoteFunction, remoteArgs) if (isEnumEachFn(remoteModule, remoteFunction, remoteArgs)):
                            rewritten = rewriteEachToCount(rhs, remoteModule, remoteFunction, remoteArgs);
                        default:
                    }
                    rewritten == null ? n : makeASTWithMeta(EMatch(pat, rewritten), n.metadata, n.pos);
                case EBinary(Match, left, rhsExpr):
                    var rewrittenRight: Null<ElixirAST> = null;
                    switch (rhsExpr.def) {
                        case ERemoteCall(remoteModule, remoteFunction, remoteArgs) if (isEnumEachFn(remoteModule, remoteFunction, remoteArgs)):
                            rewrittenRight = rewriteEachToCount(rhsExpr, remoteModule, remoteFunction, remoteArgs);
                        default:
                    }
                    rewrittenRight == null ? n : makeASTWithMeta(EBinary(Match, left, rewrittenRight), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function isEnumModule(mod: ElixirAST): Bool {
        return switch (mod.def) {
            case EVar(m) if (m == "Enum"):
                true;
            case EAtom(a):
                var s: String = a;
                s == "Enum";
            default:
                false;
        };
    }

    static inline function isEnumEachCall(mod: ElixirAST, func: String, args: Array<ElixirAST>): Bool {
        return func == "each" && args != null && args.length == 2 && isEnumModule(mod);
    }

    static inline function isEnumEachFn(mod: ElixirAST, func: String, args: Array<ElixirAST>): Bool {
        if (!isEnumEachCall(mod, func, args)) return false;
        return switch (args[1].def) { case EFn(clauses) if (clauses.length == 1): true; default: false; };
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
        return makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "count", [listExpr, fnNode]), node.metadata, node.pos);
    }

    // ------------------------------------------------------------
    // External-counter rewrite: count = 0; _ = Enum.each(...); count
    // ------------------------------------------------------------

    static function rewriteExternalCounterBlock(node: ElixirAST, stmts: Array<ElixirAST>): Null<ElixirAST> {
        if (stmts == null || stmts.length < 3) return null;
        // Some lowerings emit nested EBlock statements that print as multiple top-level lines.
        // Flatten a single level so pattern matching is stable.
        stmts = flattenStatements(stmts);
        if (stmts.length < 3) return null;

        var lastExpr = unwrapParen(stmts[stmts.length - 1]);
        var countVar = switch (lastExpr.def) {
            case EVar(v): v;
            default: null;
        };
        if (countVar == null) {
            #if debug_count_each_to_count_ext
            // Keep debug noise low: only log when the block looks like a counter shape.
            if (stmts.length <= 6) trace('[CountEachToEnumCount] skip: last expr not var');
            #end
            return null;
        }
        #if debug_count_each_to_count_ext
        var debugCandidate = (countVar == "count" && stmts.length <= 6);
        #end

        // Require a simple init at the start: count = 0
        if (!isVarInitToZero(stmts[0], countVar)) {
            #if debug_count_each_to_count_ext
            if (debugCandidate) trace('[CountEachToEnumCount] skip: init not ' + countVar + ' = 0');
            #end
            return null;
        }

        // Find the Enum.each statement in the block (order can vary across lowerings)
        var each: Null<EnumEachInfo> = null;
        for (i in 1...(stmts.length - 1)) {
            var stmt = stmts[i];
            // Last statement is the `count` return; ignore here
            if (i == stmts.length - 1) continue;

            var extracted = extractEnumEach(stmt);
            if (extracted != null) {
                if (each != null) {
                    #if debug_count_each_to_count_ext
                    if (debugCandidate) trace('[CountEachToEnumCount] skip: multiple Enum.each statements');
                    #end
                    return null;
                }
                each = extracted;
                continue;
            }
            if (isIgnorableCounterStmt(stmt)) continue;

            #if debug_count_each_to_count_ext
            if (debugCandidate) {
                var printed = ElixirASTPrinter.print(unwrapParen(stmt), 0);
                trace('[CountEachToEnumCount] skip: unexpected stmt in counter block: ' + printed + ' def=' + Std.string(unwrapParen(stmt).def));
            }
            #end
            return null;
        }
        if (each == null) {
            #if debug_count_each_to_count_ext
            if (debugCandidate) trace('[CountEachToEnumCount] skip: no Enum.each statement found in counter block');
            #end
            return null;
        }

        var eachFn = extractEachFn(each.fnArg);
        if (eachFn == null) {
            #if debug_count_each_to_count_ext
            if (debugCandidate) trace('[CountEachToEnumCount] skip: could not extract each fn');
            #end
            return null;
        }

        var countPredicate = findCountPredicate(eachFn.body, countVar);
        if (countPredicate == null) {
            #if debug_count_each_to_count_ext
            if (debugCandidate) trace('[CountEachToEnumCount] skip: could not find count predicate for ' + countVar);
            #end
            return null;
        }

        var safeBinder = safeBinderName(eachFn.binder);
        var predicate = replaceVar(countPredicate, eachFn.binder, safeBinder);
        var fnNode = makeAST(EFn([{ args: [PVar(safeBinder)], guard: null, body: predicate }]));
        return makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "count", [each.listExpr, fnNode]), node.metadata, node.pos);
    }

    static function isVarInitToZero(stmt: ElixirAST, name: String): Bool {
        var s = unwrapParen(stmt);
        if (s == null || s.def == null || name == null) return false;
        return switch (s.def) {
            case EBinary(Match, left, rhs):
                switch (left.def) {
                    case EVar(v) if (v == name):
                        switch (rhs.def) { case EInteger(i) if (i == 0): true; default: false; }
                    default: false;
                }
            case EMatch(pattern, rhs):
                var lhs = switch (pattern) { case PVar(varName): varName; default: null; };
                if (lhs == name) switch (rhs.def) { case EInteger(intValue) if (intValue == 0): true; default: false; } else false;
            default:
                false;
        };
    }

    static function isIgnorableCounterStmt(stmt: ElixirAST): Bool {
        var s = unwrapParen(stmt);
        if (s == null || s.def == null) return false;
        // Common sentinel emitted by some lowerings: `_g = 0` (or similar underscored temp = 0)
        return switch (s.def) {
            case EBinary(Match, left, rhs):
                var lhs = switch (left.def) { case EVar(v): v; default: null; };
                if (lhs == null || lhs.charAt(0) != '_') return false;
                switch (rhs.def) { case EInteger(i) if (i == 0): true; default: false; }
            case EMatch(pattern, rhs):
                var lhs = switch (pattern) { case PVar(varName): varName; default: null; };
                if (lhs == null || lhs.charAt(0) != '_') return false;
                switch (rhs.def) { case EInteger(intValue) if (intValue == 0): true; default: false; }
            default:
                false;
        };
    }

    static function extractEnumEach(stmt: ElixirAST): Null<EnumEachInfo> {
        var s = unwrapParen(stmt);
        if (s == null || s.def == null) return null;
        var call: Null<ElixirAST> = null;
        switch (s.def) {
            case ERemoteCall(_, _, _):
                call = s;
            case EMatch(_, rhs):
                call = rhs;
            case EBinary(Match, _, rhs):
                call = rhs;
            default:
        }
        if (call == null) return null;
        call = unwrapParen(call);
        return switch (call.def) {
            case ERemoteCall(mod, func, args) if (isEnumEachCall(mod, func, args)):
                { listExpr: args[0], fnArg: args[1] };
            default:
                null;
        };
    }

    static function extractEachFn(fnArg: ElixirAST): Null<EachFnInfo> {
        var fnNode = unwrapToSingleClauseEFn(fnArg);
        if (fnNode == null) return null;
        return switch (fnNode.def) {
            case EFn(clauses) if (clauses.length == 1):
                var cl = clauses[0];
                var binderName: Null<String> = null;
                if (cl.args != null && cl.args.length >= 1) switch (cl.args[0]) { case PVar(n): binderName = n; default: }
                binderName == null ? null : { binder: binderName, body: cl.body };
            default:
                null;
        };
    }

    static function unwrapToSingleClauseEFn(node: ElixirAST): Null<ElixirAST> {
        if (node == null || node.def == null) return null;
        return switch (node.def) {
            case EParen(inner):
                unwrapToSingleClauseEFn(inner);
            case EFn(_):
                node;
            // Handle a common wrapper shape: (fn -> fn binder -> ... end end).()
            case ECall(target, _, args) if (target != null && (args == null || args.length == 0)):
                var outer = unwrapToSingleClauseEFn(target);
                if (outer == null) return null;
                switch (outer.def) {
                    case EFn(clauses) if (clauses.length == 1):
                        var cl = clauses[0];
                        if (cl.args != null && cl.args.length != 0) return null;
                        // Outer body is the inner fn (possibly wrapped in a block)
                        switch (cl.body.def) {
                            case EFn(_):
                                cl.body;
                            case EBlock(ss) if (ss.length == 1 && ss[0] != null && ss[0].def != null):
                                switch (ss[0].def) { case EFn(_): ss[0]; default: null; }
                            default:
                                null;
                        }
                    default:
                        null;
                }
            default:
                null;
        };
    }

    static function unwrapParen(node: ElixirAST): ElixirAST {
        var cur = node;
        while (cur != null && cur.def != null) {
            switch (cur.def) {
                case EParen(inner):
                    cur = inner;
                default:
                    return cur;
            }
        }
        return cur;
    }

    static function flattenStatements(stmts: Array<ElixirAST>): Array<ElixirAST> {
        var out: Array<ElixirAST> = [];
        for (s in stmts) {
            var unwrapped = unwrapParen(s);
            if (unwrapped == null || unwrapped.def == null) continue;
            switch (unwrapped.def) {
                case EBlock(inner) | EDo(inner):
                    for (i in inner) out.push(i);
                default:
                    out.push(s);
            }
        }
        return out;
    }

    static function findCountPredicate(fnBody: ElixirAST, countVar: String): Null<ElixirAST> {
        if (fnBody == null || fnBody.def == null) return null;
        var stmts: Array<ElixirAST> = switch (fnBody.def) { case EBlock(ss): ss; default: [fnBody]; };
        for (s in stmts) {
            switch (s.def) {
                case EIf(cond, thenBr, _):
                    if (thenContainsVarIncrement(thenBr, countVar)) return cond;
                default:
            }
        }
        return null;
    }

    static function thenContainsVarIncrement(thenBr: ElixirAST, varName: String): Bool {
        var found = false;
        function isVarPlusOne(expr: ElixirAST): Bool {
            if (expr == null || expr.def == null) return false;
            return switch (expr.def) {
                case EBinary(Add, l, r):
                    switch (l.def) { case EVar(n) if (n == varName):
                        switch (r.def) { case EInteger(i) if (i == 1): true; default: false; }
                    default: false; }
                default:
                    false;
            };
        }
        function walk(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EBinary(Match, left, rhs):
                    var lhs = switch (left.def) { case EVar(n): n; default: null; };
                    if (lhs == varName && isVarPlusOne(rhs)) found = true;
                    else { walk(left); walk(rhs); }
                case EMatch(pat, expr):
                    var lhsName = switch (pat) { case PVar(nm): nm; default: null; };
                    if (lhsName == varName && isVarPlusOne(expr)) found = true;
                    else walk(expr);
                case EBlock(ss): for (s in ss) walk(s);
                case EParen(e): walk(e);
                default:
            }
        }
        walk(thenBr);
        return found;
    }

    static function thenContainsBinderIncrement(thenBr: ElixirAST, binder: String): Bool {
        var found = false;
        function walk(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EBinary(Match, left, rhs):
                    var lhs = switch (left.def) { case EVar(n): n; default: null; };
                    if (lhs == binder) {
                        switch (rhs.def) {
                            case EBinary(Add, addLeft, addRight):
                                var addVarName = switch (addLeft.def) { case EVar(n): n; default: null; };
                                var addIsOne = switch (addRight.def) { case EInteger(v) if (v == 1): true; default: false; };
                                if (addVarName == binder && addIsOne) found = true;
                            default:
                        }
                    }
                case EMatch(pat, expr):
                    var lhsName = switch (pat) { case PVar(nm): nm; default: null; };
                    if (lhsName == binder) {
                        switch (expr.def) {
                            case EBinary(Add, addLeft, addRight):
                                var addVarName = switch (addLeft.def) { case EVar(n): n; default: null; };
                                var addIsOne = switch (addRight.def) { case EInteger(v) if (v == 1): true; default: false; };
                                if (addVarName == binder && addIsOne) found = true;
                            default:
                        }
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
        if (b == null || b.length == 0) return "item";
        if (b.charAt(0) == '_') return b.substr(1) != null && b.substr(1).length > 0 ? b.substr(1) : "item";
        return b;
    }
}

#end
