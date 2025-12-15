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
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(target, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) {
            var b = extractOkBinder(cl.pattern);
            if (b != null) {
              #if debug_transforms
              #end
              var declared = collectDeclared(cl.pattern, cl.body);
              var used = collectUsed(cl.body);
              var undef:Array<String> = [];
              for (u in used.keys()) if (!declared.exists(u) && allow(u)) undef.push(u);
              #if debug_transforms
              var declArr = [for (k in declared.keys()) k];
              #end
              if (undef.length == 1) {
                var best = undef[0];
                var binderName = b;
                if (best != null && best.length > 0 && best != binderName && !hasAliasInBody(cl.body, best, binderName)) {
                  var prefixes:Array<ElixirAST> = [
                    makeAST(EBinary(Match, makeAST(EVar(best)), makeAST(EVar(binderName))))
                  ];
                  var newBody = switch (cl.body.def) {
                    case EBlock(sts): makeASTWithMeta(EBlock(prefixes.concat(sts)), cl.body.metadata, cl.body.pos);
                    case EDo(sts2): makeASTWithMeta(EDo(prefixes.concat(sts2)), cl.body.metadata, cl.body.pos);
                    default: makeASTWithMeta(EBlock(prefixes.concat([cl.body])), cl.body.metadata, cl.body.pos);
                  };
                  out.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                  continue;
                }
              }
            }
            out.push(cl);
          }
          makeASTWithMeta(ECase(target, out), n.metadata, n.pos);
        default:
          n;
      }
    });
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
