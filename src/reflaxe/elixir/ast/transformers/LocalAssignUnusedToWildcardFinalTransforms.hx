package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalAssignUnusedToWildcardFinalTransforms
 *
 * WHAT
 * - In EBlock/EDo sequences, rewrites local assignments `name = expr` to
 *   `_ = expr` when `name` is not referenced in any subsequent statement of
 *   the same block. This matches snapshot style for effectful calls whose
 *   result is intentionally discarded.
 *
 * WHY
 * - Upstream transforms may preserve intermediate binders (e.g., step vars)
 *   even when unused. Wildcard assignment communicates intent and reduces
 *   noise while avoiding unused-variable warnings.
 *
 * HOW
 * - For each block/do, scan stmts and for each assignment at index i,
 *   check if `lhs` appears in stmts[i+1..]. If not, replace LHS with `_`.
 */
class LocalAssignUnusedToWildcardFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewriteSeq(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewriteSeq(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteSeq(stmts:Array<ElixirAST>): Array<ElixirAST> {
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      switch (s.def) {
        case EBinary(Match, {def: EVar(lhs)}, rhs):
          if ((lhs != null && lhs.length > 0 && lhs.charAt(0) == '_') && !isUsedLater(lhs, stmts, i + 1)) {
            out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("_"), s.metadata, s.pos), rhs), s.metadata, s.pos));
          } else {
            out.push(s);
          }
        case EMatch(PVar(lhs2), rhs2):
          if ((lhs2 != null && lhs2.length > 0 && lhs2.charAt(0) == '_') && !isUsedLater(lhs2, stmts, i + 1)) {
            out.push(makeASTWithMeta(EMatch(PVar("_"), rhs2), s.metadata, s.pos));
          } else {
            out.push(s);
          }
        default:
          out.push(s);
      }
    }
    return out;
  }

  static function isUsedLater(name:String, stmts:Array<ElixirAST>, start:Int): Bool {
    if (name == null || name.length == 0) return false;
    for (j in start...stmts.length) {
      var found = false;
      ElixirASTTransformer.transformNode(stmts[j], function(n: ElixirAST): ElixirAST {
        switch (n.def) {
          case EVar(v) if (v == name): found = true; return n;
          case EString(s): if (stringInterpolatesName(s, name)) { found = true; return n; } else return n;
          case ERaw(code): if (stringInterpolatesName(code, name)) { found = true; return n; } else return n;
          default: return n;
        }
      });
      if (found) return true;
    }
    return false;
  }

  static function stringInterpolatesName(s:String, name:String): Bool {
    if (s == null || name == null || name.length == 0) return false;
    var re = new EReg("\\#\\{([^}]*)\\}", "g");
    var pos = 0;
    while (re.matchSub(s, pos)) {
      var inner = re.matched(1);
      var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
      var tpos = 0;
      while (tok.matchSub(inner, tpos)) {
        if (tok.matched(0) == name) return true;
        tpos = tok.matchedPos().pos + tok.matchedPos().len;
      }
      pos = re.matchedPos().pos + re.matchedPos().len;
    }
    // Heuristic: IIFE interpolations may already be embedded as raw code strings
    // e.g., "#{(fn -> name end).()}". Detect "fn -> name end" inside the string.
    var iife = new EReg('fn\\s*->\\s*' + name + '\\s*end', "");
    if (iife.match(s)) return true;
    // Fallback boundary check for token presence in raw code
    var idx = s.indexOf(name);
    if (idx >= 0) {
      var isId = function(ch:String):Bool {
        if (ch == null || ch.length == 0) return false;
        var c = ch.charCodeAt(0);
        return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code) || c == '_'.code;
      };
      var leftOk = (idx == 0) || !isId(s.charAt(idx - 1));
      var rightOk = (idx + name.length >= s.length) || !isId(s.charAt(idx + name.length));
      if (leftOk && rightOk) return true;
    }
    return false;
  }
}

#end
