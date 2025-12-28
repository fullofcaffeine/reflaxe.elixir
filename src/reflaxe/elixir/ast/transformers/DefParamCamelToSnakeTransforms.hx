package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DefParamCamelToSnakeTransforms
 *
 * WHAT
 * - Renames camelCase function parameters to snake_case and rewrites body
 *   references accordingly. Applies to both def/defp.
 *
 * WHY
 * - Haxe inputs often use camelCase parameters (e.g., elseFn). Elixir
 *   idiomatically uses snake_case (else_fn). Normalizing parameters avoids
 *   reference/decl mismatches and aligns with idioms and snapshots.
 *
 * HOW
 * - For each EDef/EDefp:
 *   1) For each param pattern PVar(name), compute snake_case.
 *   2) When snake != name, rename the pattern to snake.
 *   3) In the function body, replace EVar(name) → EVar(snake).

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class DefParamCamelToSnakeTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var renames = computeParamRenames(args);
          var newArgs = renameParams(args, renames);
          var newBody = applyRenamesToBody(body, renames);
          makeASTWithMeta(EDef(name, newArgs, guards, newBody), n.metadata, n.pos);
        case EDefp(name, args, guards, body):
          var renames2 = computeParamRenames(args);
          var newArgs2 = renameParams(args, renames2);
          var newBody2 = applyRenamesToBody(body, renames2);
          makeASTWithMeta(EDefp(name, newArgs2, guards, newBody2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function computeParamRenames(args: Array<EPattern>): Map<String,String> {
    var m = new Map<String,String>();
    if (args == null) return m;
    for (a in args) collectRenames(a, m);
    return m;
  }

  static function collectRenames(p: EPattern, m: Map<String,String>): Void {
    switch (p) {
      case PVar(n):
        var s = toSnake(n);
        if (s != n) m.set(n, s);
      case PTuple(es) | PList(es): for (e in es) collectRenames(e, m);
      case PCons(h, t): collectRenames(h, m); collectRenames(t, m);
      case PMap(kvs): for (kv in kvs) collectRenames(kv.value, m);
      case PStruct(_, fs): for (f in fs) collectRenames(f.value, m);
      case PPin(inner): collectRenames(inner, m);
      default:
    }
  }

  static function renameParams(args: Array<EPattern>, renames: Map<String,String>): Array<EPattern> {
    if (args == null || renames == null || renames.keys() == null) return args;
    function rw(p:EPattern):EPattern {
      return switch (p) {
        case PVar(n) if (renames.exists(n)):
          PVar(renames.get(n));
        case PTuple(es): PTuple([for (e in es) rw(e)]);
        case PList(es): PList([for (e in es) rw(e)]);
        case PCons(h,t): PCons(rw(h), rw(t));
        case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: rw(kv.value) } ]);
        case PStruct(mod, fs): PStruct(mod, [for (f in fs) { key: f.key, value: rw(f.value) } ]);
        case PPin(inner): PPin(rw(inner));
        default: p;
      }
    }
    return [for (a in args) rw(a)];
  }

  static function applyRenamesToBody(body: ElixirAST, renames: Map<String,String>): ElixirAST {
    if (renames == null || !renames.iterator().hasNext()) return body;
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (renames.exists(v)):
          makeASTWithMeta(EVar(renames.get(v)), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function toSnake(s: String): String {
    if (s == null || s.length == 0) return s;
    var buf = new StringBuf();
    for (i in 0...s.length) {
      var c = s.substr(i, 1);
      var lower = c.toLowerCase();
      var upper = c.toUpperCase();
      if (c == upper && c != lower) {
        if (i != 0) buf.add("_");
        buf.add(lower);
      } else {
        buf.add(c);
      }
    }
    return buf.toString();
  }
}

#end

