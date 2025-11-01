package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * InlineUnderscoreTempUsedOnceTransforms
 *
 * WHAT
 * - Inlines simple underscore temp assignments when the temp is used exactly
 *   once in the immediately following expression in the same block.
 *
 * EXAMPLE
 *   _this = t.title
 *   String.downcase(_this)
 * becomes
 *   String.downcase(t.title)
 */
class InlineUnderscoreTempUsedOnceTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EBlock(stmts) if (stmts.length >= 2):
          var out:Array<ElixirAST> = [];
          var i = 0;
          while (i < stmts.length) {
            var s = stmts[i];
            switch (s.def) {
              case EMatch(PVar(tmp), rhs) if (isUnderscore(tmp) && i + 1 < stmts.length):
                var next = stmts[i+1];
                if (usedExactlyOnceAsVar(next, tmp)) {
                  var inlined = substituteVar(next, tmp, rhs);
                  out.push(inlined);
                  i += 2; // skip both
                  continue;
                } else {
                  out.push(s); i++;
                }
              case EBinary(Match, {def: EVar(tmp2)}, rhs2) if (isUnderscore(tmp2) && i + 1 < stmts.length):
                var next2 = stmts[i+1];
                if (usedExactlyOnceAsVar(next2, tmp2)) {
                  var inlined2 = substituteVar(next2, tmp2, rhs2);
                  out.push(inlined2); i += 2; continue;
                } else { out.push(s); i++; }
              default:
                out.push(s); i++;
            }
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isUnderscore(name:String):Bool {
    return name != null && name.length > 1 && name.charAt(0) == '_';
  }

  static function usedExactlyOnceAsVar(node:ElixirAST, name:String):Bool {
    var count = 0;
    function walk(n:ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v) if (v == name): count++;
        case EBinary(_, l, r): walk(l); walk(r);
        case EMatch(_, rhs): walk(rhs);
        case EBlock(ss): for (s in ss) walk(s);
        case EDo(ss2): for (s in ss2) walk(s);
        case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
        case ECase(expr, cs): walk(expr); for (c in cs) { if (c.guard != null) walk(c.guard); walk(c.body); }
        case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
        case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
        case EField(obj,_): walk(obj);
        case EAccess(obj2,key): walk(obj2); walk(key);
        default:
      }
    }
    walk(node);
    return count == 1;
  }

  static function substituteVar(node:ElixirAST, from:String, replacement:ElixirAST):ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EVar(v) if (v == from): replacement;
        default: n;
      }
    });
  }
}

#end

