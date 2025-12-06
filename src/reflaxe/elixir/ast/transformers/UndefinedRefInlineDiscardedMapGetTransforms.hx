package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * UndefinedRefInlineDiscardedMapGetTransforms
 *
 * WHAT
 * - When a clause/body contains a discarded assignment `_ = Map.get(obj, "some_key")`,
 *   and later references a single undefined camelCase variable whose snake_case equals
 *   `some_key`, inline the `Map.get(...)` expression at the reference site.
 *
 * WHY
 * - Some generated event handlers fetch params with Map.get into `_` for side-effects,
 *   but later use the camelCase variable. This pass ties the usage back to the fetched
 *   value without app-specific heuristics (shape- and key-based only).
 *
 * HOW
 * - For each function body, walk blocks (`EBlock`/`EDo`) in order. Maintain a windowed
 *   map `snakeKey -> Map.get(expr)` for discarded Map.get assignments encountered so far.
 *   When an undefined `EVar(camelName)` appears and `toSnake(camelName)` exists in the
 *   map, replace it with the stored `Map.get` AST.
 */
class UndefinedRefInlineDiscardedMapGetTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var nb = processBody(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name, args, guards, body):
          var nb2 = processBody(body);
          makeASTWithMeta(EDefp(name, args, guards, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function processBody(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(stmts):
          var out:Array<ElixirAST> = [];
          var i = 0;
          var discarded:Map<String,ElixirAST> = new Map();
          var declared:Map<String,Bool> = new Map();
          while (i < stmts.length) {
            var s = stmts[i];
            switch (s.def) {
              case EBinary(Match, {def: EVar("_")}, rhs):
                var key = extractMapGetKey(rhs);
                if (key != null) discarded.set(key, rhs);
                out.push(s);
                i++;
              case EMatch(PVar("_"), rhs2):
                var key2 = extractMapGetKey(rhs2);
                if (key2 != null) discarded.set(key2, rhs2);
                out.push(s);
                i++;
              default:
                // Rewrite undefined camel refs in statement using known discarded Map.get
                var rewritten = inlineUndefinedCamelRefs(s, discarded, declared);
                // Update declared set after emitting statement (captures new LHS vars)
                collectLhsDecls(rewritten, declared);
                out.push(rewritten);
                i++;
            }
          }
          makeASTWithMeta(EBlock(out), x.metadata, x.pos);
        case EDo(stmts2):
          var out2:Array<ElixirAST> = [];
          var j = 0;
          var discarded2:Map<String,ElixirAST> = new Map();
          var declared2:Map<String,Bool> = new Map();
          while (j < stmts2.length) {
            var s2 = stmts2[j];
            switch (s2.def) {
              case EBinary(Match, {def: EVar("_")}, rhsD):
                var keyD = extractMapGetKey(rhsD);
                if (keyD != null) discarded2.set(keyD, rhsD);
                out2.push(s2);
                j++;
              case EMatch(PVar("_"), rhsD2):
                var keyD2 = extractMapGetKey(rhsD2);
                if (keyD2 != null) discarded2.set(keyD2, rhsD2);
                out2.push(s2);
                j++;
              default:
                var rewritten2 = inlineUndefinedCamelRefs(s2, discarded2, declared2);
                collectLhsDecls(rewritten2, declared2);
                out2.push(rewritten2);
                j++;
            }
          }
          makeASTWithMeta(EDo(out2), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function inlineUndefinedCamelRefs(stmt: ElixirAST, discarded: Map<String,ElixirAST>, declared: Map<String,Bool>): ElixirAST {
    return ElixirASTTransformer.transformNode(stmt, function(e: ElixirAST): ElixirAST {
      switch (e.def) {
        case EVar(name):
          if (!declared.exists(name)) {
            var snake = reflaxe.elixir.ast.NameUtils.toSnakeCase(name);
            if (discarded.exists(snake)) {
              return makeASTWithMeta(EParen(discarded.get(snake)), e.metadata, e.pos);
            }
          }
          return e;
        default:
          return e;
      }
    });
  }

  static function extractMapGetKey(expr: ElixirAST): Null<String> {
    // Match both ERemoteCall(Map, "get", [...]) and ECall(ESelect(EVar("Map"), "get"), [...])
    return switch (expr.def) {
      case ERemoteCall(mod, name, args):
        var isMap = switch (mod.def) { case EVar(m): m == "Map"; default: false; };
        if (isMap && name == "get" && args != null && args.length >= 2)
          switch (args[1].def) { case EString(s): s; default: null; } else null;
      case ECall(target, funcName, args2):
        var isMapGet = (funcName == "get") && (target != null) && switch (target.def) { case EVar(m2): m2 == "Map"; default: false; };
        if (isMapGet && args2 != null && args2.length >= 2)
          switch (args2[1].def) { case EString(s2): s2; default: null; } else null;
      default: null;
    }
  }

  static function collectLhsDecls(stmt: ElixirAST, vars: Map<String,Bool>): Void {
    ASTUtils.walk(stmt, function(x: ElixirAST) {
      if (x == null || x.def == null) return;
      switch (x.def) {
        case EMatch(p, _): collectPatternDecls(p, vars);
        case EBinary(Match, l, _): collectLhs(l, vars);
        default:
      }
    });
  }
  static function collectPatternDecls(p: EPattern, vars: Map<String,Bool>): Void {
    switch (p) {
      case PVar(n): if (n != null && n.length > 0) vars.set(n, true);
      case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, vars);
      case PCons(h, t): collectPatternDecls(h, vars); collectPatternDecls(t, vars);
      case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, vars);
      case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, vars);
      case PPin(inner): collectPatternDecls(inner, vars);
      default:
    }
  }
  static function collectLhs(lhs: ElixirAST, vars: Map<String,Bool>): Void {
    switch (lhs.def) { case EVar(n): vars.set(n, true); case EBinary(Match, l2, _): collectLhs(l2, vars); default: }
  }
}

#end
