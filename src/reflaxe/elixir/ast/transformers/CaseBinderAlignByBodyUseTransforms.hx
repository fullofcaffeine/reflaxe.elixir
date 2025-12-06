package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseBinderAlignByBodyUseTransforms
 *
 * WHAT
 * - For any case clause with tuple pattern `{:tag, binder}` where `binder` is a PVar,
 *   if the body uses exactly one undefined lower-case variable name, rename the binder to
 *   that name. This is usage-driven and avoids app-specific heuristics.
 */
class CaseBinderAlignByBodyUseTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        // Only apply inside controller modules to avoid LiveView/socket false positives
        case EModule(name, attrs, body) if (isController(name)):
          var out = [for (b in body) applyInNode(b)];
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (isController(name2)):
          makeASTWithMeta(EDefmodule(name2, applyInNode(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isController(name:String):Bool {
    return name != null && name.indexOf("Web.") > 0 && StringTools.endsWith(name, "Controller");
  }

  static function applyInNode(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var env = namesFromPatterns(args);
          makeASTWithMeta(EDef(name, args, guards, applyInBody(body, env)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var env2 = namesFromPatterns(args2);
          makeASTWithMeta(EDefp(name2, args2, guards2, applyInBody(body2, env2)), n.metadata, n.pos);
        case ECase(expr, clauses):
          // no outer env; fall back to local-only declared
          var newClauses = [];
          for (c in clauses) newClauses.push(adjust(c, new Map<String,Bool>()));
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function applyInBody(b: ElixirAST, env:Map<String,Bool>): ElixirAST {
    return ElixirASTTransformer.transformNode(b, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var newClauses = [];
          for (c in clauses) newClauses.push(adjust(c, env));
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function namesFromPatterns(ps:Array<EPattern>): Map<String,Bool> {
    var m = new Map<String,Bool>();
    for (p in ps) switch (p) { case PVar(n): m.set(n,true); case PTuple(es): for (e in es) switch (e) { case PVar(n2): m.set(n2,true); default: } default: }
    return m;
  }

  static function adjust(c:{pattern:EPattern, guard:ElixirAST, body:ElixirAST}, env:Map<String,Bool>):{pattern:EPattern, guard:ElixirAST, body:ElixirAST} {
    var binder:Null<String> = switch (c.pattern) {
      case PTuple(es) if (es.length == 2): switch (es[1]) { case PVar(n): n; default: null; }
      default: null;
    };
    if (binder == null) return c;
    var baseHint:Null<String> = (binder.charAt(0) == "_") ? binder.substr(1) : binder;
    var used = collectUsed(c.body, baseHint);
    var declared = collectDeclared(c.pattern, c.body);
    // include env (function parameters like conn/params)
    for (k in env.keys()) declared.set(k, true);
    var undef:Array<String> = [];
    for (k in used.keys()) if (!declared.exists(k) && isLower(k)) undef.push(k);
    #if debug_ast_transformer
    // DEBUG: Sys.println('[CaseBinderAlignByBodyUse] binder=' + binder + ' used={' + keys(used).join(',') + '} declared={' + keys(declared).join(',') + '} undef={' + undef.join(',') + '}');
    #end
    if (undef.length == 1) {
      var newName = undef[0];
      // rename binder
      var newPat = switch (c.pattern) {
        case PTuple(es2) if (es2.length == 2): PTuple([es2[0], PVar(newName)]);
        default: c.pattern;
      };
      #if debug_ast_transformer
      #end
      return { pattern: newPat, guard: c.guard, body: c.body };
    }
    return c;
  }

  static function collectDeclared(p:EPattern, body:ElixirAST):Map<String,Bool> {
    var m = new Map<String,Bool>();
    switch (p) { case PVar(n): m.set(n,true); case PTuple(es): for (e in es) switch (e) { case PVar(n2): m.set(n2,true); default: } default: }
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST){
      switch (n.def) {
        case EMatch(PVar(nn), _): m.set(nn,true);
        case EBinary(Match, {def: EVar(nn2)}, _): m.set(nn2,true);
        default:
      }
    });
    return m;
  }
  static function collectUsed(body:ElixirAST, hint:Null<String>): Map<String,Bool> {
    var m = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n:ElixirAST){
      switch (n.def) {
        case EVar(v): m.set(v,true);
        case ERaw(s) if (hint != null && s != null):
          // Heuristic: mark hint as used if it appears as a token boundary in raw
          var pat = new EReg('(^|[^:A-Za-z0-9_])' + hint + '([^A-Za-z0-9_]|$)', "");
          if (pat.match(s)) m.set(hint, true);
        default:
      }
    });
    return m;
  }
  #if debug_ast_transformer
  static inline function keys(m:Map<String,Bool>):Array<String> {
    var a:Array<String> = [];
    for (k in m.keys()) a.push(k);
    return a;
  }
  #end
  static inline function isLower(s:String): Bool {
    if (s == null || s.length == 0) return false;
    var c = s.charAt(0);
    return c.toLowerCase() == c;
  }
}

#end
