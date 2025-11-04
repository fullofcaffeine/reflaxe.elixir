package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleInfoSomeClauseNormalizeTransforms
 *
 * WHAT
 * - Shape-specific normalization for LiveView handle_info/2: rewrites
 *   `case parse_message(msg) do {:some, b} -> alias = b; case b do ... end end`
 *   to a cleaner form without the alias and ensures noreply returns use the
 *   actual socket argument, avoiding WAE warnings.
 */
class HandleInfoSomeClauseNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "handle_info" || name == "handleInfo"):
          #if sys Sys.println('[HandleInfoSomeNormalize] Visiting ' + name); #end
          var socketArg: Null<String> = extractSocketArg(args);
          var nb = normalizeHandleInfoBody(body, socketArg);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function extractSocketArg(args:Array<EPattern>):Null<String> {
    if (args == null || args.length < 2) return "socket";
    return switch (args[1]) { case PVar(nm): nm; default: "socket"; }
  }

  static function normalizeHandleInfoBody(body: ElixirAST, socketName:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(tgt, clauses):
          var newClauses = [];
          for (cl in clauses) {
            var c2 = cl;
            // Only target {:some, binder} clauses
            var binder: Null<String> = null;
            var parts: Array<EPattern> = null;
            switch (cl.pattern) {
              case PTuple(ps) if (ps.length == 2):
                parts = ps;
                switch (ps[0]) {
                  case PLiteral(l) if (switch (l.def) { case EAtom(a): a == ":some" || a == "some"; default: false; }):
                    switch (ps[1]) { case PVar(nm): binder = nm; default: }
                  default:
                }
              default:
            }
            if (binder != null) {
              #if sys Sys.println('[HandleInfoSomeNormalize] Found {:some, ' + binder + '}'); #end
              // Attempt to collapse alias `alias = binder` and rewire inner case
              var newBody = cl.body;
              // Remove leading alias assignment
              newBody = dropLeadingAlias(newBody, binder);
              // Rewrite {:noreply, binder} to {:noreply, socket}
              newBody = rewriteNoreplySocket(newBody, binder, socketName);
              // Promote underscored binder in pattern to trimmed
              var promoted = binder;
              if (binder.length > 1 && binder.charAt(0) == '_') promoted = binder.substr(1);
              var ps2 = parts.copy();
              ps2[1] = PVar(promoted);
              var newPat = PTuple(ps2);
              // Rename body references of binder to promoted
              newBody = ElixirASTTransformer.transformNode(newBody, function(y: ElixirAST): ElixirAST {
                return switch (y.def) {
                  case EVar(v) if (v == binder): makeASTWithMeta(EVar(promoted), y.metadata, y.pos);
                  default: y;
                }
              });
              c2 = { pattern: newPat, guard: cl.guard, body: newBody };
            }
            newClauses.push(c2);
          }
          makeASTWithMeta(ECase(tgt, newClauses), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function dropLeadingAlias(body: ElixirAST, binder:String): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts) if (stmts.length > 0):
        var rest = stmts.copy();
        if (isAliasOf(rest[0], binder)) rest.shift();
        makeASTWithMeta(EBlock(rest), body.metadata, body.pos);
      case EDo(stmts2) if (stmts2.length > 0):
        var r2 = stmts2.copy();
        if (isAliasOf(r2[0], binder)) r2.shift();
        makeASTWithMeta(EDo(r2), body.metadata, body.pos);
      default:
        body;
    }
  }

  static function isAliasOf(stmt: ElixirAST, binder:String): Bool {
    return switch (stmt.def) {
      // Drop alias lines that bind to the tuple payload binder OR to the
      // socket variable produced by earlier normalizations. This makes the
      // cleanup resilient to ordering (e.g., when a pre-pass renames the
      // binder away from `_socket`).
      case EBinary(Match, {def: EVar(_)}, {def: EVar(v)}) if (v == binder || v == "_socket" || v == "socket"): true;
      case EMatch(PVar(_), {def: EVar(v2)}) if (v2 == binder || v2 == "_socket" || v2 == "socket"): true;
      default: false;
    }
  }

  static function rewriteNoreplySocket(body: ElixirAST, binder:String, socketName:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(z: ElixirAST): ElixirAST {
      return switch (z.def) {
        case ETuple(elems) if (elems.length == 2):
          switch (elems[0].def) {
            case EAtom(a) if (a == ":noreply" || a == "noreply"):
              switch (elems[1].def) {
                case EVar(v) if (v == binder || v == "_socket"):
                  makeASTWithMeta(ETuple([elems[0], makeAST(EVar(socketName))]), z.metadata, z.pos);
                default: z;
              }
            default: z;
          }
        default:
          z;
      }
    });
  }
}

#end
