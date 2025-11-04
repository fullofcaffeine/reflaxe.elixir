package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SearchFieldQueryBinderSynthesisTransforms
 *
 * WHAT
 * - Synthesizes a local `query` binder from a discovered `<something>.search_query`
 *   field when a function body references `query` but has no prior local `query`
 *   binding.
 *
 * WHY
 * - Some pipelines operate with a structured assigns/state record that exposes
 *   a `search_query` field (e.g., assigns.search_query). Other consolidation passes
 *   may later reference `query` in predicates. When no `*_query` parameter exists and
 *   no local binder is present, we derive the binder from the discovered field to
 *   maintain hygiene and avoid undefined variable errors, without tying to app module
 *   names or specific variable identifiers.
 *
 * HOW
 * - For each def/defp body:
 *   - Detect any use of the identifier `query` (EVar("query")).
 *   - Detect absence of a prior local binding to `query` (assignment/pattern).
 *   - Discover the first occurrence of a field access ending with `.search_query`.
 *   - If all conditions hold, prepend `query = String.downcase(<that_field>)` to
 *     the function body (Block/Do or wrap single expression in a Block).
 *
 * NOTES
 * - This pass is shape-based (identifier + field name) and avoids app coupling.
 * - Runs late in the pipeline to act as a hygiene repair only when needed.
 */
class SearchFieldQueryBinderSynthesisTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          makeASTWithMeta(EDef(name, args, guards, synthesize(body)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          makeASTWithMeta(EDefp(name2, args2, guards2, synthesize(body2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function synthesize(body: ElixirAST): ElixirAST {
    if (body == null) return body;
    var usesQuery = false;
    var hasLocalBinder = false;
    var searchField: Null<ElixirAST> = null;

    // Scan body once to collect usage/binders and discover <_>.search_query
    ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      switch (x.def) {
        case EVar(nm) if (nm == 'query'):
          usesQuery = true;
        case EMatch(p,_):
          if (patternDefinesQuery(p)) hasLocalBinder = true;
        case EBinary(Match, l,_):
          if (lhsDefinesQuery(l)) hasLocalBinder = true;
        case EField(_, field) if (field == 'search_query'):
          if (searchField == null) searchField = x; // capture first occurrence
        default:
      }
      return x;
    });

    if (!usesQuery || hasLocalBinder || searchField == null) return body;

    // Prepend: query = String.downcase(<search_field>)
    var rhs = makeAST(ERemoteCall(makeAST(EVar('String')), 'downcase', [searchField]));
    var binder = makeAST(EBinary(Match, makeAST(EVar('query')), rhs));

    return switch (body.def) {
      case EBlock(sts): makeASTWithMeta(EBlock([binder].concat(sts)), body.metadata, body.pos);
      case EDo(sts2): makeASTWithMeta(EDo([binder].concat(sts2)), body.metadata, body.pos);
      default: makeASTWithMeta(EBlock([binder, body]), body.metadata, body.pos);
    }
  }

  static inline function patternDefinesQuery(p:EPattern):Bool {
    return switch (p) {
      case PVar(n) if (n == 'query'): true;
      case PTuple(es) | PList(es):
        var found = false; for (e in es) if (patternDefinesQuery(e)) { found = true; break; } found;
      case PCons(h,t): patternDefinesQuery(h) || patternDefinesQuery(t);
      case PMap(kvs):
        var f = false; for (kv in kvs) if (patternDefinesQuery(kv.value)) { f = true; break; } f;
      case PStruct(_, fs):
        var f2 = false; for (f in fs) if (patternDefinesQuery(f.value)) { f2 = true; break; } f2;
      case PPin(inner): patternDefinesQuery(inner);
      default: false;
    }
  }

  static inline function lhsDefinesQuery(l: ElixirAST):Bool {
    return switch (l.def) {
      case EVar(n) if (n == 'query'): true;
      case EBinary(Match, l2,_): lhsDefinesQuery(l2);
      default: false;
    }
  }
}

#end

