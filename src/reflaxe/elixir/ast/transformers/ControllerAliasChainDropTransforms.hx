package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ControllerAliasChainDropTransforms
 *
 * WHAT
 * - In controller modules, remove contiguous alias-chains like:
 *     json = v; data = v; conn = v
 *   that immediately precede or follow a Phoenix.Controller.json/2 call.
 *
 * WHY
 * - These alias-chains are artifacts and trigger WAE warnings (underscored var used).
 *   They obscure intent without changing semantics.
 *
 * HOW
 * - Scan EBlock/EDo sequences and drop runs of assignments to json/data/conn
 *   where RHS is the same simple variable name.
 */
class ControllerAliasChainDropTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isController(name)):
          var out = [for (b in body) cleanse(b)];
          makeASTWithMeta(EModule(name, attrs, out), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (isController(name2)):
          makeASTWithMeta(EDefmodule(name2, cleanse(doBlock)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isController(name:String):Bool {
    return name != null && name.indexOf("Web.") > 0 && StringTools.endsWith(name, "Controller");
  }

  static function cleanse(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case EDef(fn, args, g, body): makeASTWithMeta(EDef(fn, args, g, cleanBody(body)), n.metadata, n.pos);
        case EDefp(fn2, args2, g2, body2): makeASTWithMeta(EDefp(fn2, args2, g2, cleanBody(body2)), n.metadata, n.pos);
        case ECase(expr, clauses):
          var newClauses = [];
          for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: cleanBody(cl.body) });
          makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function cleanBody(b: ElixirAST): ElixirAST {
    return switch (b.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(dropChains(stmts)), b.metadata, b.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(dropChains(stmts2)), b.metadata, b.pos);
      default: b;
    }
  }

  static inline function isAliasName(n:String):Bool {
    return n == "json" || n == "data" || n == "conn";
  }

  static function isAssignAlias(stmt: ElixirAST): { ok:Bool, name:String, rhs:Null<String> } {
    return switch (stmt.def) {
      case EBinary(Match, {def:EVar(nm)}, {def:EVar(rv)}): { ok: isAliasName(nm), name: nm, rhs: rv };
      case EMatch(PVar(nm2), {def:EVar(rv2)}): { ok: isAliasName(nm2), name: nm2, rhs: rv2 };
      default: { ok:false, name:null, rhs:null };
    }
  }

  static function dropChains(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    var i = 0;
    while (i < stmts.length) {
      var info = isAssignAlias(stmts[i]);
      if (info.ok) {
        // collect run
        var rhs = info.rhs;
        var k = i + 1;
        var names = new Map<String,Bool>();
        names.set(info.name, true);
        while (k < stmts.length) {
          var nxt = isAssignAlias(stmts[k]);
          if (!nxt.ok || nxt.rhs != rhs) break;
          names.set(nxt.name, true);
          k++;
        }
        // If we saw at least two distinct alias names pointing to same rhs, drop the run
        var distinct = 0; for (n in names.keys()) distinct++;
        if (distinct >= 2) { i = k; continue; }
      }
      out.push(stmts[i]); i++;
    }
    return out;
  }
}

#end
