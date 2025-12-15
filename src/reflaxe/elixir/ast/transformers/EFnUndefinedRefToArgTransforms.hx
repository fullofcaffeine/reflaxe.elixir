package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EFnUndefinedRefToArgTransforms
 *
 * WHAT
 * - In anonymous function clauses with exactly one argument (fn arg -> ... end),
 *   if there is exactly one undefined simple variable reference in the clause body,
 *   rewrite that reference to the argument binder.
 *
 * WHY
 * - Late renames and loop shaping sometimes leave a drifted name inside closures
 *   (e.g., using `entry` when the only clause binder is `item`). This is a clear
 *   single-source-of-truth scenario where the only undefined body var should be
 *   the clause binder.
 *
 * HOW
 * - For each EFn clause with a single PVar binder:
 *   1) Collect declared names inside the clause body (EMatch/EBinary(Match) LHS and nested patterns).
 *   2) Collect referenced simple EVar names.
 *   3) Compute undefined = referenced − declared.
 *   4) If undefined has exactly one element U, rewrite EVar(U) → EVar(argName).
 * - Never affects clauses with multiple args or multiple undefineds (safety guard).
 */
class EFnUndefinedRefToArgTransforms {
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

            // Collect declared names inside clause body
            var declared = new Map<String,Bool>();
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
            // Seed with the arg binder
            declared.set(argName, true);
            ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
              switch (x.def) {
                case EMatch(p, _): collectPat(p);
                case EBinary(Match, l, _):
                  switch (l.def) { case EVar(v): declared.set(v, true); default: }
                case ECase(_, cs): for (c in cs) collectPat(c.pattern);
                default:
              }
              return x;
            });

            // Collect referenced simple vars (exclude module-like names: UpperCamel or with dot)
            inline function isLocalVarName(s:String):Bool {
              if (s == null || s.length == 0) return false;
              var c = s.charAt(0);
              var isUpper = c == c.toUpperCase() && c != c.toLowerCase();
              if (isUpper) return false;
              if (s.indexOf('.') != -1) return false;
              return true;
            }
            // Collect referenced simple vars
            var referenced = new Map<String,Bool>();
            ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
              switch (x.def) {
                case EVar(v) if (isLocalVarName(v)): referenced.set(v, true);
                default:
              }
              return x;
            });

            // If the clause argument binder is already referenced in the body, this closure
            // is not a single-source-of-truth situation. It may intentionally capture and
            // use outer variables (e.g., comparing `todo.id` to `id`). Do not rewrite.
            if (referenced.exists(argName)) {
              newClauses.push(cl);
              continue;
            }

            // Compute undefined references
            var undefined = [for (k in referenced.keys()) if (!declared.exists(k)) k];
            #if debug_ast_transformer
            if (undefined.length > 0) {
              // DEBUG: Sys.println('[EFnUndefinedRefToArg] arg=' + argName + ' undefined=' + undefined.join(','));
            }
            #end
            if (undefined.length == 1) {
              var u = undefined[0];
              #if debug_ast_transformer
              #end
              var newBody = ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                return switch (x.def) {
                  case EVar(v) if (v == u): makeASTWithMeta(EVar(argName), x.metadata, x.pos);
                  default: x;
                }
              });
              newClauses.push({ args: cl.args, guard: cl.guard, body: newBody });
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
