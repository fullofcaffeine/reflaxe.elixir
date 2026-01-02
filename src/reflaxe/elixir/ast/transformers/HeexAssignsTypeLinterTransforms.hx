package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.NameUtils;
import phoenix.types.HXXComponentRegistry;

using StringTools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import reflaxe.elixir.macros.RepoDiscovery;
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
 *   5) Unknown / missing required component props for resolvable dot components (e.g., `<.card title="...">`)
 *   6) Unknown / missing required component slots and invalid slot entry attrs for resolvable dot components
 *      (e.g., `<:header ...>` inside `<.card>`)
 *
 * WHY
 * - HXX authoring must be fully type-checked like TSX. Since HEEx lives in strings until
 *   normalized to ~H, the core compiler can miss invalid usages. This linter bridges that
 *   gap by correlating template `@field` references with the Haxe-typed `assigns` typedef.
 * - Attribute typing reduces "stringly-typed" template bugs (especially for `phx-*` / boolean attrs)
 *   without requiring users to embed target HEEx/EEx syntax.
 * - When a project defines a hook registry (`@:phxHookNames`), `phx-hook="Name"` values are validated
 *   against that registry when statically known.
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
 *   5) When a dot component tag is encountered and its definition is discoverable via RepoDiscovery,
 *      validate:
 *      - prop names, required props (including inner content), and basic prop kinds
 *      - slot tags (`<:name>`) against declared slots on the component assigns type (`@:slot` / `Slot<T>`)
 *      - slot entry attributes against the slot entry props type (`Slot<T>`, where `T` is a typedef/anon-struct)
 *
 * EXAMPLES
 * Haxe (invalid):
 *   typedef Assigns = { sort_by: String }
 *   HXX.hxx('<div selected={@sort_by == 1}></div>')
 * Error:
 *   HEEx assigns type error: @sort_by is String but compared to Int literal
 *
 * LIMITATIONS (Intentional; keep false positives low)
 * - Phoenix core component tags are validated via a small allowlist (`<.form>`, `<.link>`); other
 *   dot components are validated only when an unambiguous `@:component` definition is discoverable.
 *   Unknown or ambiguous components are skipped.
 * - Component prop typing is shallow: only basic kinds are inferred (String/Int/Float/Bool). Complex expressions
 *   are treated as unknown.
 * - Module-qualified components (`<CoreComponents.button>`) are validated only when the module can be matched
 *   unambiguously to a discovered `@:component` class (by `@:native` or class name).
 * - Slot typing validates:
 *   - slot tags (`<:name>`) exist on the invoked component when the component definition is discoverable
 *   - required slots are present at the call site
 *   - slot tag attributes match the slot entry typedef (including required slot attributes)
 *   - `:let` bindings are validated for binding shape (variable/pattern)
 *   - `:let` bindings on component tags are type-checked when the component declares an
 *     `inner_block: Slot<..., LetType>` slot; field accesses on the bound var are linted.
 * - Hook name validation only runs when a hook registry is present. Dynamic hook expressions (e.g. `phx-hook={@hook}`)
 *   are not validated to keep false positives low.
 */
private typedef ComponentDefinition = {
    var moduleTypePath: String;
    var nativeModuleName: Null<String>;
    var functionName: String; // snake_case
    var props: Map<String, String>; // canonical prop key (snake_case) -> kind
    var required: Map<String, Bool>; // canonical prop key (snake_case) -> required?
    var slots: Map<String, ComponentSlotDefinition>; // slot name (snake_case) -> slot definition
};

private typedef ComponentSlotDefinition = {
    var required: Bool; // required slot at callsite
    var props: Map<String, String>; // canonical prop key (snake_case) -> kind
    var requiredProps: Map<String, Bool>; // canonical prop key (snake_case) -> required?
    var letBinding: Null<ComponentLetBindingDefinition>; // optional typing for :let binders inside slot content
};

private typedef ComponentLetBindingDefinition = {
    var props: Map<String, String>; // canonical prop key (snake_case) -> kind
    var required: Map<String, Bool>; // canonical prop key (snake_case) -> required?
};

private typedef HeexLetBindingScope = {
    var varName: String; // bound variable name (e.g., `row`)
    var props: Map<String, String>; // allowed fields on the bound value (snake_case)
    var contextTag: String; // e.g., "<:col>"
};

class HeexAssignsTypeLinterTransforms {
    static var componentFunctionIndex: Null<Map<String, Array<ComponentDefinition>>> = null;
    static var componentDefinitionCache: Map<String, Null<ComponentDefinition>> = new Map();
    #if macro
    static var phoenixCoreComponentDefinitionCache: Map<String, Null<ComponentDefinition>> = new Map();
    #end
    static var fileContentCache: Map<String, Null<String>> = new Map();
    static var assignsFieldsCache: Map<String, Null<Map<String, String>>> = new Map();
    #if macro
    static var phxHookNameCache: Null<Map<String, Bool>> = null;
    #end

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
        ASTUtils.walk(ast, function(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EDef(_name, _args, _guards, _body) | EDefp(_name, _args, _guards, _body):
                    lintFunction(n, ctx);
                default:
            }
        });
        return ast;
    }

    static function getFileContentCached(path: String): Null<String> {
        if (path == null || path.length == 0) return null;
        if (fileContentCache.exists(path)) return fileContentCache.get(path);
        var content: Null<String> = null;
        try content = sys.io.File.getContent(path) catch (_:Dynamic) content = null;
        fileContentCache.set(path, content);
        return content;
    }

    static function getAssignsFieldsCached(assignsTypeName: String, fileContent: String, hxPath: String): Null<Map<String, String>> {
        if (assignsTypeName == null || assignsTypeName.length == 0) return null;
        if (fileContent == null) return null;
        var key = hxPath + "::" + assignsTypeName;
        if (assignsFieldsCache.exists(key)) return assignsFieldsCache.get(key);
        var fields = extractAssignsFields(assignsTypeName, fileContent);
        assignsFieldsCache.set(key, fields);
        return fields;
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

        // Resolve Haxe source path for this function
        var hxPath = (n.metadata != null && n.metadata.sourceFile != null) ? n.metadata.sourceFile : null;
        if (hxPath == null && body != null && body.metadata != null && body.metadata.sourceFile != null) {
            hxPath = body.metadata.sourceFile;
        }
#if debug_assigns_linter
        // DISABLED: trace('[HeexAssignsTypeLinter] ' + functionName + '/? at hxPath=' + hxPath);
#end
        if (hxPath == null) return; // No source; skip
        // Skip compiler/library/internal files to avoid scanning whole libs
        var hxPathNorm = StringTools.replace(hxPath, "\\", "/");
        var hxPathMatch = hxPathNorm.startsWith("/") ? hxPathNorm : ("/" + hxPathNorm);
        if (hxPathMatch.indexOf("/reflaxe/elixir/") != -1 || hxPathMatch.indexOf("/vendor/") != -1 || hxPathMatch.indexOf("/std/") != -1) {
            return;
        }

        // Fail-fast: skip linter if this function body contains neither ~H sigils nor EFragment nodes.
        // This check can be expensive, so do it only after ensuring we're in project sources.
        if (!containsHeexOrFragments(body)) {
            return;
        }

        var fileContent = getFileContentCached(hxPath);
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
        var fields: Null<Map<String, String>> = (assignsTypeBase != null) ? getAssignsFieldsCached(assignsTypeBase, fileContent, hxPath) : null;
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
        ASTUtils.walk(node, function(x: ElixirAST): Void {
            if (found == null && x.metadata != null && x.metadata.sourceFile != null) found = x.metadata.sourceFile;
        });
        return found;
    }

    static function collectHeexContents(node: ElixirAST, out: Array<{content:String, pos:haxe.macro.Expr.Position}>): Void {
        ASTUtils.walk(node, function(x: ElixirAST): Void {
            switch (x.def) {
                case ESigil(type, content, _mods) if (type == "H"):
                    out.push({ content: content, pos: x.pos });
                default:
            }
        });
    }

    static function findMinSourceLine(node: ElixirAST): Null<Int> {
        var minLine: Null<Int> = null;
        ASTUtils.walk(node, function(x: ElixirAST): Void {
            if (x.metadata != null && x.metadata.sourceLine != null) {
                if (minLine == null || x.metadata.sourceLine < minLine) minLine = x.metadata.sourceLine;
            }
        });
        return minLine;
    }

    static function containsHeexOrFragments(node: ElixirAST): Bool {
        if (node == null || node.def == null) return false;
        var found = false;

        function scan(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case ESigil(type, _content, _mods) if (type == "H"):
                    found = true;
                case EFragment(_tag, _attrs, _children):
                    found = true;
                default:
                    ElixirASTTransformer.iterateAST(x, scan);
            }
        }

        scan(node);
        return found;
    }

    // Validate attributes from parsed fragment metadata (if annotator ran)
    static function validateHeexFragments(node: ElixirAST, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, enableAssignsChecks: Bool): Void {
        ASTUtils.walk(node, function(x: ElixirAST): Void {
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
        });
    }

    // Validate attributes using native EFragment nodes present in AST
    static function validateNativeEFragments(node: ElixirAST, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, enableAssignsChecks: Bool): Void {
        ASTUtils.walk(node, function(x: ElixirAST): Void {
            switch (x.def) {
                case EFragment(tag, attributes, children):
                    // Validate each fragment exactly once; traversal is handled by the walker.
                    validateFragment(tag, attributes, children, null, fields, typeName, ctx, x.pos, enableAssignsChecks, []);
                default:
            }
        });
    }

    // ---------------------------------------------------------------------
    // Typed HEEx AST validation (preferred path)
    // ---------------------------------------------------------------------
    static function validateHeexTypedAST(nodes: Array<ElixirAST>, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position, enableAssignsChecks: Bool): Void {
        for (n in nodes) {
            if (n == null || n.def == null) continue;
            validateNode(n, null, fields, typeName, ctx, pos, enableAssignsChecks, []);
        }
    }

    static function validateNode(n: ElixirAST, parentTag: Null<String>, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position, enableAssignsChecks: Bool, letScopes: Array<HeexLetBindingScope>): Void {
        switch (n.def) {
            case EFragment(tag, attributes, children):
                validateSlotTag(tag, parentTag, ctx, pos);

                var nextLetScopes = extendLetScopesForNode(tag, attributes, parentTag, letScopes);

                validateFragment(tag, attributes, children, parentTag, fields, typeName, ctx, pos, enableAssignsChecks, nextLetScopes);

                for (c in children) {
                    if (c == null || c.def == null) continue;
                    validateNode(c, tag, fields, typeName, ctx, pos, enableAssignsChecks, nextLetScopes);
                }
            case ERaw(code):
                validateRawForLetScopes(code, letScopes, ctx, pos);
            default:
        }
    }

    static function validateFragment(
        tag: String,
        attributes: Array<EAttribute>,
        children: Array<ElixirAST>,
        parentTag: Null<String>,
        fields: Map<String,String>,
        typeName: String,
        ctx: Null<reflaxe.elixir.CompilationContext>,
        pos: haxe.macro.Expr.Position,
        enableAssignsChecks: Bool,
        letScopes: Array<HeexLetBindingScope>
    ): Void {
        for (attr in attributes) {
            validateAttribute(tag, parentTag, attr, fields, typeName, ctx, pos, enableAssignsChecks, letScopes);
        }
        validateSlotInvocation(tag, parentTag, attributes, children, fields, ctx, pos);
        // Component-level checks (requires full attribute set + children)
        validateComponentInvocation(tag, attributes, children, fields, ctx, pos);
    }

    static function validateAttribute(tag: String, parentTag: Null<String>, attr: EAttribute, fields: Map<String,String>, typeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position, enableAssignsChecks: Bool, letScopes: Array<HeexLetBindingScope>): Void {
        if (attr != null && attr.name == ":let") {
            validateLetDirective(tag, attr.value, ctx, pos);
            // NOTE: :let is a binding pattern, not an expression; do not run assigns lints on it.
            return;
        }

        if (isSlotTag(tag)) {
            validateSlotAttributeName(tag, parentTag, attr.name, ctx, pos);
            validateSlotPropValueKind(tag, parentTag, attr, fields, ctx, pos);
        } else {
            // 1) Name validation (only for known HTML elements; allow HEEx directive attrs)
            validateAttributeName(tag, attr.name, ctx, pos);

            // 2) Obvious kind validation for select attributes (bool-ish attrs, phx-hook, etc.)
            validateAttributeValueKind(attr.name, attr.value, fields, ctx, pos);

            // 2b) Component prop kind validation (when the component + prop is resolvable)
            validateComponentPropValueKind(tag, attr, fields, ctx, pos);
        }

        // 3) Assigns field usage within `{ ... }` attribute expressions
        validateExprForAssigns(attr.value, fields, typeName, ctx, pos, enableAssignsChecks);

        // 4) Slot :let binder field usage within attribute expressions (when a typed let scope is present)
        validateExprForLetScopes(attr.value, letScopes, ctx, pos);
    }

    static var allowedHtmlAttributeCache: Map<String, Map<String, Bool>> = new Map();
    static var globalHtmlAttributeCache: Null<Map<String, Bool>> = null;

    static function validateSlotTag(tag: String, parentTag: Null<String>, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        if (tag == null || tag.length == 0) return;
        if (tag.charAt(0) != ":") return;

        var slotName = tag.length > 1 ? tag.substr(1) : "";
        if (!isValidHeexIdentifier(slotName)) {
            error(ctx, 'HEEx slot tag error: <' + tag + '> is not a valid slot tag name (expected <:name>)', pos);
        }

        if (parentTag == null || !isHeexComponentTag(parentTag)) {
            var parentDisplay = parentTag != null ? ('<' + parentTag + '>') : "the template root";
            error(ctx, 'HEEx slot tag error: <' + tag + '> must be a direct child of a component tag (e.g. <.card>), not under ' + parentDisplay, pos);
            return;
        }

        // If the parent component definition is discoverable, validate the slot exists.
        var def = resolveComponentDefinition(parentTag);
        if (def != null) {
            var slots = def.slots;
            if (slots == null || !slots.exists(slotName)) {
                error(ctx, 'HEEx slot tag error: <' + parentTag + '> does not define slot <:' + slotName + '>', pos);
            }
        }
    }

    static inline function isSlotTag(tag: String): Bool {
        return tag != null && tag.length > 0 && tag.charAt(0) == ":";
    }

    static function validateLetDirective(tag: String, value: ElixirAST, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        if (tag == null || tag.length == 0) return;
        if (!isHeexComponentTag(tag) && !(tag.charAt(0) == ":")) {
            error(ctx, 'HEEx directive error: ":let" is only valid on component tags and slot tags, not on <' + tag + '>', pos);
        }

        if (value == null) {
            error(ctx, 'HEEx :let error: expected :let={var}, but got null', pos);
        }

        switch (value.def) {
            case EVar(name):
                if (!isValidElixirVarName(name)) {
                    error(ctx, 'HEEx :let error: expected an Elixir variable name, but got "' + name + '"', pos);
                }
            case ERaw(pattern):
                validateLetPatternString(pattern, ctx, pos);
            case EAssign(_):
                error(ctx, 'HEEx :let error: cannot bind to @assigns; expected :let={var}', pos);
            case EBoolean(_):
                error(ctx, 'HEEx :let error: expected :let={var}, but got a boolean attribute', pos);
            default:
                error(ctx, 'HEEx :let error: expected :let={var}, but got an invalid value', pos);
        }
    }

    static function resolveSlotDefinition(slotTag: String, parentTag: Null<String>): Null<ComponentSlotDefinition> {
        if (!isSlotTag(slotTag)) return null;
        if (parentTag == null) return null;

        var def = resolveComponentDefinition(parentTag);
        if (def == null || def.slots == null) return null;

        var slotName = slotTag.length > 1 ? slotTag.substr(1) : "";
        if (slotName.length == 0) return null;
        return def.slots.get(slotName);
    }

    static function validateSlotInvocation(
        slotTag: String,
        parentTag: Null<String>,
        attributes: Array<EAttribute>,
        children: Array<ElixirAST>,
        fields: Map<String,String>,
        ctx: Null<reflaxe.elixir.CompilationContext>,
        pos: haxe.macro.Expr.Position
    ): Void {
        if (!isSlotTag(slotTag)) return;
        if (parentTag == null || !isHeexComponentTag(parentTag)) return;

        var slotDef = resolveSlotDefinition(slotTag, parentTag);
        if (slotDef == null) return;

        var present = new Map<String, Bool>();
        for (attr in attributes) {
            if (attr == null || attr.name == null || attr.name.length == 0) continue;
            if (attr.name.startsWith(":")) continue;
            var key = componentAssignKeyFromAttributeName(attr.name);
            present.set(key, true);
        }

        var hasInnerContent = present.exists("inner_content") || hasMeaningfulChildren(children);
        for (k in slotDef.requiredProps.keys()) {
            if (k == "inner_content") {
                if (!hasInnerContent) {
                    error(ctx, 'HEEx slot prop error: <' + slotTag + '> is missing required inner content', pos);
                }
                continue;
            }
            if (!present.exists(k)) {
                error(ctx, 'HEEx slot prop error: <' + slotTag + '> is missing required attribute "' + k + '"', pos);
            }
        }
    }

    static function validateSlotAttributeName(slotTag: String, parentTag: Null<String>, attributeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        if (!isSlotTag(slotTag)) return;
        if (attributeName == null || attributeName.length == 0) return;
        if (attributeName.startsWith(":")) return;

        var slotDef = resolveSlotDefinition(slotTag, parentTag);
        if (slotDef == null) return;

        var key = componentAssignKeyFromAttributeName(attributeName);
        if (slotDef.props.exists(key)) return;

        error(ctx, 'HEEx slot prop error: <' + slotTag + '> does not allow attribute "' + attributeName + '"', pos);
    }

    static function validateSlotPropValueKind(
        slotTag: String,
        parentTag: Null<String>,
        attr: EAttribute,
        fields: Map<String,String>,
        ctx: Null<reflaxe.elixir.CompilationContext>,
        pos: haxe.macro.Expr.Position
    ): Void {
        if (!isSlotTag(slotTag)) return;
        if (attr == null || attr.name == null || attr.name.length == 0) return;
        if (attr.name.startsWith(":")) return;

        var slotDef = resolveSlotDefinition(slotTag, parentTag);
        if (slotDef == null) return;

        var key = componentAssignKeyFromAttributeName(attr.name);
        if (!slotDef.props.exists(key)) return;

        var expected = slotDef.props.get(key);
        if (expected == null || expected == "unknown") return;

        var actual = inferHeexExprKind(attr.value, fields);
        if (!attributeKindsCompatible(expected, actual)) {
            error(ctx, 'HEEx slot prop type error: <' + slotTag + '> "' + key + '" expects ' + expected + ' but got ' + actual, pos);
        }
    }

    static function validateLetPatternString(pattern: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        var s = pattern != null ? pattern.trim() : "";
        if (s.length == 0) {
            error(ctx, 'HEEx :let error: expected a binding pattern, but got an empty pattern', pos);
        }
        if (s.indexOf("@") != -1) {
            error(ctx, 'HEEx :let error: binding patterns cannot reference @assigns', pos);
        }

        var bound = collectElixirPatternVars(s);
        if (bound.length == 0) {
            error(ctx, 'HEEx :let error: binding pattern does not bind any variables', pos);
        }
    }

    static function collectElixirPatternVars(pattern: String): Array<String> {
        var found = new Map<String, Bool>();
        if (pattern == null) return [];

        var i = 0;
        var inSingle = false;
        var inDouble = false;

        while (i < pattern.length) {
            var ch = pattern.charCodeAt(i);

            if (!inDouble && ch == "'".code) { inSingle = !inSingle; i++; continue; }
            if (!inSingle && ch == "\"".code) { inDouble = !inDouble; i++; continue; }
            if (inSingle || inDouble) { i++; continue; }

            // Skip atoms like :ok
            if (ch == ":".code && i + 1 < pattern.length && isHeexIdentStart(pattern.charCodeAt(i + 1))) {
                i += 2;
                while (i < pattern.length && isHeexIdentChar(pattern.charCodeAt(i))) i++;
                continue;
            }

            // Recognize pinned variables (^var) by skipping '^' and letting ident parse handle it.
            if (ch == "^".code) { i++; continue; }

            if (isElixirVarStart(ch)) {
                var start = i;
                i++;
                while (i < pattern.length && isHeexIdentChar(pattern.charCodeAt(i))) i++;
                var name = pattern.substr(start, i - start);

                // If immediately followed by ':', it's likely a map key (id:) not a variable binder.
                if (i < pattern.length && pattern.charCodeAt(i) == ":".code) continue;

                if (isValidElixirVarName(name)) found.set(name, true);
                continue;
            }

            i++;
        }

        return [for (k in found.keys()) k];
    }

    static function extendLetScopesForNode(tag: String, attributes: Array<EAttribute>, parentTag: Null<String>, letScopes: Array<HeexLetBindingScope>): Array<HeexLetBindingScope> {
        if (attributes == null || attributes.length == 0) return letScopes;
        if (letScopes == null) letScopes = [];

        var letAttr: Null<EAttribute> = null;
        for (a in attributes) {
            if (a != null && a.name == ":let") { letAttr = a; break; }
        }
        if (letAttr == null) return letScopes;

        var letDef: Null<ComponentLetBindingDefinition> = null;
        if (isSlotTag(tag)) {
            letDef = resolveSlotLetBindingDefinition(tag, parentTag);
        } else if (isHeexComponentTag(tag)) {
            letDef = resolveComponentLetBindingDefinition(tag);
        } else {
            return letScopes;
        }
        if (letDef == null || letDef.props == null || !letDef.props.keys().hasNext()) return letScopes;

        var boundVars = extractLetBoundVariables(letAttr.value);
        if (boundVars == null || boundVars.length != 1) return letScopes;
        var varName = boundVars[0];
        if (!isValidElixirVarName(varName)) return letScopes;

        var next = letScopes.copy();
        next.push({
            varName: varName,
            props: letDef.props,
            contextTag: '<' + tag + '>'
        });
        return next;
    }

    static function resolveComponentLetBindingDefinition(componentTag: String): Null<ComponentLetBindingDefinition> {
        var def = resolveComponentDefinition(componentTag);
        if (def == null || def.slots == null) return null;

        var slotDef = def.slots.get("inner_block");
        if (slotDef == null) return null;
        return slotDef.letBinding;
    }

    static function resolveSlotLetBindingDefinition(slotTag: String, parentTag: Null<String>): Null<ComponentLetBindingDefinition> {
        var slotDef = resolveSlotDefinition(slotTag, parentTag);
        if (slotDef == null) return null;
        return slotDef.letBinding;
    }

    static function extractLetBoundVariables(value: ElixirAST): Array<String> {
        if (value == null || value.def == null) return [];
        return switch (value.def) {
            case EVar(name):
                name != null && name.length > 0 ? [name] : [];
            case ERaw(pattern):
                collectElixirPatternVars(pattern);
            default:
                [];
        };
    }

    static function validateExprForLetScopes(expr: ElixirAST, letScopes: Array<HeexLetBindingScope>, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        if (expr == null || expr.def == null) return;
        if (letScopes == null || letScopes.length == 0) return;

        function walk(e: ElixirAST): Void {
            if (e == null || e.def == null) return;
            switch (e.def) {
                case EField({def: EVar(varName)}, fieldName):
                    validateLetFieldAccess(varName, fieldName, letScopes, ctx, pos);
                case ERaw(code):
                    validateRawForLetScopes(code, letScopes, ctx, pos);
                default:
                    ElixirASTTransformer.iterateAST(e, walk);
            }
        }

        walk(expr);
    }

    static function validateRawForLetScopes(code: String, letScopes: Array<HeexLetBindingScope>, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        if (code == null) return;
        if (letScopes == null || letScopes.length == 0) return;

        var s = code.trim();
        if (s.startsWith("=")) s = s.substr(1);

        for (scope in letScopes) {
            if (scope == null || scope.varName == null || scope.varName.length == 0) continue;
            if (scope.props == null) continue;

            var fields = collectDotFieldAccesses(s, scope.varName);
            for (fieldName in fields) {
                validateLetFieldAccess(scope.varName, fieldName, letScopes, ctx, pos);
            }
        }
    }

    static function validateLetFieldAccess(varName: String, fieldName: String, letScopes: Array<HeexLetBindingScope>, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        if (varName == null || fieldName == null) return;
        var scope = findLetScope(varName, letScopes);
        if (scope == null || scope.props == null) return;

        var key = NameUtils.toSnakeCase(fieldName);
        if (scope.props.exists(key)) return;

        error(ctx, 'HEEx :let type error: ' + scope.contextTag + ' binding "' + scope.varName + '" does not define field "' + key + '"', pos);
    }

    static function findLetScope(varName: String, letScopes: Array<HeexLetBindingScope>): Null<HeexLetBindingScope> {
        if (varName == null || letScopes == null) return null;
        // Prefer innermost scope (last wins).
        var i = letScopes.length - 1;
        while (i >= 0) {
            var scope = letScopes[i];
            if (scope != null && scope.varName == varName) return scope;
            i--;
        }
        return null;
    }

    static function collectDotFieldAccesses(code: String, varName: String): Array<String> {
        if (code == null || varName == null || varName.length == 0) return [];
        var found = new Map<String, Bool>();

        var i = 0;
        while (i < code.length) {
            var idx = code.indexOf(varName, i);
            if (idx == -1) break;

            var prevIdx = idx - 1;
            if (prevIdx >= 0 && isHeexIdentChar(code.charCodeAt(prevIdx))) {
                i = idx + varName.length;
                continue;
            }

            var dotIdx = idx + varName.length;
            if (dotIdx >= code.length || code.charCodeAt(dotIdx) != ".".code) {
                i = idx + varName.length;
                continue;
            }

            var fieldStart = dotIdx + 1;
            if (fieldStart >= code.length || !isHeexIdentStart(code.charCodeAt(fieldStart))) {
                i = fieldStart;
                continue;
            }

            var j = fieldStart + 1;
            while (j < code.length && isHeexIdentChar(code.charCodeAt(j))) j++;
            var fieldName = code.substr(fieldStart, j - fieldStart);
            if (fieldName != null && fieldName.length > 0) found.set(fieldName, true);
            i = j;
        }

        return [for (k in found.keys()) k];
    }

    static function isHeexComponentTag(tag: String): Bool {
        if (tag == null || tag.length == 0) return false;
        return tag.charAt(0) == "." || isLikelyModuleComponentTag(tag);
    }

    static function isValidHeexIdentifier(name: String): Bool {
        if (name == null || name.length == 0) return false;
        if (!isHeexIdentStart(name.charCodeAt(0))) return false;
        for (i in 1...name.length) if (!isHeexIdentChar(name.charCodeAt(i))) return false;
        return true;
    }

    static inline function isHeexIdentStart(code: Int): Bool {
        return (code >= "A".code && code <= "Z".code)
            || (code >= "a".code && code <= "z".code)
            || code == "_".code;
    }

    static inline function isHeexIdentChar(code: Int): Bool {
        return isHeexIdentStart(code) || (code >= "0".code && code <= "9".code);
    }

    static inline function isElixirVarStart(code: Int): Bool {
        return code == "_".code || (code >= "a".code && code <= "z".code);
    }

    static function isValidElixirVarName(name: String): Bool {
        if (name == null || name.length == 0) return false;
        if (!isElixirVarStart(name.charCodeAt(0))) return false;
        for (i in 1...name.length) if (!isHeexIdentChar(name.charCodeAt(i))) return false;
        return true;
    }

    static function validateAttributeName(tag: String, attributeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        if (attributeName == null || attributeName.length == 0) return;
        // HEEx directive attrs like :if/:for/:let are valid on any tag.
        if (attributeName.startsWith(":")) return;

        if (tag != null && tag.length > 0) {
            var first = tag.charAt(0);
            if (first == ".") {
                // Phoenix core component allowlist first; otherwise attempt user component prop typing.
                var allowedCore = getAllowedPhoenixCoreComponentAttributes(tag);
                if (allowedCore != null) {
                    validatePhoenixCoreComponentAttributeName(tag, attributeName, ctx, pos);
                } else {
                    validateUserComponentAttributeName(tag, attributeName, ctx, pos);
                }
                return;
            } else if (isLikelyModuleComponentTag(tag)) {
                validateUserComponentAttributeName(tag, attributeName, ctx, pos);
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

    static function validateUserComponentAttributeName(componentTag: String, attributeName: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        var def = resolveComponentDefinition(componentTag);
        if (def == null) return; // Unknown/ambiguous component; skip to avoid false positives.

        var canonical = normalizeHeexAttributeName(attributeName);
        var htmlName = HXXComponentRegistry.toHtmlAttribute(canonical);
        if (isWildcardHeexAttribute(canonical) || isWildcardHeexAttribute(htmlName)) return;

        // Allow global HTML attributes on component tags (Phoenix pattern: pass-through globals/rest attrs).
        var globals = getGlobalHtmlAttributes();
        if (globals.exists(attributeName) || globals.exists(canonical) || (htmlName != null && globals.exists(htmlName))) return;

        var key = componentAssignKeyFromAttributeName(attributeName);
        if (def.props.exists(key)) return;

        error(ctx, 'HEEx component prop error: <' + componentTag + '> does not allow attribute "' + attributeName + '"', pos);
    }

    static function componentAssignKeyFromAttributeName(attributeName: String): String {
        var html = HXXComponentRegistry.toHtmlAttribute(attributeName);
        if (html == null) return attributeName;
        return html.split("-").join("_");
    }

    static function validateComponentInvocation(
        tag: String,
        attributes: Array<EAttribute>,
        children: Array<ElixirAST>,
        fields: Map<String,String>,
        ctx: Null<reflaxe.elixir.CompilationContext>,
        pos: haxe.macro.Expr.Position
    ): Void {
        if (tag == null || tag.length == 0) return;
        if (tag.charAt(0) != "." && !isLikelyModuleComponentTag(tag)) return;

        var def = resolveComponentDefinition(tag);
        if (def == null) {
            validatePhoenixCoreComponentInvocation(tag, attributes, children, ctx, pos);
            validateStrictComponentResolution(tag, ctx, pos);
            return;
        }

        var present = new Map<String, Bool>();
        for (attr in attributes) {
            if (attr == null || attr.name == null || attr.name.length == 0) continue;
            if (attr.name.startsWith(":")) continue; // directives don't satisfy component assigns
            var key = componentAssignKeyFromAttributeName(attr.name);
            present.set(key, true);
        }

        // Treat inner_content as satisfied by non-whitespace children.
        var hasInnerContent = present.exists("inner_content") || hasMeaningfulChildren(children);

        for (k in def.required.keys()) {
            if (k == "inner_content") {
                if (!hasInnerContent) {
                    error(ctx, 'HEEx component prop error: <' + tag + '> is missing required inner content', pos);
                }
                continue;
            }
            if (!present.exists(k)) {
                error(ctx, 'HEEx component prop error: <' + tag + '> is missing required attribute "' + k + '"', pos);
            }
        }

        // Required slot presence checks (when slot definitions are discoverable).
        if (def.slots != null) {
            var slotIter = def.slots.keys();
            if (slotIter.hasNext()) {
                var presentSlots = new Map<String, Bool>();
                for (c in children) {
                    if (c == null || c.def == null) continue;
                    switch (c.def) {
                        case EFragment(childTag, _, _) if (isSlotTag(childTag)):
                            presentSlots.set(childTag.substr(1), true);
                        default:
                    }
                }

                // Default slot: treat non-slot-tag children as satisfying <:inner_block>.
                if (!presentSlots.exists("inner_block") && hasMeaningfulInnerBlockChildren(children)) {
                    presentSlots.set("inner_block", true);
                }

                for (slotName in def.slots.keys()) {
                    var slotDef = def.slots.get(slotName);
                    if (slotDef != null && slotDef.required && !presentSlots.exists(slotName)) {
                        error(ctx, 'HEEx slot error: <' + tag + '> is missing required slot <:' + slotName + '>', pos);
                    }
                }
            }
        }
    }

    static function validatePhoenixCoreComponentInvocation(
        tag: String,
        attributes: Array<EAttribute>,
        children: Array<ElixirAST>,
        ctx: Null<reflaxe.elixir.CompilationContext>,
        pos: haxe.macro.Expr.Position
    ): Void {
        if (tag == null || tag.length == 0) return;
        if (tag.charAt(0) != ".") return;

        var present = new Map<String, Bool>();
        for (attr in attributes) {
            if (attr == null || attr.name == null || attr.name.length == 0) continue;
            if (attr.name.startsWith(":")) continue;
            var key = componentAssignKeyFromAttributeName(attr.name);
            present.set(key, true);
        }

        switch (tag) {
            case ".live_component":
                if (!present.exists("module")) {
                    error(ctx, 'HEEx component prop error: <.live_component> is missing required attribute \"module\"', pos);
                }
                if (!present.exists("id")) {
                    error(ctx, 'HEEx component prop error: <.live_component> is missing required attribute \"id\"', pos);
                }
            case ".form":
                if (getAllowedPhoenixCoreComponentAttributes(tag) == null) return;
                if (!present.exists("for")) {
                    error(ctx, 'HEEx component prop error: <.form> is missing required attribute \"for\"', pos);
                }
            default:
                if (getAllowedPhoenixCoreComponentAttributes(tag) == null) return;
        }
    }

    static function validateStrictComponentResolution(tag: String, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        if (!strictComponentResolutionEnabled()) return;
        if (tag == null || tag.length == 0) return;

        // Phoenix core components are validated via the allowlist (and do not require RepoDiscovery).
        if (isKnownPhoenixCoreComponentTag(tag)) return;

        var reason = explainComponentResolutionFailure(tag);
        error(ctx, 'HEEx component error: <' + tag + '> could not be resolved' + reason + ' (disable strict mode or add a discoverable @:component definition)', pos);
    }

    static function strictComponentResolutionEnabled(): Bool {
        #if macro
        return Context.defined("hxx_strict_components");
        #else
        return false;
        #end
    }

    static function isKnownPhoenixCoreComponentTag(tag: String): Bool {
        if (tag == ".live_component") return true;
        return getAllowedPhoenixCoreComponentAttributes(tag) != null;
    }

    static function explainComponentResolutionFailure(componentTag: String): String {
        #if macro
        if (componentTag == null || componentTag.length == 0) return "";

        if (componentFunctionIndex == null) {
            buildComponentFunctionIndex();
        }
        if (componentFunctionIndex == null) return "";

        if (componentTag.charAt(0) == ".") {
            var fn = componentTag.substr(1);
            var candidates = componentFunctionIndex.get(fn);
            if (candidates == null || candidates.length == 0) return ' (no @:component function named "' + fn + '" was discovered)';
            if (candidates.length > 1) return ' (ambiguous: ' + candidates.length + ' @:component functions named "' + fn + '" exist)';
            return "";
        }

        if (isLikelyModuleComponentTag(componentTag)) {
            var lastDot = componentTag.lastIndexOf(".");
            if (lastDot > 0 && lastDot < componentTag.length - 1) {
                var modulePart = componentTag.substr(0, lastDot);
                var fnPart = componentTag.substr(lastDot + 1);
                var fn = NameUtils.toSnakeCase(fnPart);

                var candidates = componentFunctionIndex.get(fn);
                if (candidates == null || candidates.length == 0) {
                    return ' (no @:component function named "' + fn + '" was discovered)';
                }

                var matches = 0;
                for (c in candidates) if (componentModuleMatches(c, modulePart)) matches++;

                if (matches == 0) return ' (no @:component module matched "' + modulePart + '" for function "' + fn + '")';
                if (matches > 1) return ' (ambiguous: ' + matches + ' @:component modules matched "' + modulePart + '" for function "' + fn + '")';
            }
        }

        return "";
        #else
        return "";
        #end
    }

    static function hasMeaningfulChildren(children: Array<ElixirAST>): Bool {
        if (children == null || children.length == 0) return false;
        for (c in children) {
            if (c == null) continue;
            switch (c.def) {
                case EString(s):
                    if (s != null && s.trim() != "") return true;
                case EFragment(_, _, _):
                    return true;
                default:
                    return true;
            }
        }
        return false;
    }

    static function hasMeaningfulInnerBlockChildren(children: Array<ElixirAST>): Bool {
        if (children == null || children.length == 0) return false;
        for (c in children) {
            if (c == null || c.def == null) continue;
            switch (c.def) {
                case EString(s):
                    if (s != null && s.trim() != "") return true;
                case EFragment(tag, _, _) if (isSlotTag(tag)):
                    // Slot entries do not count as default inner_block content.
                default:
                    return true;
            }
        }
        return false;
    }

    static function validateComponentPropValueKind(
        tag: String,
        attr: EAttribute,
        fields: Map<String,String>,
        ctx: Null<reflaxe.elixir.CompilationContext>,
        pos: haxe.macro.Expr.Position
    ): Void {
        if (tag == null || tag.length == 0) return;
        if (attr == null || attr.name == null || attr.name.length == 0) return;
        if (attr.name.startsWith(":")) return;
        if (tag.charAt(0) != "." && !isLikelyModuleComponentTag(tag)) return;

        var def = resolveComponentDefinition(tag);
        if (def == null) return;

        var key = componentAssignKeyFromAttributeName(attr.name);
        if (!def.props.exists(key)) return;

        var expected = def.props.get(key);
        if (expected == null || expected == "unknown") return;

        var actual = inferHeexExprKind(attr.value, fields);
        if (!attributeKindsCompatible(expected, actual)) {
            error(ctx, 'HEEx component prop type error: <' + tag + '> "' + key + '" expects ' + expected + ' but got ' + actual, pos);
        }
    }

    static function resolveComponentDefinition(componentTag: String): Null<ComponentDefinition> {
        if (componentTag == null || componentTag.length == 0) return null;
        if (componentDefinitionCache.exists(componentTag)) return componentDefinitionCache.get(componentTag);

        if (componentFunctionIndex == null) {
            #if macro
            buildComponentFunctionIndex();
            #else
            componentDefinitionCache.set(componentTag, null);
            return null;
            #end
        }

        var resolved: Null<ComponentDefinition> = null;
        if (componentTag.charAt(0) == ".") {
            var fn = componentTag.substr(1);
            var candidates = componentFunctionIndex.get(fn);
            if (candidates != null && candidates.length == 1) {
                resolved = candidates[0];
            }
        } else if (isLikelyModuleComponentTag(componentTag)) {
            var lastDot = componentTag.lastIndexOf(".");
            if (lastDot > 0 && lastDot < componentTag.length - 1) {
                var modulePart = componentTag.substr(0, lastDot);
                var fnPart = componentTag.substr(lastDot + 1);
                var fn = NameUtils.toSnakeCase(fnPart);
                var candidates = componentFunctionIndex.get(fn);
                if (candidates != null) {
                    var matches: Array<ComponentDefinition> = [];
                    for (c in candidates) if (componentModuleMatches(c, modulePart)) matches.push(c);
                    if (matches.length == 1) {
                        resolved = matches[0];
                    }
                }
            }
        }

        #if macro
        if (resolved == null) {
            resolved = resolvePhoenixCoreComponentDefinition(componentTag);
        }
        #end

        componentDefinitionCache.set(componentTag, resolved);
        return resolved;
    }

    #if macro
    static function resolvePhoenixCoreComponentDefinition(componentTag: String): Null<ComponentDefinition> {
        if (componentTag == null || componentTag.length == 0) return null;
        if (componentTag.charAt(0) != ".") return null;

        if (phoenixCoreComponentDefinitionCache.exists(componentTag)) {
            return phoenixCoreComponentDefinitionCache.get(componentTag);
        }

        var resolved: Null<ComponentDefinition> = null;
        resolved = switch (componentTag) {
            case ".form":
                buildPhoenixCoreFormComponentDefinition();
            case ".inputs_for":
                buildPhoenixCoreInputsForComponentDefinition();
            default:
                null;
        };

        phoenixCoreComponentDefinitionCache.set(componentTag, resolved);
        return resolved;
    }

    static function buildPhoenixCoreFormComponentDefinition(): Null<ComponentDefinition> {
        var letBinding: Null<ComponentLetBindingDefinition> = null;
        var formAssignsType = resolvePhoenixCoreFormLetType();
        if (formAssignsType != null) {
            var letInfo = letBindingPropsFromType(formAssignsType);
            if (letInfo != null && letInfo.props != null && letInfo.props.keys().hasNext()) {
                letBinding = { props: letInfo.props, required: letInfo.required };
            }
        }

        var slots = new Map<String, ComponentSlotDefinition>();
        slots.set("inner_block", {
            required: true,
            props: new Map(),
            requiredProps: new Map(),
            letBinding: letBinding
        });

        var required = new Map<String, Bool>();
        required.set("for", true);

        return {
            moduleTypePath: null,
            nativeModuleName: "Phoenix.Component",
            functionName: "form",
            props: new Map(),
            required: required,
            slots: slots
        };
    }

    static function buildPhoenixCoreInputsForComponentDefinition(): Null<ComponentDefinition> {
        var letBinding: Null<ComponentLetBindingDefinition> = null;
        var formAssignsType = resolvePhoenixCoreFormLetType();
        if (formAssignsType != null) {
            var letInfo = letBindingPropsFromType(formAssignsType);
            if (letInfo != null && letInfo.props != null && letInfo.props.keys().hasNext()) {
                letBinding = { props: letInfo.props, required: letInfo.required };
            }
        }

        var slots = new Map<String, ComponentSlotDefinition>();
        slots.set("inner_block", {
            required: true,
            props: new Map(),
            requiredProps: new Map(),
            letBinding: letBinding
        });

        var props = new Map<String, String>();
        props.set("field", "unknown");
        props.set("id", "string");
        props.set("as", "string");
        props.set("default", "unknown");
        props.set("append", "unknown");
        props.set("prepend", "unknown");
        props.set("skip_hidden", "bool");
        props.set("options", "unknown");

        var required = new Map<String, Bool>();
        required.set("field", true);

        return {
            moduleTypePath: null,
            nativeModuleName: "Phoenix.Component",
            functionName: "inputs_for",
            props: props,
            required: required,
            slots: slots
        };
    }

    static function resolvePhoenixCoreFormLetType(): Null<haxe.macro.Type> {
        var formType: Null<haxe.macro.Type> = null;
        try formType = Context.getType("phoenix.Phoenix.Form") catch (_:Dynamic) formType = null;
        if (formType == null) return null;

        var termType: Null<haxe.macro.Type> = null;
        try termType = Context.getType("elixir.types.Term") catch (_:Dynamic) termType = null;

        return switch (formType) {
            case TType(tdef, params):
                var typeArgs = (termType != null) ? [termType] : params;
                TypeTools.applyTypeParameters(tdef.get().type, tdef.get().params, typeArgs);
            default:
                formType;
        };
    }
    #end

    static function isLikelyModuleComponentTag(tag: String): Bool {
        if (tag == null || tag.length < 3) return false;
        if (tag.indexOf(".") == -1) return false;
        // Elixir module aliases are PascalCase; avoid validating lowercase HTML tags.
        var first = tag.charCodeAt(0);
        return first >= "A".code && first <= "Z".code;
    }

    static function componentModuleMatches(def: ComponentDefinition, modulePart: String): Bool {
        if (def == null || modulePart == null || modulePart.length == 0) return false;

        if (def.nativeModuleName != null) {
            if (def.nativeModuleName == modulePart) return true;
            var parts = def.nativeModuleName.split(".");
            var base = parts != null && parts.length > 0 ? parts[parts.length - 1] : null;
            if (base != null && base == modulePart) return true;
        }

        if (def.moduleTypePath != null) {
            if (def.moduleTypePath == modulePart) return true;
            var typeParts = def.moduleTypePath.split(".");
            var typeBase = typeParts != null && typeParts.length > 0 ? typeParts[typeParts.length - 1] : null;
            if (typeBase != null && typeBase == modulePart) return true;
        }

        return false;
    }

    #if macro
    static function buildComponentFunctionIndex(): Void {
        if (componentFunctionIndex != null) return;
        componentFunctionIndex = new Map<String, Array<ComponentDefinition>>();

        var discovered = RepoDiscovery.getDiscovered();
        if (discovered == null || discovered.length == 0) {
            RepoDiscovery.run();
            discovered = RepoDiscovery.getDiscovered();
        }

        if (discovered == null) return;

        for (typePath in discovered) {
            var t: haxe.macro.Type = null;
            try t = Context.getType(typePath) catch (_:Dynamic) t = null;
            if (t == null) continue;

            var cls: Null<haxe.macro.Type.ClassType> = null;
            switch (TypeTools.follow(t)) {
                case TInst(c, _):
                    cls = c.get();
                default:
            }
            if (cls == null || cls.meta == null) continue;

            if (!(cls.meta.has(":component") || cls.meta.has(":phoenix.components"))) continue;

            var moduleTypePath = (cls.pack != null && cls.pack.length > 0)
                ? (cls.pack.concat([cls.name]).join("."))
                : cls.name;

            var nativeModuleName: Null<String> = null;
            if (cls.meta.has(":native")) {
                var nativeMeta = cls.meta.extract(":native");
                if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                    switch (nativeMeta[0].params[0].expr) {
                        case EConst(CString(s, _)):
                            nativeModuleName = s;
                        default:
                    }
                }
            }

            for (field in cls.statics.get()) {
                if (field == null || field.meta == null || !field.meta.has(":component")) continue;

                var fnName = NameUtils.toSnakeCase(field.name);
                var fun = switch (field.type) {
                    case TFun(args, _):
                        args;
                    default:
                        null;
                };
                if (fun == null || fun.length == 0) continue;

                var assignsType = fun[0].t;
                var propInfo = propsFromAssignsType(assignsType);
                if (propInfo == null) continue;

                var def: ComponentDefinition = {
                    moduleTypePath: moduleTypePath,
                    nativeModuleName: nativeModuleName,
                    functionName: fnName,
                    props: propInfo.props,
                    required: propInfo.required,
                    slots: propInfo.slots
                };

                var existing = componentFunctionIndex.get(fnName);
                if (existing == null) {
                    componentFunctionIndex.set(fnName, [def]);
                } else {
                    existing.push(def);
                }
            }
        }
    }

    static function propsFromAssignsType(t: haxe.macro.Type): Null<{
        props: Map<String, String>,
        required: Map<String, Bool>,
        slots: Map<String, ComponentSlotDefinition>
    }> {
        var followed = TypeTools.follow(t);
        return switch (followed) {
            case TAnonymous(a):
                var props = new Map<String, String>();
                var required = new Map<String, Bool>();
                var slots = new Map<String, ComponentSlotDefinition>();

                for (f in a.get().fields) {
                    var typeStr = TypeTools.toString(f.type);
                    var isOptional = fieldIsOptionalByTypeString(typeStr) || (f.meta != null && f.meta.has(":optional"));

                    if (isSlotField(f)) {
                        var slotName = NameUtils.toSnakeCase(f.name);
                        var slotInfo = slotFieldInfoFromField(f);
                        var entryType = slotInfo != null ? slotInfo.entryType : null;
                        var letType = slotInfo != null ? slotInfo.letType : null;

                        var slotProps = new Map<String, String>();
                        var slotRequiredProps = new Map<String, Bool>();
                        if (entryType != null) {
                            var entryInfo = propsFromAssignsType(entryType);
                            if (entryInfo != null) {
                                slotProps = entryInfo.props;
                                slotRequiredProps = entryInfo.required;
                            }
                        }

                        var letBinding: Null<ComponentLetBindingDefinition> = null;
                        if (letType != null && !isElixirTermType(letType)) {
                            var letInfo = letBindingPropsFromType(letType);
                            if (letInfo != null && letInfo.props != null && letInfo.props.keys().hasNext()) {
                                letBinding = { props: letInfo.props, required: letInfo.required };
                            }
                        }

                        slots.set(slotName, {
                            required: !isOptional,
                            props: slotProps,
                            requiredProps: slotRequiredProps,
                            letBinding: letBinding
                        });
                        continue;
                    }

                    var kind = kindFromType(f.type);
                    var key = componentAssignKeyFromAttributeName(f.name);
                    props.set(key, kind);

                    if (!isOptional) required.set(key, true);
                }

                { props: props, required: required, slots: slots };
            case TType(tdef, params):
                propsFromAssignsType(TypeTools.applyTypeParameters(tdef.get().type, tdef.get().params, params));
            default:
                null;
        }
    }

    static function letBindingPropsFromType(t: haxe.macro.Type): Null<{
        props: Map<String, String>,
        required: Map<String, Bool>
    }> {
        var followed = TypeTools.follow(t);
        return switch (followed) {
            case TAnonymous(a):
                var props = new Map<String, String>();
                var required = new Map<String, Bool>();

                for (f in a.get().fields) {
                    var typeStr = TypeTools.toString(f.type);
                    var isOptional = fieldIsOptionalByTypeString(typeStr) || (f.meta != null && f.meta.has(":optional"));

                    // Let bindings represent Elixir struct/map fields (accessed via `var.field`),
                    // not HTML/HEEx attribute names. Avoid toHtmlAttribute() quirks like treating
                    // `data` as a `data-*` prefix.
                    var key = NameUtils.toSnakeCase(f.name);
                    props.set(key, kindFromType(f.type));

                    if (!isOptional) required.set(key, true);
                }

                { props: props, required: required };
            case TType(tdef, params):
                letBindingPropsFromType(TypeTools.applyTypeParameters(tdef.get().type, tdef.get().params, params));
            default:
                null;
        }
    }

    static function isSlotField(f: haxe.macro.Type.ClassField): Bool {
        if (f == null) return false;
        if (f.meta != null && f.meta.has(":slot")) return true;
        return unwrapSlotTypeInfo(f.type) != null;
    }

    static function slotFieldInfoFromField(f: haxe.macro.Type.ClassField): Null<{ entryType: haxe.macro.Type, letType: Null<haxe.macro.Type> }> {
        if (f == null) return null;
        var unwrapped = unwrapSlotTypeInfo(f.type);
        if (unwrapped != null) return unwrapped;
        // Legacy/metadata-only syntax: @:slot on a concrete entry typedef.
        if (f.meta != null && f.meta.has(":slot")) return { entryType: f.type, letType: null };
        return null;
    }

    static function unwrapSlotTypeInfo(t: haxe.macro.Type): Null<{ entryType: haxe.macro.Type, letType: Null<haxe.macro.Type> }> {
        if (t == null) return null;
        return switch (t) {
            case TType(tdef, params):
                unwrapSlotTypeInfo(TypeTools.applyTypeParameters(tdef.get().type, tdef.get().params, params));
            case TAbstract(aRef, params):
                var abs = aRef.get();
                if (abs == null) return null;
                // Optional slot: Null<Slot<T>>
                if (abs.name == "Null" && params != null && params.length == 1) {
                    unwrapSlotTypeInfo(params[0]);
                } else if (abs.name == "Slot" && abs.pack.join(".") == "phoenix.types" && params != null && params.length >= 1) {
                    var entryType = params[0];
                    var letType = params.length >= 2 ? params[1] : null;
                    { entryType: entryType, letType: letType };
                } else {
                    null;
                }
            default:
                null;
        }
    }

    static function isElixirTermType(t: haxe.macro.Type): Bool {
        if (t == null) return false;
        return switch (TypeTools.follow(t)) {
            case TAbstract(aRef, _):
                var abs = aRef.get();
                abs != null && abs.name == "Term" && abs.pack.join(".") == "elixir.types";
            default:
                false;
        };
    }

    static function fieldIsOptionalByTypeString(typeStr: String): Bool {
        if (typeStr == null) return true;
        var s = typeStr.trim();
        return s.startsWith("Null<") && s.endsWith(">");
    }
    #end

    static function getAllowedPhoenixCoreComponentAttributes(tag: String): Null<Map<String, Bool>> {
        return switch (tag) {
            case ".form":
                buildAllowedComponentAttributesFromHtmlTag("form", ["for", "as", "multipart"]);
            case ".link":
                buildAllowedComponentAttributesFromHtmlTag("a", ["navigate", "patch", "method", "replace"]);
            case ".inputs_for":
                buildAllowedComponentAttributes(["field", "id", "as", "default", "append", "prepend", "skip_hidden", "options"]);
            default:
                null;
        }
    }

    static function buildAllowedComponentAttributes(extra: Array<String>): Map<String, Bool> {
        var allowed: Map<String, Bool> = new Map();

        var globals = getGlobalHtmlAttributes();
        for (k in globals.keys()) allowed.set(k, true);

        for (name in extra) addAllowedAttributeForms(allowed, name);

        return allowed;
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

        // Additional validation: when a hook registry exists, validate known literal hook names.
        if (canonical == "phx-hook") {
            validatePhxHookName(value, ctx, pos);
        }
    }

    static function extractConstStringFromHeexExpr(expr: ElixirAST): Null<String> {
        if (expr == null || expr.def == null) return null;
        return switch (expr.def) {
            case EString(s):
                s;
            case EParen(inner):
                extractConstStringFromHeexExpr(inner);
            case EBinary(StringConcat, left, right):
                var leftValue = extractConstStringFromHeexExpr(left);
                var rightValue = extractConstStringFromHeexExpr(right);
                (leftValue != null && rightValue != null) ? (leftValue + rightValue) : null;
            case ERaw(code):
                extractConstDoubleQuotedStringFromRaw(code);
            default:
                null;
        };
    }

    static function extractConstDoubleQuotedStringFromRaw(code: String): Null<String> {
        if (code == null) return null;
        var trimmed = unwrapRawParens(code);
        if (trimmed.length < 2) return null;
        if (trimmed.charAt(0) != '"' || trimmed.charAt(trimmed.length - 1) != '"') return null;
        var inner = trimmed.substr(1, trimmed.length - 2);
        // Only accept plain literals with no escapes or interpolation to avoid mis-parsing.
        if (inner.indexOf("\\") != -1 || inner.indexOf("#{") != -1) return null;
        return inner;
    }

    static function unwrapRawParens(code: String): String {
        if (code == null) return "";
        var current = code.trim();
        while (current.length >= 2 && current.charAt(0) == "(" && current.charAt(current.length - 1) == ")") {
            current = current.substr(1, current.length - 2).trim();
        }
        return current;
    }

    static function validatePhxHookName(value: ElixirAST, ctx: Null<reflaxe.elixir.CompilationContext>, pos: haxe.macro.Expr.Position): Void {
        #if macro
        var allowed = getAllowedPhxHookNames();
        if (allowed == null) return;

        if (value == null) return;
        var name = extractConstStringFromHeexExpr(value);
        if (name == null) return;
        name = name.trim();
        if (name.length == 0) return;

        if (!allowed.exists(name)) {
            error(ctx, 'HEEx phx-hook error: unknown hook "' + name + '" (not present in any @:phxHookNames registry)', pos);
        }
        #end
    }

    #if macro
    static function getAllowedPhxHookNames(): Null<Map<String, Bool>> {
        if (phxHookNameCache != null) return phxHookNameCache;
        phxHookNameCache = buildAllowedPhxHookNames();
        return phxHookNameCache;
    }

    static function buildAllowedPhxHookNames(): Null<Map<String, Bool>> {
        var allowed: Map<String, Bool> = new Map();

        var discovered = RepoDiscovery.getDiscovered();
        if (discovered == null || discovered.length == 0) {
            RepoDiscovery.run();
            discovered = RepoDiscovery.getDiscovered();
        }

        if (discovered == null || discovered.length == 0) return null;

        for (typePath in discovered) {
            var t: haxe.macro.Type = null;
            try t = Context.getType(typePath) catch (_:Dynamic) t = null;
            if (t == null) continue;

            switch (TypeTools.follow(t)) {
                case TAbstract(aRef, _):
                    var abs = aRef.get();
                    if (abs == null || abs.meta == null || !abs.meta.has(":phxHookNames")) continue;
                    collectConstStringStaticsFromAbstract(abs, allowed);
                case TInst(cRef, _):
                    var cls = cRef.get();
                    if (cls == null || cls.meta == null || !cls.meta.has(":phxHookNames")) continue;
                    collectConstStringStaticsFromClass(cls, allowed);
                default:
            }
        }

        return allowed.keys().hasNext() ? allowed : null;
    }

    static function collectConstStringStaticsFromAbstract(abs: haxe.macro.Type.AbstractType, out: Map<String, Bool>): Void {
        if (abs == null) return;
        if (abs.impl == null) return;
        var impl = abs.impl.get();
        if (impl == null) return;
        collectConstStringStaticsFromClass(impl, out);
    }

    static function collectConstStringStaticsFromClass(cls: haxe.macro.Type.ClassType, out: Map<String, Bool>): Void {
        if (cls == null) return;
        for (field in cls.statics.get()) {
            if (field == null) continue;
            var value = extractStringConst(field.expr());
            if (value != null && value.length > 0) {
                out.set(value, true);
            }
        }
    }

    static function extractStringConst(expr: Null<TypedExpr>): Null<String> {
        if (expr == null) return null;
        return switch (expr.expr) {
            case TConst(TString(s)):
                s;
            case TMeta(_, inner):
                extractStringConst(inner);
            case TCast(inner, _):
                extractStringConst(inner);
            case TParenthesis(inner):
                extractStringConst(inner);
            default:
                null;
        };
    }
    #end

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
            case EAtom(_): "atom";
            case ECharlist(_): "string";
            case EBitstring(_): "string";
            case EList(_): "array";
            case EKeywordList(_): "array";
            case ETuple(_): "tuple";
            case EMap(_): "map";
            case EStruct(_, _): "map";
            case EStructUpdate(_, _): "map";
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

        if (expected.indexOf("|") != -1) {
            for (p in expected.split("|")) {
                if (p.trim() == actual) return true;
            }
            return false;
        }

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
                // Phoenix component assigns may use HXX attribute naming (e.g. className -> @class).
                var key = componentAssignKeyFromAttributeName(name);
                if (key != name && !out.exists(key)) {
                    out.set(key, kind);
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
                    var kind = kindFromType(f.type);
                    out.set(f.name, kind);
                    // HXX/HEEx assigns normalize camelCase to snake_case (e.g. className -> @class_name).
                    var snake = toSnakeCase(f.name);
                    if (snake != f.name && !out.exists(snake)) out.set(snake, kind);
                    // Phoenix component assigns may use HXX attribute naming (e.g. className -> @class).
                    var key = componentAssignKeyFromAttributeName(f.name);
                    if (key != f.name && !out.exists(key)) out.set(key, kind);
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

    static function kindFromType(t: haxe.macro.Type): String {
        if (t == null) return "unknown";

        var followed = TypeTools.follow(t);
        switch (followed) {
            case TAbstract(aRef, _):
                var abs = aRef.get();
                if (abs != null && abs.name == "Atom" && abs.pack.join(".") == "elixir.types") {
                    return "atom";
                }
            default:
        }

        var kind = normalizeKind(TypeTools.toString(followed));
        if (kind != "unknown") return kind;

        var unwrapped = TypeTools.followWithAbstracts(followed);
        kind = normalizeKind(TypeTools.toString(unwrapped));
        return kind;
    }

    static function normalizeKind(spec: String): String {
        var s = spec.trim();
        // Unwrap Null<T>
        if (s.startsWith("Null<") && s.endsWith(">")) {
            s = s.substr(5, s.length - 6).trim();
        }
        // Anonymous structures compile to maps in Elixir.
        if (s.startsWith("{") && s.endsWith("}")) return "map";
        // Basic kinds
        if (s == "String") return "string";
        if (s == "Int") return "int";
        if (s == "Float") return "float";
        if (s == "Bool") return "bool";
        if (s == "elixir.types.Atom" || s.endsWith(".Atom")) return "atom";
        if (~/^Array<.*/.match(s)) return "array";
        if (~/^Map<.*/.match(s) || ~/^haxe\\.ds\\..*Map<.*/.match(s)) return "map";
        // Unknown/custom → leave unknown to avoid false positives
        return "unknown";
    }
}

#end
