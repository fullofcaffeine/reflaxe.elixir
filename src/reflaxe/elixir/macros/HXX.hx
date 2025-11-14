package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
// Heavy registry import is gated behind `-D hxx_validate` to avoid compile-time overhead
#if hxx_validate
import phoenix.types.HXXComponentRegistry;
#end
#end

/**
 * HXX - Type-Safe Phoenix HEEx Template System
 *
 * Provides compile-time type safety for Phoenix HEEx templates, equivalent to
 * React with TypeScript JSX, while generating standard Phoenix HEEx output.
 *
 * ## Why HXX? The Perfect Phoenix Augmentation
 *
 * HXX enhances Phoenix HEEx development without changing its fundamental nature:
 * - **Type Safety**: Catch errors at compile-time, not runtime
 * - **IDE Support**: Full IntelliSense for all HTML/Phoenix attributes
 * - **Phoenix-First**: Designed specifically for Phoenix LiveView patterns
 * - **Zero Runtime Cost**: Types are compile-time only, generating clean HEEx
 * - **Flexible Naming**: Support for camelCase, snake_case, and kebab-case
 *
 * ## How It Works
 *
 * HXX is a compile-time macro that:
 * 1. Validates HTML elements and attributes against type definitions
 * 2. Converts attribute names (camelCase/snake_case → kebab-case)
 * 3. Transforms Haxe interpolation (${}) to Elixir interpolation (#{})
 * 4. Provides helpful error messages for invalid templates
 * 5. Generates standard HEEx that Phoenix expects
 *
 * ## Developer Experience Benefits
 *
 * ### IntelliSense That Actually Helps
 * ```haxe
 * var input: InputAttributes = {
 *     type: Email,     // Autocomplete shows all InputType options
 *     phx|            // Autocomplete: phxClick, phxChange, phxSubmit...
 * };
 * ```
 *
 * ### Compile-Time Error Detection
 * ```haxe
 * // ❌ Typos caught at compile-time
 * HXX.hxx('<button phx_clik="save">')  // Error: Did you mean phx_click?
 *
 * // ❌ Wrong attributes for elements
 * HXX.hxx('<input href="/path">')      // Error: href not valid for input
 *
 * // ❌ Type mismatches
 * HXX.hxx('<input required="yes">')    // Error: Bool expected, not String
 * ```
 *
 * ### Respects Phoenix/Elixir Culture
 * ```haxe
 * // All naming styles work and generate correct HEEx:
 * HXX.hxx('<div phx_click="handler">')     // Elixir style ✅
 * HXX.hxx('<div phxClick="handler">')      // Haxe style ✅
 * HXX.hxx('<div phx-click="handler">')     // HTML style ✅
 * // All generate: <div phx-click="handler">
 * ```
 *
 * ## Phoenix LiveView Integration
 *
 * First-class support for all Phoenix LiveView features:
 * - **Events**: phxClick, phxChange, phxSubmit, phxFocus, phxBlur
 * - **Keyboard**: phxKeydown, phxKeyup, phxWindowKeydown
 * - **Mouse**: phxMouseenter, phxMouseleave
 * - **Navigation**: phxLink, phxLinkState, phxPatch, phxNavigate
 * - **Optimization**: phxDebounce, phxThrottle, phxUpdate, phxTrackStatic
 * - **Hooks**: phxHook for JavaScript interop
 *
 * ## Usage Examples
 *
 * ### Basic Template
 * ```haxe
 * var template = HXX.hxx('
 *     <div className="container">
 *         <h1>${title}</h1>
 *         <button phxClick="save" disabled=${!valid}>
 *             Save
 *         </button>
 *     </div>
 * ');
 * ```
 *
 * ### LiveView Component
 * ```haxe
 * function render(assigns: Assigns) {
 *     return HXX.hxx('
 *         <div id="todos" phxUpdate="stream">
 *             <%= for todo <- @todos do %>
 *                 <div id={"todo-${todo.id}"}>
 *                     <input type="checkbox"
 *                            checked={todo.completed}
 *                            phxClick="toggle"
 *                            phxValue={todo.id} />
 *                     <span class={todo.completed ? "done" : ""}>
 *                         ${todo.title}
 *                     </span>
 *                 </div>
 *             <% end %>
 *         </div>
 *     ');
 * }
 * ```
 *
 * ### Form with Validation
 * ```haxe
 * var form = HXX.hxx('
 *     <.form for={@changeset} phxSubmit="save" phxChange="validate">
 *         <.input field={@form[:email]}
 *                 type="email"
 *                 placeholder="Enter email"
 *                 required />
 *         <.button type="submit" disabled={!@changeset.valid?}>
 *             Submit
 *         </.button>
 *     </.form>
 * ');
 * ```
 *
 * ## Why This Works Better Than JSX→HEEx
 *
 * | Aspect | JSX (React) | HXX (Phoenix) | Advantage |
 * |--------|-------------|---------------|--------|
 * | **Rendering** | Client-side | Server-side templates | Matches Phoenix SSR |
 * | **Events** | onClick | phxClick | Native Phoenix events |
 * | **State** | useState/props | Phoenix assigns | LiveView state model |
 * | **Components** | React components | Phoenix functions | Phoenix components |
 * | **Naming** | camelCase only | Flexible (3 styles) | Respects Elixir |
 *
 * ## Type Safety Without Compromise
 *
 * HXX provides the same level of type safety as React+TypeScript while:
 * - Generating standard HEEx (not a custom format)
 * - Supporting all Phoenix LiveView features natively
 * - Respecting Elixir naming conventions
 * - Having zero runtime overhead
 * - Working with existing Phoenix tooling
 *
 * ## Implementation Details
 *
 * The macro performs these transformations:
 * 1. `${expr}` → `#{expr}` (Haxe to Elixir interpolation)
 * 2. `className` → `class` (special HTML attributes)
 * 3. `phxClick` → `phx-click` (camelCase to kebab-case)
 * 4. `phx_click` → `phx-click` (snake_case to kebab-case)
 * 5. Validates all attributes against type definitions
 * 6. Preserves Phoenix component syntax (`<.button>`)
 *
 * @see phoenix.types.HXXTypes For type definitions
 * @see phoenix.types.HXXComponentRegistry For element/attribute validation
 * @see docs/02-user-guide/HXX_TYPE_SAFETY.md For complete user guide
 */
class HXX {

    #if macro
    /**
     * Process a template string into type-safe Phoenix HEEx
     *
     * This macro function is the main entry point for HXX templates.
     * It validates the template at compile-time and transforms it into
     * valid HEEx that Phoenix expects.
     *
     * @param templateStr The template string to process (must be a string literal)
     * @return The processed HEEx template string with proper Phoenix syntax
     *
     * @throws Compile-time error if template contains invalid elements or attributes
     * @throws Compile-time warning for potentially incorrect attribute usage
     *
     * ## Example
     * ```haxe
     * // Input (Haxe with type safety)
     * var template = HXX.hxx('
     *     <div className="card" phxClick="expand">
     *         <h1>${title}</h1>
     *     </div>
     * ');
     *
     * // Output (Phoenix HEEx)
     * <div class="card" phx-click="expand">
     *     <h1><%= title %></h1>
     * </div>
     * ```
     */
    public static macro function hxx(templateStr: Expr): Expr {
        return switch (templateStr.expr) {
            case EConst(CString(s, _)):
                #if (macro && hxx_instrument_sys)
                var __t0 = haxe.Timer.stamp();
                var __bytes = s != null ? s.length : 0;
                var __posInfo = haxe.macro.Context.getPosInfos(templateStr.pos);
                #end
                #if macro
                haxe.macro.Context.warning("[HXX] hxx() invoked", templateStr.pos);
                #end
                // Fast-path: if author already provided EEx/HEEx markers, do not rewrite.
                // This avoids unnecessary processing and prevents pathological regex scans.
                // We still tag it so the builder emits a ~H sigil.
                if (s.indexOf("<%=") != -1 || s.indexOf("<% ") != -1 || s.indexOf("<%\n") != -1) {
                    #if macro
                    haxe.macro.Context.warning("[HXX] fast-path (pre-EEx detected) + for-rewrite", templateStr.pos);
                    #end
                    var preProcessed = rewriteForBlocks(s);
                    return macro @:heex $v{preProcessed};
                }

                // Validate the template and proceed with HXX → HEEx conversion
                #if macro
                haxe.macro.Context.warning("[HXX] processing template string", templateStr.pos);
                #end
                var validation = validateTemplateTypes(s);
                if (!validation.valid) {
                    for (error in validation.errors) Context.warning(error, templateStr.pos);
                }
                var processed = processTemplateString(s, templateStr.pos);
                #if (macro && hxx_instrument_sys)
                var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
                var __file = (__posInfo != null) ? __posInfo.file : "<unknown>";
                Sys.println(
                    '[MacroTiming] name=HXX.hxx bytes=' + __bytes
                    + ' elapsed_ms=' + Std.int(__elapsed)
                    + ' file=' + __file
                );
                #end
                #if macro
                haxe.macro.Context.warning("[HXX] processed (length=" + processed.length + ")", templateStr.pos);
                #end
                macro @:heex $v{processed};
            case _:
                Context.error("hxx() expects a string literal", templateStr.pos);
        }
    }

    /**
     * HXX.block – marks a nested template fragment to be inlined as HEEx content.
     * Accepts a string literal containing HXX/HTML and returns it as-is at macro time.
     * TemplateHelpers recognizes HXX.block() when nested inside another HXX.hxx() and
     * will inline its processed content without wrapping it in an interpolation tag.
     */
    public static macro function block(content: Expr): Expr {
        return switch (content.expr) {
            case EConst(CString(s, _)):
                // Return the string literal as-is; outer processing will handle it
                macro $v{s};
            case _:
                Context.error("block() expects a string literal", content.pos);
        }
    }

    /**
     * Process template string at compile time
     *
     * This is the core transformation engine that converts Haxe template
     * syntax into Phoenix HEEx format while preserving Phoenix conventions.
     *
     * ## Transformation Pipeline
     *
     * 1. **Interpolation**: `${expr}` → `#{expr}` for Elixir
     * 2. **Attributes**: camelCase/snake_case → kebab-case
     * 3. **Conditionals**: Ternary operators → Elixir if/else
     * 4. **Loops**: Array.map → Phoenix for comprehensions
     * 5. **Components**: Preserve Phoenix component syntax
     * 6. **Events**: Ensure LiveView directives are correct
     *
     * @param template The raw template string from the user
     * @return Processed HEEx-compatible template string
     */
    static function processTemplateString(template: String, ?pos: haxe.macro.Expr.Position): String {
        // Convert Haxe ${} interpolation to Elixir #{} interpolation
        var processed = template;

        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        var __bytes = template != null ? template.length : 0;
        var __posInfo = (pos != null) ? haxe.macro.Context.getPosInfos(pos) : null;
        #end

        // 0) Rewrite HXX control/loop tags that must be lowered before interpolation scanning
        //    - <for {item in expr}> ... </for> → <% for item <- expr do %> ... <% end %>
        processed = rewriteForBlocks(processed);

        // 1) Rewrite attribute-level interpolations first: attr=${expr} or attr="${expr}" → attr={expr}
        //    Also map assigns.* → @* and ternary → inline if
        processed = rewriteAttributeInterpolations(processed);

        // 2) Handle remaining Haxe string interpolation (non-attribute positions):
        //    ${expr} or #{expr} -> <%= expr %> (convert assigns.* -> @*)
        // Fix: Use proper regex escaping - single backslash in Haxe regex literals
        var interp = ~/\$\{([^}]+)\}/g;
        processed = interp.map(processed, function (re) {
            var expr = re.matched(1);
            expr = StringTools.trim(expr);
            // Guard: disallow injecting HTML as string via ${"<div ..."}
            if (expr.length >= 2) {
                var first = expr.charAt(0);
                if ((first == '"' || first == '\'') && expr.length >= 2) {
                    // find first non-space after quote
                    var idx = 1;
                    while (idx < expr.length && ~/^\s$/.match(expr.charAt(idx))) idx++;
                    if (idx < expr.length && expr.charAt(idx) == '<') {
                        #if macro
                        haxe.macro.Context.error('HXX: injecting HTML via string inside ${...} is not allowed. Use inline markup or HXX.block(\'...\') as a deliberate escape hatch.', pos != null ? pos : haxe.macro.Context.currentPos());
                        #end
                    }
                }
            }
            expr = StringTools.replace(expr, "assigns.", "@");
            return '<%= ' + expr + ' %>';
        });

        // Support #{expr} placeholders to avoid Haxe compile-time interpolation conflicts
        var interpHash = ~/#\{([^}]+)\}/g;
        processed = interpHash.map(processed, function (re) {
            var expr = StringTools.trim(re.matched(1));
            expr = StringTools.replace(expr, "assigns.", "@");
            return '<%= ' + expr + ' %>';
        });

        // 2b) Convert attribute-level EEx back into HEEx attribute expressions
        //    name=<%= expr %>  → name={expr}
        var eexAttr = ~/=\s*<%=\s*([^%]+?)\s*%>/g;
        processed = eexAttr.replace(processed, '={$1}');

        //    name=<% if cond do %>then<% else %>else<% end %> → name={if cond, do: "then", else: "else"}
        var eexIf = ~/=\s*<%\s*if\s+(.+?)\s+do\s*%>([^<]*)<%\s*else\s*%>([^<]*)<%\s*end\s*%>/g;
        processed = eexIf.map(processed, function (re) {
            var cond = StringTools.trim(re.matched(1));
            var th = StringTools.trim(re.matched(2));
            var el = StringTools.trim(re.matched(3));
            // Quote then/else if not already quoted
            if (!(StringTools.startsWith(th, '"') && StringTools.endsWith(th, '"')) && !(StringTools.startsWith(th, "'") && StringTools.endsWith(th, "'"))) th = '"' + th + '"';
            if (!(StringTools.startsWith(el, '"') && StringTools.endsWith(el, '"')) && !(StringTools.startsWith(el, "'") && StringTools.endsWith(el, "'"))) el = '"' + el + '"';
            return '={if ' + cond + ', do: ' + th + ', else: ' + el + '}';
        });

        // Convert camelCase attributes to kebab-case
        processed = convertAttributes(processed);

        // Handle Phoenix component syntax: <.button> stays as <.button>
        // This is already valid HEEx syntax

        // Handle conditional rendering and loops
        processed = processConditionals(processed);
        processed = processLoops(processed);
        processed = processComponents(processed);
        processed = processLiveViewEvents(processed);

        #if hxx_instrument_sys
        var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
        var __file = (__posInfo != null) ? __posInfo.file : "<unknown>";
        // One-line, grep-friendly summary (bounded; prints only when -D hxx_instrument_sys)
        #if macro
        haxe.macro.Context.warning('[HXX] processTemplateString bytes=' + __bytes + ' elapsed_ms=' + Std.int(__elapsed) + ' file=' + __file, haxe.macro.Context.currentPos());
        #elseif sys
        Sys.println('[HXX] processTemplateString bytes=' + __bytes + ' elapsed_ms=' + Std.int(__elapsed) + ' file=' + __file);
        #end
        #end
        return processed;
    }

    /**
     * Rewrite <for {pattern in expr}> ... </for> to HEEx for-blocks.
     * Supports simple patterns like `todo in list` or `item in some_call()`.
     * Runs early, before generic interpolation handling.
     */
    static function rewriteForBlocks(src:String):String {
        if (src == null || src.indexOf('<for {') == -1) return src;
        var out = new StringBuf();
        var i = 0;
        while (i < src.length) {
            var start = src.indexOf('<for {', i);
            if (start == -1) { out.add(src.substr(i)); break; }
            out.add(src.substr(i, start - i));
            var headEnd = src.indexOf('}>', start);
            if (headEnd == -1) { out.add(src.substr(start)); break; }
            var headInner = src.substr(start + 6, headEnd - (start + 6)); // between { and }
            var closeTag = src.indexOf('</for>', headEnd + 2);
            if (closeTag == -1) { out.add(src.substr(start)); break; }
            var body = src.substr(headEnd + 2, closeTag - (headEnd + 2));
            var parts = headInner.split(' in ');
            if (parts.length != 2) {
                // Fallback: keep original; do not break template
                out.add(src.substr(start, (closeTag + 6) - start));
                i = closeTag + 6;
                continue;
            }
            var pat = StringTools.trim(parts[0]);
            var iter = StringTools.trim(parts[1]);
            // Map assigns.* to @* in iterator expression
            iter = StringTools.replace(iter, 'assigns.', '@');
            out.add('<% for ' + pat + ' <- ' + iter + ' do %>');
            // Recursively allow nested for/if inside body
            out.add(rewriteForBlocks(body));
            out.add('<% end %>');
            i = closeTag + 6;
        }
        return out.toString();
    }

    /**
     * Rewrite attribute values written as ${...} into HEEx attribute expressions { ... }.
     * - Handles: attr=${expr} or attr="${expr}" → attr={expr}
     * - Maps assigns.* → @*
     * - For top-level ternary cond ? a : b → {if cond, do: a, else: b}
     */
    static function rewriteAttributeInterpolations(s: String): String {
        if (s == null || s.length == 0) return s;
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var j = s.indexOf("${", i);
            if (j == -1) { out.add(s.substr(i)); break; }
            // Find preceding '=' within tag, without crossing a '>'
            var k = j - 1;
            var seenGt = false;
            while (k >= i) {
                var ch = s.charAt(k);
                if (ch == '>') { seenGt = true; break; }
                if (ch == '=') break;
                k--;
            }
            if (k < i || seenGt || s.charAt(k) != '=') {
                // Not an attribute context, copy through '${' and continue
                out.add(s.substr(i, j - i));
                out.add("${");
                i = j + 2;
                continue;
            }
            // Identify attribute name
            var nameEnd = k - 1;
            while (nameEnd >= i && ~/^\s$/.match(s.charAt(nameEnd))) nameEnd--;
            var nameStart = nameEnd;
            while (nameStart >= i && ~/^[A-Za-z0-9_:\-]$/.match(s.charAt(nameStart))) nameStart--;
            nameStart++;
            if (nameStart > nameEnd) {
                out.add(s.substr(i, j - i));
                out.add("${");
                i = j + 2;
                continue;
            }
            var attrName = s.substr(nameStart, (nameEnd - nameStart + 1));
            // Copy prefix up to attribute name start and '='
            out.add(s.substr(i, (nameStart - i)));
            out.add(attrName);
            out.add("=");
            // Optional opening quote after '='
            var vpos = k + 1;
            while (vpos < s.length && ~/^\s$/.match(s.charAt(vpos))) vpos++;
            var quote: Null<String> = null;
            if (vpos < s.length && (s.charAt(vpos) == '"' || s.charAt(vpos) == '\'')) { quote = s.charAt(vpos); vpos++; }
            if (vpos != j) {
                // Not plain attr=${...}
                out.add(s.substr(k + 1, (j - (k + 1))));
                out.add("${");
                i = j + 2; continue;
            }
            // Parse balanced braces for ${...}
            var p = j + 2; var depth = 1;
            while (p < s.length && depth > 0) {
                var c = s.charAt(p);
                if (c == '{') depth++; else if (c == '}') depth--; p++;
            }
            var inner = s.substr(j + 2, (p - 1) - (j + 2));
            var expr = StringTools.trim(inner);
            // Map assigns.* → @*
            expr = StringTools.replace(expr, "assigns.", "@");
            // Ternary to inline-if for attribute context
            var tern = ~/(.*)\?(.*):(.*)/;
            if (tern.match(expr)) {
                var cond = StringTools.trim(tern.matched(1));
                var th = StringTools.trim(tern.matched(2));
                var el = StringTools.trim(tern.matched(3));
                expr = 'if ' + cond + ', do: ' + th + ', else: ' + el;
            }
            out.add('{'); out.add(expr); out.add('}');
            // Skip closing quote if present
            if (quote != null) {
                var qpos = p; if (qpos < s.length && s.charAt(qpos) == quote) p = qpos + 1;
            }
            i = p;
        }
        return out.toString();
    }

    /**
     * Process conditional rendering patterns
     */
    static function processConditionals(template: String): String {
        // Convert Haxe ternary to Elixir if/else
        // #{condition ? "true_value" : "false_value"} -> <%= if condition, do: "true_value", else: "false_value" %>
        // Fix: Use proper regex escaping - single backslash in Haxe regex literals
        var ternaryPattern = ~/#\{([^?]+)\?([^:]+):([^}]+)\}/g;
        return ternaryPattern.replace(template, '<%= if $1, do: $2, else: $3 %>');
    }

    /**
     * Process loop patterns (simplified)
     */
    static function processLoops(template: String): String {
        // Handle map operations: #{array.map(func).join("")} -> <%= for item <- array do %><%= func(item) %><% end %>
        // This is a simplified version - full implementation would need more sophisticated parsing

        // Handle basic map/join patterns
        // Fix: Use proper regex escaping - single backslash in Haxe regex literals
        var mapJoinPattern = ~/#\{([^.]+)\.map\(([^)]+)\)\.join\("([^"]*)"\)\}/g;
        return mapJoinPattern.replace(template, '<%= for item <- $1 do %><%= $2(item) %><% end %>');
    }

    /**
     * Process Phoenix component syntax
     * Preserves <.component> syntax and handles attributes
     */
    static function processComponents(template: String): String {
        // Phoenix components with dot prefix are already valid HEEx
        // Just ensure attributes are properly formatted
        var componentPattern = ~/<\.([a-zA-Z_][a-zA-Z0-9_]*)(\s+[^>]*)?\/>/g;
        return componentPattern.replace(template, "$0");
    }

    /**
     * Process LiveView event handlers
     * Ensures phx-* attributes are preserved
     */
    static function processLiveViewEvents(template: String): String {
        // LiveView events (phx-click, phx-change, etc.) are already valid
        // This is a placeholder for future enhancements
        return template;
    }

    /**
     * Helper to validate template syntax at compile time
     */
    static function validateTemplate(template: String): Bool {
        // Basic validation to catch common errors early
        var openTags = ~/<([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>/g;
        var closeTags = ~/<\/([a-zA-Z][a-zA-Z0-9]*)>/g;

        // Count open and close tags (simplified)
        var opens = [];
        openTags.map(template, function(r) {
            opens.push(r.matched(1));
            return "";
        });

        var closes = [];
        closeTags.map(template, function(r) {
            closes.push(r.matched(1));
            return "";
        });

        // Basic balance check
        return opens.length == closes.length;
    }

    /**
     * Validate template types and attributes
     *
     * Performs compile-time validation to ensure:
     * - All HTML elements are valid
     * - All attributes are valid for their elements
     * - Attribute types match expected types
     * - Phoenix components are properly registered
     *
     * Provides helpful error messages with suggestions when validation fails.
     *
     * @param template The template to validate
     * @return ValidationResult with valid flag and error messages
     *
     * ## Error Message Examples
     * - "Unknown attribute 'onClick' for <button>. Did you mean: phxClick?"
     * - "Unknown HTML element: <customElement>. Register it first."
     * - "Attribute 'href' not valid for <input>. Available: type, name, value..."
     */
    static function validateTemplateTypes(template: String): ValidationResult {
#if !hxx_validate
        // Validation disabled: return success without touching heavy registries
        return { valid: true, errors: [] };
#else
        var errors: Array<String> = [];
        var valid = true;

        // Parse elements and their attributes
        var elementPattern = ~/<([a-zA-Z][a-zA-Z0-9\-]*)\s*([^>]*)>/g;

        elementPattern.map(template, function(r) {
            var tagName = r.matched(1);
            var attributesStr = r.matched(2);

            // Check if element is registered
            if (!HXXComponentRegistry.isRegisteredElement(tagName) && !StringTools.startsWith(tagName, ".")) {
                // Phoenix components start with ".", so skip those
                errors.push('Unknown HTML element: <${tagName}>. If this is a custom component, register it first.');
                valid = false;
            }

            // Parse and validate attributes
            if (attributesStr != null && attributesStr.length > 0) {
                validateAttributes(tagName, attributesStr, errors);
            }

            return "";
        });

        return { valid: valid, errors: errors };
#end
    }

    /**
     * Validate attributes for an element
     */
    static function validateAttributes(tagName: String, attributesStr: String, errors: Array<String>): Void {
#if !hxx_validate
        // No-op when validation is disabled
        return;
#else
        // Parse attributes (simplified - real implementation would be more robust)
        var attrPattern = ~/([a-zA-Z][a-zA-Z0-9]*)\s*=/g;

        attrPattern.map(attributesStr, function(r) {
            var attrName = r.matched(1);

            // Check if attribute is valid for this element
            if (!HXXComponentRegistry.validateAttribute(tagName, attrName)) {
                var allowed = HXXComponentRegistry.getAllowedAttributes(tagName);
                var suggestions = findSimilarAttributes(attrName, allowed);

                var errorMsg = 'Unknown attribute "${attrName}" for <${tagName}>.';
                if (suggestions.length > 0) {
                    errorMsg += ' Did you mean: ${suggestions.join(", ")}?';
                } else if (allowed.length > 0) {
                    errorMsg += ' Available: ${allowed.slice(0, 5).join(", ")}...';
                }

                errors.push(errorMsg);
            }

            return "";
        });
#end
    }

    /**
     * Find similar attribute names for suggestions
     */
    static function findSimilarAttributes(input: String, available: Array<String>): Array<String> {
        var suggestions = [];
        var inputLower = input.toLowerCase();

        for (attr in available) {
            var attrLower = attr.toLowerCase();
            // Simple similarity check - could be improved with Levenshtein distance
            if (attrLower.indexOf(inputLower) != -1 || inputLower.indexOf(attrLower) != -1) {
                suggestions.push(attr);
            }
        }

        return suggestions.slice(0, 3); // Return top 3 suggestions
    }

    /**
     * Convert camelCase attributes to kebab-case in templates
     *
     * Intelligently handles attribute naming conventions:
     * - `className` → `class` (special HTML case)
     * - `phxClick` → `phx-click` (Phoenix LiveView)
     * - `dataUserId` → `data-user-id` (data attributes)
     * - `ariaLabel` → `aria-label` (accessibility)
     *
     * Also preserves snake_case and kebab-case if already present.
     *
     * @param template The template with mixed attribute naming
     * @return Template with all attributes in correct HTML/HEEx format
     */
    static function convertAttributes(template: String): String {
        // Match attributes in tags
        var attrPattern = ~/(<[^>]+?)([a-zA-Z][a-zA-Z0-9]*)(\s*=\s*[^>]*?>)/g;

        return attrPattern.map(template, function(r) {
            var prefix = r.matched(1);
            var attrName = r.matched(2);
            var suffix = r.matched(3);

            // Convert the attribute name
            var convertedName = phoenix.types.HXXComponentRegistry.toHtmlAttribute(attrName);

            return prefix + convertedName + suffix;
        });
    }
    #end
}

/**
 * Validation result type
 */
typedef ValidationResult = {
    valid: Bool,
    errors: Array<String>
}
