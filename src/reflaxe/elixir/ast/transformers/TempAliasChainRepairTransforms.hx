package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * TempAliasChainRepairTransforms
 *
 * WHAT
 * - Repairs pathological temporary alias chains where a temp like `this1` is read
 *   before it is assigned, in the shape:
 *     varX = this1;
 *     _ = this1;
 *     this1 = expr;
 *   Rewrites to:
 *     varX = expr;   # drops the useless temp
 *
 * WHY
 * - Some normalization passes can reorder chains around temps (`thisN`) in ways that
 *   momentarily expose use-before-assign. This pass removes the temp entirely, producing
 *   a straightforward assignment. Shape-based and target-agnostic.
 */
class TempAliasChainRepairTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts):
          var out:Array<ElixirAST> = [];
          var i = 0;
          while (i < stmts.length) {
            if (i + 2 < stmts.length) {
              var s1 = stmts[i];
              var s2 = stmts[i+1];
              var s3 = stmts[i+2];
              var lhsName:Null<String> = null;
              var tempName:Null<String> = null;
              switch (s1.def) {
                case EBinary(Match, {def: EVar(lhs)}, {def: EVar(tmp)}) if (StringTools.startsWith(tmp, "this")):
                  lhsName = lhs; tempName = tmp;
                case EMatch(PVar(lhsM), {def: EVar(tmpM)}) if (StringTools.startsWith(tmpM, "this")):
                  lhsName = lhsM; tempName = tmpM;
                default:
              }
              if (lhsName != null && tempName != null) {
                var s2IsDiscard = switch (s2.def) {
                  case EBinary(Match, {def: EVar("_")}, {def: EVar(tmp2)}) if (tmp2 == tempName): true;
                  case EMatch(PVar("_"), {def: EVar(tmp3)}) if (tmp3 == tempName): true;
                  default: false;
                };
                var rhsOfTemp:Null<ElixirAST> = null;
                switch (s3.def) {
                  case EBinary(Match, {def: EVar(tmp4)}, rhs) if (tmp4 == tempName): rhsOfTemp = rhs;
                  case EMatch(PVar(tmp5), rhs2) if (tmp5 == tempName): rhsOfTemp = rhs2;
                  default:
                }
                if (s2IsDiscard && rhsOfTemp != null) {
                  // Emit: lhsName = rhsOfTemp
                  var newAssign = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(lhsName), s1.metadata, s1.pos), rhsOfTemp), s1.metadata, s1.pos);
                  out.push(newAssign);
                  i += 3; // drop the three original statements
                  continue;
                }
              }
            }
            out.push(stmts[i]);
            i++;
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        case EDo(stmts2):
          var out2:Array<ElixirAST> = [];
          var j = 0;
          while (j < stmts2.length) {
            if (j + 2 < stmts2.length) {
              var t1 = stmts2[j];
              var t2 = stmts2[j+1];
              var t3 = stmts2[j+2];
              var lhs2:Null<String> = null;
              var temp2:Null<String> = null;
              switch (t1.def) {
                case EBinary(Match, {def: EVar(lh)}, {def: EVar(tm)}) if (StringTools.startsWith(tm, "this")):
                  lhs2 = lh; temp2 = tm;
                case EMatch(PVar(lhM), {def: EVar(tmM)}) if (StringTools.startsWith(tmM, "this")):
                  lhs2 = lhM; temp2 = tmM;
                default:
              }
              if (lhs2 != null && temp2 != null) {
                var discard2 = switch (t2.def) {
                  case EBinary(Match, {def: EVar("_")}, {def: EVar(x)}) if (x == temp2): true;
                  case EMatch(PVar("_"), {def: EVar(x2)}) if (x2 == temp2): true;
                  default: false;
                };
                var rhs2:Null<ElixirAST> = null;
                switch (t3.def) {
                  case EBinary(Match, {def: EVar(tm3)}, r) if (tm3 == temp2): rhs2 = r;
                  case EMatch(PVar(tm4), r2) if (tm4 == temp2): rhs2 = r2;
                  default:
                }
                if (discard2 && rhs2 != null) {
                  out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(lhs2), t1.metadata, t1.pos), rhs2), t1.metadata, t1.pos));
                  j += 3; continue;
                }
              }
            }
            out2.push(stmts2[j]);
            j++;
          }
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
