package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnBinderAlignToUndefinedRefTransforms
 *
 * WHAT
 * - In single-arg anonymous functions, if there is a single undefined simple
 *   variable referenced in the body, rename the binder to that undefined name
 *   and rewrite binder references accordingly.
 *
 * WHY
 * - Some loop builders fall back to a generic binder name (e.g., "item").
 *   When the original body relies on a specific name (e.g., "todo"), later
 *   passes can leave it undefined. Unifying the binder name to the intended
 *   body reference is shape-safe when the undefined name is unique.
 *
 * HOW
 * - For each EFn clause with exactly one PVar binder:
 *   1) Collect declared names inside the clause (including binder and inner LHS binds).
 *   2) Collect referenced simple EVar names and compute undefined.
 *   3) If undefined.length == 1, let u be that name. Rename binder argName->u and
 *      rewrite EVar(argName) -> EVar(u) in the clause body.
 */
class EFnBinderAlignToUndefinedRefTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EFn(clauses):
          var newClauses = [];
          for (cl in clauses) {
            var argName: Null<String> = null;
            if (cl.args != null && cl.args.length == 1) {
              switch (cl.args[0]) { case PVar(a): argName = a; default: }
            }
            if (argName == null) { newClauses.push(cl); continue; }
            var declared = new Map<String,Bool>();
            declared.set(argName, true);
            function collectPat(p:EPattern):Void {
              switch (p) {
                case PVar(n): declared.set(n, true);
                case PTuple(es) | PList(es): for (e in es) collectPat(e);
                case PCons(h,t): collectPat(h); collectPat(t);
                case PMap(kvs): for (kv in kvs) collectPat(kv.value);
                case PStruct(_, fs): for (f in fs) collectPat(f.value);
                case PPin(inner): collectPat(inner);
                default:
              }
            }
            // Helper to detect local variable names (exclude modules/captures)
            inline function isLocalVarName(s:String):Bool {
              if (s == null || s.length == 0) return false;
              var c = s.charAt(0);
              var isUpper = c == c.toUpperCase() && c != c.toLowerCase();
              if (isUpper) return false;
              if (s.indexOf('.') != -1) return false;
              return true;
            }
            // Scan clause body for declared and referenced names
            var referenced = new Map<String,Bool>();
            ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
              switch (x.def) {
                case EMatch(p, _): collectPat(p);
                case EBinary(Match, l, _):
                  switch (l.def) { case EVar(v): declared.set(v, true); default: }
                case ECase(_, cs): for (c in cs) collectPat(c.pattern);
                case EVar(v) if (isLocalVarName(v)): referenced.set(v, true);
                default:
              }
              return x;
            });
            // Gather undefined refs and those used as struct/map field receivers
            var undefined = [for (k in referenced.keys()) if (!declared.exists(k)) k];
            var fieldReceivers = new Map<String,Bool>();
            ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
              return switch (x.def) {
                case EField({def: EVar(v)}, _ ) if (isLocalVarName(v) && !declared.exists(v)):
                  fieldReceivers.set(v, true); x;
                default: x;
              };
            });
            #if debug_ast_transformer
            if (undefined.length > 0) // DEBUG: Sys.println('[EFnBinderAlignToUndefinedRef] arg=' + argName + ' undefined=' + undefined.join(','));
            #end
            var receiverList = [for (k in fieldReceivers.keys()) k];
            #if debug_ast_transformer
            // Emit context: whether this EFn is used as Enum.each(..., fn -> ... end)
            var inEnumEach = false;
            ElixirASTTransformer.transformNode(cl.body, function(y: ElixirAST): ElixirAST {
              // no-op traversal; just here to allow potential future context
              return y;
            });
            // DEBUG: Sys.println('[EFnBinderAlignToUndefinedRef] binder=' + argName + ' undefined={' + undefined.join(',') + '} fieldReceivers={' + receiverList.join(',') + '}');
            #end
            if (receiverList.length == 1) {
              var u = receiverList[0];
              #if debug_ast_transformer
              #end
              // Rename binder and its uses to u
              var newBody = ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                return switch (x.def) {
                  case EVar(v) if (v == argName): makeASTWithMeta(EVar(u), x.metadata, x.pos);
                  default: x;
                }
              });
              newClauses.push({ args: [PVar(u)], guard: cl.guard, body: newBody });
            } else {
              newClauses.push(cl);
            }
          }
          makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
