package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

using StringTools;

/**
 * HeexAssignsTypeLinterTransforms
 *
 * WHAT
 * - Statically validates `@assigns` field usage inside ~H templates generated from HXX.
 * - Reports errors for:
 *   1) Unknown assigns fields (e.g., `@sort_byy` when only `sort_by` exists)
 *   2) Obvious literal type mismatches in comparisons (e.g., `@sort_by == 1` when `sort_by: String`)
 *
 * WHY
 * - HXX authoring must be fully type-checked like TSX. Since HEEx lives in strings until
 *   normalized to ~H, the core compiler can miss invalid usages. This linter bridges that
 *   gap by correlating template `@field` references with the Haxe-typed `assigns` typedef.
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
 *
 * EXAMPLES
 * Haxe (invalid):
 *   typedef Assigns = { sort_by: String }
 *   HXX.hxx('<div selected={@sort_by == 1}></div>')
 * Error:
 *   HEEx assigns type error: @sort_by is String but compared to Int literal
 *
 * LIMITATIONS (Intentional for M1)
 * - Only checks literal comparisons (numbers, strings, true/false, nil) inside ~H content.
 * - Does not attempt full expression typing for complex cases yet; follow-up work will leverage
 *   structured attribute parsing (EFragment) and builder-time typing.
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
                trace('[HeexAssignsTypeLinter] render/1 at hxPath=' + hxPath);
#end
                if (hxPath == null) return; // No source; skip
                // Skip compiler/library/internal files to avoid scanning whole libs
                var hxPathNorm = StringTools.replace(hxPath, "\\", "/");
                if (hxPathNorm.indexOf("/reflaxe/elixir/") != -1 || hxPathNorm.indexOf("/vendor/") != -1 || hxPathNorm.indexOf("/std/") != -1) {
                    return;
                }
                var fileContent: String = null;
                try fileContent = sys.io.File.getContent(hxPath) catch (e: Dynamic) fileContent = null;
                if (fileContent == null) return;

                var assignsType = extractAssignsTypeName(fileContent);
#if debug_assigns_linter
                trace('[HeexAssignsTypeLinter] assigns type=' + assignsType);
#end
                if (assignsType == null) return; // cannot determine type name; skip

                var fields = extractAssignsFields(assignsType, fileContent);
#if debug_assigns_linter
                var keys = [for (k in fields.keys()) k].join(',');
                trace('[HeexAssignsTypeLinter] typedef fields=' + keys);
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
                    trace('[HeexAssignsTypeLinter] ~H content @fields=' + used.join(','));
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
                        var dyn2: Dynamic = meta;
                        if (Reflect.hasField(dyn2, "heexAST")) {
                            var nodes: Array<ElixirAST> = Reflect.field(dyn2, "heexAST");
                            if (nodes != null && nodes.length > 0) {
                                validateHeexTypedAST(nodes, fields, typeName, ctx, x.pos);
                            }
                        }
                        var dyn: Dynamic = meta;
                        if (Reflect.hasField(dyn, "heexFragments")) {
                            var frags: Array<Dynamic> = Reflect.field(dyn, "heexFragments");
                            if (frags != null) {
                                for (f in frags) {
                                    var attrs: Array<Dynamic> = f.attributes;
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
            case EFragment(_tag, attributes, children):
                // Attributes
                for (a in attributes) {
                    validateExprForAssigns(a.value, fields, typeName, ctx, pos);
                }
                // Children
                for (c in children) validateNode(c, fields, typeName, ctx, pos);
            default:
        }
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

    static function extractAssignsFields(typeName: String, hx: String): Map<String, String> {
        var out = new Map<String, String>();
        // Find typedef <typeName> = { ... }
        var idx = hx.indexOf('typedef ' + typeName + '');
        if (idx == -1) return out;
        var braceStart = hx.indexOf('{', idx);
        if (braceStart == -1) return out;
        var i = braceStart + 1;
        var depth = 1;
        while (i < hx.length && depth > 0) {
            var ch = hx.charAt(i);
            if (ch == '{') depth++; else if (ch == '}') depth--; i++;
        }
        var braceEnd = i - 1;
        if (braceEnd <= braceStart) return out;
        var block = hx.substr(braceStart + 1, braceEnd - (braceStart + 1));
        // Parse lines: supports both `var name: Type` and `name: Type`, with optional comma/semicolon terminators
        var lines = block.split("\n");
        for (ln in lines) {
            var line = ln.trim();
            if (line.length == 0 || line.startsWith("//")) continue;
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
        return out;
    }

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
