package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer; // transformNode

/**
 * LiveViewTransforms
 *
 * WHAT
 * - LiveView-specific shaping passes that keep ElixirASTTransformer thin.
 * - Implements: liveViewHandlerArgShapingPass
 *
 * WHY
 * - Keep framework-specific logic modular and maintainable per AGENTS directives.
 * - Ensure handle_event signatures are idiomatic (event, params, socket) to enable
 *   downstream param aliasing passes.
 *
 * HOW
 * - For modules with metadata.isLiveView, scan defs and when encountering handle_event/2
 *   where the second arg looks like a socket, insert a middle `params` argument.
 */
class LiveViewTransforms {
    public static function liveViewHandlerArgShapingPass(ast: ElixirAST): ElixirAST {
        inline function isSocketLikeName(n:String):Bool return n == "socket" || n == "presenceSocket" || n == "presence_socket";
        function moduleLooksLiveView(body:ElixirAST, meta:Dynamic):Bool {
            if (meta != null && Reflect.hasField(meta, "isLiveView") && Reflect.field(meta, "isLiveView") == true) return true;
            var found = false;
            ElixirASTTransformer.transformNode(body, function(n){
                if (found) return n;
                switch (n.def) {
                    case EUse(mod, _): if (mod == "Phoenix.LiveView") found = true;
                    default:
                }
                return n;
            });
            return found;
        }
        function insertParamsInArgs(args:Array<EPattern>):Array<EPattern> {
            if (args == null || args.length != 2) return args;
            var a0 = args[0], a1 = args[1];
            var a1Name:Null<String> = switch (a1) { case PVar(n): n; default: null; };
            if (a1Name != null && isSocketLikeName(a1Name)) {
                return [a0, PVar("params"), a1];
            }
            return args;
        }
        function transformBody(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EBlock(stmts): makeAST(EBlock([for (s in stmts) transformBody(s)]));
                case EDef(name, args, guard, body) if (name == "handle_event"):
                    var newArgs = insertParamsInArgs(args);
                    makeASTWithMeta(EDef(name, newArgs, guard, body), n.metadata, n.pos);
                default: n;
            };
        }
        return ElixirASTTransformer.transformNode(ast, function(node) {
            return switch (node.def) {
                case EDefmodule(name, body) if (moduleLooksLiveView(body, node.metadata)):
                    makeASTWithMeta(EDefmodule(name, transformBody(body)), node.metadata, node.pos);
                case EModule(name, attrs, exprs) if (moduleLooksLiveView(makeAST(EBlock(exprs)), node.metadata)):
                    var b = transformBody(makeAST(EBlock(exprs)));
                    switch (b.def) { case EBlock(st): makeASTWithMeta(EModule(name, attrs, st), node.metadata, node.pos); default: node; }
                default: node;
            };
        });
    }
}

#end
