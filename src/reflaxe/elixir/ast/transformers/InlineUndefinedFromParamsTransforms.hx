package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * InlineUndefinedFromParamsTransforms
 *
 * WHAT
 * - For any def/defp with a params or _params argument, inline undefined lower-case
 *   local references as Map.get(paramsVar, snake_case(name)) with id/_id conversion.
 *
 * WHY
 * - Complements prefix-binding passes when code shape resists prefix insertion.
 */
class InlineUndefinedFromParamsTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
      return switch (node.def) {
        case EDef(name, args, guards, body):
          var pv = findParamsVar(args);
          if (pv == null) return node;
          var declared = new Map<String,Bool>(); collectDecls(body, declared);
          var nb = inlineUndeclared(body, declared, pv);
          makeASTWithMeta(EDef(name, args, guards, nb), node.metadata, node.pos);
        case EDefp(name, args, guards, body):
          var pv2 = findParamsVar(args);
          if (pv2 == null) return node;
          var declared2 = new Map<String,Bool>(); collectDecls(body, declared2);
          var nb2 = inlineUndeclared(body, declared2, pv2);
          makeASTWithMeta(EDefp(name, args, guards, nb2), node.metadata, node.pos);
        default:
          node;
      }
    });
  }

  static function findParamsVar(args:Array<EPattern>): Null<String> {
    if (args == null || args.length == 0) return null;
    for (a in args) switch (a) { case PVar(n): if (n == "params" || n == "_params") return n; default: }
    return null;
  }
  static inline function toSnake(s:String):String return reflaxe.elixir.ast.NameUtils.toSnakeCase(s);
  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "_params" || name == "event") return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c && c != '_';
  }
  static function isCamel(name:String):Bool {
    var result = false;
    if (name != null && name.length > 0) {
      var c0 = name.charAt(0);
      if (c0.toLowerCase() == c0) {
        var i = 1;
        while (i < name.length) {
          var ch = name.charAt(i);
          if (ch.toUpperCase() == ch && ch.toLowerCase() != ch) { result = true; break; }
          i++;
        }
      }
    }
    return result;
  }
  static function needsIntConversion(varName:String):Bool {
    return varName == "id" || StringTools.endsWith(varName, "_id");
  }
  static function buildExtract(varName:String, paramsVar:String):ElixirAST {
    var key = toSnake(varName);
    var get = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(paramsVar)), makeAST(EString(key)) ]));
    if (!needsIntConversion(varName)) return get;
    var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ get ]));
    var toInt = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ get ]));
    return makeAST(EIf(isBin, toInt, get));
  }
  static function inlineUndeclared(body: ElixirAST, declared: Map<String,Bool>, paramsVar:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EVar(v) if ((allow(v) || isCamel(v)) && !declared.exists(v)):
          #if sys Sys.println('[InlineFromParams] Inlining ' + v + ' from ' + paramsVar); #end
          buildExtract(v, paramsVar);
        default: n;
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
    switch (lhs.def) { case EVar(n): out.set(n, true); case EBinary(Match, l2, _): collectLhs(l2, out); default: }
  }
}

#end
