package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.NameUtils;

using StringTools;

/**
 * HeexEventNameNormalizationTransforms
 *
 * WHAT
 * - Normalizes Phoenix LiveView event attribute values (phx-*) to lowercase snake_case
 *   strings and validates that they contain only lowercase letters, digits, and underscores.
 * - Works for both structured template fragments (EFragment) and ~H sigil content (ESigil("H", ...)).
 *
 * WHY
 * - Event attribute values such as phx-click="FilterTodos" do not match LiveView
 *   handler names (handle_event("filter_todos", ...)). This prevents events from
 *   reaching the handler. Normalizing to snake_case ensures idiomatic, working code.
 *
 * HOW
 * - For EFragment: iterate attributes and, when the attribute name is a LiveView event
 *   (phx-click/change/submit/focus/blur/keydown/keyup/window-keydown/window-keyup/click-away),
 *   convert EString/EAtom values to EString snake_case. Validate post-normalization.
 * - For ESigil("H", content): conservatively parse the HEEx string and rewrite event
 *   attribute values that are simple quoted strings. Avoid modifying expressions.
 * - A contextual variant is provided to emit compile-time warnings/errors via CompilationContext.
 *
 * EXAMPLES
 * Haxe (HXX):
 *   HXX.hxx('<button phx-click="FilterTodos">Filter</button>')
 * Elixir (before):
 *   ~H"""
 *   <button phx-click="FilterTodos">Filter</button>
 *   """
 * Elixir (after):
 *   ~H"""
 *   <button phx-click="filter_todos">Filter</button>
 *   """
 */
class HeexEventNameNormalizationTransforms {
    // Public entry (stateless)
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return normalize(ast, null);
    }

    // Public entry (contextual)
    public static function contextualPass(ast: ElixirAST, context: reflaxe.elixir.CompilationContext): ElixirAST {
        return normalize(ast, context);
    }

    static var EVENT_ATTRS: Array<String> = [
        "phx-click",
        "phx-change",
        "phx-submit",
        "phx-focus",
        "phx-blur",
        "phx-keydown",
        "phx-keyup",
        "phx-window-keydown",
        "phx-window-keyup",
        "phx-click-away"
    ];

    static var NON_EVENT_PREFIXES: Array<String> = [
        "phx-value-",
        "phx-update",
        "phx-hook",
        "phx-target",
        "phx-debounce",
        "phx-throttle",
        "phx-page-loading",
        "phx-viewport",
        // Phoenix static asset tracking (not an event)
        "phx-track-static"
    ];

    static function isEventAttr(name: String): Bool {
        if (!name.startsWith("phx-")) return false;
        for (pfx in NON_EVENT_PREFIXES) if (name.startsWith(pfx)) return false;
        for (ev in EVENT_ATTRS) if (name == ev) return true;
        // Unknown phx-* attribute that is not explicitly an event: do not treat as event.
        return false;
    }

    static function toEventSnakeCase(s: String): String {
        if (s == null) return s;
        var normalized = s.trim();
        // replace spaces and hyphens with underscores first
        normalized = normalized.split("-").join("_");
        normalized = ~/\s+/g.replace(normalized, "_");
        // then apply CamelCase -> snake_case
        normalized = NameUtils.toSnakeCase(normalized);
        // collapse multiple underscores
        normalized = ~/__+/g.replace(normalized, "_");
        // lower-case (toSnakeCase already lowercases but keep idempotency)
        normalized = normalized.toLowerCase();
        return normalized;
    }

    static function isValidEventName(s: String): Bool {
        // only lowercase letters, digits, underscore
        return ~/^[a-z0-9_]+$/.match(s);
    }

    static function warn(ctx: Null<reflaxe.elixir.CompilationContext>, msg: String, pos: haxe.macro.Expr.Position): Void {
        if (ctx != null) ctx.warning(msg, pos);
    }

    static function error(ctx: Null<reflaxe.elixir.CompilationContext>, msg: String, pos: haxe.macro.Expr.Position): Void {
        if (ctx != null) ctx.error(msg, pos); else throw msg;
    }

    static function normalize(ast: ElixirAST, ctx: Null<reflaxe.elixir.CompilationContext>): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                // Structured fragment path
                case EFragment(tag, attributes, children):
                    var changed = false;
                    var newAttrs: Array<EAttribute> = [];
                    for (attr in attributes) {
                        if (isEventAttr(attr.name)) {
                            switch (attr.value.def) {
                                case EString(v):
                                    var snake = toEventSnakeCase(v);
                                    if (snake != v) changed = true;
                                    if (!isValidEventName(snake)) {
                                        warn(ctx, 'Invalid LiveView event name "${v}" → "${snake}"; expected lowercase snake_case', n.pos);
                                    }
                                    newAttrs.push({ name: attr.name, value: makeAST(EString(snake)) });
                                case EAtom(a):
                                    var raw: String = (cast a : String);
                                    var snake2 = toEventSnakeCase(raw);
                                    changed = true;
                                    if (!isValidEventName(snake2)) {
                                        warn(ctx, 'Invalid LiveView event atom :${raw} → "${snake2}"; expected lowercase snake_case string', n.pos);
                                    }
                                    newAttrs.push({ name: attr.name, value: makeAST(EString(snake2)) });
                                default:
                                    // Non-literal expression; validate if we can statically detect upper-case via metadata (skip for now)
                                    newAttrs.push(attr);
                            }
                        } else {
                            newAttrs.push(attr);
                        }
                    }
                    if (changed) makeASTWithMeta(EFragment(tag, newAttrs, children), n.metadata, n.pos) else n;

                // ~H sigil path – conservative rewrite for quoted string values only
                case ESigil(type, content, modifiers) if (type == "H"):
                    var updated = rewriteHeexString(content, ctx, n.pos);
                    if (updated != content) makeASTWithMeta(ESigil(type, updated, modifiers), n.metadata, n.pos) else n;

                default:
                    n;
            }
        });
    }

    /**
     * Rewrite event values inside an HEEx string conservatively.
     * Only transforms attributes like: phx-click="SomeEvent" → phx-click="some_event".
     * Skips dynamic expressions and non-quoted values.
     */
    static function rewriteHeexString(s: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): String {
        // Pattern: (phx-<name>)\s*=\s*"([^"]*)"
        // We will validate <name> with isEventAttr and then normalize the captured value.
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var idx = s.indexOf("phx-", i);
            if (idx == -1) {
                out.add(s.substr(i));
                break;
            }
            // copy up to idx
            out.add(s.substr(i, idx - i));
            // read attribute name
            var j = idx;
            while (j < s.length) {
                var ch = s.charAt(j);
                var isNameChar = ~/^[A-Za-z0-9_-]$/.match(ch);
                if (!isNameChar) break;
                j++;
            }
            var attrName = s.substr(idx, j - idx);
            // If this is not a LiveView event attribute (e.g., phx-track-static, phx-hook),
            // copy the attribute name verbatim and continue scanning from the same
            // position so that any following whitespace/equals/value is preserved.
            if (!isEventAttr(attrName)) {
                out.add(attrName);
                i = j;
                continue;
            }
            out.add(attrName);
            // Skip whitespace
            while (j < s.length && ~/^\s$/.match(s.charAt(j))) j++;
            if (j >= s.length || s.charAt(j) != '=') {
                i = j;
                continue;
            }
            out.add("="); j++;
            while (j < s.length && ~/^\s$/.match(s.charAt(j))) j++;
            if (j >= s.length || s.charAt(j) != '"') {
                // Not a quoted value – leave as-is
                i = j;
                continue;
            }
            // Quoted string start
            out.add('"'); j++;
            var valStart = j;
            var valBuf = new StringBuf();
            var closed = false;
            while (j < s.length) {
                var ch2 = s.charAt(j);
                if (ch2 == '"') { closed = true; break; }
                // Do not rewrite dynamic expressions like { ... } or <%= ... %>
                if (ch2 == '{' || (ch2 == '<' && j + 2 < s.length && s.substr(j, 3) == "<%=")) {
                    // Copy the rest unchanged until we hit the closing quote
                    valBuf = new StringBuf();
                    valBuf.add(s.substr(valStart, j - valStart));
                    // fast-forward to closing quote
                    var k = j;
                    while (k < s.length && s.charAt(k) != '"') k++;
                    valBuf.add(s.substr(j, k - j));
                    j = k; // j now at closing quote or end
                    break;
                }
                valBuf.add(ch2);
                j++;
            }
            var rawVal = valBuf.toString();
            if (closed) {
                var snake = toEventSnakeCase(rawVal);
                if (!isValidEventName(snake)) {
                    warn(ctx, 'Invalid LiveView event name "${rawVal}" in ${attrName}; normalized to "${snake}"', pos);
                }
                out.add(snake);
                out.add('"');
                j++; // skip closing quote
                i = j;
            } else {
                // Unterminated quote; copy remainder as-is
                out.add(rawVal);
                i = j;
            }
        }
        return out.toString();
    }
}

#end
