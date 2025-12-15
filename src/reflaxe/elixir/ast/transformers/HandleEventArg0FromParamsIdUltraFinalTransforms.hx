package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.NameUtils;

/**
 * HandleEventArg0FromParamsIdUltraFinalTransforms
 *
 * WHAT
 * - Ultra-final safeguard for handle_event/3 wrappers: when a helper call uses
 *   `(params, ..., socket)` as arguments, rewrite the first arg to the `id`
 *   extracted from params (with binary→int conversion) if a local `id` was not
 *   already selected by earlier passes.
 *
 * WHY
 * - Ensures id-based helpers receive an id instead of the entire
 *   params map without relying on app names.
 *
 * HOW
 * - Module-level pass. We first collect local function signatures
 *   (name→arity→first-parameter-name). Inside each `handle_event/3` clause we
 *   scan for calls where the first argument is the `params` binding and the
 *   last argument is the `socket` binding. If the callee is local and its first
 *   parameter name is `id` or ends with `_id` (and is not explicitly
 *   `params`/`_params`), we replace the first argument with `Map.get(params, "<key>")`
 *   (using the parameter name as the key), coercing binary→integer. If a local
 *   variable for that id key is already bound earlier in the wrapper body, we
 *   reuse it instead of re-extracting.
 *
 * EXAMPLES
 * Haxe
 *   // inside LiveView
 *   function handle_event("delete", params, socket) {
 *     delete_todo(params, socket);
 *   }
 *
 * Elixir (before)
 *   def handle_event("delete", params, socket) do
 *     delete_todo(params, socket)
 *   end
 *
 * Elixir (after)
 *   def handle_event("delete", params, socket) do
 *     delete_todo((if Kernel.is_binary(Map.get(params, "id")), do: String.to_integer(Map.get(params, "id")), else: Map.get(params, "id"))), socket)
 *   end
 */
class HandleEventArg0FromParamsIdUltraFinalTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    // Work at module granularity so we can inspect local function signatures
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body):
          var sigs = collectLocalSigs(body);
          var out = rewriteInBody(body, sigs);
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        case EDefmodule(modName, doBlock):
          var stmts = switch (doBlock.def) { case EDo(s): s; case EBlock(blockStmts): blockStmts; default: []; };
          var blockSigs = collectLocalSigs(stmts);
          var rewrittenStmts = rewriteInBody(stmts, blockSigs);
          makeASTWithMeta(EDefmodule(modName, makeAST(EBlock(rewrittenStmts))), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3 && switch (args[0]) { case PLiteral({def: EString(_)}): true; default: false; };
  }
  static inline function secondArgVar(args:Array<EPattern>):String { return switch (args[1]) { case PVar(n): n; default: "params"; } }
  static inline function thirdArgVar(args:Array<EPattern>):String { return switch (args[2]) { case PVar(n): n; default: "socket"; } }

  static inline function needsInt(name:String):Bool return name == "id" || StringTools.endsWith(name, "_id");

  static function buildExtract(paramsVar:String, key:String):ElixirAST {
    var get = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(paramsVar)), makeAST(EString(key)) ]));
    if (!needsInt(key)) return get;
    var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ get ]));
    var toInt = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ get ]));
    return makeAST(EIf(isBin, toInt, get));
  }

  static function rewrite(body: ElixirAST, paramsVar:String, socketVar:String, sigs:Map<String, Map<Int, Null<String>>> = null): ElixirAST {
    // Collect declared names to decide if this wrapper likely binds an id/*_id
    var declared = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(e:ElixirAST) {
      if (e == null || e.def == null) return;
      switch (e.def) {
        case EMatch(p, _): collectPat(p, declared);
        case EBinary(Match, l, _): collectLhs(l, declared);
        default:
      }
    });
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECall(target, fname, args) if (target == null && args != null && args.length >= 2):
          var lastArgIsSocket = switch (args[args.length - 1].def) { case EVar(v) if (v == socketVar): true; default: false; };
          var firstArgIsParams = switch (args[0].def) { case EVar(v) if (v == paramsVar): true; default: false; };
          var expectedIdVar = expectedIdVarName(fname, args.length, sigs);
          if (expectedIdVar != null && lastArgIsSocket && firstArgIsParams) {
            var chosenFirstArg = chooseFirstArgReplacement(paramsVar, expectedIdVar, declared);
            var newArgs = args.copy();
            newArgs[0] = chosenFirstArg;
            makeASTWithMeta(ECall(target, fname, newArgs), x.metadata, x.pos);
          } else x;
        default:
          x;
      }
    });
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
    switch (lhs.def) { case EVar(n): out.set(n, true); case EBinary(Match, left, _): collectLhs(left, out); default: }
  }

  // Collect local function signatures (name/arity with first param names), encoded as a map name->list of arities
  static function collectLocalSigs(body:Array<ElixirAST>):Map<String, Map<Int, Null<String>>> {
    var m = new Map<String, Map<Int, Null<String>>>();
    for (s in body) switch (s.def) {
      case EDef(n, a, _, _) | EDefp(n, a, _, _):
        var ar = a != null ? a.length : 0;
        var firstName:Null<String> = null;
        if (a != null && a.length > 0) switch (a[0]) { case PVar(vn): firstName = vn; default: }
        var byAr = m.get(n);
        if (byAr == null) byAr = new Map<Int, Null<String>>();
        byAr.set(ar, firstName);
        m.set(n, byAr);
      default:
    }
    return m;
  }

  static function expectedIdVarName(fname:String, arity:Int, sigs:Map<String, Map<Int, Null<String>>>): Null<String> {
    if (sigs == null) return null;
    var byAr = sigs.get(fname);
    if (byAr == null) return null;
    var first = byAr.get(arity);
    if (first == null) return null;
    if (first == "params" || first == "_params") return null;
    var normalized = first;
    if (StringTools.startsWith(normalized, "_") && normalized.length > 1) normalized = normalized.substr(1);
    var key = NameUtils.toSnakeCase(normalized);
    return needsInt(key) ? normalized : null;
  }

  static function rewriteInBody(body:Array<ElixirAST>, sigs:Map<String, Map<Int, Null<String>>>):Array<ElixirAST> {
    var out:Array<ElixirAST> = [];
    for (s in body) switch (s.def) {
      case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
        var paramsVar = secondArgVar(args);
        var socketVar = thirdArgVar(args);
        out.push(makeASTWithMeta(EDef(name, args, guards, rewrite(body, paramsVar, socketVar, sigs)), s.metadata, s.pos));
      case EDefp(name, args, guards, body) if (isHandleEvent3(name, args)):
        var paramsVar = secondArgVar(args);
        var socketVar = thirdArgVar(args);
        out.push(makeASTWithMeta(EDefp(name, args, guards, rewrite(body, paramsVar, socketVar, sigs)), s.metadata, s.pos));
      default:
        out.push(s);
    }
    return out;
  }

  static inline function chooseFirstArgReplacement(paramsVar:String, expectedVar:String, declared:Map<String,Bool>):ElixirAST {
    if (expectedVar != null && declared.exists(expectedVar)) return makeAST(EVar(expectedVar));
    var key = NameUtils.toSnakeCase(expectedVar);
    if (declared.exists(key)) return makeAST(EVar(key));
    if (declared.exists('_' + key)) return makeAST(EVar('_' + key));
    return buildExtract(paramsVar, key);
  }
}

#end
