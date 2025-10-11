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
 *   to use the canonical changeset variable.
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
                                case ERemoteCall(m, _, _):
                                    switch (m.def) { case EVar(n) if (n == "Ecto.Changeset"): usesChangeset = true; default: }
                                case EBlock(es): for (e in es) scan(e);
                                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                                case ECase(e, cs): scan(e); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                                case EBinary(_, l, r): scan(l); scan(r);
                                case EMatch(_, rhs): scan(rhs);
                                case ECall(t,_,as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
                                case ERemoteCall(m,_,as): scan(m); if (as != null) for (a in as) scan(a);
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
                                case EVar(v) if (isThisLike(v)):
                                    makeASTWithMeta(EVar(binder), n.metadata, n.pos);
                                case EVar(v) if (v == "cs" && binder != "cs"):
                                    makeASTWithMeta(EVar(binder), n.metadata, n.pos);
                                default:
                                    n;
                            }
                        }
                        var newBody = [for (b in body) ElixirASTTransformer.transformNode(b, tx)];
                        makeASTWithMeta(EModule(modName, attrs, newBody), node.metadata, node.pos);
                    }
                // (handled in function body normalization)

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

    static function normalizeBody(body: ElixirAST): ElixirAST {
        // Determine canonical changeset variable name
        var csVar = findChangesetVar(body);
        #if true
        trace('[ChangesetTransforms] findChangesetVar -> ' + Std.string(csVar));
        #end
        if (csVar == null) {
            // Fallback: pick a sensible binder from declared names
            var declared = new Array<String>();
            ASTUtils.walk(body, function(n: ElixirAST) {
                switch (n.def) {
                    case EMatch(PVar(v), _): declared.push(v);
                    case EBinary(Match, left, _):
                        switch (left.def) { case EVar(v): declared.push(v); default: }
                    default:
                }
            });
            // Prefer 'changeset'
            var pick: Null<String> = null;
            for (n in declared) if (n == "changeset") { pick = n; break; }
            // Else last _?thisN
            if (pick == null) {
                for (i in 0...declared.length) {
                    var name = declared[declared.length - 1 - i];
                    if (StringTools.startsWith(name, "this") || StringTools.startsWith(name, "_this")) { pick = name; break; }
                }
            }
            csVar = pick != null ? pick : "cs";
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
                    }
                    
                    makeASTWithMeta(ERemoteCall(mod, fn, a), n.metadata, n.pos);
                default:
                    n;
            }
        }

        // 4) Wrap cond branches that apply validate_length to rebind csVar
        function wrapCond(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECond(clauses) if (condContainsValidateLength(clauses)):
                    var rewritten = rewriteCondToReturnCsVar(clauses, csVar);
                    #if true
                    trace('[ChangesetTransforms] wrap cond -> bind to ' + csVar);
                    #end
                    makeASTWithMeta(EMatch(PVar(csVar), makeAST(ECond(rewritten))), n.metadata, n.pos);
                default:
                    n;
            }
        }

        // First pass: rename opts declarations
        var pass1 = ElixirASTTransformer.transformNode(body, renameOptsDecl);
        // Second pass: fix validate_* targets
        var pass2 = ElixirASTTransformer.transformNode(pass1, rewriteValidateCalls);
        // Fourth pass: rebind cond validate_length results using binderAfterRequired
        function wrapCondWithBinder(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECond(clauses) if (condContainsValidateLength(clauses)):
                    var rewritten = rewriteCondToReturnCsVar(clauses, binderAfterRequired);
                    
                    makeASTWithMeta(EMatch(PVar(binderAfterRequired), makeAST(ECond(rewritten))), n.metadata, n.pos);
                default:
                    n;
            }
        }

        return ElixirASTTransformer.transformNode(pass2, wrapCondWithBinder);
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
        var out = [];
        for (c in clauses) {
            if (c == null) continue;
            var newBody: ElixirAST = c.body;
            // Ensure validate_length first arg is cs
            switch (newBody.def) {
                case ERemoteCall(mod, fn, args) if (isChangeset(mod) && fn == "validate_length"):
                    var a = args.copy();
                    if (a.length > 0) a[0] = makeAST(EVar(csVar));
                    newBody = makeAST(ERemoteCall(mod, fn, a));
                default:
            }
            // Replace default :true -> :nil with true -> cs
            var newCond = c.condition;
            switch (newCond.def) {
                case EAtom(name) if (name == "true"):
                    switch (newBody.def) {
                        case ENil | EAtom(_):
                            newBody = makeAST(EVar(csVar));
                        default:
                    }
                default:
            }
            out.push({condition: newCond, body: newBody});
        }
        // Ensure there is a default true -> cs clause
        var hasDefault = false;
        for (c in out) switch (c.condition.def) { case EAtom(n) if (n == "true"): hasDefault = true; default: }
        if (!hasDefault) out.push({condition: makeAST(EAtom(ElixirAtom.raw("true"))), body: makeAST(EVar(csVar))});
        return out;
    }

    static function findChangesetVar(body: ElixirAST): Null<String> {
        var found: Null<String> = null;
        var foundFromValidate: Null<String> = null;
        function visit(n: ElixirAST): Void {
            if (n == null || n.def == null || found != null) return;
            switch (n.def) {
                case EMatch(PVar(v), rhs) if (containsChangeCall(rhs)):
                    #if true
                    trace('[ChangesetTransforms] found change match binder via EMatch: ' + v);
                    #end
                    found = v;
                case EBinary(Match, left, rhs) if (containsChangeCall(rhs)):
                    var v = getRightmostLhsVar(left);
                    #if true
                    trace('[ChangesetTransforms] found change match binder via EBinary: ' + Std.string(v));
                    #end
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
