package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * MountSessionExtractCleanupTransforms
 *
 * WHAT
 * - Removes redundant assignments of the form `session = Map.get(params, "session")`
 *   inside Phoenix LiveView mount/3 when the second argument is already the
 *   `session` map provided by Phoenix.
 *
 * WHY
 * - Some earlier generic extract-from-params rewrites can introduce a pointless
 *   reassignment from `_params` to `session`, which then forces uses of `_params`
 *   and triggers warnings ("underscored variable `_params` is used after being set").
 *   Using the real `session` argument is idiomatic and warning-free.
 *
 * HOW
 * - For `def mount(arg0, session, socket)`, scans the body EBlock and drops any
 *   top-level statement that matches:
 *     session = Map.get(<arg0>, "session")
 * - Purely shape-based, no app-specific names beyond Phoenix mount signature.
 */
class MountSessionExtractCleanupTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "mount" && args != null && args.length >= 3):
                    // Ensure the second arg is a PVar("session") to apply cleanup
                    switch (args[1]) {
                        case PVar(sess) if (sess == "session"):
                            var arg0Name = switch (args[0]) { case PVar(p0): p0; default: null; };
                            var nb = cleanup(body, arg0Name, sess);
                            makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }

    static function cleanup(body: ElixirAST, paramsName: Null<String>, sessionName:String): ElixirAST {
        if (paramsName == null) return body;
        return switch (body.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                for (s in stmts) {
                    var drop = false;
                    switch (s.def) {
                        case EMatch(PVar(lhs), rhs) if (lhs == sessionName):
                            drop = isSessionGetFromParams(rhs, paramsName);
                        case EBinary(Match, left, right):
                            switch (left.def) {
                                case EVar(lhs2) if (lhs2 == sessionName):
                                    drop = isSessionGetFromParams(right, paramsName);
                                default:
                            }
                        default:
                    }
                    if (!drop) out.push(s);
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            case EDo(stmtsDo):
                var outDo:Array<ElixirAST> = [];
                for (s in stmtsDo) {
                    var drop = false;
                    switch (s.def) {
                        case EMatch(PVar(lhs), rhs) if (lhs == sessionName):
                            drop = isSessionGetFromParams(rhs, paramsName);
                        case EBinary(Match, left, right):
                            switch (left.def) {
                                case EVar(lhs2) if (lhs2 == sessionName):
                                    drop = isSessionGetFromParams(right, paramsName);
                                default:
                            }
                        default:
                    }
                    if (!drop) outDo.push(s);
                }
                makeASTWithMeta(EDo(outDo), body.metadata, body.pos);
            default:
                body;
        }
    }

    static function sameIgnoringUnderscore(a:String, b:String):Bool {
        if (a == b) return true;
        if (a != null && b != null) {
            if (a.length > 1 && a.charAt(0) == '_' && a.substr(1) == b) return true;
            if (b.length > 1 && b.charAt(0) == '_' && b.substr(1) == a) return true;
        }
        return false;
    }

    static function isSessionGetFromParams(expr: ElixirAST, paramsName: String): Bool {
        return switch (expr.def) {
            case ERemoteCall({def: EVar(mod)}, fn, [arg0, {def: EString(key)}]) if (mod == "Map" && fn == "get" && key == "session"):
                switch (arg0.def) { case EVar(v) if (sameIgnoringUnderscore(v, paramsName)): true; default: false; }
            default: false;
        }
    }
}

#end
