package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

class AssignChainGenericSimplifyTransforms {
  static function unwrapRhsAssign(e: ElixirAST): Null<{a:String, b:String, rhs:ElixirAST}> {
    if (e == null || e.def == null) return null;
    return switch (e.def) {
      case EBinary(Match, {def: EVar(b)}, rhs): {a: null, b: b, rhs: rhs};
      case EMatch(PVar(bm), rhsM): {a: null, b: bm, rhs: rhsM};
      case EParen(inner): unwrapRhsAssign(inner);
      case EBlock(es) if (es.length == 1): unwrapRhsAssign(es[0]);
      default: null;
    }
  }
  public static function simplifyPass(ast: ElixirAST): ElixirAST {
    return transformPass(ast);
  }
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EFn(clauses):
          var newClauses = [];
          for (cl in clauses) {
            var nb = transformPass(cl.body);
            newClauses.push({ args: cl.args, guard: cl.guard, body: nb });
          }
          makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
        case EBlock(stmts):
          var out = [];
          var i = 0;
          while (i < stmts.length) {
            var s = stmts[i];
            switch (s.def) {
              case EBinary(Match, {def: EVar(a)}, rhsAny):
                var un = unwrapRhsAssign(rhsAny);
                if (un != null && un.b != null && un.rhs != null) {
                  var b = un.b; var rhs = un.rhs;
                  out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b), s.metadata, s.pos), rhs), s.metadata, s.pos));
                  out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), s.metadata, s.pos), makeASTWithMeta(EVar(b), s.metadata, s.pos)), s.metadata, s.pos));
                  break;
                } else {
                  out.push(s);
                }
              case EMatch(PVar(a2), rhsAny2):
                var un2 = unwrapRhsAssign(rhsAny2);
                if (un2 != null && un2.b != null && un2.rhs != null) {
                  var b2 = un2.b; var rhs2 = un2.rhs;
                  out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b2), s.metadata, s.pos), rhs2), s.metadata, s.pos));
                  out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a2), s.metadata, s.pos), makeASTWithMeta(EVar(b2), s.metadata, s.pos)), s.metadata, s.pos));
                  break;
                } else {
                  out.push(s);
                }
              default:
                out.push(s);
            }
            i++;
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        case EDo(stmts2):
          var out2 = [];
          for (s in stmts2) {
            switch (s.def) {
              case EBinary(Match, {def: EVar(a2)}, rhsAny3):
                var un3 = unwrapRhsAssign(rhsAny3);
                if (un3 != null && un3.b != null && un3.rhs != null) {
                  var b2 = un3.b; var rhs2 = un3.rhs;
                  out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b2), s.metadata, s.pos), rhs2), s.metadata, s.pos));
                  out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a2), s.metadata, s.pos), makeASTWithMeta(EVar(b2), s.metadata, s.pos)), s.metadata, s.pos));
                  break;
                } else {
                  out2.push(s);
                }
              case EMatch(PVar(a3), rhsAny4):
                var un4 = unwrapRhsAssign(rhsAny4);
                if (un4 != null && un4.b != null && un4.rhs != null) {
                  var b3 = un4.b; var rhs3 = un4.rhs;
                  out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b3), s.metadata, s.pos), rhs3), s.metadata, s.pos));
                  out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a3), s.metadata, s.pos), makeASTWithMeta(EVar(b3), s.metadata, s.pos)), s.metadata, s.pos));
                  break;
                } else {
                  out2.push(s);
                }
              default:
                out2.push(s);
            }
          }
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
