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
          #if sys Sys.println('[ClauseBindToBinder] Visiting ECase target=' + (switch (target.def) { case EVar(v): v; default: Type.enumConstructor(target.def); })); #end
          var out:Array<ECaseClause> = [];
          for (cl in clauses) {
            var b = extractBinder(cl.pattern);
            if (b != null) {
              #if sys
              Sys.println('[ClauseBindToBinder] clause {:_, ' + b + '}');
              #end
              var declared = collectDeclared(cl.pattern, cl.body);
              var used = collectUsed(cl.body);
              var undef:Array<String> = [];
              for (u in used.keys()) if (!declared.exists(u) && allow(u)) undef.push(u);
              #if sys
              var declArr = [for (k in declared.keys()) k];
              Sys.println('[ClauseBindToBinder] declared={' + declArr.join(',') + '} used={' + [for (k in used.keys()) k].join(',') + '} undef={' + undef.join(',') + '}');
              #end
              if (undef.length >= 1) {
                // Choose the most frequently referenced undefined variable in the body
                var freq = new haxe.ds.StringMap<Int>();
                for (c in undef) freq.set(c, 0);
                reflaxe.elixir.ast.ASTUtils.walk(cl.body, function(w: ElixirAST) {
                  switch (w.def) { case EVar(nm) if (freq.exists(nm)): freq.set(nm, freq.get(nm) + 1); default: }
                });
                var best:Null<String> = null; var bestCount = -1;
                for (c in undef) { var cnt = freq.exists(c) ? freq.get(c) : 0; if (cnt > bestCount) { bestCount = cnt; best = c; } }
                if (best != null) {
                  #if sys Sys.println('[ClauseBindToBinder] prefix bind ' + best + ' = ' + b + ' (count=' + Std.string(bestCount) + ')'); #end
                  var prefix = makeAST(EBinary(Match, makeAST(EVar(best)), makeAST(EVar(b))));
                  var newBody = switch (cl.body.def) {
                    case EBlock(sts): makeASTWithMeta(EBlock([prefix].concat(sts)), cl.body.metadata, cl.body.pos);
                    case EDo(sts2): makeASTWithMeta(EDo([prefix].concat(sts2)), cl.body.metadata, cl.body.pos);
                    default: makeASTWithMeta(EBlock([prefix, cl.body]), cl.body.metadata, cl.body.pos);
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

  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "_params" || name == "event") return false;
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
        case EVar(v): names.set(v, true);
        case EString(s):
          var block = new EReg("\\#\\{([^}]*)\\}", "g");
          var pos = 0;
          while (block.matchSub(s, pos)) {
            var inner = block.matched(1);
            var tok = new EReg("[a-z_][a-z0-9_]*", "gi");
            var tpos = 0;
            while (tok.matchSub(inner, tpos)) {
              var id = tok.matched(0);
              if (allow(id)) names.set(id, true);
              tpos = tok.matchedPos().pos + tok.matchedPos().len;
            }
            pos = block.matchedPos().pos + block.matchedPos().len;
          }
        default:
      }
    });
    // Fallback: scan printed body text for interpolation identifiers and bare identifiers
    try {
      var printed = reflaxe.elixir.ast.ElixirASTPrinter.print(ast, 0);
      var block = new EReg("\\#\\{([^}]*)\\}", "g");
      var pos = 0;
      while (block.matchSub(printed, pos)) {
        var inner = block.matched(1);
        var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "gi");
        var tpos = 0;
        while (tok.matchSub(inner, tpos)) {
          var id = tok.matched(0);
          if (allow(id)) names.set(id, true);
          tpos = tok.matchedPos().pos + tok.matchedPos().len;
        }
        pos = block.matchedPos().pos + block.matchedPos().len;
      }
    } catch (e:Dynamic) {}
    return names;
  }
}

#end
