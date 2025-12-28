package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
#if debug_inline_underscore
import Type;
#end

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

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class InlineUnderscoreTempUsedOnceTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    #if debug_inline_underscore
    // DISABLED: trace('[InlineUnderscore] === PASS INVOKED ===');
    #end
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EBlock(stmts) if (stmts.length >= 2):
          #if debug_inline_underscore
          // DISABLED: trace('[InlineUnderscore] Found EBlock with ${stmts.length} statements');
          for (si in 0...stmts.length) {
            var st = stmts[si];
            if (st != null && st.def != null) {
              // DISABLED: trace('[InlineUnderscore]   stmt[$si]: ${Type.enumConstructor(st.def)}');
              switch (st.def) {
                case EMatch(pattern, _):
                  // DISABLED: trace('[InlineUnderscore]     pattern: ${Type.enumConstructor(pattern)}');
                  switch (pattern) {
                    case PVar(vn): trace('[InlineUnderscore]       PVar name: "$vn", isUnderscore: ${isUnderscore(vn)}');
                    default:
                  }
                default:
              }
            }
          }
          #end
          var out:Array<ElixirAST> = [];
          var i = 0;
          while (i < stmts.length) {
            var s = stmts[i];
            switch (s.def) {
              case EMatch(PVar(tmp), rhs) if (isUnderscore(tmp) && i + 1 < stmts.length):
                #if debug_inline_underscore
                // DISABLED: trace('[InlineUnderscore] Found underscore EMatch: $tmp');
                #end
                var next = stmts[i+1];
                if (usedExactlyOnceAsVar(next, tmp)) {
                  #if debug_inline_underscore
                  // DISABLED: trace('[InlineUnderscore] ✅ INLINING $tmp - used exactly once');
                  #end
                  var inlined = substituteVar(next, tmp, rhs);
                  out.push(inlined);
                  i += 2; // skip both
                  continue;
                } else {
                  #if debug_inline_underscore
                  // DISABLED: trace('[InlineUnderscore] ❌ NOT inlining $tmp - NOT used exactly once');
                  #end
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

    // Helper to check if character is an identifier character
    inline function isIdentChar(c:String):Bool {
      if (c == null || c.length == 0) return false;
      var ch = c.charCodeAt(0);
      return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
    }

    // Count occurrences in raw code strings using token boundary detection
    function countInRaw(code:String):Int {
      if (code == null || name == null) return 0;
      var rawCount = 0;
      var i = 0;
      while (i < code.length) {
        var idx = code.indexOf(name, i);
        if (idx == -1) break;
        var before = idx > 0 ? code.charAt(idx - 1) : "";
        var afterIdx = idx + name.length;
        var after = afterIdx < code.length ? code.charAt(afterIdx) : "";
        if (!isIdentChar(before) && !isIdentChar(after)) {
          rawCount++;
        }
        i = idx + 1;
      }
      return rawCount;
    }

    function walk(n:ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v) if (v == name): count++;
        case ERaw(code): count += countInRaw(code);  // Also check inside raw code!
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
    // Convert simple replacement AST to string for ERaw substitution
    var replacementStr:Null<String> = simpleASTToString(replacement);

    #if debug_inline_underscore
    // DISABLED: trace('[InlineUnderscore] substituteVar: from="$from", replacementStr=$replacementStr');
    #end

    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EVar(v) if (v == from): replacement;
        case ERaw(code) if (replacementStr != null):
          // Substitute variable name in raw code string
          #if debug_inline_underscore
          // DISABLED: trace('[InlineUnderscore] Found ERaw: "$code"');
          #end
          var newCode = substituteInRawCode(code, from, replacementStr);
          #if debug_inline_underscore
          // DISABLED: trace('[InlineUnderscore] After substitution: "$newCode"');
          #end
          if (newCode != code) {
            makeAST(ERaw(newCode));
          } else {
            n;
          }
        default: n;
      }
    });
  }

  /**
   * Convert simple AST expressions to string for ERaw substitution.
   * Returns null for complex expressions that can't be safely stringified.
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
      default: null;  // Complex expressions - don't substitute in ERaw
    };
  }

  /**
   * Substitute a variable name in raw code using token boundary detection.
   * Avoids false positives from substring matches.
   */
  static function substituteInRawCode(code:String, from:String, to:String):String {
    inline function isIdentChar(c:String):Bool {
      if (c == null || c.length == 0) return false;
      var ch = c.charCodeAt(0);
      return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
    }

    var result = new StringBuf();
    var i = 0;
    var lastEnd = 0;

    while (i < code.length) {
      var idx = code.indexOf(from, i);
      if (idx == -1) break;

      var before = idx > 0 ? code.charAt(idx - 1) : "";
      var afterIdx = idx + from.length;
      var after = afterIdx < code.length ? code.charAt(afterIdx) : "";

      if (!isIdentChar(before) && !isIdentChar(after)) {
        // Valid token boundary - replace
        result.add(code.substring(lastEnd, idx));
        result.add(to);
        lastEnd = afterIdx;
        i = afterIdx;
      } else {
        i = idx + 1;
      }
    }

    if (lastEnd > 0) {
      result.add(code.substring(lastEnd));
      return result.toString();
    }
    return code;
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
