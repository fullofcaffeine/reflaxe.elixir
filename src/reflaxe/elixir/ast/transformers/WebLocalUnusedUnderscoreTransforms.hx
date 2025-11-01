package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WebLocalUnusedUnderscoreTransforms
 *
 * WHAT
 * - In modules under <App>Web.*, underscore local assignment binders that are
 *   not referenced later in the same body. This removes Phoenix compile warnings
 *   without changing behavior (RHS is preserved).
 *
 * WHY
 * - LiveView and Controller code often bind intermediate locals (data/json/etc.).
 *   When not used later, Elixir warns. We fix shape-based, not by names.
 */
class WebLocalUnusedUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isWeb(name)):
          var out = [for (b in body) applyToDefs(b)];
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (isWeb(name2)):
          makeASTWithMeta(EDefmodule(name2, applyToDefs(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isWeb(name:String):Bool {
    if (name == null) return false;
    var isWeb = name.indexOf("Web.") > 0;
    // Never touch Presence modules
    if (name.indexOf("Web.Presence") > 0 || StringTools.endsWith(name, ".Presence")) return false;
    return isWeb;
  }

  static function applyToDefs(node:ElixirAST):ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EDef(fn, args, guards, body):
          makeASTWithMeta(EDef(fn, args, guards, underscoreUnused(body)), n.metadata, n.pos);
        case EDefp(fn2, args2, guards2, body2):
          makeASTWithMeta(EDefp(fn2, args2, guards2, underscoreUnused(body2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function underscoreUnused(body:ElixirAST):ElixirAST {
    return switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), body.metadata, body.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), body.metadata, body.pos);
      default: body;
    }
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var s1 = switch (s.def) {
        case EMatch(PVar(b), rhs) if (!usedLater(stmts, i+1, b)):
          makeASTWithMeta(EMatch(PVar('_' + b), rhs), s.metadata, s.pos);
        case EBinary(Match, {def: EVar(b2)}, rhs2) if (!usedLater(stmts, i+1, b2)):
          makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b2)), rhs2), s.metadata, s.pos);
        case ECase(expr, clauses):
          var nc = [];
          for (cl in clauses) nc.push({ pattern: cl.pattern, guard: cl.guard, body: underscoreUnused(cl.body) });
          makeASTWithMeta(ECase(expr, nc), s.metadata, s.pos);
        default:
          s;
      }
      out.push(s1);
    }
    return out;
  }

  static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
    var found = false;
    function scan(n: ElixirAST): Void {
      if (found || n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v) if (v == name): found = true;
        case EBinary(_, l, r): scan(l); scan(r);
        case EMatch(_, rhs): scan(rhs);
        case EBlock(ss): for (s in ss) scan(s);
        case EDo(ss2): for (s in ss2) scan(s);
        case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
        case ECase(expr, clauses):
          scan(expr);
          for (cl in clauses) { if (cl.guard != null) scan(cl.guard); scan(cl.body); }
        case EWith(clauses, doBlock, elseBlock):
          for (wc in clauses) scan(wc.expr);
          scan(doBlock);
          if (elseBlock != null) scan(elseBlock);
        case ECall(t,_,as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
        case ERemoteCall(t2,_,as2): scan(t2); if (as2 != null) for (a2 in as2) scan(a2);
        case EField(obj,_): scan(obj);
        case EAccess(obj2,key): scan(obj2); scan(key);
        case EKeywordList(pairs): for (p in pairs) scan(p.value);
        case EMap(pairs): for (p in pairs) { scan(p.key); scan(p.value); }
        case EStructUpdate(base, fs): scan(base); for (f in fs) scan(f.value);
        case ETuple(es) | EList(es): for (e in es) scan(e);
        case EFn(clauses): for (cl in clauses) { if (cl.guard != null) scan(cl.guard); scan(cl.body); }
        default:
      }
    }
    for (j in start...stmts.length) if (!found) scan(stmts[j]);
    return found;
  }
}

#end
