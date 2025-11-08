package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CasePayloadBinderAvoidReservedTransforms
 *
 * WHAT
 * - Avoids using reserved names (socket, live_socket, params) as the payload binder
 *   in case patterns. When a clause binds a reserved name but the body clearly uses
 *   exactly one undefined variable, rename the binder to that variable and update the
 *   body references.
 *
 * WHY
 * - Prevents accidental collisions where the binder name shadows well-known env names
 *   in LiveView/Phoenix-like code but without tying to any app-specific tags.
 *
 * HOW
 * - For each ECase clause with {:atom, PVar(binder)} or {:atom, PVar(binder), ...}:
 *   - If binder is in {socket, live_socket, params}
 *   - Collect declared names (pattern + LHS in body) and used names in body.
 *   - Let candidates = used \ declared \ {binder}, excluding other reserved names.
 *   - If candidates has exactly one name, rename binder to that name and rewrite body
 *     occurrences of the old binder to the new one.
 */
class CasePayloadBinderAvoidReservedTransforms {
  static inline function isReserved(name:String):Bool {
    return name == "socket" || name == "live_socket" || name == "params";
  }

  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (isReserved(name)) return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c;
  }

  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(target, clauses):
          var out = [];
          for (cl in clauses) {
            var binder = extractPayloadBinder(cl.pattern);
            if (binder != null && isReserved(binder)) {
          #if (sys && debug_case_payload && !no_traces) Sys.println('[CasePayloadAvoidReserved] reserved binder ' + binder + ' detected'); #end
              var declared = new Map<String,Bool>();
              collectPatternVars(cl.pattern, declared);
              collectLhsVarsInBody(cl.body, declared);
              var used = collectUsedVars(cl.body);
              var cands:Array<String> = [];
              for (u in used.keys()) if (allow(u) && !declared.exists(u) && u != binder) cands.push(u);
              // Prefer common payload names when multiple candidates exist
              var preferred:Array<String> = ["todo", "id", "message", "params", "reason"];
              var chosen:Null<String> = null;
              if (cands.length > 1) {
                for (p in preferred) for (c in cands) if (c == p) { chosen = c; break; }
              } else if (cands.length == 1) {
                chosen = cands[0];
              }
              if (chosen != null) {
                #if (sys && debug_case_payload && !no_traces) Sys.println('[CasePayloadAvoidReserved] renaming binder ' + binder + ' -> ' + chosen); #end
                var newName = chosen;
                var newPat = rewritePayloadBinder(cl.pattern, newName);
                if (newPat != null) {
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

  static function extractPayloadBinder(p:EPattern):Null<String> {
    return switch (p) {
      case PTuple(es) if (es.length >= 2):
        switch (es[1]) { case PVar(n): n; default: null; }
      default: null;
    }
  }

  static function rewritePayloadBinder(p:EPattern, newName:String):Null<EPattern> {
    return switch (p) {
      case PTuple(es) if (es.length >= 2):
        switch (es[1]) { case PVar(_): PTuple([es[0], PVar(newName)].concat(es.slice(2))); default: null; }
      default: null;
    }
  }

  static function replaceVar(body: ElixirAST, from:String, to:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x:ElixirAST): ElixirAST {
      return switch (x.def) { case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos); default: x; };
    });
  }

  static function collectUsedVars(ast: ElixirAST): Map<String,Bool> {
    var names = new Map<String,Bool>();
    ElixirASTTransformer.transformNode(ast, function(e:ElixirAST): ElixirAST {
      switch (e.def) { case EVar(v): names.set(v, true); default: }
      return e;
    });
    return names;
  }

  static function collectLhsVarsInBody(body: ElixirAST, vars: Map<String,Bool>): Void {
    reflaxe.elixir.ast.ASTUtils.walk(body, function(e:ElixirAST) {
      if (e == null || e.def == null) return;
      switch (e.def) {
        case EMatch(p, _): collectPatternVars(p, vars);
        case EBinary(Match, l, _): collectLhs(l, vars);
        case ECase(_, cs): for (c in cs) collectPatternVars(c.pattern, vars);
        default:
      }
    });
  }

  static function collectPatternVars(p:EPattern, vars:Map<String,Bool>): Void {
    switch (p) {
      case PVar(n): vars.set(n, true);
      case PTuple(es) | PList(es): for (e in es) collectPatternVars(e, vars);
      case PCons(h,t): collectPatternVars(h, vars); collectPatternVars(t, vars);
      case PMap(kvs): for (kv in kvs) collectPatternVars(kv.value, vars);
      case PStruct(_, fs): for (f in fs) collectPatternVars(f.value, vars);
      case PPin(inner): collectPatternVars(inner, vars);
      default:
    }
  }

  static function collectLhs(l:ElixirAST, vars:Map<String,Bool>): Void {
    switch (l.def) { case EVar(n): vars.set(n, true); case EBinary(Match, l2, _): collectLhs(l2, vars); default: }
  }
}

#end
