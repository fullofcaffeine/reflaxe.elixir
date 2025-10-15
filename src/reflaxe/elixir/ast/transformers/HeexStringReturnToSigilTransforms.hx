package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexStringReturnToSigilTransforms
 *
 * WHAT
 * - Converts functions that return plain HTML strings into ~H sigil blocks so HEEx can
 *   compile them properly. Supports simple cases where the final expression (or if-branches)
 *   are string literals (optionally parenthesized) that contain HTML-like markup.
 *
 * WHY
 * - Returning raw strings from helper functions and embedding them in ~H causes escaping, so
 *   literal tags appear in the browser. Converting these helpers to return ~H ensures the
 *   content is treated as HEEx and renders correctly without Phoenix.HTML.raw.
 *
 * HOW
 * - For EDef/EDefp bodies:
 *   - Detect EString/EParen(EString) as the final expression (and within EIf branches).
 *   - If the string content looks like HTML/HEEx (contains '<' and '>'), convert to
 *     ESigil("H", converted, "") where converted:
 *       • replaces #{...} and ${...} with <%= ... %>
 *       • rewrites assigns.* to @
 *   - Preserve metadata and parens depth.
 */
class HeexStringReturnToSigilTransforms {
    static function looksLikeHtml(s:String):Bool {
        if (s == null) return false;
        var t = StringTools.trim(s);
        // Heuristic: contains a tag-like pair and not just text
        return t.indexOf("<") != -1 && t.indexOf(">") != -1;
    }

    static function convertInterpolations(s:String):String {
        if (s == null) return s;
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var j1 = s.indexOf("#{", i);
            var j2 = s.indexOf("${", i);
            var j = (j1 == -1) ? j2 : (j2 == -1 ? j1 : (j1 < j2 ? j1 : j2));
            if (j == -1) { out.add(s.substr(i)); break; }
            out.add(s.substr(i, j - i));
            var k = j + 2;
            var depth = 1;
            while (k < s.length && depth > 0) {
                var ch = s.charAt(k);
                if (ch == '{') depth++; else if (ch == '}') depth--; k++;
            }
            var expr = s.substr(j + 2, (k - 1) - (j + 2));
            expr = StringTools.trim(expr);
            expr = StringTools.replace(expr, "assigns.", "@");
            out.add('<%= ' + expr + ' %>');
            i = k;
        }
        return out.toString();
    }

    static function toHeex(node: ElixirAST): ElixirAST {
        // unwrap parens to find string
        var cur = node;
        var parens = 0;
        while (true) {
            switch (cur.def) {
                case EParen(inner): cur = inner; parens++;
                default: break;
            }
            if (Type.enumConstructor(cur.def) != "EParen") break;
        }
        switch (cur.def) {
            case EString(s) if (looksLikeHtml(s)):
                var conv = convertInterpolations(s);
                var rebuilt: ElixirAST = makeAST(ESigil("H", conv, ""));
                while (parens-- > 0) rebuilt = makeAST(EParen(rebuilt));
                return makeASTWithMeta(rebuilt.def, node.metadata, node.pos);
            default:
                return node;
        }
    }

    static function transformBody(ret: ElixirAST, ensureAssigns: Bool): ElixirAST {
        return ElixirASTTransformer.transformNode(ret, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EIf(cond, thenB, elseB):
                    var newThen = transformBody(thenB, ensureAssigns);
                    var newElse = elseB != null ? transformBody(elseB, ensureAssigns) : null;
                    makeASTWithMeta(EIf(cond, newThen, newElse), n.metadata, n.pos);
                case EBlock(stmts):
                    if (stmts.length == 0) return n;
                    var last = stmts[stmts.length - 1];
                    var convertedLast = toHeex(last);
                    if (convertedLast == last) return n;
                    var newStmts = stmts.copy();
                    // If assigns is required and not provided by params, inject minimal map
                    if (ensureAssigns) newStmts.insert(newStmts.length - 1, makeAST(EMatch(PVar("assigns"), makeAST(EMap([])))));
                    newStmts[newStmts.length - 1] = convertedLast;
                    makeASTWithMeta(EBlock(newStmts), n.metadata, n.pos);
                case EParen(inner):
                    var converted = toHeex(n);
                    if (converted != n) {
                        if (ensureAssigns) {
                            // Wrap into a block with assigns = %{} then the sigil
                            makeASTWithMeta(EBlock([
                                makeAST(EMatch(PVar("assigns"), makeAST(EMap([])))),
                                converted
                            ]), n.metadata, n.pos);
                        } else converted;
                    } else n;
                case EString(_):
                    var conv = toHeex(n);
                    if (conv != n && ensureAssigns) {
                        makeASTWithMeta(EBlock([
                            makeAST(EMatch(PVar("assigns"), makeAST(EMap([])))),
                            conv
                        ]), n.metadata, n.pos);
                    } else conv;
                default:
                    n;
            }
        });
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) | EDefp(name, args, guards, body):
                    // HEEx requires the parameter to be literally named `assigns`.
                    // We support both `assigns` and `_assigns` (previous passes may underscore it)
                    // and will rename `_assigns` → `assigns` when we actually convert to ~H.
                    var hasAssignsParam = false;
                    var hasUnderscoredAssigns = false;
                    var argsRenamed = args;
                    for (a in args) switch (a) {
                        case PVar(p) if (p == "assigns"): hasAssignsParam = true;
                        case PVar(p) if (p == "_assigns"): hasUnderscoredAssigns = true;
                        default:
                    }
                    // Only convert helpers that already take assigns/_assigns.
                    // Functions without assigns remain as strings and will be handled by
                    // the HEEx wrapper/inliner passes at call sites.
                    if (!hasAssignsParam && !hasUnderscoredAssigns) return n;
                    var newBody = transformBody(body, false);
                    if (newBody != body) {
                        if (!hasAssignsParam && hasUnderscoredAssigns) {
                            // Rename `_assigns` → `assigns` in the parameter list to satisfy HEEx
                            var tmp:Array<EPattern> = [];
                            for (a in args) switch (a) {
                                case PVar(p) if (p == "_assigns"): tmp.push(PVar("assigns"));
                                default: tmp.push(a);
                            }
                            argsRenamed = tmp;
                        }
                        var newDef = Type.enumConstructor(n.def) == "EDef"
                            ? EDef(name, argsRenamed, guards, newBody)
                            : EDefp(name, argsRenamed, guards, newBody);
                        makeASTWithMeta(newDef, n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }
}

#end
