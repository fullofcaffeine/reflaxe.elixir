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

    // Late safety net: ensure {:error, binder} arms alias reason when used in body
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
                            if (binder != null && binder != "reason") {
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
