package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import haxe.ds.StringMap;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * CaseBinderAlignFinalTransforms
 *
 * WHAT
 * - Absolute-last safety net that aligns the payload binder in `{:tag, binder}`
 *   to the clause's sole undefined local used in the clause body.
 *
 * WHY
 * - Earlier passes may underscore or rename binders; when the body clearly uses a
 *   single undefined variable (todo/id/message), ensure the pattern matches it to
 *   prevent undefined-variable errors. Generic and shape-based.
 *
 * HOW
 * - For each ECase clause with `{:atom, PVar(binder)}`:
 *   - Collect declared names (pattern + LHS matches inside the clause body)
 *   - Collect used simple vars in the body
 *   - If exactly one undefined lower-case name U exists and U != binder,
 *     rename the binder to U and rewrite body occurrences of `binder` to `U` (in case it’s referenced).
 */
class CaseBinderAlignFinalTransforms {
  static function prefer(names:Array<String>): Null<String> {
    if (names == null || names.length == 0) return null;
    var order = ["todo", "id", "message", "params", "reason"];
    for (p in order) for (n in names) if (n == p) return n;
    return null;
  }
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(target, clauses):
          var out = [];
          for (cl in clauses) {
            var binder = extractTagPayloadBinder(cl.pattern);
            if (binder != null) {
              #if sys Sys.println('[CaseBinderAlignFinal] clause with binder=' + binder); #end
              #if sys Sys.println('[CaseBinderAlignFinal] Found {:tag, ' + binder + '}'); #end
              var declared = collectDeclaredNames(cl.pattern, cl.body);
              var used = collectUsedLowerVars(cl.body);
              #if sys
              var declArr = [for (k in declared.keys()) k];
              Sys.println('[CaseBinderAlignFinal] declared=' + declArr.join(','));
              Sys.println('[CaseBinderAlignFinal] used=' + used.join(','));
              #end
              var undef:Array<String> = [];
              for (u in used) if (!declared.exists(u) && u != binder) undef.push(u);
              if (undef.length == 0) {
                var ex = new StringMap<Bool>();
                ex.set(binder, true);
                for (k in declared.keys()) ex.set(k, true);
                var alt = findFirstMeaningfulVar(cl.body, ex);
                if (alt != null) undef.push(alt);
              }
              #if sys Sys.println('[CaseBinderAlignFinal] used=' + used.join(',') + ' declared=' + (function(){var a=[]; for (k in declared.keys()) a.push(k); return a.join(','); })() + ' undef=' + undef.join(',')); #end
              // If multiple, try a semantic preference
              if (undef.length > 1) {
                var pref = prefer(undef);
                if (pref != null) undef = [pref];
              }
              if (undef.length == 1) {
                var newName = undef[0];
                var newPat = rewriteTagPayloadBinder(cl.pattern, newName);
                if (newPat != null) {
                  #if sys Sys.println('[CaseBinderAlignFinal] Renaming binder ' + binder + ' -> ' + newName); #end
                  var newBody = replaceVar(cl.body, binder, newName);
                  out.push({ pattern: newPat, guard: cl.guard, body: newBody });
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

  static function extractTagPayloadBinder(p:EPattern): Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) {
          case PLiteral(l):
            switch (es[1]) { case PVar(n): n; default: null; }
          default: null;
        }
      default: null;
    }
  }

  static function rewriteTagPayloadBinder(p:EPattern, newName:String): Null<EPattern> {
    return switch (p) {
      case PTuple(es) if (es.length == 2):
        switch (es[0]) { case PLiteral(_): switch (es[1]) { case PVar(_): PTuple([es[0], PVar(newName)]); default: null; } default: null; }
      default: null;
    }
  }

  static function collectDeclaredNames(p:EPattern, body: ElixirAST): Map<String,Bool> {
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
    // Body LHS
    ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
      switch (n.def) {
        case EMatch(pt, _): pat(pt);
        case EBinary(Match, {def: EVar(lhs)}, _): m.set(lhs, true);
        default:
      }
      return n;
    });
    return m;
  }

  static function collectUsedLowerVars(ast: ElixirAST): Array<String> {
    var names = new Map<String,Bool>();
    // Use builder-provided metadata when present
    try {
      var meta:Dynamic = ast.metadata;
      if (meta != null && untyped meta.usedLocalsFromTyped != null) {
        var arr:Array<String> = untyped meta.usedLocalsFromTyped;
        for (n in arr) if (n != null && n.length > 0 && isLower(n)) names.set(n, true);
      }
    } catch (e:Dynamic) {}

    ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      switch (n.def) {
        case EVar(v): if (isLower(v)) names.set(v,true);
        case EString(s):
          if (s != null && s.indexOf("#{") != -1) {
            var block = new EReg("\\#\\{([^}]*)\\}", "g");
            var pos = 0;
            while (block.matchSub(s, pos)) {
              var inner = block.matched(1);
              var tok = new EReg("[a-z_][a-z0-9_]*", "gi");
              var tpos = 0;
              while (tok.matchSub(inner, tpos)) {
                var id = tok.matched(0);
                if (isLower(id)) names.set(id, true);
                tpos = tok.matchedPos().pos + tok.matchedPos().len;
              }
              pos = block.matchedPos().pos + block.matchedPos().len;
            }
          }
        default:
      }
      return n;
    });
    return [for (k in names.keys()) k];
  }

  static function findFirstMeaningfulVar(ast: ElixirAST, exclude:StringMap<Bool>): Null<String> {
    var pick:Null<String> = null;
    ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      if (pick != null || n == null || n.def == null) return n;
      switch (n.def) {
        case EVar(v):
          if (isLower(v) && !exclude.exists(v)) pick = v;
        default:
      }
      return n;
    });
    return pick;
  }

  static inline function isLower(s:String):Bool {
    if (s == null || s.length == 0) return false;
    var c = s.charAt(0);
    return c.toLowerCase() == c;
  }

  static function replaceVar(body: ElixirAST, from:String, to:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(n:ElixirAST):ElixirAST {
      return switch (n.def) { case EVar(v) if (v == from): makeASTWithMeta(EVar(to), n.metadata, n.pos); default: n; };
    });
  }
}

#end
