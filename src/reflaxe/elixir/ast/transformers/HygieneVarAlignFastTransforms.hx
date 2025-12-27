package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * HygieneVarAlignFastTransforms
 *
 * WHAT
 * - O(n) variable alignment pass that rewrites declarations and references to a
 *   canonical base name within each function, without quadratic binder pairing.
 * - Replaces late RefDeclAlignment (O(n²)) to unblock compilation hangs.
 *
 * WHY
 * - Late hygiene was aligning `_foo`/`foo`/`foo1` variants via pairwise scans,
 *   which becomes quadratic in LiveView modules. This pass keeps determinism
 *   while running in a single walk per function.
 *
 * HOW
 * - For each def/defp:
 *   1) Collect declared identifiers from params, patterns, and match LHS.
 *   2) Collect referenced identifiers using VariableUsageCollector (O(n)).
 *   3) For each base name (strip leading underscore and numeric suffix):
 *        - If a plain `base` is referenced → canonical = `base`.
 *        - Else if only `_base` is declared and either `_base` or `base` is
 *          referenced → canonical = `base` (promote underscore when used).
 *        - Else if only numeric variants are referenced → keep first variant.
 *   4) Rewrite decls (patterns/LHS) and refs (EVar) to canonical when present.
 * - Does not invent new variables; skips bases without references to avoid
 *   widening unused underscores.
 *
 * EXAMPLES
 *   Decl: `_users`; Ref: `users`  → both become `users`
 *   Decl: `_ok_conn`; Ref: `_ok_conn` → stays `_ok_conn` (no plain ref)
 *   Decl: `payload`; Ref: `payload` → unchanged
 *
 * NOTES
 * - Keeps underscore on params that remain unused (no references).
 * - Ignores atoms/module names by restricting bases to lowercase starters.
 */
class HygieneVarAlignFastTransforms {
  public static function alignPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
      return switch (node.def) {
        case EDef(name, params, guards, body):
          var newBody = align(body, params);
          makeASTWithMeta(EDef(name, params, guards, newBody), node.metadata, node.pos);
        case EDefp(name, params, guards, body):
          var newBody = align(body, params);
          makeASTWithMeta(EDefp(name, params, guards, newBody), node.metadata, node.pos);
        default:
          node;
      }
    });
  }

  static function align(body: ElixirAST, ?params:Array<EPattern>): ElixirAST {
    var declared = new Map<String,Bool>();

    if (params != null) for (p in params) collectPatternDecls(p, declared);

    ASTUtils.walk(body, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EMatch(p, _): collectPatternDecls(p, declared);
        case EBinary(Match, left, _): collectLhsDecls(left, declared);
        case EFn(clauses): for (cl in clauses) for (a in cl.args) collectPatternDecls(a, declared);
        default:
      }
    });

    var referenced = VariableUsageCollector.referencedInFunctionScope(body);

    // Filter bases to lowercase starters to avoid atoms/module aliases.
    function toBase(name:String):String {
      if (name == null || name.length == 0) return null;
      var base = stripNumeric(stripLeadingUnderscores(name));
      if (base == null || base.length == 0) return null;
      var c = base.charAt(0);
      return (c == c.toLowerCase() && c != "_") ? base : null;
    }

    var canonical = new Map<String,String>();
    var referencedBases = new Map<String, Bool>();
    for (ref in referenced.keys()) {
      var b = toBase(ref);
      if (b != null) referencedBases.set(b, true);
    }

    for (decl in declared.keys()) {
      var base = toBase(decl);
      if (base == null) continue;
      var plainRef = referenced.exists(base);
      var hasUnderscoreDecl = (decl.length > 0 && decl.charAt(0) == "_");
      var anyRef = referencedBases.exists(base);

      if (plainRef) {
        canonical.set(base, base);
      } else if (hasUnderscoreDecl && anyRef) {
        canonical.set(base, base);
      }
    }

    if (canonical.keys().hasNext() == false) return body;

    function rewritePattern(p:EPattern):EPattern {
      return switch (p) {
        case PVar(v):
          var b = toBase(v);
          if (b != null && canonical.exists(b)) {
            var target = canonical.get(b);
            (v == target) ? p : PVar(target);
          } else p;
        case PTuple(items): PTuple(items.map(rewritePattern));
        case PList(items): PList(items.map(rewritePattern));
        case PCons(head, tail): PCons(rewritePattern(head), rewritePattern(tail));
        case PMap(fields):
          PMap([for (f in fields) { key: f.key, value: rewritePattern(f.value) }]);
        case PStruct(module, fields):
          PStruct(module, [for (f in fields) { key: f.key, value: rewritePattern(f.value) }]);
        case PAlias(varName, pat):
          var b2 = toBase(varName);
          var newName = (b2 != null && canonical.exists(b2)) ? canonical.get(b2) : varName;
          PAlias(newName, rewritePattern(pat));
        default: p;
      }
    }

    function rewriteLhs(lhs:ElixirAST):ElixirAST {
      return switch (lhs.def) {
        case EVar(v):
          var b = toBase(v);
          if (b != null && canonical.exists(b)) {
            var target = canonical.get(b);
            (v == target) ? lhs : makeASTWithMeta(EVar(target), lhs.metadata, lhs.pos);
          } else lhs;
        case EMatch(p, rhs): makeASTWithMeta(EMatch(rewritePattern(p), rhs), lhs.metadata, lhs.pos);
        default: lhs;
      }
    }

    function tx(n:ElixirAST):ElixirAST {
      if (n == null || n.def == null) return n;
      return switch (n.def) {
        case EVar(v):
          var b = toBase(v);
          if (b != null && canonical.exists(b)) {
            var target = canonical.get(b);
            (v == target) ? n : makeASTWithMeta(EVar(target), n.metadata, n.pos);
          } else n;
        case EMatch(p, rhs): makeASTWithMeta(EMatch(rewritePattern(p), rhs), n.metadata, n.pos);
        case EBinary(Match, left, rhs): makeASTWithMeta(EBinary(Match, rewriteLhs(left), rhs), n.metadata, n.pos);
        default: n;
      }
    }

    return ElixirASTTransformer.transformNode(body, tx);
  }

  static function collectPatternDecls(p:EPattern, out:Map<String,Bool>):Void {
    if (p == null) return;
    switch (p) {
        case PVar(v): out.set(v, true);
        case PTuple(items): for (i in items) collectPatternDecls(i, out);
        case PList(items): for (i in items) collectPatternDecls(i, out);
        case PCons(head, tail): collectPatternDecls(head, out); collectPatternDecls(tail, out);
        case PMap(fields): for (f in fields) collectPatternDecls(f.value, out);
        case PStruct(_, fields): for (f in fields) collectPatternDecls(f.value, out);
        case PAlias(varName, pat): out.set(varName, true); collectPatternDecls(pat, out);
        default:
    }
  }

  static function collectLhsDecls(lhs:ElixirAST, out:Map<String,Bool>):Void {
    if (lhs == null || lhs.def == null) return;
    switch (lhs.def) {
      case EVar(v): out.set(v, true);
      case EMatch(p, _): collectPatternDecls(p, out);
      default:
    }
  }

  static function stripLeadingUnderscores(name:String):String {
    var i = 0;
    while (i < name.length && name.charAt(i) == "_") i++;
    return name.substr(i);
  }

  static function stripNumeric(name:String):String {
    var i = name.length - 1;
    while (i >= 0 && name.charAt(i) >= "0" && name.charAt(i) <= "9") i--;
    return name.substr(0, i + 1);
  }
}

#end
