package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleInfoAliasCleanupTransforms
 *
 * WHAT
 * - In handle_info/2 bodies, remove alias lines of the form `alias = _socket`
 *   and replace later references to `alias` with `socket`.
 * - Also rewrite any `{:noreply, _socket}` to `{:noreply, socket}`.
 *
 * WHY
 * - Neutral lowerings may introduce `_socket` and alias lines that trigger
 *   warnings-as-errors. This pass cleans them up without app coupling.
 */
class HandleInfoAliasCleanupTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "handle_info" || name == "handleInfo"):
          var nb = cleanup(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function cleanup(body: ElixirAST): ElixirAST {
    // Find alias = _socket at top-level of the nearest block and record alias name
    var aliasName: Null<String> = null;
    function scanForAlias(stmts:Array<ElixirAST>):Array<ElixirAST> {
      var out:Array<ElixirAST> = [];
      for (i in 0...stmts.length) {
        var s = stmts[i];
        var removed = false;
        switch (s.def) {
          case EBinary(Match, left, right):
            switch (left.def) {
              case EVar(nm):
                switch (right.def) {
                  case EVar(rv) if (rv == "_socket" || rv == "socket"):
                    aliasName = nm; // record alias and drop this statement
                    removed = true;
                  default:
                }
              default:
            }
          default:
        }
        if (!removed) out.push(s);
      }
      return out;
    }

    function replaceAlias(e: ElixirAST): ElixirAST {
      // Always run replacement so `_socket` → `socket` is normalized even when
      // no alias line is present at the current block level.
      return ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST {
        return switch (x.def) {
          case EVar(v) if (v == aliasName || v == "_socket"): makeASTWithMeta(EVar("socket"), x.metadata, x.pos);
          case ETuple(elems) if (elems.length == 2):
            switch (elems[0].def) {
              case EAtom(a) if (a == ":noreply" || a == "noreply"):
                switch (elems[1].def) {
                  case EVar(v2) if (v2 == "_socket" || (aliasName != null && v2 == aliasName) || v2 == "socket"):
                    var newElems = [elems[0], makeASTWithMeta(EVar("socket"), x.metadata, x.pos)];
                    makeASTWithMeta(ETuple(newElems), x.metadata, x.pos);
                  default: x;
                }
              default: x;
            }
          default: x;
        }
      });
    }

    return switch (body.def) {
      case EBlock(stmts):
        var kept = scanForAlias(stmts);
        var b2 = makeASTWithMeta(EBlock(kept), body.metadata, body.pos);
        replaceAlias(b2);
      case EDo(stmts2):
        var kept2 = scanForAlias(stmts2);
        var d2 = makeASTWithMeta(EDo(kept2), body.metadata, body.pos);
        replaceAlias(d2);
      default:
        replaceAlias(body);
    }
  }
}

#end
