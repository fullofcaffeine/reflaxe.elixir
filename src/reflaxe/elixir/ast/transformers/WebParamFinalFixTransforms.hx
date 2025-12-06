package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * WebParamFinalFixTransforms
 *
 * WHAT
 * - Ultra-late safety pass for Web/Live modules that ensures def/defp heads and
 *   anonymous function binders do not use underscored names when the body uses
 *   the base variant (id/user_id/todo/t/etc.). Also recognizes pinned usages.
 *
 * WHY
 * - Some earlier passes may introduce or preserve `_name` binders while body uses
 *   `name`, causing undefined variable errors and underscore warnings. This pass
 *   guarantees binder/body agreement right before printing.
 *
 * HOW
 * - For each EDef/EDefp in Web/Live modules:
 *   - Promote `_param` → `param` when `param` is referenced in body (including pins ^param)
 *     and no `param` binder exists.
 *   - Rewrite body `_param` → `param` when necessary.
 * - For each EFn clause:
 *   - Rename `_x` → `x` when body references `x` or `_x`.
 */
class WebParamFinalFixTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (isWebOrLive(name)):
                    #if debug_web_binder
                    // DISABLED: trace('[WebParamFinalFix] Module ' + name);
                    #end
                    var newBody = [for (b in body) fixNode(b)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name2, doBlock) if (isWebOrLive(name2)):
                    #if debug_web_binder
                    // DISABLED: trace('[WebParamFinalFix] Defmodule ' + name2);
                    #end
                    makeASTWithMeta(EDefmodule(name2, fixNode(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function isWebOrLive(name:String):Bool {
        if (name == null) return false;
        return name.indexOf("Web.") != -1 || StringTools.endsWith(name, "Live") || name.indexOf("Controller") != -1;
    }

    static function fixNode(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EDef(fname, args, guards, body):
                    var rename = computeParamPromotions(args, body);
                    var newArgs = renameParams(args, rename);
                    var newBody = renameBody(body, rename);
                    #if debug_web_binder
                    if (Lambda.count(rename) > 0) {
                        inline function patList(cs:Array<EPattern>):String return [for (p in cs) switch(p){ case PVar(n): n; default: Std.string(p);}].join(',');
                        // DISABLED: trace('[WebParamFinalFix] def ' + fname + '(' + patList(args) + ') -> (' + patList(newArgs) + ')');
                    } else {
                        inline function patList(cs2:Array<EPattern>):String return [for (p in cs2) switch(p){ case PVar(n): n; default: Std.string(p);}].join(',');
                        // DISABLED: trace('[WebParamFinalFix] def ' + fname + ' (no rename) args=(' + patList(args) + ')');
                    }
                    #end
                    makeASTWithMeta(EDef(fname, newArgs, guards, newBody), x.metadata, x.pos);
                case EDefp(fname2, args2, guards2, body2):
                    #if debug_web_binder
                    inline function patListDbg(cs:Array<EPattern>):String return [for (p in cs) switch(p){ case PVar(n): n; default: Std.string(p);}].join(',');
                    var usesEditing = VariableUsageCollector.usedInFunctionScope(body2, "editing_todo");
                    var usesUserId = VariableUsageCollector.usedInFunctionScope(body2, "user_id") || pinUsesName(body2, "user_id") || erawUsesName(body2, "user_id");
                    // DISABLED: trace('[WebParamFinalFix][dbg] defp ' + fname2 + ' args=(' + patListDbg(args2) + ') uses(editing_todo)=' + usesEditing + ' uses(user_id)=' + usesUserId);
                    #end
                    var rename2 = computeParamPromotions(args2, body2);
                    var newArgs2 = renameParams(args2, rename2);
                    var newBody2 = renameBody(body2, rename2);
                    #if debug_web_binder
                    if (Lambda.count(rename2) > 0) {
                        inline function patListArgs(cs:Array<EPattern>):String return [for (p in cs) switch(p){ case PVar(n): n; default: Std.string(p);}].join(',');
                        // DISABLED: trace('[WebParamFinalFix] defp ' + fname2 + '(' + patListArgs(args2) + ') -> (' + patListArgs(newArgs2) + ')');
                    } else {
                        inline function patListArgsDbg(cs3:Array<EPattern>):String return [for (p in cs3) switch(p){ case PVar(n): n; default: Std.string(p);}].join(',');
                        // DISABLED: trace('[WebParamFinalFix] defp ' + fname2 + ' (no rename) args=(' + patListArgsDbg(args2) + ')');
                    }
                    #end
                    makeASTWithMeta(EDefp(fname2, newArgs2, guards2, newBody2), x.metadata, x.pos);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        // used: all variable identifiers seen in body (not closure-aware)
                        var used = collectUsedVars(cl.body);
                        // free: variables referenced in the body that are free (closure-aware)
                        var free = VariableUsageCollector.referencedInFunctionScope(cl.body);
                        var newBodyClause = cl.body;
                        #if debug_web_binder
                        // Debug: list used vars and current args
                        var usedList = [];
                        for (k in used.keys()) usedList.push(k);
                        inline function patListDbg(cs:Array<EPattern>):String return [for (p in cs) switch(p){ case PVar(n): n; default: Std.string(p);}].join(',');
                        // DISABLED: trace('[WebParamFinalFix][EFn] args=(' + patListDbg(cl.args) + ') used={' + usedList.join(',') + '}');
                        #end
                        // Capture original single binder (if present) for potential rename mapping
                        var originalBinder: Null<String> = null;
                        if (cl.args != null && cl.args.length == 1) switch (cl.args[0]) { case PVar(nm): originalBinder = nm; default: }

                        // Build a set of base arg names present
                        var argBases = new Map<String,Bool>();
                        for (a in cl.args) switch (a) { case PVar(nm) if (nm != null): argBases.set(nm, true); default: }
                        var outArgs:Array<EPattern> = [];
                        for (a in cl.args) switch (a) {
                            case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
                                var base = n.substr(1);
                                if (used.exists(n) || used.exists(base)) outArgs.push(PVar(base)) else outArgs.push(a);
                            default:
                                outArgs.push(a);
                        }
                        // If single-arg EFn and body consistently uses a different free var as a struct receiver,
                        // prefer renaming binder to that var (shape-based, avoids domain heuristics).
                        if (outArgs.length == 1) {
                            var currentBinder = switch (outArgs[0]) { case PVar(nm): nm; default: null; };
                            if (currentBinder != null) {
                                // Quick repair: if binder is underscored (_x) and body uses x, promote binder to x.
                                if (currentBinder.length > 1 && currentBinder.charAt(0) == '_') {
                                    var baseNm = currentBinder.substr(1);
                                    if (containsVarName(cl.body, baseNm) || erawUsesName(cl.body, baseNm)) {
                                        outArgs[0] = PVar(baseNm);
                                        currentBinder = baseNm;
                                        argBases = new Map<String,Bool>(); argBases.set(baseNm, true);
                                    }
                                }
                                // Deterministic preference for common predicate/reducer binders.
                                inline function validName(n:String):Bool return (n != null && n.length > 0 && n.charAt(0) != '_' && !~/[\.]/.match(n) && ~/^[a-z_][a-z0-9_]*$/.match(n));
                                inline function allowedBinder(n:String):Bool return (n == 't' || n == 'elem' || n == 'todo');

                                var chosenBinder:Null<String> = null;
                                // Prefer 't' then 'elem'; avoid renaming to a name that is also a free var (would shadow outer var)
                                if (used.exists('t') && currentBinder != 't' && validName('t')) chosenBinder = 't';
                                else if (used.exists('elem') && currentBinder != 'elem' && validName('elem')) chosenBinder = 'elem';
                                else {
                                    // Consider other single candidate heuristics: a single lower_snake identifier used as a field receiver
                                    var recvCandidates = new Array<String>();
                                    for (k in used.keys()) if (k != currentBinder && validName(k) && allowedBinder(k)) {
                                        if (varUsedAsFieldReceiver(cl.body, k)) recvCandidates.push(k);
                                    }
                                    if (recvCandidates.length == 1) {
                                        var cand = recvCandidates[0];
                                        // Do NOT choose a name that is also a free variable in the EFn body (to avoid shadowing outer vars)
                                        if (!free.exists(cand)) {
                                            chosenBinder = cand;
                                        }
                                    }
                                }

                                // Do not rename to arbitrary other names like id/tag. Restrict renames to allowed binders only.

                                if (chosenBinder != null && chosenBinder != currentBinder) {
                                    outArgs[0] = PVar(chosenBinder);
                                    argBases = new Map<String,Bool>(); argBases.set(chosenBinder, true);
                                    #if debug_web_binder
                                    // DISABLED: trace('[WebParamFinalFix] Renaming EFn binder ' + currentBinder + ' -> ' + chosenBinder + ' (preferred heuristic)');
                                    #end
                                } else {
                                    // Additional repair: if there is exactly one lower_snake non-arg used name remaining, rewrite it to the binder
                                    var freeVars = new Array<String>();
                                    for (k in used.keys()) if (k != currentBinder && validName(k) && !argBases.exists(k)) freeVars.push(k);
                                    if (freeVars.length == 1) {
                                        var victim = freeVars[0];
                                        // Only rewrite if the victim itself is an allowed binder name (avoid id/tag/etc.)
                                        if (allowedBinder(victim)) {
                                            #if debug_web_binder
                                            // DISABLED: trace('[WebParamFinalFix] Rewriting free var ' + victim + ' to binder ' + currentBinder + ' inside single-arg EFn');
                                            #end
                                            newBodyClause = ElixirASTTransformer.transformNode(newBodyClause, function(n4: ElixirAST): ElixirAST {
                                                return switch (n4.def) { case EVar(v) if (v == victim): makeASTWithMeta(EVar(currentBinder), n4.metadata, n4.pos); default: n4; }
                                            });
                                        } else {
                                            // Skip unsafe rewrite
                                        }
                                    }
                                }
                            }
                        }
                        var renamePairs = new Map<String,String>();
                        for (i in 0...cl.args.length) switch (cl.args[i]) { case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
                            var base2 = nm.substr(1);
                            if (used.exists(nm)) renamePairs.set(nm, base2);
                            default: }
                        // newBodyClause may have been updated above; keep using the same variable
                        // If the single-arg binder itself was renamed (e.g., id -> t), rewrite body occurrences of the old binder to the new name
                        if (originalBinder != null) {
                            var newBinder: Null<String> = switch (outArgs.length == 1 ? outArgs[0] : null) { case PVar(nm2): nm2; default: null; };
                            if (newBinder != null && newBinder != originalBinder) {
                                renamePairs.set(originalBinder, newBinder);
                                #if debug_web_binder
                                // DISABLED: trace('[WebParamFinalFix] Binder rename: ' + originalBinder + ' -> ' + newBinder + ' (apply in body)');
                                #end
                            }
                        }
                        if (Lambda.count(renamePairs) > 0) newBodyClause = ElixirASTTransformer.transformNode(newBodyClause, function(n2: ElixirAST): ElixirAST {
                            return switch (n2.def) { case EVar(v) if (renamePairs.exists(v)): makeASTWithMeta(EVar(renamePairs.get(v)), n2.metadata, n2.pos); default: n2; }
                        });
                        // Also rewrite body occurrences of _arg -> arg when arg exists as binder
                        if (Lambda.count(argBases) > 0) newBodyClause = ElixirASTTransformer.transformNode(newBodyClause, function(n3: ElixirAST): ElixirAST {
                            return switch (n3.def) {
                                case EVar(v) if (v != null && v.length > 1 && v.charAt(0) == '_' && argBases.exists(v.substr(1))):
                                    makeASTWithMeta(EVar(v.substr(1)), n3.metadata, n3.pos);
                                default:
                                    n3;
                            }
                        });
                        #if debug_web_binder
                        inline function patList(cs:Array<EPattern>):String return [for (p in cs) switch(p){ case PVar(n): n; default: Std.string(p);}].join(',');
                        if (patList(cl.args) != patList(outArgs)) trace('[WebParamFinalFix] EFn args ' + patList(cl.args) + ' -> ' + patList(outArgs));
                        #end
                        newClauses.push({args: outArgs, guard: cl.guard, body: newBodyClause});
                    }
                    makeASTWithMeta(EFn(newClauses), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }

    static function varUsedAsFieldReceiver(node: ElixirAST, varName: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case EField(target, _):
                    switch (target.def) {
                        case EVar(v) if (v == varName): found = true;
                        default: walk(target);
                    }
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, cls): walk(expr); for (cl in cls) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base, fs): walk(base); for (f in fs) walk(f.value);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(node);
        return found;
    }

    static function computeParamPromotions(args:Array<EPattern>, body:ElixirAST):Map<String,String> {
        var have = new Map<String,Bool>();
        var rename = new Map<String,String>();
        if (args != null) for (a in args) switch (a) { case PVar(n) if (n != null): have.set(n,true); default: }
        if (args != null) for (a in args) switch (a) {
            case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
                var base = n.substr(1);
                var used = VariableUsageCollector.usedInFunctionScope(body, base) || pinUsesName(body, base) || erawUsesName(body, base) || containsVarName(body, base);
                if (!have.exists(base) && used) rename.set(n, base);
            default:
        }
        return rename;
    }

    static function erawUsesName(body: ElixirAST, name: String): Bool {
        var found = false;
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= '0'.code && ch <= '9'.code) || (ch >= 'A'.code && ch <= 'Z'.code) || (ch >= 'a'.code && ch <= 'z'.code) || c == "_" || c == ".";
        }
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case ERaw(code):
                    if (code != null && name != null && name.length > 0 && name.charAt(0) != '_') {
                        var start = 0;
                        while (!found) {
                            var i = code.indexOf(name, start);
                            if (i == -1) break;
                            var before = i > 0 ? code.substr(i - 1, 1) : null;
                            var afterIdx = i + name.length;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            if (!isIdentChar(before) && !isIdentChar(after)) { found = true; break; }
                            start = i + name.length;
                        }
                    }
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses): walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
                case EField(obj,_): walk(obj);
                case EAccess(obj2,key): walk(obj2); walk(key);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base,fs): walk(base); for (f in fs) walk(f.value);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(body);
        return found;
    }

    static function containsVarName(body: ElixirAST, name: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case EVar(v) if (v == name):
                    found = true;
                case EPin(inner):
                    walk(inner);
                case EParen(e):
                    walk(e);
                case EBinary(_, l, r):
                    walk(l); walk(r);
                case EMatch(_, rhs):
                    walk(rhs);
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses): walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
                case EField(obj,_): walk(obj);
                case EAccess(obj2,key): walk(obj2); walk(key);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base, fs): walk(base); for (f in fs) walk(f.value);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(body);
        return found;
    }

    static function renameParams(args:Array<EPattern>, rename:Map<String,String>):Array<EPattern> {
        if (args == null || Lambda.count(rename) == 0) return args;
        var out:Array<EPattern> = [];
        for (a in args) switch (a) { case PVar(n) if (rename.exists(n)): out.push(PVar(rename.get(n))); default: out.push(a); }
        return out;
    }

    static function renameBody(body:ElixirAST, rename:Map<String,String>):ElixirAST {
        if (Lambda.count(rename) == 0) return body;
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) { case EVar(v) if (rename.exists(v)): makeASTWithMeta(EVar(rename.get(v)), n.metadata, n.pos); default: n; }
        });
    }

    static function collectUsedVars(node: ElixirAST): Map<String,Bool> {
        var used = new Map<String,Bool>();
        function visit(e: ElixirAST): Void {
            if (e == null || e.def == null) return;
            switch (e.def) {
                case EVar(name): used.set(name, true);
                case EPin(inner): visit(inner);
                case EField(target, _): visit(target);
                case EBlock(stmts): for (s in stmts) visit(s);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case ECase(expr, clauses): visit(expr); for (c in clauses) { if (c.guard != null) visit(c.guard); visit(c.body); }
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(tgt2, _, args2): visit(tgt2); for (a2 in args2) visit(a2);
                case EList(els): for (el in els) visit(el);
                case ETuple(els): for (el in els) visit(el);
                case EMap(pairs): for (p in pairs) { visit(p.key); visit(p.value); }
                case EKeywordList(pairs): for (p in pairs) visit(p.value);
                case EStructUpdate(base, fields): visit(base); for (f in fields) visit(f.value);
                case EFn(clauses): for (cl in clauses) visit(cl.body);
                default:
            }
        }
        visit(node);
        return used;
    }

    static function pinUsesName(body: ElixirAST, name: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case EPin(inner):
                    // Walk inner to handle parentheses or nested nodes
                    switch (inner.def) {
                        case EVar(v) if (v == name): found = true;
                        default: walk(inner);
                    }
                case EParen(e):
                    walk(e);
                case EBinary(_, l, r):
                    walk(l); walk(r);
                case EMatch(_, rhs):
                    walk(rhs);
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses): walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
                case EField(obj,_): walk(obj);
                case EAccess(obj2,key): walk(obj2); walk(key);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base, fs): walk(base); for (f in fs) walk(f.value);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(body);
        return found;
    }
}

#end
