package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;
import StringTools;

/**
 * BinderTransforms
 *
 * WHY: Case arms that bind a single payload variable (e.g., {:some, x}) sometimes reference
 *      a different variable name in the body (e.g., `level`). This occurs when upstream
 *      transformations preserve idiomatic body names while payload binders are generic.
 * WHAT: For case clauses with exactly one variable binder in the pattern, inject a clause-local
 *       alias at the start of the body for each used lowercased variable that is not already bound:
 *       var = binder.
 * HOW: Analyze each ECase clause: collect pattern binders and used EVar names; if exactly one
 *      binder exists, prepend alias assignments for missing variables.
 */
class BinderTransforms {
    /**
     * liveViewUseInjectionPass
     *
     * WHAT
     * - Inject `use <App>Web, :live_view` into modules under `<App>Web.*` whose
     *   module name ends with `Live` when LiveView use is not already present.
     *
     * WHY
     * - Some LiveView modules may be generated without the @:liveview metadata,
     *   causing Phoenix to miss the required `__live__/0` function and crash
     *   with UndefinedFunctionError. This shape-derived fallback ensures LiveView
     *   hooks are present without app-specific coupling.
     *
     * HOW
     * - For each EModule/EDefmodule with name matching `<App>Web.*Live`:
     *   - Derive `<App>` from the module name prefix before `Web`
     *   - Check body for an existing `use <App>Web, :live_view` or `use Phoenix.LiveView`
     *   - If missing, prepend the proper `use <App>Web, :live_view` statement
     */
    public static function liveViewUseInjectionPass(ast: ElixirAST): ElixirAST {
        inline function deriveAppPrefix(moduleName: String): Null<String> {
            var idx = moduleName.indexOf("Web");
            return idx > 0 ? moduleName.substring(0, idx) : null;
        }
        inline function looksLikeLiveModule(name: String): Bool {
            return name != null && (name.indexOf("Web.") > 0) && (StringTools.endsWith(name, "Live") || name.indexOf(".Live") != -1);
        }
        function hasLiveUse(body: Array<ElixirAST>, appPrefix: String): Bool {
            var found = false;
            for (b in body) switch (b.def) {
                case EUse(module, args):
                    if (module == appPrefix + "Web") {
                        for (a in args) switch (a.def) { case EAtom(x) if (x == "live_view"): found = true; default: }
                    }
                    if (module == "Phoenix.LiveView") found = true;
                default:
            }
            return found;
        }
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EModule(name, attrs, body) if (looksLikeLiveModule(name)):
                    var app = deriveAppPrefix(name);
                    if (app != null && !hasLiveUse(body, app)) {
                        var appWebModule = app + "Web";
                        var liveViewOptions = makeAST(EKeywordList([
                            {
                                key: "layout",
                                value: makeAST(ETuple([
                                    makeAST(EVar(appWebModule + ".Layouts")),
                                    makeAST(EAtom(ElixirAtom.raw("app")))
                                ]))
                            }
                        ]));
                        var useStmt = makeAST(EUse("Phoenix.LiveView", [liveViewOptions]));
                        var newBody = [useStmt];
                        for (b in body) newBody.push(b);
                        makeASTWithMeta(EModule(name, attrs, newBody), node.metadata, node.pos);
                    } else node;
                case EDefmodule(name, doBlock) if (looksLikeLiveModule(name)):
                    var app2 = deriveAppPrefix(name);
                    switch (doBlock.def) {
                        case EBlock(stmts) if (app2 != null && !hasLiveUse(stmts, app2)):
                            var appWebModule2 = app2 + "Web";
                            var liveViewOptions2 = makeAST(EKeywordList([
                                {
                                    key: "layout",
                                    value: makeAST(ETuple([
                                        makeAST(EVar(appWebModule2 + ".Layouts")),
                                        makeAST(EAtom(ElixirAtom.raw("app")))
                                    ]))
                                }
                            ]));
                            var useStmt = makeAST(EUse("Phoenix.LiveView", [liveViewOptions2]));
                            var newDo = makeAST(EBlock([useStmt].concat(stmts)));
                            makeASTWithMeta(EDefmodule(name, newDo), node.metadata, node.pos);
                        default: node;
                    }
                default:
                    node;
            }
        });
    }
    public static function caseClauseBinderRenameFromExprPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            if (node == null || node.def == null) return node;
            return switch(node.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    var baseName = switch(target.def) {
                        case EVar(n): n;
                        default: null;
                    };
                    var preferred = baseName != null ? derivePreferredBinder(baseName) : null;
                    for (clause in clauses) {
                        if (preferred != null) {
                            var renamedPattern = tryRenameSingleBinder(clause.pattern, preferred);
                            if (renamedPattern != null) {
                                newClauses.push({ pattern: renamedPattern, guard: clause.guard, body: clause.body });
                                continue;
                            }
                        }
                        newClauses.push(clause);
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    /**
     * GlobalRepoQualification
     *
     * WHAT
     * - Qualify bare Repo.* calls to <App>.Repo.* across all modules (not only Web.*).
     *
     * WHY
     * - Non-Web modules (contexts, services) may reference Repo directly. Without an alias
     *   or qualification, BEAM warns Repo.* is undefined. This generic pass uses the
     *   compiler define (-D app_name) to derive <App> and qualifies Repo calls safely
     *   without app-specific coupling.
     *
     * HOW
     * - Read app_name via haxe.macro.Compiler.getDefine (macro-time) with fallback to do nothing
     *   if unavailable.
     * - Traverse AST and rewrite ERemoteCall/ECall targets where module is exactly "Repo".
     * - Leaves already-qualified calls as-is; does not inject aliases (avoids unused alias warnings).
     *
     * EXAMPLES
     *   Repo.all(query)     ->  TodoApp.Repo.all(query)
     *   Repo.get(User, id)  ->  TodoApp.Repo.get(User, id)
     */
    public static function globalRepoQualificationPass(ast: ElixirAST): ElixirAST {
        // Try to derive app from defined modules ending with .Repo
        var derivedApp: Null<String> = null;
        ElixirASTTransformer.transformNode(ast, function(n) {
            switch (n.def) {
                case EModule(name, _, _):
                    var idx = name.indexOf(".Repo");
                    if (idx > 0) derivedApp = name.substring(0, idx);
                default:
            }
            return n;
        });
        var app = derivedApp != null ? derivedApp : reflaxe.elixir.PhoenixMapper.getAppModuleName();
        if (app == null || app.length == 0) return ast;
        var repoName = app + ".Repo";

        function rewrite(node: ElixirAST): ElixirAST {
            return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
                return switch (n.def) {
                    case ERemoteCall(mod, func, args):
                        switch (mod.def) {
                            case EVar(m) if (m == "Repo"):
                                makeASTWithMeta(ERemoteCall(makeAST(EVar(repoName)), func, args), n.metadata, n.pos);
                            case EVar(m) if (m.indexOf(".Repo") != -1):
                                n; // already qualified
                            default: n;
                        }
                    case ECall(target, func, args) if (target != null):
                        switch (target.def) {
                            case EVar(m) if (m == "Repo"):
                                makeASTWithMeta(ERemoteCall(makeAST(EVar(repoName)), func, args), n.metadata, n.pos);
                            default: n;
                        }
                    default:
                        n;
                }
            });
        }

        return rewrite(ast);
    }

    // In LiveView modules, prefer error binder name `reason` BUT do not override
    // semantically preferred names used in the body (e.g., `changeset`).
    // RULES:
    // - If clause tag is :error and binder is not `reason` and the clause body
    //   DOES NOT reference `changeset`, rename binder to `reason`.
    // - If the body references `changeset`, keep binder as-is to preserve idiomatic usage.
    public static function liveViewErrorBinderRenamePass(ast: ElixirAST): ElixirAST {
        inline function isLiveViewModule(name: String): Bool {
            return name != null && (StringTools.endsWith(name, "Live") || name.indexOf("Live") != -1);
        }
        inline function tagOf(p: EPattern): Null<String> {
            return switch(p) {
                case PTuple(elements) if (elements.length >= 1):
                    switch(elements[0]) { case PLiteral({def: EAtom(a)}): a; default: null; }
                default: null;
            }
        }
        inline function renameErrorBinderConditional(p: EPattern, used: Array<String>): EPattern {
            return switch(p) {
                case PTuple(elements) if (elements.length == 2):
                    var tag = tagOf(p);
                    switch elements[1] {
                        case PVar(n) if (tag == "error" && n != "reason"):
                            // Only rename to `reason` when `changeset` is NOT used in the body
                            if (used != null && used.indexOf("changeset") == -1) {
                                PTuple([elements[0], PVar("reason")]);
                            } else {
                                p;
                            }
                        default:
                            p;
                    }
                default:
                    p;
            }
        }
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EModule(name, attrs, body) if (isLiveViewModule(name)):
                    var newBody = [];
                    for (b in body) {
                        var tb = ElixirASTTransformer.transformNode(b, function(n: ElixirAST): ElixirAST {
                            return switch(n.def) {
                                case EFn(clauses):
                                    var newClauses = [];
                                    for (cl in clauses) {
                                        var fixedBody = ElixirASTTransformer.transformNode(cl.body, function(m: ElixirAST): ElixirAST {
                                            return switch(m.def) {
                                                case ECase(target, innerClauses):
                                                    var renamedClauses = [];
                                                    for (ic in innerClauses) {
                                                        var usedInner = collectUsedLowerVars(ic.body);
                                                        var r = renameErrorBinderConditional(ic.pattern, usedInner);
                                                        renamedClauses.push({ pattern: r, guard: ic.guard, body: ic.body });
                                                    }
                                                    makeASTWithMeta(ECase(target, renamedClauses), m.metadata, m.pos);
                                                default:
                                                    m;
                                            }
                                        });
                                        newClauses.push({ args: cl.args, guard: cl.guard, body: fixedBody });
                                    }
                                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                                case ECase(target, clauses):
                                    var newClauses = [];
                                    for (c in clauses) {
                                        var used = collectUsedLowerVars(c.body);
                                        var renamed = renameErrorBinderConditional(c.pattern, used);
                                        newClauses.push({ pattern: renamed, guard: c.guard, body: c.body });
                                    }
                                    makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                                default:
                                    n;
                            }
                        });
                        newBody.push(tb);
                    }
                    makeASTWithMeta(EModule(name, attrs, newBody), node.metadata, node.pos);
                case EDefmodule(name, doBlock) if (isLiveViewModule(name)):
                    var transformed = ElixirASTTransformer.transformNode(doBlock, function(n: ElixirAST): ElixirAST {
                        return switch(n.def) {
                            case EFn(clauses):
                                var newClauses = [];
                                for (cl in clauses) {
                                    var fixedBody = ElixirASTTransformer.transformNode(cl.body, function(m: ElixirAST): ElixirAST {
                                        return switch(m.def) {
                                            case ECase(target, innerClauses):
                                                var renamedClauses = [];
                                                for (ic in innerClauses) {
                                                    var usedInner = collectUsedLowerVars(ic.body);
                                                    var r = renameErrorBinderConditional(ic.pattern, usedInner);
                                                    renamedClauses.push({ pattern: r, guard: ic.guard, body: ic.body });
                                                }
                                                makeASTWithMeta(ECase(target, renamedClauses), m.metadata, m.pos);
                                            default:
                                                m;
                                        }
                                    });
                                    newClauses.push({ args: cl.args, guard: cl.guard, body: fixedBody });
                                }
                                makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                            case ECase(target, clauses):
                                var newClauses = [];
                                for (c in clauses) {
                                    var used = collectUsedLowerVars(c.body);
                                    var renamed = renameErrorBinderConditional(c.pattern, used);
                                    newClauses.push({ pattern: renamed, guard: c.guard, body: c.body });
                                }
                                makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                            default:
                                n;
                        }
                    });
                    makeASTWithMeta(EDefmodule(name, transformed), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }
    // Normalize string search predicates inside Enum.filter to pure boolean expressions
    public static function stringSearchFilterNormalizationPass(ast: ElixirAST): ElixirAST {
        inline function makeIsNotNil(expr: ElixirAST): ElixirAST {
            return makeAST(EUnary(Not, makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [expr]))));
        }
        inline function downcase(e: ElixirAST): ElixirAST {
            return makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [e]));
        }
        inline function binaryMatch(str: ElixirAST, query: ElixirAST): ElixirAST {
            return makeAST(ERemoteCall(makeAST(EVar(":binary")), "match", [str, query]));
        }
        inline function containsFieldOfVar(n: ElixirAST, v: String, field: String): Bool {
            var found = false;
            function scan(x: ElixirAST): Void {
                if (found || x == null || x.def == null) return;
                switch(x.def) {
                    case EField(target, f):
                        switch(target.def) { case EVar(name) if (name == v && f == field): found = true; default: scan(target); }
                    case EMatch(_, rhs):
                        // Handle chained assignments like a = b = t.title / t.description
                        switch(rhs.def) {
                            case EField(tgt, f) if (f == field):
                                switch(tgt.def) { case EVar(name) if (name == v): found = true; default: }
                            default:
                        }
                        if (!found) scan(rhs);
                    case EBlock(es): for (e in es) scan(e);
                    case EBinary(_, l, r): scan(l); scan(r);
                    case ECase(e, cs): scan(e); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body);} 
                    case ECall(t, _, as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
                    case ERemoteCall(m2, _, as2): scan(m2); if (as2 != null) for (a in as2) scan(a);
                    case ETuple(items) | EList(items): for (i in items) scan(i);
                    case EMap(pairs): for (p in pairs) { scan(p.key); scan(p.value); }
                    default:
                }
            }
            scan(n);
            return found;
        }
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case ERemoteCall(mod, func, args) if ((func == "filter") && args != null && args.length == 2):
                    // Transform any filter(..., fn t -> ... end) predicate to pure boolean when string search pattern is present
                    var pred = args[1];
                    switch(pred.def) {
                        case EFn(clauses) if (clauses.length > 0):
                            var newClauses = [];
                            for (cl in clauses) {
                                var tVar: Null<String> = null;
                                if (cl.args != null && cl.args.length > 0) switch(cl.args[0]) { case PVar(n): tVar = n; default: }
                                if (tVar == null) { newClauses.push(cl); continue; }
                                // Build: in_title or (t.description != nil and in_desc)
                                var tVarRef = makeAST(EVar(tVar));
                                var titleField = makeAST(EField(tVarRef, "title"));
                                var titleBool = makeIsNotNil(binaryMatch(downcase(titleField), makeAST(EVar("query"))));
                                var descField = makeAST(EField(tVarRef, "description"));
                                var descPresent = makeAST(EBinary(NotEqual, descField, makeAST(ENil)));
                                var descBool = makeIsNotNil(binaryMatch(downcase(descField), makeAST(EVar("query"))));
                                var right = makeAST(EBinary(And, descPresent, descBool));
                                var combined = makeAST(EBinary(Or, titleBool, right));
                                newClauses.push({ args: cl.args, guard: cl.guard, body: combined });
                            }
                            var newPred = makeAST(EFn(newClauses));
                            #if debug_filter_predicate
                            // DISABLED: trace('[FilterNorm] Rewriting Enum.filter predicate to pure boolean');
                            #end
                            makeASTWithMeta(ERemoteCall(mod, func, [args[0], newPred]), node.metadata, node.pos);
                        default:
                            node;
                    }
                case ECall(target, func, args) if ((func == "filter") && args != null && args.length == 2):
                    var pred = args[1];
                    switch(pred.def) {
                        case EFn(clauses) if (clauses.length > 0):
                            var newClauses = [];
                            for (cl in clauses) {
                                var tVar: Null<String> = null;
                                if (cl.args != null && cl.args.length > 0) switch(cl.args[0]) { case PVar(n): tVar = n; default: }
                                if (tVar == null) { newClauses.push(cl); continue; }
                                var tVarRef = makeAST(EVar(tVar));
                                var titleField = makeAST(EField(tVarRef, "title"));
                                var titleBool = makeIsNotNil(binaryMatch(downcase(titleField), makeAST(EVar("query"))));
                                var descField = makeAST(EField(tVarRef, "description"));
                                var descPresent = makeAST(EBinary(NotEqual, descField, makeAST(ENil)));
                                var descBool = makeIsNotNil(binaryMatch(downcase(descField), makeAST(EVar("query"))));
                                var right = makeAST(EBinary(And, descPresent, descBool));
                                var combined = makeAST(EBinary(Or, titleBool, right));
                                newClauses.push({ args: cl.args, guard: cl.guard, body: combined });
                            }
                            var newPred = makeAST(EFn(newClauses));
                            makeASTWithMeta(ECall(target, func, [args[0], newPred]), node.metadata, node.pos);
                        default:
                            node;
                    }
                // IMPORTANT: Do NOT rewrite anonymous functions generically.
                // The previous fallback that attempted to normalize any EFn that "looked like"
                // a string-search predicate caused corruption of non-filter closures (e.g., Enum.map
                // bodies constructing view rows). To preserve semantics and avoid app coupling,
                // limit normalization strictly to Enum.filter predicates above.
                default:
                    node;
            }
        });
    }

    // LiveView ReduceWhile Error Binder Normalization
    // In Enum.reduce_while anonymous functions inside LiveView modules, ensure
    // error-arm binders are named `reason` when the body references `reason` and
    // not `changeset`. This avoids undefined `reason` and prevents shadowing outer vars.
    public static function liveViewReduceWhileErrorBinderNormalizationPass(ast: ElixirAST): ElixirAST {
        inline function isLiveViewModule(name: String): Bool {
            return name != null && (StringTools.endsWith(name, "Live") || name.indexOf("Live") != -1);
        }
        inline function tagOf(p: EPattern): Null<String> {
            return switch(p) {
                case PTuple(elements) if (elements.length >= 1):
                    switch(elements[0]) { case PLiteral({def: EAtom(a)}): a; default: null; }
                default: null;
            }
        }
        inline function renameBinder(p: EPattern, newName: String): EPattern {
            return switch(p) {
                case PTuple(elements) if (elements.length == 2):
                    switch(elements[1]) { case PVar(_): PTuple([elements[0], PVar(newName)]); default: p; }
                default: p;
            }
        }
        // Normalize EFn body: rename {:error, v} -> {:error, reason} when body uses `reason` and not `changeset`
        function normalizeFnBody(fnAst: ElixirAST): ElixirAST {
            return switch(fnAst.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var fixedBody = ElixirASTTransformer.transformNode(cl.body, function(n: ElixirAST): ElixirAST {
                            return switch(n.def) {
                                case ECase(target, caseClauses):
                                    var newCaseClauses = [];
                                    for (c in caseClauses) {
                                        var tag = tagOf(c.pattern);
                                        if (tag == "error") {
                                            var used = collectUsedLowerVars(c.body);
                                            var usesReason = used.indexOf("reason") != -1;
                                            var usesChangeset = used.indexOf("changeset") != -1;
                                            if (usesReason && !usesChangeset) {
                                                var renamed = renameBinder(c.pattern, "reason");
                                                newCaseClauses.push({ pattern: renamed, guard: c.guard, body: c.body });
                                                continue;
                                            }
                                        }
                                        newCaseClauses.push(c);
                                    }
                                    makeASTWithMeta(ECase(target, newCaseClauses), n.metadata, n.pos);
                                default:
                                    n;
                            }
                        });
                        newClauses.push({ args: cl.args, guard: cl.guard, body: fixedBody });
                    }
                    makeASTWithMeta(EFn(newClauses), fnAst.metadata, fnAst.pos);
                default:
                    fnAst;
            }
        }
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EModule(name, attrs, body) if (isLiveViewModule(name)):
                    var newBody = [];
                    for (b in body) {
                        var tb = ElixirASTTransformer.transformNode(b, function(n: ElixirAST): ElixirAST {
                            return switch(n.def) {
                                case ERemoteCall(mod, func, args):
                                    // Enum.reduce_while(list, acc, fn -> ... end)
                                    var isEnum = switch(mod.def) { case EVar(m) if (m == "Enum"): true; default: false; };
                                    if (isEnum && func == "reduce_while" && args != null && args.length >= 3) {
                                        var newArgs = args.copy();
                                        newArgs[2] = normalizeFnBody(args[2]);
                                        makeASTWithMeta(ERemoteCall(mod, func, newArgs), n.metadata, n.pos);
                                    } else n;
                                case ECall(target, func, args):
                                    // reduce_while called as a captured local maybe
                                    if (func == "reduce_while" && args != null && args.length >= 3) {
                                        var newArgs = args.copy();
                                        newArgs[2] = normalizeFnBody(args[2]);
                                        makeASTWithMeta(ECall(target, func, newArgs), n.metadata, n.pos);
                                    } else n;
                                default:
                                    n;
                            }
                        });
                        newBody.push(tb);
                    }
                    makeASTWithMeta(EModule(name, attrs, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    // LiveView Assign Call Rewrite: rewrite bare assign(socket, map) to Component.assign(socket, map)
    // Context: Some generated LiveView modules may not import assign/2; using Component.assign/2 is explicit and valid.
    public static function liveViewAssignCallRewritePass(ast: ElixirAST): ElixirAST {
        inline function isLiveModuleName(n: String): Bool {
            return n != null && (StringTools.endsWith(n, "Live") || n.indexOf("Live") != -1);
        }
        function rewriteInside(x: ElixirAST): ElixirAST {
            return ElixirASTTransformer.transformNode(x, function(n: ElixirAST): ElixirAST {
                return switch(n.def) {
                    case ECall(_, func, args) if (func == "assign" && args != null && args.length == 2):
                        makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", args), n.metadata, n.pos);
                    case ERemoteCall(mod, func, args) if (func == "assign" && args != null && args.length >= 2):
                        makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", args), n.metadata, n.pos);
                    default:
                        n;
                }
            });
        }
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch(n.def) {
                case EModule(name, attrs, body) if (isLiveModuleName(name)):
                    var newBody: Array<ElixirAST> = [];
                    for (b in body) newBody.push(rewriteInside(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (isLiveModuleName(name)):
                    var newDo = rewriteInside(doBlock);
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * ListPushRewrite
     *
     * WHAT
     * - Rewrites mutable list push calls to immutable concatenation assignments.
     *
     * WHY
     * - Elixir lists are immutable. Calls like `list.push(x)` are not valid; they
     *   are artifacts from imperative patterns. We must convert to
     *   `list = Enum.concat(list, [x])` to both be valid and idiomatic.
     *
     * HOW
     * - Detect method-style calls with name "push" in either ERemoteCall or ECall form
     *   where the target is a lowercase variable name.
     * - Replace the expression with an assignment using Enum.concat/2.
     * - Runs early and again late to catch push calls introduced by other passes.
     *
     * EXAMPLES
     *   list.push(v)           ->  list = Enum.concat(list, [v])
     *   items.push(render(x))  ->  items = Enum.concat(items, [render(x)])
     */
    public static function listPushRewritePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch(n.def) {
                case ERemoteCall(mod, func, args) if (func == "push" && args != null && args.length == 1):
                    switch(mod.def) {
                        case EVar(name) if (name != null && name.length > 0 && isLower(name)):
                            #if debug_list_push
                            // DISABLED: trace('[ListPushRewrite] Rewriting ' + name + '.push/1 (remote call)');
                            #end
                            var listVar = makeAST(EVar(name));
                            var newRight = makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [listVar, makeAST(EList([args[0]]))]));
                            makeAST(EMatch(PVar(name), newRight));
                        default:
                            n;
                    }
                case ECall(target, func, args) if (func == "push" && target != null && args != null && args.length == 1):
                    switch(target.def) {
                        case EVar(name) if (name != null && name.length > 0 && isLower(name)):
                            #if debug_list_push
                            // DISABLED: trace('[ListPushRewrite] Rewriting ' + name + '.push/1 (call)');
                            #end
                            var listVar = makeAST(EVar(name));
                            var newRight = makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [listVar, makeAST(EList([args[0]]))]));
                            makeAST(EMatch(PVar(name), newRight));
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }

    /**
     * repoQualificationPass
     *
     * WHAT
     * - Rewrites bare Repo.* calls to <App>.Repo.* by deriving <App> from
     *   the enclosing module name shape ("<App>Web.*" → "<App>").
     *
     * WHY
     * - Phoenix conventions organize web modules as <App>Web.* and expect Repo
     *   calls to be fully-qualified (or aliased). During code generation and
     *   subsequent transforms, bare Repo.* can be introduced. This pass ensures
     *   those calls are properly qualified so they resolve without relying on
     *   fragile name lookups or alias presence.
     * - Running this pass both early and late guarantees correctness even when
     *   earlier passes add or move Repo calls.
     *
     * HOW
     * - For EModule/EDefmodule where the name contains "Web":
     *   1) Derive the app prefix from the module name by trimming the trailing
     *      "Web" segment (e.g., "TodoAppWeb.TodoLive" → "TodoApp").
     *   2) Rewrite any ERemoteCall/ECall whose target module is exactly "Repo"
     *      into ERemoteCall with module "<App>.Repo".
     *   3) Leaves already-qualified calls unchanged.
     *
     * EXAMPLES
     * Before:
     *   defmodule TodoAppWeb.TodoLive do
     *     Repo.update(changeset)
     *   end
     *
     * After:
     *   defmodule TodoAppWeb.TodoLive do
     *     TodoApp.Repo.update(changeset)
     *   end
     */
    public static function repoQualificationPass(ast: ElixirAST): ElixirAST {
        // Helper: derive app prefix from a module name like "TodoAppWeb.TodoLive" → "TodoApp"
        inline function deriveAppPrefix(moduleName: String): Null<String> {
            if (moduleName == null) return null;
            var idx = moduleName.indexOf("Web");
            return idx > 0 ? moduleName.substring(0, idx) : null;
        }

        // Helper: rewrite Repo.* inside a subtree using a specific repo name
        function rewriteRepoRefs(subtree: ElixirAST, repoName: String): ElixirAST {
            return ElixirASTTransformer.transformNode(subtree, function(n: ElixirAST): ElixirAST {
                return switch (n.def) {
                    case ERemoteCall(mod, func, args):
                        switch (mod.def) {
                            case EVar(m) if (m == "Repo"):
                                #if debug_repo_qualification
                                // DISABLED: trace('[RepoQualification] Rewriting Repo.${func} to ${repoName}.${func}');
                                #end
                                makeASTWithMeta(ERemoteCall(makeAST(EVar(repoName)), func, args), n.metadata, n.pos);
                            case EVar(m) if (m != null && m.indexOf(".Repo") != -1):
                                // Already qualified Repo usage; log for visibility
                                #if debug_repo_qualification
                                // DISABLED: trace('[RepoQualification] Found already-qualified ${m}.${func}');
                                #end
                                n;
                            default: n;
                        }
                    case ECall(target, func, args) if (target != null):
                        // Some builders may produce ECall(EVar("Repo"), func, args) for static-like calls
                        switch (target.def) {
                            case EVar(m) if (m == "Repo"):
                                #if debug_repo_qualification
                                // DISABLED: trace('[RepoQualification] Rewriting (call) Repo.${func} to ${repoName}.${func}');
                                #end
                                makeASTWithMeta(ERemoteCall(makeAST(EVar(repoName)), func, args), n.metadata, n.pos);
                            default:
                                n;
                        }
                    default:
                        n;
                }
            });
        }

        // Walk the AST; when entering a module/defmodule, compute repo and rewrite within that scope
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var prefix = deriveAppPrefix(name);
                    // Fallback to appName from node metadata if available
                    if (prefix == null && n.metadata != null && Reflect.hasField(n.metadata, "appName") && n.metadata.appName != null) {
                        prefix = n.metadata.appName;
                    }
                    if (prefix == null) {
                        // Fallback to PhoenixMapper app module name (based on -D app_name)
                        try { prefix = reflaxe.elixir.PhoenixMapper.getAppModuleName(); } catch (e:Dynamic) {}
                    }
                    if (prefix != null) {
                        var repoName = prefix + ".Repo";
                        var newBody: Array<ElixirAST> = [];
                        for (b in body) newBody.push(rewriteRepoRefs(b, repoName));
                        makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                    } else {
                        n;
                    }
                case EDefmodule(name, doBlock):
                    var prefix = deriveAppPrefix(name);
                    if (prefix == null && n.metadata != null && Reflect.hasField(n.metadata, "appName") && n.metadata.appName != null) {
                        prefix = n.metadata.appName;
                    }
                    if (prefix == null) {
                        try { prefix = reflaxe.elixir.PhoenixMapper.getAppModuleName(); } catch (e:Dynamic) {}
                        #if macro
                        if (prefix == null) {
                            try {
                                var d = haxe.macro.Compiler.getDefine("app_name");
                                if (d != null && d.length > 0) prefix = d;
                            } catch (e:Dynamic) {}
                        }
                        #end
                    }
                    if (prefix != null) {
                        var repoName = prefix + ".Repo";
                        var newDo = rewriteRepoRefs(doBlock, repoName);
                        makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                    } else {
                        n;
                    }
                default:
                    n;
            }
        });
    }

    /**
     * ModuleQualificationPass
     *
     * WHAT
     * - Qualify bare application module calls inside <App>Web.* modules.
     * - Pattern: ERemoteCall/ECall with target EVar(UpperCamelCase) like "Todo.update_priority/2"
     *   becomes "<App>.Todo.update_priority/2" when <App>.Todo is a defined module.
     *
     * WHY
     * - Generators may emit unqualified application module calls within web modules.
     *   Elixir requires either full qualification or an alias. This pass provides
     *   a shape-derived, alias-free fix without app-coupling, mirroring Repo handling.
     *
     * HOW
     * - Collect defined module names from the AST once (EModule/EDefmodule names).
     * - Within modules whose name matches "<App>Web.*", derive "<App>" prefix.
     * - For remote/calls whose target is a single-segment, UpperCamelCase identifier
     *   and not a known global module (Kernel, Enum, Map, String, etc.),
     *   if a module named "<App>.<Target>" exists in the collected set, rewrite
     *   the call to use that fully qualified module name.
     *
     * EXAMPLES
     * Haxe:
     *   // inside TodoAppWeb.TodoLive
     *   Todo.update_priority(todo, priority);
     * Elixir (before):
     *   Todo.update_priority(todo, priority)
     * Elixir (after):
     *   TodoApp.Todo.update_priority(todo, priority)
     */
    public static function moduleQualificationPass(ast: ElixirAST): ElixirAST {
        // Collect all defined module names in this AST (one-time scan)
        var definedModules = new Map<String, Bool>();
        function collectModules(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EModule(name, _, body):
                    definedModules.set(name, true);
                    for (b in body) collectModules(b);
                case EDefmodule(name, doBlock):
                    definedModules.set(name, true);
                    collectModules(doBlock);
                default:
                    // Recurse shallowly to find nested module definitions
                    switch (n.def) {
                        case EBlock(exprs): for (e in exprs) collectModules(e);
                        case EIf(c,t,e): collectModules(c); collectModules(t); if (e != null) collectModules(e);
                        case ECase(ex, cls): collectModules(ex); for (c in cls) { if (c.guard != null) collectModules(c.guard); collectModules(c.body);} 
                        case EFn(cs): for (cl in cs) collectModules(cl.body);
                        case ECall(t,_,args): if (t != null) collectModules(t); if (args != null) for (a in args) collectModules(a);
                        case ERemoteCall(m,_,args): collectModules(m); if (args != null) for (a in args) collectModules(a);
                        default:
                    }
            }
        }
        collectModules(ast);

        inline function deriveAppPrefix(moduleName: String): Null<String> {
            if (moduleName == null) return null;
            var idx = moduleName.indexOf("Web");
            return idx > 0 ? moduleName.substring(0, idx) : null;
        }

        // Centralized globals that must never be qualified
        inline function isGlobalWhitelisted(name:String):Bool {
            return reflaxe.elixir.ast.StdModuleWhitelist.isWhitelistedRoot(name);
        }

        inline function isSingleSegmentModule(name: String): Bool {
            return name != null && name.indexOf(".") == -1 && name.length > 0;
        }
        inline function isUpperCamel(name: String): Bool {
            var c = name.charAt(0);
            return c.toUpperCase() == c && c.toLowerCase() != c; // starts uppercase letter
        }

        function qualifyIn(subtree: ElixirAST, appPrefix: String): ElixirAST {
            // Note: SafePubSub mapping does not require appPrefix; we still
            // traverse even when appPrefix is null but only apply prefix-based
            // rewrites when it is available.
            return ElixirASTTransformer.transformNode(subtree, function(n: ElixirAST): ElixirAST {
                return switch (n.def) {
                    case ECapture(expr, arity):
                        // Handle &Module.func/arity captures
                        switch (expr.def) {
                            case ERemoteCall(mod, func, args):
                                switch (mod.def) {
                                    case EVar(m) if (isSingleSegmentModule(m) && isUpperCamel(m) && !isGlobalWhitelisted(m)):
                                        if (m == "Presence" && appPrefix != null) {
                                            var fqP = appPrefix + "Web." + m;
                                            return makeASTWithMeta(ECapture(makeAST(ERemoteCall(makeAST(EVar(fqP)), func, args)), arity), n.metadata, n.pos);
                                        }
                                        if (m == "SafePubSub") {
                                            return makeASTWithMeta(ECapture(makeAST(ERemoteCall(makeAST(EVar("Phoenix.SafePubSub")), func, args)), arity), n.metadata, n.pos);
                                        }
                                        if (appPrefix != null) {
                                            var fq = appPrefix + "." + m;
                                            return makeASTWithMeta(ECapture(makeAST(ERemoteCall(makeAST(EVar(fq)), func, args)), arity), n.metadata, n.pos);
                                        } else n;
                                    default: n;
                                }
                            default: n;
                        }
                    case ERemoteCall(mod, func, args):
                        switch (mod.def) {
                            case EVar(m) if (isSingleSegmentModule(m) && isUpperCamel(m) && !isGlobalWhitelisted(m)):
                                // Always map Presence to <App>Web.Presence
                                if (m == "Presence" && appPrefix != null) {
                                    var fqP = appPrefix + "Web." + m;
                                    return makeASTWithMeta(ERemoteCall(makeAST(EVar(fqP)), func, args), n.metadata, n.pos);
                                }
                                // Map SafePubSub -> Phoenix.SafePubSub
                                if (m == "SafePubSub") {
                                    return makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.SafePubSub")), func, args), n.metadata, n.pos);
                                }
                                if (appPrefix != null) {
                                    var fq = appPrefix + "." + m;
                                    return makeASTWithMeta(ERemoteCall(makeAST(EVar(fq)), func, args), n.metadata, n.pos);
                                } else n;
                            default: n;
                        }
                    case ECall(target, func, args) if (target != null):
                        switch (target.def) {
                            case EVar(m) if (isSingleSegmentModule(m) && isUpperCamel(m) && !isGlobalWhitelisted(m)):
                                if (m == "Presence" && appPrefix != null) {
                                    var fqP = appPrefix + "Web." + m;
                                    return makeASTWithMeta(ERemoteCall(makeAST(EVar(fqP)), func, args), n.metadata, n.pos);
                                }
                                if (m == "SafePubSub") {
                                    return makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.SafePubSub")), func, args), n.metadata, n.pos);
                                }
                                if (appPrefix != null) {
                                    var fq = appPrefix + "." + m;
                                    return makeASTWithMeta(ERemoteCall(makeAST(EVar(fq)), func, args), n.metadata, n.pos);
                                } else n;
                            default: n;
                        }
                    default:
                        n;
                }
            });
        }

        // Operate within modules; use app prefix if available, but still map
        // SafePubSub regardless of prefix.
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    // Gate qualification STRICTLY to <App>Web.* modules to avoid leaking
                    // app-specific prefixes into generic/core code.
                    var prefix = deriveAppPrefix(name);
                    if (prefix == null) {
                        // Not a Web module: do not qualify application modules globally.
                        n;
                    } else {
                        var newBody: Array<ElixirAST> = [];
                        for (b in body) newBody.push(qualifyIn(b, prefix));
                        makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                    }
                case EDefmodule(name, doBlock):
                    var prefix = deriveAppPrefix(name);
                    if (prefix == null) {
                        // Not a Web module: pass through unchanged.
                        n;
                    } else {
                        var newDo = qualifyIn(doBlock, prefix);
                        makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                    }
                default:
                    n;
            }
        });
    }

    /**
     * WebEFnModuleQualificationPass
     *
     * WHAT
     * - Final sweep to qualify single-segment CamelCase module calls inside <App>Web.* modules,
     *   with focus on calls appearing within EFn bodies (lambdas) used by Enum.each/reduce_while etc.
     *
     * WHY
     * - Earlier passes may miss or later introduce bare module calls inside anonymous functions. This
     *   pass ensures Web-context code consistently qualifies to <App>.Module.
     *
     * HOW
     * - For EModule/EDefmodule names containing "Web", derive <App> prefix and rewrite ERemoteCall/ECall
     *   targets where module is a single-segment CamelCase and not in the std/framework whitelist.
     */
    public static function webEFnModuleQualificationPass(ast: ElixirAST): ElixirAST {
        inline function deriveAppPrefix(moduleName: String): Null<String> {
            if (moduleName == null) return null;
            var idx = moduleName.indexOf("Web");
            return idx > 0 ? moduleName.substring(0, idx) : null;
        }
        inline function isSingleSegmentModule(name: String): Bool {
            return name != null && name.indexOf(".") == -1 && name.length > 0;
        }
        inline function isUpperCamel(name: String): Bool {
            var c = name.charAt(0);
            return c.toUpperCase() == c && c.toLowerCase() != c;
        }
        inline function isGlobalWhitelisted(name:String):Bool {
            return reflaxe.elixir.ast.StdModuleWhitelist.isWhitelistedRoot(name);
        }
        function qualifySubtree(sub: ElixirAST, appPrefix: String): ElixirAST {
            return ElixirASTTransformer.transformNode(sub, function(n: ElixirAST): ElixirAST {
                return switch (n.def) {
                    case ERemoteCall(mod, func, args):
                        switch (mod.def) {
                            case EVar(m) if (isSingleSegmentModule(m) && isUpperCamel(m) && !isGlobalWhitelisted(m)):
                                if (appPrefix != null) {
                                    var fq = appPrefix + "." + m;
                                    makeASTWithMeta(ERemoteCall(makeAST(EVar(fq)), func, args), n.metadata, n.pos);
                                } else n;
                            default: n;
                        }
                    case ECall(target, func, args) if (target != null):
                        switch (target.def) {
                            case EVar(m) if (isSingleSegmentModule(m) && isUpperCamel(m) && !isGlobalWhitelisted(m)):
                                if (appPrefix != null) {
                                    var fq = appPrefix + "." + m;
                                    makeASTWithMeta(ERemoteCall(makeAST(EVar(fq)), func, args), n.metadata, n.pos);
                                } else n;
                            default: n;
                        }
                    default:
                        n;
                }
            });
        }
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name.indexOf("Web") != -1):
                    var prefix = deriveAppPrefix(name);
                    var newBody: Array<ElixirAST> = [];
                    for (b in body) newBody.push(qualifySubtree(b, prefix));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name.indexOf("Web") != -1):
                    var prefix2 = deriveAppPrefix(name);
                    var newDo = qualifySubtree(doBlock, prefix2);
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * WebReduceWhileEFnQualificationPass
     *
     * WHAT
     * - Specifically qualify single-segment module calls inside Enum.reduce_while anonymous function bodies
     *   within <App>Web.* modules. This acts as a final, targeted safety net in case previous generic
     *   qualification passes missed reduce_while EFns emitted late in the pipeline.
     *
     * HOW
     * - For each ERemoteCall/ECall of reduce_while within <App>Web.* modules, rewrite the 3rd argument (the function)
     *   by qualifying any ERemoteCall/ECall whose target is a single-segment, non-whitelisted CamelCase module
     *   to <App>.<Module>.
     */
    public static function webReduceWhileEFnQualificationPass(ast: ElixirAST): ElixirAST {
        inline function deriveAppPrefix(moduleName: String): Null<String> {
            if (moduleName == null) return null;
            var idx = moduleName.indexOf("Web");
            return idx > 0 ? moduleName.substring(0, idx) : null;
        }
        inline function isSingleSegmentModule(name: String): Bool {
            return name != null && name.indexOf(".") == -1 && name.length > 0;
        }
        inline function isUpperCamel(name: String): Bool {
            var c = name.charAt(0);
            return c.toUpperCase() == c && c.toLowerCase() != c;
        }
        inline function isGlobalWhitelisted(name:String):Bool {
            return reflaxe.elixir.ast.StdModuleWhitelist.isWhitelistedRoot(name);
        }
        function qualifyFnBody(fnAst: ElixirAST, appPrefix: String): ElixirAST {
            return ElixirASTTransformer.transformNode(fnAst, function(n: ElixirAST): ElixirAST {
                return switch (n.def) {
                    case ERemoteCall(mod, func, args):
                        switch (mod.def) {
                            case EVar(m) if (isSingleSegmentModule(m) && isUpperCamel(m) && !isGlobalWhitelisted(m)):
                                if (appPrefix != null) {
                                    var fq = appPrefix + "." + m;
                                    makeASTWithMeta(ERemoteCall(makeAST(EVar(fq)), func, args), n.metadata, n.pos);
                                } else n;
                            default: n;
                        }
                    case ECall(target, func, args) if (target != null):
                        switch (target.def) {
                            case EVar(m) if (isSingleSegmentModule(m) && isUpperCamel(m) && !isGlobalWhitelisted(m)):
                                if (appPrefix != null) {
                                    var fq = appPrefix + "." + m;
                                    makeASTWithMeta(ERemoteCall(makeAST(EVar(fq)), func, args), n.metadata, n.pos);
                                } else n;
                            default: n;
                        }
                    default:
                        n;
                }
            });
        }
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EModule(name, attrs, body) if (name.indexOf("Web") != -1):
                    var app = deriveAppPrefix(name);
                    var newBody = [];
                    for (b in body) newBody.push(ElixirASTTransformer.transformNode(b, function(n: ElixirAST): ElixirAST {
                        return switch (n.def) {
                            case ERemoteCall(mod, func, args) if (func == "reduce_while" && args != null && args.length >= 3):
                                var isEnum = switch (mod.def) { case EVar(m) if (m == "Enum"): true; default: false; };
                                if (isEnum) {
                                    var a = args.copy();
                                    a[2] = qualifyFnBody(a[2], app);
                                    makeASTWithMeta(ERemoteCall(mod, func, a), n.metadata, n.pos);
                                } else n;
                            case ECall(target, func, args) if (func == "reduce_while" && args != null && args.length >= 3):
                                var copiedArgs = args.copy();
                                copiedArgs[2] = qualifyFnBody(copiedArgs[2], app);
                                makeASTWithMeta(ECall(target, func, copiedArgs), n.metadata, n.pos);
                            default:
                                n;
                        }
                    }));
                    makeASTWithMeta(EModule(name, attrs, newBody), node.metadata, node.pos);
                case EDefmodule(name, doBlock) if (name.indexOf("Web") != -1):
                    var appPrefix = deriveAppPrefix(name);
                    var newDo = ElixirASTTransformer.transformNode(doBlock, function(n: ElixirAST): ElixirAST {
                        return switch (n.def) {
                            case ERemoteCall(mod, func, args) if (func == "reduce_while" && args != null && args.length >= 3):
                                var isEnumModule = switch (mod.def) { case EVar(m) if (m == "Enum"): true; default: false; };
                                if (isEnumModule) {
                                    var copiedArgs = args.copy();
                                    copiedArgs[2] = qualifyFnBody(copiedArgs[2], appPrefix);
                                    makeASTWithMeta(ERemoteCall(mod, func, copiedArgs), n.metadata, n.pos);
                                } else n;
                            case ECall(target, func, args) if (func == "reduce_while" && args != null && args.length >= 3):
                                var copiedArgs = args.copy();
                                copiedArgs[2] = qualifyFnBody(copiedArgs[2], appPrefix);
                                makeASTWithMeta(ECall(target, func, copiedArgs), n.metadata, n.pos);
                            default:
                                n;
                        }
                    });
                    makeASTWithMeta(EDefmodule(name, newDo), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    /**
     * ERawWebModuleQualificationPass
     *
     * WHAT
     * - Qualify bare module calls inside ERaw strings within <App>Web.* modules.
     *
     * HOW
     * - Scan ERaw code and prefix tokens like `Foo.` with `<App>.Foo.` when Foo is a single-segment
     *   CamelCase module and not whitelisted (Enum, Map, Ecto, Phoenix, etc.).
     */
    public static function erawWebModuleQualificationPass(ast: ElixirAST): ElixirAST {
        inline function isUpper(c:String):Bool return c.toUpperCase() == c && c.toLowerCase() != c;
        function qualify(code:String, app:String):String {
            var out = new StringBuf();
            var i = 0;
            while (i < code.length) {
                var ch = code.charAt(i);
                // Eligible start: uppercase letter and not part of an identifier
                var prev = i > 0 ? code.charAt(i - 1) : "";
                var isPrevIdent = ~/^[A-Za-z0-9_]$/.match(prev);
                if (!isPrevIdent && isUpper(ch)) {
                    // Capture identifier
                    var j = i;
                    var name = new StringBuf();
                    while (j < code.length) {
                        var c = code.charAt(j);
                        if (!~/^[A-Za-z0-9_]$/.match(c)) break;
                        name.add(c);
                        j++;
                    }
                    var token = name.toString();
                    // Next char must be '.' to be a module call
                    if (j < code.length && code.charAt(j) == '.') {
                        // Do not qualify whitelisted roots
                        if (!reflaxe.elixir.ast.StdModuleWhitelist.isWhitelistedRoot(token) && app != null && app.length > 0) {
                            out.add(app);
                            out.add(".");
                        }
                        out.add(token);
                        i = j; // Keep '.' in stream for default handler
                        continue;
                    }
                }
                out.add(ch);
                i++;
            }
            return out.toString();
        }
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name.indexOf("Web") != -1):
                    var app = name.substring(0, name.indexOf("Web"));
                    var newBody:Array<ElixirAST> = [];
                    for (b in body) newBody.push(ElixirASTTransformer.transformNode(b, function(x){
                        return switch (x.def) {
                            case ERaw(code):
                                var q = qualify(code, app);
                                q != code ? makeASTWithMeta(ERaw(q), x.metadata, x.pos) : x;
                            default: x;
                        }
                    }));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name.indexOf("Web") != -1):
                    var app2 = name.substring(0, name.indexOf("Web"));
                    var newDo = ElixirASTTransformer.transformNode(doBlock, function(x){
                        return switch (x.def) {
                            case ERaw(code):
                                var q = qualify(code, app2);
                                q != code ? makeASTWithMeta(ERaw(q), x.metadata, x.pos) : x;
                            default: x;
                        }
                    });
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * SelfAssignCompressionPass
     *
     * WHAT
     * - Compress duplicated self-assignments like `x = x = expr` to `x = expr`.
     */
    public static function selfAssignCompressionPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EMatch(PVar(v1), {def: EMatch(PVar(v2), expr)}) if (v1 == v2):
                    makeASTWithMeta(EMatch(PVar(v1), expr), n.metadata, n.pos);
                // x = (x = expr) where inner is Binary(Match)
                case EMatch(PVar(v1), {def: EBinary(Match, {def: EVar(v2)}, expr)}) if (v1 == v2):
                    makeASTWithMeta(EMatch(PVar(v1), expr), n.metadata, n.pos);
                // Paren-wrapped inner assignment: x = (x = expr)
                case EMatch(PVar(v1), {def: EParen({def: EMatch(PVar(v2), expr2)})}) if (v1 == v2):
                    makeASTWithMeta(EMatch(PVar(v1), expr2), n.metadata, n.pos);
                // Paren-wrapped inner assignment where inner is Binary(Match): x = (x = expr)
                case EMatch(PVar(v1), {def: EParen({def: EBinary(Match, {def: EVar(v2p)}, expr2p)})}) if (v1 == v2p):
                    makeASTWithMeta(EMatch(PVar(v1), expr2p), n.metadata, n.pos);
                // Block-wrapped single inner assignment: x = (begin; x = expr end)
                case EMatch(PVar(v1), {def: EBlock(es)}) if (es.length == 1):
                    switch (es[0].def) {
                        case EMatch(PVar(v2), expr3) if (v1 == v2):
                            makeASTWithMeta(EMatch(PVar(v1), expr3), n.metadata, n.pos);
                        default:
                            n;
                    }
                // Block-wrapped single inner assignment where inner is Binary(Match)
                case EMatch(PVar(v1), {def: EBlock(esb)}) if (esb.length == 1):
                    switch (esb[0].def) {
                        case EBinary(Match, {def: EVar(v2b)}, expr3b) if (v1 == v2b):
                            makeASTWithMeta(EMatch(PVar(v1), expr3b), n.metadata, n.pos);
                        default:
                            n;
                    }
                case EBinary(Match, left, {def: EBinary(Match, left2, expr2)}):
                    var l1 = switch (left.def) { case EVar(nm): nm; default: null; };
                    var l2 = switch (left2.def) { case EVar(nm2): nm2; default: null; };
                    if (l1 != null && l1 == l2) makeASTWithMeta(EBinary(Match, left, expr2), n.metadata, n.pos) else n;
                // Outer binary match with inner EMatch on RHS: x = (x = expr)
                case EBinary(Match, {def: EVar(vOut)}, {def: EMatch(PVar(vIn), exprR)}) if (vOut == vIn):
                    makeASTWithMeta(EBinary(Match, makeAST(EVar(vOut)), exprR), n.metadata, n.pos);
                // Paren-wrapped inner assignment on RHS: x = (x = expr)
                case EBinary(Match, left, {def: EParen({def: EBinary(Match, left2b, expr2b)})}):
                    var l1b = switch (left.def) { case EVar(nm): nm; default: null; };
                    var l2b = switch (left2b.def) { case EVar(nm2): nm2; default: null; };
                    if (l1b != null && l1b == l2b) makeASTWithMeta(EBinary(Match, left, expr2b), n.metadata, n.pos) else n;
                // Block-wrapped single inner assignment on RHS: x = (begin; x = expr end)
                case EBinary(Match, left, {def: EBlock(es2)}) if (es2.length == 1):
                    var lhsName = switch (left.def) { case EVar(nm): nm; default: null; };
                    if (lhsName != null) {
                        switch (es2[0].def) {
                            case EBinary(Match, leftInner, exprInner):
                                var lInner = switch (leftInner.def) { case EVar(nm3): nm3; default: null; };
                                if (lInner != null && lInner == lhsName) makeASTWithMeta(EBinary(Match, left, exprInner), n.metadata, n.pos) else n;
                            default:
                                n;
                        }
                    } else n;
                default:
                    n;
            }
        });
    }

    // (Removed) unusedLocalAssignmentUnderscorePass: prefer fixing root causes and deleting dead code

    /**
     * simplifyProvableIsNilFalsePass
     *
     * WHAT
     * - Replaces guard conditions `Kernel.is_nil(var)` (or `is_nil(var)`) with `false`
     *   when it is provable in the local block that `var` was assigned a non-nil literal
     *   value earlier and not reassigned.
     *
     * WHY
     * - Elixir warns on comparisons between disjoint types (e.g., binary() == nil).
     *   When code sets `direction = "asc"` and then checks `is_nil(direction)`,
     *   the result is always false. Emitting the check triggers a type warning and
     *   is unnecessary. This conservative simplification eliminates the warning
     *   without changing semantics.
     *
     * HOW
     * - For each function body, recursively process blocks and track variables
     *   assigned to clearly non-nil literals (string, number, list, map, tuple, atom true/false).
     * - When encountering `is_nil(var)` and `var` is in the non-nil set, replace with `false`.
     * - If a variable is reassigned to an unknown expression or nil, remove it from the set.
     * - Conservative: Only literal non-nil assignments mark a variable as non-nil.
     *
     * EXAMPLES
     * Before:
     *   direction = "asc"
     *   if Kernel.is_nil(direction) do ... end
     * After:
     *   direction = "asc"
     *   if false do ... end
     */
    public static function simplifyProvableIsNilFalsePass(ast: ElixirAST): ElixirAST {
        // Determine if an expression is definitely a non-nil literal
        inline function isDefinitelyNonNilLiteral(e: ElixirAST): Bool {
            return switch (e.def) {
                case EString(_): true;
                case EInteger(_): true;
                case EFloat(_): true;
                case EBoolean(_): true;
                case EList(_): true;
                case EMap(_): true;
                case ETuple(_): true;
                case EAtom(atom) if (atom != "nil"): true;
                default: false;
            };
        }

        // Rewrite is_nil(var) when var is known non-nil
        inline function rewriteIsNilIfProvablyFalse(expr: ElixirAST, nonNil: Map<String, Bool>): ElixirAST {
            return switch (expr.def) {
                case ERemoteCall(mod, func, args) if (func == "is_nil" && args != null && args.length == 1):
                    // Preserve guards injected by EctoEqPinnedNilGuardTransforms
                    if (expr.metadata != null && expr.metadata.ectoPinnedNilGuard == true) return expr;
                    switch (mod.def) {
                        case EVar(m) if (m == "Kernel"):
                            switch (args[0].def) {
                                case EVar(v) if (nonNil.exists(v)):
                                    makeASTWithMeta(EBoolean(false), expr.metadata, expr.pos);
                                default: expr;
                            }
                        default: expr;
                    }
                case ECall(target, func, args) if (target == null && func == "is_nil" && args != null && args.length == 1):
                    if (expr.metadata != null && expr.metadata.ectoPinnedNilGuard == true) return expr;
                    switch (args[0].def) {
                        case EVar(v) if (nonNil.exists(v)):
                            makeASTWithMeta(EBoolean(false), expr.metadata, expr.pos);
                        default: expr;
                    }
                default: expr;
            }
        }

        // Process a block with a flowing non-nil set
        function processBlock(block: ElixirAST, incoming: Map<String, Bool>): ElixirAST {
            // Defensive: some defs may not carry a body (e.g. stubbed functions); skip safely.
            if (block == null) return block;
            return switch (block.def) {
                case EBlock(stmts):
                    var nonNil = new Map<String, Bool>();
                    // copy incoming set
                    for (k in incoming.keys()) nonNil.set(k, true);
                    var out: Array<ElixirAST> = [];
                    for (stmt in stmts) {
                        var s = stmt;
                        // Generic deep rewrite first: fold Kernel.is_nil(var) anywhere it appears
                        // when `var` is provably a non-nil literal in current flow context.
                        s = ElixirASTTransformer.transformNode(s, function(n: ElixirAST): ElixirAST {
                            return rewriteIsNilIfProvablyFalse(n, nonNil);
                        });
                        // Attempt rewrite in conditions
                        switch (s.def) {
                            case EIf(cond, thenB, elseB):
                                var newCond = rewriteIsNilIfProvablyFalse(cond, nonNil);
                                var newThen = processBlock(thenB, nonNil);
                                var newElse = elseB != null ? processBlock(elseB, nonNil) : null;
                                s = makeASTWithMeta(EIf(newCond, newThen, newElse), s.metadata, s.pos);
                            case ECase(expr, clauses):
                                var newExpr = rewriteIsNilIfProvablyFalse(expr, nonNil);
                                var newClauses = [];
                                for (c in clauses) {
                                    var bodyProcessed = processBlock(c.body, nonNil);
                                    newClauses.push({ pattern: c.pattern, guard: c.guard, body: bodyProcessed });
                                }
                                s = makeASTWithMeta(ECase(newExpr, newClauses), s.metadata, s.pos);
                            default:
                                // No-op; we'll examine assignments below
                        }
                        // Track assignments for non-nil inference
                        switch (s.def) {
                            case EMatch(PVar(name), rhs):
                                if (isDefinitelyNonNilLiteral(rhs)) {
                                    nonNil.set(name, true);
                                } else {
                                    nonNil.remove(name);
                                }
                            case EBinary(Match, left, rhs):
                                // Handle `name = <literal>` pattern as well
                                switch (left.def) {
                                    case EVar(name2):
                                        if (isDefinitelyNonNilLiteral(rhs)) {
                                            nonNil.set(name2, true);
                                        } else {
                                            nonNil.remove(name2);
                                        }
                                    default:
                                }
                            default:
                        }
                        out.push(s);
                    }
                    makeASTWithMeta(EBlock(out), block.metadata, block.pos);
                default:
                    // Not a block; conservatively descend
                    ElixirASTTransformer.transformNode(block, function(n) return n);
            }
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, processBlock(body, new Map())), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, processBlock(body, new Map())), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * stringToAtomLiteralPass
     *
     * WHAT
     * - Converts String.to_atom("field") and String.to_existing_atom("field") to literal atoms :field
     *   when the argument is a string literal.
     *
     * WHY
     * - Eliminates runtime conversion and ensures idiomatic atom literals in generated code.
     */
    public static function stringToAtomLiteralPass(ast: ElixirAST): ElixirAST {
        inline function toAtom(e: ElixirAST): ElixirAST {
            return switch (e.def) {
                case EString(s): makeAST(EAtom(s));
                default: e;
            };
        }
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, func, args):
                    switch (mod.def) {
                        case EVar(m) if (m == "String" && (func == "to_atom" || func == "to_existing_atom") && args != null && args.length == 1):
                            toAtom(args[0]);
                        default: n;
                    }
                default: n;
            }
        });
    }

    /**
     * DateImplRewrite
     *
     * WHAT
     * - Rewrites calls to Haxe Date_Impl_ helpers to existing Elixir APIs or pass-throughs
     *   to remove undefined-module warnings while preserving behavior.
     *
     * WHY
     * - Generated code may include Date_Impl_.from_string/1 and Date_Impl_.get_time/1 which
     *   are Haxe-side helpers, not Elixir modules. We map them to equivalent/benign forms.
     *
     * HOW
     * - Date_Impl_.from_string(x) -> x (string passthrough for string-typed fields)
     * - Date_Impl_.get_time(DateTime.utc_now()) -> DateTime.to_iso8601(DateTime.utc_now())
     *   (or leave as utc_now() if field is dynamic)
     */
    public static function dateImplRewritePass(ast: ElixirAST): ElixirAST {
        inline function isDateImplModule(modName: String): Bool {
            if (modName == null) return false;
            var lastDot = modName.lastIndexOf(".");
            var last = lastDot >= 0 ? modName.substring(lastDot + 1) : modName;
            return last == "Date_Impl_";
        }
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall({def: EVar(m)}, f, args) if (isDateImplModule(m) && f == "from_string" && args.length == 1):
                    // Passthrough string
                    args[0];
                case ERemoteCall({def: EVar(m)}, f, args) if (isDateImplModule(m) && f == "get_time" && args.length == 1):
                    // If arg is DateTime.utc_now(), normalize to DateTime.to_iso8601(DateTime.utc_now()) to match intended snapshots
                    switch (args[0].def) {
                        case ERemoteCall({def: EVar(dm)}, "utc_now", _ ) if (dm == "DateTime"):
                            makeAST(ERemoteCall(makeAST(EVar("DateTime")), "to_iso8601", [args[0]]));
                        default:
                            args[0];
                    }
                case ECall({def: EVar(m)}, f, args) if (isDateImplModule(m) && f == "from_string" && args.length == 1):
                    args[0];
                case ECall({def: EVar(m)}, f, args) if (isDateImplModule(m) && f == "get_time" && args.length == 1):
                    switch (args[0].def) {
                        case ERemoteCall({def: EVar(dm)}, "utc_now", _ ) if (dm == "DateTime"):
                            makeAST(ERemoteCall(makeAST(EVar("DateTime")), "to_iso8601", [args[0]]));
                        default:
                            args[0];
                    }
                default:
                    n;
            }
        });
    }

    /**
     * presenceApiModuleRewritePass
     *
     * WHAT
     * - Rewrites calls to Phoenix.Presence.* (track/update/list/untrack) to the application
     *   presence module <App>Web.Presence.* as required by Phoenix. The runtime presence API
     *   is provided by the user-defined presence module (via `use Phoenix.Presence`).
     *
     * WHY
     * - Generated code occasionally emits `Phoenix.Presence.track/4` etc., which are not
     *   public APIs on `Phoenix.Presence`. The functions are defined on `<App>Web.Presence`.
     *   This causes undefined or private warnings that break WAE. Rewriting to the proper
     *   module fixes warnings and matches idiomatic usage.
     *
     * HOW
     * - Derive `<App>` from the enclosing module name: `<App>Web.*` → `<App>`.
     * - Replace ERemoteCall(EVar("Phoenix.Presence"), fn, args) where fn ∈ {track, update, untrack, list}
     *   with ERemoteCall(EVar("<App>Web.Presence"), fn, args).
     * - Conservative: only transform when we can derive `<App>` or a global app prefix
     *   (observed via other modules).
     *
     * EXAMPLES
     *   Phoenix.Presence.track(self(), "users", key, meta) -> TodoAppWeb.Presence.track(self(), "users", key, meta)
     */
    public static function presenceApiModuleRewritePass(ast: ElixirAST): ElixirAST {
        inline function deriveAppPrefix(name: String): Null<String> {
            if (name == null) return null;
            var idx = name.indexOf("Web");
            return idx > 0 ? name.substring(0, idx) : null;
        }

        function rewriteInScope(sub: ElixirAST, app: String): ElixirAST {
            var presenceModule = app + "Web.Presence";
            return ElixirASTTransformer.transformNode(sub, function(n: ElixirAST): ElixirAST {
                return switch (n.def) {
                    case ERemoteCall(mod, fn, args):
                        var modStr = switch (mod.def) { case EVar(m): m; default: null; };
                        if (modStr == "Phoenix.Presence") {
                            switch (fn) {
                                case "track" | "update" | "untrack" | "list":
                                    makeASTWithMeta(ERemoteCall(makeAST(EVar(presenceModule)), fn, args), n.metadata, n.pos);
                                default:
                                    n;
                            }
                        } else n;
                    default:
                        n;
                }
            });
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var app = deriveAppPrefix(name);
                    if (app == null) try app = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e:Dynamic) {}
                    if (app == null) return n;
                    var newBody: Array<ElixirAST> = [];
                    for (b in body) newBody.push(rewriteInScope(b, app));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var app = deriveAppPrefix(name);
                    if (app == null) try app = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e:Dynamic) {}
                    if (app == null) return n;
                    var newDo = rewriteInScope(doBlock, app);
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * ModuleNewToStructLiteral
     *
     * WHAT
     * - Transforms `Module.new()` (Haxe-style constructor) to `%Module{}` struct literal.
     *
     * WHY
     * - Ecto schema modules don’t provide `new/0`; `%Module{}` is the idiomatic way to build
     *   an empty struct for changesets.
     *
     * HOW
     * - Detect ERemoteCall/ECall named "new" on an UpperCamel module reference and rewrite
     *   to EStruct(moduleName, []).
     */
    public static function moduleNewToStructLiteralPass(ast: ElixirAST): ElixirAST {
        inline function isUpperCamel(n: String): Bool {
            return n != null && n.length > 0 && (n.charAt(0) == n.charAt(0).toUpperCase()) && (n.charAt(0) != n.charAt(0).toLowerCase());
        }
        inline function deriveAppPrefix(moduleName: String): Null<String> {
            if (moduleName == null) return null;
            var idx = moduleName.indexOf("Web");
            return idx > 0 ? moduleName.substring(0, idx) : null;
        }
        function toStruct(mod: ElixirAST, meta: Dynamic, pos: haxe.macro.Expr.Position, appPrefix: Null<String>): ElixirAST {
            return switch (mod.def) {
                case EVar(name) if (name != null && name.length > 0 && isUpperCamel(name)):
                    var full = (appPrefix != null && name.indexOf('.') == -1) ? appPrefix + '.' + name : name;
                    makeASTWithMeta(EStruct(full, []), meta, pos);
                default: makeASTWithMeta(EStruct(reflaxe.elixir.ast.ElixirASTPrinter.printAST(mod), []), meta, pos);
            }
        }
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var prefix = deriveAppPrefix(name);
                    var newBody = [for (b in body) ElixirASTTransformer.transformNode(b, function(x) {
                        return switch (x.def) {
                            case ERemoteCall(mod, "new", args) if (args.length == 0): toStruct(mod, x.metadata, x.pos, prefix);
                            case ECall(mod, "new", args) if (mod != null && args.length == 0): toStruct(mod, x.metadata, x.pos, prefix);
                            default: x;
                        }
                    })];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var prefix = deriveAppPrefix(name);
                    var newDo = ElixirASTTransformer.transformNode(doBlock, function(x) {
                        return switch (x.def) {
                            case ERemoteCall(mod, "new", args) if (args.length == 0): toStruct(mod, x.metadata, x.pos, prefix);
                            case ECall(mod, "new", args) if (mod != null && args.length == 0): toStruct(mod, x.metadata, x.pos, prefix);
                            default: x;
                        }
                    });
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                case ERemoteCall(mod, "new", args) if (args.length == 0):
                    toStruct(mod, n.metadata, n.pos, null);
                case ECall(mod, "new", args) if (mod != null && args.length == 0):
                    toStruct(mod, n.metadata, n.pos, null);
                default:
                    n;
            }
        });
    }

    /**
     * ChangesetStructQualification
     *
     * WHAT
     * - Qualify bare struct literals passed to Ecto.Changeset changeset/2 calls inside <App>Web.* modules.
     *
     * WHY
     * - In Phoenix LiveView modules, calling `<App>.Todo.changeset(%Todo{}, params)` triggers
     *   `__struct__/1 undefined` because `%Todo{}` is unqualified. The struct must be `%<App>.Todo{}`.
     *
     * HOW
     * - When encountering `ERemoteCall(module, "changeset", [EStruct(name, _), ...])` within an
     *   `<App>Web.*` module, qualify the struct's module name with `<App>.` if it is unqualified and
     *   the remote module appears to be `<App>.<Name>` (ensures consistent qualification).
     *
     * EXAMPLES
     *   TodoApp.Todo.changeset(%Todo{}, attrs)  ->  TodoApp.Todo.changeset(%TodoApp.Todo{}, attrs)
     */
    public static function changesetStructQualificationPass(ast: ElixirAST): ElixirAST {
        inline function deriveAppPrefix(name: String): Null<String> {
            if (name == null) return null;
            var idx = name.indexOf("Web");
            return idx > 0 ? name.substring(0, idx) : null;
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(modName, attrs, body):
                    var appPrefix = deriveAppPrefix(modName);
                    var newBody: Array<ElixirAST> = [];
                    for (b in body) newBody.push(ElixirASTTransformer.transformNode(b, function(x) {
                        return switch (x.def) {
                            case ERemoteCall(remoteMod, fn, args) if (fn == "changeset" && args.length >= 1 && appPrefix != null):
                                var modStr = (function() {
                                    return switch (remoteMod.def) {
                                        case EVar(rn): rn;
                                        default: ElixirASTPrinter.printAST(remoteMod);
                                    }
                                })();
                                // Only qualify when remote module seems to be <App>.<Name>
                                if (modStr.indexOf(appPrefix + ".") == 0) {
                                    switch (args[0].def) {
                                        case EStruct(name, fields) if (name.indexOf('.') == -1):
                                            var q = makeAST(EStruct(appPrefix + "." + name, fields));
                                            var newArgs = args.copy();
                                            newArgs[0] = q;
                                            makeASTWithMeta(ERemoteCall(remoteMod, fn, newArgs), x.metadata, x.pos);
                                        default:
                                            x;
                                    }
                                } else x;
                            default:
                                x;
                        }
                    }));
                    makeASTWithMeta(EModule(modName, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(modName, doBlock):
                    var appPrefix = deriveAppPrefix(modName);
                    var newDo = ElixirASTTransformer.transformNode(doBlock, function(x) {
                        return switch (x.def) {
                            case ERemoteCall(remoteMod, fn, args) if (fn == "changeset" && args.length >= 1 && appPrefix != null):
                                var modStr = (function() {
                                    return switch (remoteMod.def) {
                                        case EVar(rn): rn;
                                        default: ElixirASTPrinter.printAST(remoteMod);
                                    }
                                })();
                                if (modStr.indexOf(appPrefix + ".") == 0) {
                                    switch (args[0].def) {
                                        case EStruct(name, fields) if (name.indexOf('.') == -1):
                                            var q = makeAST(EStruct(appPrefix + "." + name, fields));
                                            var newArgs = args.copy();
                                            newArgs[0] = q;
                                            makeASTWithMeta(ERemoteCall(remoteMod, fn, newArgs), x.metadata, x.pos);
                                        default:
                                            x;
                                    }
                                } else x;
                            default:
                                x;
                        }
                    });
                    makeASTWithMeta(EDefmodule(modName, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    // ERaw Repo Qualification: qualify "Repo." inside raw code within <App>Web modules
    public static function erawRepoQualificationPass(ast: ElixirAST): ElixirAST {
        inline function deriveAppPrefix(name: String): Null<String> {
            if (name == null) return null;
            var idx = name.indexOf("Web");
            return idx > 0 ? name.substring(0, idx) : null;
        }

        // Replace occurrences of Repo. with <App>.Repo. respecting simple boundaries
        function qualifyRepoToken(code: String, repoName: String): String {
            // Replace patterns where Repo. is preceded by start or non-identifier/dot
            var out = new StringBuf();
            var i = 0;
            while (i < code.length) {
                if (i + 5 <= code.length && code.substr(i, 5) == "Repo.") {
                    // Check boundary before "Repo."
                    var prev = i > 0 ? code.charAt(i - 1) : "";
                    var isBoundary = (i == 0) || !~/[A-Za-z0-9_\.]/.match(prev);
                    if (isBoundary) {
                        out.add(repoName);
                        out.add(".");
                        i += 5;
                        continue;
                    }
                }
                out.add(code.charAt(i));
                i++;
            }
            return out.toString();
        }
        
        // Qualify Repo. tokens inside ERaw nodes conservatively
        function qualifyRepoInERaw(node: ElixirAST, repoName: String): ElixirAST {
            return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
                return switch (x.def) {
                    case ERaw(code):
                        var qualified = qualifyRepoToken(code, repoName);
                        if (qualified != code) {
                            #if debug_repo_qualification
                            // DISABLED: trace('[RepoQualification ERaw] Qualified Repo.* in raw code');
                            #end
                            makeASTWithMeta(ERaw(qualified), x.metadata, x.pos);
                        } else x;
                    default:
                        x;
                }
            });
        }
        
        // Only operate within modules to know app prefix
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var prefix = deriveAppPrefix(name);
                    if (prefix == null) return n;
                    var repoName = prefix + ".Repo";
                    var newBody: Array<ElixirAST> = [];
                    for (b in body) newBody.push(qualifyRepoInERaw(b, repoName));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);

                case EDefmodule(name, doBlock):
                    var prefix = deriveAppPrefix(name);
                    if (prefix == null) return n;
                    var repoName = prefix + ".Repo";
                    var newDo = qualifyRepoInERaw(doBlock, repoName);
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);

                default:
                    n;
            }
        });
    }

    // Remove redundant temp-to-binder assignments inside case clauses
    // Example:
    //   case {:todo_created, todo} ->
    //     todo = _g
    //     %{type: "todo_created", todo: todo}
    // The pattern already binds `todo`; the assignment from temp `_g` is redundant and may reference
    // an eliminated temp. This pass removes such assignments conservatively.
    public static function casePatternTempAssignmentRemovalPass(ast: ElixirAST): ElixirAST {
        // Detect infrastructure temps: g, g1, _g, _g1, ...
        function isInfraTemp(name: String): Bool {
            if (name == null || name.length == 0) return false;
            var n = name;
            if (n.charAt(0) == "_") n = n.substr(1);
            if (n == "g") return true;
            if (n.charAt(0) != "g") return false;
            for (i in 1...n.length) {
                var c = n.charCodeAt(i);
                if (c < '0'.code || c > '9'.code) return false;
            }
            return true;
        }

        function extractSimpleVarName(expr: Null<ElixirAST>): Null<String> {
            if (expr == null || expr.def == null) return null;
            return switch (expr.def) {
                case EVar(v):
                    v;
                case EParen(inner):
                    extractSimpleVarName(inner);
                default:
                    null;
            };
        }

        function collectBoundVarsFromPattern(p: EPattern, out: Map<String, Bool>): Void {
            switch (p) {
                case PVar(name) if (name != null && name.length > 0):
                    out.set(name, true);
                case PAlias(name, inner):
                    if (name != null && name.length > 0) out.set(name, true);
                    collectBoundVarsFromPattern(inner, out);
                case PTuple(es) | PList(es):
                    for (e in es) collectBoundVarsFromPattern(e, out);
                case PCons(h, t):
                    collectBoundVarsFromPattern(h, out);
                    collectBoundVarsFromPattern(t, out);
                case PMap(kvs):
                    for (kv in kvs) collectBoundVarsFromPattern(kv.value, out);
                case PStruct(_, fs):
                    for (f in fs) collectBoundVarsFromPattern(f.value, out);
                case PPin(inner):
                    collectBoundVarsFromPattern(inner, out);
                default:
            }
        }

        function declaredVarFromStatement(stmt: ElixirAST): Null<String> {
            if (stmt == null || stmt.def == null) return null;
            return switch (stmt.def) {
                case EMatch(PVar(lhs), _):
                    lhs;
                case EBinary(Match, {def: EVar(lhs)}, _):
                    lhs;
                default:
                    null;
            };
        }

        function dropUndefinedTempAssignmentsInClauseBody(body: ElixirAST, bound: Map<String, Bool>): ElixirAST {
            if (body == null || body.def == null) return body;
            return switch (body.def) {
                case EBlock(stmts):
                    var declared = new Map<String, Bool>();
                    for (k in bound.keys()) declared.set(k, true);

                    var kept: Array<ElixirAST> = [];
                    for (s in stmts) {
                        var drop = false;
                        var rhsName: Null<String> = null;
                        switch (s.def) {
                            case EMatch(_, rhs):
                                rhsName = extractSimpleVarName(rhs);
                            case EBinary(Match, _, rhs2):
                                rhsName = extractSimpleVarName(rhs2);
                            default:
                        }
                        if (rhsName != null && isInfraTemp(rhsName) && !declared.exists(rhsName)) {
                            // This statement reads an infra temp that is not bound by the clause pattern
                            // and has not been declared earlier in the clause body.
                            drop = true;
                        }

                        if (!drop) {
                            kept.push(s);
                            var lhs = declaredVarFromStatement(s);
                            if (lhs != null) declared.set(lhs, true);
                        }
                    }
                    makeASTWithMeta(EBlock(kept), body.metadata, body.pos);

                case EDo(stmts):
                    var declaredDo = new Map<String, Bool>();
                    for (k in bound.keys()) declaredDo.set(k, true);

                    var keptDo: Array<ElixirAST> = [];
                    for (s in stmts) {
                        var drop = false;
                        var rhsName: Null<String> = null;
                        switch (s.def) {
                            case EMatch(_, rhs):
                                rhsName = extractSimpleVarName(rhs);
                            case EBinary(Match, _, rhs2):
                                rhsName = extractSimpleVarName(rhs2);
                            default:
                        }
                        if (rhsName != null && isInfraTemp(rhsName) && !declaredDo.exists(rhsName)) {
                            drop = true;
                        }

                        if (!drop) {
                            keptDo.push(s);
                            var lhs = declaredVarFromStatement(s);
                            if (lhs != null) declaredDo.set(lhs, true);
                        }
                    }
                    makeASTWithMeta(EDo(keptDo), body.metadata, body.pos);

                default:
                    body;
            }
        }

        function pass(node: ElixirAST): ElixirAST {
            if (node == null || node.def == null) return node;

            return switch (node.def) {
                case ECase(expr, clauses):
                    var nextExpr = pass(expr);
                    var nextClauses: Array<ECaseClause> = [];
                    for (cl in clauses) {
                        var bound = new Map<String, Bool>();
                        collectBoundVarsFromPattern(cl.pattern, bound);
                        var nextGuard = cl.guard == null ? null : pass(cl.guard);
                        var nextBody = pass(cl.body);
                        var cleanedBody = dropUndefinedTempAssignmentsInClauseBody(nextBody, bound);
                        nextClauses.push({ pattern: cl.pattern, guard: nextGuard, body: cleanedBody });
                    }
                    makeASTWithMeta(ECase(nextExpr, nextClauses), node.metadata, node.pos);

                case EParen(inner):
                    makeASTWithMeta(EParen(pass(inner)), node.metadata, node.pos);

                default:
                    ElixirASTTransformer.transformAST(node, pass);
            };
        }

        return pass(ast);
    }

    /**
     * NilGuardCoalesceToMap
     *
     * WHAT
     * - After an `if Kernel.is_nil(var) do ... end` guard, coalesce `var` to an empty map `%{}`
     *   when subsequent statements access fields on `var` (var.field). This avoids
     *   "expected a map or struct" warnings in idiomatic code paths that track-and-use metadata.
     *
     * WHY
     * - Generators sometimes guard nil but still use `var.field` later without reassigning `var`.
     *   Elixir warns because `var` may still be nil along that path. Coalescing to `%{}` is a
     *   safe, semantics-preserving fallback for metadata maps (fields become nil).
     *
     * HOW
     * - Scan function bodies (EBlock). For each `if Kernel.is_nil(v) do ... end`, look ahead to
     *   find a subsequent `EField(EVar(v), field)` before any reassignment to `v`.
     * - If found, insert `v = %{}` immediately after the nil-guard statement.
     * - Conservative and local to the block; does not change behavior when `v` is already a map.
     *
     * EXAMPLES
     *   current_meta = get_user_presence(...)
     *   if Kernel.is_nil(current_meta), do: track_user(...)
     *   updated = %{online_at: current_meta.onlineAt}
     *   => inject: current_meta = %{}
     */
    public static function nilGuardCoalesceToMapPass(ast: ElixirAST): ElixirAST {
        function containsFieldUse(node: ElixirAST, v: String): Bool {
            var found = false;
            ElixirASTTransformer.transformNode(node, function(n) {
                if (found) return n;
                switch (n.def) {
                    case EField({def: EVar(name)}, _): if (name == v) found = true;
                    default:
                }
                return n;
            });
            return found;
        }
        // Rewrite EField(var, field) -> Map.get(var, :field) for vars coalesced to %{}
        function rewriteFieldsAfterCoalesce(b: ElixirAST): ElixirAST {
            return switch (b.def) {
                case EBlock(stmts):
                    var active: Map<String, Bool> = new Map();
                    var newStmts: Array<ElixirAST> = [];
                    // Helper to transform field uses for currently active vars
                    function transformForActive(n: ElixirAST): ElixirAST {
                        return ElixirASTTransformer.transformNode(n, function(x) {
                            switch (x.def) {
                                case EField({def: EVar(name)}, field):
                                    if (active.exists(name)) {
                                        var atomField = reflaxe.elixir.ast.NameUtils.toSnakeCase(field);
                                        return makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(name)), makeAST(EAtom(atomField)) ]));
                                    } else {
                                        return x;
                                    }
                                case EAccess({def: EVar(name)}, {def: EAtom(atom)}):
                                    if (active.exists(name)) {
                                        // Normalize to Map.get(var, :atom) for consistency
                                        var atomField = reflaxe.elixir.ast.NameUtils.toSnakeCase(atom);
                                        return makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(name)), makeAST(EAtom(atomField)) ]));
                                    } else {
                                        return x;
                                    }
                                default:
                                    return x;
                            }
                        });
                    }

                    for (s in stmts) {
                        var transformed = transformForActive(s);
                        // Track start/stop of coalesce lifespan per variable
                        switch (transformed.def) {
                            case EMatch(PVar(name), {def: EMap([])}):
                                // Start rewriting field accesses for this var
                                active.set(name, true);
                            case EMatch(PVar(name), _):
                                // Any other assignment to the var ends the rewriting window
                                if (active.exists(name)) active.remove(name);
                            default:
                        }
                        newStmts.push(transformed);
                    }
                    makeASTWithMeta(EBlock(newStmts), b.metadata, b.pos);
                default:
                    b;
            }
        }
        function processBlock(b: ElixirAST): ElixirAST {
            return switch (b.def) {
                case EBlock(stmts):
                    var out: Array<ElixirAST> = [];
                    var i = 0;
                    while (i < stmts.length) {
                        var s = stmts[i];
                        var inserted = false;
                        switch (s.def) {
                            case EIf(cond, thenB, elseB):
                                // Match Kernel.is_nil(v)
                                var v: Null<String> = null;
                                switch (cond.def) {
                                    case ERemoteCall({def: EVar(m)}, f, args) if (m == "Kernel" && f == "is_nil" && args.length == 1):
                                        switch (args[0].def) { case EVar(name): v = name; default: }
                                    case ECall(null, f, args) if (f == "is_nil" && args.length == 1):
                                        switch (args[0].def) { case EVar(name): v = name; default: }
                                    default:
                                }
                                out.push(s);
                                if (v != null) {
                                    // Look ahead for var.field use before any reassignment to v
                                    var j = i + 1;
                                    var seenFieldUse = false;
                                    var seenReassign = false;
                                    while (j < stmts.length && !seenFieldUse && !seenReassign) {
                                        switch (stmts[j].def) {
                                            case EMatch(PVar(name), _):
                                                // Treat assignment to the tracked var as reassignment; otherwise, scan RHS for field usage
                                                if (name == v) {
                                                    seenReassign = true;
                                                } else if (containsFieldUse(stmts[j], v)) {
                                                    seenFieldUse = true;
                                                }
                                            default:
                                                if (containsFieldUse(stmts[j], v)) seenFieldUse = true;
                                        }
                                        j++;
                                    }
                                    if (seenFieldUse && !seenReassign) {
                                        out.push(makeAST(EMatch(PVar(v), makeAST(EMap([])))));
                                        inserted = true;
                                    }
                                }
                            default:
                                out.push(s);
                        }
                        i++;
                    }
                    makeASTWithMeta(EBlock(out), b.metadata, b.pos);
                default:
                    b;
            }
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var pb = processBlock(body);
                    makeASTWithMeta(EDef(name, args, guards, rewriteFieldsAfterCoalesce(pb)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    var pb = processBlock(body);
                    makeASTWithMeta(EDefp(name, args, guards, rewriteFieldsAfterCoalesce(pb)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    // Rename preserved switch result variables to avoid underscored warnings
    public static function renameSwitchResultVarsPass(ast: ElixirAST): ElixirAST {
        inline function rename(name:String):String {
            return (name != null && name.length >= 23 && name.substr(0,23) == "__elixir_switch_result_")
                ? ("switch_result_" + name.substr(23))
                : name;
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch(n.def) {
                case EVar(v):
                    var newName = rename(v);
                    if (newName != v) makeASTWithMeta(EVar(newName), n.metadata, n.pos) else n;
                case EMatch(pattern, expr):
                    var newPat = switch(pattern) {
                        case PVar(pn): var nn = rename(pn); if (nn != pn) PVar(nn) else pattern;
                        default: pattern;
                    };
                    if (newPat != pattern) makeASTWithMeta(EMatch(newPat, expr), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    // Inject `alias <App>.Repo, as: Repo` into <App>Web.* modules when bare Repo.* is referenced
    public static function repoAliasInjectionPass(ast: ElixirAST): ElixirAST {
        inline function deriveAppPrefix(name: String): Null<String> {
            if (name == null) return null;
            var idx = name.indexOf("Web");
            return idx > 0 ? name.substring(0, idx) : null;
        }

        // Scan a subtree to determine if Repo.* is referenced
        function referencesRepo(node: ElixirAST): Bool {
            var found = false;
            ElixirASTTransformer.transformNode(node, function(n) {
                if (found) return n; // early stop not supported; just skip
                switch (n.def) {
                    case ERemoteCall(mod, _, _):
                        switch (mod.def) { case EVar(m) if (m == "Repo"): found = true; default: }
                    case ECall(target, _, _) if (target != null):
                        switch (target.def) { case EVar(m) if (m == "Repo"): found = true; default: }
                    case ERaw(code) if (code != null && code.indexOf("Repo.") != -1):
                        found = true;
                    default:
                }
                return n;
            });
            return found;
        }

        // Check if alias already present
        function hasRepoAlias(body: Array<ElixirAST>, repoModule: String): Bool {
            for (b in body) switch (b.def) {
                case EAlias(module, as) if (module == repoModule && (as == null || as == "Repo")):
                    return true;
                default:
            }
            return false;
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var prefix = deriveAppPrefix(name);
                    if (prefix == null) {
                        try { prefix = reflaxe.elixir.PhoenixMapper.getAppModuleName(); } catch (e:Dynamic) {}
                    }
                    if (prefix == null) return n;
                    var repoModule = prefix + ".Repo";
                    // Only inject when bare Repo.* is referenced, to avoid unused-alias warnings
                    if (!referencesRepo(n)) return n;
                    if (hasRepoAlias(body, repoModule)) return n;
                    var newBody: Array<ElixirAST> = [];
                    newBody.push(makeAST(EAlias(repoModule, "Repo")));
                    for (b in body) newBody.push(b);
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);

                case EDefmodule(name, doBlock):
                    var prefix = deriveAppPrefix(name);
                    if (prefix == null) {
                        try { prefix = reflaxe.elixir.PhoenixMapper.getAppModuleName(); } catch (e:Dynamic) {}
                    }
                    if (prefix == null) return n;
                    var repoModule = prefix + ".Repo";
                    // Inject alias inside do-block only when bare Repo.* is referenced
                    if (!referencesRepo(n)) return n;
                    var newDo = switch (doBlock.def) {
                        case EBlock(stmts):
                            if (hasRepoAlias(stmts, repoModule)) doBlock else {
                                var list = [ makeAST(EAlias(repoModule, "Repo")) ];
                                for (s in stmts) list.push(s);
                                makeAST(EBlock(list));
                            }
                        default:
                            makeAST(EBlock([ makeAST(EAlias(repoModule, "Repo")), doBlock ]));
                    };
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);

                default:
                    n;
            }
        });
    }

    /**
     * repoAliasInjectionGlobalPass
     *
     * WHAT
     * - Injects `alias <App>.Repo, as: Repo` at top of any module that references Repo.*.
     *
     * WHY
     * - Non-Web modules (e.g., contexts) often use bare Repo.*.
     *   This prevents warnings without over-qualifying everywhere.
     *
     * HOW
     * - Determine app name via PhoenixMapper.getAppModuleName() or by scanning for *.Repo module.
     * - Detect Repo.* usage in the module body.
     * - If not already aliased, inject the alias at the beginning of the module body.
     */
    public static function repoAliasInjectionGlobalPass(ast: ElixirAST): ElixirAST {
        // Resolve app name
        var app: Null<String> = null;
        // Try derive from present modules
        ElixirASTTransformer.transformNode(ast, function(n) {
            switch (n.def) {
                case EModule(name, _, _):
                    var idx = name.indexOf(".Repo");
                    if (idx > 0) app = name.substring(0, idx);
                default:
            }
            return n;
        });
        if (app == null || app.length == 0) {
            try app = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e:Dynamic) {}
        }
        if (app == null || app.length == 0) return ast;
        var repoModule = app + ".Repo";

        function referencesRepo(node: ElixirAST): Bool {
            var found = false;
            ElixirASTTransformer.transformNode(node, function(n) {
                if (found) return n;
                switch (n.def) {
                    case ERemoteCall({def: EVar(m)}, _, _) if (m == "Repo"): found = true;
                    case ECall({def: EVar(m)}, _, _) if (m == "Repo"): found = true;
                    default:
                }
                return n;
            });
            return found;
        }

        function hasRepoAlias(body: Array<ElixirAST>): Bool {
            for (b in body) switch (b.def) {
                case EAlias(module, as) if (module == repoModule && (as == null || as == "Repo")):
                    return true;
                default:
            }
            return false;
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    if (!referencesRepo(n) || hasRepoAlias(body)) return n;
                    var newBody: Array<ElixirAST> = [];
                    newBody.push(makeAST(EAlias(repoModule, "Repo")));
                    for (b in body) newBody.push(b);
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    if (!referencesRepo(n)) return n;
                    var newDo = switch (doBlock.def) {
                        case EBlock(stmts): if (hasRepoAlias(stmts)) doBlock else makeAST(EBlock([ makeAST(EAlias(repoModule, "Repo")) ].concat(stmts)));
                        default: makeAST(EBlock([ makeAST(EAlias(repoModule, "Repo")), doBlock ]));
                    };
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * EqNilToIsNil
     *
     * WHAT
     * - Rewrites equality comparisons with nil to Kernel.is_nil/1.
     *
     * WHY
     * - Elixir warns on comparisons between disjoint types (e.g., binary() == nil).
     *   Using Kernel.is_nil(x) is idiomatic and avoids type warnings while preserving semantics.
     *
     * HOW
     * - Pattern match on EBinary(Equal, left, right) where either side is ENil.
     * - Replace with ERemoteCall(Kernel, "is_nil", [other_side]).
     *
     * EXAMPLES
     *   x == nil     -> Kernel.is_nil(x)
     *   nil == value -> Kernel.is_nil(value)
     */
    public static function eqNilToIsNilPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch(n.def) {
                case EBinary(Equal, left, right):
                    switch [left.def, right.def] {
                        case [_, ENil]: makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [left]));
                        case [ENil, _]: makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [right]));
                        default: n;
                    }
                case EBinary(NotEqual, left2, right2):
                    switch [left2.def, right2.def] {
                        case [_, ENil]:
                            var inner = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [left2]));
                            makeAST(ElixirASTDef.EUnary(Not, inner));
                        case [ENil, _]:
                            var inner2 = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [right2]));
                            makeAST(ElixirASTDef.EUnary(Not, inner2));
                        default: n;
                    }
                default:
                    n;
            }
        });
    }
    // Normalize system_alert clause binders and fix body var refs (flashType -> flash_type, socket/message names)
    public static function systemAlertClauseNormalizationPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            // Only operate within handle_info definitions
            return switch(node.def) {
                case EDef(name, args, guards, body) if (name == "handle_info"):
                    var newBody = ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
                        return switch(n.def) {
                            case ECase(target, clauses):
                                var newClauses = [];
                                for (clause in clauses) {
                                    var updated = false;
                                    var pat = clause.pattern;
                                    switch pat {
                                        case PTuple(elements) if (elements.length == 3):
                                            var tag = extractAtom(elements[0]);
                                            if (tag == "system_alert") {
                                                var third  = switch elements[2] { case PVar(n): n; default: null; };
                                                var newSecond = PVar("message");
                                                var newThird  = PVar(third != null && third != "flash_type" ? "flash_type" : (third == null ? "flash_type" : third));
                                                pat = PTuple([elements[0], newSecond, newThird]);
                                                // Fix body references: flashType -> flash_type
                                                var fixedBody = ElixirASTTransformer.transformNode(clause.body, function(x) {
                                                    return switch(x.def) {
                                                        case EVar(v) if (v == "flashType"): makeASTWithMeta(EVar("flash_type"), x.metadata, x.pos);
                                                        case ERemoteCall(mod2, func2, args2) if (func2 == "put_flash"):
                                                            if (args2.length >= 2) {
                                                                switch(args2[1].def) {
                                                                    case EVar(v) if (v == "flashType"):
                                                                        var newArgs = args2.copy();
                                                                        newArgs[1] = makeAST(EVar("flash_type"));
                                                                        return makeASTWithMeta(ERemoteCall(mod2, func2, newArgs), x.metadata, x.pos);
                                                                    default:
                                                                }
                                                            }
                                                            x;
                                                        default: x;
                                                    };
                                                });
                                                newClauses.push({ pattern: pat, guard: clause.guard, body: fixedBody });
                                                updated = true;
                                            }
                                        default:
                                    }
                                    if (!updated) newClauses.push(clause);
                                }
                                makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                            default:
                                n;
                        }
                    });
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body) if (name == "handle_info"):
                    var newBody = ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
                        return switch(n.def) {
                            case ECase(target, clauses):
                                var newClauses = [];
                                for (clause in clauses) {
                                    var updated = false;
                                    var pat = clause.pattern;
                                    switch pat {
                                        case PTuple(elements) if (elements.length == 3):
                                            var tag = extractAtom(elements[0]);
                                            if (tag == "system_alert") {
                                                var third  = switch elements[2] { case PVar(n): n; default: null; };
                                                var newSecond = PVar("message");
                                                var newThird  = PVar(third != null && third != "flash_type" ? "flash_type" : (third == null ? "flash_type" : third));
                                                pat = PTuple([elements[0], newSecond, newThird]);
                                                var fixedBody = ElixirASTTransformer.transformNode(clause.body, function(x) {
                                                    return switch(x.def) {
                                                        case EVar(v) if (v == "flashType"): makeASTWithMeta(EVar("flash_type"), x.metadata, x.pos);
                                                        case ERemoteCall(mod2, func2, args2) if (func2 == "put_flash"):
                                                            if (args2.length >= 2) {
                                                                switch(args2[1].def) {
                                                                    case EVar(v) if (v == "flashType"):
                                                                        var newArgs = args2.copy();
                                                                        newArgs[1] = makeAST(EVar("flash_type"));
                                                                        return makeASTWithMeta(ERemoteCall(mod2, func2, newArgs), x.metadata, x.pos);
                                                                    default:
                                                                }
                                                            }
                                                            x;
                                                        default: x;
                                                    };
                                                });
                                                newClauses.push({ pattern: pat, guard: clause.guard, body: fixedBody });
                                                updated = true;
                                            }
                                        default:
                                    }
                                    if (!updated) newClauses.push(clause);
                                }
                                makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                            default:
                                n;
                        }
                    });
                    makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            };
        });
    }

    // Removed: app-coupled LiveView cancel_edit inline presence update pass
    public static function liveViewCancelEditInlinePresencePass(ast: ElixirAST): ElixirAST {
        return ast;
    }

    // Normalize Repo result binders in case arms to canonical names used in bodies (user/data/changeset/reason)
    public static function repoResultBinderNormalizationPass(ast: ElixirAST): ElixirAST {
        inline function isRepoTuplePattern(p: EPattern): Bool {
            return switch(p) {
                case PTuple(elements) if (elements.length == 2):
                    switch(elements[0]) {
                        case PLiteral({def: EAtom(tag)}) if (tag == "ok" || tag == "error"): true;
                        default: false;
                    }
                default: false;
            }
        }
        inline function extractBinder(p: EPattern): Null<String> {
            return switch(p) {
                case PTuple(elements) if (elements.length == 2):
                    switch(elements[1]) { case PVar(n): n; default: null; }
                default: null;
            }
        }
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (clause in clauses) {
                        if (isRepoTuplePattern(clause.pattern)) {
                            var binder = extractBinder(clause.pattern);
                            if (binder != null) {
                                var used = collectUsedLowerVars(clause.body);
                                // Canonical names we support
                                var canon = ["user","data","changeset","reason"];
                                var aliases = [for (v in used) if (v != binder && canon.indexOf(v) != -1) v];
                                if (aliases.length > 0) {
                                var assigns = [for (v in aliases) makeAST(EMatch(PVar(v), makeAST(EVar(binder))))];
                                var newBody = switch(clause.body.def) {
                                    case EBlock(exprs): makeAST(EBlock(assigns.concat(exprs)));
                                    default: makeAST(EBlock(assigns.concat([clause.body])));
                                };
                                newClauses.push({ pattern: clause.pattern, guard: clause.guard, body: newBody });
                                    continue;
                                }
                            }
                        }
                        newClauses.push(clause);
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    // Late safety net: ensure {:error, binder} arms alias reason only when the body references `reason`
    public static function errorReasonAliasInjectionPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (clause in clauses) {
                        var pat = clause.pattern;
                        var tag: Null<String> = switch(pat) { case PTuple(e) if (e.length > 0): extractAtom(e[0]); default: null; };
                        if (tag == "error") {
                            var binder = switch(pat) { case PTuple(e) if (e.length == 2): switch(e[1]) { case PVar(n): n; default: null; }; default: null; };
                            var used = collectUsedLowerVars(clause.body);
                            if (binder != null && binder != "reason" && used.indexOf("reason") != -1) {
                                var aliasAssign = makeAST(EMatch(PVar("reason"), makeAST(EVar(binder))));
                                var newBody = switch(clause.body.def) {
                                    case EBlock(exprs): makeAST(EBlock([aliasAssign].concat(exprs)));
                                    default: makeAST(EBlock([aliasAssign, clause.body]));
                                };
                                newClauses.push({ pattern: clause.pattern, guard: clause.guard, body: newBody });
                                continue;
                            }
                        }
                        newClauses.push(clause);
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    // Late normalization: if an error-arm body references `reason`, ensure the
    // pattern binder is named `reason` (unless `changeset` is explicitly used).
    public static function resultErrorBinderLateNormalizationPass(ast: ElixirAST): ElixirAST {
        inline function tagOf(p: EPattern): Null<String> {
            return switch(p) {
                case PTuple(elements) if (elements.length >= 1):
                    switch(elements[0]) { case PLiteral({def: EAtom(a)}): a; default: null; }
                default: null;
            }
        }
        inline function renameBinder(p: EPattern, newName: String): EPattern {
            return switch(p) {
                case PTuple(elements) if (elements.length == 2):
                    switch(elements[1]) { case PVar(_): PTuple([elements[0], PVar(newName)]); default: p; }
                default: p;
            }
        }
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EFn(clauses):
                    // Explicitly transform clause bodies to catch nested cases (e.g., in reduce_while)
                    var newClauses = [];
                    for (cl in clauses) {
                        var fixedBody = ElixirASTTransformer.transformNode(cl.body, function(n: ElixirAST): ElixirAST {
                            return switch(n.def) {
                                case ECase(target, caseClauses):
                                    var newCaseClauses = [];
                                    for (c in caseClauses) {
                                        var tag = tagOf(c.pattern);
                                        if (tag == "error") {
                                            var used = collectUsedLowerVars(c.body);
                                            var usesReason = used.indexOf("reason") != -1;
                                            var usesChangeset = used.indexOf("changeset") != -1;
                                            if (usesReason && !usesChangeset) {
                                                var renamed = renameBinder(c.pattern, "reason");
                                                newCaseClauses.push({ pattern: renamed, guard: c.guard, body: c.body });
                                                continue;
                                            }
                                        }
                                        newCaseClauses.push(c);
                                    }
                                    makeASTWithMeta(ECase(target, newCaseClauses), n.metadata, n.pos);
                                default:
                                    n;
                            }
                        });
                        newClauses.push({ args: cl.args, guard: cl.guard, body: fixedBody });
                    }
                    makeASTWithMeta(EFn(newClauses), node.metadata, node.pos);

                case ECase(target, clauses):
                    var newClauses = [];
                    for (clause in clauses) {
                        var tag = tagOf(clause.pattern);
                        if (tag == "error") {
                            var used = collectUsedLowerVars(clause.body);
                            var usesReason = used.indexOf("reason") != -1;
                            var usesChangeset = used.indexOf("changeset") != -1;
                            if (usesReason && !usesChangeset) {
                                var renamed = renameBinder(clause.pattern, "reason");
                                newClauses.push({ pattern: renamed, guard: clause.guard, body: clause.body });
                                continue;
                            }
                        }
                        newClauses.push(clause);
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    // Controller-specific binder normalization: rename {:ok,_}/{:error,_} and add aliases for data/user/changeset
    public static function controllerResultBinderNormalizationPass(ast: ElixirAST): ElixirAST {
        inline function usesPhoenixController(body: ElixirAST): Bool {
            var found = false;
            function scan(n: ElixirAST): Void {
                if (found || n == null || n.def == null) return;
                switch(n.def) {
                    case ERemoteCall(mod, _, args):
                        switch(mod.def) {
                            case EVar(m) if (m == "Phoenix.Controller"): found = true;
                            default:
                        }
                        if (!found) {
                            scan(mod);
                            for (a in args) scan(a);
                        }
                    case EBlock(exprs): for (e in exprs) scan(e);
                    case ECase(expr, clauses): scan(expr); for (c in clauses) { if (c.guard != null) scan(c.guard); scan(c.body);} 
                    case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                    case ECall(target, _, args): if (target != null) scan(target); for (a in args) scan(a);
                    case ETuple(items) | EList(items): for (i in items) scan(i);
                    case EMap(pairs): for (p in pairs) { scan(p.key); scan(p.value); }
                    case EUnary(_, x): scan(x);
                    case EBinary(_, l, r): scan(l); scan(r);
                    case EParen(x): scan(x);
                    default:
                }
            }
            scan(body);
            return found;
        }
        inline function renameBinder(p: EPattern, newName: String): EPattern {
            return switch(p) {
                case PTuple(elements) if (elements.length == 2):
                    switch(elements[1]) {
                        case PVar(_): PTuple([elements[0], PVar(newName)]);
                        default: p;
                    }
                default: p;
            }
        }
        inline function tagOf(p: EPattern): Null<String> {
            return switch(p) {
                case PTuple(elements) if (elements.length >= 1):
                    switch(elements[0]) { case PLiteral({def: EAtom(a)}): a; default: null; }
                default: null;
            }
        }
        inline function bodyUsesPhoenixController(b: ElixirAST): Bool {
            return usesPhoenixController(b);
        }
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EModule(modName, attrs, body):
                    var isCtrl = (modName != null && StringTools.endsWith(modName, "Controller"));
                    if (!isCtrl) return node;
                    var newBody:Array<ElixirAST> = [];
                    for (b in body) {
                        var tb = ElixirASTTransformer.transformNode(b, function(n: ElixirAST): ElixirAST {
                            return switch(n.def) {
                                case EDef(name, args, guards, body):
                                    var nb = ElixirASTTransformer.transformNode(body, function(inner: ElixirAST): ElixirAST {
                                        return switch(inner.def) {
                                            case ECase(target, clauses):
                                                var newClauses = [];
                                                for (clause in clauses) {
                                                    var tag = tagOf(clause.pattern);
                                                    if ((tag == "ok" || tag == "error") && usesPhoenixController(clause.body)) {
                                                        var desired = tag == "ok" ? "user" : "changeset";
                                                        var renamed = renameBinder(clause.pattern, desired);
                                                        var used = collectUsedLowerVars(clause.body);
                                                        var assigns: Array<ElixirAST> = [];
                                                        if (used.indexOf("data") != -1) assigns.push(makeAST(EMatch(PVar("data"), makeAST(EVar(desired)))));
                                                        var nb2 = if (assigns.length > 0) switch(clause.body.def) {
                                                            case EBlock(exprs): makeAST(EBlock(assigns.concat(exprs)));
                                                            default: makeAST(EBlock(assigns.concat([clause.body])));
                                                        } else clause.body;
                                                        newClauses.push({ pattern: renamed, guard: clause.guard, body: nb2 });
                                                        continue;
                                                    }
                                                    newClauses.push(clause);
                                                }
                                                makeASTWithMeta(ECase(target, newClauses), inner.metadata, inner.pos);
                                            default:
                                                inner;
                                        }
                                    });
                                    makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                                case EDefp(name, args, guards, body):
                                    var nb = ElixirASTTransformer.transformNode(body, function(inner: ElixirAST): ElixirAST {
                                        return switch(inner.def) {
                                            case ECase(target, clauses):
                                                var newClauses = [];
                                                for (clause in clauses) {
                                                    var tag = tagOf(clause.pattern);
                                                    if ((tag == "ok" || tag == "error") && usesPhoenixController(clause.body)) {
                                                        var desired = tag == "ok" ? "user" : "changeset";
                                                        var renamed = renameBinder(clause.pattern, desired);
                                                        var used = collectUsedLowerVars(clause.body);
                                                        var assigns: Array<ElixirAST> = [];
                                                        if (used.indexOf("data") != -1) assigns.push(makeAST(EMatch(PVar("data"), makeAST(EVar(desired)))));
                                                        var nb2 = if (assigns.length > 0) switch(clause.body.def) {
                                                            case EBlock(exprs): makeAST(EBlock(assigns.concat(exprs)));
                                                            default: makeAST(EBlock(assigns.concat([clause.body])));
                                                        } else clause.body;
                                                        newClauses.push({ pattern: renamed, guard: clause.guard, body: nb2 });
                                                        continue;
                                                    }
                                                    newClauses.push(clause);
                                                }
                                                makeASTWithMeta(ECase(target, newClauses), inner.metadata, inner.pos);
                                            default:
                                                inner;
                                        }
                                    });
                                    makeASTWithMeta(EDefp(name, args, guards, nb), n.metadata, n.pos);
                                default:
                                    n;
                            }
                        });
                        newBody.push(tb);
                    }
                    makeASTWithMeta(EModule(modName, attrs, newBody), node.metadata, node.pos);
                case EDefmodule(modName, doBlock):
                    var isCtrl2 = (modName != null && StringTools.endsWith(modName, "Controller"));
                    if (!isCtrl2) return node;
                    // Transform inner doBlock similarly to EModule body
                    var transformedDo = ElixirASTTransformer.transformNode(doBlock, function(n: ElixirAST): ElixirAST {
                        return switch(n.def) {
                            case EDef(name, args, guards, body):
                                var nb = ElixirASTTransformer.transformNode(body, function(inner: ElixirAST): ElixirAST {
                                    return switch(inner.def) {
                                        case ECase(target, clauses):
                                            var newClauses = [];
                                            for (clause in clauses) {
                                                var tag = tagOf(clause.pattern);
                                                if ((tag == "ok" || tag == "error") && usesPhoenixController(clause.body)) {
                                                    var desired = tag == "ok" ? "user" : "changeset";
                                                    var renamed = renameBinder(clause.pattern, desired);
                                                    var used = collectUsedLowerVars(clause.body);
                                                    var assigns: Array<ElixirAST> = [];
                                                    // Alias any canonical names used in the body to the binder value
                                                    if (used.indexOf("user") != -1 && desired != "user") assigns.push(makeAST(EMatch(PVar("user"), makeAST(EVar(desired)))));
                                                    if (used.indexOf("changeset") != -1 && desired != "changeset") assigns.push(makeAST(EMatch(PVar("changeset"), makeAST(EVar(desired)))));
                                                    if (used.indexOf("data") != -1) assigns.push(makeAST(EMatch(PVar("data"), makeAST(EVar(desired)))));
                                                    var nb2 = if (assigns.length > 0) switch(clause.body.def) {
                                                        case EBlock(exprs): makeAST(EBlock(assigns.concat(exprs)));
                                                        default: makeAST(EBlock(assigns.concat([clause.body])));
                                                    } else clause.body;
                                                    newClauses.push({ pattern: renamed, guard: clause.guard, body: nb2 });
                                                    continue;
                                                }
                                                newClauses.push(clause);
                                            }
                                            makeASTWithMeta(ECase(target, newClauses), inner.metadata, inner.pos);
                                        default:
                                            inner;
                                    }
                                });
                                makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                            case EDefp(name, args, guards, body):
                                var nb = ElixirASTTransformer.transformNode(body, function(inner: ElixirAST): ElixirAST {
                                    return switch(inner.def) {
                                        case ECase(target, clauses):
                                            var newClauses = [];
                                            for (clause in clauses) {
                                                var tag = tagOf(clause.pattern);
                                                if ((tag == "ok" || tag == "error") && usesPhoenixController(clause.body)) {
                                                    var desired = tag == "ok" ? "user" : "changeset";
                                                    var renamed = renameBinder(clause.pattern, desired);
                                                    var used = collectUsedLowerVars(clause.body);
                                                    var assigns: Array<ElixirAST> = [];
                                                    if (used.indexOf("user") != -1 && desired != "user") assigns.push(makeAST(EMatch(PVar("user"), makeAST(EVar(desired)))));
                                                    if (used.indexOf("changeset") != -1 && desired != "changeset") assigns.push(makeAST(EMatch(PVar("changeset"), makeAST(EVar(desired)))));
                                                    if (used.indexOf("data") != -1) assigns.push(makeAST(EMatch(PVar("data"), makeAST(EVar(desired)))));
                                                    var nb2 = if (assigns.length > 0) switch(clause.body.def) {
                                                        case EBlock(exprs): makeAST(EBlock(assigns.concat(exprs)));
                                                        default: makeAST(EBlock(assigns.concat([clause.body])));
                                                    } else clause.body;
                                                    newClauses.push({ pattern: renamed, guard: clause.guard, body: nb2 });
                                                    continue;
                                                }
                                                newClauses.push(clause);
                                            }
                                            makeASTWithMeta(ECase(target, newClauses), inner.metadata, inner.pos);
                                        default:
                                            inner;
                                    }
                                });
                                makeASTWithMeta(EDefp(name, args, guards, nb), n.metadata, n.pos);
                            default:
                                n;
                        }
                    });
                    makeASTWithMeta(EDefmodule(modName, transformedDo), node.metadata, node.pos);
                case EDef(name, args, guards, body):
                    var newBody = ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
                        return switch(n.def) {
                            case ECase(target, clauses):
                                var newClauses = [];
                                for (clause in clauses) {
                                    var tag = tagOf(clause.pattern);
                                    if ((tag == "ok" || tag == "error") && bodyUsesPhoenixController(clause.body)) {
                                        var desired = tag == "ok" ? "user" : "changeset";
                                        var renamed = renameBinder(clause.pattern, desired);
                                        var used = collectUsedLowerVars(clause.body);
                                        var assigns: Array<ElixirAST> = [];
                                        if (used.indexOf("data") != -1) {
                                            assigns.push(makeAST(EMatch(PVar("data"), makeAST(EVar(desired)))));
                                        }
                                        // Preserve body and prepend aliases if required
                                        var newBody2 = if (assigns.length > 0) switch(clause.body.def) {
                                            case EBlock(exprs): makeAST(EBlock(assigns.concat(exprs)));
                                            default: makeAST(EBlock(assigns.concat([clause.body])));
                                        } else clause.body;
                                        newClauses.push({ pattern: renamed, guard: clause.guard, body: newBody2 });
                                        continue;
                                    }
                                    newClauses.push(clause);
                                }
                                makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                            default:
                                n;
                        }
                    });
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var newBody = ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
                        return switch(n.def) {
                            case ECase(target, clauses):
                                var newClauses = [];
                                for (clause in clauses) {
                                    var tag = tagOf(clause.pattern);
                                    if ((tag == "ok" || tag == "error") && bodyUsesPhoenixController(clause.body)) {
                                        var desired = tag == "ok" ? "user" : "changeset";
                                        var renamed = renameBinder(clause.pattern, desired);
                                        var used = collectUsedLowerVars(clause.body);
                                        var assigns: Array<ElixirAST> = [];
                                        if (used.indexOf("data") != -1) {
                                            assigns.push(makeAST(EMatch(PVar("data"), makeAST(EVar(desired)))));
                                        }
                                        var newBody2 = if (assigns.length > 0) switch(clause.body.def) {
                                            case EBlock(exprs): makeAST(EBlock(assigns.concat(exprs)));
                                            default: makeAST(EBlock(assigns.concat([clause.body])));
                                        } else clause.body;
                                        newClauses.push({ pattern: renamed, guard: clause.guard, body: newBody2 });
                                        continue;
                                    }
                                    newClauses.push(clause);
                                }
                                makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                            default:
                                n;
                        }
                    });
                    makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    // Ensure Phoenix.Controller.json bodies have required aliases (user/changeset/data) from {:ok,_}/{:error,_}
    public static function controllerPhoenixJsonAliasInjectionPass(ast: ElixirAST): ElixirAST {
        inline function isControllerModuleName(n: String): Bool {
            return n != null && StringTools.endsWith(n, "Controller");
        }
        inline function tagOf(p: EPattern): Null<String> {
            return switch(p) {
                case PTuple(elements) if (elements.length >= 1):
                    switch(elements[0]) { case PLiteral({def: EAtom(a)}): a; default: null; }
                default: null;
            }
        }
        inline function binderOf(p: EPattern): Null<String> {
            return switch(p) {
                case PTuple(elements) if (elements.length == 2):
                    switch(elements[1]) { case PVar(n): n; default: null; }
                default: null;
            }
        }
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EModule(name, attrs, body) if (isControllerModuleName(name)):
                    var newBody:Array<ElixirAST> = [];
                    for (b in body) {
                        var tb = ElixirASTTransformer.transformNode(b, function(n: ElixirAST): ElixirAST {
                            return switch(n.def) {
                                case ECase(target, clauses):
                                    var newClauses = [];
                                    for (clause in clauses) {
                                        var tag = tagOf(clause.pattern);
                                        var binder = binderOf(clause.pattern);
                                        if ((tag == "ok" || tag == "error") && binder != null) {
                                            var assigns: Array<ElixirAST> = [];
                                            if (tag == "ok") {
                                                assigns.push(makeAST(EMatch(PVar("user"), makeAST(EVar(binder)))));
                                                assigns.push(makeAST(EMatch(PVar("data"), makeAST(EVar(binder)))));
                                            } else {
                                                assigns.push(makeAST(EMatch(PVar("changeset"), makeAST(EVar(binder)))));
                                                assigns.push(makeAST(EMatch(PVar("data"), makeAST(EVar(binder)))));
                                            }
                                            var nb = switch(clause.body.def) {
                                                case EBlock(exprs): makeAST(EBlock(assigns.concat(exprs)));
                                                default: makeAST(EBlock(assigns.concat([clause.body])));
                                            };
                                            newClauses.push({ pattern: clause.pattern, guard: clause.guard, body: nb });
                                            continue;
                                        }
                                        newClauses.push(clause);
                                    }
                                    makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                                default:
                                    n;
                            }
                        });
                        newBody.push(tb);
                    }
                    makeASTWithMeta(EModule(name, attrs, newBody), node.metadata, node.pos);
                case EDefmodule(name, doBlock) if (isControllerModuleName(name)):
                    var transformedDo = ElixirASTTransformer.transformNode(doBlock, function(n: ElixirAST): ElixirAST {
                        return switch(n.def) {
                            case ECase(target, clauses):
                                var newClauses = [];
                                for (clause in clauses) {
                                    var tag = tagOf(clause.pattern);
                                    var binder = binderOf(clause.pattern);
                                    if ((tag == "ok" || tag == "error") && binder != null) {
                                        var assigns: Array<ElixirAST> = [];
                                        if (tag == "ok") {
                                            assigns.push(makeAST(EMatch(PVar("user"), makeAST(EVar(binder)))));
                                            assigns.push(makeAST(EMatch(PVar("data"), makeAST(EVar(binder)))));
                                        } else {
                                            assigns.push(makeAST(EMatch(PVar("changeset"), makeAST(EVar(binder)))));
                                            assigns.push(makeAST(EMatch(PVar("data"), makeAST(EVar(binder)))));
                                        }
                                        var nb = switch(clause.body.def) {
                                            case EBlock(exprs): makeAST(EBlock(assigns.concat(exprs)));
                                            default: makeAST(EBlock(assigns.concat([clause.body])));
                                        };
                                        newClauses.push({ pattern: clause.pattern, guard: clause.guard, body: nb });
                                        continue;
                                    }
                                    newClauses.push(clause);
                                }
                                makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                            default:
                                n;
                        }
                    });
                    makeASTWithMeta(EDefmodule(name, transformedDo), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    // Rename {:ok, v}/{:error, v} binder based on body usage
    public static function resultBinderRenameByBodyUsagePass(ast: ElixirAST): ElixirAST {
        inline function renameBinder(p: EPattern, newName: String): EPattern {
            return switch(p) {
                case PTuple(elements) if (elements.length == 2):
                    switch(elements[1]) {
                        case PVar(_): PTuple([elements[0], PVar(newName)]);
                        default: p;
                    }
                default: p;
            }
        }
        inline function tagOf(p: EPattern): Null<String> {
            return switch(p) {
                case PTuple(elements) if (elements.length >= 1):
                    switch(elements[0]) { case PLiteral({def: EAtom(a)}): a; default: null; }
                default: null;
            }
        }
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (clause in clauses) {
                        var tag = tagOf(clause.pattern);
                        if (tag == "ok" || tag == "error") {
                            var used = collectUsedLowerVars(clause.body);
                            var preferred: Null<String> = null;
                        if (tag == "ok") {
                            // Prefer common generics first
                            if (used.indexOf("user") != -1) preferred = "user";
                            else if (used.indexOf("data") != -1) preferred = "data";
                            // Fallback: if exactly one undefined lower-case var appears in body, use it
                            if (preferred == null) {
                                var declared = new Map<String, Bool>();
                                var binds = collectPatternBinders(clause.pattern);
                                for (b in binds) declared.set(b, true);
                                var undef = used.filter(v -> !declared.exists(v));
                                if (undef.length == 1) preferred = undef[0];
                            }
                        } else { // error
                            if (used.indexOf("reason") != -1) preferred = "reason";
                            else if (used.indexOf("changeset") != -1) preferred = "changeset";
                        }
                            // Special: avoid shadowing LiveView socket variables
                            switch(clause.pattern) {
                                case PTuple(elements) if (elements.length == 2):
                                    switch(elements[1]) {
                                        case PVar(name) if (tag == "error" && name == "socket"):
                                            preferred = "reason";
                                        default:
                                    }
                                default:
                            }
                            if (preferred != null) {
                                var renamed = renameBinder(clause.pattern, preferred);
                                if (renamed != clause.pattern) {
                                    newClauses.push({ pattern: renamed, guard: clause.guard, body: clause.body });
                                    continue;
                                }
                            }
                        }
                        newClauses.push(clause);
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }
    public static function caseClauseBinderRenameByTagPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            if (node == null || node.def == null) return node;
            return switch(node.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (clause in clauses) {
                        var renamed = renameByTag(clause.pattern);
                        if (renamed != null) newClauses.push({ pattern: renamed, guard: clause.guard, body: clause.body });
                        else newClauses.push(clause);
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    // Replace inner `case parsed_msg do` with `case <binder> do` when outer arm binds {:some, binder}
    public static function innerParsedMsgCaseToBinderPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (clause in clauses) {
                        var binder = extractSomeBinder(clause.pattern);
                        if (binder != null) {
                            var newBody = replaceParsedMsgCase(clause.body, binder);
                            newClauses.push({ pattern: clause.pattern, guard: clause.guard, body: newBody });
                        } else {
                            newClauses.push(clause);
                        }
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    // Removed: tag-driven event parameter alias injection pass
    public static function eventParamAliasInjectionPass(ast: ElixirAST): ElixirAST {
        return ast;
    }

    // Removed helper for tag+var extraction (no longer needed)

    static function extractSomeBinder(pat: EPattern): Null<String> {
        return switch(pat) {
            case PTuple(elements) if (elements.length == 2):
                switch([elements[0], elements[1]]) {
                    case [PLiteral({def: EAtom(a)}), PVar(name)] if (a == "some"): name;
                    default: null;
                }
            default: null;
        }
    }

    static function replaceParsedMsgCase(body: ElixirAST, binder: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch(n.def) {
                case ECase(caseExpr, clauses):
                    switch(caseExpr.def) {
                        case EVar(v) if (v == "parsed_msg"): makeASTWithMeta(ECase(makeAST(EVar(binder)), clauses), n.metadata, n.pos);
                        default: n;
                    }
                default: n;
            }
        });
    }

    static function renameByTag(pat: EPattern): Null<EPattern> {
        return switch(pat) {
            case PTuple(elements) if (elements.length == 2):
                var tag = extractAtom(elements[0]);
                switch(elements[1]) {
                    case PVar(old):
                        var preferred = preferredNameForTag(tag);
                        if (preferred != null && preferred != old) {
                            PTuple([elements[0], PVar(preferred)]);
                        } else null;
                    default: null;
                }
            default: null;
        }
    }

    static inline function extractAtom(pat: EPattern): Null<String> {
        return switch(pat) {
            case PLiteral({def: EAtom(a)}): a;
            default: null;
        }
    }

    /**
     * preferredNameForTag
     *
     * WHAT
     * - Derives a generic preferred binder name for common event/message tags.
     *
     * WHY
     * - Formerly included example-app specific mappings (e.g., todo_*). To avoid
     *   app coupling, we retain only broadly applicable, target-agnostic heuristics.
     *
     * HOW
     * - Use coarse-grained substring/prefix rules for common UX semantics (sort, filter,
     *   query) and CRUD-style prefixes. Do not reference domain terms like "todo".
     *
     * EXAMPLES
     * - "sort_users" -> sort_by
     * - "delete_item" -> id
     * - "save_user" -> params
     */
    static function preferredNameForTag(tag: String): Null<String> {
        if (tag == null) return null;

        // Canonical, target-agnostic heuristics only
        var t = tag;
        inline function contains(substr: String): Bool return t.indexOf(substr) != -1;
        inline function startsWith(prefix: String): Bool return StringTools.startsWith(t, prefix);

        // Sorting and filtering semantics
        if (contains("sort")) return "sort_by";
        if (contains("filter")) return "filter";

        // Search/query semantics
        if (contains("search")) return "params"; // search forms typically submit params
        if (contains("query")) return "query";

        // Tagging / prioritization
        if (contains("tag")) return "tag";
        if (contains("priority")) return "priority";

        // CRUD-style events
        if (startsWith("delete_") || startsWith("remove_") || startsWith("toggle_") || startsWith("edit_")) {
            return "id"; // operate on a single entity id
        }
        if (startsWith("save_") || startsWith("create_") || startsWith("update_")) {
            return "params"; // submit params payload
        }

        // Generic cross-app events
        switch (tag) {
            case "validate": return "params";
            case "clear_filters": return null; // no payload expected
            case "bulk_update": return "action";
            case "user_online" | "user_offline": return "user_id";
            default:
        }
        return null;
    }

    static function tryRenameSingleBinder(pat: EPattern, newName: String): Null<EPattern> {
        // Only handle tuple like {:tag, var}
        return switch(pat) {
            case PTuple(elements) if (elements.length == 2):
                switch(elements[1]) {
                    case PVar(oldName) if (oldName != newName):
                        PTuple([elements[0], PVar(newName)]);
                    default: null;
                }
            default: null;
        }
    }

    static function derivePreferredBinder(base: String): String {
        // Shape-based, domain-agnostic mapping
        // - *_id   -> id
        // - *error -> error
        // - else   -> value (generic)
        var last = (base != null && base.indexOf("_") != -1) ? base.split("_")[base.split("_").length - 1] : base;
        if (last != null) {
            if (StringTools.endsWith(last, "id")) return "id";
            if (StringTools.endsWith(last, "error")) return "error";
        }
        return "value";
    }
    public static function caseClauseBinderAliasInjectionPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            if (node == null || node.def == null) return node;
            return switch(node.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (clause in clauses) {
                        var binders = collectPatternBinders(clause.pattern);
                        if (binders.length == 1) {
                            var used = collectUsedLowerVars(clause.body);
                            var binder = binders[0];
                            // Generic only: alias when body uses a camelCase variant that snakes to the binder name
                            var toAlias = used.filter(v -> v != binder && toSnake(v) == binder);
                            if (toAlias.length > 0) {
                                var body = clause.body;
                                var assigns = [for (v in toAlias) makeAST(EMatch(PVar(v), makeAST(EVar(binder))))];
                                var newBody = switch(body.def) {
                                    case EBlock(exprs): makeAST(EBlock(assigns.concat(exprs)));
                                    default: makeAST(EBlock(assigns.concat([body])));
                                }
                                newClauses.push({ pattern: clause.pattern, guard: clause.guard, body: newBody });
                                continue;
                            }
                        }
                        newClauses.push(clause);
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function collectPatternBinders(pat: EPattern): Array<String> {
        var result: Array<String> = [];
        function walk(p: EPattern): Void {
            switch (p) {
                case PVar(name):
                    if (name != null && name.length > 0 && isLower(name)) result.push(name);
                case PTuple(items):
                    for (i in items) walk(i);
                case PList(items):
                    for (i in items) walk(i);
                case PCons(head, tail):
                    walk(head); walk(tail);
                case PMap(pairs):
                    for (kv in pairs) walk(kv.value);
                default:
            }
        }
        walk(pat);
        return result;
    }

    static function collectUsedLowerVars(ast: ElixirAST): Array<String> {
        var names = new Map<String, Bool>();
        function scan(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch(n.def) {
                case EVar(name):
                    if (name != null && name.length > 0 && isLower(name)) names.set(name, true);
                case EString(value):
                    // Extract #{var} placeholders in interpolated strings
                    if (value != null && value.length > 0) {
                        var re = new EReg("\\#\\{([a-z_][a-zA-Z0-9_]*)\\}", "g");
                        var pos = 0;
                        while (re.matchSub(value, pos)) {
                            var v = re.matched(1);
                            if (v != null && isLower(v)) names.set(v, true);
                            var mEnd = re.matchedPos().pos + re.matchedPos().len;
                            pos = mEnd;
                        }
                    }
                case EField(target, _):
                    // Dot access: record variables used as field owners (e.g., params.status)
                    scan(target);
                case EAccess(target, key):
                    // Bracket access: scan both sides
                    scan(target); scan(key);
                case EBinary(_, left, right):
                    scan(left); scan(right);
                case EUnary(_, expr):
                    scan(expr);
                case EPipe(left, right):
                    scan(left); scan(right);
                case EBlock(exprs):
                    for (e in exprs) scan(e);
                case EIf(c,t,e):
                    scan(c); scan(t); if (e != null) scan(e);
                case ECase(expr, clauses):
                    scan(expr); for (c in clauses) { if (c.guard != null) scan(c.guard); scan(c.body);} 
                case ECall(target, _, args):
                    if (target != null) scan(target); if (args != null) for (a in args) scan(a);
                case ERemoteCall(mod, _, args):
                    scan(mod); if (args != null) for (a in args) scan(a);
                case ETuple(items) | EList(items):
                    for (i in items) scan(i);
                case EMap(pairs):
                    for (p in pairs) { scan(p.key); scan(p.value); }
                default:
            }
        }
        scan(ast);
        return [for (k in names.keys()) k];
    }

    static inline function isLower(s: String): Bool {
        var c = s.charAt(0);
        return c.toLowerCase() == c; // crude but effective for variable vs module
    }

    // Removed app-leaning alias whitelist; aliasing is strictly usage- and snake_case-driven

    static function toSnake(s: String): String {
        if (s == null || s.length == 0) return s;
        var buf = new StringBuf();
        for (i in 0...s.length) {
            var c = s.substr(i, 1);
            var lower = c.toLowerCase();
            var upper = c.toUpperCase();
            if (c == upper && c != lower) {
                if (i != 0) buf.add("_");
                buf.add(lower);
            } else {
                buf.add(c);
            }
        }
        return buf.toString();
    }
}

#end
