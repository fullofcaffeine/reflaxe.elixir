package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * MountDropHeadIdentityReassignTransforms
 *
 * WHAT
 * - In Phoenix LiveView `mount/3`, drop top-level statements that reassign any
 *   of the head binders (`params`, `session`, `socket`) to trivial identities:
 *   - `session = Map.get(params|_params, "session")`
 *   - `socket = params|_params` (or any binder directly assigned from another)
 *   - `params = params`/`_params = params` etc.
 *
 * WHY
 * - Some earlier generic passes can introduce redundant reassignments that cause
 *   unused/undefined warnings (e.g., referencing `_params` when the head uses
 *   `params`). Dropping these no-op rebinds preserves semantics and removes noise.
 */
class MountDropHeadIdentityReassignTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "mount" && args != null && args.length == 3):
          var p = switch (args[0]) { case PVar(v): v; default: null; };
          var s = switch (args[1]) { case PVar(v2): v2; default: null; };
          var sk = switch (args[2]) { case PVar(v3): v3; default: null; };
          var nb = drop(body, p, s, sk);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function sameOrUnderscore(a:Null<String>, b:Null<String>):Bool {
    if (a == null || b == null) return false;
    if (a == b) return true;
    if (a.length > 1 && a.charAt(0) == '_' && a.substr(1) == b) return true;
    if (b.length > 1 && b.charAt(0) == '_' && b.substr(1) == a) return true;
    return false;
  }

  static function drop(body: ElixirAST, paramsName:Null<String>, sessionName:Null<String>, socketName:Null<String>): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts):
        makeASTWithMeta(EBlock(filter(stmts, paramsName, sessionName, socketName)), body.metadata, body.pos);
      case EDo(stmts2):
        makeASTWithMeta(EDo(filter(stmts2, paramsName, sessionName, socketName)), body.metadata, body.pos);
      default:
        body;
    }
  }

  static function filter(stmts:Array<ElixirAST>, paramsName:Null<String>, sessionName:Null<String>, socketName:Null<String>):Array<ElixirAST> {
    var out:Array<ElixirAST> = [];
    for (st in stmts) {
      var drop = false;
      switch (st.def) {
        case EMatch(PVar(lhs), rhs):
          if (lhs == sessionName && isMapGetSession(rhs, paramsName)) drop = true;
          else if ((lhs == socketName || lhs == paramsName || (paramsName != null && lhs == '_' + paramsName)) && isTrivialVar(rhs, [paramsName, '_' + paramsName, socketName, sessionName])) drop = true;
        case EBinary(Match, left, right):
          switch (left.def) {
            case EVar(lhs2):
              if (lhs2 == sessionName && isMapGetSession(right, paramsName)) drop = true;
              else if ((lhs2 == socketName || lhs2 == paramsName || (paramsName != null && lhs2 == '_' + paramsName)) && isTrivialVar(right, [paramsName, '_' + paramsName, socketName, sessionName])) drop = true;
            default:
          }
        default:
      }
      if (!drop) out.push(st);
    }
    return out;
  }

  static inline function isTrivialVar(expr:ElixirAST, allowed:Array<Null<String>>):Bool {
    return switch (expr.def) {
      case EVar(v): allowed.indexOf(v) != -1;
      default: false;
    }
  }

  static inline function isMapGetSession(expr:ElixirAST, paramsName:Null<String>):Bool {
    if (paramsName == null) return false;
    return switch (expr.def) {
      case ERemoteCall({def: EVar(mod)}, fn, [arg0, {def: EString(key)}]) if (mod == "Map" && fn == "get" && key == "session"):
        switch (arg0.def) {
          case EVar(v): sameOrUnderscore(v, paramsName);
          default: false;
        }
      default: false;
    }
  }
}

#end

