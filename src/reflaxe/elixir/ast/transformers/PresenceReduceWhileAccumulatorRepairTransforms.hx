package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceReduceWhileAccumulatorRepairTransforms
 *
 * WHAT
 * - In Presence modules, when a function body contains a reduce_while loop that
 *   appends to an accumulator via Enum.concat(acc, [expr]) but no prior
 *   initialization exists, inject `acc = []` before the loop and, if the
 *   function returns `[]`, change it to return `acc`.
 */
class PresenceReduceWhileAccumulatorRepairTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (looksPresence(n, name)):
          var nb = [for (b in body) applyToDefs(b)];
          makeASTWithMeta(EModule(name, attrs, nb), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (looksPresence(n, name2)):
          makeASTWithMeta(EDefmodule(name2, applyToDefs(doBlock)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function looksPresence(node:ElixirAST, name:String):Bool {
    return (node.metadata?.isPresence == true) || (name != null && name.indexOf("Web.Presence") > 0) || StringTools.endsWith(name, ".Presence");
  }

  static function applyToDefs(node:ElixirAST):ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(x:ElixirAST):ElixirAST {
      return switch (x.def) {
        case EDef(fn, args, guards, body): makeASTWithMeta(EDef(fn, args, guards, fix(body)), x.metadata, x.pos);
        case EDefp(fn2, args2, guards2, body2): makeASTWithMeta(EDefp(fn2, args2, guards2, fix(body2)), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function fix(body:ElixirAST):ElixirAST {
    var accVar:String = null;
    var hasReduceWhile = false;
    function scan(n:ElixirAST):Void {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case ERemoteCall(_, func, _) if (func == "reduce_while"): hasReduceWhile = true;
        case ERemoteCall({def: EVar(modName)}, "concat", args) if (args != null && args.length >= 1):
          var isEnum = (modName == "Enum") || StringTools.endsWith(modName, ".Enum");
          if (isEnum) switch (args[0].def) { case EVar(v): accVar = v; default: }
        default:
      }
      switch (n.def) {
        case EBinary(_, l, r): scan(l); scan(r);
        case EMatch(_, rhs): scan(rhs);
        case EBlock(ss): for (s in ss) scan(s);
        case EDo(ss2): for (s in ss2) scan(s);
        case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
        case ECase(e2, cs): scan(e2); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
        case ECall(t,_,as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
        case ERemoteCall(t2,_,as2): scan(t2); if (as2 != null) for (a2 in as2) scan(a2);
        default:
      }
    }
    scan(body);
    if (!hasReduceWhile || accVar == null) return body;

    // Prepend acc = [] and replace final [] return with acc
    function rewriteTailReturnToAcc(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EBlock(stmts) if (stmts.length > 0):
          var last = stmts[stmts.length - 1];
          var newLast = switch (last.def) { case EList(_): makeAST(EVar(accVar)); default: last; };
          var prefix = stmts.copy(); prefix.pop();
          makeASTWithMeta(EBlock(prefix.concat([newLast])), n.metadata, n.pos);
        case EDo(stmts2) if (stmts2.length > 0):
          var last2 = stmts2[stmts2.length - 1];
          var newLast2 = switch (last2.def) { case EList(_): makeAST(EVar(accVar)); default: last2; };
          var prefix2 = stmts2.copy(); prefix2.pop();
          makeASTWithMeta(EDo(prefix2.concat([newLast2])), n.metadata, n.pos);
        default: n;
      }
    }

    var init = makeAST(EBinary(Match, makeAST(EVar(accVar)), makeAST(EList([]))));
    var withInit = switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock([init].concat(stmts)), body.metadata, body.pos);
      case EDo(stmts2): makeASTWithMeta(EDo([init].concat(stmts2)), body.metadata, body.pos);
      default: makeASTWithMeta(EBlock([init, body]), body.metadata, body.pos);
    }
    return rewriteTailReturnToAcc(withInit);
  }
}

#end
