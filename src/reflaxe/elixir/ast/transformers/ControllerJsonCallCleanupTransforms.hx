package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControllerJsonCallCleanupTransforms
 *
 * WHAT
 * - In controller modules, clean sequences like:
 *     json = v; data = v; conn = v; Phoenix.Controller.json(conn, data)
 *   by removing the alias assignments and calling `Phoenix.Controller.json(conn, v)`.
 * - Also removes single `data = v` immediately before `Phoenix.Controller.json(conn, data)`.
 *
 * WHY
 * - Some late stages may introduce alias variables that trigger warnings and obscure intent.
 *   This pass restores the straightforward API call shape without app coupling.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ControllerJsonCallCleanupTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isController(name)):
          #if debug_ast_transformer
          #end
          var out = [for (b in body) cleanseDefs(b)];
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (isController(name2)):
          #if debug_ast_transformer
          #end
          makeASTWithMeta(EDefmodule(name2, cleanseDefs(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isController(name:String):Bool {
    return name != null && name.indexOf("Web.") > 0 && StringTools.endsWith(name, "Controller");
  }

  static function cleanseDefs(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EDef(fn, args, guards, body):
          makeASTWithMeta(EDef(fn, args, guards, cleanseBody(body)), n.metadata, n.pos);
        case EDefp(fn2, args2, guards2, body2):
          makeASTWithMeta(EDefp(fn2, args2, guards2, cleanseBody(body2)), n.metadata, n.pos);
        case ECase(expr, clauses):
          // Ensure we also cleanse bodies of any nested case arms inside function bodies
          var newClauses = [];
          for (cl in clauses) {
            var cleanedBody = cleanseBody(cl.body);
            var newPat = maybeRenameBinderFromBodyMapKeys(cl.pattern, cleanedBody);
            var effBinder:Null<String> = switch (newPat) { case PTuple(es) if (es.length==2): switch (es[1]) { case PVar(n): n; default: null; } default: null; };
            var finalBody = cleanedBody;
            if (effBinder != null) {
              finalBody = mapUndefinedVarsToBinder(finalBody, effBinder, defaultControllerEnv());
            }
            // No alias injection here; only structural cleanup
            finalBody = cleanseAliasInBody(finalBody);
            newClauses.push({ pattern: newPat, guard: cl.guard, body: finalBody });
          }
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function cleanseBody(b: ElixirAST): ElixirAST {
    return switch (b.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), b.metadata, b.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), b.metadata, b.pos);
      default: b;
    }
  }

  // Helper to create a tiny env map of common controller params
  static inline function defaultControllerEnv(): Map<String,Bool> {
    var m = new Map<String,Bool>();
    m.set("conn", true); m.set("params", true); m.set("socket", true); m.set("live_socket", true); m.set("liveSocket", true);
    return m;
  }

  static inline function isOkAtom(ast: ElixirAST): Bool {
    return switch (ast.def) { case EAtom(v): v == ":ok" || v == "ok"; default: false; }
  }

  static function maybeRenameBinderFromBodyMapKeys(pat: EPattern, body: ElixirAST): EPattern {
    // Only consider {:ok, binder} patterns
    var binder:Null<String> = null;
    var headOk = false;
    switch (pat) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) { case PLiteral(l) if (isOkAtom(l)): headOk = true; default: }
        switch (es[1]) { case PVar(nm): binder = nm; default: }
      default:
    }
    if (!headOk || binder == null) return pat;
    // Scan structured map values in Phoenix.Controller.json second argument
    var undefInMap = new Map<String,Bool>();
    // Build declared set from body (including env)
    var declared = new Map<String,Bool>();
    collectPatternDecls(pat, declared);
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x: ElixirAST) {
      switch (x.def) {
        case EMatch(p,_): collectPatternDecls(p, declared);
        case EBinary(Match, l,_): collectLhs(l, declared);
        default:
      }
    });
    declared.set("socket", true); declared.set("live_socket", true); declared.set("liveSocket", true); declared.set("conn", true); declared.set("params", true);
    // Find EMap pairs under Phoenix.Controller.json second arg and record undefined EVar names used as values
    ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
      switch (n.def) {
        case ERemoteCall(target, fnName, args) if (fnName == "json" && args != null && args.length == 2):
          switch (args[1].def) {
            case EMap(pairs):
              for (p in pairs) switch (p.value.def) { case EVar(vn): if (!declared.exists(vn)) undefInMap.set(vn,true); default: }
            default:
          }
        default:
      }
      return n;
    });
    var want:Null<String> = null;
    var cnt = 0; for (k in undefInMap.keys()) { want = k; cnt++; }
    if (cnt != 1) want = null;
    #if debug_ast_transformer
    var dbgBinder = binder == null ? "null" : binder;
    var dbgWant = want == null ? "null" : want;
    #end
    if (want != null && binder != want) {
      #if debug_ast_transformer
      #end
      return switch (pat) {
        case PTuple(es) if (es.length == 2): PTuple([es[0], PVar(want)]);
        default: pat;
      }
    }
    return pat;
  }

  // When a clause binds {:ok, binder} or {:error, binder} and the body references
  // an undefined lower-case var (often the intended result name), map those EVar
  // occurrences to the bound binder. This is a localized, shape-based repair.
  static function mapUndefinedVarsToBinder(body: ElixirAST, binder: String, env:Map<String,Bool>): ElixirAST {
    // Collect declared names within the body (LHS of assignments, inner patterns)
    var declared = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST){
      switch (n.def) {
        case EMatch(p, _): collectPatternDecls(p, declared);
        case EBinary(Match, l, _): collectLhs(l, declared);
        case ECase(_, cs): for (c in cs) collectPatternDecls(c.pattern, declared);
        default:
      }
    });
    for (k in env.keys()) declared.set(k,true);
    function rewriteUndefinedInMap(arg: ElixirAST, declared: Map<String,Bool>): ElixirAST {
      return ElixirASTTransformer.transformNode(arg, function(x:ElixirAST):ElixirAST {
        return switch (x.def) {
          case EMap(pairs):
            var npairs:Array<EMapPair> = [];
            for (p in pairs) {
              var v2 = p.value;
              switch (p.value.def) {
                case EVar(vname) if (vname != null && vname.length > 0):
                  var c = vname.charAt(0);
                  if (c.toLowerCase() == c && !declared.exists(vname) && vname != "socket" && vname != "live_socket" && vname != "liveSocket") {
                    v2 = makeAST(EVar(binder));
                  }
                default:
              }
              npairs.push({ key: p.key, value: v2 });
            }
            makeASTWithMeta(EMap(npairs), x.metadata, x.pos);
          default: x;
        }
      });
    }

    // Helper to rewrite Phoenix.Controller.json second argument maps
    function rewriteJsonCall(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ERemoteCall(target, fnName, args) if (fnName == "json" && args != null && args.length == 2):
          var newSecond = switch (args[1].def) {
            case EVar(vn) if (vn == "data"): makeAST(EVar(binder));
            default: rewriteUndefinedInMap(args[1], declared);
          };
          makeASTWithMeta(ERemoteCall(target, fnName, [args[0], newSecond]), n.metadata, n.pos);
        default: n;
      }
    }

    return ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EVar(v) if (v != null && v.length > 0):
          var c = v.charAt(0);
          if (c.toLowerCase() == c && !declared.exists(v) && v != "socket" && v != "live_socket" && v != "liveSocket") {
            #if debug_ast_transformer
            #end
            makeASTWithMeta(EVar(binder), n.metadata, n.pos);
          }
          else n;
        case ERemoteCall(_, _, _):
          rewriteJsonCall(n);
        default: n;
      }
    });
  }

  static function collectPatternDecls(p:EPattern, acc:Map<String,Bool>):Void {
    switch (p) {
      case PVar(n): acc.set(n,true);
      case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, acc);
      case PCons(h,t): collectPatternDecls(h, acc); collectPatternDecls(t, acc);
      case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, acc);
      case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, acc);
      case PPin(inner): collectPatternDecls(inner, acc);
      default:
    }
  }
  static function collectLhs(lhs: ElixirAST, acc:Map<String,Bool>):Void {
    switch (lhs.def) { case EVar(n): acc.set(n,true); case EBinary(Match, l2, r2): collectLhs(l2, acc); collectLhs(r2, acc); default: }
  }

  static function prefixBindUndefinedToBinder(body: ElixirAST, binder: String): ElixirAST {
    // Build declared and used sets
    var declared = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST){
      switch (n.def) {
        case EMatch(p, _): collectPatternDecls(p, declared);
        case EBinary(Match, l, _): collectLhs(l, declared);
        case ECase(_, cs): for (c in cs) collectPatternDecls(c.pattern, declared);
        default:
      }
    });
    declared.set("socket", true); declared.set("live_socket", true); declared.set("liveSocket", true); declared.set("conn", true); declared.set("params", true);
    var used = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST){ switch (n.def) { case EVar(v): used.set(v,true); default: }});
    var undef:Array<String> = [];
    for (k in used.keys()) {
      if (!declared.exists(k)) {
        var c = k.charAt(0);
        if (c.toLowerCase() == c && k != "socket" && k != "live_socket" && k != "liveSocket" && k != "conn" && k != "params") undef.push(k);
      }
    }
    if (undef.length == 0) return body;
    var assigns:Array<ElixirAST> = [];
    for (u in undef) assigns.push(makeAST(EMatch(PVar(u), makeAST(EVar(binder)))));
    return makeAST(EBlock(assigns.concat([body])));
  }

  static function cleanseAliasInBody(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(filterAlias(stmts)), body.metadata, body.pos);
      case EDo(stmts): makeASTWithMeta(EDo(filterAlias(stmts)), body.metadata, body.pos);
      default: body;
    }
  }

  static function filterAlias(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (s in stmts) {
      if (isAssignTo("json", s) || isAssignTo("data", s) || isAssignTo("conn", s)) {
        var rv = rhsVar(s);
        if (rv != null) continue; // drop alias
      }
      out.push(s);
    }
    return out;
  }

  static function isAssignTo(name:String, stmt:ElixirAST): Bool {
    return switch (stmt.def) {
      case EBinary(Match, {def: EVar(nm)}, _): nm == name;
      case EMatch(PVar(nm2), _): nm2 == name;
      default: false;
    }
  }
  static function rhsVar(stmt:ElixirAST): Null<String> {
    return switch (stmt.def) {
      case EBinary(Match, _, {def: EVar(v)}): v;
      case EMatch(_, {def: EVar(v2)}): v2;
      default: null;
    }
  }
  static function isJsonCall(e: ElixirAST): Bool {
    return switch (e.def) {
      case ERemoteCall(target, fnName, args):
        if (fnName != "json" || args == null || args.length != 2) return false;
        switch (target.def) { case EVar(m) if (m == "Phoenix.Controller"): true; default: false; }
      default: false;
    }
  }
  static function rewrite(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    var i = 0;
    while (i < stmts.length) {
      // Drop trivial alias-chains proactively
      if (isAssignTo("json", stmts[i]) || isAssignTo("data", stmts[i]) || isAssignTo("conn", stmts[i])) {
        var rv0 = rhsVar(stmts[i]);
        // Only drop if RHS is a simple var (aliasing), not a function call
        if (rv0 != null) { i++; continue; }
      }
      if (isJsonCall(stmts[i])) {
        // scan backwards to drop preceding alias chain
        var callIdx = i;
        var k = i - 1;
        var rhs:Null<String> = null;
        while (k >= 0 && (isAssignTo("json", stmts[k]) || isAssignTo("data", stmts[k]) || isAssignTo("conn", stmts[k]))) {
          var rv = rhsVar(stmts[k]);
          if (rv != null) rhs = rv; // prefer the last seen
          k--;
        }
        // Emit statements up to k
        var j = out.length; // current output length
        // out already has stmts[0..i-1] mirrored; we need to remove tail alias block
        // Remove any trailing alias entries we might have pushed
        while (j > 0 && (isAssignTo("json", out[j-1]) || isAssignTo("data", out[j-1]) || isAssignTo("conn", out[j-1]))) {
          out.pop(); j--;
        }
        // Rewrite call if we found RHS
        var call = stmts[i];
        if (rhs != null) {
          #if debug_ast_transformer
          #end
          call = ElixirASTTransformer.transformNode(call, function(n:ElixirAST): ElixirAST {
            return switch (n.def) {
              case ERemoteCall(t, fnName, args) if (fnName == "json" && args.length == 2):
                makeASTWithMeta(ERemoteCall(t, fnName, [args[0], makeAST(EVar(rhs))]), n.metadata, n.pos);
              default: n;
            }
          });
        }
        out.push(call);
        i++;
        continue;
      }
      out.push(stmts[i]); i++;
    }
    return out;
  }
}

#end
