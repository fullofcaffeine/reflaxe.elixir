package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceBareCallPreserveTransforms
 *
 * WHAT
 * - Rewrites bare Presence effect calls at statement level into wildcard assignments
 *   to ensure they are preserved through hygiene/cleanup passes.
 *   Specifically: `Presence.track/update/untrack(...)` → `_ = Presence.track/update/untrack(...)`.
 *
 * WHY
 * - Presence calls are effectful (track/update/untrack) and must not be pruned even
 *   when their return values are unused. Converting them to `_ = ...` normalizes shape
 *   so later passes that discard unused named binders do not remove the effect. This
 *   avoids regressions where bare calls vanish due to generic cleanup.
 *
 * HOW
 * - Walk block-like contexts (EBlock, EDo, EFn clause bodies). For each top-level
 *   statement, if it is a bare ERemoteCall to a Presence module with one of the
 *   effectful functions, wrap it into EMatch(PWildcard, call).
 * - Conservatively matches modules by API shape only:
 *     - Phoenix.Presence
 *     - <Any>.Presence (e.g., <App>Web.Presence)
 *     - Presence (imported alias)
 * - Does NOT touch `list/1` which is non-effectful.
 *
 * EXAMPLES
 * Elixir before:
 *   Phoenix.Presence.track(self(), "users", key, meta)
 *   TodoAppWeb.Presence.update(self(), "users", key, meta)
 *
 * Elixir after:
 *   _ = Phoenix.Presence.track(self(), "users", key, meta)
 *   _ = TodoAppWeb.Presence.update(self(), "users", key, meta)
 */
class PresenceBareCallPreserveTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (looksLikePresenceModule(name, n)):
                    var newBody = [for (b in body) transformInPresence(b)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (looksLikePresenceModule(name, n)):
                    makeASTWithMeta(EDefmodule(name, transformInPresence(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function looksLikePresenceModule(name:String, node:ElixirAST):Bool {
        if (node != null && node.metadata != null && node.metadata.isPresence == true) return true;
        if (name == null) return false;
        return StringTools.endsWith(name, ".Presence") || StringTools.endsWith(name, "Web.Presence");
    }

    static function transformInPresence(sub: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(sub, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    makeASTWithMeta(EBlock(processStatements(stmts)), n.metadata, n.pos);
                case EDo(stmts2):
                    makeASTWithMeta(EDo(processStatements(stmts2)), n.metadata, n.pos);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var body = cl.body;
                        var newBody = switch (body.def) {
                            case EBlock(ss): makeASTWithMeta(EBlock(processStatements(ss)), body.metadata, body.pos);
                            case EDo(ss2): makeASTWithMeta(EDo(processStatements(ss2)), body.metadata, body.pos);
                            default: body;
                        };
                        newClauses.push({ args: cl.args, guard: cl.guard, body: newBody });
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function processStatements(stmts: Array<ElixirAST>): Array<ElixirAST> {
        var out: Array<ElixirAST> = [];
        for (i in 0...stmts.length) {
            var s = stmts[i];
            var isLast = (i == stmts.length - 1);
            switch (s.def) {
                // Only rewrite bare remote calls; leave existing matches/assignments intact
                case ERemoteCall(mod, func, args):
                    // Do not rewrite the final statement to preserve return-value shape in snapshots
                    if (!isLast && isPresenceEffect(mod, func)) {
                        out.push(makeASTWithMeta(EMatch(PWildcard, s), s.metadata, s.pos));
                    } else {
                        out.push(s);
                    }
                // Also preserve bare local presence calls (track/update/untrack) emitted inside Presence modules
                // Example: track(self(), socket, key, meta) → _ = track(self(), socket, key, meta)
                case ECall(target, func2, args2) if (target == null && isPresenceLocalEffect(func2)):
                    if (!isLast) {
                        out.push(makeASTWithMeta(EMatch(PWildcard, s), s.metadata, s.pos));
                    } else {
                        out.push(s);
                    }
                default:
                    out.push(s);
            }
        }
        return out;
    }

    static inline function isPresenceEffect(mod: ElixirAST, func: String): Bool {
        // API-based: match Phoenix.Presence, <Any>.Presence, or Presence alias
        var modName: Null<String> = switch (mod.def) {
            case EVar(m): m;
            default: null;
        };
        if (modName == null) return false;
        var isPresenceModule = (modName == "Phoenix.Presence") || StringTools.endsWith(modName, ".Presence") || (modName == "Presence");
        if (!isPresenceModule) return false;
        return (func == "track" || func == "update" || func == "untrack");
    }

    static inline function isPresenceLocalEffect(func: String): Bool {
        // Within Presence modules, local calls to behavior-injected functions should be preserved
        // Support both plain names and macro-generated internal variants
        return (func == "track" || func == "update" || func == "untrack"
            || func == "track_internal" || func == "update_internal" || func == "untrack_internal");
    }
}

#end
