package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * InlinePrevAssignIntoArgTransforms
 *
 * WHAT
 * - In a block, when an assignment `v = expr` is immediately followed by a function call
 *   whose first argument compares `case :binary.match(v, sub) do ... end` with 0/-1, rewrite
 *   the call to use `:binary.match(expr, sub) != :nomatch` and drop the preceding assignment.
 *
 * WHY
 * - Removes transient temps that force multi-statement arguments and may lead to invalid formatting.
 *
 * HOW
 * - Scan EBlock/EDo sequential statements for [assign, call] pairs and apply shape-based rewrite.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class InlinePrevAssignIntoArgTransforms {
  static inline function isBinaryModule(mod: ElixirAST): Bool {
    return switch (mod.def) {
      case EVar(m): (m == ":binary" || m == "binary");
      case EAtom(a):
        var s: String = a;
        s == ":binary" || s == "binary";
      default:
        false;
    };
  }

  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewriteSeq(stmts)), n.metadata, n.pos);
        case EDo(stmts): makeASTWithMeta(EDo(rewriteSeq(stmts)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteSeq(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null || stmts.length < 2) return stmts;
    var out:Array<ElixirAST> = [];
    var i = 0;
    while (i < stmts.length) {
      if (i + 1 < stmts.length) {
        var lhsVar: Null<String> = null;
        var rhsExpr: Null<ElixirAST> = null;
        switch (stmts[i].def) {
          case EBinary(Match, {def: EVar(v)}, rhs): lhsVar = v; rhsExpr = rhs;
          case EMatch(PVar(v), rhs): lhsVar = v; rhsExpr = rhs;
          default:
        }
        if (lhsVar != null && rhsExpr != null) {
          var next = stmts[i+1];
          var replaced: Null<ElixirAST> = tryRewriteCallUsingVar(next, lhsVar, rhsExpr);
          if (replaced != null) {
            out.push(replaced);
            i += 2; // drop assignment
            continue;
          }
        }
      }
      out.push(stmts[i]); i++;
    }
    return out;
  }

  static function tryRewriteCallUsingVar(callNode: ElixirAST, varName: String, rhs: ElixirAST): Null<ElixirAST> {
    function normalizeArg(a: ElixirAST): Null<ElixirAST> {
      return switch (a.def) {
        case EBinary(op, left, right) if ((op == GreaterEqual && isZero(right)) || (op == Greater && isMinusOne(right))):
          switch (left.def) {
            case ECase(matchExpr, _):
              switch (matchExpr.def) {
                case ERemoteCall(mod, fnName, margs) if (fnName == "match" && margs != null && margs.length == 2 && isBinaryModule(mod)):
                  switch (margs[0].def) { case EVar(v) if (v == varName):
                    var binMod = makeAST(EVar(":binary"));
                    var newCall = makeAST(ERemoteCall(binMod, "match", [rhs, margs[1]]));
                    var nomatch = makeAST(EAtom(":nomatch"));
                    makeAST(EBinary(NotEqual, newCall, nomatch));
                  default: null; }
                case ECall(target, fnName, margs) if (target != null && fnName == "match" && margs != null && margs.length == 2 && isBinaryModule(target)):
                  switch (margs[0].def) { case EVar(v) if (v == varName):
                    var binMod = makeAST(EVar(":binary"));
                    var newCall = makeAST(ERemoteCall(binMod, "match", [rhs, margs[1]]));
                    var nomatch = makeAST(EAtom(":nomatch"));
                    makeAST(EBinary(NotEqual, newCall, nomatch));
                  default: null; }
                default: null;
              }
            default: null;
          }
        default: null;
      }
    }
    return switch (callNode.def) {
      case ECall(t, fnName, args) if (args != null && args.length >= 1):
        var newFirst = normalizeArg(args[0]);
        if (newFirst != null) makeASTWithMeta(ECall(t, fnName, [newFirst].concat(args.slice(1))), callNode.metadata, callNode.pos) else null;
      case ERemoteCall(m, fnName, args) if (args != null && args.length >= 1):
        var newFirst = normalizeArg(args[0]);
        if (newFirst != null) makeASTWithMeta(ERemoteCall(m, fnName, [newFirst].concat(args.slice(1))), callNode.metadata, callNode.pos) else null;
      default: null;
    }
  }

  static inline function isZero(e: ElixirAST): Bool {
    return switch (e.def) { case EInteger(v) if (v == 0): true; default: false; }
  }
  static inline function isMinusOne(e: ElixirAST): Bool {
    return switch (e.def) { case EInteger(v) if (v == -1): true; default: false; }
  }
}

#end
