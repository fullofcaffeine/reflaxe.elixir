package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalAssignUnusedUnderscoreScopedTransforms
 *
 * WHAT
 * - Underscore assignment binders that are not referenced later in the same
 *   block, but only within safe scopes: any def/defp except `mount`.
 *
 * WHY
 * - Silences unused local warnings in controllers, LiveView handle_event
 *   bodies, and render helpers without touching mount/3 where rebinding
 *   `socket` may be intentionally propagated.
 *
 * HOW
 * - For each EDef/EDefp whose name != "mount", rewrite EBlock/EDo children so
 *   that `name = expr` becomes `_name = expr` when `name` is not referenced in
 *   any subsequent statement within the same block.
 */
  class LocalAssignUnusedUnderscoreScopedTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      // Gate (relaxed for WAE): when inside LiveView modules, only allow on
      // render_* helpers and handle_event/3 to avoid false positives.
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name != "mount"):
          if (n.metadata != null && (Reflect.field(n.metadata, "isLiveView") == true)) {
            if (!StringTools.startsWith(name, "render_") && !(name == "handle_event" && args != null && args.length == 3)) return n;
          }
          var usedInFn = collectUsedVars(body);
          var newBody = rewriteBlocks(body, usedInFn);
          makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (name2 != "mount"):
          if (n.metadata != null && (Reflect.field(n.metadata, "isLiveView") == true)) {
            if (!StringTools.startsWith(name2, "render_") && !(name2 == "handle_event" && args2 != null && args2.length == 3)) return n;
          }
          var usedInFn2 = collectUsedVars(body2);
          var newBody2 = rewriteBlocks(body2, usedInFn2);
          makeASTWithMeta(EDefp(name2, args2, guards2, newBody2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteBlocks(node: ElixirAST, used:Map<String,Bool>): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(stmts):
          makeASTWithMeta(EBlock(rewrite(stmts, used)), x.metadata, x.pos);
        case EDo(stmts2):
          makeASTWithMeta(EDo(rewrite(stmts2, used)), x.metadata, x.pos);
        case EFn(clauses):
          var newClauses = [];
          for (c in clauses) {
            var nb = rewriteBlocks(c.body, used);
            newClauses.push({args: c.args, guard: c.guard, body: nb});
          }
          makeASTWithMeta(EFn(newClauses), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>, used:Map<String,Bool>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var s1 = switch (s.def) {
        case EMatch(PVar(b), rhs) if (b != "children" && !usedLater(stmts, i+1, b) && !used.exists(b) && (isEphemeralRhs(rhs) || (b == "g" && isCase(rhs)))):
          makeASTWithMeta(EMatch(PVar('_' + b), rhs), s.metadata, s.pos);
        case EBinary(Match, {def: EVar(b2)}, rhs2) if (b2 != "children" && !usedLater(stmts, i+1, b2) && !used.exists(b2) && (isEphemeralRhs(rhs2) || (b2 == "g" && isCase(rhs2)))):
          makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b2)), rhs2), s.metadata, s.pos);
        // Align binder to Map.get(params, "key") base name when that base is used later
        case EBinary(Match, {def: EVar(b3)}, rhs3):
          switch (rhs3.def) {
            case ERemoteCall({def: EVar("Map")}, "get", ra) if (ra != null && ra.length == 2):
              switch (ra[1].def) {
                case EString(key) if (usedLater(stmts, i+1, key) && !used.exists(key)):
                  makeASTWithMeta(EBinary(Match, makeAST(EVar(key)), rhs3), s.metadata, s.pos);
                default: s;
              }
            default: s;
          }
        default:
          s;
      }
      out.push(s1);
    }
    return out;
  }

  static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
    var found = false;
    for (j in start...stmts.length) if (!found) {
      reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(x:ElixirAST){
        switch (x.def) { case EVar(v) if (v == name): found = true; default: }
      });
    }
    return found;
  }

  static function isCase(rhs: ElixirAST): Bool {
    return switch (rhs.def) {
      case ECase(_, _): true;
      default: false;
    }
  }

  static function collectUsedVars(node: ElixirAST): Map<String,Bool> {
    var used:Map<String,Bool> = new Map();
    reflaxe.elixir.ast.ASTUtils.walk(node, function(x:ElixirAST){
      switch (x.def) { case EVar(v): used.set(v, true); default: }
    });
    return used;
  }

  static function isEphemeralRhs(rhs: ElixirAST): Bool {
    return switch (rhs.def) {
      case ERemoteCall({def: EVar("Map")}, fnName, args) if (fnName == "get" && args != null && args.length == 2):
        // Ephemeral when key is a string and not a structural extraction
        switch (args[1].def) {
          case EString(_): true;
          default: isNuisanceKey(args[1]);
        }
      // Do not treat list/map literals as ephemeral; they may be used later (e.g., permitted fields)
      default: false;
    }
  }

  static function isNuisanceKey(arg: ElixirAST): Bool {
    return switch (arg.def) {
      case EString(s) if (s == "to_string" || s == "fn" || s == "end" || s == "sort_by"): true;
      default: false;
    }
  }
}

#end
