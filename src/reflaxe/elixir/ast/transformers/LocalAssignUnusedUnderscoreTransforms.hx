package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalAssignUnusedUnderscoreTransforms
 *
 * WHAT
 * - For block/do bodies, underscore local assignment binders that are not
 *   referenced in any subsequent statement of the same block.
 *
 * WHY
 * - Silences warnings like "variable `x` is unused" while keeping the
 *   assignment expression semantics intact (returns RHS).
 */
class LocalAssignUnusedUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts):
          makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(stmts2):
          makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var s1 = switch (s.def) {
        case EMatch(PVar(b), rhs) if (startsWithUnderscore(b) && !usedLater(stmts, i+1, b)):
          makeASTWithMeta(EMatch(PVar('_' + b), rhs), s.metadata, s.pos);
        case EBinary(Match, {def: EVar(b2)}, rhs2) if (startsWithUnderscore(b2) && !usedLater(stmts, i+1, b2)):
          makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b2)), rhs2), s.metadata, s.pos);
        default:
          s;
      }
      out.push(s1);
    }
    return out;
  }

  static inline function startsWithUnderscore(name:String):Bool {
    return name != null && name.length > 0 && name.charAt(0) == '_';
  }

  static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
    var found = false;
    for (j in start...stmts.length) if (!found) {
      // AST walk for EVar occurrences
      reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(x:ElixirAST){
        switch (x.def) { case EVar(v) if (v == name): found = true; default: }
      });
      // Interpolation and ERaw token scan
      if (!found) {
        scanStringsAndRaw(stmts[j], name, function(){ found = true; });
      }
    }
    return found;
  }

  static inline function scanStringsAndRaw(n: ElixirAST, target:String, hit: Void->Void):Void {
    function visit(x:ElixirAST):Void {
      if (x == null || x.def == null) return;
      switch (x.def) {
        case EString(s) if (s != null):
          var i = 0;
          while (i < s.length) {
            var idx = s.indexOf("#{", i);
            if (idx == -1) break;
            var j = s.indexOf('}', idx + 2);
            if (j == -1) break;
            var inner = s.substr(idx + 2, j - (idx + 2));
            if (inner.indexOf(target) != -1) { hit(); return; }
            i = j + 1;
          }
        case ERaw(code) if (code != null):
          if (code.indexOf(target) != -1) { hit(); return; }
        case EBlock(ss): for (y in ss) visit(y);
        case EIf(c,t,e): visit(c); visit(t); if (e != null) visit(e);
        case ECase(expr, cs): visit(expr); for (c in cs) visit(c.body);
        case EBinary(_, l, r): visit(l); visit(r);
        case EMatch(_, rhs): visit(rhs);
        case ECall(t,_,as): if (t != null) visit(t); if (as != null) for (a in as) visit(a);
        case ERemoteCall(t2,_,as2): visit(t2); if (as2 != null) for (a in as2) visit(a);
        default:
      }
    }
    visit(n);
  }
}

#end
