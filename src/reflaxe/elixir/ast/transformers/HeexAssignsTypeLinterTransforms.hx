package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import phoenix.types.HXXComponentRegistry;

using StringTools;

#if macro
import haxe.macro.Context;
import haxe.macro.TypeTools;
#end

/**
 * HeexAssignsTypeLinterTransforms
 *
 * WHAT
 * - Statically validates `@assigns` field usage inside ~H templates generated from HXX.
 * - Reports errors for:
 *   1) Unknown assigns fields (e.g., `@sort_byy` when only `sort_by` exists)
 *   2) Obvious literal type mismatches in comparisons (e.g., `@sort_by == 1` when `sort_by: String`)
 *   3) Unknown HTML attributes on registered elements (e.g., `<input hreff="...">`)
 *   4) Obvious attribute value kind mismatches for boolean-ish attrs and `phx-hook`
 *
 * WHY
 * - HXX authoring must be fully type-checked like TSX. Since HEEx lives in strings until
 *   normalized to ~H, the core compiler can miss invalid usages. This linter bridges that
 *   gap by correlating template `@field` references with the Haxe-typed `assigns` typedef.
 * - Attribute typing reduces "stringly-typed" template bugs (especially for `phx-*` / boolean attrs)
 *   without requiring users to embed target HEEx/EEx syntax.
 *
 * HOW
 * - For each LiveView render(assigns) function:
 *   1) Read the originating Haxe source file from node metadata.
 *   2) Extract the assigns type name from the render signature (e.g., `render(assigns: TodoLiveAssigns)`).
 *   3) Parse the typedef block `typedef TodoLiveAssigns = { ... }` and collect fields with simple kinds
 *      (String, Int, Float, Bool, Array<>, Map<>, Null<T> → unwrap).
 *   4) Walk ~H sigil content within render and:
 *      - Collect `@field` usages and validate against the typedef fields.
 *      - Find literal comparisons with `@field` and check kind compatibility.
 *      - Validate element attributes using `phoenix.types.HXXComponentRegistry` (kebab/camel/snake-case),
 *        allowing `data-*`, `aria-*`, `phx-value-*`, and HEEx directive attrs like `:if`.
 *
 * EXAMPLES
 * Haxe (invalid):
 *   typedef Assigns = { sort_by: String }
 *   HXX.hxx('<div selected={@sort_by == 1}></div>')
 * Error:
 *   HEEx assigns type error: @sort_by is String but compared to Int literal
 *
 * LIMITATIONS (Intentional for M1)
 * - Attribute validation only applies to registered HTML elements (component tags like `<.button>` are skipped).
 * - Only checks obvious attribute kind mismatches (bool-ish attrs + `phx-hook`) when the expression kind is clear.
 * - Does not fully type component props or complex HEEx expressions yet.
 */
class HeexAssignsTypeLinterTransforms {
    // Public entry: non-contextual (throws on error)
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return lint(ast, null);
    }

    // Public entry: contextual (uses CompilationContext for proper error reporting)
    public static function contextualPass(ast: ElixirAST, ctx: reflaxe.elixir.CompilationContext): ElixirAST {
        return lint(ast, ctx);
    }

    static function error(ctx: Null<reflaxe.elixir.CompilationContext>, msg: String, pos: haxe.macro.Expr.Position): Void {
        if (ctx != null) ctx.error(msg, pos); else throw msg;
    }

    static function lint(ast: ElixirAST, ctx: Null<reflaxe.elixir.CompilationContext>): ElixirAST {
        // Lint any render(assigns) function in project files; skip compiler/vendor/std paths
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case EModule(_name, _attrs, body):
                    for (child in body) lintRender(child, ctx);
                case EDefmodule(_name, doBlock):
                    lintRender(doBlock, ctx);
                default:
            }
            return n;
        });
    }

    static function lintRender(n: ElixirAST, ctx: Null<reflaxe.elixir.CompilationContext>): Void {
        switch (n.def) {
            case EDef(name, _args, _guards, body) if (name == "render"):
                // Fail-fast: skip linter if this render body contains neither ~H sigils nor EFragment nodes
                if (!containsHeexOrFragments(body)) {
                    return;
                }
                // Resolve Haxe source path for this function
                var hxPath = (n.metadata != null && n.metadata.sourceFile != null) ? n.metadata.sourceFile : null;
                if (hxPath == null) {
                    // Fallback: search within body for any node carrying sourceFile metadata
                    hxPath = findAnySourceFile(body);
                }
#if debug_assigns_linter
                // DISABLED: trace('[HeexAssignsTypeLinter] render/1 at hxPath=' + hxPath);
#end
                if (hxPath == null) return; // No source; skip
                // Skip compiler/library/internal files to avoid scanning whole libs
                var hxPathNorm = StringTools.replace(hxPath, "\\", "/");
                if (hxPathNorm.indexOf("/reflaxe/elixir/") != -1 || hxPathNorm.indexOf("/vendor/") != -1 || hxPathNorm.indexOf("/std/") != -1) {
                    return;
                }
                var fileContent: String = null;
                try fileContent = sys.io.File.getContent(hxPath) catch (e) fileContent = null;
                if (fileContent == null) return;

                var nearLine: Null<Int> = findMinSourceLine(body);
                var assignsType = (nearLine != null)
                    ? extractAssignsTypeNameBefore(fileContent, nearLine)
                    : extractAssignsTypeName(fileContent);
#if debug_assigns_linter
                // DISABLED: trace('[HeexAssignsTypeLinter] assigns type=' + assignsType);
#end
                if (assignsType == null) return; // cannot determine type name; skip

                var fields = extractAssignsFields(assignsType, fileContent);
#if debug_assigns_linter
                var keys = [for (k in fields.keys()) k].join(',');
                // DISABLED: trace('[HeexAssignsTypeLinter] typedef fields=' + keys);
#end
                if (fields == null) fields = new Map<String, String>();

                // Prefer structured validation first
                // 1) Validate ~H nodes via builder-attached typed HEEx AST (heexAST) or fragment metadata
                validateHeexFragments(body, fields, assignsType, ctx);

                // 2) Validate any native EFragment nodes already present in the render body
                validateNativeEFragments(body, fields, assignsType, ctx);

                // 3) Bridge path: string-based validation for ~H contents (kept until full EFragment emission)
                var contents: Array<{content:String, pos:haxe.macro.Expr.Position}> = [];
                collectHeexContents(body, contents);
                for (item in contents) {
                    var used = collectAtFields(item.content);
#if debug_assigns_linter
                    // DISABLED: trace('[HeexAssignsTypeLinter] ~H content @fields=' + used.join(','));
#end
                    for (f in used) if (!fields.exists(f)) {
                        error(ctx, 'HEEx assigns error: Unknown field @' + f + ' (not found in typedef ' + assignsType + ')', item.pos);
                    }
                    checkLiteralComparisons(item.content, fields, assignsType, ctx, item.pos);
                }
            default:
        }
    }

    static function findAnySourceFile(node: ElixirAST): Null<String> {
        var found: Null<String> = null;
        ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            if (found == null && x.metadata != null && x.metadata.sourceFile != null) {
                found = x.metadata.sourceFile;
            }
            return x;
        });
        return found;
    }

    static function collectHeexContents(node: ElixirAST, out: Array<{content:String, pos:haxe.macro.Expr.Position}>): Void {
        ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            switch (x.def) {
                case ESigil(type, content, _mods) if (type == "H"):
                    out.push({ content: content, pos: x.pos });
                default:
            }
            return x;
        });
    }

    static function findMinSourceLine(node: ElixirAST): Null<Int> {
        var minLine: Null<Int> = null;
        ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            if (x.metadata != null && x.metadata.sourceLine != null) {
                if (minLine == null || x.metadata.sourceLine < minLine) minLine = x.metadata.sourceLine;
            }
            return x;
        });
        return minLine;
    }

    static function containsHeexOrFragments(node: ElixirAST): Bool {
        var found = false;
        ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            if (found) return x;
            switch (x.def) {
                case ESigil(type, _content, _mods) if (type == "H"):
                    found = true;
                case EFragment(_tag, _attrs, _children):
                    found = true;
                default:
            }
            return x;
        });
        return found;
    }

    // Validate attributes from parsed fragment metadata (if annotator ran)
    static function validateHeexFragments(node: ElixirAST, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>): Void {
        ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            switch (x.def) {
                case ESigil(type, _content, _mods) if (type == "H"):
                    var meta = x.metadata;
                    if (meta != null) {
                        // Prefer typed HEEx AST when available
                        var nodes = meta.heexAST;
                        if (nodes != null && nodes.length > 0) {
                            validateHeexTypedAST(nodes, fields, typeName, ctx, x.pos);
                        }
                        var frags = meta.heexFragments;
                        if (frags != null) {
                            for (f in frags) {
                                var attrs = f.attributes;
                                if (attrs == null) continue;
                                for (a in attrs) {
                                    var vexpr: String = a.valueExpr;
                                    // Unknown field checks: scan @field tokens
                                    var used = collectAtFields(vexpr);
                                    for (uf in used) {
                                        if (!fields.exists(uf)) {
                                            error(ctx, 'HEEx assigns error: Unknown field @' + uf + ' (not found in typedef ' + typeName + ')', x.pos);
                                        }
                                    }
                                    // Literal kind mismatches within attribute expressions
                                    checkLiteralComparisons(vexpr, fields, typeName, ctx, x.pos);
                                }
                            }
                        }
                    }
                default:
            }
            return x;
        });
    }

    // Validate attributes using native EFragment nodes present in AST
    static function validateNativeEFragments(node: ElixirAST, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>): Void {
        ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            switch (x.def) {
                case EFragment(_tag, _attrs, _children):
                    // Validate this fragment and all nested children via structured walker
                    validateNode(x, fields, typeName, ctx, x.pos);
                default:
            }
            return x;
        });
    }

    // ---------------------------------------------------------------------
    // Typed HEEx AST validation (preferred path)
    // ---------------------------------------------------------------------
    static function validateHeexTypedAST(nodes: Array<ElixirAST>, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        for (n in nodes) validateNode(n, fields, typeName, ctx, pos);
    }

    static function validateNode(n: ElixirAST, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        switch (n.def) {
            case EFragment(tag, attributes, children):
                // Attributes
                for (attr in attributes) {
                    validateAttribute(tag, attr, fields, typeName, ctx, pos);
                }
                // Children
                for (c in children) validateNode(c, fields, typeName, ctx, pos);
            default:
        }
    }

    static function validateAttribute(tag: String, attr: EAttribute, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        // 1) Name validation (only for known HTML elements; allow HEEx directive attrs)
        validateAttributeName(tag, attr.name, ctx, pos);

        // 2) Obvious kind validation for select attributes (bool-ish attrs, phx-hook, etc.)
        validateAttributeValueKind(attr.name, attr.value, fields, ctx, pos);

        // 3) Assigns field usage within `{ ... }` attribute expressions
        validateExprForAssigns(attr.value, fields, typeName, ctx, pos);
    }

    static var allowedHtmlAttributeCache: Map<String, Map<String, Bool>> = new Map();
    static var globalHtmlAttributeCache: Null<Map<String, Bool>> = null;

    static function validateAttributeName(tag: String, attributeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        if (attributeName == null || attributeName.length == 0) return;
        // HEEx directive attrs like :if/:for/:let are valid on any tag.
        if (attributeName.startsWith(":")) return;

        // Only validate registered HTML elements to avoid false positives on Phoenix components/custom tags.
        if (!isRegisteredHtmlElement(tag)) return;

        var canonical = normalizeHeexAttributeName(attributeName);
        var htmlName = HXXComponentRegistry.toHtmlAttribute(canonical);
        // Allow wildcard-style attributes regardless of authoring style (kebab/camel/snake-case).
        if (isWildcardHeexAttribute(canonical) || isWildcardHeexAttribute(htmlName)) return;

        var allowed = getAllowedHtmlAttributesForTag(tag);
        if (allowed.exists(attributeName) || allowed.exists(canonical) || (htmlName != null && allowed.exists(htmlName))) return;

        error(ctx, 'HEEx attribute error: <' + tag + '> does not allow attribute "' + attributeName + '"', pos);
    }

    static function validateAttributeValueKind(attributeName: String, value: ElixirAST, fields: Map<String,String>, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        if (attributeName == null || attributeName.length == 0) return;
        if (attributeName.startsWith(":")) return; // directive attrs: do not validate here

        var canonical = HXXComponentRegistry.toHtmlAttribute(normalizeHeexAttributeName(attributeName));
        if (canonical == null) return;
        var expected = expectedKindForAttribute(canonical);
        if (expected == null) return;

        var actual = inferHeexExprKind(value, fields);
        if (!attributeKindsCompatible(expected, actual)) {
            error(ctx, 'HEEx attribute type error: "' + canonical + '" expects ' + expected + ' but got ' + actual, pos);
        }
    }

    static function isRegisteredHtmlElement(tag: String): Bool {
        if (tag == null || tag.length == 0) return false;
        // Skip Phoenix component tags (<.foo>) and slot tags (<:inner_block>)
        var first = tag.charAt(0);
        if (first == "." || first == ":") return false;
        return HXXComponentRegistry.getElementType(tag) != null;
    }

    static function getAllowedHtmlAttributesForTag(tag: String): Map<String, Bool> {
        var key = tag.toLowerCase();
        if (allowedHtmlAttributeCache.exists(key)) return allowedHtmlAttributeCache.get(key);

        var allowed: Map<String, Bool> = new Map();

        var globals = getGlobalHtmlAttributes();
        for (k in globals.keys()) allowed.set(k, true);

        var attrs = HXXComponentRegistry.getAllowedAttributes(tag);
        for (a in attrs) addAllowedAttributeForms(allowed, a);

        allowedHtmlAttributeCache.set(key, allowed);
        return allowed;
    }

    static function getGlobalHtmlAttributes(): Map<String, Bool> {
        if (globalHtmlAttributeCache != null) return globalHtmlAttributeCache;
        var allowed: Map<String, Bool> = new Map();
        // div is registered with global attributes in HXXComponentRegistry; use it as the source of truth.
        for (a in HXXComponentRegistry.getAllowedAttributes("div")) addAllowedAttributeForms(allowed, a);
        globalHtmlAttributeCache = allowed;
        return allowed;
    }

    static function addAllowedAttributeForms(allowed: Map<String, Bool>, name: String): Void {
        if (name == null || name.length == 0) return;
        // Wildcard attributes (data*) are handled separately.
        if (name.indexOf("*") != -1) return;
        allowed.set(name, true);
        var html = HXXComponentRegistry.toHtmlAttribute(name);
        if (html != null) allowed.set(html, true);
    }

    static function normalizeHeexAttributeName(name: String): String {
        // Accept snake_case in templates but validate against canonical kebab-case where applicable.
        return name.indexOf("_") != -1 ? name.split("_").join("-") : name;
    }

    static function isWildcardHeexAttribute(name: String): Bool {
        if (name == null) return false;
        var n = name.toLowerCase();
        return n.startsWith("data-") || n.startsWith("aria-") || n.startsWith("phx-value-");
    }

    static function expectedKindForAttribute(canonicalAttr: String): Null<String> {
        return switch (canonicalAttr) {
            // HTML boolean-ish attributes (subset)
            case "disabled", "required", "checked", "selected", "readonly", "multiple", "autofocus",
                 "defer", "async", "nomodule",
                 // Phoenix/ARIA common boolean-ish attributes
                 "phx-track-static", "aria-hidden":
                "bool";
            // Phoenix hook name
            case "phx-hook":
                "string";
            default:
                null;
        }
    }

    static function inferHeexExprKind(expr: ElixirAST, fields: Map<String,String>): String {
        if (expr == null) return "unknown";
        return switch (expr.def) {
            case EString(v):
                var t = v != null ? v.trim().toLowerCase() : "";
                (t == "true" || t == "false") ? "bool" : "string";
            case EInteger(_): "int";
            case EFloat(_): "float";
            case EBoolean(_): "bool";
            case ENil: "nil";
            case EAssign(name):
                (fields != null && fields.exists(name)) ? fields.get(name) : "unknown";
            case EBinary(op, _, _):
                (isComparisonOp(op) || op == AndAlso || op == OrElse) ? "bool" : "unknown";
            case EIf(_, thenB, elseB):
                var thenKind = inferHeexExprKind(thenB, fields);
                var elseKind = elseB != null ? inferHeexExprKind(elseB, fields) : "nil";
                if (thenKind == elseKind) thenKind
                else if (thenKind == "nil") elseKind
                else if (elseKind == "nil") thenKind
                else "unknown";
            case EParen(inner):
                inferHeexExprKind(inner, fields);
            default:
                "unknown";
        }
    }

    static function attributeKindsCompatible(expected: String, actual: String): Bool {
        if (expected == null || actual == null) return true;
        // Allow nil for optional attribute omission.
        if (actual == "nil") return true;
        // If we can't confidently infer the kind, do not error.
        if (actual == "unknown") return true;

        return expected == actual;
    }

    static function validateExprForAssigns(expr: ElixirAST, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        // Collect used assigns fields and check comparisons on the fly
        var used = new Map<String,Bool>();
        analyzeExpr(expr, fields, typeName, ctx, pos, used);
        for (k in used.keys()) {
            if (!fields.exists(k)) {
                error(ctx, 'HEEx assigns error: Unknown field @' + k + ' (not found in typedef ' + typeName + ')', pos);
            }
        }
    }

    static function analyzeExpr(expr: ElixirAST, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position, used: Map<String,Bool>): Void {
        switch (expr.def) {
            case EAssign(name):
                used.set(name, true);
            case EField(target, _):
                analyzeExpr(target, fields, typeName, ctx, pos, used);
            case EAccess(target, key):
                analyzeExpr(target, fields, typeName, ctx, pos, used);
                analyzeExpr(key, fields, typeName, ctx, pos, used);
            case EBinary(op, left, right):
                // Recurse first
                analyzeExpr(left, fields, typeName, ctx, pos, used);
                analyzeExpr(right, fields, typeName, ctx, pos, used);
                // Check literal comparisons like @field == "str" or 1 < @field
                if (isComparisonOp(op)) {
                    var lName = extractAssignFieldName(left);
                    var rName = extractAssignFieldName(right);
                    var lLit = extractLiteralKind(left);
                    var rLit = extractLiteralKind(right);
                    if (lName != null && rLit != null) checkKindCompat(lName, rLit, fields, typeName, ctx, pos);
                    if (rName != null && lLit != null) checkKindCompat(rName, lLit, fields, typeName, ctx, pos);
                }
            case EIf(cond, thenB, elseB):
                analyzeExpr(cond, fields, typeName, ctx, pos, used);
                analyzeExpr(thenB, fields, typeName, ctx, pos, used);
                if (elseB != null) analyzeExpr(elseB, fields, typeName, ctx, pos, used);
            case ECall(target, _fn, args):
                if (target != null) analyzeExpr(target, fields, typeName, ctx, pos, used);
                for (a in args) analyzeExpr(a, fields, typeName, ctx, pos, used);
            case EParen(inner):
                analyzeExpr(inner, fields, typeName, ctx, pos, used);
            default:
        }
    }

    static inline function isComparisonOp(op: EBinaryOp): Bool {
        return switch (op) {
            case Equal | NotEqual | Less | Greater | LessEqual | GreaterEqual | StrictEqual | StrictNotEqual: true;
            default: false;
        }
    }

    static function extractAssignFieldName(expr: ElixirAST): Null<String> {
        return switch (expr.def) {
            case EAssign(name): name;
            case EField(target, _): extractAssignFieldName(target);
            case EAccess(target, _): extractAssignFieldName(target);
            default: null;
        }
    }

    static function extractLiteralKind(expr: ElixirAST): Null<String> {
        return switch (expr.def) {
            case EString(_): "string";
            case EInteger(_): "int";
            case EBoolean(_): "bool";
            case ENil: "nil";
            default: null;
        }
    }

    static function checkKindCompat(field: String, litKind: String, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        var fieldKind = fields.exists(field) ? fields.get(field) : null;
        if (fieldKind != null && !kindsCompatible(fieldKind, litKind)) {
            error(ctx, 'HEEx assigns type error: @' + field + ' is ' + fieldKind + ' but compared to ' + litKind + ' literal', pos);
        }
    }

    static function collectAtFields(s: String): Array<String> {
        var found = new Map<String, Bool>();
        var i = 0;
        while (i < s.length) {
            var idx = s.indexOf("@", i);
            if (idx == -1) break;
            var j = idx + 1;
            if (j < s.length && isIdentStart(s.charCodeAt(j))) {
                var k = j + 1;
                while (k < s.length && isIdentPart(s.charCodeAt(k))) k++;
                var name = s.substr(j, k - j);
                found.set(name, true);
                i = k;
            } else {
                i = j;
            }
        }
        return [for (k in found.keys()) k];
    }

    static inline function isIdentStart(c: Int): Bool {
        return (c >= 'A'.code && c <= 'Z'.code) || (c >= 'a'.code && c <= 'z'.code) || c == '_'.code;
    }
    static inline function isIdentPart(c: Int): Bool {
        return isIdentStart(c) || (c >= '0'.code && c <= '9'.code);
    }

    static function checkLiteralComparisons(content: String, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        // Pattern 1: @field <op> <literal>
        var p1 = ~/@([A-Za-z_][A-Za-z0-9_]*)\s*(==|!=|===|!==|<=|>=|<|>)\s*("[^"]*"|\d+|true|false|nil)/g;
        var start1 = 0;
        while (p1.matchSub(content, start1)) {
            var field = p1.matched(1);
            var lit = p1.matched(3);
            var litKind = literalKind(lit);
            var fieldKind = fields.exists(field) ? fields.get(field) : null;
            if (fieldKind != null && !kindsCompatible(fieldKind, litKind)) {
                error(ctx, 'HEEx assigns type error: @' + field + ' is ' + fieldKind + ' but compared to ' + litKind + ' literal', pos);
            }
            var mpos = p1.matchedPos();
            start1 = mpos.pos + mpos.len;
        }
        // Pattern 2: <literal> <op> @field
        var p2 = ~/("[^"]*"|\d+|true|false|nil)\s*(==|!=|===|!==|<=|>=|<|>)\s*@([A-Za-z_][A-Za-z0-9_]*)/g;
        var start2 = 0;
        while (p2.matchSub(content, start2)) {
            var lit2 = p2.matched(1);
            var field2 = p2.matched(3);
            var litKind2 = literalKind(lit2);
            var fieldKind2 = fields.exists(field2) ? fields.get(field2) : null;
            if (fieldKind2 != null && !kindsCompatible(fieldKind2, litKind2)) {
                error(ctx, 'HEEx assigns type error: @' + field2 + ' is ' + fieldKind2 + ' but compared to ' + litKind2 + ' literal', pos);
            }
            var mpos2 = p2.matchedPos();
            start2 = mpos2.pos + mpos2.len;
        }
    }

    static function literalKind(lit: String): String {
        var t = lit.trim();
        if (t == "true" || t == "false") return "bool";
        if (t == "nil") return "nil";
        if (t.length > 0 && t.charAt(0) == '"') return "string";
        // numbers
        return ~/^[0-9]+$/.match(t) ? "int" : "unknown";
    }

    static function kindsCompatible(fieldKind: String, litKind: String): Bool {
        // Allow nil comparisons for nullable-like fields (we do not know nullability yet; allow all)
        if (litKind == "nil") return true;
        if (fieldKind == null || litKind == null) return true;
        // Simple exact match for now
        return fieldKind == litKind;
    }

    static function extractAssignsTypeName(hx: String): Null<String> {
        // Look for: function render(assigns: TypeName)
        var re = ~/function\s+render\s*\(\s*assigns\s*:\s*([A-Za-z0-9_\.]+)/;
        return re.match(hx) ? re.matched(1) : null;
    }

    static function extractAssignsTypeNameBefore(hx: String, nearLine: Int): Null<String> {
        // Scan line-by-line and pick the nearest render(assigns: Type) defined at or before nearLine
        var lines = hx.split("\n");
        var bestName: Null<String> = null;
        var bestLine = -1;
        var re = ~/function\s+render\s*\([^)]*assigns\s*:\s*([A-Za-z0-9_\.]+)/;
        for (idx in 0...lines.length) {
            var line = lines[idx];
            if (re.match(line)) {
                var name = re.matched(1);
                var lineNo = idx + 1;
                if (lineNo <= nearLine && lineNo > bestLine) { bestLine = lineNo; bestName = name; }
            }
        }
        return bestName;
    }

    static function extractAssignsFields(typeName: String, hx: String): Map<String, String> {
        var parsed = extractAssignsFieldsFromTypedefBlock(typeName, hx);
        if (parsed.foundTypedef) {
            return parsed.fields;
        }

#if macro
        // Fallback: resolve assigns typedefs via the Haxe typer so the linter works even
        // when the assigns type is declared in a different module/file.
        var resolved = extractAssignsFieldsViaContext(typeName, hx);
        if (resolved != null) return resolved;
#end

        return parsed.fields;
    }

    private static function extractAssignsFieldsFromTypedefBlock(typeName: String, hx: String): { foundTypedef: Bool, fields: Map<String, String> } {
        var out = new Map<String, String>();
        // Find typedef <typeName> = { ... }
        var idx = hx.indexOf('typedef ' + typeName + '');
        if (idx == -1) return { foundTypedef: false, fields: out };
        var braceStart = hx.indexOf('{', idx);
        if (braceStart == -1) return { foundTypedef: false, fields: out };
        var i = braceStart + 1;
        var depth = 1;
        while (i < hx.length && depth > 0) {
            var ch = hx.charAt(i);
            if (ch == '{') depth++; else if (ch == '}') depth--; i++;
        }
        var braceEnd = i - 1;
        if (braceEnd <= braceStart) return { foundTypedef: false, fields: out };
        var block = hx.substr(braceStart + 1, braceEnd - (braceStart + 1));

        // Support anonymous structure extension: typedef X = {> Base, ... }
        var baseTypes: Array<String> = [];

        // Parse lines: supports both `var name: Type` and `name: Type`, with optional comma/semicolon terminators
        var lines = block.split("\n");
        for (ln in lines) {
            var line = ln.trim();
            if (line.length == 0 || line.startsWith("//")) continue;

            if (line.startsWith(">")) {
                var rest = line.substr(1).trim();
                if (rest.endsWith(",")) rest = rest.substr(0, rest.length - 1).trim();
                if (rest.length > 0) baseTypes.push(rest);
                continue;
            }

            var name: String = null;
            var typeSpec: String = null;
            var reVar = ~/^var\s+([A-Za-z0-9_]+)\s*:\s*([^,;]+)\s*[,;]?$/;
            if (reVar.match(line)) {
                name = reVar.matched(1);
                typeSpec = reVar.matched(2).trim();
            } else {
                var rePlain = ~/^([A-Za-z0-9_]+)\s*:\s*([^,;]+)\s*[,;]?$/;
                if (rePlain.match(line)) {
                    name = rePlain.matched(1);
                    typeSpec = rePlain.matched(2).trim();
                }
            }
            if (name != null && typeSpec != null) {
                out.set(name, normalizeKind(typeSpec));
            }
        }

        for (base in baseTypes) {
            var baseParsed = extractAssignsFieldsFromTypedefBlock(base, hx);
            if (baseParsed.foundTypedef) {
                for (k in baseParsed.fields.keys()) if (!out.exists(k)) out.set(k, baseParsed.fields.get(k));
            }
        }

        return { foundTypedef: true, fields: out };
    }

#if macro
    static function extractAssignsFieldsViaContext(typeName: String, hx: String): Null<Map<String, String>> {
        var candidates = new Array<String>();

        if (typeName.indexOf(".") != -1) {
            candidates.push(typeName);
        }

        var resolvedFromImports = resolveTypeNameFromImports(typeName, hx);
        if (resolvedFromImports != null) candidates.push(resolvedFromImports);

        var packageName = extractPackageName(hx);
        if (packageName != null && typeName.indexOf(".") == -1) {
            candidates.push(packageName + "." + typeName);
        }

        for (candidate in candidates) {
            try {
                var t = Context.getType(candidate);
                var fields = fieldsFromType(t);
                if (fields != null) return fields;
            } catch (_:Dynamic) {
                // try next candidate
            }
        }

        return null;
    }

    static function fieldsFromType(t: haxe.macro.Type): Null<Map<String, String>> {
        var out = new Map<String, String>();
        var followed = TypeTools.follow(t);
        switch (followed) {
            case TAnonymous(a):
                for (f in a.get().fields) {
                    out.set(f.name, normalizeKind(TypeTools.toString(f.type)));
                }
                return out;
            case TType(tdef, params):
                return fieldsFromType(TypeTools.applyTypeParameters(tdef.get().type, tdef.get().params, params));
            default:
                return null;
        }
    }

    static function extractPackageName(hx: String): Null<String> {
        var re = ~/^\s*package\s+([A-Za-z0-9_\.]+)\s*;/m;
        return re.match(hx) ? re.matched(1) : null;
    }

    static function resolveTypeNameFromImports(typeName: String, hx: String): Null<String> {
        var importPaths = new Map<String, String>();

        // Supports:
        // - import a.b.C;
        // - import a.b.C as Alias;
        var re = ~/^\s*import\s+([A-Za-z0-9_\.]+)(?:\s+as\s+([A-Za-z0-9_]+))?\s*;/m;
        var start = 0;
        while (re.matchSub(hx, start)) {
            var full = re.matched(1);
            var alias = re.matched(2);
            var lastDot = full.lastIndexOf(".");
            var visible = (alias != null && alias != "") ? alias : (lastDot == -1 ? full : full.substr(lastDot + 1));
            importPaths.set(visible, full);

            var pos = re.matchedPos();
            start = pos.pos + pos.len;
        }

        if (importPaths.exists(typeName)) {
            return importPaths.get(typeName);
        }

        // Handle module-import prefix usage: Foo.Bar where Foo is imported as a module.
        var dot = typeName.indexOf(".");
        if (dot != -1) {
            var prefix = typeName.substr(0, dot);
            if (importPaths.exists(prefix)) {
                return importPaths.get(prefix) + typeName.substr(dot);
            }
        }

        return null;
    }
#end

    static function normalizeKind(spec: String): String {
        var s = spec.trim();
        // Unwrap Null<T>
        if (s.startsWith("Null<") && s.endsWith(">")) {
            s = s.substr(5, s.length - 6).trim();
        }
        // Basic kinds
        if (s == "String") return "string";
        if (s == "Int") return "int";
        if (s == "Float") return "float";
        if (s == "Bool") return "bool";
        if (~/^Array<.*/.match(s)) return "array";
        if (~/^Map<.*/.match(s)) return "map";
        // Unknown/custom → leave unknown to avoid false positives
        return "unknown";
    }
}

#end
