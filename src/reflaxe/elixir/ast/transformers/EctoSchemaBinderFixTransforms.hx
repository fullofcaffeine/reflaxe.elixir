package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * EctoSchemaBinderFixTransforms
 *
 * WHAT
 * - Normalize Ecto schema changeset/2 binders by dropping leading underscores when
 *   the function body references the base names. Keeps original non-underscore
 *   names intact; does not invent app-specific names.
 *
 * WHY
 * - Hygiene passes may prefix parameters with underscores; schema changesets routinely use
 *   both binders in the body. This prevents undefined-variable errors.
 *
 * HOW
 * - For any module, when encountering def/defp named `changeset` with 2 params, rename
 *   parameters from `_todo/_params` to `todo/params` when the body references those base names.
 */
class EctoSchemaBinderFixTransforms {
    /**
     * WHAT
     * - Force canonical binder names for schema changeset/2 to `todo, params` and
     *   rewrite body references accordingly.
     *
     * WHY
     * - Hygiene passes can introduce `_todo/_params` while changeset bodies refer
     *   to `todo/params`, causing undefined variable errors under WAE.
     *
     * HOW
 * - For def/defp changeset/2, capture original param names. If a param name
 *   starts with `_` and the body references the base name (without `_`), rename
 *   the parameter to the base name. Also rewrite body references of the
 *   underscore form to the base name to preserve consistency. No hardcoded
 *   domain names are used.
     */
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(fname, args, guards, body) if (fname == "changeset" && args.length == 2):
                    var p0: String = switch (args[0]) { case PVar(nm): nm; default: null; };
                    var p1: String = switch (args[1]) { case PVar(nm): nm; default: null; };
                    inline function baseName(n: String): String return (n != null && n.length > 0 && n.charAt(0) == '_') ? n.substr(1) : n;
                    // Compute desired names by API shape: prefer names used in Ecto.Changeset.change/cast calls
                    var desired0: String = null;
                    var desired1: String = null;
                    function scanForDesired(n: ElixirAST): Void {
                        if (desired0 != null && desired1 != null) return;
                        switch (n.def) {
                            case ERemoteCall(mod, fn, args) if (args != null && args.length >= 2):
                                var m = switch (mod.def) { case EVar(s): s; default: null; };
                                if (m == "Ecto.Changeset" && (fn == "change" || fn == "cast")) {
                                    switch (args[0].def) { case EVar(v): desired0 = v; default: }
                                    switch (args[1].def) { case EVar(v2): desired1 = v2; default: }
                                }
                            case EBlock(es): for (e in es) scanForDesired(e);
                            case EIf(c,t,e): scanForDesired(c); scanForDesired(t); if (e != null) scanForDesired(e);
                            case ECase(e, cs): scanForDesired(e); for (c in cs) { if (c.guard != null) scanForDesired(c.guard); scanForDesired(c.body); }
                            case ECall(t,_,as): if (t != null) scanForDesired(t); if (as != null) for (a in as) scanForDesired(a);
                            case ERemoteCall(m2,_,as2): scanForDesired(m2); if (as2 != null) for (a in as2) scanForDesired(a);
                            default:
                        }
                    }
                    scanForDesired(body);
                    // Only drop leading underscores when either:
                    // 1) shape-derived desired names were found from Ecto.Changeset.* calls, or
                    // 2) the function body references the base (non-underscore) names.
                    var base0 = baseName(p0);
                    var base1 = baseName(p1);
                    var bodyUsesBase0 = base0 != null && VariableUsageCollector.usedInFunctionScope(body, base0);
                    var bodyUsesBase1 = base1 != null && VariableUsageCollector.usedInFunctionScope(body, base1);
                    var rename0 = (desired0 != null) || bodyUsesBase0;
                    var rename1 = (desired1 != null) || bodyUsesBase1;
                    if (desired0 == null && rename0) desired0 = base0; // when renaming by usage, use base
                    if (desired1 == null && rename1) desired1 = base1;
                    var newArgs: Array<EPattern> = [
                        PVar(rename0 && desired0 != null ? desired0 : p0),
                        PVar(rename1 && desired1 != null ? desired1 : p1)
                    ];
                    var newBody = ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
                        return switch (x.def) {
                            // Rewrite underscore form to base ONLY when we actually renamed the parameter
                            case EVar(v) if (rename0 && p0 != null && v == p0 && desired0 != null): makeASTWithMeta(EVar(desired0), x.metadata, x.pos);
                            case EVar(v2) if (rename1 && p1 != null && v2 == p1 && desired1 != null): makeASTWithMeta(EVar(desired1), x.metadata, x.pos);
                            default: x;
                        }
                    });
                    makeASTWithMeta(EDef(fname, newArgs, guards, newBody), n.metadata, n.pos);
                case EDefp(fname2, args2, guards2, body2) if (fname2 == "changeset" && args2.length == 2):
                    var q0: String = switch (args2[0]) { case PVar(nm): nm; default: null; };
                    var q1: String = switch (args2[1]) { case PVar(nm): nm; default: null; };
                    // Repeat for defp version
                    var d0: String = null;
                    var d1: String = null;
                    function scanDesired2(n: ElixirAST): Void {
                        if (d0 != null && d1 != null) return;
                        switch (n.def) {
                            case ERemoteCall(mod, fn, args) if (args != null && args.length >= 2):
                                var m = switch (mod.def) { case EVar(s): s; default: null; };
                                if (m == "Ecto.Changeset" && (fn == "change" || fn == "cast")) {
                                    switch (args[0].def) { case EVar(v): d0 = v; default: }
                                    switch (args[1].def) { case EVar(v2): d1 = v2; default: }
                                }
                            case EBlock(es): for (e in es) scanDesired2(e);
                            case EIf(c,t,e): scanDesired2(c); scanDesired2(t); if (e != null) scanDesired2(e);
                            case ECase(e, cs): scanDesired2(e); for (c in cs) { if (c.guard != null) scanDesired2(c.guard); scanDesired2(c.body); }
                            case ECall(t,_,as): if (t != null) scanDesired2(t); if (as != null) for (a in as) scanDesired2(a);
                            case ERemoteCall(m2,_,as2): scanDesired2(m2); if (as2 != null) for (a in as2) scanDesired2(a);
                            default:
                        }
                    }
                    scanDesired2(body2);
                    inline function baseName2(n: String): String return (n != null && n.length > 0 && n.charAt(0) == '_') ? n.substr(1) : n;
                    var baseQ0 = baseName2(q0);
                    var baseQ1 = baseName2(q1);
                    var bodyUsesBaseQ0 = baseQ0 != null && VariableUsageCollector.usedInFunctionScope(body2, baseQ0);
                    var bodyUsesBaseQ1 = baseQ1 != null && VariableUsageCollector.usedInFunctionScope(body2, baseQ1);
                    var renameQ0 = (d0 != null) || bodyUsesBaseQ0;
                    var renameQ1 = (d1 != null) || bodyUsesBaseQ1;
                    if (d0 == null && renameQ0) d0 = baseQ0;
                    if (d1 == null && renameQ1) d1 = baseQ1;
                    var newArgs2: Array<EPattern> = [
                        PVar(renameQ0 && d0 != null ? d0 : q0),
                        PVar(renameQ1 && d1 != null ? d1 : q1)
                    ];
                    var newBody2 = ElixirASTTransformer.transformNode(body2, function(x: ElixirAST): ElixirAST {
                        return switch (x.def) {
                            case EVar(v) if (renameQ0 && q0 != null && v == q0 && d0 != null): makeASTWithMeta(EVar(d0), x.metadata, x.pos);
                            case EVar(v2) if (renameQ1 && q1 != null && v2 == q1 && d1 != null): makeASTWithMeta(EVar(d1), x.metadata, x.pos);
                            default: x;
                        }
                    });
                    makeASTWithMeta(EDefp(fname2, newArgs2, guards2, newBody2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end
