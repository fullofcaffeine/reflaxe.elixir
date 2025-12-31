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
 * - Component tag validation is currently implemented for a small set of Phoenix core tags
 *   (e.g. `<.form>` and `<.link>`). Unknown components are skipped to avoid false positives.
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
        // Lint any template-producing function in project files; skip compiler/vendor/std paths.
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case EDef(_name, _args, _guards, _body) | EDefp(_name, _args, _guards, _body):
                    lintFunction(n, ctx);
                default:
            }
            return n;
        });
    }

    static function lintFunction(n: ElixirAST, ctx: Null<reflaxe.elixir.CompilationContext>): Void {
        var functionName: String = null;
        var body: ElixirAST = null;
        switch (n.def) {
            case EDef(name, _args, _guards, fnBody):
                functionName = name;
                body = fnBody;
            case EDefp(name, _args, _guards, fnBody):
                functionName = name;
                body = fnBody;
            default:
                return;
        }

        // Fail-fast: skip linter if this function body contains neither ~H sigils nor EFragment nodes
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
        // DISABLED: trace('[HeexAssignsTypeLinter] ' + functionName + '/? at hxPath=' + hxPath);
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
        var assignsTypeSpec = (nearLine != null)
            ? extractAssignsTypeSpecForFunctionBefore(functionName, fileContent, nearLine)
            : extractAssignsTypeSpecForFunction(functionName, fileContent);

        var assignsTypeName = assignsTypeSpec != null ? unwrapAssignsType(assignsTypeSpec) : null;
        var assignsTypeBase = assignsTypeName != null ? stripTypeParameters(assignsTypeName) : null;
#if debug_assigns_linter
        // DISABLED: trace('[HeexAssignsTypeLinter] assigns type spec=' + assignsTypeSpec + ' base=' + assignsTypeBase);
#end
        var fields: Null<Map<String, String>> = (assignsTypeBase != null) ? extractAssignsFields(assignsTypeBase, fileContent) : null;
        var enableAssignsChecks = fields != null;
        var fieldsForValidation = fields != null ? fields : new Map<String, String>();
        var typeNameForErrors = assignsTypeBase != null ? assignsTypeBase : "(unknown assigns type)";
#if debug_assigns_linter
        if (fields != null) {
            var keys = [for (k in fields.keys()) k].join(',');
            // DISABLED: trace('[HeexAssignsTypeLinter] typedef fields=' + keys);
        }
#end

        // Prefer structured validation first
        // 1) Validate ~H nodes via builder-attached typed HEEx AST (heexAST) or fragment metadata
        validateHeexFragments(body, fieldsForValidation, typeNameForErrors, ctx, enableAssignsChecks);

        // 2) Validate any native EFragment nodes already present in the function body
        validateNativeEFragments(body, fieldsForValidation, typeNameForErrors, ctx, enableAssignsChecks);

        // 3) Bridge path: string-based validation for ~H contents (kept until full EFragment emission)
        if (enableAssignsChecks) {
            var contents: Array<{content:String, pos:haxe.macro.Expr.Position}> = [];
            collectHeexContents(body, contents);
            for (item in contents) {
                var used = collectAtFields(item.content);
#if debug_assigns_linter
                // DISABLED: trace('[HeexAssignsTypeLinter] ~H content @fields=' + used.join(','));
#end
                for (f in used) if (!fieldsForValidation.exists(f)) {
                    error(ctx, 'HEEx assigns error: Unknown field @' + f + ' (not found in typedef ' + typeNameForErrors + ')', item.pos);
                }
                checkLiteralComparisons(item.content, fieldsForValidation, typeNameForErrors, ctx, item.pos);
            }
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
    static function validateHeexFragments(node: ElixirAST, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, enableAssignsChecks: Bool): Void {
        ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            switch (x.def) {
                case ESigil(type, _content, _mods) if (type == "H"):
                    var meta = x.metadata;
                    if (meta != null) {
                        // Prefer typed HEEx AST when available
                        var nodes = meta.heexAST;
                        if (nodes != null && nodes.length > 0) {
                            validateHeexTypedAST(nodes, fields, typeName, ctx, x.pos, enableAssignsChecks);
                        }
                        var frags = meta.heexFragments;
                        if (frags != null) {
                            for (f in frags) {
                                var attrs = f.attributes;
                                if (attrs == null) continue;
                                for (a in attrs) {
                                    var vexpr: String = a.valueExpr;
                                    // Unknown field checks: scan @field tokens
                                    if (enableAssignsChecks) {
                                        var used = collectAtFields(vexpr);
                                        for (uf in used) {
                                            if (!fields.exists(uf)) {
                                                error(ctx, 'HEEx assigns error: Unknown field @' + uf + ' (not found in typedef ' + typeName + ')', x.pos);
                                            }
                                        }
                                    }
                                    // Literal kind mismatches within attribute expressions
                                    if (enableAssignsChecks) {
                                        checkLiteralComparisons(vexpr, fields, typeName, ctx, x.pos);
                                    }
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
    static function validateNativeEFragments(node: ElixirAST, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, enableAssignsChecks: Bool): Void {
        ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            switch (x.def) {
                case EFragment(_tag, _attrs, _children):
                    // Validate this fragment and all nested children via structured walker
                    validateNode(x, fields, typeName, ctx, x.pos, enableAssignsChecks);
                default:
            }
            return x;
        });
    }

    // ---------------------------------------------------------------------
    // Typed HEEx AST validation (preferred path)
    // ---------------------------------------------------------------------
    static function validateHeexTypedAST(nodes: Array<ElixirAST>, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position, enableAssignsChecks: Bool): Void {
        for (n in nodes) validateNode(n, fields, typeName, ctx, pos, enableAssignsChecks);
    }

    static function validateNode(n: ElixirAST, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position, enableAssignsChecks: Bool): Void {
        switch (n.def) {
            case EFragment(tag, attributes, children):
                // Attributes
                for (attr in attributes) {
                    validateAttribute(tag, attr, fields, typeName, ctx, pos, enableAssignsChecks);
                }
                // Children
                for (c in children) validateNode(c, fields, typeName, ctx, pos, enableAssignsChecks);
            default:
        }
    }

    static function validateAttribute(tag: String, attr: EAttribute, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position, enableAssignsChecks: Bool): Void {
        // 1) Name validation (only for known HTML elements; allow HEEx directive attrs)
        validateAttributeName(tag, attr.name, ctx, pos);

        // 2) Obvious kind validation for select attributes (bool-ish attrs, phx-hook, etc.)
        validateAttributeValueKind(attr.name, attr.value, fields, ctx, pos);

        // 3) Assigns field usage within `{ ... }` attribute expressions
        validateExprForAssigns(attr.value, fields, typeName, ctx, pos, enableAssignsChecks);
    }

    static var allowedHtmlAttributeCache: Map<String, Map<String, Bool>> = new Map();
    static var globalHtmlAttributeCache: Null<Map<String, Bool>> = null;

    static function validateAttributeName(tag: String, attributeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        if (attributeName == null || attributeName.length == 0) return;
        // HEEx directive attrs like :if/:for/:let are valid on any tag.
        if (attributeName.startsWith(":")) return;

        if (tag != null && tag.length > 0) {
            var first = tag.charAt(0);
            if (first == ".") {
                validatePhoenixCoreComponentAttributeName(tag, attributeName, ctx, pos);
                return;
            }
            // Slot tags (<:inner_block>) don't validate attributes.
            if (first == ":") return;
        }

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

    static function validatePhoenixCoreComponentAttributeName(componentTag: String, attributeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        // Only validate a small allowlist of Phoenix core component tags to avoid
        // false positives on user-defined components.
        var allowed = getAllowedPhoenixCoreComponentAttributes(componentTag);
        if (allowed == null) return;

        var canonical = normalizeHeexAttributeName(attributeName);
        var htmlName = HXXComponentRegistry.toHtmlAttribute(canonical);
        if (isWildcardHeexAttribute(canonical) || isWildcardHeexAttribute(htmlName)) return;

        if (allowed.exists(attributeName) || allowed.exists(canonical) || (htmlName != null && allowed.exists(htmlName))) return;

        error(ctx, 'HEEx component attribute error: <' + componentTag + '> does not allow attribute "' + attributeName + '"', pos);
    }

    static function getAllowedPhoenixCoreComponentAttributes(tag: String): Null<Map<String, Bool>> {
        return switch (tag) {
            case ".form":
                buildAllowedComponentAttributesFromHtmlTag("form", ["for", "as", "multipart"]);
            case ".link":
                buildAllowedComponentAttributesFromHtmlTag("a", ["navigate", "patch", "method", "replace"]);
            default:
                null;
        }
    }

    static function buildAllowedComponentAttributesFromHtmlTag(htmlTag: String, extra: Array<String>): Map<String, Bool> {
        var allowed: Map<String, Bool> = new Map();

        var html = getAllowedHtmlAttributesForTag(htmlTag);
        for (k in html.keys()) allowed.set(k, true);

        for (name in extra) addAllowedAttributeForms(allowed, name);

        return allowed;
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

    static function validateExprForAssigns(expr: ElixirAST, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position, enableAssignsChecks: Bool): Void {
        if (!enableAssignsChecks) return;

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

    static function extractAssignsTypeSpecForFunction(functionName: String, hx: String): Null<String> {
        return extractAssignsTypeSpecForFunctionBefore(functionName, hx, null);
    }

    static function extractAssignsTypeSpecForFunctionBefore(functionName: String, hx: String, nearLine: Null<Int>): Null<String> {
        if (functionName == null || functionName.length == 0) return null;

        var escaped = escapeRegExp(functionName);
        var re = new EReg('function\\s+' + escaped + '\\s*\\(', "g");
        var searchStart = 0;

        var bestLine = -1;
        var bestType: Null<String> = null;

        while (re.matchSub(hx, searchStart)) {
            var matchPos = re.matchedPos();
            var openParenIndex = matchPos.pos + matchPos.len - 1;

            var lineNo = lineNumberAtIndex(hx, matchPos.pos);

            if (nearLine == null || lineNo <= nearLine) {
                var params = extractEnclosed(hx, openParenIndex, "(", ")");
                if (params != null) {
                    var assignsTypeSpec = extractTypeSpecForParam("assigns", params);
                    if (assignsTypeSpec != null && lineNo > bestLine) {
                        bestLine = lineNo;
                        bestType = assignsTypeSpec;
                    }
                }
            }

            searchStart = matchPos.pos + matchPos.len;
        }

        return bestType;
    }

    static function unwrapAssignsType(typeSpec: String): Null<String> {
        if (typeSpec == null) return null;
        var trimmed = typeSpec.trim();
        if (trimmed.length == 0) return null;

        var lt = trimmed.indexOf("<");
        if (lt == -1) return trimmed;
        var outer = trimmed.substr(0, lt).trim();
        if (!outer.endsWith("Assigns")) return trimmed;

        var inner = extractEnclosed(trimmed, lt, "<", ">");
        return inner != null ? inner.trim() : trimmed;
    }

    static function stripTypeParameters(typeSpec: String): Null<String> {
        if (typeSpec == null) return null;
        var trimmed = typeSpec.trim();
        if (trimmed.length == 0) return null;

        var lt = trimmed.indexOf("<");
        return lt == -1 ? trimmed : trimmed.substr(0, lt).trim();
    }

    static function extractEnclosed(hx: String, openIndex: Int, openToken: String, closeToken: String): Null<String> {
        if (hx == null || openIndex < 0 || openIndex >= hx.length) return null;
        if (hx.substr(openIndex, openToken.length) != openToken) return null;

        var i = openIndex;
        var depth = 0;
        var start = openIndex + openToken.length;

        while (i < hx.length) {
            var ch = hx.charAt(i);
            if (ch == openToken) {
                depth++;
            } else if (ch == closeToken) {
                depth--;
                if (depth == 0) {
                    var end = i;
                    return hx.substr(start, end - start);
                }
            }
            i++;
        }

        return null;
    }

    static function extractTypeSpecForParam(paramName: String, params: String): Null<String> {
        if (paramName == null || paramName.length == 0) return null;
        if (params == null || params.length == 0) return null;

        var searchStart = 0;
        while (searchStart < params.length) {
            var idx = params.indexOf(paramName, searchStart);
            if (idx == -1) return null;

            var beforeOk = idx == 0 || !isIdentPart(params.charCodeAt(idx - 1));
            var afterIdx = idx + paramName.length;
            var afterOk = afterIdx >= params.length || !isIdentPart(params.charCodeAt(afterIdx));

            if (beforeOk && afterOk) {
                var i = afterIdx;
                while (i < params.length && StringTools.isSpace(params, i)) i++;
                if (i < params.length && params.charAt(i) == ":") {
                    i++;
                    while (i < params.length && StringTools.isSpace(params, i)) i++;
                    var start = i;

                    var angleDepth = 0;
                    var parenDepth = 0;
                    var bracketDepth = 0;

                    while (i < params.length) {
                        var ch = params.charAt(i);
                        switch (ch) {
                            case "<":
                                angleDepth++;
                            case ">":
                                if (angleDepth > 0) angleDepth--;
                            case "(":
                                parenDepth++;
                            case ")":
                                if (parenDepth > 0) parenDepth--;
                            case "[":
                                bracketDepth++;
                            case "]":
                                if (bracketDepth > 0) bracketDepth--;
                            case "," | "=":
                                if (angleDepth == 0 && parenDepth == 0 && bracketDepth == 0) {
                                    var spec = params.substr(start, i - start).trim();
                                    return spec.length > 0 ? spec : null;
                                }
                            default:
                        }
                        i++;
                    }

                    var endSpec = params.substr(start).trim();
                    return endSpec.length > 0 ? endSpec : null;
                }
            }

            searchStart = idx + paramName.length;
        }

        return null;
    }

    static function lineNumberAtIndex(text: String, index: Int): Int {
        var lineNo = 1;
        var i = 0;
        var max = index < text.length ? index : text.length;
        while (i < max) {
            if (text.charAt(i) == "\n") lineNo++;
            i++;
        }
        return lineNo;
    }

    static function escapeRegExp(s: String): String {
        var escaped = "";
        for (i in 0...s.length) {
            var ch = s.charAt(i);
            escaped += switch (ch) {
                case "\\" | "^" | "$" | "." | "|" | "?" | "*" | "+" | "(" | ")" | "[" | "]" | "{" | "}":
                    "\\" + ch;
                default:
                    ch;
            }
        }
        return escaped;
    }

    static function extractAssignsFields(typeName: String, hx: String): Null<Map<String, String>> {
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

        return null;
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

            // Strip trailing inline comments (common in assigns typedefs).
            var commentIndex = line.indexOf("//");
            if (commentIndex != -1) {
                line = line.substr(0, commentIndex).trim();
                if (line.length == 0) continue;
            }

            if (line.startsWith(">")) {
                var rest = line.substr(1).trim();
                if (rest.endsWith(",")) rest = rest.substr(0, rest.length - 1).trim();
                if (rest.length > 0) baseTypes.push(rest);
                continue;
            }

            var name: String = null;
            var typeSpec: String = null;
            var reVar = ~/^var\s+\??([A-Za-z0-9_]+)\s*:\s*([^,;]+)\s*[,;]?$/;
            if (reVar.match(line)) {
                name = reVar.matched(1);
                typeSpec = reVar.matched(2).trim();
            } else {
                var rePlain = ~/^\??([A-Za-z0-9_]+)\s*:\s*([^,;]+)\s*[,;]?$/;
                if (rePlain.match(line)) {
                    name = rePlain.matched(1);
                    typeSpec = rePlain.matched(2).trim();
                }
            }
            if (name != null && typeSpec != null) {
                var kind = normalizeKind(typeSpec);
                out.set(name, kind);
                // HXX/HEEx assigns normalize camelCase to snake_case (e.g. className -> @class_name).
                var snake = toSnakeCase(name);
                if (snake != name && !out.exists(snake)) {
                    out.set(snake, kind);
                }
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

    static function toSnakeCase(name: String): String {
        var out = "";
        for (i in 0...name.length) {
            var ch = name.charAt(i);
            var isUpper = ch != ch.toLowerCase() && ch == ch.toUpperCase();
            if (isUpper) {
                if (i > 0 && out.length > 0 && out.charAt(out.length - 1) != "_") out += "_";
                out += ch.toLowerCase();
            } else {
                out += ch.toLowerCase();
            }
        }
        return out;
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
