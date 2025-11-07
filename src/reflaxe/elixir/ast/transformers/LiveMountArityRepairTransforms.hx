package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LiveMountArityRepairTransforms
 *
 * WHAT
 * - Repairs Phoenix LiveView mount function heads to the canonical arity and binder names.
 *
 * WHY
 * - Some generation paths may yield incorrect mount heads (extra params, duplicate socket),
 *   which breaks idiomatic mount/3 and downstream LiveView transforms.
 *
 * HOW
 * - For any def/defp named "mount":
 *   - If args.length != 3, coerce to 3 by selecting the first two args and the last arg as socket.
 *   - Standardize names to (params, _session, socket) when patterns are simple PVar.
 *   - Rewrite body references from old names to the standardized binders.
 * - Shape-based only; no app-specific heuristics.
 */
class LiveMountArityRepairTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "mount" && args != null && args.length != 3):
          var newArgs:Array<EPattern> = [];
          var renameFromTo:Map<String,String> = new Map();
          var first: EPattern = args[0];
          var second: EPattern = (args.length >= 2) ? args[1] : PVar("_session");
          var last: EPattern = args[args.length - 1];
          // Standardize names when possible
          switch (first) { case PVar(old): newArgs.push(PVar("params")); renameFromTo.set(old, "params"); default: newArgs.push(first); }
          switch (second) { case PVar(old2): newArgs.push(PVar("_session")); renameFromTo.set(old2, "_session"); default: newArgs.push(second); }
          switch (last) { case PVar(old3): newArgs.push(PVar("socket")); renameFromTo.set(old3, "socket"); default: newArgs.push(last); }
          var newBody = renameVarsInBody(body, renameFromTo);
          makeASTWithMeta(EDef(name, newArgs, guards, newBody), n.metadata, n.pos);
        case EDefp(namep, argsp, guardsp, bodyp) if (namep == "mount" && argsp != null && argsp.length != 3):
          var newArgsp:Array<EPattern> = [];
          var rename:Map<String,String> = new Map();
          var f: EPattern = argsp[0];
          var s: EPattern = (argsp.length >= 2) ? argsp[1] : PVar("_session");
          var l: EPattern = argsp[argsp.length - 1];
          switch (f) { case PVar(o): newArgsp.push(PVar("params")); rename.set(o, "params"); default: newArgsp.push(f); }
          switch (s) { case PVar(o2): newArgsp.push(PVar("_session")); rename.set(o2, "_session"); default: newArgsp.push(s); }
          switch (l) { case PVar(o3): newArgsp.push(PVar("socket")); rename.set(o3, "socket"); default: newArgsp.push(l); }
          var nb = renameVarsInBody(bodyp, rename);
          makeASTWithMeta(EDefp(namep, newArgsp, guardsp, nb), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function renameVarsInBody(body: ElixirAST, mapping: Map<String,String>): ElixirAST {
    if (mapping == null || mapping.keys().hasNext() == false) return body;
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (mapping.exists(v)):
          makeASTWithMeta(EVar(mapping.get(v)), x.metadata, x.pos);
        default:
          x;
      };
    });
  }
}

#end

