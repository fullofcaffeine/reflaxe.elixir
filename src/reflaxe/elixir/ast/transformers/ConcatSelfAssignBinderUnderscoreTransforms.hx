package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ConcatSelfAssignBinderUnderscoreTransforms
 *
 * WHAT
 * - Rewrites statements of the form `x = Enum.concat(x, y)` to
 *   `_x = Enum.concat(x, y)` to avoid overshadowing warnings when the
 *   local binder `x` is not subsequently referenced. This keeps semantics
 *   (the concat result is computed) but prevents redefining the outer `x`.
 *
 * WHY
 * - Phoenix render helpers often fold list building via Enum.concat/2 and
 *   code generation may emit `item = Enum.concat(item, [...])` inside a block
 *   where `item` is also a surrounding variable. Elixir warns about the local
 *   `item` being unused. Underscoring the binder is idiomatic and silences it.
 */
class ConcatSelfAssignBinderUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return rewriteNode(ast);
  }

  static function rewriteNode(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EDef(name, args, g, body): makeASTWithMeta(EDef(name, args, g, rewriteNode(body)), n.metadata, n.pos);
        case EDefp(name2, args2, g2, body2): makeASTWithMeta(EDefp(name2, args2, g2, rewriteNode(body2)), n.metadata, n.pos);
        case EFn(clauses):
          var outClauses = [];
          for (cl in clauses) outClauses.push({ args: cl.args, guard: cl.guard, body: rewriteNode(cl.body) });
          makeASTWithMeta(EFn(outClauses), n.metadata, n.pos);
        case ECase(expr, clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: rewriteNode(cl.body) });
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      switch (s.def) {
        case EBinary(Match, {def: EVar(b)}, {def: ERemoteCall({def: EVar("Enum")}, "concat", args)}) if (args != null && args.length >= 1):
          switch (args[0].def) {
            case EVar(b2) if (b2 == b):
              out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b)), makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", args))), s.metadata, s.pos));
            default:
              out.push(s);
          }
        case EBinary(Match, {def: EVar(b)}, {def: ECall(target, fnName, argsC)}) if (fnName == "concat" && argsC != null && argsC.length >= 1):
          var isEnum = switch (target.def) { case EVar(m): m == "Enum"; default: false; };
          if (isEnum) switch (argsC[0].def) {
            case EVar(b2c) if (b2c == b):
              out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b)), makeAST(ECall(target, fnName, argsC))), s.metadata, s.pos));
            default:
              out.push(s);
          } else out.push(s);
        case EMatch(PVar(b3), {def: ERemoteCall({def: EVar("Enum")}, "concat", args2)}) if (args2 != null && args2.length >= 1):
          switch (args2[0].def) {
            case EVar(b4) if (b4 == b3):
              out.push(makeASTWithMeta(EMatch(PVar('_' + b3), makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", args2))), s.metadata, s.pos));
            default:
              out.push(s);
          }
        case EMatch(PVar(b3c), {def: ECall(target2, fnName2, args2c)}) if (fnName2 == "concat" && args2c != null && args2c.length >= 1):
          var isEnum2 = switch (target2.def) { case EVar(m2): m2 == "Enum"; default: false; };
          if (isEnum2) switch (args2c[0].def) {
            case EVar(b4c) if (b4c == b3c):
              out.push(makeASTWithMeta(EMatch(PVar('_' + b3c), makeAST(ECall(target2, fnName2, args2c))), s.metadata, s.pos));
            default:
              out.push(s);
          } else out.push(s);
        default:
          out.push(s);
      }
    }
    return out;
  }
}

#end
