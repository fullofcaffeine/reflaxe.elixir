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
                if (usedExactlyOnceAsVar(next2, tmp2) || isSafeMultiUseInlineContext(next2)) {
                  var inlined2 = substituteVar(next2, tmp2, rhs2);
                  out.push(inlined2); i += 2; continue;
                } else { out.push(s); i++; }
              default:
                out.push(s); i++;
            }
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        // Also handle do-blocks (EDo) the same way
        case EDo(stmts) if (stmts.length >= 2):
          var out2:Array<ElixirAST> = [];
          var i2 = 0;
          while (i2 < stmts.length) {
            var s2 = stmts[i2];
            switch (s2.def) {
              case EMatch(PVar(tmp), rhs) if (isUnderscore(tmp) && i2 + 1 < stmts.length):
                var next = stmts[i2+1];
                if (usedExactlyOnceAsVar(next, tmp)) {
                  var inlined = substituteVar(next, tmp, rhs);
                  out2.push(inlined);
                  i2 += 2; continue;
                } else { out2.push(s2); i2++; }
              case EBinary(Match, {def: EVar(tmp2)}, rhs2) if (isUnderscore(tmp2) && i2 + 1 < stmts.length):
                var next2 = stmts[i2+1];
                if (usedExactlyOnceAsVar(next2, tmp2) || isSafeMultiUseInlineContext(next2)) {
                  var inlined2 = substituteVar(next2, tmp2, rhs2);
                  out2.push(inlined2); i2 += 2; continue;
                } else { out2.push(s2); i2++; }
              default:
                out2.push(s2); i2++;
            }
          }
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
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

  // Conservative fallback: allow inlining underscore temps even if referenced
  // multiple times when the next node is a pure expression context that we know
  // stays within a single argument or branch (e.g., case/cond, :binary.match, String.at).
  static function isSafeMultiUseInlineContext(node: ElixirAST): Bool {
    function argContainsSafe(n: ElixirAST): Bool {
      return switch (n.def) {
        case ECase(_, _) | ECond(_): true;
        case ERemoteCall(mod, fn, _):
          switch (mod.def) {
            case EVar(m) if (m == ":binary" && fn == "match"): true;
            case EVar(m2) if (m2 == "String" && (fn == "at" || fn == "upcase" || fn == "downcase")): true;
            default: false;
          }
        case EBinary(_, left, _):
          // If the left side is a case or :binary.match, treat as safe
          switch (left.def) {
            case ECase(_, _): true;
            case ERemoteCall(mod2, fn2, _):
              switch (mod2.def) { case EVar(mm) if (mm == ":binary" && fn2 == "match"): true; default: false; }
            default: false;
          }
        default: false;
      }
    }
    return switch (node.def) {
      case ECase(_, _) | ECond(_): true;
      case ERemoteCall(mod, fn, args):
        if (argContainsSafe(args != null && args.length > 0 ? args[0] : null)) return true; else false;
      case ECall(_, _, args):
        if (argContainsSafe(args != null && args.length > 0 ? args[0] : null)) return true; else false;
      default: false;
    }
  }
}

#end
