package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

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
 * - Ensures delete/edit/toggle helpers receive an id instead of the entire
 *   params map without relying on app names.
 *
 * HOW
 * - Module-level pass. We first collect local function signatures
 *   (name→arity→first-parameter-name). Inside each `handle_event/3` clause we
 *   scan for calls where the first argument is the `params` binding and the
 *   last argument is the `socket` binding. If the callee is local and its first
 *   parameter is explicitly named `params`/`_params`, we skip (it expects a map);
 *   otherwise we replace the first argument with `Map.get(params, "id")`,
 *   coercing binary→integer.
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

  static function buildExtractId(paramsVar:String):ElixirAST {
    var get = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(paramsVar)), makeAST(EString("id")) ]));
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
    var hasIdHint = declared.exists('id') || hasIdSuffix(declared);
    var chosenFirstArg:ElixirAST = chooseFirstArgReplacement(paramsVar, declared);
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECall(target, fname, args) if (args != null && args.length >= 2):
          var lastArgIsSocket = switch (args[args.length - 1].def) { case EVar(v) if (v == socketVar): true; default: false; };
          var firstArgIsParams = switch (args[0].def) { case EVar(v) if (v == paramsVar): true; default: false; };
          var permittedByCallee = shouldRewriteByCallee(fname, args.length, sigs);
          if (permittedByCallee && hasIdHint && lastArgIsSocket && firstArgIsParams) {
            var newArgs = args.copy();
            newArgs[0] = chosenFirstArg;
            makeASTWithMeta(ECall(target, fname, newArgs), x.metadata, x.pos);
          } else x;
        case ERemoteCall(mod, fname, args) if (args != null && args.length >= 2):
          var lastArgIsSocket = switch (args[args.length - 1].def) { case EVar(v) if (v == socketVar): true; default: false; };
          var firstArgIsParams = switch (args[0].def) { case EVar(v) if (v == paramsVar): true; default: false; };
          var permittedByCallee = shouldRewriteByCallee(fname, args.length, sigs);
          if (permittedByCallee && hasIdHint && lastArgIsSocket && firstArgIsParams) {
            var newArgs = args.copy();
            newArgs[0] = chosenFirstArg;
            makeASTWithMeta(ERemoteCall(mod, fname, newArgs), x.metadata, x.pos);
          } else x;
        default:
          x;
      }
    });
  }

  static function hasIdSuffix(declared:Map<String,Bool>):Bool {
    for (k in declared.keys()) if (StringTools.endsWith(k, '_id')) return true; return false;
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

  // Decide rewrite permissibility by callee definition: if a local function with same name/arity exists and its first arg is explicitly named `params` or `_params`, skip rewrite; otherwise permit.
  static function shouldRewriteByCallee(fname:String, arity:Int, sigs:Map<String, Map<Int, Null<String>>>):Bool {
    if (sigs == null) return true; // no info → allow based on hasIdHint
    var byAr = sigs.get(fname);
    if (byAr == null) return true; // external/remote → allow based on hasIdHint
    var first = byAr.get(arity);
    if (first == null) return true; // unknown → allow based on hasIdHint
    // If callee explicitly names its first argument params/_params, we assume it expects a map → do not rewrite.
    return !(first == "params" || first == "_params");
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

  static inline function chooseFirstArgReplacement(paramsVar:String, declared:Map<String,Bool>):ElixirAST {
    // Prefer local `id`, else a declared `*_id`, else extract from params.
    if (declared.exists('id')) return makeAST(EVar('id'));
    var suffix = firstIdSuffixVar(declared);
    if (suffix != null) return makeAST(EVar(suffix));
    return buildExtractId(paramsVar);
  }

  static function firstIdSuffixVar(declared:Map<String,Bool>):Null<String> {
    var candidate:Null<String> = null;
    for (k in declared.keys()) if (StringTools.endsWith(k, '_id')) {
      if (candidate == null || k.length < candidate.length || (k.length == candidate.length && k < candidate)) candidate = k;
    }
    return candidate;
  }
}

#end
