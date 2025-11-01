package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PresenceConcatAccumulatorInitTransforms
 *
 * WHAT
 * - Inside Presence modules, ensure accumulators used in `Enum.concat(acc, [expr])`
 *   are initialized to `[]` if no prior definition exists in the function body.
 *
 * WHY
 * - Some rewrite passes may remove the explicit `acc = []` initializer when
 *   converting iteration shapes. This restores the missing initialization to
 *   keep code valid and warnings-free.
 */
class PresenceConcatAccumulatorInitTransforms {
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

  static function applyToDefs(node:ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(x:ElixirAST): ElixirAST {
      return switch (x.def) {
        case EDef(fn, args, guards, body):
          makeASTWithMeta(EDef(fn, args, guards, ensureInit(body)), x.metadata, x.pos);
        case EDefp(fn2, args2, guards2, body2):
          makeASTWithMeta(EDefp(fn2, args2, guards2, ensureInit(body2)), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function ensureInit(body:ElixirAST): ElixirAST {
    var needsInit = new Map<String,Bool>();
    var hasInitList = new Map<String,Bool>();

    // Scan body for concat uses and definitions in a single pass
    function scan(n:ElixirAST):Void {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EBinary(Match, {def: EVar(lhs)}, rhs0):
          switch (rhs0.def) { case EList(_): hasInitList.set(lhs, true); default: }
        case EMatch(PVar(lhs2), rhs1):
          switch (rhs1.def) { case EList(_): hasInitList.set(lhs2, true); default: }
        case ERemoteCall({def: EVar(modName)}, fn, args) if (fn == "concat" && args != null && args.length >= 1):
          var isEnum = (modName == "Enum") || StringTools.endsWith(modName, ".Enum");
          if (isEnum) switch (args[0].def) { case EVar(v): needsInit.set(v, true); default: }
        default:
      }
      // Recurse
      switch (n.def) {
        case EBinary(_, l, r): scan(l); scan(r);
        case EMatch(_, rhs): scan(rhs);
        case EBlock(ss): for (s in ss) scan(s);
        case EDo(ss2): for (s in ss2) scan(s);
        case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
        case ECase(e2, cs): scan(e2); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
        case ECall(t,_,as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
        case ERemoteCall(t2,_,as2): scan(t2); if (as2 != null) for (a2 in as2) scan(a2);
        case EField(obj,_): scan(obj);
        case EAccess(obj2,key): scan(obj2); scan(key);
        default:
      }
    }
    scan(body);
    // Filter out vars that already have an explicit [] initializer
    var anyNeeded = false;
    var initList:Array<String> = [];
    for (v in needsInit.keys()) {
      if (!hasInitList.exists(v)) { anyNeeded = true; initList.push(v); }
    }
    if (!anyNeeded) return body;

    // Prepend initializations in a block
    var inits:Array<ElixirAST> = [];
    for (v in initList) inits.push(makeAST(EBinary(Match, makeAST(EVar(v)), makeAST(EList([])))));

    inline function rewriteTailToVar(n:ElixirAST, v:String):ElixirAST {
      return switch (n.def) {
        case EBlock(stmts) if (stmts.length > 0):
          var last = stmts[stmts.length - 1];
          var newLast = switch (last.def) { case EList(_): makeAST(EVar(v)); default: last; };
          var prefix = stmts.copy(); prefix.pop();
          makeASTWithMeta(EBlock(prefix.concat([newLast])), n.metadata, n.pos);
        case EDo(stmts2) if (stmts2.length > 0):
          var last2 = stmts2[stmts2.length - 1];
          var newLast2 = switch (last2.def) { case EList(_): makeAST(EVar(v)); default: last2; };
          var prefix2 = stmts2.copy(); prefix2.pop();
          makeASTWithMeta(EDo(prefix2.concat([newLast2])), n.metadata, n.pos);
        default: n;
      }
    }

    var firstVar:String = null; for (k in initList) { firstVar = k; break; }
    var withInit = switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(inits.concat(stmts)), body.metadata, body.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(inits.concat(stmts2)), body.metadata, body.pos);
      default: makeASTWithMeta(EBlock(inits.concat([body])), body.metadata, body.pos);
    };
    return firstVar != null ? rewriteTailToVar(withInit, firstVar) : withInit;
  }
}

#end
