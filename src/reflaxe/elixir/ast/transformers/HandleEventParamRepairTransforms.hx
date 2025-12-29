package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleEventParamRepairTransforms
 *
 * WHAT
 * - Repairs handle_event/3 clauses by:
 *   1) Converting discarded param fetches `_ = Map.get(params, "key")` into
 *      variable binds when the body uses a camelCase/local var whose snake_case
 *      matches "key" (e.g., sortBy → "sort_by").
 *   2) Inserting missing binds for any remaining undefined locals used in the body.
 *
 * WHY
 * - Some earlier passes may discard Map.get results or omit binds. This pass
 *   deterministically aligns extraction with actual body usage without app coupling.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HandleEventParamRepairTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
      return switch (node.def) {
        case EModule(name, attrs, body):
          var outMod:Array<ElixirAST> = [];
          for (s in body) outMod.push(transformPass(s));
          makeASTWithMeta(EModule(name, attrs, outMod), node.metadata, node.pos);
        case EDefmodule(modName, doBlock):
          var stmts = switch (doBlock.def) { case EDo(s): s; case EBlock(s2): s2; default: [];} ;
          var out2:Array<ElixirAST> = [];
          for (s in stmts) out2.push(transformPass(s));
          makeASTWithMeta(EDefmodule(modName, makeAST(EBlock(out2))), node.metadata, node.pos);
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var paramVar = extractParamsVarName(args);
          var nb = repair(body, paramVar);
          makeASTWithMeta(EDef(name, args, guards, nb), node.metadata, node.pos);
        case EDef(nameAny, argsAny, _, _):
          #if debug_transforms
          if (nameAny == "handle_event") {
            var kinds = [];
            if (argsAny != null) for (a in argsAny) kinds.push(reflaxe.elixir.util.EnumReflection.enumConstructor(a));
          }
          #end
          node;
        case EDefp(name, args, guards, body) if (isHandleEvent3(name, args)):
          var paramVar2 = extractParamsVarName(args);
          var nb2 = repair(body, paramVar2);
          makeASTWithMeta(EDefp(name, args, guards, nb2), node.metadata, node.pos);
        case EDefp(nameAny2, argsAny2, _, _):
          #if debug_transforms
          if (nameAny2 == "handle_event") {
            var kinds2 = [];
            if (argsAny2 != null) for (a2 in argsAny2) kinds2.push(reflaxe.elixir.util.EnumReflection.enumConstructor(a2));
          }
          #end
          node;
        default:
          node;
      }
    });
  }

  static function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    if (name != "handle_event" || args == null || args.length != 3) return false;
    return switch (args[0]) { case PLiteral({def: EString(_)}): true; default: false; }
  }

  static inline function toSnake(s:String):String {
    return reflaxe.elixir.ast.NameUtils.toSnakeCase(s);
  }

  static function buildExtract(varName:String, paramVar:String):ElixirAST {
    if (varName == "params") return makeAST(EVar(paramVar));
    var key = toSnake(varName);
    var get = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(paramVar)), makeAST(EString(key)) ]));
    if (varName == "id" || StringTools.endsWith(varName, "_id")) {
      var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ get ]));
      var toInt = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ get ]));
      return makeAST(EIf(isBin, toInt, get));
    }
    return get;
  }

  static function extractParamsVarName(args:Array<EPattern>):String {
    if (args == null || args.length < 2) return "params";
    return switch (args[1]) { case PVar(n): n; default: "params"; }
  }

  static function repair(body: ElixirAST, paramsVar:String): ElixirAST {
    // Gather body-used and declared names
    var declared = new Map<String,Bool>();
    collectDecls(body, declared);
    var used = collectUsed(body);
    declared.set("params", true); declared.set("socket", true);

    // First pass: convert discarded Map.get binds to named locals when body needs them,
    // applied recursively across nested blocks/fns.
    function rewriteUnderscoreAssign(node: ElixirAST, need: Map<String,Bool>): ElixirAST {
      return switch (node.def) {
        case EBinary(Match, {def: EVar("_")}, rhs):
          var key = extractMapGetKey(rhs);
          if (key != null) {
            var chosen:Null<String> = null;
            for (u in need.keys()) if (toSnake(u) == key) { chosen = u; break; }
            if (chosen != null) {
              return makeASTWithMeta(EBinary(Match, makeAST(EVar(chosen)), rhs), node.metadata, node.pos);
            } else {
              // Fallback: upgrade wildcard bind to a named snake_case variable derived from the key
              // This allows later VarNameNormalization to rewrite camelCase references to the bound snake_case
              return makeASTWithMeta(EBinary(Match, makeAST(EVar(key)), rhs), node.metadata, node.pos);
            }
          }
          node;
        case EMatch(PVar("_"), rhs2):
          var key2 = extractMapGetKey(rhs2);
          if (key2 != null) {
            var chosen2:Null<String> = null;
            for (u in need.keys()) if (toSnake(u) == key2) { chosen2 = u; break; }
            if (chosen2 != null) {
              return makeASTWithMeta(EBinary(Match, makeAST(EVar(chosen2)), rhs2), node.metadata, node.pos);
            } else {
              return makeASTWithMeta(EBinary(Match, makeAST(EVar(key2)), rhs2), node.metadata, node.pos);
            }
          }
          node;
        default:
          node;
      }
    }

    // Compute needs
    var need = new Map<String,Bool>();
    for (u in used.keys()) if (!declared.exists(u) && allow(u)) need.set(u, true);
    #if debug_transforms
    var needList = [for (k in need.keys()) k].join(',');
    #end

    // Apply the underscore->named repair throughout the entire body tree
    var repairedBody = ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
      // visibility: log discarded Map.get keys as we traverse
      switch (n.def) {
        case EBinary(Match, {def: EVar("_")}, rhsD):
          var k = extractMapGetKey(rhsD);
          #if debug_ast_transformer
          if (k != null) {
            // DEBUG: Sys.println('[HandleEventRepair] seen _ = Map.get(..., ' + k + ')');
          }
          #end
        case EMatch(PVar("_"), rhsD2):
          var k2 = extractMapGetKey(rhsD2);
          #if debug_ast_transformer
          if (k2 != null) {
            // DEBUG: Sys.println('[HandleEventRepair] seen _ <- Map.get(..., ' + k2 + ')');
          }
          #end
        default:
      }
      return rewriteUnderscoreAssign(n, need);
    });

    // Recompute declared after rewrite
    declared = new Map<String,Bool>();
    collectDecls(repairedBody, declared);
    declared.set("params", true); declared.set("socket", true);

    // Second pass: for remaining undefined locals, prepend extraction binds
    var finalUsed = collectUsed(repairedBody);
    var missing:Array<String> = [];
    for (u in finalUsed.keys()) if (!declared.exists(u) && allow(u)) missing.push(u);
    if (missing.length == 0) return repairedBody;
    var prefix = [for (v in missing) makeAST(EBinary(Match, makeAST(EVar(v)), buildExtract(v, paramsVar)))];
    return switch (repairedBody.def) {
      case EBlock(sts): makeASTWithMeta(EBlock(prefix.concat(sts)), body.metadata, body.pos);
      case EDo(sts2): makeASTWithMeta(EDo(prefix.concat(sts2)), body.metadata, body.pos);
      default: makeASTWithMeta(EBlock(prefix.concat([repairedBody])), body.metadata, body.pos);
    }
  }

  static function extractMapGetKey(expr: ElixirAST): Null<String> {
    return switch (expr.def) {
      case ERemoteCall(mod, name, args):
        var isMap = switch (mod.def) { case EVar(m): m == "Map"; default: false; };
        if (isMap && name == "get" && args != null && args.length >= 2)
          switch (args[1].def) { case EString(s): s; default: null; } else null;
      case ECall(target, funcName, args2):
        var isMapGet = (funcName == "get") && (target != null) && switch (target.def) { case EVar(m2): m2 == "Map"; default: false; };
        if (isMapGet && args2 != null && args2.length >= 2)
          switch (args2[1].def) { case EString(s2): s2; default: null; } else null;
      default: null;
    }
  }

  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "event" || name == "live_socket") return false;
    // Skip internal/intermediate variables that should NOT be extracted from params
    if (isInternalVariable(name)) return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c && c != '_';
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
    if (name == null || name.length == 0) return false;
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

  static function collectUsed(ast: ElixirAST): Map<String,Bool> {
    var names = new Map<String,Bool>();
    ASTUtils.walk(ast, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v): names.set(v, true);
        case EString(s):
          try {
            var block = new EReg("\\#\\{([^}]*)\\}", "g");
            var pos = 0;
            while (block.matchSub(s, pos)) {
              var inner = block.matched(1);
              var tok = new EReg("[a-z_][a-z0-9_]*", "gi");
              var tpos = 0;
              while (tok.matchSub(inner, tpos)) {
                var id = tok.matched(0);
                if (allow(id)) names.set(id, true);
                tpos = tok.matchedPos().pos + tok.matchedPos().len;
              }
              pos = block.matchedPos().pos + block.matchedPos().len;
            }
          } catch (e) {}
        default:
      }
    });
    return names;
  }
}

#end
