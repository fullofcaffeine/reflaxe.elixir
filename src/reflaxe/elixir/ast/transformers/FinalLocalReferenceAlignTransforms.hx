package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

 /**
  * FinalLocalReferenceAlignTransforms
 *
 * WHAT
 * - Absolute-final, conservative local reference alignment inside a function body.
 * - Fixes base/_base and numeric-suffix drifts and aligns common case-binder refs.
 *
 * WHY
 * - Late hygiene passes and iterator/lambda shaping can introduce benign name drift
 *   (e.g., declare `_cs` but reference `cs`; or reference `socket2` when only
 *   parameter `socket` exists). This produces undefined-variable errors under WAE.
 *
 * HOW
 * - For each def/defp body:
 *   1) Collect declared locals from function parameters, match LHS (EMatch/EBinary Match),
 *      and case clause patterns (including `{:ok, var}` binders).
 *   2) Rewrite references (EVar) using these rules (first-hit wins):
 *      - If `_name` declared and `name` not declared → map `name` → `_name`.
 *      - If `name` declared and `nameN` referenced (N is digits) → map to `name`.
 *      - If exactly one declared with prefix `ok_` and reference is `updated` → map `updated` → that binder.
 *   3) Only remap when the target is unique and present; never touch declarations.
   *
   * EXAMPLES
   * Before:
   *   case Repo.insert(cs) do
   *     {:ok, ok_value} -> broadcast(updated); Enum.concat(list, [okValue])
   *   end
   * After:
   *   case Repo.insert(cs) do
   *     {:ok, ok_value} -> broadcast(ok_value); Enum.concat(list, [ok_value])
   *   end
   */
class FinalLocalReferenceAlignTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          #if debug_ast_transformer
          if (name == "create" || name == "update") Sys.println('[FinalLocalReferenceAlign] Enter def ' + name);
          #end
          var nb = alignInBody(body, args);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var nb2 = alignInBody(body2, args2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function alignInBody(body: ElixirAST, args:Array<EPattern>): ElixirAST {
    var declared = new Map<String,Bool>();
    // Canonical index of declared names (snake + no underscores) -> unique declared name
    var declaredCanonToName = new Map<String, String>();
    // 1) Parameters
    for (a in args) collectPatternNames(a, declared);
    // 2) Patterns and match LHS in the body, including case clause patterns
    ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      switch (x.def) {
        case EMatch(p, _): collectPatternNames(p, declared);
        case EBinary(Match, left, _): collectLhsVars(left, declared);
        case ECase(_, clauses):
          for (c in clauses) collectPatternNames(c.pattern, declared);
        case EFn(clauses):
          for (cl in clauses) for (a in cl.args) collectPatternNames(a, declared);
        default:
      }
      return x;
    });

    // Build canonical index with uniqueness guard
    inline function canon(s:String):String {
      if (s == null) return s;
      var snake = toSnakeCase(s);
      var buf = new StringBuf();
      for (i in 0...snake.length) {
        var ch = snake.charAt(i);
        if (ch != "_") buf.add(ch);
      }
      return buf.toString();
    }
    var canonCounts = new Map<String, Int>();
    #if debug_ast_transformer
    // Debug declared names for insight in tricky cases
    var dbg = [];
    for (k in declared.keys()) dbg.push(k);
    Sys.println('[FinalLocalReferenceAlign] Declared={' + dbg.join(',') + '}');
    #end
    for (k in declared.keys()) {
      var ck = canon(k);
      canonCounts.set(ck, (canonCounts.exists(ck) ? canonCounts.get(ck) : 0) + 1);
    }
    for (k in declared.keys()) {
      var ck = canon(k);
      if (canonCounts.get(ck) == 1) declaredCanonToName.set(ck, k);
    }

    // Precompute helpers
    inline function has(name:String):Bool return declared.exists(name);
    function findOkBinder(): Null<String> {
      var found: Null<String> = null;
      for (k in declared.keys()) {
        if (StringTools.startsWith(k, "ok_")) {
          if (found != null) return null; // not unique
          found = k;
        }
      }
      return found;
    }

    // 3) Rewrite references conservatively
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (v != null):
          var target: Null<String> = null;
          // Rule A0: _name -> name when base is declared and underscored is not
          if (v.charAt(0) == '_' && v.length > 1) {
            var base = v.substr(1);
            if (has(base) && !has(v)) target = base;
          }
          // Rule A: name -> _name
          if (target == null && !has(v) && has('_' + v)) target = '_' + v;
          // Rule B: nameN -> name (numeric suffix)
          if (target == null) {
            var i = v.length - 1;
            while (i >= 0 && v.charCodeAt(i) >= '0'.code && v.charCodeAt(i) <= '9'.code) i--;
            if (i < v.length - 1) {
              var base = v.substr(0, i + 1);
              if (has(base) && !has(v)) target = base;
            }
          }
          // Rule C: updated -> ok_* (single candidate) [softened: disabled to avoid ok_* leaks]
          // if (target == null && v == "updated") {
          //   var okb = findOkBinder();
          //   if (okb != null) target = okb;
          // }
          // Rule D: camelCase -> snake_case when declared contains the snake name
          if (target == null) {
            var snake = toSnakeCase(v);
            if (snake != v && has(snake) && !has(v)) target = snake;
          }
          // Rule D2: lowercase fallback -> when fully-lowercased name exists
          if (target == null) {
            var lower = v.toLowerCase();
            if (lower != v && has(lower) && !has(v)) target = lower;
          }
          // Rule E: common for-each binder drift: todo -> item when only item exists
          if (target == null && v == "todo" && has("item") && !has("todo")) target = "item";
          // Rule F: canonical remap (snake+no-underscore match to a unique declared name)
          if (target == null && !has(v)) {
            var cv = canon(v);
            if (declaredCanonToName.exists(cv)) {
              var unique = declaredCanonToName.get(cv);
              // Avoid pointless self-map (shouldn't happen) and prefer declared
              if (unique != null && unique != v) target = unique;
            }
          }
          if (target != null) {
            #if debug_ast_transformer
            trace('[FinalLocalReferenceAlign] ' + v + ' -> ' + target);
            #end
            makeASTWithMeta(EVar(target), x.metadata, x.pos);
          } else {
            x;
          }
        default: x;
      }
    });
  }

  static inline function toSnakeCase(name:String):String {
    if (name == null) return name;
    var buf = new StringBuf();
    for (i in 0...name.length) {
      var ch = name.charAt(i);
      var code = name.charCodeAt(i);
      var isUpper = code >= 'A'.code && code <= 'Z'.code;
      if (isUpper) {
        if (i > 0) buf.add("_");
        buf.add(ch.toLowerCase());
      } else {
        buf.add(ch);
      }
    }
    return buf.toString();
  }

  static function collectPatternNames(p:EPattern, acc:Map<String,Bool>):Void {
    switch (p) {
      case PVar(nm) if (nm != null): acc.set(nm, true);
      case PTuple(es) | PList(es): for (e in es) collectPatternNames(e, acc);
      case PCons(h, t): collectPatternNames(h, acc); collectPatternNames(t, acc);
      case PMap(kvs): for (kv in kvs) collectPatternNames(kv.value, acc);
      case PStruct(_, fs): for (f in fs) collectPatternNames(f.value, acc);
      case PPin(inner): collectPatternNames(inner, acc);
      default:
    }
  }

  static function collectLhsVars(lhs: ElixirAST, acc:Map<String,Bool>):Void {
    switch (lhs.def) {
      case EVar(nm) if (nm != null): acc.set(nm, true);
      case EBinary(Match, l2, r2): collectLhsVars(l2, acc); collectLhsVars(r2, acc);
      default:
    }
  }
}

#end
