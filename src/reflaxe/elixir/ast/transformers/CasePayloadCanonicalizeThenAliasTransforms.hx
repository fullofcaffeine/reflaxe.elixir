package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CasePayloadCanonicalizeThenAliasTransforms
 *
 * WHAT
 * - For two-tuple case patterns {:atom, binder}, when the clause body uses
 *   one or more undefined simple lower-case locals, canonicalize the payload
 *   binder to `_value` and prepend alias lines `u = _value` (and `fn_ = _value`)
 *   so the body reads naturally without renaming the pattern.
 *
 * WHY
 * - Guards/pattern snapshots expect canonical `_value` payload binders with
 *   clause-local aliases to meaningful names used in the body. This keeps the
 *   pattern idiomatic and avoids late binder renames.
 *
 * HOW
 * - For each ECase clause with PTuple([PLiteral(_), PVar(_)]):
 *   1) Collect declared names from pattern + LHS in body.
 *   2) Collect used names (AST + #{...}).
 *   3) undefined = used − declared − reserved.
 *   4) If undefined.nonEmpty, rewrite second binder to `_value` and prepend
 *      `fn_ = _value` (if not present) and `u = _value` for each `u` in undefined.
 *   5) Set `lockPayloadBinder=true` metadata on the clause body (canonicalization lock)
 *      so late passes skip renaming the second-slot binder once canonicalized.
 *
 * EXAMPLES
 * Haxe:
 *   switch res {
 *     case Ok(user):
 *       update(user);
 *     case Error(reason):
 *   }
 * Elixir (after):
 *   case res do
 *     {:ok, _value} ->
 *       user = _value
 *       update(user)
 *     {:error, reason} -> :error
 *   end
 */
class CasePayloadCanonicalizeThenAliasTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) out.push(processClause(cl));
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function processClause(cl: ECaseClause): ECaseClause {
    var isTwoTuple = false;
    var originalBinder:Null<String> = null;
    var tagAtom:Null<String> = null;
    switch (cl.pattern) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) {
          case PLiteral({def: EAtom(a)}): isTwoTuple = true; tagAtom = a;
          case PLiteral(_): isTwoTuple = true; // non-atom literal; avoid canonicalization below
          default:
        }
        switch (es[1]) { case PVar(n): originalBinder = n; default: }
      default:
    }
    if (!isTwoTuple) return cl;
    // Gate: Only canonicalize well-known Result-style tags to avoid overreach in generic enums
    if (tagAtom != null) {
      var ta = tagAtom;
      var low = ta.toLowerCase();
      if (!(low == "ok" || low == "error")) {
        return cl;
      }
    } else {
      return cl; // non-atom literal tag — skip
    }

    var declared = collectDeclared(cl.pattern, cl.body);
    var used = collectUsed(cl.body, cl.guard);
    var undefined:Array<String> = [];
    for (u in used.keys()) if (allow(u) && !declared.exists(u)) undefined.push(u);

    // Always force canonical binder to `_value` for two-tuple {:atom, binder}
    var pat2 = switch (cl.pattern) {
      case PTuple(es2) if (es2.length == 2): PTuple([es2[0], PVar("_value")]);
      default: cl.pattern;
    };

    // Prepend aliases:
    // - Alias the original binder name back to `_value` when it is referenced in the body
    // - Alias additional undefined locals to `_value`
    // - If any aliasing is needed, also prepend a conventional `fn_ = _value` line first
    var prefix:Array<ElixirAST> = [];
    var needBinderAlias:Bool = originalBinder != null && originalBinder != "_value" && allow(originalBinder) && used.exists(originalBinder) && !hasAlias(cl.body, originalBinder, "_value");
    var extraAliases:Array<String> = [];
    for (u in undefined) if (u != "fn_" && (originalBinder == null || u != originalBinder) && !hasAlias(cl.body, u, "_value")) extraAliases.push(u);
    var needAnyAlias = needBinderAlias || extraAliases.length > 0;
    if (needAnyAlias && !hasAlias(cl.body, "fn_", "_value")) {
      prefix.push(makeAST(EBinary(Match, makeAST(EVar("fn_")), makeAST(EVar("_value")))));
    }
    if (needBinderAlias) {
      prefix.push(makeAST(EBinary(Match, makeAST(EVar(originalBinder)), makeAST(EVar("_value")))));
    }
    for (u in extraAliases) {
      prefix.push(makeAST(EBinary(Match, makeAST(EVar(u)), makeAST(EVar("_value")))));
    }

    if (cl.body == null) return cl;
    var newBody = switch (cl.body.def) {
      case EBlock(sts): makeASTWithMeta(EBlock(prefix.concat(sts)), cl.body.metadata, cl.body.pos);
      case EDo(sts2): makeASTWithMeta(EDo(prefix.concat(sts2)), cl.body.metadata, cl.body.pos);
      default: makeASTWithMeta(EBlock(prefix.concat([cl.body])), cl.body.metadata, cl.body.pos);
    };
    // Mark this clause body as having a locked canonical payload binder to prevent late renamers
    try {
      if (newBody.metadata == null) newBody.metadata = {};
      untyped newBody.metadata.lockPayloadBinder = true;
      untyped newBody.metadata.canonicalPayloadValue = true;
    } catch (e:Dynamic) {}
    return { pattern: pat2, guard: cl.guard, body: newBody };
  }

  static function hasAlias(body:ElixirAST, lhs:String, rhs:String):Bool {
    var found = false;
    function scan(n:ElixirAST):Void {
      if (found || n == null || n.def == null) return;
      switch (n.def) {
        case EBlock(ss) | EDo(ss): for (s in ss) scan(s);
        case EBinary(Match, {def: EVar(l)}, {def: EVar(r)}): if (l == lhs && r == rhs) { found = true; return; }
        case EMatch(PVar(l2), {def: EVar(r2)}): if (l2 == lhs && r2 == rhs) { found = true; return; }
        default:
      }
    }
    scan(body);
    return found;
  }

  static function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "_params" || name == "event") return false;
    switch (name) {
      case "end" | "do" | "case" | "fn" | "receive" | "after" | "else" | "catch" | "rescue" | "true" | "false" | "nil" | "when":
        return false;
      default:
    }
    var c = name.charAt(0);
    return c.toLowerCase() == c && c != '_';
  }

  static function collectDeclared(p:EPattern, body:ElixirAST): Map<String,Bool> {
    var m = new Map<String,Bool>();
    function pat(px:EPattern):Void {
      switch (px) {
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
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x:ElixirAST){ switch (x.def) { case EMatch(pt,_): pat(pt); case EBinary(Match, {def: EVar(lhs)}, _): m.set(lhs,true); default: } });
    return m;
  }

  static function collectUsed(body: ElixirAST, guard: Null<ElixirAST>): Map<String,Bool> {
    var m = new Map<String,Bool>();
    function scan(n:ElixirAST):Void {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v): if (allow(v)) m.set(v, true);
        case EString(s): markInterps(s, m);
        case ERaw(code): markInterps(code, m);
        case EBlock(ss): for (s in ss) scan(s);
        case EDo(ss2): for (s in ss2) scan(s);
        case EBinary(_, l, r): scan(l); scan(r);
        case EMatch(_, rhs): scan(rhs);
        case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
        case ECase(e, cs): scan(e); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
        default:
      }
    }
    scan(body);
    if (guard != null) scan(guard);
    return m;
  }

  static function markInterps(s:String, used:Map<String,Bool>):Void {
    if (s == null) return;
    var re = new EReg("\\#\\{([^}]*)\\}", "g");
    var pos = 0;
    while (re.matchSub(s, pos)) {
      var inner = re.matched(1);
      var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
      var tpos = 0;
      while (tok.matchSub(inner, tpos)) {
        var id = tok.matched(0);
        if (allow(id)) used.set(id, true);
        tpos = tok.matchedPos().pos + tok.matchedPos().len;
      }
      pos = re.matchedPos().pos + re.matchedPos().len;
    }
  }
}

#end
