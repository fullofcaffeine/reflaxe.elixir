package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WebJsonSecondArgRewriteFinalTransforms
 *
 * WHAT
 * - Ultimate safety: inside Web.* modules, rewrite Phoenix.Controller.json(conn, data|json)
 *   to use an actually-declared local candidate in the surrounding body, preferring
 *   case binder (value/reason) or a single declared lower-case var (e.g., `value`).
 *
 * HOW
 * - Deep-walk bodies. For each json/2 call, look upward to the nearest enclosing
 *   ECase clause (if any) and extract its binder when the tag is :ok or :error.
 *   Otherwise, scan the enclosing body for declared names and pick the single
 *   lower-case candidate among {value, user, changeset}. If found, rewrite arg2.

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class WebJsonSecondArgRewriteFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isWeb(name)):
          makeASTWithMeta(EModule(name, attrs, rewriteList(body)), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (isWeb(name2)):
          makeASTWithMeta(EDefmodule(name2, rewriteNode(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isWeb(name:String):Bool {
    return name != null && name.indexOf("Web.") > 0;
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
        case EBlock(stmts): makeASTWithMeta(EBlock(rewriteStmts(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewriteStmts(stmts2)), n.metadata, n.pos);
        case ECase(expr, clauses):
          var cls = [];
          for (cl in clauses) cls.push({ pattern: cl.pattern, guard: cl.guard, body: rewriteWithBinder(cl.body, binderOf(cl.pattern)) });
          makeASTWithMeta(ECase(expr, cls), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteWithBinder(body:ElixirAST, binder:Null<String>): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ERemoteCall(t, fnName, args) if (fnName == "json" && args != null && args.length == 2 && isPhoenixController(t)):
          var cand = pickCandidate(body, binder);
          if (cand != null && isAliasName(args[1])) makeASTWithMeta(ERemoteCall(t, fnName, [args[0], makeAST(EVar(cand))]), n.metadata, n.pos) else n;
        default: n;
      }
    });
  }

  static function isPhoenixController(target:ElixirAST): Bool {
    return switch (target.def) { case EVar(m) if (m == "Phoenix.Controller"): true; default: false; }
  }
  static function isAliasName(arg:ElixirAST): Bool {
    return switch (arg.def) { case EVar(v) if (v == "data" || v == "json"): true; default: false; }
  }

  static function rewriteStmts(stmts:Array<ElixirAST>):Array<ElixirAST> {
    var out:Array<ElixirAST> = [];
    for (s in stmts) out.push(rewriteNode(s));
    return out;
  }

  static function binderOf(p:EPattern): Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2): switch (es[1]) { case PVar(n): n; default: null; }
      default: null;
    }
  }

  static function pickCandidate(body:ElixirAST, binder:Null<String>): Null<String> {
    // Highest priority: clause binder if present
    if (binder != null) return binder;
    // Otherwise, prefer common names present in body
    var declared = new Map<String,Bool>();
    collectDecls(body, declared);
    inline function has(n:String):Bool return declared.exists(n);
    if (has("value")) return "value";
    if (has("user")) return "user";
    if (has("changeset")) return "changeset";
    return null;
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
}

#end

