package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ASTUtils;

/**
 * UnderscorePromoteByUseLateTransforms
 *
 * WHAT
 * - Late, linear pass that promotes underscored locals ("_foo") to their
 *   base name ("foo") when the base is referenced in the same function body.
 *
 * WHY
 * - Some hygiene passes underscore unused binds, but later rewrites introduce
 *   references to the base name. Without promotion, Elixir ends up with
 *   undefined variables (e.g., `_users` bound, but `users` referenced).
 * - Previous O(n²) RefDeclAlignment caused hangs; this provides a focused,
 *   O(n) safety net for the common underscored-decl/used-base shape.
 *
 * HOW
 * - For each def/defp:
 *   1) Collect referenced identifiers (EVar) in the body; record their bases
 *      (strip leading underscore and trailing digits).
 *   2) Rewrite decls and refs:
 *      - If a name starts with "_" and its base is in the referenced set,
 *        drop the underscore.
 *      - Applies to vars in match LHS, patterns, and references.
 * - Ignores atoms/module aliases by requiring lowercase initial char.
 */
class UnderscorePromoteByUseLateTransforms {
  public static function promotePass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
      return switch (node.def) {
        case EDef(name, params, guards, body):
          var refs = collectRefs(body);
          var newBody = rewrite(body, refs);
          makeASTWithMeta(EDef(name, params, guards, newBody), node.metadata, node.pos);
        case EDefp(name, params, guards, body):
          var refs = collectRefs(body);
          var newBody = rewrite(body, refs);
          makeASTWithMeta(EDefp(name, params, guards, newBody), node.metadata, node.pos);
        default:
          node;
      }
    });
  }

  static function collectRefs(body: ElixirAST): Map<String,Bool> {
    var refs = new Map<String,Bool>();
    ASTUtils.walk(body, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v):
          var b = base(v);
          if (b != null) refs.set(b, true);
        default:
      }
    });
    return refs;
  }

  static function rewrite(body: ElixirAST, refs:Map<String,Bool>): ElixirAST {
    function promote(name:String):String {
      var b = base(name);
      if (b != null && refs.exists(b) && name.charAt(0) == "_") return b;
      return name;
    }

    function rewPat(p:EPattern):EPattern {
      return switch (p) {
        case PVar(v): PVar(promote(v));
        case PTuple(items): PTuple(items.map(rewPat));
        case PList(items): PList(items.map(rewPat));
        case PCons(h, t): PCons(rewPat(h), rewPat(t));
        case PMap(fields): PMap([for (f in fields) { key: f.key, value: rewPat(f.value) }]);
        case PStruct(mod, fields): PStruct(mod, [for (f in fields) { key: f.key, value: rewPat(f.value) }]);
        case PAlias(varName, pat): PAlias(promote(varName), rewPat(pat));
        default: p;
      }
    }

    function rewPatInLhs(lhs:ElixirAST):ElixirAST {
      if (lhs == null || lhs.def == null) return lhs;
      return switch (lhs.def) {
        case EVar(v):
          var nv = promote(v);
          (nv == v) ? lhs : makeASTWithMeta(EVar(nv), lhs.metadata, lhs.pos);
        case EMatch(p, rhs):
          makeASTWithMeta(EMatch(rewPat(p), rhs), lhs.metadata, lhs.pos);
        default:
          lhs;
      }
    }

    return ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
      if (n == null || n.def == null) return n;
      return switch (n.def) {
        case EVar(v):
          var nv = promote(v);
          (nv == v) ? n : makeASTWithMeta(EVar(nv), n.metadata, n.pos);
        case EMatch(p, rhs):
          makeASTWithMeta(EMatch(rewPat(p), rhs), n.metadata, n.pos);
        case EBinary(Match, left, rhs):
          makeASTWithMeta(EBinary(Match, rewPatInLhs(left), rhs), n.metadata, n.pos);
        case EFn(clauses):
          var newClauses = [for (c in clauses) {
            args: [for (a in c.args) rewPat(a)],
            guard: c.guard,
            body: c.body
          }];
          makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function base(name:String):String {
    if (name == null || name.length == 0) return null;
    var s = stripLeadingUnderscores(name);
    if (s == null || s.length == 0) return null;
    var i = s.length - 1;
    while (i >= 0 && s.charAt(i) >= "0" && s.charAt(i) <= "9") i--;
    var b = s.substr(0, i + 1);
    if (b == "" || b.charAt(0) != b.charAt(0).toLowerCase() || b.charAt(0) == "_") return null;
    return b;
  }

  static function stripLeadingUnderscores(name:String):String {
    var i = 0;
    while (i < name.length && name.charAt(i) == "_") i++;
    return name.substr(i);
  }
}

#end
