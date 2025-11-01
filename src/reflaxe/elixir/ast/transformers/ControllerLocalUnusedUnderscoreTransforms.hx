package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControllerLocalUnusedUnderscoreTransforms
 *
 * WHAT
 * - In Phoenix Controller modules, underscore local assignment binders that are
 *   not referenced later in the same function body. This silences warnings like
 *   "variable \"data\" is unused", without changing behavior.
 *
 * SCOPE
 * - Modules detected as Controllers by metadata (AnnotationTransforms) or by
 *   module name ending in "Controller" under Web namespace.
 */
class ControllerLocalUnusedUnderscoreTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (isControllerModule(n, name)):
                    var out:Array<ElixirAST> = [];
                    for (b in body) out.push(applyToDefs(b));
                    makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
                case EDefmodule(modName, doBlock) if (isControllerDoBlock(n, doBlock)):
                    makeASTWithMeta(EDefmodule(modName, applyToDefs(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function applyToDefs(node:ElixirAST):ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, underscoreUnused(body)), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2):
                    makeASTWithMeta(EDefp(name2, args2, guards2, underscoreUnused(body2)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function underscoreUnused(body:ElixirAST):ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    var s1 = switch (s.def) {
                        case EMatch(PVar(b), rhs) if (!usedLater(stmts, i+1, b)):
                            makeASTWithMeta(EMatch(PVar('_' + b), rhs), s.metadata, s.pos);
                        case EBinary(Match, left, right):
                            switch (left.def) {
                                case EVar(b2) if (!usedLater(stmts, i+1, b2)):
                                    makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b2)), right), s.metadata, s.pos);
                                default: s;
                            }
                        default:
                            s;
                    };
                    out.push(s1);
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }

    static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
        var found = false;
        for (j in start...stmts.length) if (!found) {
            reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(x:ElixirAST){
                switch (x.def) { case EVar(v) if (v == name): found = true; default: }
            });
        }
        return found;
    }

    static inline function isControllerModule(node:ElixirAST, name:String):Bool {
        if (node.metadata?.isPhoenixWeb == true && node.metadata?.phoenixContext == PhoenixContext.Controller) return true;
        return name != null && name.indexOf("Web.") >= 0 && StringTools.endsWith(name, "Controller");
    }

    static inline function isControllerDoBlock(node:ElixirAST, doBlock:ElixirAST):Bool {
        // Rely on bubbled metadata when available
        return node.metadata?.phoenixContext == PhoenixContext.Controller;
    }
}

#end

