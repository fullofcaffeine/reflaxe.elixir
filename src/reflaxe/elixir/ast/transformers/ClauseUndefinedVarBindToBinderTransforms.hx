package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ClauseUndefinedVarBindToBinderTransforms
 *
 * WHAT
 * - For ECase clauses shaped as `{:tag, binder}` whose body references exactly one
 *   undefined lower-case local `u`, prefix-bind `u = binder` inside the clause body.
 *
 * WHY
 * - Some earlier steps can leave the success binder with an unfortunate name (e.g., `socket`).
 *   The body, however, clearly uses a meaningful variable (e.g., `todo`), causing compile errors.
 *   Prefix-binding the intended local to the binder preserves semantics without renaming env vars.
 *
 * HOW
 * - For each ECase clause:
 *   - If pattern is `{:atom, PVar(b)}` and body’s used lower-case locals contain exactly one
 *     undefined `u`, and `u` is not reserved (`socket`, `params`, ...), then make the clause body:
 *       `u = b; <original body>`
 * - Runs absolute-final; no app coupling.
 */
class ClauseUndefinedVarBindToBinderTransforms {
  public static function bindPass(ast: ElixirAST): ElixirAST {
    return transformWithScope(ast, new Map());
  }

  /**
   * Walk with a lightweight bound-variable scope.
   *
   * WHY
   * - Case clause bodies can legally reference variables bound in the surrounding scope.
   * - Treating those as "undefined" and binding them to the case binder corrupts semantics
   *   (regression: errors/result in strict examples).
   *
   * HOW
   * - Track sequential bindings in EBlock/EDo (function args + prior assignments).
   * - When deciding if a variable is undefined inside a clause, exclude anything already in scope.
   */
  static function transformWithScope(node: ElixirAST, inScope: Map<String, Bool>): ElixirAST {
    if (node == null || node.def == null) return node;

    return switch (node.def) {
      case EDef(name, args, guards, body):
        var scope = collectPatternVars(args);
        makeASTWithMeta(
          EDef(
            name,
            args,
            guards != null ? transformWithScope(guards, scope) : null,
            transformWithScope(body, scope)
          ),
          node.metadata,
          node.pos
        );

      case EDefp(name, args, guards, body):
        var scope = collectPatternVars(args);
        makeASTWithMeta(
          EDefp(
            name,
            args,
            guards != null ? transformWithScope(guards, scope) : null,
            transformWithScope(body, scope)
          ),
          node.metadata,
          node.pos
        );

      case EFn(clauses):
        makeASTWithMeta(
          EFn(clauses.map(cl -> {
            var clauseScope = cloneScope(inScope);
            for (a in cl.args) collectPatternVarsInto(a, clauseScope);
            {
              args: cl.args,
              guard: cl.guard != null ? transformWithScope(cl.guard, clauseScope) : null,
              body: transformWithScope(cl.body, clauseScope)
            };
          })),
          node.metadata,
          node.pos
        );

      case EBlock(expressions):
        var localScope = cloneScope(inScope);
        var out:Array<ElixirAST> = [];
        for (e in expressions) {
          var next = transformWithScope(e, localScope);
          out.push(next);
          bindFromStatement(next, localScope);
        }
        makeASTWithMeta(EBlock(out), node.metadata, node.pos);

      case EDo(expressions2):
        var localScope = cloneScope(inScope);
        var out:Array<ElixirAST> = [];
        for (e2 in expressions2) {
          var next = transformWithScope(e2, localScope);
          out.push(next);
          bindFromStatement(next, localScope);
        }
        makeASTWithMeta(EDo(out), node.metadata, node.pos);

      case ECase(target, clauses):
        var outClauses:Array<ECaseClause> = [];
        for (cl in clauses) {
          // Pattern binds are available in the clause guard/body.
          var clauseScope = cloneScope(inScope);
          collectPatternVarsInto(cl.pattern, clauseScope);

          var newGuard = cl.guard != null ? transformWithScope(cl.guard, clauseScope) : null;
          var newBody = transformWithScope(cl.body, clauseScope);
          outClauses.push(processClause({ pattern: cl.pattern, guard: newGuard, body: newBody }, inScope));
        }
        makeASTWithMeta(ECase(transformWithScope(target, inScope), outClauses), node.metadata, node.pos);

      default:
        ElixirASTTransformer.transformAST(node, child -> transformWithScope(child, inScope));
    };
  }

  static function processClause(cl: ECaseClause, outerScope: Map<String, Bool>): ECaseClause {
    var b = extractOkBinder(cl.pattern);
    if (b == null) return cl;

    var declared = collectDeclared(cl.pattern, cl.body);
    var used = collectUsed(cl.body);
    var undef:Array<String> = [];
    for (u in used.keys()) {
      if (!declared.exists(u) && allow(u) && (outerScope == null || !outerScope.exists(u))) undef.push(u);
    }

    if (undef.length != 1) return cl;

    var best = undef[0];
    var binderName = b;
    if (best == null || best.length == 0 || best == binderName) return cl;
    if (hasAliasInBody(cl.body, best, binderName)) return cl;

    var prefixes:Array<ElixirAST> = [
      makeAST(EBinary(Match, makeAST(EVar(best)), makeAST(EVar(binderName))))
    ];
    var newBody = switch (cl.body.def) {
      case EBlock(sts): makeASTWithMeta(EBlock(prefixes.concat(sts)), cl.body.metadata, cl.body.pos);
      case EDo(sts2): makeASTWithMeta(EDo(prefixes.concat(sts2)), cl.body.metadata, cl.body.pos);
      default: makeASTWithMeta(EBlock(prefixes.concat([cl.body])), cl.body.metadata, cl.body.pos);
    };
    return { pattern: cl.pattern, guard: cl.guard, body: newBody };
  }

  static function bindFromStatement(stmt: ElixirAST, scope: Map<String, Bool>): Void {
    if (stmt == null || stmt.def == null) return;
    switch (stmt.def) {
      case EMatch(pat, _):
        collectPatternVarsInto(pat, scope);
      case EBinary(Match, left, _):
        collectLhsVars(left, scope);
      default:
    }
  }

  static function collectLhsVars(lhs: ElixirAST, out: Map<String, Bool>): Void {
    if (lhs == null || lhs.def == null) return;
    switch (lhs.def) {
      case EVar(nm) if (nm != null && nm.length > 0):
        out.set(nm, true);
      case EPin(_):
        // pinned vars do not bind
      case ETuple(items) | EList(items):
        for (i in items) collectLhsVars(i, out);
      case EKeywordList(pairs):
        for (p in pairs) collectLhsVars(p.value, out);
      case EMap(pairs2):
        for (p in pairs2) collectLhsVars(p.value, out);
      case EBinary(Match, l, r):
        collectLhsVars(l, out);
        collectLhsVars(r, out);
      default:
    }
  }

  static function collectPatternVars(args: Array<EPattern>): Map<String, Bool> {
    var out = new Map<String, Bool>();
    if (args == null) return out;
    for (p in args) collectPatternVarsInto(p, out);
    return out;
  }

  static function collectPatternVarsInto(p: EPattern, out: Map<String, Bool>): Void {
    if (p == null) return;
    switch (p) {
      case PVar(n) if (n != null && n.length > 0):
        out.set(n, true);
      case PAlias(nm, inner):
        if (nm != null && nm.length > 0) out.set(nm, true);
        collectPatternVarsInto(inner, out);
      case PPin(_):
        // pinned vars do not bind; outer scope must already contain them
      case PTuple(es) | PList(es):
        for (e in es) collectPatternVarsInto(e, out);
      case PCons(h, t):
        collectPatternVarsInto(h, out);
        collectPatternVarsInto(t, out);
      case PMap(kvs):
        for (kv in kvs) collectPatternVarsInto(kv.value, out);
      case PStruct(_, fs):
        for (f in fs) collectPatternVarsInto(f.value, out);
      default:
    }
  }

  static function cloneScope(m: Map<String, Bool>): Map<String, Bool> {
    var out = new Map<String, Bool>();
    if (m != null) for (k in m.keys()) out.set(k, true);
    return out;
  }

  static function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "_params" || name == "event") return false;
    // Filter out Elixir keywords and common language tokens that may appear in printed text
    switch (name) {
      case "end" | "do" | "case" | "fn" | "receive" | "after" | "else" | "catch" | "rescue" | "true" | "false" | "nil" | "when":
        return false;
      default:
    }
    var c = name.charAt(0);
    return c.toLowerCase() == c;
  }

  static function extractBinder(p:EPattern): Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[1]) { case PVar(n): n; default: null; }
      default: null;
    }
  }

  static function extractOkBinder(p: EPattern): Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) {
          case PLiteral({def: EAtom(a)}) if ((a : String) == ":ok" || (a : String) == "ok"):
            switch (es[1]) { case PVar(n): n; default: null; }
          default:
            null;
        }
      default:
        null;
    }
  }

  static function renameSecondBinder(p:EPattern, newName:String): Null<EPattern> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[1]) {
          case PVar(_): PTuple([es[0], PVar(newName)]);
          default: null;
        }
      default: null;
    }
  }

  static function collectDeclared(p:EPattern, body:ElixirAST): Map<String,Bool> {
    var m = new Map<String,Bool>();
    function pat(pt:EPattern):Void {
      switch (pt) {
        case PVar(n): m.set(n, true);
        case PTuple(es) | PList(es): for (e in es) pat(e);
        case PCons(h,t): pat(h); pat(t);
        case PMap(kvs): for (kv in kvs) pat(kv.value);
        case PStruct(_, fs): for (f in fs) pat(f.value);
        case PPin(inner): pat(inner);
        default:
      }
    }
    pat(p);
    // LHS inside body
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EMatch(pt, _): pat(pt);
        case EBinary(Match, {def: EVar(lhs)}, _): m.set(lhs, true);
        default:
      }
    });
    return m;
  }

  static function collectUsed(ast: ElixirAST): Map<String,Bool> {
    var names = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(ast, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v): if (allow(v)) names.set(v, true);
        case EString(s):
          var block = new EReg("\\#\\{([^}]*)\\}", "g");
          var pos = 0;
          while (block.matchSub(s, pos)) {
            var inner = block.matched(1);
            var tok = new EReg("[a-z_][a-z0-9_]*", "gi");
            var tpos = 0;
            while (tok.matchSub(inner, tpos)) {
              var id = tok.matched(0);
              if (allow(id)) {
                var mp = tok.matchedPos();
                var before = mp.pos > 0 ? inner.substr(mp.pos - 1, 1) : null;
                var afterIdx = mp.pos + mp.len;
                var after = afterIdx < inner.length ? inner.substr(afterIdx, 1) : null;

                // Skip atoms/keywords (`:ok`, `key:`) and function calls (`inspect(...)`).
                var nextNonWsIdx = afterIdx;
                while (nextNonWsIdx < inner.length) {
                  var ch = inner.substr(nextNonWsIdx, 1);
                  if (ch != " " && ch != "\t" && ch != "\n" && ch != "\r") break;
                  nextNonWsIdx++;
                }
                var nextNonWs = nextNonWsIdx < inner.length ? inner.substr(nextNonWsIdx, 1) : null;

                if (before == ":" || after == ":" || nextNonWs == "(") {
                  // ignore
                } else {
                  names.set(id, true);
                }
              }
              tpos = tok.matchedPos().pos + tok.matchedPos().len;
            }
            pos = block.matchedPos().pos + block.matchedPos().len;
          }
        default:
      }
    });
    return names;
  }

  static function hasAliasInBody(body:ElixirAST, lhs:String, rhs:String):Bool {
    var found = false;
    function check(n:ElixirAST):Void {
      if (found || n == null || n.def == null) return;
      switch (n.def) {
        case EBlock(sts) | EDo(sts):
          for (s in sts) check(s);
        case EBinary(Match, {def: EVar(l)}, {def: EVar(r)}):
          if (l == lhs && r == rhs) { found = true; return; }
        case EMatch(PVar(l2), {def: EVar(r2)}):
          if (l2 == lhs && r2 == rhs) { found = true; return; }
        default:
      }
    }
    check(body);
    return found;
  }
}

#end
