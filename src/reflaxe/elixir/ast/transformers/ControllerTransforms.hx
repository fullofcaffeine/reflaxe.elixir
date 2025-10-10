package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer; // for transformNode/transformAST/iterateAST
using StringTools;

/**
 * ControllerTransforms
 *
 * WHAT
 * - Focused transformation passes that shape Phoenix controller functions to idiomatic forms.
 * - Includes:
 *   - controllerActionArgShapingPass: expose `conn`/`params` (and safe soft names) in action args by usage.
 *   - controllerOkErrorBinderShapingPass: in {:ok|:error, binder} arms, rename binder to the sole missing name
 *     referenced in the body and inject a clause‑local alias for stability.
 *
 * WHY
 * - Keep ElixirASTTransformer thin; isolate controller‑specific logic to reduce file size and complexity.
 * - Enforce clear pass responsibilities and ordering to avoid rename/alias conflicts with generic hygiene.
 * - Preserve Phoenix idioms while applying compile‑time shaping for readability and safety.
 *
 * HOW
 * - Stateless, structural passes that traverse ElixirAST and rewrite only when structural conditions match.
 * - Designed to run early in the controller pipeline:
 *   ControllerActionArgShaping → ControllerOkErrorBinderShaping → CaseClauseBindingAlias → Hygiene
 *
 * CONTEXT
 * - Invoked from ElixirASTTransformer.getEnabledPasses() as registered passes.
 * - Does not depend on builder; uses only AST shape and light identifier usage detection.
 *
 * EDGE CASES
 * - Conservative insertions: only insert new args for `conn`/`params` when no safe rename candidate exists.
 * - Avoid renaming/creating reserved names like `socket`, `assigns`, `conn`, `params` unless necessary.
 * - Binder renames only apply when exactly one missing simple identifier is referenced in the clause body.
 *
 * EXAMPLES
 * - Haxe controller action referencing `params` without arg → adds/renames to expose `params` in def args.
 * - Case arm `{:ok, user}` but body uses `data` only → binder becomes `data` and aliases `data = user`.
 */
class ControllerTransforms {
    static inline function isControllerActionName(name: String): Bool {
        if (name == null) return false;
        return name == "index" || name == "create" || name == "update" || name == "delete"
            || name == "show" || name == "new" || name == "edit";
    }

    /**
     * ControllerActionArgShapingPass
     * WHAT: Within Controller modules, if a controller action body references structural variables like
     *       conn/params (and selectively changeset/user/data), ensure the function parameter list exposes
     *       those names structurally. Conservative: prefer renaming an existing non-critical parameter; only
     *       insert new parameters for conn/params when absolutely missing and no candidates exist.
     * WHY: Keep controller function signatures idiomatic without relying on heuristic generic rename passes.
     * HOW: Detect controller modules (metadata.isController or name ends with "Controller"). For each action
     *      def, collect used identifiers and declared parameters; perform targeted arg renames/additions.
     */
    public static function controllerActionArgShapingPass(ast: ElixirAST): ElixirAST {
        inline function isControllerModuleName(n:String):Bool return n != null && StringTools.endsWith(n, "Controller");
        inline function isSimpleIdent(n:String):Bool return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        function collectUsed(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return;
            ElixirASTTransformer.transformNode(node, function(n) {
                switch(n.def) {
                    case EVar(vn): if (isSimpleIdent(vn)) acc.set(vn, true);
                    default:
                }
                return n; // no structural changes
            });
        }
        function collectParamBinders(patterns:Array<EPattern>):Array<String> {
            var out:Array<String> = [];
            function visit(p:EPattern):Void {
                switch (p) {
                    case PVar(n): out.push(n);
                    case PTuple(l): for (e in l) visit(e);
                    case PList(l): for (e in l) visit(e);
                    case PCons(h,t): visit(h); visit(t);
                    case PMap(ps): for (kv in ps) visit(kv.value);
                    case PStruct(_, fs): for (f in fs) visit(f.value);
                    case PAlias(n, inner): out.push(n); visit(inner);
                    case PPin(inner): visit(inner);
                    case PBinary(segs): for (s in segs) visit(s.pattern);
                    default:
                }
            }
            if (patterns != null) for (p in patterns) visit(p);
            return out;
        }
        function gatherNamesFromPattern(p:EPattern, acc:Map<String,Bool>):Void {
            switch (p) {
                case PVar(name): acc.set(name, true);
                case PTuple(el): for (e in el) gatherNamesFromPattern(e, acc);
                case PList(el): for (e in el) gatherNamesFromPattern(e, acc);
                case PCons(h,t): gatherNamesFromPattern(h, acc); gatherNamesFromPattern(t, acc);
                case PMap(pairs): for (pair in pairs) gatherNamesFromPattern(pair.value, acc);
                case PStruct(_, fields): for (f in fields) gatherNamesFromPattern(f.value, acc);
                case PAlias(n, inner): acc.set(n, true); gatherNamesFromPattern(inner, acc);
                case PPin(inner): gatherNamesFromPattern(inner, acc);
                case PBinary(segs): for (s in segs) gatherNamesFromPattern(s.pattern, acc);
                default:
            }
        }
        function collectBodyDeclaredLocals(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return;
            switch (node.def) {
                case EMatch(pat, expr): gatherNamesFromPattern(pat, acc); collectBodyDeclaredLocals(expr, acc);
                case EBlock(stmts): for (s in stmts) collectBodyDeclaredLocals(s, acc);
                case EIf(c,t,e): collectBodyDeclaredLocals(c, acc); collectBodyDeclaredLocals(t, acc); if (e != null) collectBodyDeclaredLocals(e, acc);
                case ECase(target, clauses): collectBodyDeclaredLocals(target, acc); for (cl in clauses) collectBodyDeclaredLocals(cl.body, acc);
                case ECond(conds): for (c in conds) collectBodyDeclaredLocals(c.body, acc);
                case ECall(target, _, args): if (target != null) collectBodyDeclaredLocals(target, acc); for (a in args) collectBodyDeclaredLocals(a, acc);
                case ERemoteCall(mod, _, args): collectBodyDeclaredLocals(mod, acc); for (a in args) collectBodyDeclaredLocals(a, acc);
                case EParen(inner): collectBodyDeclaredLocals(inner, acc);
                default:
            }
        }
        function renameCandidateTo(p:EPattern, candidate:String, toName:String):EPattern {
            return switch (p) {
                case PVar(n) if (n == candidate): PVar(toName);
                case PTuple(l): PTuple([for (e in l) renameCandidateTo(e, candidate, toName)]);
                case PList(l): PList([for (e in l) renameCandidateTo(e, candidate, toName)]);
                case PCons(h,t): PCons(renameCandidateTo(h, candidate, toName), renameCandidateTo(t, candidate, toName));
                case PMap(ps): PMap([for (kv in ps) {key: kv.key, value: renameCandidateTo(kv.value, candidate, toName)}]);
                case PStruct(mod, fs): PStruct(mod, [for (f in fs) {key: f.key, value: renameCandidateTo(f.value, candidate, toName)}]);
                case PAlias(n, inner): PAlias(n == candidate ? toName : n, renameCandidateTo(inner, candidate, toName));
                case PPin(inner): PPin(renameCandidateTo(inner, candidate, toName));
                case PBinary(segs): PBinary([for (s in segs) {pattern: renameCandidateTo(s.pattern, candidate, toName), size: s.size, type: s.type, modifiers: s.modifiers}]);
                default: p;
            };
        }
        function shapeAction(name:String, args:Array<EPattern>, body:ElixirAST):{args:Array<EPattern>, body:ElixirAST} {
            var used = new Map<String,Bool>(); collectUsed(body, used);
            var params = collectParamBinders(args);
            var declared = new Map<String,Bool>(); for (p in params) declared.set(p, true);
            collectBodyDeclaredLocals(body, declared);

            var newArgs = args != null ? args.copy() : [];
            // Hard names: conn, params — may insert
            var hard = ["conn", "params"];
            // Soft names: changeset/user/data — rename only when safe
            var soft = ["changeset", "user", "data"];

            for (tgt in hard) {
                if (used.exists(tgt) && !declared.exists(tgt)) {
                    var candidate:Null<String> = null;
                    for (pname in params) {
                        if (pname != null && pname != tgt && pname != "socket" && pname != "assigns" && pname != "conn" && pname != "params" && !declared.exists(tgt)) {
                            candidate = pname; break;
                        }
                    }
                    if (candidate != null) {
                        newArgs = [for (a in newArgs) renameCandidateTo(a, candidate, tgt)];
                        params = collectParamBinders(newArgs);
                        declared = new Map<String,Bool>(); for (p in params) declared.set(p, true);
                        collectBodyDeclaredLocals(body, declared);
                    } else {
                        newArgs.push(PVar(tgt));
                        params = collectParamBinders(newArgs);
                        declared.set(tgt, true);
                    }
                }
            }

            // Soft names: rename only, no insertion
            for (tgt in soft) {
                if (used.exists(tgt) && !declared.exists(tgt)) {
                    var candidate2:Null<String> = null;
                    for (pname2 in params) {
                        if (pname2 != null && pname2 != tgt && pname2 != "socket" && pname2 != "assigns" && pname2 != "conn" && pname2 != "params" && !declared.exists(tgt)) {
                            candidate2 = pname2; break;
                        }
                    }
                    if (candidate2 != null) {
                        newArgs = [for (a in newArgs) renameCandidateTo(a, candidate2, tgt)];
                        params = collectParamBinders(newArgs);
                        declared = new Map<String,Bool>(); for (p in params) declared.set(p, true);
                        collectBodyDeclaredLocals(body, declared);
                    }
                }
            }

            return {args: newArgs, body: body};
        }

        function transformControllerBody(body:ElixirAST):ElixirAST {
            return switch (body.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    for (s in stmts) {
                        switch (s.def) {
                            case EDef(n, a, g, b) if (isControllerActionName(n)):
                                var shaped = shapeAction(n, a, b);
                                out.push(makeAST(EDef(n, shaped.args, g, shaped.body)));
                            default:
                                out.push(s);
                        }
                    }
                    makeAST(EBlock(out));
                default:
                    switch (body.def) {
                        case EDef(n, a, g, b) if (isControllerActionName(n)):
                            var shaped = shapeAction(n, a, b);
                            makeAST(EDef(n, shaped.args, g, shaped.body));
                        default:
                            body;
                    }
            };
        }

        return ElixirASTTransformer.transformNode(ast, function(node) {
            return switch (node.def) {
                case EDefmodule(name, body) if (node.metadata != null && (node.metadata.isController == true || isControllerModuleName(name))):
                    makeASTWithMeta(EDefmodule(name, transformControllerBody(body)), node.metadata, node.pos);
                case EModule(name, attrs, exprs) if (node.metadata != null && (node.metadata.isController == true || isControllerModuleName(name))):
                    var newBody = transformControllerBody(makeAST(EBlock(exprs)));
                    switch (newBody.def) {
                        case EBlock(sts): makeASTWithMeta(EModule(name, attrs, sts), node.metadata, node.pos);
                        default: makeASTWithMeta(EModule(name, attrs, [newBody]), node.metadata, node.pos);
                    }
                default:
                    node;
            };
        });
    }

    /**
     * ControllerOkErrorBinderShaping
     * WHAT: In controller actions, for case arms with atom-head tuples {:ok|:error, binder}, if the clause body
     *       references exactly one missing simple identifier (e.g., user, data, changeset), rename the binder to that
     *       identifier. Also inject a clause‑local alias `missing = binder` to keep usage readable.
     */
    public static function controllerOkErrorBinderShapingPass(ast: ElixirAST): ElixirAST {
        inline function isSimpleIdent(n:String):Bool return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        function collectUsed(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return;
            ElixirASTTransformer.transformNode(node, function(n) {
                switch (n.def) {
                    case EVar(vn): if (isSimpleIdent(vn)) acc.set(vn, true);
                    default:
                }
                return n;
            });
        }
        function declaredInPattern(p:EPattern):Map<String,Bool> {
            var m = new Map<String,Bool>();
            function visit(q:EPattern):Void {
                switch (q) {
                    case PVar(n): m.set(n, true);
                    case PTuple(l): for (e in l) visit(e);
                    case PList(l): for (e in l) visit(e);
                    case PCons(h,t): visit(h); visit(t);
                    case PMap(ps): for (kv in ps) visit(kv.value);
                    case PStruct(_, fs): for (f in fs) visit(f.value);
                    case PAlias(n, inner): m.set(n, true); visit(inner);
                    case PPin(inner): visit(inner);
                    case PBinary(segs): for (s in segs) visit(s.pattern);
                    default:
                }
            }
            visit(p);
            return m;
        }
        function collectBodyDeclaredLocals(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return;
            switch (node.def) {
                case EMatch(pat, expr):
                    function gather(p:EPattern):Void {
                        switch (p) {
                            case PVar(n): acc.set(n, true);
                            case PTuple(l): for (e in l) gather(e);
                            case PList(l): for (e in l) gather(e);
                            case PCons(h,t): gather(h); gather(t);
                            case PMap(ps): for (kv in ps) gather(kv.value);
                            case PStruct(_, fs): for (f in fs) gather(f.value);
                            case PAlias(n, inner): acc.set(n, true); gather(inner);
                            case PPin(inner): gather(inner);
                            case PBinary(segs): for (s in segs) gather(s.pattern);
                            default:
                        }
                    }
                    gather(pat);
                    collectBodyDeclaredLocals(expr, acc);
                case EBlock(stmts): for (s in stmts) collectBodyDeclaredLocals(s, acc);
                case EIf(c,t,e): collectBodyDeclaredLocals(c, acc); collectBodyDeclaredLocals(t, acc); if (e != null) collectBodyDeclaredLocals(e, acc);
                case ECase(target, clauses): collectBodyDeclaredLocals(target, acc); for (cl in clauses) collectBodyDeclaredLocals(cl.body, acc);
                case ECond(conds): for (c in conds) collectBodyDeclaredLocals(c.body, acc);
                case ECall(target, _, args): if (target != null) collectBodyDeclaredLocals(target, acc); for (a in args) collectBodyDeclaredLocals(a, acc);
                case ERemoteCall(mod, _, args): collectBodyDeclaredLocals(mod, acc); for (a in args) collectBodyDeclaredLocals(a, acc);
                case EParen(inner): collectBodyDeclaredLocals(inner, acc);
                default:
            }
        }
        function renameBinderAtIndex(p:EPattern, index:Int, toName:String):EPattern {
            return switch (p) {
                case PTuple(el) if (index >= 0 && index < el.length):
                    var newEl = el.copy();
                    switch (newEl[index]) { case PVar(_): newEl[index] = PVar(toName); default: }
                    PTuple(newEl);
                default: p;
            };
        }
        function processBody(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case ECase(target, clauses):
                    var fixed:Array<ECaseClause> = [];
                    for (cl in clauses) {
                        var out = cl;
                        switch (cl.pattern) {
                            case PTuple(elements) if (elements.length >= 2):
                                var headIsAtomOkOrError = false;
                                switch (elements[0]) { case PLiteral({def: EAtom(a)}) if (a == "ok" || a == "error"): headIsAtomOkOrError = true; default: }
                                if (headIsAtomOkOrError) {
                                    var used = new Map<String,Bool>(); collectUsed(cl.body, used);
                                    var declared = declaredInPattern(cl.pattern);
                                    var bodyLocals = new Map<String,Bool>(); collectBodyDeclaredLocals(cl.body, bodyLocals);
                                    var missing:Array<String> = [];
                                    for (u in used.keys()) if (!declared.exists(u) && !bodyLocals.exists(u)) missing.push(u);
                                    // Only allow conservative conventional names for controller ok/error binder shaping
                                    var allowed = new Map<String,Bool>();
                                    allowed.set("user", true);
                                    allowed.set("data", true);
                                    allowed.set("changeset", true);
                                    if (missing.length == 1 && allowed.exists(missing[0])) {
                                        var toName = missing[0];
                                        // Extract existing binder name at index 1
                                        var binderName: Null<String> = null;
                                        switch (cl.pattern) {
                                            case PTuple(el) if (el.length >= 2):
                                                switch (el[1]) { case PVar(bn): binderName = bn; default: }
                                            default:
                                        }
                                        // Inject alias: toName = binderName (when binderName exists)
                                        var newBody1 = cl.body;
                                        if (binderName != null) {
                                            var aliasStmt = makeAST(EMatch(PVar(toName), makeAST(EVar(binderName))));
                                            newBody1 = switch (cl.body.def) {
                                                case EBlock(stmts): makeAST(EBlock([aliasStmt].concat(stmts)));
                                                default: makeAST(EBlock([aliasStmt, cl.body]));
                                            };
                                            #if debug_controller_shaping
                                            trace('[ControllerOkErrorBinderShaping] Injected alias ' + toName + ' = ' + binderName);
                                            #end
                                        }
                                        // Prefer renaming binder to the unique missing identifier to keep pattern and body consistent
                                        var newPat = renameBinderAtIndex(cl.pattern, 1, toName);
                                        #if debug_controller_shaping
                                        trace('[ControllerOkErrorBinderShaping] Renamed binder at index 1 to ' + toName);
                                        #end
                                        out = { pattern: newPat, guard: cl.guard, body: newBody1 };
                                    }
                                }
                            default:
                        }
                        fixed.push(out);
                    }
                    makeASTWithMeta(ECase(processBody(target), fixed), n.metadata, n.pos);
                case EBlock(stmts):
                    makeAST(EBlock([for (s in stmts) processBody(s)]));
                case EIf(c,t,e):
                    makeAST(EIf(processBody(c), processBody(t), e != null ? processBody(e) : null));
                default:
                    n;
            };
        }
        return ElixirASTTransformer.transformNode(ast, function(n) {
            return switch (n.def) {
                case EDef(name, args, g, body) if (isControllerActionName(name)):
                    makeASTWithMeta(EDef(name, args, g, processBody(body)), n.metadata, n.pos);
                default:
                    n;
            };
        });
    }
}

#end
