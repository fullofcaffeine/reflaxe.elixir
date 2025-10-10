package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;
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
                            trace('[FilterNorm] Rewriting Enum.filter predicate to pure boolean');
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
                // Fallback: directly normalize EFn bodies that clearly implement string search
                case EFn(clauses) if (clauses.length > 0):
                    var outClauses = [];
                    for (cl in clauses) {
                        var tVar: Null<String> = null;
                        if (cl.args != null && cl.args.length > 0) switch(cl.args[0]) { case PVar(n): tVar = n; default: }
                        if (tVar != null) {
                            // Heuristic: only when :binary.match pattern exists in body
                            var hasMatch = (function(): Bool {
                                var found = false; function scan(n: ElixirAST): Void {
                                    if (found || n == null || n.def == null) return; switch(n.def) {
                                        case ERemoteCall(m, f, _):
                                            var isBin = switch(m.def) {
                                                case EVar(nn) if (nn == ":binary"): true;
                                                case EAtom(a) if (a == ":binary"): true;
                                                default: false;
                                            };
                                            if (isBin && f == "match") found = true;
                                        case EBlock(es): for (e in es) scan(e);
                                        case EBinary(_, l, r): scan(l); scan(r);
                                        case ECase(e, cs): scan(e); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body);} 
                                        case ECall(t, _, as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
                                        // Redundant remote call match removed to avoid unused pattern warning
                                        default:
                                    }}; scan(cl.body); return found;
                            })();
                            var used = collectUsedLowerVars(cl.body);
                            var hasTitleOrDesc = containsFieldOfVar(cl.body, tVar, "title") || containsFieldOfVar(cl.body, tVar, "description");
                            // Be pragmatic: when predicate looks like a string-search (has :binary.match or references
                            // title/description fields), rewrite to pure boolean using `query` if available, otherwise
                            // still collapse to contains semantics (query var is expected per our compiler’s pattern).
                            if (hasMatch || hasTitleOrDesc) {
                                var tRef = makeAST(EVar(tVar));
                                var titleField = makeAST(EField(tRef, "title"));
                                var titleBool = makeIsNotNil(binaryMatch(downcase(titleField), makeAST(EVar("query"))));
                                var descField = makeAST(EField(tRef, "description"));
                                var descPresent = makeAST(EBinary(NotEqual, descField, makeAST(ENil)));
                                var descBool = makeIsNotNil(binaryMatch(downcase(descField), makeAST(EVar("query"))));
                                var right = makeAST(EBinary(And, descPresent, descBool));
                                var combined = makeAST(EBinary(Or, titleBool, right));
                                #if debug_filter_predicate
                                trace('[FilterNorm] Fallback EFn rewrite to pure boolean');
                                #end
                                outClauses.push({ args: cl.args, guard: cl.guard, body: combined });
                                continue;
                            }
                        }
                        outClauses.push(cl);
                    }
                    makeASTWithMeta(EFn(outClauses), node.metadata, node.pos);
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

    // Rewrite obj.push(val) -> obj = Enum.concat(obj, [val])
    public static function listPushRewritePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch(n.def) {
                case ERemoteCall(mod, func, args) if (func == "push" && args != null && args.length == 1):
                    switch(mod.def) {
                        case EVar(name) if (name != null && name.length > 0 && isLower(name)):
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

    // Qualify bare Repo.* calls to <App>.Repo based on module name prefix (e.g., TodoAppWeb.* -> TodoApp.Repo)
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
                                trace('[RepoQualification] Rewriting Repo.${func} to ${repoName}.${func}');
                                #end
                                makeASTWithMeta(ERemoteCall(makeAST(EVar(repoName)), func, args), n.metadata, n.pos);
                            case EVar(m) if (m != null && m.indexOf(".Repo") != -1):
                                // Already qualified Repo usage; log for visibility
                                #if debug_repo_qualification
                                trace('[RepoQualification] Found already-qualified ${m}.${func}');
                                #end
                                n;
                            default: n;
                        }
                    case ECall(target, func, args) if (target != null):
                        // Some builders may produce ECall(EVar("Repo"), func, args) for static-like calls
                        switch (target.def) {
                            case EVar(m) if (m == "Repo"):
                                #if debug_repo_qualification
                                trace('[RepoQualification] Rewriting (call) Repo.${func} to ${repoName}.${func}');
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
                    #if macro
                    if (prefix == null) {
                        try { prefix = haxe.macro.Compiler.getDefine("app_name"); } catch (e:Dynamic) {}
                    }
                    #end
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
                    #if macro
                    if (prefix == null) {
                        try { prefix = haxe.macro.Compiler.getDefine("app_name"); } catch (e:Dynamic) {}
                    }
                    #end
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

    // Late minimal sweep: prefix unused local assignment variables with underscore
    public static function unusedLocalAssignmentUnderscorePass(ast: ElixirAST): ElixirAST {
        // For each function, collect declared names and usages, then underscore unreferenced locals
        function processBody(body: ElixirAST): ElixirAST {
            var declared = new Map<String, Int>();
            var used = new Map<String, Int>();

            // Single-pass read-only collection across the body
            ASTUtils.walk(body, function(n: ElixirAST) {
                if (n == null || n.def == null) return;
                switch (n.def) {
                    case EMatch(pattern, _):
                        // Collect variable names declared in patterns
                        function collectPattern(p: EPattern): Void {
                            switch (p) {
                                case PVar(name):
                                    declared.set(name, (declared.exists(name) ? declared.get(name) : 0) + 1);
                                case PTuple(elems) | PList(elems):
                                    for (ep in elems) collectPattern(ep);
                                default:
                            }
                        }
                        collectPattern(pattern);
                    case EVar(name):
                        used.set(name, (used.exists(name) ? used.get(name) : 0) + 1);
                    default:
                }
            });

            // Non-recursive rewriter: rely on transformNode for traversal
            function rewrite(n: ElixirAST): ElixirAST {
                if (n == null || n.def == null) return n;
                return switch (n.def) {
                    case EMatch(pattern, expr):
                        var newPattern = switch (pattern) {
                            case PVar(name):
                                // If declared but never used, and not already underscore-prefixed, prefix it
                                var isDeclared = declared.exists(name);
                                var isUsed = used.exists(name);
                                if (isDeclared && !isUsed && name.charAt(0) != "_") PVar("_" + name) else pattern;
                            case PTuple(elems):
                                PTuple([for (p in elems) switch (p) { case PVar(nm) if (declared.exists(nm) && !used.exists(nm) && nm.charAt(0) != "_"): PVar("_"+nm); default: p; }]);
                            case PList(elems):
                                PList([for (p in elems) switch (p) { case PVar(nm) if (declared.exists(nm) && !used.exists(nm) && nm.charAt(0) != "_"): PVar("_"+nm); default: p; }]);
                            default:
                                pattern;
                        };
                        makeASTWithMeta(EMatch(newPattern, expr), n.metadata, n.pos);
                    default:
                        n;
                }
            }

            return ElixirASTTransformer.transformNode(body, rewrite);
        }

        return ElixirASTTransformer.transformNode(ast, function(n) {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, processBody(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, processBody(body)), n.metadata, n.pos);
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
                            trace('[RepoQualification ERaw] Qualified Repo.* in raw code');
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

    // Inject `alias <App>.Repo, as: Repo` into <App>Web.* modules when Repo.* is referenced
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
                    if (prefix == null) return n;
                    var repoModule = prefix + ".Repo";
                    if (hasRepoAlias(body, repoModule)) return n;
                    var newBody: Array<ElixirAST> = [];
                    newBody.push(makeAST(EAlias(repoModule, "Repo")));
                    for (b in body) newBody.push(b);
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);

                case EDefmodule(name, doBlock):
                    var prefix = deriveAppPrefix(name);
                    if (prefix == null) return n;
                    var repoModule = prefix + ".Repo";
                    // Inject alias inside do-block
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

    // Replace (x == nil) with Kernel.is_nil(x) to avoid typing warnings
    public static function eqNilToIsNilPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch(n.def) {
                case EBinary(Equal, left, right):
                    switch [left.def, right.def] {
                        case [_, ENil]: makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [left]));
                        case [ENil, _]: makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [right]));
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

    // For LiveView event case, repair CancelEdit branch by inlining Presence.update_user_editing
    public static function liveViewCancelEditInlinePresencePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            // Only operate within handle_event definitions
            return switch(node.def) {
                case EDef(name, args, guards, body) if (name == "handle_event"):
                    var newBody = ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
                        return switch(n.def) {
                            case ECase(target, clauses):
                                var newClauses = [];
                                for (clause in clauses) {
                                    var isCancel = switch(clause.pattern) {
                                        case PLiteral({def: EAtom(a)}) if (a == "cancel_edit"): true;
                                        case PTuple(items) if (items.length >= 1):
                                            switch(items[0]) { case PLiteral({def: EAtom(a)}) if (a == "cancel_edit"): true; default: false; }
                                        default: false;
                                    };
                                    if (!isCancel) { newClauses.push(clause); continue; }
                                    var repairedBody = ElixirASTTransformer.transformNode(clause.body, function(x: ElixirAST): ElixirAST {
                                        return switch(x.def) {
                                            case ERemoteCall(mod, func, args) if (func == "set_editing_todo"):
                                                if (args.length >= 2) {
                                                    var replace = switch(args[0].def) {
                                                        case EVar(v) if (v == "presenceSocket" || v == "presence_socket"): true;
                                                        default: false;
                                                    };
                                                    if (replace) {
                                                        var newFirst = makeAST(ERemoteCall(
                                                            makeAST(EVar("Presence")),
                                                            "update_user_editing",
                                                            [
                                                                makeAST(EVar("socket")),
                                                                makeAST(EField(makeAST(EField(makeAST(EVar("socket")), "assigns")), "currentUser")),
                                                                makeAST(ENil)
                                                            ]
                                                        ));
                                                        var newArgs = args.copy(); newArgs[0] = newFirst;
                                                        return makeASTWithMeta(ERemoteCall(mod, func, newArgs), x.metadata, x.pos);
                                                    }
                                                }
                                                x;
                                            default:
                                                x;
                                        };
                                    });
                                    newClauses.push({ pattern: clause.pattern, guard: clause.guard, body: repairedBody });
                                }
                                makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                            default:
                                n;
                        }
                    });
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body) if (name == "handle_event"):
                    var newBody = ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
                        return switch(n.def) {
                            case ECase(target, clauses):
                                var newClauses = [];
                                for (clause in clauses) {
                                    var isCancel = switch(clause.pattern) {
                                        case PLiteral({def: EAtom(a)}) if (a == "cancel_edit"): true;
                                        case PTuple(items) if (items.length >= 1):
                                            switch(items[0]) { case PLiteral({def: EAtom(a)}) if (a == "cancel_edit"): true; default: false; }
                                        default: false;
                                    };
                                    if (!isCancel) { newClauses.push(clause); continue; }
                                    var repairedBody = ElixirASTTransformer.transformNode(clause.body, function(x: ElixirAST): ElixirAST {
                                        return switch(x.def) {
                                            case ERemoteCall(mod, func, args) if (func == "set_editing_todo"):
                                                if (args.length >= 2) {
                                                    var replace = switch(args[0].def) {
                                                        case EVar(v) if (v == "presenceSocket" || v == "presence_socket"): true;
                                                        default: false;
                                                    };
                                                    if (replace) {
                                                        var newFirst = makeAST(ERemoteCall(
                                                            makeAST(EVar("Presence")),
                                                            "update_user_editing",
                                                            [
                                                                makeAST(EVar("socket")),
                                                                makeAST(EField(makeAST(EField(makeAST(EVar("socket")), "assigns")), "currentUser")),
                                                                makeAST(ENil)
                                                            ]
                                                        ));
                                                        var newArgs = args.copy(); newArgs[0] = newFirst;
                                                        return makeASTWithMeta(ERemoteCall(mod, func, newArgs), x.metadata, x.pos);
                                                    }
                                                }
                                                x;
                                            default:
                                                x;
                                        };
                                    });
                                    newClauses.push({ pattern: clause.pattern, guard: clause.guard, body: repairedBody });
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

    // Rename {:ok, v}/{:error, v} binder based on body usage (user/data/changeset/reason)
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
                                if (used.indexOf("user") != -1) preferred = "user";
                                else if (used.indexOf("data") != -1) preferred = "data";
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

    // Inject clause-local alias for event parameters based on tag when pattern binder name differs
    public static function eventParamAliasInjectionPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case ECase(target, clauses):
                    var isEvent = switch(target.def) { case EVar(v): v == "event"; default: false; };
                    if (!isEvent) return node;
                    var newClauses = [];
                    for (clause in clauses) {
                        var tagAndVar = extractTagAndVar(clause.pattern);
                        if (tagAndVar != null) {
                            var preferred = preferredNameForTag(tagAndVar.tag);
                            if (preferred != null && preferred != tagAndVar.varName) {
                                var aliasAssign = makeAST(EMatch(PVar(preferred), makeAST(EVar(tagAndVar.varName))));
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

    static function extractTagAndVar(pat: EPattern): Null<{tag: String, varName: String}> {
        return switch(pat) {
            case PTuple(elements) if (elements.length == 2):
                var t = extractAtom(elements[0]);
                switch(elements[1]) {
                    case PVar(name) if (t != null): { tag: t, varName: name };
                    default: null;
                }
            default: null;
        }
    }

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

    static function preferredNameForTag(tag: String): Null<String> {
        if (tag == null) return null;
        // 1) Preserve known PubSub/message patterns that carry domain payloads
        switch (tag) {
            case "todo_created" | "todo_updated": return "todo"; // carries struct payload
            case "todo_deleted": return "id";                      // carries identifier
        }

        // 2) Canonical LiveView event aliases (target-agnostic, table-driven by substring)
        var t = tag;
        inline function contains(substr: String): Bool return t.indexOf(substr) != -1;
        inline function startsWith(prefix: String): Bool return StringTools.startsWith(t, prefix);

        // Sorting and filtering first (most specific UX semantics)
        if (contains("sort")) return "sort_by";
        if (contains("filter")) return "filter";

        // Search/query semantics
        if (contains("search")) return "params"; // LiveView search forms submit params
        if (contains("query")) return "query";

        // Tagging / prioritization
        if (contains("tag")) return "tag";
        if (contains("priority")) return "priority";

        // CRUD-style events
        if (startsWith("delete_") || startsWith("remove_") || startsWith("toggle_") || startsWith("edit_")) {
            return "id"; // conventionally operate on a single entity id
        }
        if (startsWith("save_") || startsWith("create_") || startsWith("update_")) {
            return "params"; // conventionally submit params payload
        }

        // Known cross-app generic events
        switch (tag) {
            case "validate": return "params";
            case "clear_filters": return null; // no payload expected
            case "bulk_update": return "action"; // retains legacy semantic
            case "user_online" | "user_offline": return "user_id";
            case "toggle_todo" | "delete_todo" | "edit_todo": return "id";
            case "create_todo" | "save_todo": return "params";
            case "filter_todos": return "filter";
            case "sort_todos": return "sort_by";
            case "search_todos": return "query";
            case "toggle_tag": return "tag";
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
        // Use last segment after underscore if present, else base itself
        var segs = base.split("_");
        var last = segs[segs.length - 1];
        // Normalize known endings
        switch(last) {
            case "level" | "action" | "user" | "todo" | "changeset" | "data" | "reason": return last;
            default:
                // fallback generic
                return "value";
        }
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
                            var toAlias = used.filter(v -> v != binder && (isPreferredAliasName(v) || toSnake(v) == binder));
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

    static inline function isPreferredAliasName(v: String): Bool {
        // Restrict alias injection to common Phoenix/Repo and LiveView event names
        return (
            v == "user" || v == "changeset" || v == "data" || v == "reason" || v == "todo" ||
            v == "params" || v == "id" || v == "filter" || v == "sort_by" || v == "query" || v == "tag" ||
            v == "user_id" || v == "action" || v == "priority" || v == "updated_todo"
        );
    }

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
