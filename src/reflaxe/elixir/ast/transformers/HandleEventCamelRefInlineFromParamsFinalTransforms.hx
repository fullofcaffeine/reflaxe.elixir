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

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HandleEventCamelRefInlineFromParamsFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var pvar = paramsVar(args);
          var nb = inlineCamelRefs(body, pvar);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var paramsVarAlt = paramsVar(args2);
          var inlinedBodyAlt = inlineCamelRefs(body2, paramsVarAlt);
          makeASTWithMeta(EDefp(name2, args2, guards2, inlinedBodyAlt), n.metadata, n.pos);
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

  /**
   * Check if a variable name looks like an internal/intermediate variable rather than
   * a form field that should be extracted from params.
   *
   * Internal variables typically have names like:
   * - searchSocket, updatedSocket, resultSocket (socket variants)
   * - newSelected, currentlySelected (computed values)
   * - refreshedTodos, filteredItems (processed collections)
   *
   * Form fields typically have names like:
   * - id, title, description, name, email, query, tag, priority
   */
  static function isInternalVariable(name:String):Bool {
    // Check for common internal variable suffixes (case-insensitive check via lowercase)
    var lower = name.toLowerCase();
    // Socket-related
    if (StringTools.endsWith(lower, "socket")) return true;
    // Selection/state-related
    if (StringTools.endsWith(lower, "selected")) return true;
    // Processed data
    if (StringTools.startsWith(lower, "refreshed")) return true;
    if (StringTools.startsWith(lower, "filtered")) return true;
    if (StringTools.startsWith(lower, "updated")) return true;
    if (StringTools.startsWith(lower, "new") && lower.length > 3) return true; // "newX" but not "new"
    // Result/temp variables
    if (StringTools.endsWith(lower, "result")) return true;
    if (StringTools.startsWith(lower, "temp")) return true;
    if (StringTools.startsWith(lower, "tmp")) return true;
    return false;
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
          // Only convert to Map.get if variable is NOT declared in the body
          // Check both camelCase and snake_case versions to handle naming mismatches
          // Also skip internal variables that look like socket/state/computed values
          case EVar(v) if (isCamel(v) && !reserved(v) && !isInternalVariable(v) && !declared.exists(v) && !declared.exists(toSnake(v))):
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
