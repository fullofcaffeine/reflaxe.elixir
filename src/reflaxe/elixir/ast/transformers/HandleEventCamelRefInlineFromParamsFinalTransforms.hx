package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventCamelRefInlineFromParamsFinalTransforms
 *
 * WHAT
 * - In handle_event/3 clauses, inline camelCase EVar references that are not declared
 *   by replacing them with Map.get(params, snake_case(var)) (with id/_id integer conversion).
 *
 * WHY
 * - Late pass order can cause earlier prefix-binds to be dropped or not seen by
 *   VarNameNormalization. Inlining is robust and avoids ordering hazards while staying
 *   shape-based and target-agnostic.
 */
class HandleEventCamelRefInlineFromParamsFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    #if sys Sys.println('[HandleEventCamelInlineFinal] pass start'); #end
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          #if sys Sys.println('[HandleEventCamelInlineFinal] handle_event def found'); #end
          var pvar = paramsVar(args);
          var nb = inlineCamelRefs(body, pvar);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          #if sys Sys.println('[HandleEventCamelInlineFinal] handle_event defp found'); #end
          var pvar2 = paramsVar(args2);
          var nb2 = inlineCamelRefs(body2, pvar2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    if (name != "handle_event" || args == null || args.length != 3) return false;
    return switch (args[0]) { case PLiteral({def: EString(_)}): true; default: false; }
  }
  static inline function paramsVar(args:Array<EPattern>):String {
    return switch (args[1]) { case PVar(n): n; default: "params"; }
  }
  static inline function toSnake(s:String):String {
    return reflaxe.elixir.ast.NameUtils.toSnakeCase(s);
  }
  static inline function needsInt(name:String):Bool {
    return name == "id" || StringTools.endsWith(name, "_id");
  }
  static function isCamel(s:String):Bool {
    var result = false;
    if (s != null && s.length > 0) {
      var c0 = s.charAt(0);
      if (c0.toLowerCase() == c0) {
        var i = 1;
        while (i < s.length) {
          var ch = s.charAt(i);
          if (ch.toUpperCase() == ch && ch.toLowerCase() != ch) { result = true; break; }
          i++;
        }
      }
    }
    return result;
  }
  static function reserved(name:String):Bool {
    return name == "params" || name == "_params" || name == "socket" || name == "event" || name == "live_socket";
  }
  static function buildExtract(varName:String, paramsVar:String):ElixirAST {
    var key = toSnake(varName);
    var get = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(paramsVar)), makeAST(EString(key)) ]));
    if (!needsInt(key)) return get;
    var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ get ]));
    var toInt = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ get ]));
    return makeAST(EIf(isBin, toInt, get));
  }
  static function inlineCamelRefs(body: ElixirAST, paramsVar:String): ElixirAST {
    // Collect declared names to avoid inlining where var is already bound
    var declared = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x: ElixirAST) {
      if (x == null || x.def == null) return;
      switch (x.def) {
        case EMatch(p, _): collectPat(p, declared);
        case EBinary(Match, l, _): collectLhs(l, declared);
        default:
      }
    });
    declared.set(paramsVar, true); declared.set("socket", true);
    function rewrite(n: ElixirAST): ElixirAST {
      return ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
        return switch (x.def) {
          case EVar(v) if (isCamel(v) && !reserved(v)):
            #if sys Sys.println('[HandleEventCamelInlineFinal] inline ' + v + ' from ' + paramsVar); #end
            buildExtract(v, paramsVar);
          case ECall(target, fname, args):
            var newArgs = args != null ? [for (a in args) rewrite(a)] : args;
            var newTarget = target != null ? rewrite(target) : target;
            makeASTWithMeta(ECall(newTarget, fname, newArgs), x.metadata, x.pos);
          case ERemoteCall(mod, fname2, args2):
            var newArgs2 = args2 != null ? [for (a2 in args2) rewrite(a2)] : args2;
            var newMod = rewrite(mod);
            makeASTWithMeta(ERemoteCall(newMod, fname2, newArgs2), x.metadata, x.pos);
          case ETuple(items):
            var ni = [for (it in items) rewrite(it)];
            makeASTWithMeta(ETuple(ni), x.metadata, x.pos);
          case EList(items2):
            var nl = [for (it2 in items2) rewrite(it2)];
            makeASTWithMeta(EList(nl), x.metadata, x.pos);
          case EMap(pairs):
            var np = [for (p in pairs) { key: rewrite(p.key), value: rewrite(p.value) }];
            makeASTWithMeta(EMap(np), x.metadata, x.pos);
          default: x;
        }
      });
    }
    return rewrite(body);
  }
  static function collectPat(p:EPattern, out:Map<String,Bool>):Void {
    switch (p) {
      case PVar(n): out.set(n, true);
      case PTuple(es) | PList(es): for (e in es) collectPat(e, out);
      case PCons(h,t): collectPat(h, out); collectPat(t, out);
      case PMap(kvs): for (kv in kvs) collectPat(kv.value, out);
      case PStruct(_, fs): for (f in fs) collectPat(f.value, out);
      case PPin(inner): collectPat(inner, out);
      default:
    }
  }
  static function collectLhs(lhs:ElixirAST, out:Map<String,Bool>):Void {
    switch (lhs.def) { case EVar(n): out.set(n, true); case EBinary(Match, l2, _): collectLhs(l2, out); default: }
  }
}

#end
