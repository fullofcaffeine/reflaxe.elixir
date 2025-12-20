package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexAssignsLocalVarRenameTransforms
 *
 * WHAT
 * - In any function whose body contains a HEEx sigil (`~H` / `ESigil("H", ...)`),
 *   rewrite stray `_assigns` references back to `assigns`:
 *   - `EMatch(PVar("_assigns"), rhs)` → `EMatch(PVar("assigns"), rhs)`
 *   - `EBinary(Match, EVar("_assigns"), rhs)` → `EBinary(Match, EVar("assigns"), rhs)`
 *   - Any expression `EVar("_assigns")` → `EVar("assigns")`
 *
 * WHY
 * - Phoenix's `~H` macro requires a variable literally named `assigns` in scope.
 * - Earlier hygiene/underscore passes may safely rename unused params to `_assigns`,
 *   but they may not rewrite all body occurrences (and some app code legitimately
 *   rebinds assigns before returning `~H`).
 * - If `_assigns` survives in the body, you can end up rebinding the wrong name
 *   (e.g. `_assigns = assigns |> assign(...)`) and the template still uses the
 *   original `assigns` map → runtime `KeyError` for expected assigns keys.
 *
 * HOW
 * - Detect `~H` usage by scanning the body for `ESigil("H", ...)`.
 * - If present, traverse the function body and rename `_assigns` → `assigns`
 *   in both patterns and expression variables.
 *
 * EXAMPLES
 * Elixir (before):
 *   def render(assigns) do
 *     _assigns = assign(assigns, :flash_info, "hi")
 *     ~H"<%= @flash_info %>"
 *   end
 * Elixir (after):
 *   def render(assigns) do
 *     assigns = assign(assigns, :flash_info, "hi")
 *     ~H"<%= @flash_info %>"
 *   end
 */
class HeexAssignsLocalVarRenameTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    if (!containsHSigil(body)) return n;
                    var newBody = renameAssignsInBody(body);
                    (newBody == body) ? n : makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2):
                    if (!containsHSigil(body2)) return n;
                    var newBody2 = renameAssignsInBody(body2);
                    (newBody2 == body2) ? n : makeASTWithMeta(EDefp(name2, args2, guards2, newBody2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function containsHSigil(node: ElixirAST): Bool {
        var found = false;
        ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            if (found) return x;
            switch (x.def) {
                case ESigil(type, _, _) if (type == "H"):
                    found = true;
                case ERemoteCall(_mod, funcName, _args) if (funcName == "sigil_H"):
                    found = true;
                case ERaw(code) if (code != null && (code.indexOf("~H\"") != -1 || code.indexOf("~H'''") != -1 || code.indexOf("~H\"\"\"") != -1 || code.indexOf("~H'") != -1)):
                    found = true;
                default:
            }
            return x;
        });
        return found;
    }

    static function renameAssignsInBody(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(name) if (name == "_assigns"):
                    makeASTWithMeta(EVar("assigns"), x.metadata, x.pos);
                case EMatch(pattern, rhs):
                    var newPattern = renameAssignsInPattern(pattern);
                    (newPattern == pattern) ? x : makeASTWithMeta(EMatch(newPattern, rhs), x.metadata, x.pos);
                case EBinary(Match, left, rhs):
                    var newLeft = switch (left.def) {
                        case EVar(name2) if (name2 == "_assigns"): makeASTWithMeta(EVar("assigns"), left.metadata, left.pos);
                        default: left;
                    };
                    (newLeft == left) ? x : makeASTWithMeta(EBinary(Match, newLeft, rhs), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }

    static function renameAssignsInPattern(p: EPattern): EPattern {
        return switch (p) {
            case PVar(name) if (name == "_assigns"):
                PVar("assigns");
            case PVar(_):
                p;
            case PTuple(els):
                PTuple(els.map(renameAssignsInPattern));
            case PList(els):
                PList(els.map(renameAssignsInPattern));
            case PCons(h, t):
                PCons(renameAssignsInPattern(h), renameAssignsInPattern(t));
            case PMap(pairs):
                PMap(pairs.map(pa -> { key: pa.key, value: renameAssignsInPattern(pa.value) }));
            case PStruct(m, fields):
                PStruct(m, fields.map(f -> { key: f.key, value: renameAssignsInPattern(f.value) }));
            case PAlias(name2, pat):
                var aliasName = name2 == "_assigns" ? "assigns" : name2;
                PAlias(aliasName, renameAssignsInPattern(pat));
            case PPin(inner):
                PPin(renameAssignsInPattern(inner));
            case PBinary(segs):
                PBinary(segs.map(s -> { pattern: renameAssignsInPattern(s.pattern), size: s.size, type: s.type, modifiers: s.modifiers }));
            case PWildcard | PLiteral(_):
                p;
        }
    }
}

#end
