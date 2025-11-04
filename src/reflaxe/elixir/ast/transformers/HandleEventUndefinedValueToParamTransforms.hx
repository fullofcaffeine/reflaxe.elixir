package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleEventUndefinedValueToParamTransforms
 *
 * WHAT
 * - In def/defp handle_event/3, if no local binding named `value` exists,
 *   rewrite any occurrences of the identifier `value` to the head payload
 *   binder (second argument), i.e., `params` or `_params`.
 *
 * WHY
 * - Prevents undefined variable errors when late passes reintroduce the
 *   bare identifier `value` in wrapper code (e.g., id conversion branches).
 *
 * HOW
 * - For each handle_event/3 function, collect declared names from LHS
 *   patterns and matches in the body. If `value` is not declared, walk
 *   the body and replace EVar("value") with EVar(paramVar).
 */
class HandleEventUndefinedValueToParamTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var paramVar = extractParamsVarName(args);
          var declared = new Map<String,Bool>();
          collectDecls(body, declared);
          if (!declared.exists("value")) {
            var nb = rewrite(body, paramVar);
            makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
          } else n;
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var paramVar2 = extractParamsVarName(args2);
          var declared2 = new Map<String,Bool>();
          collectDecls(body2, declared2);
          if (!declared2.exists("value")) {
            var nb2 = rewrite(body2, paramVar2);
            makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
          } else n;
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    if (name != "handle_event" || args == null || args.length != 3) return false;
    return switch (args[0]) { case PLiteral({def: EString(_)}): true; default: false; }
  }

  static inline function extractParamsVarName(args:Array<EPattern>):String {
    if (args == null || args.length < 2) return "params";
    return switch (args[1]) { case PVar(nm): nm; default: "params"; }
  }

  static function rewrite(body: ElixirAST, paramVar:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (v == "value"): makeASTWithMeta(EVar(paramVar), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function collectDecls(ast: ElixirAST, out: Map<String,Bool>): Void {
    ASTUtils.walk(ast, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EMatch(p, _): collectPattern(p, out);
        case EBinary(Match, l, _): collectLhs(l, out);
        case ECase(_, cs): for (c in cs) collectPattern(c.pattern, out);
        default:
      }
    });
  }

  static function collectPattern(p: EPattern, out: Map<String,Bool>): Void {
    switch (p) {
      case PVar(n): out.set(n, true);
      case PTuple(es) | PList(es): for (e in es) collectPattern(e, out);
      case PCons(h,t): collectPattern(h, out); collectPattern(t, out);
      case PMap(kvs): for (kv in kvs) collectPattern(kv.value, out);
      case PStruct(_, fs): for (f in fs) collectPattern(f.value, out);
      case PPin(inner): collectPattern(inner, out);
      default:
    }
  }

  static function collectLhs(lhs: ElixirAST, out: Map<String,Bool>): Void {
    switch (lhs.def) {
      case EVar(n): out.set(n, true);
      case EBinary(Match, l2, _): collectLhs(l2, out);
      default:
    }
  }
}

#end

