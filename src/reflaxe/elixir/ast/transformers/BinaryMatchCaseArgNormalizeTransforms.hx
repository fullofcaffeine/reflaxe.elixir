package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * BinaryMatchCaseArgNormalizeTransforms
 *
 * WHAT
 * - Normalize function arguments shaped as:
 *   (fn -> var = <expr>; case :binary.match(var, sub) do {pos,_} -> pos; :nomatch -> -1 end >= 0 end).()
 *   or as a plain block within the argument, into:
 *   (:binary.match(<expr>, sub) != :nomatch)
 *
 * WHY
 * - Avoids invalid multi-line argument formatting and yields a compact boolean expression.
 *
 * HOW
 * - For each ECall/ERemoteCall, inspect args; when an arg is a two-statement block
 *   (assignment to a simple var followed by comparison of a case on :binary.match),
 *   replace it with a NotEqual comparison against :nomatch using the RHS of the assignment.
 */
class BinaryMatchCaseArgNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ECall(t, fnName, args):
          makeASTWithMeta(ECall(t, fnName, normalizeArgs(args)), n.metadata, n.pos);
        case ERemoteCall(m, fnName, args):
          makeASTWithMeta(ERemoteCall(m, fnName, normalizeArgs(args)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function normalizeArgs(args:Array<ElixirAST>): Array<ElixirAST> {
    if (args == null) return args;
    var out:Array<ElixirAST> = [];
    for (a in args) out.push(normalizeArg(a));
    return out;
  }

  static function normalizeArg(arg: ElixirAST): ElixirAST {
    // Unwrap (fn -> block end).() into block for analysis
    var candidate: ElixirAST = switch (arg.def) {
      case ECall({def: EFn(clauses)}, _, []) if (clauses.length == 1):
        clauses[0].body;
      case EParen(inner):
        inner;
      default:
        arg;
    };
    // Only for two-statement blocks
    var stmts: Array<ElixirAST> = switch (candidate.def) {
      case EBlock(ss) if (ss.length >= 2): ss;
      case EDo(ss2) if (ss2.length >= 2): ss2;
      case EParen(inner2):
        switch (inner2.def) { case EBlock(ss3) if (ss3.length >= 2): ss3; case EDo(ss4) if (ss4.length >= 2): ss4; default: null; }
      default: null;
    }
    if (stmts == null) return arg;
    // First stmt: var assignment
    var varName: Null<String> = null;
    var rhsExpr: Null<ElixirAST> = null;
    switch (stmts[0].def) {
      case EBinary(Match, {def: EVar(v)}, rhs): varName = v; rhsExpr = rhs;
      case EMatch(PVar(v2), rhs2): varName = v2; rhsExpr = rhs2;
      default:
    }
    if (varName == null || rhsExpr == null) return arg;
    // Second stmt: comparison of case :binary.match(var, sub)
    var cmp: Null<ElixirAST> = stmts[1];
    // Accept additional trailing stmts but operate on stmts[1]
    var ok = false;
    var subExpr: Null<ElixirAST> = null;
    switch (cmp.def) {
      case EBinary(op, left, right) if ((op == GreaterEqual && isZero(right)) || (op == Greater && isMinusOne(right))):
        switch (left.def) {
          case ECase(matchExpr, clauses):
            // matchExpr must be :binary.match(varName, sub)
            switch (matchExpr.def) {
              case ERemoteCall({def: EVar(m)}, fnName, margs) if (m == ":binary" && fnName == "match" && margs != null && margs.length == 2):
                switch (margs[0].def) { case EVar(v) if (v == varName): ok = true; default: }
                if (ok) subExpr = margs[1];
              default:
            }
          default:
        }
      default:
    }
    if (!ok || subExpr == null) return arg;
    // Build boolean: :binary.match(rhsExpr, subExpr) != :nomatch
    var binMod = makeAST(EVar(":binary"));
    var call = makeAST(ERemoteCall(binMod, "match", [rhsExpr, subExpr]));
    var nomatch = makeAST(EAtom(":nomatch"));
    return makeAST(EBinary(NotEqual, call, nomatch));
  }

  static inline function isZero(e: ElixirAST): Bool {
    return switch (e.def) { case EInteger(v) if (v == 0): true; default: false; }
  }
  static inline function isMinusOne(e: ElixirAST): Bool {
    return switch (e.def) { case EInteger(v) if (v == -1): true; default: false; }
  }
}

#end
