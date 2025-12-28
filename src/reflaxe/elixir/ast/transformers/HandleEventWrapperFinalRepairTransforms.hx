package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventWrapperFinalRepairTransforms
 *
 * WHAT
 * - Ultra-final safety net for LiveView handle_event/3 wrappers that ensures:
 *   1) Local helper calls use (params, socket) instead of (socket, socket)
 *   2) Any remaining undefined lower-case locals used in the body are inlined from params
 *      via Map.get with id/_id integer conversion when binary.
 *
 * WHY
 * - Earlier synthesis passes may produce wrappers that accidentally pass socket
 *   twice or lose a preceding param bind due to subsequent hygiene.
 * - This pass is shape-only and target-agnostic; it never depends on app names.
 *
 * HOW
 * - For EDef/EDefp named "handle_event" with 3 args ["<string>", paramsVar, socketVar]:
 *   - Walk the body, repairing ECall helper invocations whose first argument equals socketVar
 *     and last argument equals socketVar by rewriting the first argument to paramsVar.
 *   - Inline any remaining undefined lower-case EVar(v) from paramsVar.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HandleEventWrapperFinalRepairTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var pvar = secondArgVar(args);
          var svar = thirdArgVar(args);
          var repaired = repairBody(body, pvar, svar);
          makeASTWithMeta(EDef(name, args, guards, repaired), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var paramsVarAlt = secondArgVar(args2);
          var socketVarAlt = thirdArgVar(args2);
          var repairedAlt = repairBody(body2, paramsVarAlt, socketVarAlt);
          makeASTWithMeta(EDefp(name2, args2, guards2, repairedAlt), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    if (name != "handle_event" || args == null || args.length != 3) return false;
    return switch (args[0]) { case PLiteral({def: EString(_)}): true; default: false; };
  }

  static inline function secondArgVar(args:Array<EPattern>):String {
    return switch (args[1]) { case PVar(n): n; default: "params"; };
  }
  static inline function thirdArgVar(args:Array<EPattern>):String {
    return switch (args[2]) { case PVar(n): n; default: "socket"; };
  }

  static inline function toSnake(s:String):String return reflaxe.elixir.ast.NameUtils.toSnakeCase(s);
  static inline function needsInt(name:String):Bool return name == "id" || StringTools.endsWith(name, "_id");

  static function buildExtract(varName:String, paramsVar:String):ElixirAST {
    var key = toSnake(varName);
    var get = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(paramsVar)), makeAST(EString(key)) ]));
    if (!needsInt(varName)) return get;
    var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ get ]));
    var toInt = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ get ]));
    return makeAST(EIf(isBin, toInt, get));
  }

  static function repairBody(body: ElixirAST, paramsVar:String, socketVar:String): ElixirAST {
    // Collect locals that were extracted from params earlier in the function
    var paramLocals:Map<String,Bool> = collectParamLocals(body, paramsVar);
    // Helper 1: repair helper call arg ordering (params,socket) vs (socket,socket)
    function repairCalls(n: ElixirAST): ElixirAST {
      return ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
        return switch (x.def) {
          case ECall(target, fname, args) if (args != null && args.length >= 2):
            var a0IsSocket = switch (args[0].def) { case EVar(v) if (v == socketVar): true; default: false; };
            var lastIsSocket = switch (args[args.length - 1].def) { case EVar(v2) if (v2 == socketVar): true; default: false; };
            if (a0IsSocket && lastIsSocket) {
              var newArgs = args.copy();
              newArgs[0] = makeAST(EVar(paramsVar));
              makeASTWithMeta(ECall(target, fname, newArgs), x.metadata, x.pos);
            } else if (lastIsSocket) {
              // Prefer using a previously extracted local or an existing id/*_id over passing the whole params map
              var a0IsParams = switch (args[0].def) { case EVar(vp) if (vp == paramsVar): true; default: false; };
              if (a0IsParams) {
                var newArgs2 = args.copy();
                var replaced = false;
                // Heuristic A: prefer declared 'id' or '*_id' variable in the function body
                var declaredBody = new Map<String,Bool>();
                reflaxe.elixir.ast.ASTUtils.walk(body, function(nn:ElixirAST){ switch (nn.def) { case EMatch(p,_): collectPat(p, declaredBody); case EBinary(Match, l,_): collectLhs(l, declaredBody); default: } });
                var preferred:Null<String> = null;
                if (declaredBody.exists('id')) preferred = 'id';
                else for (k in declaredBody.keys()) if (StringTools.endsWith(k, '_id')) { preferred = k; break; }
                if (preferred != null) {
                  newArgs2[0] = makeAST(EVar(preferred));
                  replaced = true;
                } else if (paramLocals != null) {
                  // Heuristic B: single extracted param-local
                  var candidates = [for (k in paramLocals.keys()) k];
                  if (candidates.length == 1) { newArgs2[0] = makeAST(EVar(candidates[0])); replaced = true; }
                }
                if (replaced) {
                  makeASTWithMeta(ECall(target, fname, newArgs2), x.metadata, x.pos);
                } else {
                  // If first arg is already params, leave it - function expects full params map
                  // Only do id extraction for functions that clearly expect an id-like value
                  x;
                }
              } else x;
            } else x;
          case ERemoteCall(mod, fname2, args2) if (args2 != null && args2.length >= 2):
            var a0IsSocket2 = switch (args2[0].def) { case EVar(v3) if (v3 == socketVar): true; default: false; };
            var lastIsSocket2 = switch (args2[args2.length - 1].def) { case EVar(v4) if (v4 == socketVar): true; default: false; };
            if (a0IsSocket2 && lastIsSocket2) {
              var newArgs2 = args2.copy();
              newArgs2[0] = makeAST(EVar(paramsVar));
              makeASTWithMeta(ERemoteCall(mod, fname2, newArgs2), x.metadata, x.pos);
            } else if (lastIsSocket2) {
              var a0IsParams2 = switch (args2[0].def) { case EVar(vp2) if (vp2 == paramsVar): true; default: false; };
              if (a0IsParams2) {
                var newArgs3 = args2.copy();
                var replaced2 = false;
                var declaredBody2 = new Map<String,Bool>();
                reflaxe.elixir.ast.ASTUtils.walk(body, function(nn2:ElixirAST){ switch (nn2.def) { case EMatch(p2,_): collectPat(p2, declaredBody2); case EBinary(Match, l2,_): collectLhs(l2, declaredBody2); default: } });
                var preferred2:Null<String> = null;
                if (declaredBody2.exists('id')) preferred2 = 'id';
                else for (k2 in declaredBody2.keys()) if (StringTools.endsWith(k2, '_id')) { preferred2 = k2; break; }
                if (preferred2 != null) { newArgs3[0] = makeAST(EVar(preferred2)); replaced2 = true; }
                else if (paramLocals != null) {
                  var candidates2 = [for (k in paramLocals.keys()) k];
                  if (candidates2.length == 1) { newArgs3[0] = makeAST(EVar(candidates2[0])); replaced2 = true; }
                }
                if (replaced2) {
                  makeASTWithMeta(ERemoteCall(mod, fname2, newArgs3), x.metadata, x.pos);
                } else {
                  // If first arg is already params, leave it - function expects full params map
                  // Only do id extraction for functions that clearly expect an id-like value
                  x;
                }
              } else x;
            } else x;
          default: x;
        }
      });
    }

    // Helper 1b: upgrade wildcard Map.get(param, "key") assigns to named snake_case variable binds
    function upgradeWildcardMapGets(n: ElixirAST): ElixirAST {
      return ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
        return switch (x.def) {
          case EBinary(Match, {def: EVar("_")}, rhs):
            var key = extractMapGetKey(rhs);
            if (key != null) {
              makeASTWithMeta(EBinary(Match, makeAST(EVar(key)), rhs), x.metadata, x.pos);
            } else x;
          case EMatch(PVar("_"), rhs2):
            var key2 = extractMapGetKey(rhs2);
            if (key2 != null) {
              makeASTWithMeta(EBinary(Match, makeAST(EVar(key2)), rhs2), x.metadata, x.pos);
            } else x;
          default: x;
        }
      });
    }

    // Helper 2: inline remaining undefined locals from params
    function inlineUndeclared(n: ElixirAST): ElixirAST {
      // Collect declared names in scope (simple, conservative)
      var declared = new Map<String,Bool>();
      reflaxe.elixir.ast.ASTUtils.walk(n, function(y: ElixirAST) {
        if (y == null || y.def == null) return;
        switch (y.def) {
          case EMatch(p, _): collectPat(p, declared);
          case EBinary(Match, l, _): collectLhs(l, declared);
          default:
        }
      });
      return ElixirASTTransformer.transformNode(n, function(y: ElixirAST): ElixirAST {
        return switch (y.def) {
          case EVar(v) if (allow(v) && !declared.exists(v)):
            buildExtract(v, paramsVar);
          default: y;
        }
      });
    }

    var step1 = repairCalls(body);
    var step1b = upgradeWildcardMapGets(step1);
    var step2 = inlineUndeclared(step1b);
    // Prefix-bind any remaining undefined locals referenced anywhere in the wrapper (incl. strings/raw)
    var declared = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(step2, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EMatch(p, _): collectPat(p, declared);
        case EBinary(Match, l, _): collectLhs(l, declared);
        default:
      }
    });
    declared.set(paramsVar, true); declared.set(socketVar, true);
    var used = collectAllUsed(step2);
    #if debug_transforms
    var declList = [for (k in declared.keys()) k].join(',');
    // DEBUG: Sys.println('[HandleEventWrapperFinal] used={' + used.join(',') + '}');
    #end
    var missing:Array<String> = [];
    // Check both exact name AND snake_case version to handle camelCase/snake_case naming mismatches
    // (e.g., searchSocket used but search_socket declared)
    for (u in used) {
        var snake = toSnake(u);
        if (!declared.exists(u) && !declared.exists(snake) && allow(u)) missing.push(u);
    }
    if (missing.length == 0) return step2;
    var prefix = [for (v in missing) makeAST(EBinary(Match, makeAST(EVar(v)), buildExtract(v, paramsVar)))];
    return switch (step2.def) {
      case EBlock(sts): makeASTWithMeta(EBlock(prefix.concat(sts)), step2.metadata, step2.pos);
      case EDo(sts2): makeASTWithMeta(EDo(prefix.concat(sts2)), step2.metadata, step2.pos);
      default: makeASTWithMeta(EBlock(prefix.concat([step2])), step2.metadata, step2.pos);
    }
  }

  static function collectParamLocals(body: ElixirAST, paramsVar:String): Map<String,Bool> {
    var m = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EBinary(Match, {def: EVar(lhs)}, rhs):
          if (rhsLooksLikeMapGet(rhs, paramsVar)) m.set(lhs, true);
        case EMatch(PVar(lhs2), rhs2):
          if (rhsLooksLikeMapGet(rhs2, paramsVar)) m.set(lhs2, true);
        default:
      }
    });
    return m;
  }
  static function rhsLooksLikeMapGet(rhs: ElixirAST, paramsVar:String): Bool {
    return switch (rhs.def) {
      case ERemoteCall(mod, name, args) if (name == "get" && args != null && args.length >= 2):
        switch (mod.def) { case EVar(m) if (m == "Map"): true; default: false; }
      case ECall(target, name2, args2) if (name2 == "get" && args2 != null && args2.length >= 2):
        switch (target.def) { case EVar(m2) if (m2 == "Map"): true; default: false; }
      default: false;
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

  static function collectAllUsed(ast: ElixirAST): Array<String> {
    var names = new Map<String,Bool>();
    ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      if (n == null || n.def == null) return n;
      switch (n.def) {
        case EVar(v): if (allow(v)) names.set(v, true);
        case EString(s):
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
        case ERaw(code):
          if (code != null) {
            var tok2 = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
            var p2 = 0;
            while (tok2.matchSub(code, p2)) {
              var id2 = tok2.matched(0);
              if (allow(id2)) names.set(id2, true);
              p2 = tok2.matchedPos().pos + tok2.matchedPos().len;
            }
          }
        default:
      }
      return n;
    });
    // Fallback: scan the printed body text for interpolation identifiers if nothing was found
    if (!names.iterator().hasNext()) {
      try {
        var printed = reflaxe.elixir.ast.ElixirASTPrinter.print(ast, 0);
        var block2 = new EReg("\\#\\{([^}]*)\\}", "g");
        var pos2 = 0;
        while (block2.matchSub(printed, pos2)) {
          var inner2 = block2.matched(1);
          var tok3 = new EReg("[A-Za-z_][A-Za-z0-9_]*", "gi");
          var tpos2 = 0;
          while (tok3.matchSub(inner2, tpos2)) {
            var id3 = tok3.matched(0);
            if (allow(id3)) names.set(id3, true);
            tpos2 = tok3.matchedPos().pos + tok3.matchedPos().len;
          }
          pos2 = block2.matchedPos().pos + block2.matchedPos().len;
        }
      } catch (e) {}
    }
    return [for (k in names.keys()) k];
  }

  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "_params" || name == "event") return false;
    // Skip internal/intermediate variables that should NOT be extracted from params
    if (isInternalVariable(name)) return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c;
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
