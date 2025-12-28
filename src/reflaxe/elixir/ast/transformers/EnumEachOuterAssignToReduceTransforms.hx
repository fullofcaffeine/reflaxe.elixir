package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import haxe.ds.StringMap;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
#if debug_enum_each_outer_assign
import reflaxe.elixir.ast.ElixirASTPrinter;
#end

/**
 * EnumEachOuterAssignToReduceTransforms
 *
 * WHAT
 * - Rewrites `Enum.each/2` loops that attempt to "mutate" an outer variable (via `var = ...`)
 *   into `Enum.reduce/3` so the updated value is threaded and survives outside the closure.
 *
 * WHY
 * - In Elixir, variables captured by anonymous functions are immutable from the caller scope.
 *   A pattern like:
 *     most_recent = init
 *     Enum.each(xs, fn x -> if cond, do: most_recent = x end)
 *     most_recent
 *   does not update `most_recent` outside the closure and triggers `--warnings-as-errors`
 *   about rebinding a variable from the outer context.
 *
 * HOW
 * - In statement lists (EBlock/EDo), find an `Enum.each(list, fn binder -> if cond do var = rhs end end)`
 *   where:
 *   - `var` is bound earlier in the same statement list
 *   - `var` is referenced after the Enum.each statement
 * - Replace the each statement with:
 *     var = Enum.reduce(list, var, fn binder, var_acc ->
 *       if cond', do: rhs', else: var_acc
 *     end)
 *   and rewrite `cond`/`rhs` to reference `var_acc` instead of `var`.
 *
 * EXAMPLES
 * Haxe:
 *   var mostRecent = userNotifications[0];
 *   for (i in 1...userNotifications.length) {
 *     if (userNotifications[i].timestamp > mostRecent.timestamp) mostRecent = userNotifications[i];
 *   }
 * Elixir (before):
 *   most_recent = user_notifications[0]
 *   _ = Enum.each(range, fn i ->
 *     if user_notifications[i].timestamp > most_recent.timestamp do
 *       most_recent = user_notifications[i]
 *     end
 *   end)
 * Elixir (after):
 *   most_recent =
 *     Enum.reduce(range, most_recent, fn i, most_recent_acc ->
 *       if user_notifications[i].timestamp > most_recent_acc.timestamp,
 *         do: user_notifications[i],
 *         else: most_recent_acc
 *     end)
 */
class EnumEachOuterAssignToReduceTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var rewritten = rewriteStatements(stmts);
                    rewritten == stmts ? n : makeASTWithMeta(EBlock(rewritten), n.metadata, n.pos);
                case EDo(stmts):
                    var rewrittenDo = rewriteStatements(stmts);
                    rewrittenDo == stmts ? n : makeASTWithMeta(EDo(rewrittenDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteStatements(stmts: Array<ElixirAST>): Array<ElixirAST> {
        // This pass relies on sequential context ("bound so far" + "used later"),
        // so we thread that context through nested EBlock/EDo statements which are
        // scope-transparent in Elixir.
        var boundSoFar: StringMap<Bool> = new StringMap();
        return rewriteStatementsWithContext(stmts, boundSoFar, []);
    }

    static function rewriteStatementsWithContext(
        stmts: Array<ElixirAST>,
        boundSoFar: StringMap<Bool>,
        followStmts: Array<ElixirAST>
    ): Array<ElixirAST> {
        if (stmts == null || stmts.length < 1) return stmts;

        var out: Array<ElixirAST> = [];

        for (index in 0...stmts.length) {
            var stmt = stmts[index];

            // Nested blocks in statement position do not introduce a new scope. Process
            // their contents with the current sequential context and include the outer
            // continuation for "used later" checks.
            switch (stmt.def) {
                case EBlock(innerStmts):
                    var innerFollow = stmts.slice(index + 1).concat(followStmts);
                    var rewrittenInner = rewriteStatementsWithContext(innerStmts, boundSoFar, innerFollow);
                    var rewrittenStmt = makeASTWithMeta(EBlock(rewrittenInner), stmt.metadata, stmt.pos);
                    out.push(rewrittenStmt);
                    continue;
                case EDo(innerStatements):
                    var innerFollowStatements = stmts.slice(index + 1).concat(followStmts);
                    var rewrittenInnerStatements = rewriteStatementsWithContext(innerStatements, boundSoFar, innerFollowStatements);
                    var rewrittenStmt = makeASTWithMeta(EDo(rewrittenInnerStatements), stmt.metadata, stmt.pos);
                    out.push(rewrittenStmt);
                    continue;
                default:
            }

#if debug_enum_each_outer_assign
            var stmtPreview = ElixirASTPrinter.printAST(stmt);
            if (stmtPreview != null && stmtPreview.indexOf("Enum.each") != -1) {
                trace('[EnumEachOuterAssignToReduce] candidate stmt=' + stmtPreview);
            }
#end

            var eachInfo = extractEnumEachStatement(stmt);
            if (eachInfo == null) {
                out.push(stmt);
                bindFromStatement(stmt, boundSoFar);
                continue;
            }

            var eachCall = eachInfo.eachCall;
            var collectionExpr = eachInfo.collection;
            var fnNode = eachInfo.fnArg;

            var eachFn = extractSingleClauseFn(fnNode);
            if (eachFn == null) {
#if debug_enum_each_outer_assign
                trace('[EnumEachOuterAssignToReduce] skip: fn arg is not single-clause fn');
#end
                out.push(stmt);
                bindFromStatement(stmt, boundSoFar);
                continue;
            }

            var binderName = eachFn.binder;
            var body = eachFn.body;

            var assignment = extractSingleIfAssignment(body);
            if (assignment == null) {
#if debug_enum_each_outer_assign
                trace('[EnumEachOuterAssignToReduce] skip: body is not single-if-assignment');
#end
                out.push(stmt);
                bindFromStatement(stmt, boundSoFar);
                continue;
            }

            var assignedName = assignment.name;
            if (!boundSoFar.exists(assignedName)) {
                // If the name wasn't bound before, it is local to the closure and not a cross-scope mutation.
#if debug_enum_each_outer_assign
                var boundNames: Array<String> = [];
                for (k in boundSoFar.keys()) boundNames.push(k);
                trace('[EnumEachOuterAssignToReduce] skip: assignedName not bound earlier name=' + assignedName + ' boundSoFar=' + boundNames.join(","));
                if (index > 0) {
                    trace('[EnumEachOuterAssignToReduce] prev stmt=' + ElixirASTPrinter.printAST(stmts[index - 1]));
                }
#end
                out.push(stmt);
                bindFromStatement(stmt, boundSoFar);
                continue;
            }

            // Only rewrite when the assigned variable is used later in this statement list.
            if (!anyStatementUsesVar(stmts.slice(index + 1).concat(followStmts), assignedName)) {
#if debug_enum_each_outer_assign
                trace('[EnumEachOuterAssignToReduce] skip: assignedName not used later name=' + assignedName);
#end
                out.push(stmt);
                bindFromStatement(stmt, boundSoFar);
                continue;
            }

#if debug_enum_each_outer_assign
            trace('[EnumEachOuterAssignToReduce] rewrite: name=' + assignedName + ' binder=' + binderName);
#end

            var accName = assignedName + "_acc";

            var conditionWithAcc = replaceVar(assignment.condition, assignedName, accName);
            var rhsWithAcc = replaceVar(assignment.rhs, assignedName, accName);

            var reduceFn = makeAST(EFn([{
                args: [PVar(binderName), PVar(accName)],
                guard: null,
                body: makeAST(EIf(conditionWithAcc, rhsWithAcc, makeAST(EVar(accName))))
            }]));
            var reduceCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce", [collectionExpr, makeAST(EVar(assignedName)), reduceFn]));

            var rewrittenStmt = makeASTWithMeta(EMatch(PVar(assignedName), reduceCall), stmt.metadata, stmt.pos);
            out.push(rewrittenStmt);
            bindFromStatement(rewrittenStmt, boundSoFar);
        }

        return out;
    }

    private static function extractEnumEachStatement(stmt: ElixirAST): Null<{ eachCall: ElixirAST, collection: ElixirAST, fnArg: ElixirAST }> {
        if (stmt == null || stmt.def == null) return null;

        var direct = extractEnumEachCall(stmt);
        if (direct != null) return direct;

        // Handle `_ = Enum.each(...)` and similar wrappers.
        return switch (stmt.def) {
            case EMatch(PVar("_"), rhs):
                extractEnumEachCall(rhs);
            case EMatch(PWildcard, rhs):
                extractEnumEachCall(rhs);
            case EBinary(Match, left, rhs):
                var unwrappedLeft = unwrapParen(left);
                switch (unwrappedLeft.def) { case EVar("_"): extractEnumEachCall(rhs); default: null; }
            default:
                null;
        };
    }

    private static function extractEnumEachCall(node: ElixirAST): Null<{ eachCall: ElixirAST, collection: ElixirAST, fnArg: ElixirAST }> {
        if (node == null || node.def == null) return null;
        var unwrapped = unwrapParen(node);
        if (unwrapped == null || unwrapped.def == null) return null;
        return switch (unwrapped.def) {
            case ERemoteCall(mod, "each", args) if (isEnum(mod) && args != null && args.length == 2):
                { eachCall: unwrapped, collection: args[0], fnArg: args[1] };
            case ECall(target, "each", args) if (target != null && isEnum(target) && args != null && args.length == 2):
                { eachCall: unwrapped, collection: args[0], fnArg: args[1] };
            default:
                null;
        };
    }

    private static function isEnum(mod: ElixirAST): Bool {
        return switch (mod.def) {
            case EVar("Enum"): true;
            case EAtom(a):
                var s: String = a;
                s == "Enum";
            default: false;
        };
    }

    private static function extractSingleClauseFn(fnNode: ElixirAST): Null<{ binder: String, body: ElixirAST }> {
        if (fnNode == null || fnNode.def == null) return null;
        return switch (fnNode.def) {
            case EFn(clauses) if (clauses != null && clauses.length == 1):
                var clause = clauses[0];
                var binderName = "_";
                if (clause.args != null && clause.args.length > 0) {
                    switch (clause.args[0]) {
                        case PVar(n): binderName = n;
                        case PWildcard: binderName = "_";
                        default:
                    }
                }
                { binder: binderName, body: clause.body };
            default:
                null;
        };
    }

    private static function extractSingleIfAssignment(body: ElixirAST): Null<{ condition: ElixirAST, name: String, rhs: ElixirAST }> {
        if (body == null || body.def == null) return null;

        // Accept `if cond do <assign> end` (no else) with a single assignment in the then-branch.
        var unwrapped = unwrapSingleStatementBlock(body);
        return switch (unwrapped.def) {
            case EIf(cond, thenBranch, elseBranch) if (elseBranch == null || isNilExpr(elseBranch)):
                var assign = extractAssignment(thenBranch);
                assign == null ? null : { condition: cond, name: assign.name, rhs: assign.rhs };
            default:
                null;
        };
    }

    private static function isNilExpr(e: ElixirAST): Bool {
        return e != null && e.def != null && switch (e.def) { case ENil: true; default: false; };
    }

    private static function unwrapParen(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case EParen(inner): unwrapParen(inner);
            default: e;
        };
    }

    private static function unwrapSingleStatementBlock(e: ElixirAST): ElixirAST {
        var unwrapped = unwrapParen(e);
        return switch (unwrapped.def) {
            case EBlock(stmts) if (stmts != null && stmts.length == 1):
                unwrapSingleStatementBlock(stmts[0]);
            case EDo(stmts) if (stmts != null && stmts.length == 1):
                unwrapSingleStatementBlock(stmts[0]);
            default:
                unwrapped;
        };
    }

    private static function extractAssignment(node: ElixirAST): Null<{ name: String, rhs: ElixirAST }> {
        if (node == null || node.def == null) return null;
        var normalized = switch (node.def) {
            case EBlock(stmts) if (stmts != null && stmts.length == 1):
                stmts[0];
            case EDo(stmts) if (stmts != null && stmts.length == 1):
                stmts[0];
            default:
                node;
        };
        var unwrapped = unwrapParen(normalized);
        return switch (unwrapped.def) {
            case EMatch(PVar(name), rhs):
                { name: name, rhs: rhs };
            case EBinary(Match, left, rhs):
                var unwrappedLeft = unwrapParen(left);
                switch (unwrappedLeft.def) {
                    case EVar(varName):
                        { name: varName, rhs: rhs };
                    default:
                        null;
                }
            default:
                null;
        };
    }

    private static function bindFromStatement(stmt: ElixirAST, out: StringMap<Bool>): Void {
        if (stmt == null || stmt.def == null) return;
        switch (stmt.def) {
            case EMatch(PVar(name), _):
                out.set(name, true);
            case EBinary(Match, left, _):
                var unwrappedLeft = unwrapParen(left);
                switch (unwrappedLeft.def) { case EVar(varName): out.set(varName, true); default: }
            default:
        }
    }

    private static function anyStatementUsesVar(stmts: Array<ElixirAST>, name: String): Bool {
        if (stmts == null || stmts.length == 0) return false;
        for (s in stmts) if (exprUsesVar(s, name)) return true;
        return false;
    }

    private static function exprUsesVar(expr: ElixirAST, name: String): Bool {
        if (expr == null || expr.def == null) return false;
        var found = false;

        function visit(e: ElixirAST): Void {
            if (found || e == null || e.def == null) return;

            switch (e.def) {
                case EVar(v) if (v == name):
                    found = true;
                    return;
                case EFn(_):
                    // Do not treat nested closures as uses in the outer statement list.
                    return;

                case EBinary(Match, _left, rhs):
                    // Ignore the binder; only RHS can be an expression use.
                    visit(rhs);
                case EMatch(_pat, rhs):
                    visit(rhs);

                case EBlock(stmts):
                    for (s in stmts) visit(s);
                case EDo(statements):
                    for (statement in statements) visit(statement);
                case EIf(c, t, el):
                    visit(c);
                    visit(t);
                    if (el != null) visit(el);
                case EUnless(cu, bu, eu):
                    visit(cu);
                    visit(bu);
                    if (eu != null) visit(eu);
                case ECond(clauses):
                    for (cl in clauses) {
                        visit(cl.condition);
                        visit(cl.body);
                    }
                case ECase(subject, clauses):
                    visit(subject);
                    for (clause in clauses) {
                        if (clause.guard != null) visit(clause.guard);
                        visit(clause.body);
                    }
                case EWith(clauses, doBlock, elseBlock):
                    for (clause in clauses) visit(clause.expr);
                    visit(doBlock);
                    if (elseBlock != null) visit(elseBlock);
                case EBinary(_, l, r):
                    visit(l);
                    visit(r);
                case EUnary(_, inner):
                    visit(inner);
                case EPipe(left, right):
                    visit(left);
                    visit(right);
                case ECall(tgt, _fn, args):
                    if (tgt != null) visit(tgt);
                    for (a in args) visit(a);
                case ERemoteCall(mod, _functionName, args):
                    visit(mod);
                    for (arg in args) visit(arg);
                case EField(t, _):
                    visit(t);
                case EAccess(target, k):
                    visit(target);
                    visit(k);
                case ETuple(elems) | EList(elems):
                    for (elem in elems) visit(elem);
                case EMap(pairs):
                    for (p in pairs) { visit(p.key); visit(p.value); }
                case EKeywordList(pairs):
                    for (pair in pairs) visit(pair.value);
                case EStruct(_m, fields):
                    for (f in fields) visit(f.value);
                case EStructUpdate(base, fields):
                    visit(base);
                    for (field in fields) visit(field.value);
                case ERange(a, b, _, step):
                    visit(a);
                    visit(b);
                    if (step != null) visit(step);
                case EParen(inner):
                    visit(inner);
                case EFor(gens, filters, body, into, _uniq):
                    for (g in gens) visit(g.expr);
                    for (filter in filters) visit(filter);
                    if (body != null) visit(body);
                    if (into != null) visit(into);
                case ECapture(capturedExpr, _):
                    visit(capturedExpr);
                case EReceive(clauses, after):
                    for (clause in clauses) {
                        if (clause.guard != null) visit(clause.guard);
                        visit(clause.body);
                    }
                    if (after != null) {
                        visit(after.timeout);
                        visit(after.body);
                    }
                case ETry(tryBody, rescueClauses, catchClauses, afterBlock, elseBlock):
                    visit(tryBody);
                    for (r in rescueClauses) visit(r.body);
                    for (catchClause in catchClauses) visit(catchClause.body);
                    if (afterBlock != null) visit(afterBlock);
                    if (elseBlock != null) visit(elseBlock);
                case ERaise(exception, attributes):
                    visit(exception);
                    if (attributes != null) visit(attributes);
                case EThrow(value):
                    visit(value);
                case ESend(target, message):
                    visit(target);
                    visit(message);
                case EModuleAttribute(_name, value):
                    visit(value);
                case EQuote(options, expr):
                    for (o in options) visit(o);
                    visit(expr);
                case EUnquote(expr) | EUnquoteSplicing(expr):
                    visit(expr);
                case EUse(_module, options):
                    for (option in options) visit(option);
                case EFragment(_tag, attrs, children):
                    for (attribute in attrs) visit(attribute.value);
                    for (child in children) visit(child);
                default:
            }
        }

        visit(expr);
        return found;
    }

    private static function replaceVar(expr: ElixirAST, fromName: String, toName: String): ElixirAST {
        return ElixirASTTransformer.transformNode(expr, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (v == fromName):
                    makeASTWithMeta(EVar(toName), n.metadata, n.pos);
                case EFn(_):
                    // Nested closures are their own scope.
                    n;
                default:
                    n;
            }
        });
    }
}

#end
