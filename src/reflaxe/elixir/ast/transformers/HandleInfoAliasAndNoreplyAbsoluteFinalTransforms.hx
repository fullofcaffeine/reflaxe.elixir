package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleInfoAliasAndNoreplyAbsoluteFinalTransforms
 *
 * WHAT
 * - Absolute-final safety net for LiveView handle_info/2 clause bodies:
 *   1) Drop leading alias lines of the shape `name = _socket | socket`.
 *   2) Normalize `{:noreply, _socket}` to use the real `socket` param.
 *
 * WHY
 * - Earlier neutral lowerings or binder-collision repairs may introduce an
 *   alias to the socket argument inside a clause (`value = _socket`). Left in
 *   place, these trigger warnings-as-errors (unused alias, underscored var used
 *   after set). This pass removes such artifacts without app coupling.
 *
 * HOW
 * - Match def/defp handle_info/2; traverse ECase clauses and:
 *   - If the clause body is EBlock/EDo and its first statement matches an alias
 *     to `_socket` or `socket`, drop that statement.
 *   - Recursively rewrite ETuple `{:noreply, _socket}` to `{:noreply, socket}`.
 */
class HandleInfoAliasAndNoreplyAbsoluteFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleInfo2(name, args)):
          var nb = rewriteHandleInfoBody(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleInfo2(name2, args2)):
          var nb2 = rewriteHandleInfoBody(body2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleInfo2(name:String, args:Array<EPattern>):Bool {
    return name == "handle_info" && args != null && args.length == 2;
  }

  static function rewriteHandleInfoBody(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(tgt, clauses):
          var out = [];
          for (cl in clauses) {
            var b = dropLeadingAlias(cl.body);
            b = noreplySocketNormalize(b);
            out.push({ pattern: cl.pattern, guard: cl.guard, body: b });
          }
          makeASTWithMeta(ECase(tgt, out), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function dropLeadingAlias(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts) if (stmts.length > 0):
        var rest = stmts.copy();
        if (isAliasToSocket(rest[0])) rest.shift();
        makeASTWithMeta(EBlock(rest), body.metadata, body.pos);
      case EDo(stmts2) if (stmts2.length > 0):
        var r2 = stmts2.copy();
        if (isAliasToSocket(r2[0])) r2.shift();
        makeASTWithMeta(EDo(r2), body.metadata, body.pos);
      default: body;
    }
  }

  static function isAliasToSocket(stmt: ElixirAST): Bool {
    return switch (stmt.def) {
      case EBinary(Match, {def: EVar(_)}, {def: EVar(v)}) if (v == "_socket" || v == "socket"): true;
      case EMatch(PVar(_), {def: EVar(v2)}) if (v2 == "_socket" || v2 == "socket"): true;
      default: false;
    }
  }

  static function noreplySocketNormalize(e: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(e, function(z: ElixirAST): ElixirAST {
      return switch (z.def) {
        case ETuple(elems) if (elems.length == 2):
          switch (elems[0].def) {
            case EAtom(a) if (a == ":noreply" || a == "noreply"):
              switch (elems[1].def) {
                case EVar(v) if (v == "_socket"): makeASTWithMeta(ETuple([elems[0], makeAST(EVar("socket"))]), z.metadata, z.pos);
                default: z;
              }
            default: z;
          }
        default: z;
      }
    });
  }
}

#end

