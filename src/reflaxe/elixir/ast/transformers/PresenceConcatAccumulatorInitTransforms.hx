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
    var defined = new Map<String,Bool>();

    // Scan body for concat uses and definitions in a single pass
    function scan(n:ElixirAST):Void {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EBinary(Match, {def: EVar(lhs)}, _): defined.set(lhs, true);
        case EMatch(PVar(lhs2), _): defined.set(lhs2, true);
        case ERemoteCall({def: EVar("Enum")}, fn, args) if (fn == "concat" && args != null && args.length >= 1):
          switch (args[0].def) { case EVar(v): if (!defined.exists(v)) needsInit.set(v, true); default: }
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
    if (needsInit.keys().hasNext() == false) return body;

    // Prepend initializations in a block
    var inits:Array<ElixirAST> = [];
    for (v in needsInit.keys()) inits.push(makeAST(EBinary(Match, makeAST(EVar(v)), makeAST(EList([])))));

    return switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(inits.concat(stmts)), body.metadata, body.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(inits.concat(stmts2)), body.metadata, body.pos);
      default: makeASTWithMeta(EBlock(inits.concat([body])), body.metadata, body.pos);
    }
  }
}

#end

