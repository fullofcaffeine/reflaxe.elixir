package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * UnderscoreTempInlineDowncaseTransforms
 *
 * WHAT
 * - Inlines simple underscore-temporary assignment immediately followed by
 *   a String.downcase call in the same block.
 *
 * WHY
 * - Eliminates "underscored variable _this is used" warnings in nested
 *   if/else branches by removing the temporary altogether.
 *
 * HOW
 * - For consecutive statements: `_x = rhs; String.downcase(_x)` →
 *   `String.downcase(rhs)`.
 * - Also handles ERaw nodes containing `String.downcase(_x)` (from __elixir__).
 */
class UnderscoreTempInlineDowncaseTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    var i = 0;
    while (i < stmts.length) {
      if (i + 1 < stmts.length) {
        switch (stmts[i].def) {
          case EBinary(Match, {def: EVar(tmp)}, rhs) if (tmp != null && tmp.length > 1 && tmp.charAt(0) == "_"):
            // Check if next statement uses this temp
            var inlined = tryInlineUsage(tmp, rhs, stmts[i+1]);
            if (inlined != null) {
              out.push(inlined);
              i += 2;
              continue;
            }
          case EMatch(PVar(tmp2), rhs2) if (tmp2 != null && tmp2.length > 1 && tmp2.charAt(0) == "_"):
            // Check if next statement uses this temp
            var inlined2 = tryInlineUsage(tmp2, rhs2, stmts[i+1]);
            if (inlined2 != null) {
              out.push(inlined2);
              i += 2;
              continue;
            }
          default:
        }
      }
      out.push(stmts[i]);
      i++;
    }
    return out;
  }

  /**
   * Try to inline the temp variable in the next statement.
   * Returns the inlined statement if successful, null otherwise.
   */
  static function tryInlineUsage(tmp:String, rhs:ElixirAST, next:ElixirAST):Null<ElixirAST> {
    if (next == null || next.def == null) return null;

    return switch (next.def) {
      // Original case: ERemoteCall with String.downcase
      case ERemoteCall({def: EVar("String")}, fnName, args) if (fnName == "downcase" && args != null && args.length == 1):
        switch (args[0].def) {
          case EVar(v) if (v == tmp):
            makeASTWithMeta(ERemoteCall(makeAST(EVar("String")), "downcase", [rhs]), next.metadata, next.pos);
          default: null;
        }

      // New case: ERaw containing String.downcase(_tmp)
      case ERaw(code) if (code != null && code.indexOf("String.downcase(") >= 0):
        var rhsStr = simpleASTToString(rhs);
        if (rhsStr != null) {
          var newCode = substituteInRaw(code, tmp, rhsStr);
          if (newCode != code) {
            makeASTWithMeta(ERaw(newCode), next.metadata, next.pos);
          } else {
            null;
          }
        } else {
          null;
        }

      default: null;
    };
  }

  /**
   * Convert simple AST to string for ERaw substitution.
   */
  static function simpleASTToString(ast:ElixirAST):Null<String> {
    if (ast == null || ast.def == null) return null;
    return switch (ast.def) {
      case EVar(name): name;
      case EField(obj, field):
        var objStr = simpleASTToString(obj);
        if (objStr != null) '${objStr}.${field}' else null;
      case EAtom(name): ':${name}';
      case EInteger(val): Std.string(val);
      case EFloat(val): Std.string(val);
      case EString(val): '"${val}"';
      case EBoolean(val): val ? "true" : "false";
      case ENil: "nil";
      default: null;
    };
  }

  /**
   * Substitute variable name in raw code with token boundary detection.
   */
  static function substituteInRaw(code:String, from:String, to:String):String {
    inline function isIdentChar(c:String):Bool {
      if (c == null || c.length == 0) return false;
      var ch = c.charCodeAt(0);
      return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
    }

    var result = new StringBuf();
    var idx = 0;
    var lastEnd = 0;

    while (idx < code.length) {
      var pos = code.indexOf(from, idx);
      if (pos == -1) break;

      var before = pos > 0 ? code.charAt(pos - 1) : "";
      var afterIdx = pos + from.length;
      var after = afterIdx < code.length ? code.charAt(afterIdx) : "";

      if (!isIdentChar(before) && !isIdentChar(after)) {
        result.add(code.substring(lastEnd, pos));
        result.add(to);
        lastEnd = afterIdx;
        idx = afterIdx;
      } else {
        idx = pos + 1;
      }
    }

    if (lastEnd > 0) {
      result.add(code.substring(lastEnd));
      return result.toString();
    }
    return code;
  }
}

#end
