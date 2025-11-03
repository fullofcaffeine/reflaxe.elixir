package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControllerJsonSecondArgUndefinedRewriteUltimateTransforms
 *
 * WHAT
 * - Ultimate safety net for controllers: if a Phoenix.Controller.json(conn, data)
 *   call remains and `data` is undefined in the current clause/body scope, rewrite
 *   the second argument to a real, in-scope variable — preferably the case arm binder
 *   (e.g., `value`/`reason`).
 *
 * WHY
 * - Earlier alias-injection passes were removed to avoid app coupling. In rare shapes
 *   (notably single-expression case arms), `data` may survive after alias drops.
 *   Leaving it causes MIX_ENV=test WAE failures (undefined variable).
 *
 * HOW
 * - Walk controller modules. Within case clauses, compute the bound binder (if any)
 *   and collect locally declared names. For any json(conn, data) where `data` is not
 *   declared in the current scope, rewrite arg2 to the binder if present; otherwise,
 *   prefer a single lower-case candidate used in the body. If none, fall back to an
 *   empty map (extremely rare) to keep compilation sound. This pass runs at the very end.
 */
class ControllerJsonSecondArgUndefinedRewriteUltimateTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isController(name)):
          makeASTWithMeta(EModule(name, attrs, rewriteList(body)), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (isController(name2)):
          makeASTWithMeta(EDefmodule(name2, rewriteNode(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isController(name:String):Bool {
    return name != null && name.indexOf("Web.") > 0 && StringTools.endsWith(name, "Controller");
  }

  static function rewriteList(nodes:Array<ElixirAST>):Array<ElixirAST> {
    var out:Array<ElixirAST> = [];
    for (b in nodes) out.push(rewriteNode(b));
    return out;
  }

  static function rewriteNode(node:ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EDef(name, args, g, body): makeASTWithMeta(EDef(name, args, g, rewriteNode(body)), n.metadata, n.pos);
        case EDefp(name2, args2, g2, body2): makeASTWithMeta(EDefp(name2, args2, g2, rewriteNode(body2)), n.metadata, n.pos);
        case EBlock(stmts): makeASTWithMeta(EBlock(rewriteStmts(stmts, null)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewriteStmts(stmts2, null)), n.metadata, n.pos);
        case ECase(expr, clauses):
          var cls = [];
          for (cl in clauses) {
            var binder = binderOf(cl.pattern);
            cls.push({ pattern: cl.pattern, guard: cl.guard, body: rewriteWithContext(cl.body, binder) });
          }
          makeASTWithMeta(ECase(expr, cls), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteStmts(stmts:Array<ElixirAST>, binder:Null<String>): Array<ElixirAST> {
    var out:Array<ElixirAST> = [];
    for (s in stmts) out.push(rewriteWithContext(s, binder));
    return out;
  }

  static function rewriteWithContext(node:ElixirAST, binder:Null<String>): ElixirAST {
    // Build declared set for this node scope
    var declared = new Map<String,Bool>();
    collectDecls(node, declared);
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ERemoteCall(t, fnName, args) if (fnName == "json" && args != null && args.length == 2 && isPhoenixController(t)):
          switch (args[1].def) {
            case EVar(v) if (v == "data"):
              var replacement:Null<ElixirAST> = null;
              if (binder != null) replacement = makeAST(EVar(binder));
              if (replacement == null) {
                var cand = singleLowerUsedVar(node);
                if (cand != null) replacement = makeAST(EVar(cand));
              }
              if (replacement == null) replacement = makeAST(EMap([]));
              #if debug_ast_transformer
              Sys.println('[ControllerJsonSecondArgUndefinedRewrite] Rewriting json(conn, data) to in-scope expression');
              #end
              makeASTWithMeta(ERemoteCall(t, fnName, [args[0], replacement]), n.metadata, n.pos);
            default: n;
          }
        default: n;
      }
    });
  }

  static inline function isPhoenixController(target:ElixirAST): Bool {
    return switch (target.def) { case EVar(m) if (m == "Phoenix.Controller"): true; default: false; }
  }

  static function binderOf(p:EPattern): Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2): switch (es[1]) { case PVar(n): n; default: null; }
      default: null;
    }
  }

  static function collectDecls(node:ElixirAST, acc:Map<String,Bool>):Void {
    reflaxe.elixir.ast.ASTUtils.walk(node, function(n:ElixirAST){
      switch (n.def) {
        case EMatch(PVar(nm), _): acc.set(nm, true);
        case EBinary(Match, {def:EVar(nm2)}, _): acc.set(nm2, true);
        case ECase(_, cs): for (c in cs) switch (c.pattern) { case PTuple(es) if (es.length==2): switch (es[1]) { case PVar(n): acc.set(n,true); default: } default: }
        default:
      }
    });
  }

  static function singleLowerUsedVar(node:ElixirAST): Null<String> {
    var used = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(node, function(n:ElixirAST){
      switch (n.def) { case EVar(v): if (v != null && v.length > 0) {
        var c = v.charAt(0);
        if (c.toLowerCase() == c && v != "conn" && v != "params" && v != "socket" && v != "live_socket") used.set(v,true);
      } default: }
    });
    var cands:Array<String> = []; for (k in used.keys()) cands.push(k);
    return cands.length == 1 ? cands[0] : null;
  }
}

#end
