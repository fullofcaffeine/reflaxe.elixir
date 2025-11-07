package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexNestedSigilFlattenFinalTransforms
 *
 * WHAT
 * - Flattens nested ~H sigils that appear inside ~H content:
 *   `<%= ~H""" ... """ %>` → `...` (inner body only).
 *
 * WHY
 * - Nested ~H inside ~H produces invalid heredoc delimiters and breaks Elixir parsing.
 *   Flattening preserves semantics and matches idiomatic HEEx expectations.
 *
 * HOW
 * - For ESigil("H", content), scan for `<%= ~H"""` … `""" %>` segments and replace with the
 *   inner body between the triple quotes. Conservative, whitespace‑tolerant.
 */
class HeexNestedSigilFlattenFinalTransforms {
  static function flattenNestedHeex(s:String):String {
    if (s == null || s.indexOf("<%=") == -1) return s;
    var out = new StringBuf();
    var i = 0;
    while (i < s.length) {
      var open = s.indexOf("<%=", i);
      if (open == -1) { out.add(s.substr(i)); break; }
      out.add(s.substr(i, open - i));
      var close = s.indexOf("%>", open + 3);
      if (close == -1) { out.add(s.substr(open)); break; }
      var inner = StringTools.trim(s.substr(open + 3, close - (open + 3)));
      if (StringTools.startsWith(inner, "~H\"\"\"")) {
        var start = inner.indexOf("\"\"\"");
        if (start != -1) {
          var bodyStart = start + 3;
          var bodyEnd = inner.indexOf("\"\"\"", bodyStart);
          if (bodyEnd != -1) {
            var body = inner.substr(bodyStart, bodyEnd - bodyStart);
            out.add(body);
            i = close + 2; // continue after %>
            continue;
          }
        }
      }
      out.add(s.substr(open, (close + 2) - open));
      i = close + 2;
    }
    return out.toString();
  }

  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ESigil(type, content, modifiers) if (type == "H"):
          var flattened = flattenNestedHeex(content);
          if (flattened != content) makeASTWithMeta(ESigil(type, flattened, modifiers), n.metadata, n.pos) else n;
        default:
          n;
      }
    });
  }
}

#end

