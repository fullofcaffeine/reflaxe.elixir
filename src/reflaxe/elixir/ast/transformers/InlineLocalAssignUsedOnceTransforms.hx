package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * InlineLocalAssignUsedOnceTransforms
 *
 * WHAT
 * - Inlines simple local assignments `name = expr` when `name` is referenced
 *   exactly once later in the same body and never re-assigned before that use.
 *   Drops the assignment and replaces the sole use with `expr`.
 *
 * WHY
 * - Eliminates one-off temporaries (e.g., `data`, `json`) that trigger warnings
 *   while keeping semantics intact.
 */
class InlineLocalAssignUsedOnceTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isController(name)):
          var nb = [for (b in body) applyToDefs(b)];
          makeASTWithMeta(EModule(name, attrs, nb), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (isController(name2)):
          makeASTWithMeta(EDefmodule(name2, applyToDefs(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isController(name:String):Bool {
    return name != null && name.indexOf("Web.") > 0 && StringTools.endsWith(name, "Controller");
  }

  static function applyToDefs(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EDef(fn, args, guards, body):
          makeASTWithMeta(EDef(fn, args, guards, transformBody(body)), n.metadata, n.pos);
        case EDefp(fn2, args2, guards2, body2):
          makeASTWithMeta(EDefp(fn2, args2, guards2, transformBody(body2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function transformBody(n: ElixirAST): ElixirAST {
    return switch (n.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
      default: n;
    }
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    var i = 0;
    while (i < stmts.length) {
      var s = stmts[i];
      switch (s.def) {
        case EMatch(PVar(b), rhs):
          var res = tryInline(stmts, i, b, rhs, s.metadata, s.pos);
          if (res.inlined) { out.push(res.nextStmt); i += 2; continue; } else { out.push(s); i++; continue; }
        case EBinary(Match, {def: EVar(b2)}, rhs2):
          var res2 = tryInline(stmts, i, b2, rhs2, s.metadata, s.pos);
          if (res2.inlined) { out.push(res2.nextStmt); i += 2; continue; } else { out.push(s); i++; continue; }
        default:
          out.push(s); i++;
      }
    }
    return out;
  }

  static function tryInline(stmts:Array<ElixirAST>, idx:Int, name:String, rhs:ElixirAST, md:Dynamic, pos:haxe.macro.Expr.Position):{inlined:Bool, nextStmt:ElixirAST} {
    if (name == null || name.length == 0) return {inlined:false, nextStmt:null};
    if (name.charAt(0) == '_') return {inlined:false, nextStmt:null};
    if (idx + 1 >= stmts.length) return {inlined:false, nextStmt:null};

    // Count references to `name` and ensure no re-assignment before first use
    var useCount = 0;
    var firstUseStmt:Int = -1;
    var reassigned = false;
    for (j in idx+1...stmts.length) {
      // detect reassignment on LHS
      switch (stmts[j].def) {
        case EMatch(PVar(n), _) if (n == name): reassigned = true;
        case EBinary(Match, {def: EVar(n2)}, _) if (n2 == name): reassigned = true;
        default:
      }
      if (reassigned) break;
      var found = false;
      reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(x:ElixirAST){
        switch (x.def) { case EVar(v) if (v == name): found = true; default: }
      });
      if (found) { useCount++; if (firstUseStmt == -1) firstUseStmt = j; if (useCount > 1) break; }
    }
    if (reassigned || useCount != 1 || firstUseStmt == -1) return {inlined:false, nextStmt:null};

    // Substitute in firstUseStmt
    var target = stmts[firstUseStmt];
    var replaced = ElixirASTTransformer.transformNode(target, function(n:ElixirAST):ElixirAST {
      return switch (n.def) { case EVar(v) if (v == name): rhs; default: n; }
    });
    return {inlined:true, nextStmt:replaced};
  }
}

#end
