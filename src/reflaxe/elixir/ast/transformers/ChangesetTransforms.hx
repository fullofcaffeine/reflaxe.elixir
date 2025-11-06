package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * ChangesetTransforms
 *
 * WHAT
 * - Normalizes Ecto.Changeset pipelines to use a single local binding for the
 *   active changeset (canonicalized as the binder of the first `change/2` call,
 *   with a safe fallback to `cs` when no binder is found) and fixes
 *   inconsistent temporary names (`this1`/`this2`, underscored `_opts`) that break
 *   compilation.
 *
 * WHY
 * - Loop/assignment desugarings sometimes emit nested matches and inconsistent
 *   temporary identifiers, leading to undefined variables in validate_* calls.
 *   This pass restores a clean, idiomatic pipeline.
 *
 * HOW
 * - Detect the local binder used for `Ecto.Changeset.change(...)` on the left-hand
 *   side and treat that as the canonical changeset variable (e.g., `_this1`, `changeset`).
 *   If none is found, fallback to `cs`.
 * - For `Ecto.Changeset.validate_required/validate_length`, force the first argument
 *   to use the canonical changeset variable; ensure normalization works inside cond/if bodies.
 * - Rename `_opts = %{...}` to `opts = %{...}` to match downstream field accesses.
 * - Canonicalize any references to `thisN`/`_thisN` to `cs` within the function.
 *
 * EXAMPLES
 * Haxe:
 *   // cs = change(todo, params) -> cs = validate_required(cs, ["title"])
 *   // then conditionally validate_length(cs, opts)
 *
 * Elixir before:
 *   _cs = _this1 = Ecto.Changeset.change(todo, params)
 *   _this1 = _this2 = Ecto.Changeset.validate_required(cs, ...)
 *   _opts = %{min: 3, max: 200}
 *   cond do
 *     opts.min != nil -> Ecto.Changeset.validate_length(this2, :title, [min: opts.min])
 *     :true -> :nil
 *   end
 *
 * Elixir after:
 *   changeset = Ecto.Changeset.change(todo, params)
 *   changeset = Ecto.Changeset.validate_required(changeset, ...)
 *   opts = %{min: 3, max: 200}
 *   cond do
 *     opts.min != nil -> Ecto.Changeset.validate_length(changeset, :title, [min: opts.min])
 *     true -> nil
 *   end
 */
class ChangesetTransforms {
    static var debugCount:Int = 0;
    public static function normalizeChangesetPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                // Module-level fallback: if Ecto.Changeset is used/imported in the module,
                // perform conservative reference canonicalization to avoid undefined thisN/cs
                case EModule(modName, attrs, body):
                    var usesChangeset = false;
                    for (b in body) switch (b.def) {
                        case EImport(m, _, _) if (m == "Ecto.Changeset"): usesChangeset = true;
                        default:
                    }
                    if (!usesChangeset) {
                        // Also detect direct usage by scanning remote calls
                        function scan(x: ElixirAST): Void {
                            if (usesChangeset || x == null || x.def == null) return;
                            switch (x.def) {
                                case ERemoteCall(m, _, as):
                                    switch (m.def) { case EVar(n) if (n == "Ecto.Changeset"): usesChangeset = true; default: }
                                    // traverse target and args
                                    scan(m); if (as != null) for (a in as) scan(a);
                                case EBlock(es): for (e in es) scan(e);
                                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                                case ECase(e, cs): scan(e); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                                case EBinary(_, l, r): scan(l); scan(r);
                                case EMatch(_, rhs): scan(rhs);
                                case ECall(t,_,as2): if (t != null) scan(t); if (as2 != null) for (a in as2) scan(a);
                                default:
                            }
                        }
                        for (b in body) scan(b);
                    }
                    if (!usesChangeset) node else {
                        // Collect declared vars across module to choose a binder
                        var declared = new Map<String,Bool>();
                        reflaxe.elixir.ast.ASTUtils.walk(makeAST(EBlock(body)), function(n) {
                            switch (n.def) {
                                case EMatch(PVar(v), _): declared.set(v, true);
                                case EBinary(Match, left, _):
                                    // collect nested lhs vars
                                    function collect(lhs: ElixirAST) {
                                        switch (lhs.def) {
                                            case EVar(v): declared.set(v, true);
                                            case EBinary(Match, l2, r2): collect(l2); collect(r2);
                                            default:
                                        }
                                    }
                                    collect(left);
                                default:
                            }
                        });
                        var binder = if (declared.exists("cs")) "cs" else if (declared.exists("_this2")) "_this2" else if (declared.exists("_this1")) "_this1" else if (declared.exists("this2")) "this2" else if (declared.exists("this1")) "this1" else "cs";
                        // Apply canonicalization of refs at module scope conservatively
                        function tx(n: ElixirAST): ElixirAST {
                            return switch (n.def) {
                                // Canonicalize references first
                                case EVar(v) if (isThisLike(v)):
                                    makeASTWithMeta(EVar(binder), n.metadata, n.pos);
                                case EVar(v) if (v == "cs" && binder != "cs"):
                                    makeASTWithMeta(EVar(binder), n.metadata, n.pos);
                                // Also run function-body normalization within module scope
                                case EDef(name, params, guards, body):
                                    var newB = normalizeBody(body);
                                    makeASTWithMeta(EDef(name, params, guards, newB), n.metadata, n.pos);
                                case EDefp(name, params, guards, body):
                                    var newBp = normalizeBody(body);
                                    makeASTWithMeta(EDefp(name, params, guards, newBp), n.metadata, n.pos);
                                default:
                                    n;
                            }
                        }
                        var newBody = [for (b in body) ElixirASTTransformer.transformNode(b, tx)];
                        makeASTWithMeta(EModule(modName, attrs, newBody), node.metadata, node.pos);
                    }
                // (handled in function body normalization)

                // Within defmodule blocks, apply the same normalization as EModule
                case EDefmodule(modName, doBlock):
                    var usesChangeset2 = false;
                    // Detect usage within doBlock
                    function scanDefBlock(x: ElixirAST): Void {
                        if (usesChangeset2 || x == null || x.def == null) return;
                        switch (x.def) {
                            case EImport(m, _, _) if (m == "Ecto.Changeset"): usesChangeset2 = true;
                            case ERemoteCall(m, _, as):
                                switch (m.def) { case EVar(n) if (n == "Ecto.Changeset"): usesChangeset2 = true; default: }
                                scanDefBlock(m); if (as != null) for (a in as) scanDefBlock(a);
                            case EBlock(es): for (e in es) scanDefBlock(e);
                            case EIf(c,t,e): scanDefBlock(c); scanDefBlock(t); if (e != null) scanDefBlock(e);
                            case ECase(e, cs): scanDefBlock(e); for (c in cs) { if (c.guard != null) scanDefBlock(c.guard); scanDefBlock(c.body); }
                            case EBinary(_, l, r): scanDefBlock(l); scanDefBlock(r);
                            case EMatch(_, rhs): scanDefBlock(rhs);
                            case ECall(t,_,as2): if (t != null) scanDefBlock(t); if (as2 != null) for (a in as2) scanDefBlock(a);
                            default:
                        }
                    }
                    scanDefBlock(doBlock);
                    if (!usesChangeset2) node else {
                        var declaredVars = new Map<String,Bool>();
                        reflaxe.elixir.ast.ASTUtils.walk(doBlock, function(n) {
                            switch (n.def) {
                                case EMatch(PVar(v), _): declaredVars.set(v, true);
                                case EBinary(Match, left, _):
                                    function collectVarsFromLhs(lhs: ElixirAST) {
                                        switch (lhs.def) {
                                            case EVar(v): declaredVars.set(v, true);
                                            case EBinary(Match, l2, r2): collectVarsFromLhs(l2); collectVarsFromLhs(r2);
                                            default:
                                        }
                                    }
                                    collectVarsFromLhs(left);
                                default:
                            }
                        });
                        var changesetBinder = if (declaredVars.exists("cs")) "cs" else if (declaredVars.exists("_this2")) "_this2" else if (declaredVars.exists("_this1")) "_this1" else if (declaredVars.exists("this2")) "this2" else if (declaredVars.exists("this1")) "this1" else "cs";
                        function rewriteThisRefsToChangesetBinder(n: ElixirAST): ElixirAST {
                            return switch (n.def) {
                                case EVar(v) if (isThisLike(v)):
                                    makeASTWithMeta(EVar(changesetBinder), n.metadata, n.pos);
                                case EVar(v) if (v == "cs" && changesetBinder != "cs"):
                                    makeASTWithMeta(EVar(changesetBinder), n.metadata, n.pos);
                                case EDef(name, params, guards, body):
                                    var newB = normalizeBody(body);
                                    makeASTWithMeta(EDef(name, params, guards, newB), n.metadata, n.pos);
                                case EDefp(name, params, guards, body):
                                    var newBp = normalizeBody(body);
                                    makeASTWithMeta(EDefp(name, params, guards, newBp), n.metadata, n.pos);
                                default:
                                    n;
                            }
                        }
                        var newDo = ElixirASTTransformer.transformNode(doBlock, rewriteThisRefsToChangesetBinder);
                        makeASTWithMeta(EDefmodule(modName, newDo), node.metadata, node.pos);
                    }

                // Within function bodies, canonicalize `thisN`/`_thisN` and `_opts` declarations
                case EDef(name, params, guards, body):
                    var newBody = normalizeBody(body);
                    makeASTWithMeta(EDef(name, params, guards, newBody), node.metadata, node.pos);
                case EDefp(name, params, guards, body):
                    var newBody = normalizeBody(body);
                    makeASTWithMeta(EDefp(name, params, guards, newBody), node.metadata, node.pos);

                default:
                    node;
            }
        });
    }

    /**
     * normalizeValidateFieldAtomPass
     *
     * WHAT
     * - Rewrites the field argument of Ecto.Changeset.validate_* calls from
     *   String.to_atom("field") or "field" to the literal atom :field when safe.
     *
     * WHY
     * - Using runtime conversion hides intent and triggers typing warnings in strict
     *   environments. Literal atoms are idiomatic and safer.
     *
     * HOW
     * - Traverse the AST and match ERemoteCall(Ecto.Changeset, validate_*), replace
     *   second argument if it is String.to_atom(EString) or EString with EAtom.
     */
    public static function normalizeValidateFieldAtomPass(ast: ElixirAST): ElixirAST {
        function normalizeFieldArg(arg: ElixirAST): ElixirAST {
            return switch (arg.def) {
                // String.to_atom("field") -> :field
                case ERemoteCall({def: EVar(m)}, f, [fld]) if (m == "String" && f == "to_atom"):
                    switch (fld.def) {
                        case EString(s): makeAST(EAtom(s));
                        default: arg;
                    }
                // String.to_existing_atom("field") -> :field
                case ERemoteCall({def: EVar(m)}, f, [fld]) if (m == "String" && f == "to_existing_atom"):
                    switch (fld.def) {
                        case EString(s): makeAST(EAtom(s));
                        default: arg;
                    }
                // String.to_existing_atom(Macro.underscore("FieldName")) -> :field_name (for static strings)
                case ERemoteCall({def: EVar(m1)}, f1, [{def: ECall(null, f2, [inner])}]) if (m1 == "String" && (f1 == "to_existing_atom" || f1 == "to_atom") && f2 == "Macro.underscore"):
                    switch (inner.def) {
                        case EString(s): makeAST(EAtom(s));
                        default: arg;
                    }
                // Plain string literal -> atom
                case EString(s): makeAST(EAtom(s));
                default: arg;
            }
        }
        function normalizeFieldsList(arg: ElixirAST): ElixirAST {
            return switch (arg.def) {
                case EList(elements):
                    var out = [];
                    for (e in elements) {
                        switch (e.def) {
                            case EString(s): out.push(makeAST(EAtom(s)));
                            case EAtom(_): out.push(e);
                            default: out.push(e);
                        }
                    }
                    makeAST(EList(out));
                case ERemoteCall({def: EVar(m)}, f, [listExpr, funExpr]) if (m == "Enum" && f == "map"):
                    // Detect &String.to_atom/1 or &String.to_existing_atom/1
                    var isStringToAtomCapture = false;
                    switch (funExpr.def) {
                        case ECapture(inner, _):
                            switch (inner.def) {
                                case ERemoteCall({def: EVar(m2)}, f2, _):
                                    if (m2 == "String" && (f2 == "to_atom" || f2 == "to_existing_atom")) isStringToAtomCapture = true;
                                case EField({def: EVar(cls)}, meth) if (cls == "String" && (meth == "to_atom" || meth == "to_existing_atom")):
                                    isStringToAtomCapture = true;
                                default:
                            }
                        default:
                    }
                    if (isStringToAtomCapture) {
                        switch (listExpr.def) {
                            case EList(elements2):
                                var out2 = [];
                                for (e2 in elements2) {
                                    switch (e2.def) {
                                        case EString(s2): out2.push(makeAST(EAtom(s2)));
                                        case EAtom(_): out2.push(e2);
                                        default: out2.push(e2);
                                    }
                                }
                                makeAST(EList(out2));
                            default:
                                arg;
                        }
                    } else arg;
                default: arg;
            }
        }
        // Replace opts.field ==/!= nil with Kernel.is_nil(Map.get(opts,:field)) in conditions (applies inside nested boolean/cond trees)
        function rewriteNilComparisons(n: ElixirAST): ElixirAST {
            inline function isOptsField(e: ElixirAST): Null<String> {
                return switch (e.def) {
                    case EField({def: EVar(v)}, fld) if (v == "opts"): fld;
                    case EAccess({def: EVar(v)}, key) if (v == "opts"):
                        switch (key.def) { case EAtom(a): a; default: null; }
                    default: null;
                };
            }
            return switch (n.def) {
                case EBinary(Equal, l, r):
                    switch [isOptsField(l), r.def, isOptsField(r), l.def] {
                        case [f, ENil, _, _] if (f != null):
                            makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [ makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(f))])) ]));
                        case [_, _, f2, ENil] if (f2 != null):
                            makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [ makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(f2))])) ]));
                        default: n;
                    }
                case EBinary(NotEqual, l2, r2):
                    switch [isOptsField(l2), r2.def, isOptsField(r2), l2.def] {
                        case [f, ENil, _, _] if (f != null):
                            var inner = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [ makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(f))])) ]));
                            makeAST(ElixirASTDef.EUnary(Not, inner));
                        case [_, _, f2, ENil] if (f2 != null):
                            var inner2 = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [ makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(f2))])) ]));
                            makeAST(ElixirASTDef.EUnary(Not, inner2));
                        default: n;
                    }
                default: n;
            }
        }
        function rewrite(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, fn, args) if (isChangeset(mod) && (fn == "validate_required" || fn == "validate_length")):
                    var a = args.copy();
                    if (a.length >= 2) {
                        if (fn == "validate_required") {
                            a[1] = normalizeFieldsList(a[1]);
                        } else {
                            a[1] = normalizeFieldArg(a[1]);
                        }
                    }
                    makeASTWithMeta(ERemoteCall(mod, fn, a), n.metadata, n.pos);
                default:
                    n;
            }
        }
        return ElixirASTTransformer.transformNode(ast, rewrite);
    }

    static function normalizeBody(body: ElixirAST): ElixirAST {
        #if debug_changeset_transforms
        Sys.println('[ChangesetTransforms] normalizeBody invoked');
        #end
        // Early exit: preserve pure expression bodies that directly return a Changeset pipeline
        // (no assignments/blocks), to avoid introducing or expecting a `cs` binder.
        var isSimpleExpr = switch (body.def) {
            case EBlock(_)|EDo(_)|EIf(_,_,_)|ECase(_,_)|ECond(_): false;
            case EBinary(Match, _, _)|EMatch(_, _): false;
            default: true;
        };
        if (isSimpleExpr && containsChangesetCallsDetect(body)) {
            return body; // keep direct returns intact
        }
        // Handle single-expression block that returns a pure changeset expression
        switch (body.def) {
            case EBlock(stmts) if (stmts.length == 1):
                var only = stmts[0];
                var onlySimple = switch (only.def) {
                    case EBlock(_)|EDo(_)|EIf(_,_,_)|ECase(_,_)|ECond(_)|EBinary(Match,_,_)|EMatch(_, _): false;
                    default: true;
                };
                if (onlySimple && containsChangesetCallsDetect(only)) return only;
            default:
        }
        // Ensure an initial `cs` binder exists for the changeset-producing expression
        function lhsAllWildcards(lhs: ElixirAST): Bool {
            return switch (lhs.def) {
                case EVar(v) if (v == "_" || (v != null && v.length > 1 && v.charAt(0) == '_')): true;
                case EBinary(Match, l2, r2): lhsAllWildcards(l2) || lhsAllWildcards(r2);
                default: false;
            }
        }
        function patternAllWildcards(p: EPattern): Bool {
            return switch (p) {
                case PVar(n) if (n == "_" || (n != null && n.length > 1 && n.charAt(0) == '_')): true;
                case PTuple(es): var any = false; for (e in es) any = any || patternAllWildcards(e); any;
                case PList(es): var any2 = false; for (e in es) any2 = any2 || patternAllWildcards(e); any2;
                case PCons(h, t): patternAllWildcards(h) || patternAllWildcards(t);
                default: false;
            }
        }
        function peelInnermost(n: ElixirAST): ElixirAST {
            var cur = n;
            while (cur != null && cur.def != null) {
                switch (cur.def) {
                    case EBinary(Match, left, inner) if (lhsAllWildcards(left)):
                        cur = inner;
                    case EMatch(pat, inner2) if (patternAllWildcards(pat)):
                        cur = inner2;
                    default:
                        return cur;
                }
            }
            return cur == null ? n : cur;
        }
        function containsCastCall(e: ElixirAST): Bool {
            return switch (e.def) {
                case ERemoteCall(mod, fn, _) if (isChangeset(mod) && fn == "cast"): true;
                case ERaw(code) if (code != null && code.indexOf("Ecto.Changeset.cast(") != -1): true;
                case EMatch(_, inner): containsCastCall(inner);
                case EBinary(Match, _, right): containsCastCall(right);
                case EParen(inner): containsCastCall(inner);
                default: false;
            }
        }
        function ensureInitialBinder(b: ElixirAST): ElixirAST {
            return switch (b.def) {
                case EBlock(stmts) if (stmts.length > 0):
                    var first = stmts[0];
                    var rhs: Null<ElixirAST> = null;
                    switch (first.def) {
                        case EBinary(Match, left, r) if (lhsAllWildcards(left) && containsCastCall(r)):
                            rhs = peelInnermost(r);
                        case EMatch(pat, r2) if (patternAllWildcards(pat) && containsCastCall(r2)):
                            rhs = r2;
                        default:
                    }
                    if (rhs != null) {
                        var csAssign = makeASTWithMeta(EBinary(Match, makeAST(EVar("cs")), rhs), first.metadata, first.pos);
                        var newStmts = [csAssign];
                        for (i in 1...stmts.length) newStmts.push(stmts[i]);
                        makeASTWithMeta(EBlock(newStmts), b.metadata, b.pos);
                    } else b;
                default:
                    b;
            }
        }
        // Promote any wildcard assignment to cast(...) into cs = ...
        function rewriteCastAssign(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBinary(Match, left, rhs) if (lhsAllWildcards(left) && containsCastCall(rhs)):
                    makeASTWithMeta(EBinary(Match, makeAST(EVar("cs")), peelInnermost(rhs)), n.metadata, n.pos);
                case EMatch(pat, rhs2) if (patternAllWildcards(pat) && containsCastCall(rhs2)):
                    makeASTWithMeta(EBinary(Match, makeAST(EVar("cs")), rhs2), n.metadata, n.pos);
                case ERaw(code) if (code != null && code.indexOf("Ecto.Changeset.cast(") != -1):
                    // Promote raw cast expression used as a standalone statement
                    makeASTWithMeta(EBinary(Match, makeAST(EVar("cs")), n), n.metadata, n.pos);
                default:
                    n;
            }
        }
        body = ElixirASTTransformer.transformNode(ensureInitialBinder(body), rewriteCastAssign);
        // Determine canonical changeset variable name
        var csVar = findChangesetVar(body);
        if (csVar == null) {
            // Fallback: enforce canonical binder name "cs" for changeset pipelines
            csVar = "cs";
        }
        // 1) Rename `_opts = %{} | [..]` to `opts = ...`
        function renameOptsDecl(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EMatch(PVar(v), expr) if (v == "_opts" && (isMap(expr) || isKeywordList(expr))):
                    makeASTWithMeta(EMatch(PVar("opts"), expr), n.metadata, n.pos);
                default:
                    n;
            }
        }

        // 2) Determine binder after validate_required by inspecting its assignment LHS (pick rightmost LHS var)
        var binderAfterRequired = findValidateRequiredVar(body);
        if (binderAfterRequired == null) binderAfterRequired = csVar;

        // 3) Rewrite validate_* calls: first arg -> appropriate binder
        function rewriteValidateCalls(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, fn, args) if (isChangesetValidate(mod, fn, args)):
                    var a = args.copy();
                    if (a.length > 0) {
                        // validate_required should use initial change binder (csVar)
                        // validate_length should use binderAfterRequired (if available)
                        // For validate_required, always use the binder from change/2 (csVar)
                        // For validate_length, use the binder produced by validate_required assignment (binderAfterRequired)
                        var targetBinder = (fn == "validate_required") ? csVar : binderAfterRequired;
                        a[0] = makeAST(EVar(targetBinder));
                        // Normalize field argument to atom when possible: String.to_atom("title") -> :title
                        if (a.length >= 2) {
                            a[1] = (function(arg: ElixirAST) {
                                return switch (arg.def) {
                                    case ERemoteCall({def: EVar(m)}, f, [fld]) if (m == "String" && f == "to_atom"):
                                        switch (fld.def) {
                                            case EString(s): makeAST(EAtom(s));
                                            default: arg;
                                        }
                                    case EString(s):
                                        makeAST(EAtom(s));
                                    default:
                                        arg;
                                }
                            })(a[1]);
                        }
                    }
                    
                    makeASTWithMeta(ERemoteCall(mod, fn, a), n.metadata, n.pos);
                default:
                    n;
            }
        }

        // 3a) Rebind standalone validate_* calls to csVar
        function rebindStandaloneValidate(n: ElixirAST): ElixirAST {
            inline function isValidateCall(e: ElixirAST): Bool {
                return switch (e.def) {
                    case ERemoteCall(mod, fn, args): isChangesetValidate(mod, fn, args);
                    case ERaw(code): code != null && (code.indexOf("Ecto.Changeset.validate_required(") != -1 || code.indexOf("Ecto.Changeset.validate_length(") != -1);
                    default: false;
                }
            }
            return switch (n.def) {
                // _ = if ... validate_length ... else cs -> cs = if ... end
                case EMatch(PVar("_"), rhs) if (isValidateLengthCall(rhs)):
                    makeASTWithMeta(EMatch(PVar(csVar), rhs), n.metadata, n.pos);
                // _ = <validate_* call>
                case EMatch(PVar("_"), rhs) if (isValidateCall(rhs)):
                    makeASTWithMeta(EBinary(Match, makeAST(EVar(csVar)), rhs), n.metadata, n.pos);
                // _ = nested assignment containing validate_*
                case EBinary(Match, {def: EVar("_")}, rhs) if (isValidateCall(rhs)):
                    makeASTWithMeta(EBinary(Match, makeAST(EVar(csVar)), rhs), n.metadata, n.pos);
                // Plain standalone validate_* call -> cs = call
                case ERemoteCall(mod2, fn2, args2) if (isChangesetValidate(mod2, fn2, args2)):
                    makeASTWithMeta(EBinary(Match, makeAST(EVar(csVar)), n), n.metadata, n.pos);
                default:
                    n;
            }
        }

        // 3b) Canonicalize assignment LHS of change/validate_* to csVar (drop thisN temps)
        inline function isThisTemp(name: String): Bool {
            return name != null && (StringTools.startsWith(name, "this") || StringTools.startsWith(name, "_this"));
        }
        function rewriteAssignmentLhs(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EMatch(PVar(lhs), rhs) if (rhs != null):
                    var isTarget = switch (rhs.def) {
                        case ERemoteCall(m, f, _): isChangeset(m) && (f == "change" || f == "validate_required" || f == "validate_length");
                        case EMatch(_, inner):
                            switch (inner.def) {
                                case ERemoteCall(m2, f2, _): isChangeset(m2) && (f2 == "change" || f2 == "validate_required" || f2 == "validate_length");
                                default: false;
                            }
                        case EBinary(Match, _, r2):
                            switch (r2.def) {
                                case ERemoteCall(m3, f3, _): isChangeset(m3) && (f3 == "change" || f3 == "validate_required" || f3 == "validate_length");
                                default: false;
                            }
                        default: false;
                    };
                    if (isTarget) {
                        var newRhs = rhs;
                        // Collapse nested chain: cs = (thisN = expr) -> cs = expr
                        switch (rhs.def) {
                            case EMatch(PVar(inner), innerExpr) if (isThisTemp(inner)):
                                newRhs = innerExpr;
                            default:
                        }
                        if (lhs != csVar) {
                            makeASTWithMeta(EMatch(PVar(csVar), newRhs), n.metadata, n.pos);
                        } else makeASTWithMeta(EMatch(PVar(csVar), newRhs), n.metadata, n.pos);
                    } else n;
                case EBinary(Match, left, rhs):
                    // dst = (thisN = change/validate_*) -> cs = change/validate_*
                    var isTarget = switch (rhs.def) {
                        case ERemoteCall(m, f, _): isChangeset(m) && (f == "change" || f == "validate_required" || f == "validate_length");
                        case EMatch(_, inner):
                            switch (inner.def) {
                                case ERemoteCall(m2, f2, _): isChangeset(m2) && (f2 == "change" || f2 == "validate_required" || f2 == "validate_length");
                                default: false;
                            }
                        case EBinary(Match, _, r2):
                            switch (r2.def) {
                                case ERemoteCall(m3, f3, _): isChangeset(m3) && (f3 == "change" || f3 == "validate_required" || f3 == "validate_length");
                                default: false;
                            }
                        default: false;
                    };
                    if (isTarget) {
                        var newRhs = rhs;
                        // Collapse nested chain on RHS: cs = (thisN = expr) -> cs = expr
                        switch (rhs.def) {
                            case EMatch(PVar(inner), innerExpr) if (isThisTemp(inner)):
                                newRhs = innerExpr;
                            default:
                        }
                        makeASTWithMeta(EBinary(Match, makeAST(EVar(csVar)), newRhs), n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        }

        // 3c) Rewrite opts.* access to Map.get(opts, :*) to avoid typed unknown key warnings
        function rewriteOptsAccess(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EAccess({def: EVar(v)}, key) if (v == "opts"):
                    var keyAtom = switch (key.def) { case EAtom(a): a; default: null; };
                    if (keyAtom != null) {
                        makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(keyAtom))]), n.metadata, n.pos);
                    } else n;
                case EField({def: EVar(v2)}, fld) if (v2 == "opts"):
                    // opts.min -> Map.get(opts, :min)
                    makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(fld))]), n.metadata, n.pos);
                default: n;
            }
        }

        // 4) Wrap cond branches that apply validate_length to rebind csVar
        function wrapCond(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECond(clauses) if (condContainsValidateLength(clauses)):
                    var rewritten = rewriteCondToReturnCsVar(clauses, csVar);
                    makeASTWithMeta(EMatch(PVar(csVar), makeAST(ECond(rewritten))), n.metadata, n.pos);
                default:
                    n;
            }
        }

        // First pass: rename opts declarations
        var pass1 = ElixirASTTransformer.transformNode(body, renameOptsDecl);
        // Second pass: fix validate_* targets
        var pass2 = ElixirASTTransformer.transformNode(pass1, rewriteValidateCalls);
        // 3c: apply opts access rewrite globally within the body to convert opts.* to Map.get(opts,:*)
        var pass2c = ElixirASTTransformer.transformNode(pass2, rewriteOptsAccess);
        // 3c-2: Normalize nil comparisons on opts.* to use Kernel.is_nil(Map.get(...))
        function rewriteNilComparisonsLocal(n: ElixirAST): ElixirAST {
            inline function isOptsField(e: ElixirAST): Null<String> {
                return switch (e.def) {
                    case EField({def: EVar(v)}, fld) if (v == "opts"): fld;
                    case EAccess({def: EVar(v)}, key) if (v == "opts"):
                        switch (key.def) { case EAtom(a): a; default: null; }
                    case ERemoteCall({def: EVar(m)}, f, [tgt, key]) if (m == "Map" && f == "get"):
                        switch (tgt.def) {
                            case EVar(v) if (v == "opts"):
                                switch (key.def) { case EAtom(a): a; default: null; }
                            default: null;
                        }
                    default: null;
                };
            }
            return switch (n.def) {
                case EBinary(Equal, l, r):
                    switch [isOptsField(l), r.def, isOptsField(r), l.def] {
                        case [f, ENil, _, _] if (f != null):
                            makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [ makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(f))])) ]));
                        case [_, _, f2, ENil] if (f2 != null):
                            makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [ makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(f2))])) ]));
                        default: n;
                    }
                case EBinary(NotEqual, l2, r2):
                    switch [isOptsField(l2), r2.def, isOptsField(r2), l2.def] {
                        case [f, ENil, _, _] if (f != null):
                            var inner = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [ makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(f))])) ]));
                            makeAST(ElixirASTDef.EUnary(Not, inner));
                        case [_, _, f2, ENil] if (f2 != null):
                            var inner2 = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [ makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(f2))])) ]));
                            makeAST(ElixirASTDef.EUnary(Not, inner2));
                        default: n;
                    }
                default: n;
            }
        }
        var pass2c2 = ElixirASTTransformer.transformNode(pass2c, rewriteNilComparisonsLocal);
        // 4) Rebind cond validate_length results to csVar (single canonical binder)
        function wrapCondWithBinder(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECond(clauses) if (condContainsValidateLength(clauses)):
                    var rewritten = rewriteCondToReturnCsVar(clauses, csVar);
                    makeASTWithMeta(EMatch(PVar(csVar), makeAST(ECond(rewritten))), n.metadata, n.pos);
                default:
                    n;
            }
        }
        // Third pass-b: canonicalize assignment LHS to csVar
        var pass2a = ElixirASTTransformer.transformNode(pass2c2, rebindStandaloneValidate);
        var pass2b = ElixirASTTransformer.transformNode(pass2a, rewriteAssignmentLhs);

        // 3d) Compress duplicated self-assignments like `cs = cs = cond do ... end`
        function compressDoubleAssign(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EMatch(PVar(v1), {def: EMatch(PVar(v2), expr)}) if (v1 == v2):
                    makeASTWithMeta(EMatch(PVar(v1), expr), n.metadata, n.pos);
                case EBinary(Match, left, {def: EBinary(Match, left2, expr2)}):
                    // Only when both LHS refer to the same var
                    var l1 = switch (left.def) { case EVar(nm): nm; default: null; };
                    var l2 = switch (left2.def) { case EVar(nm2): nm2; default: null; };
                    if (l1 != null && l1 == l2) makeASTWithMeta(EBinary(Match, left, expr2), n.metadata, n.pos) else n;
                default:
                    n;
            }
        }
        var pass2d = ElixirASTTransformer.transformNode(pass2b, compressDoubleAssign);

        // Fourth pass: wrap conds rebinding to csVar
        return ElixirASTTransformer.transformNode(pass2d, wrapCondWithBinder);
    }

    // Helper: detect presence of Ecto.Changeset calls within an expression subtree
    static function containsChangesetCallsDetect(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall(mod, fn, _):
                switch (mod.def) { case EVar(m) if (m == "Ecto.Changeset"): true; default: false; }
            case ERaw(code): code != null && code.indexOf("Ecto.Changeset.") != -1;
            case ECall(_, _, args):
                var found = false; if (args != null) for (a in args) if (containsChangesetCallsDetect(a)) { found = true; break; } found;
            case ERemoteCall(t, _, args2):
                if (containsChangesetCallsDetect(t)) true else { var f=false; if (args2 != null) for (a in args2) if (containsChangesetCallsDetect(a)) { f=true; break; } f; }
            case EParen(inner): containsChangesetCallsDetect(inner);
            default: false;
        };
    }

    static inline function isThisLike(v: String): Bool {
        return v == "this" || v == "this1" || v == "this2" || v == "_this1" || v == "_this2";
    }

    static inline function isMap(e: ElixirAST): Bool {
        return switch (e.def) { case EMap(_): true; default: false; }
    }

    static inline function isKeywordList(e: ElixirAST): Bool {
        return switch (e.def) { case EKeywordList(_): true; default: false; }
    }

    static function containsChangeCall(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall(mod, fn, _) if (isChangeset(mod) && fn == "change"): true;
            case ERaw(code) if (code != null && code.indexOf("Ecto.Changeset.change(") != -1): true;
            case EMatch(_, inner): containsChangeCall(inner);
            case EBinary(Match, _, right): containsChangeCall(right);
            case EParen(inner): containsChangeCall(inner);
            case EBlock(stmts):
                for (s in stmts) if (containsChangeCall(s)) return true; false;
            default: false;
        }
    }

    static function extractChangeCall(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case ERemoteCall(mod, fn, args) if (isChangeset(mod) && fn == "change"): e;
            case ERaw(_): e; // Keep raw code as-is
            case EMatch(_, inner): extractChangeCall(inner);
            case EBinary(Match, _, right): extractChangeCall(right);
            case EParen(inner): extractChangeCall(inner);
            case EBlock(stmts):
                for (s in stmts) {
                    if (containsChangeCall(s)) return extractChangeCall(s);
                }
                e;
            default: e;
        }
    }

    static inline function isChangesetValidate(mod: ElixirAST, func: String, args: Array<ElixirAST>): Bool {
        if (!isChangeset(mod)) return false;
        if (args == null || args.length == 0) return false;
        return switch (func) {
            case "validate_required" | "validate_length": true;
            default: false;
        }
    }

    static function isValidateLengthCall(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall(mod, fn, args) if (isChangeset(mod) && fn == "validate_length"): true;
            default: false;
        }
    }

    static function containsValidateCall(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall(mod, fn, _) if (isChangeset(mod) && (fn == "validate_required" || fn == "validate_length")): true;
            case ERaw(code) if (code != null && (code.indexOf("Ecto.Changeset.validate_required(") != -1 || code.indexOf("Ecto.Changeset.validate_length(") != -1)): true;
            case EMatch(_, inner): containsValidateCall(inner);
            case EBinary(Match, _, right): containsValidateCall(right);
            case EParen(inner): containsValidateCall(inner);
            case EBlock(stmts):
                for (s in stmts) if (containsValidateCall(s)) return true; false;
            default: false;
        }
    }

    static function extractValidateCall(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case ERemoteCall(mod, fn, args) if (isChangeset(mod) && (fn == "validate_required" || fn == "validate_length")): e;
            case EMatch(_, inner): extractValidateCall(inner);
            case EBinary(Match, _, right): extractValidateCall(right);
            case EParen(inner): extractValidateCall(inner);
            default: e;
        }
    }

    static function condContainsValidateLength(clauses: Array<ECondClause>): Bool {
        for (c in clauses) {
            if (c != null && c.body != null && isValidateLengthCall(c.body)) return true;
        }
        return false;
    }

    static function rewriteCondToReturnCsVar(clauses: Array<ECondClause>, csVar: String): Array<ECondClause> {
        var out:Array<ECondClause> = [];
        for (c in clauses) {
            if (c == null) continue;
            // Drop any existing default true/:true arms; we'll add a single canonical default later
            var isDefault = switch (c.condition.def) {
                case EBoolean(true): true;
                case EAtom(name) if (name == "true"): true;
                default: false;
            };
            if (isDefault) continue;

            var newBody: ElixirAST = c.body;
            // Ensure validate_length first arg is cs and atomize field arg
            switch (newBody.def) {
                case ERemoteCall(mod, fn, args) if (isChangeset(mod) && fn == "validate_length"):
                    var a = args.copy();
                    if (a.length > 0) a[0] = makeAST(EVar(csVar));
                    if (a.length > 1) {
                        a[1] = (function(arg: ElixirAST) {
                            return switch (arg.def) {
                                case EString(s): makeAST(EAtom(s));
                                case ERemoteCall({def: EVar(m)}, f, [fld]) if (m == "String" && (f == "to_atom" || f == "to_existing_atom")):
                                    switch (fld.def) {
                                        case EString(s2): makeAST(EAtom(s2));
                                        default: arg;
                                    }
                                default: arg;
                            }
                        })(a[1]);
                    }
                    // Rebuild call and normalize opts.* access inside keyword list (third arg)
                    var rebuilt = makeAST(ERemoteCall(mod, fn, a));
                    // Local normalizer for opts.* access
                    function rewriteOptsAccessInKeyword(n: ElixirAST): ElixirAST {
                        return switch (n.def) {
                            case EAccess({def: EVar(v)}, key) if (v == "opts"):
                                var keyAtom = switch (key.def) { case EAtom(a): a; default: null; };
                                if (keyAtom != null) {
                                    makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(keyAtom))]), n.metadata, n.pos);
                                } else n;
                            case EField({def: EVar(v2)}, fld) if (v2 == "opts"):
                                makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(fld))]), n.metadata, n.pos);
                            default: n;
                        }
                    }
                    newBody = ElixirASTTransformer.transformNode(rebuilt, rewriteOptsAccessInKeyword);
                default:
            }
            // Re-normalize conditions to Map.get/Kernel.is_nil to guarantee correctness
            var normalizedCond = (function(condIn: ElixirAST): ElixirAST {
                // local helpers mirror normalizeBody ones
                function rewriteOptsAccessLocal(n: ElixirAST): ElixirAST {
                    return switch (n.def) {
                        case EAccess({def: EVar(v)}, key) if (v == "opts"):
                            var keyAtom = switch (key.def) { case EAtom(a): a; default: null; };
                            if (keyAtom != null) {
                                makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(keyAtom))]), n.metadata, n.pos);
                            } else n;
                        case EField({def: EVar(v2)}, fld) if (v2 == "opts"):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(fld))]), n.metadata, n.pos);
                        default: n;
                    }
                }
                function rewriteNilComparisonForOpts(n: ElixirAST): ElixirAST {
                    inline function isOptsField(e: ElixirAST): Null<String> {
                        return switch (e.def) {
                            case EField({def: EVar(v)}, fld) if (v == "opts"): fld;
                            case EAccess({def: EVar(v)}, key) if (v == "opts"):
                                switch (key.def) { case EAtom(a): a; default: null; }
                            case ERemoteCall({def: EVar(m)}, f, [tgt, key]) if (m == "Map" && f == "get"):
                                switch (tgt.def) {
                                    case EVar(v) if (v == "opts"):
                                        switch (key.def) { case EAtom(a): a; default: null; }
                                    default: null;
                                }
                            default: null;
                        };
                    }
                    return switch (n.def) {
                        case EBinary(Equal, l, r):
                            switch [isOptsField(l), r.def, isOptsField(r), l.def] {
                                case [f, ENil, _, _] if (f != null):
                                    makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [ makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(f))])) ]));
                                case [_, _, f2, ENil] if (f2 != null):
                                    makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [ makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(f2))])) ]));
                                default: n;
                            }
                        case EBinary(NotEqual, l2, r2):
                            switch [isOptsField(l2), r2.def, isOptsField(r2), l2.def] {
                                case [f, ENil, _, _] if (f != null):
                                    var inner = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [ makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(f))])) ]));
                                    makeAST(ElixirASTDef.EUnary(Not, inner));
                                case [_, _, f2, ENil] if (f2 != null):
                                    var inner2 = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [ makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(f2))])) ]));
                                    makeAST(ElixirASTDef.EUnary(Not, inner2));
                                default: n;
                            }
                        default: n;
                    }
                }
                var stepA = ElixirASTTransformer.transformNode(condIn, rewriteOptsAccessLocal);
                var stepB = ElixirASTTransformer.transformNode(stepA, rewriteNilComparisonForOpts);
                return stepB;
            })(c.condition);
            out.push({condition: normalizedCond, body: newBody});
        }
        // Append a single default clause returning the canonical changeset
        out.push({condition: makeAST(EBoolean(true)), body: makeAST(EVar(csVar))});
        return out;
    }

    static function findChangesetVar(body: ElixirAST): Null<String> {
        var found: Null<String> = null;
        var foundFromValidate: Null<String> = null;
        function visit(n: ElixirAST): Void {
            if (n == null || n.def == null || found != null) return;
            switch (n.def) {
                case EMatch(PVar(v), rhs) if (containsChangeCall(rhs)):
                    found = v;
                case EBinary(Match, left, rhs) if (containsChangeCall(rhs)):
                    var v = getRightmostLhsVar(left);
                    if (v != null) found = v;
                case EBlock(stmts):
                    for (s in stmts) visit(s);
                default:
            }
        }
        visit(body);
        return found;
    }

    static function findValidateRequiredVar(body: ElixirAST): Null<String> {
        var found: Null<String> = null;
        function visit(n: ElixirAST): Void {
            if (n == null || n.def == null || found != null) return;
            switch (n.def) {
                case EMatch(PVar(v), rhs) if (containsValidateRequiredCall(rhs)):
                    found = v;
                case EBinary(Match, left, rhs) if (containsValidateRequiredCall(rhs)):
                    var v2 = getRightmostLhsVar(left);
                    if (v2 != null) found = v2;
                case EBlock(stmts):
                    for (s in stmts) visit(s);
                default:
            }
        }
        visit(body);
        return found;
    }

    static function containsValidateRequiredCall(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall(mod, fn, _) if (isChangeset(mod) && fn == "validate_required"): true;
            case ERaw(code) if (code != null && code.indexOf("Ecto.Changeset.validate_required(") != -1): true;
            case EMatch(_, inner): containsValidateRequiredCall(inner);
            case EBinary(Match, _, right): containsValidateRequiredCall(right);
            case EParen(inner): containsValidateRequiredCall(inner);
            default: false;
        }
    }

    static function getRightmostLhsVar(lhs: ElixirAST): Null<String> {
        return switch (lhs.def) {
            case EVar(n): n;
            case EBinary(Match, _, right):
                switch (right.def) {
                    case EVar(n): n;
                    case _: getRightmostLhsVar(right);
                }
            default: null;
        }
    }

    static inline function isChangeset(mod: ElixirAST): Bool {
        return switch (mod.def) {
            case EVar(name): name != null && (name == "Ecto.Changeset" || name.indexOf("Ecto.Changeset") != -1);
            default: false;
        }
    }
}

#end
        
