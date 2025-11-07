package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * LocalAssignUnusedUnderscoreGlobalFinalTransforms
 *
 * WHAT
 * - As an absolute-final cleanup, underscore binders of local assignments that
 *   are not referenced in any subsequent statement of the same block/do or fn
 *   body. Excludes binder name `socket`.
 */
  class LocalAssignUnusedUnderscoreGlobalFinalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      // Gate: skip inside LiveView modules to avoid renaming locals that are referenced
      // from interpolated strings and lifted closures in HEEx. LiveView modules are
      // marked with metadata.isLiveView by the annotation/builder pipeline.
      switch (n.def) {
        case EModule(_, _, _) | EDefmodule(_, _):
          if (n.metadata != null && (Reflect.field(n.metadata, "isLiveView") == true)) {
            return n; // Do not rewrite inside LiveView modules
          }
        default:
      }
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        case EFn(clauses):
          var newClauses = [];
          for (c in clauses) newClauses.push({args:c.args, guard:c.guard, body: pass(c.body)});
          makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var s1 = switch (s.def) {
        case EBinary(Match, {def: EVar(b)}, rhs) if (shouldUnderscore(b) && !usedLater(stmts, i+1, b)):
          makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b)), rhs), s.metadata, s.pos);
        case EMatch(PVar(b2), rhs2) if (shouldUnderscore(b2) && !usedLater(stmts, i+1, b2)):
          makeASTWithMeta(EMatch(PVar('_' + b2), rhs2), s.metadata, s.pos);
        default: s;
      }
      out.push(s1);
    }
    return out;
  }

  static function shouldUnderscore(name:String): Bool {
    // Only operate on names that are already intentional throwaways
    if (name == null || name.length == 0) return false;
    if (name.charAt(0) != '_') return false;
    // Exclude some common binders even if underscored (safety)
    return switch (name) {
      case "_socket" | "_conn" | "_children": false;
      default: true;
    }
  }

  static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
    var found = false;
    inline function containsInString(src:String, needle:String):Bool {
      if (src == null) return false;
      // quick check: must have interpolation marker
      if (src.indexOf("#{") < 0) return false;
      // conservative: substring match on needle inside string
      return src.indexOf(needle) >= 0;
    }
    function walk(n:ElixirAST):Void {
      if (found || n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v) if (v == name): found = true;
        case EString(s) if (containsInString(s, name)): found = true;
        case ERaw(code) if (containsInString(code, name)): found = true;
        case EBlock(ss): for (e in ss) walk(e);
        case EDo(ss2): for (e in ss2) walk(e);
        case EBinary(_, l, r): walk(l); walk(r);
        case EMatch(_, rhs): walk(rhs);
        case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
        case ECase(expr, cs): walk(expr); for (c in cs) walk(c.body);
        case ECall(t,_,args): if (t != null) walk(t); for (a in args) walk(a);
        case ERemoteCall(t2,_,args2): walk(t2); for (a in args2) walk(a);
        default:
      }
    }
    for (j in start...stmts.length) if (!found) walk(stmts[j]);
    return found;
  }
}

#end
