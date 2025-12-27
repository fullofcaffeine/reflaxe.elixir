package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
using StringTools;

/**
 * DropStandaloneVarRefTransforms
 *
 * WHAT
 * - Removes standalone variable-reference expressions (e.g. `old_score`) that appear in
 *   statement position inside EBlock/EDo lists (i.e. not the last expression).
 *
 * WHY
 * - Some builder/transform combinations can leave behind pure "value" expressions from
 *   constructs like post-increment (`x++`) when the returned old value is not used.
 * - In Elixir this triggers warnings such as:
 *     "variable old_score in code block has no effect as it is never returned"
 *   which become fatal under `--warnings-as-errors`.
 *
 * HOW
 * - Walk all EBlock/EDo nodes and filter out any statement that is a bare `EVar(_)` (or
 *   `EParen(EVar(_))`) when it is not the final expression of the sequence.
 * - The final expression is preserved to maintain block return semantics.
 *
 * EXAMPLES
 * Elixir (before):
 *   old_score = score
 *   score = score + 1
 *   old_score
 *   score
 * Elixir (after):
 *   old_score = score
 *   score = score + 1
 *   score
 */
class DropStandaloneVarRefTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      if (n == null || n.def == null) return n;

      return switch (n.def) {
        case EBlock(stmts):
          makeASTWithMeta(EBlock(drop(stmts)), n.metadata, n.pos);
        case EDo(stmts2):
          makeASTWithMeta(EDo(drop(stmts2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function drop(stmts: Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null || stmts.length <= 1) return stmts;
    var out: Array<ElixirAST> = [];
    var lastIndex = stmts.length - 1;
    for (i in 0...stmts.length) {
      var s = stmts[i];
      if (i != lastIndex) {
        // Statement-position: the value of `s` is unused. If `s` is itself a block/do list,
        // drop trailing standalone var refs inside it as well.
        s = dropTrailingVarRefsInStatement(s);
        if (isStandaloneVarRef(s)) continue;
      }
      out.push(s);
    }
    return out;
  }

  static function dropTrailingVarRefsInStatement(s: ElixirAST): ElixirAST {
    if (s == null || s.def == null) return s;
    return switch (s.def) {
      case EBlock(stmts):
        var trimmed = trimTrailingVarRefs(stmts);
        if (trimmed == stmts) s else makeASTWithMeta(EBlock(trimmed), s.metadata, s.pos);
      case EDo(stmts2):
        var trimmed2 = trimTrailingVarRefs(stmts2);
        if (trimmed2 == stmts2) s else makeASTWithMeta(EDo(trimmed2), s.metadata, s.pos);
      default:
        s;
    }
  }

  static function trimTrailingVarRefs(stmts: Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null || stmts.length == 0) return stmts;
    var end = stmts.length;
    while (end > 0 && isStandaloneVarRef(stmts[end - 1])) end--;
    if (end == stmts.length) return stmts;
    return stmts.slice(0, end);
  }

  static inline function isStandaloneVarRef(s: ElixirAST): Bool {
    if (s == null || s.def == null) return false;
    return switch (s.def) {
      case EVar(_): true;
      case ERaw(code): isBareVarIdentifier(code);
      case EParen(inner):
        inner != null && inner.def != null && switch (inner.def) {
          case EVar(_): true;
          case ERaw(code2): isBareVarIdentifier(code2);
          default: false;
        };
      default:
        false;
    }
  }

  static inline function isBareVarIdentifier(code: String): Bool {
    if (code == null) return false;
    var t = code.trim();
    if (t.length == 0) return false;
    // Lower-case identifier shape (variables), no dots or punctuation.
    return ~/^[a-z_][a-z0-9_]*$/.match(t);
  }
}

#end
