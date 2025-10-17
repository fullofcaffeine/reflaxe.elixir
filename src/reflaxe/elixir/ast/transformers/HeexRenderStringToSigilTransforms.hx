package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.TemplateHelpers;

/**
 * HeexRenderStringToSigilTransforms
 *
 * WHAT
 * - Ensures LiveView render(assigns) returns a ~H sigil when the body ends with
 *   a literal HTML-ish string. Converts the final string into ESigil("H", ...).
 *
 * WHY
 * - Some code paths (e.g., HXX macro returning a processed string) leave render/1
 *   returning a plain string. LiveView requires %Phoenix.LiveView.Rendered{}.
 *
 * HOW
 * - For EDef("render", [assigns], _, body):
 *   - If body is EBlock([... , EString s]) and s contains tag-like content, replace
 *     the last expression with ESigil("H", converted, "").
 *   - Conversion mirrors HeexStringReturnToSigilTransforms.convertInterpolations.
 */
class HeexRenderStringToSigilTransforms {
    static inline function unwrapParens(n: ElixirAST): ElixirAST {
        var cur = n;
        while (Type.enumConstructor(cur.def) == "EParen") {
            switch (cur.def) {
                case EParen(inner): cur = inner;
                default:
            }
        }
        return cur;
    }
    static inline function looksLikeHtml(s:String):Bool {
        if (s == null) return false;
        var t = StringTools.trim(s);
        return t.indexOf("<") != -1 && t.indexOf(">") != -1;
    }

    static function convertInterpolations(s:String):String {
        if (s == null) return s;
        // Delegate to TemplateHelpers to keep a single source of truth, including
        // attribute-level expression rewriting and control-tag normalization.
        var res = TemplateHelpers.rewriteInterpolations(s);
        res = TemplateHelpers.rewriteControlTags(res);
        return res;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "render"):
                    // Debug: log arg patterns to ensure we recognize assigns
                    var argNames = [];
                    for (a in args) switch (a) {
                        case PVar(p): argNames.push(p);
                        case PWildcard: argNames.push("_");
                        case PLiteral(_): argNames.push("[lit]");
                        default: argNames.push("[complex]");
                    }
                    trace('[HeexRenderStringToSigil] Found render with args=' + argNames.join(","));
                    var hasAssigns = false;
                    for (a in args) switch (a) { case PVar(p) if (p == "assigns"): hasAssigns = true; default: }
                    if (!hasAssigns) return n;
                    var b0 = unwrapParens(body);
                    trace('[HeexRenderStringToSigil] Body node after unwrap=' + Type.enumConstructor(b0.def));
                    switch (b0.def) {
                        case EBlock(stmts) if (stmts.length > 0):
                            var last = stmts[stmts.length - 1];
                            last = unwrapParens(last);
                            switch (last.def) {
                case EString(s):
                    var conv = convertInterpolations(s);
                    var newStmts = stmts.copy();
                                    newStmts[newStmts.length - 1] = makeAST(ESigil("H", conv, ""));
                                    var updated = makeASTWithMeta(EDef(name, args, guards, makeAST(EBlock(newStmts))), n.metadata, n.pos);
                                    trace('[HeexRenderStringToSigil] Rewrote render/1 EBlock last EString → ~H');
                                    updated;
                                default: n;
                            }
                case EDo(stmts) if (stmts.length > 0):
                    var last2 = stmts[stmts.length - 1];
                    last2 = unwrapParens(last2);
                    switch (last2.def) {
                        case EString(ss):
                            var conv3 = convertInterpolations(ss);
                                    var out = stmts.copy();
                                    out[out.length - 1] = makeAST(ESigil("H", conv3, ""));
                                    var updated2 = makeASTWithMeta(EDef(name, args, guards, makeAST(EDo(out))), n.metadata, n.pos);
                                    trace('[HeexRenderStringToSigil] Rewrote render/1 EDo last EString → ~H');
                                    updated2;
                        default: n;
                    }
                case EString(s4):
                            var sig2 = makeAST(ESigil("H", convertInterpolations(s4), ""));
                            var updated3 = makeASTWithMeta(EDef(name, args, guards, sig2), n.metadata, n.pos);
                            trace('[HeexRenderStringToSigil] Rewrote render/1 EString body → ~H');
                            updated3;
                        default: n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
