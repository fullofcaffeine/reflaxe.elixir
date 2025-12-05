package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * CaseClauseUnusedBinderUnderscoreFinalTransforms
 *
 * WHAT
 * - Absolute-final pass: in case/cond clauses, underscore simple binders
 *   that are not referenced in the clause body (e.g., {:ok, value} -> ...
 *   where `value` is never read).
 */
class CaseClauseUnusedBinderUnderscoreFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(scrut, clauses):
          var cls = [];
          for (c in clauses) cls.push(rewriteClause(c));
          makeASTWithMeta(ECase(scrut, cls), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteClause(c: ECaseClause): ECaseClause {
    var used = collectUsed(c.body);
    var newPat = underscoreUnusedInPattern(c.pattern, used);
    return { pattern: newPat, guard: c.guard, body: c.body };
  }

  static function underscoreUnusedInPattern(p: EPattern, used: Map<String,Bool>): EPattern {
    return switch (p) {
      case PVar(n): (used.exists(n) ? p : PVar('_' + n));
      case PTuple(es): PTuple([for (e in es) underscoreUnusedInPattern(e, used)]);
      case PList(es): PList([for (e in es) underscoreUnusedInPattern(e, used)]);
      case PCons(h,t): PCons(underscoreUnusedInPattern(h, used), underscoreUnusedInPattern(t, used));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: underscoreUnusedInPattern(kv.value, used) }]);
      case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: underscoreUnusedInPattern(f.value, used) }]);
      case PPin(inner): PPin(underscoreUnusedInPattern(inner, used));
      default: p;
    }
  }

  static function collectUsed(ast: ElixirAST): Map<String,Bool> {
    var names = new Map<String,Bool>();

    // Helper to extract identifiers from raw code strings
    // Matches: variable names that could be Elixir identifiers
    // Pattern: word boundary, lowercase/underscore start, alphanumeric/underscore continuation
    inline function extractIdentifiers(code: String): Void {
      if (code == null) return;
      // Match Elixir-style identifiers: start with lowercase or underscore, continue with alphanum/underscore
      var identifierPattern = new EReg("\\b([a-z_][a-z0-9_]*)\\b", "g");
      var searchPos = 0;
      while (identifierPattern.matchSub(code, searchPos)) {
        var id = identifierPattern.matched(1);
        if (id != null && id.length > 0) {
          // Skip Elixir keywords and common non-variable tokens
          var isKeyword = (id == "do" || id == "end" || id == "fn" || id == "if" || id == "else" ||
                          id == "case" || id == "when" || id == "cond" || id == "for" || id == "in" ||
                          id == "true" || id == "false" || id == "nil" || id == "and" || id == "or" ||
                          id == "not" || id == "def" || id == "defp" || id == "defmodule");
          if (!isKeyword) {
            names.set(id, true);
          }
        }
        var pos = identifierPattern.matchedPos();
        searchPos = pos.pos + pos.len;
      }
    }

    ASTUtils.walk(ast, function(x: ElixirAST) {
      if (x == null || x.def == null) return;
      switch (x.def) {
        case EVar(v):
          names.set(v, true);
        case ERaw(code):
          extractIdentifiers(code);
        case EString(s):
          // Also check string interpolations for variable references
          extractIdentifiers(s);
        default:
      }
    });
    return names;
  }
}

#end
