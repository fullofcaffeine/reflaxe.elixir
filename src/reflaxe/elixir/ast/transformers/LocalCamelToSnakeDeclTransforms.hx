package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalCamelToSnakeDeclTransforms
 *
 * WHAT
 * - Renames local variable declarations from camelCase to snake_case within a
 *   function, and rewrites body references accordingly. Covers EMatch patterns
 *   (PVar) and EBinary(Match, EVar, _).
 *
 * WHY
 * - Haxe code commonly uses camelCase locals (sortBy, updatedTodo, parsedResult).
 *   Elixir idioms and other passes expect snake_case. Normalizing declarations
 *   eliminates undefined references like sortBy when later code refers to sort_by.
 */
class LocalCamelToSnakeDeclTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var rename = collectLocalDeclRenames(body);
          var newBody = applyRenames(body, rename);
          makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
        case EDefp(name, args, guards, body):
          var rename2 = collectLocalDeclRenames(body);
          var newBody2 = applyRenames(body, rename2);
          makeASTWithMeta(EDefp(name, args, guards, newBody2), n.metadata, n.pos);
        default:
          n;
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

  static function collectLocalDeclRenames(body: ElixirAST): Map<String,String> {
    var m = new Map<String,String>();
    function collectPattern(p:EPattern):Void {
      switch (p) {
        case PVar(n):
          var s = toSnake(n);
          if (s != n) m.set(n, s);
        case PTuple(es) | PList(es): for (e in es) collectPattern(e);
        case PCons(h,t): collectPattern(h); collectPattern(t);
        case PMap(kvs): for (kv in kvs) collectPattern(kv.value);
        case PStruct(_,fs): for (f in fs) collectPattern(f.value);
        case PPin(inner): collectPattern(inner);
        default:
      }
    }
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x:ElixirAST) {
      if (x == null || x.def == null) return;
      switch (x.def) {
        case EMatch(p, _): collectPattern(p);
        case EBinary(Match, l, _):
          switch (l.def) { case EVar(n): var s = toSnake(n); if (s != n) m.set(n, s); default: }
        default:
      }
    });
    return m;
  }

  static function applyRenames(body: ElixirAST, renames: Map<String,String>): ElixirAST {
    if (renames == null || !renames.iterator().hasNext()) return body;
    function rwPattern(p:EPattern):EPattern {
      return switch (p) {
        case PVar(n) if (renames.exists(n)): PVar(renames.get(n));
        case PTuple(es): PTuple([for (e in es) rwPattern(e)]);
        case PList(es): PList([for (e in es) rwPattern(e)]);
        case PCons(h,t): PCons(rwPattern(h), rwPattern(t));
        case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: rwPattern(kv.value) } ]);
        case PStruct(m, fs): PStruct(m, [for (f in fs) { key: f.key, value: rwPattern(f.value) } ]);
        case PPin(inner): PPin(rwPattern(inner));
        default: p;
      }
    }
    return ElixirASTTransformer.transformNode(body, function(x:ElixirAST): ElixirAST {
      return switch (x.def) {
        case EMatch(p, rhs): makeASTWithMeta(EMatch(rwPattern(p), x), x.metadata, x.pos);
        case EBinary(Match, l, rhs):
          var nl = switch (l.def) { case EVar(n) if (renames.exists(n)): makeASTWithMeta(EVar(renames.get(n)), l.metadata, l.pos); default: l; };
          makeASTWithMeta(EBinary(Match, nl, rhs), x.metadata, x.pos);
        case EVar(v) if (renames.exists(v)):
          makeASTWithMeta(EVar(renames.get(v)), x.metadata, x.pos);
        default:
          x;
      }
    });
  }
}

#end

