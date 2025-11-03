package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

class DebugControllerJsonArgsPass {
  public static function pass(ast: ElixirAST): ElixirAST {
    #if debug_controller_json
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isController(name)):
          Sys.println('[DebugControllerJson] Visiting ' + name);
          var out = [for (b in body) visit(b)];
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        default: n;
      }
    });
    #else
    return ast;
    #end
  }

  static inline function isController(name:String): Bool {
    return name != null && name.indexOf('Web.') > 0 && StringTools.endsWith(name, 'Controller');
  }

  static function visit(node:ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ERemoteCall(t, fnName, args) if (fnName == 'json' && args != null && args.length == 2):
          var arg2 = args[1];
          var kind = Std.string(arg2.def);
          Sys.println('[DebugControllerJson] json arg2 kind: ' + kind);
          n;
        default: n;
      }
    });
  }
}

#end

