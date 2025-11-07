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
              case EBinary(Match, {def: EVar(tmpVar)}, rhsExpr) if (isUnderscore(tmpVar) && i + 1 < stmts.length):
                var nextStmt = stmts[i+1];
                if (usedExactlyOnceAsVar(nextStmt, tmpVar) || isSafeMultiUseInlineContext(nextStmt)) {
                  var inlined = substituteVar(nextStmt, tmpVar, rhsExpr);
                  out.push(inlined); i += 2; continue;
                } else { out.push(s); i++; }
              default:
                out.push(s); i++;
            }
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        // Also handle do-blocks (EDo) the same way
        case EDo(stmts) if (stmts.length >= 2):
          var output:Array<ElixirAST> = [];
          var index = 0;
          while (index < stmts.length) {
            var cur = stmts[index];
            switch (cur.def) {
              case EMatch(PVar(tmp), rhs) if (isUnderscore(tmp) && index + 1 < stmts.length):
                var next = stmts[index+1];
                if (usedExactlyOnceAsVar(next, tmp)) {
                  var inlined = substituteVar(next, tmp, rhs);
                  output.push(inlined);
                  index += 2; continue;
                } else { output.push(cur); index++; }
              case EBinary(Match, {def: EVar(tmpVar)}, rhsExpr) if (isUnderscore(tmpVar) && index + 1 < stmts.length):
                var nextStmt = stmts[index+1];
                if (usedExactlyOnceAsVar(nextStmt, tmpVar) || isSafeMultiUseInlineContext(nextStmt)) {
                  var inlined = substituteVar(nextStmt, tmpVar, rhsExpr);
                  output.push(inlined); index += 2; continue;
                } else { output.push(cur); index++; }
              default:
                output.push(cur); index++;
            }
          }
          makeASTWithMeta(EDo(output), n.metadata, n.pos);
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
        case EDo(statements): for (s in statements) walk(s);
        case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
        case ECase(expr, cs): walk(expr); for (c in cs) { if (c.guard != null) walk(c.guard); walk(c.body); }
        case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
        case ERemoteCall(targetExpr,_,argsList): walk(targetExpr); if (argsList != null) for (argNode in argsList) walk(argNode);
        case EField(obj,_): walk(obj);
        case EAccess(objectExpr,key): walk(objectExpr); walk(key);
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
