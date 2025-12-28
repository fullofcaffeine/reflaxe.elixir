package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import haxe.ds.StringMap;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
#if debug_static_var_mutation
import reflaxe.elixir.ast.ElixirASTPrinter;
#if macro
import haxe.macro.Context;
#end
#end

/**
 * StaticVarMutationRewriteTransforms
 *
 * WHAT
 * - Repairs Haxe static var "mutation" patterns for the Elixir target by ensuring the
 *   generated code actually persists the new value via the static accessor setter.
 * - Handles common immutable update forms emitted for Array.push and Map.set:
 *   - `MyMod.users() ++ [x]` (ignored concat result)
 *   - `tmp = MyMod.preferences(); _ = Map.put(tmp, k, v)` (discarded Map.put result)
 *
 * WHY
 * - Haxe static fields are mutable; on the Elixir target they are implemented as
 *   accessor functions (`field/0` getter + `field/1` setter) backed by process storage.
 * - If we emit pure operations like `users() ++ [x]` without calling the setter, the
 *   update is lost and Elixir warns under `--warnings-as-errors` when the result is ignored.
 *
 * HOW
 * - For each module, discover static accessor names by detecting `field/0` and `field/1`
 *   functions whose bodies call `__haxe_static_get__/2` and `__haxe_static_put__/2`.
 * - Rewrite in function bodies:
 *   1) Standalone list concat on a static getter:
 *        `Mod.field() ++ rhs` → `Mod.field(Mod.field() ++ rhs)`
 *   2) Temp-based updates:
 *        `tmp = Mod.field(); _ = Map.put(tmp, k, v)`
 *        → `tmp = Map.put(tmp, k, v); Mod.field(tmp)`
 *      and similarly for `tmp = tmp ++ rhs`.
 *
 * EXAMPLES
 * Haxe:
 *   static var users:Array<User> = [];
 *   users.push(u);
 * Elixir (before):
 *   MyMod.users() ++ [u]
 * Elixir (after):
 *   MyMod.users(MyMod.users() ++ [u])
 *
 * Haxe:
 *   static var prefs:Map<Int, Pref> = [];
 *   prefs.set(id, pref);
 * Elixir (before):
 *   tmp = MyMod.prefs()
 *   _ = Map.put(tmp, id, pref)
 * Elixir (after):
 *   tmp = Map.put(tmp, id, pref)
 *   MyMod.prefs(tmp)
 */
class StaticVarMutationRewriteTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EModule(moduleName, attrs, body):
                    #if debug_static_var_mutation
                    if (shouldDebugModule(moduleName)) {
                        debug('[StaticVarMutationRewrite] visit module=' + moduleName);
                    }
                    #end
                    var accessors = findStaticAccessors(body);
                    if (accessors == null || accessors.keys().hasNext() == false) {
                        #if debug_static_var_mutation
                        if (shouldDebugModule(moduleName)) {
                            debug('[StaticVarMutationRewrite] skip: no accessors');
                            debugDumpDefs(body);
                        }
                        #end
                        node;
                    } else {
                        #if debug_static_var_mutation
                        if (shouldDebugModule(moduleName)) {
                            debug('[StaticVarMutationRewrite] module=' + moduleName + ' accessors=' + formatAccessorNames(accessors));
                        }
                        #end
                        var changed = false;
                        var rewrittenBody: Array<ElixirAST> = [];
                        for (child in body) {
                            var next = rewriteWithAccessors(child, moduleName, accessors);
                            if (next != child) changed = true;
                            rewrittenBody.push(next);
                        }
                        changed
                            ? makeASTWithMeta(EModule(moduleName, attrs, rewrittenBody), node.metadata, node.pos)
                            : node;
                    }
                case EDefmodule(moduleName, doBlock):
                    #if debug_static_var_mutation
                    if (shouldDebugModule(moduleName)) {
                        debug('[StaticVarMutationRewrite] visit defmodule=' + moduleName);
                    }
                    #end
                    var bodyStatements = extractStatementsFromDoBlock(doBlock);
                    var accessors = findStaticAccessors(bodyStatements);
                    if (accessors == null || accessors.keys().hasNext() == false) {
                        #if debug_static_var_mutation
                        if (shouldDebugModule(moduleName)) {
                            debug('[StaticVarMutationRewrite] skip: no accessors');
                            debugDumpDefs(bodyStatements);
                        }
                        #end
                        node;
                    } else {
                        #if debug_static_var_mutation
                        if (shouldDebugModule(moduleName)) {
                            debug('[StaticVarMutationRewrite] defmodule=' + moduleName + ' accessors=' + formatAccessorNames(accessors));
                        }
                        #end
                        var changed = false;
                        var rewrittenStatements: Array<ElixirAST> = [];
                        for (child in bodyStatements) {
                            var next = rewriteWithAccessors(child, moduleName, accessors);
                            if (next != child) changed = true;
                            rewrittenStatements.push(next);
                        }
                        changed
                            ? makeASTWithMeta(EDefmodule(moduleName, rebuildDoBlock(doBlock, rewrittenStatements)), node.metadata, node.pos)
                            : node;
                    }
                default:
                    node;
            }
        });
    }

    private static function extractStatementsFromDoBlock(doBlock: ElixirAST): Array<ElixirAST> {
        if (doBlock == null || doBlock.def == null) return [];
        return switch (doBlock.def) {
            case EDo(stmts): stmts != null ? stmts : [];
            case EBlock(stmts): stmts != null ? stmts : [];
            default: [doBlock];
        };
    }

    private static function rebuildDoBlock(original: ElixirAST, statements: Array<ElixirAST>): ElixirAST {
        if (original == null || original.def == null) return makeAST(EDo(statements));
        return switch (original.def) {
            case EDo(_):
                makeASTWithMeta(EDo(statements), original.metadata, original.pos);
            case EBlock(_):
                makeASTWithMeta(EBlock(statements), original.metadata, original.pos);
            default:
                if (statements != null && statements.length == 1) {
                    statements[0];
                } else {
                    makeASTWithMeta(EDo(statements), original.metadata, original.pos);
                }
        };
    }

    #if debug_static_var_mutation
    private static function shouldDebugModule(moduleName: String): Bool {
        #if macro
        var filter = Context.definedValue("debug_static_var_mutation_filter");
        #else
        var filter: String = null;
        #end
        return filter == null || filter == "" || (moduleName != null && moduleName.indexOf(filter) != -1);
    }

    private static inline function debug(message: String): Void {
        #if sys
        Sys.println(message);
        Sys.stdout().flush();
        #else
        trace(message);
        #end
    }

    private static function formatAccessorNames(accessors: StringMap<Bool>): String {
        if (accessors == null) return "[]";
        var names: Array<String> = [];
        for (name in accessors.keys()) names.push(name);
        return "[" + names.join(", ") + "]";
    }

    private static function debugDumpDefs(stmts: Array<ElixirAST>): Void {
        if (stmts == null) return;
        var defs: Array<String> = [];
        for (s in stmts) {
            if (s == null || s.def == null) continue;
            switch (s.def) {
                case EDef(name, args, _g, _b):
                    defs.push('def ' + name + '/' + (args != null ? Std.string(args.length) : "null"));
                case EDefp(privateName, privateArgs, _guard, _body):
                    defs.push('defp ' + privateName + '/' + (privateArgs != null ? Std.string(privateArgs.length) : "null"));
                default:
            }
        }
        debug('[StaticVarMutationRewrite] defs=' + defs.join(", "));
    }
    #end

    static function rewriteWithAccessors(node: ElixirAST, moduleName: String, accessors: StringMap<Bool>): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var rewritten = rewriteStatementList(stmts, moduleName, accessors);
                    rewritten == stmts ? n : makeASTWithMeta(EBlock(rewritten), n.metadata, n.pos);
                case EDo(stmts):
                    var rewrittenDo = rewriteStatementList(stmts, moduleName, accessors);
                    rewrittenDo == stmts ? n : makeASTWithMeta(EDo(rewrittenDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteStatementList(stmts: Array<ElixirAST>, moduleName: String, accessors: StringMap<Bool>): Array<ElixirAST> {
        if (stmts == null || stmts.length == 0) return stmts;

        var moduleExpr = makeAST(EVar(moduleName));
        var out: Array<ElixirAST> = [];

        // Track temps initialized from static getters: tmp -> accessor name
        var tempToAccessor: StringMap<String> = new StringMap();

        for (stmt in stmts) {
            var rewritten: Null<ElixirAST> = null;

            #if debug_static_var_mutation
            if (shouldDebugModule(moduleName)) {
                switch (stmt.def) {
                    case EBinary(Concat, left, _right):
                        debug('[StaticVarMutationRewrite] saw ++ stmt=' + ElixirASTPrinter.print(stmt, 0));
                        debug('[StaticVarMutationRewrite]   lhs def=' + Std.string(left.def));
                    default:
                }
            }
            #end

            // 1) Standalone concat: Mod.field() ++ rhs
            var concatInfo = extractStaticGetterConcat(stmt, moduleExpr, accessors);
            if (concatInfo != null) {
                #if debug_static_var_mutation
                if (shouldDebugModule(moduleName)) {
                    debug('[StaticVarMutationRewrite] rewrite ++ via accessor=' + concatInfo.accessor);
                }
                #end
                rewritten = makeASTWithMeta(
                    ERemoteCall(concatInfo.moduleExpr, concatInfo.accessor, [concatInfo.concatExpr]),
                    stmt.metadata,
                    stmt.pos
                );
            }

            // 2) temp = Mod.field()
            if (rewritten == null) {
                var tmpInit = extractTempInitFromStaticGetter(stmt, moduleExpr, accessors);
                if (tmpInit != null) {
                    tempToAccessor.set(tmpInit.tempName, tmpInit.accessor);
                    rewritten = stmt;
                }
            }

            // 3) Rewrite `_ = Map.put(tmp, k, v)` or `tmp = Map.put(tmp, k, v)` and persist via setter.
            if (rewritten == null) {
                var tmpUpdate = extractTempMapPutUpdate(stmt);
                if (tmpUpdate != null && tempToAccessor.exists(tmpUpdate.tempName)) {
                    var accessorName = tempToAccessor.get(tmpUpdate.tempName);
                    // Ensure tmp is updated, then call setter with tmp.
                    var tmpAssign = makeASTWithMeta(EMatch(PVar(tmpUpdate.tempName), tmpUpdate.putCall), stmt.metadata, stmt.pos);
                    var setterCall = makeASTWithMeta(
                        ERemoteCall(moduleExpr, accessorName, [makeAST(EVar(tmpUpdate.tempName))]),
                        stmt.metadata,
                        stmt.pos
                    );
                    out.push(tmpAssign);
                    out.push(setterCall);
                    continue;
                }
            }

            // 4) Rewrite `tmp = tmp ++ rhs` (or standalone `tmp ++ rhs`) and persist via setter.
            if (rewritten == null) {
                var tmpConcat = extractTempConcatUpdate(stmt);
                if (tmpConcat != null && tempToAccessor.exists(tmpConcat.tempName)) {
                    var accessorName = tempToAccessor.get(tmpConcat.tempName);
                    var tmpAssign = makeASTWithMeta(EMatch(PVar(tmpConcat.tempName), tmpConcat.concatExpr), stmt.metadata, stmt.pos);
                    var setterCall = makeASTWithMeta(
                        ERemoteCall(moduleExpr, accessorName, [makeAST(EVar(tmpConcat.tempName))]),
                        stmt.metadata,
                        stmt.pos
                    );
                    out.push(tmpAssign);
                    out.push(setterCall);
                    continue;
                }
            }

            // Default: keep stmt (or rewritten variant)
            out.push(rewritten != null ? rewritten : stmt);
        }

        return out;
    }

    private static function findStaticAccessors(body: Array<ElixirAST>): StringMap<Bool> {
        if (body == null || body.length == 0) return null;

        var getters: StringMap<Bool> = new StringMap();
        var setters: StringMap<Bool> = new StringMap();

        for (node in body) {
            switch (node.def) {
                case EDef(name, args, _guards, fnBody):
                    if (args == null) continue;
                    if (args.length == 0 && containsLocalCall(fnBody, "__haxe_static_get__")) getters.set(name, true);
                    if (args.length == 1 && containsLocalCall(fnBody, "__haxe_static_put__")) setters.set(name, true);
                case EDefp(name, args, _guards, fnBody):
                    if (args == null) continue;
                    if (args.length == 0 && containsLocalCall(fnBody, "__haxe_static_get__")) getters.set(name, true);
                    if (args.length == 1 && containsLocalCall(fnBody, "__haxe_static_put__")) setters.set(name, true);
                default:
            }
        }

        var accessors: StringMap<Bool> = new StringMap();
        for (name in getters.keys()) {
            if (setters.exists(name)) accessors.set(name, true);
        }
        return accessors;
    }

    private static function containsLocalCall(ast: ElixirAST, funcName: String): Bool {
        if (ast == null || ast.def == null) return false;
        var found = false;
        ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            if (!found && n != null && n.def != null) {
                switch (n.def) {
                    case ECall(null, fn, _args) if (fn == funcName):
                        found = true;
                    default:
                }
            }
            return n;
        });
        return found;
    }

    private static function isStaticGetterCall(expr: ElixirAST, moduleExpr: ElixirAST, accessors: StringMap<Bool>): Null<String> {
        if (expr == null || expr.def == null) return null;
        return switch (expr.def) {
            case ERemoteCall(mod, fn, args) if (args != null && args.length == 0 && sameModule(mod, moduleExpr) && accessors.exists(fn)):
                fn;
            case ECall(target, fn, callArgs) if (callArgs != null && callArgs.length == 0 && target != null && sameModule(target, moduleExpr) && accessors.exists(fn)):
                fn;
            case ECall(null, fn, callArgs) if (callArgs != null && callArgs.length == 0 && accessors.exists(fn)):
                fn;
            default:
                null;
        };
    }

    private static function sameModule(a: ElixirAST, b: ElixirAST): Bool {
        var na = extractModuleAlias(a);
        var nb = extractModuleAlias(b);
        return na != null && nb != null && na == nb;
    }

    private static function extractModuleAlias(e: ElixirAST): Null<String> {
        if (e == null || e.def == null) return null;
        return switch (e.def) {
            case EVar(name):
                name;
            case EAtom(a):
                var s: String = a;
                s;
            case EField(base, field):
                var left = extractModuleAlias(base);
                left == null ? null : left + "." + field;
            default:
                null;
        };
    }

    private static function extractStaticGetterConcat(stmt: ElixirAST, moduleExpr: ElixirAST, accessors: StringMap<Bool>): Null<{ moduleExpr: ElixirAST, accessor: String, concatExpr: ElixirAST }> {
        if (stmt == null || stmt.def == null) return null;
        return switch (stmt.def) {
            case EBinary(Concat, left, right):
                var accessor = isStaticGetterCall(left, moduleExpr, accessors);
                if (accessor == null) return null;
                { moduleExpr: moduleExpr, accessor: accessor, concatExpr: makeAST(EBinary(Concat, left, right)) };
            default:
                null;
        };
    }

    private static function extractTempInitFromStaticGetter(stmt: ElixirAST, moduleExpr: ElixirAST, accessors: StringMap<Bool>): Null<{ tempName: String, accessor: String }> {
        if (stmt == null || stmt.def == null) return null;
        var lhsName: Null<String> = null;
        var rhs: Null<ElixirAST> = null;
        switch (stmt.def) {
            case EMatch(PVar(name), value):
                lhsName = name;
                rhs = value;
            case EBinary(Match, left, value):
                switch (left.def) {
                    case EVar(varName):
                        lhsName = varName;
                        rhs = value;
                    default:
                }
            default:
        }
        if (lhsName == null || rhs == null) return null;
        var accessor = isStaticGetterCall(rhs, moduleExpr, accessors);
        return accessor == null ? null : { tempName: lhsName, accessor: accessor };
    }

    private static function extractTempMapPutUpdate(stmt: ElixirAST): Null<{ tempName: String, putCall: ElixirAST }> {
        if (stmt == null || stmt.def == null) return null;

        // Accept:
        // - `_ = Map.put(tmp, k, v)`
        // - `tmp = Map.put(tmp, k, v)`
        // - bare `Map.put(tmp, k, v)` statement
        //
        // We treat the *first argument* as the mutated temp name regardless of the assignment target.
        var rhs: ElixirAST = switch (stmt.def) {
            case EMatch(_pat, value): value;
            case EBinary(Match, _left, value): value;
            default: stmt;
        };

        var args: Null<Array<ElixirAST>> = null;
        var putCall: Null<ElixirAST> = null;
        switch (rhs.def) {
            case ERemoteCall(mod, "put", callArgs) if (callArgs != null && callArgs.length == 3):
                // Accept Map.put/3
                switch (mod.def) {
                    case EVar("Map"):
                        args = callArgs;
                        putCall = rhs;
                    case EAtom(a):
                        var s: String = a;
                        if (s == "Map") { args = callArgs; putCall = rhs; }
                    default:
                }
            case ECall(target, "put", callArgs) if (target != null && callArgs != null && callArgs.length == 3):
                switch (target.def) {
                    case EVar("Map"):
                        args = callArgs;
                        putCall = rhs;
                    case EAtom(atom):
                        var atomName: String = atom;
                        if (atomName == "Map") { args = callArgs; putCall = rhs; }
                    default:
                }
            default:
        }

        if (args == null || putCall == null) return null;
        return switch (args[0].def) {
            case EVar(tmp):
                { tempName: tmp, putCall: putCall };
            default:
                null;
        };
    }

    private static function extractTempConcatUpdate(stmt: ElixirAST): Null<{ tempName: String, concatExpr: ElixirAST }> {
        if (stmt == null || stmt.def == null) return null;

        // Support `tmp = tmp ++ rhs` and standalone `tmp ++ rhs` (the latter becomes an assignment).
        switch (stmt.def) {
            case EBinary(Concat, left, right):
                switch (left.def) {
                    case EVar(tmp):
                        return { tempName: tmp, concatExpr: makeAST(EBinary(Concat, left, right)) };
                    default:
                        return null;
                }
            case EMatch(PVar(tempName), rhs):
                switch (rhs.def) {
                    case EBinary(Concat, concatLeft, concatRight):
                        switch (concatLeft.def) {
                            case EVar(varName) if (varName == tempName):
                                return { tempName: tempName, concatExpr: rhs };
                            default:
                        }
                    default:
                }
            case EBinary(Match, left, rhs):
                switch (left.def) {
                    case EVar(tempName):
                        switch (rhs.def) {
                            case EBinary(Concat, concatLeft, _concatRight):
                                switch (concatLeft.def) {
                                    case EVar(varName) if (varName == tempName):
                                        return { tempName: tempName, concatExpr: rhs };
                                    default:
                                }
                            default:
                        }
                    default:
                }
            default:
                null;
        }

        return null;
    }
}

#end
