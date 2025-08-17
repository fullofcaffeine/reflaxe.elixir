package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.helpers.NamingHelper;

using StringTools;

/**
 * HxxCompiler - Phoenix-aware HXX template compiler
 * 
 * Converts HXX.hxx() calls to optimal Phoenix HEEx templates by reconstructing
 * templates from Haxe's AST and applying Phoenix-specific transformations.
 * 
 * Architecture:
 * 1. AST Reconstruction - Walks TypedExpr tree to rebuild template structure
 * 2. Phoenix Pattern Processing - Converts Haxe idioms to Phoenix conventions  
 * 3. HEEx Generation - Produces clean ~H sigils with proper interpolation
 * 
 * Key Features:
 * - Type-safe interpolation from Haxe expressions
 * - Phoenix component syntax preservation (<.button>)
 * - LiveView attribute handling (phx-click, phx-submit)
 * - Assigns pattern conversion (assigns.field → @field)
 * - Idiomatic Elixir code generation
 * 
 * @see documentation/guides/HXX_GUIDE.md - Usage patterns and examples
 * @see documentation/HXX_ARCHITECTURE.md - Technical implementation details
 */
class HxxCompiler {
    
    /**
     * Main entry point - converts HXX.hxx() call AST to HEEx template
     * 
     * @param expr The TypedExpr from HXX.hxx() function call argument
     * @return String Clean HEEx template with ~H sigil
     */
    public static function compileHxxTemplate(expr: TypedExpr): String {
        try {
            // Step 1: Reconstruct template structure from AST
            var templateData = reconstructTemplate(expr);
            
            // Step 2: Apply Phoenix-specific transformations
            var phoenixTemplate = processPhoenixPatterns(templateData);
            
            // Step 3: Generate final HEEx code with ~H sigil
            return wrapInHEExSigil(phoenixTemplate);
            
        } catch (e: Dynamic) {
            // Fallback for debugging - should be removed in production
            Context.warning('HXX compilation failed: ${e}, falling back to string compilation', expr.pos);
            return '""';  // Empty string fallback
        }
    }
    
    /**
     * Reconstructs template content from Haxe AST
     * 
     * Walks the TypedExpr tree and builds a structured representation
     * that preserves both static content and dynamic expressions.
     * 
     * @param expr The root TypedExpr to reconstruct
     * @return TemplateData Structured template representation
     */
    private static function reconstructTemplate(expr: TypedExpr): TemplateData {
        return walkAST(expr, new TemplateContext());
    }
    
    /**
     * Recursively walks the AST and builds template nodes
     * 
     * @param expr Current AST node to process
     * @param context Template compilation context
     * @return TemplateNode Processed template node
     */
    private static function walkAST(expr: TypedExpr, context: TemplateContext): TemplateNode {
        switch (expr.expr) {
            case TConst(TString(s)):
                // Pure string literal - keep as-is
                return TextNode(s);
                
            case TConst(TInt(i)):
                // Integer constant: 42 → {42}
                return VariableNode(Std.string(i));
                
            case TConst(TFloat(f)):
                // Float constant: 3.14 → {3.14}
                return VariableNode(f);
                
            case TConst(TBool(b)):
                // Boolean constant: true → {true}
                return VariableNode(b ? "true" : "false");
                
            case TConst(TNull):
                // Null constant: null → {nil}
                return VariableNode("nil");
                
            case TConst(TThis):
                // This reference: this → {__MODULE__}
                return VariableNode("__MODULE__");
                
            case TConst(TSuper):
                // Super reference: super → {super()}
                return VariableNode("super()");
                
            case TParenthesis(e):
                // Parenthesized expression: (expr) → process inner expression
                return walkAST(e, context);
                
            case TTypeExpr(moduleType):
                // Type expression (cast, type check) - convert to string representation
                var typeName = switch (moduleType) {
                    case TClassDecl(c): c.get().name;
                    case TEnumDecl(e): e.get().name;
                    case TTypeDecl(t): t.get().name;
                    case TAbstract(a): a.get().name;
                };
                return VariableNode(NamingHelper.toSnakeCase(typeName));
                
            case TField(obj, field):
                // Object property access: user.name → {user.name}
                var fieldName = switch (field) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FClosure(_, cf): cf.get().name;
                    case FAnon(cf): cf.get().name;
                    case FEnum(_, ef): ef.name;
                    case FDynamic(s): s;
                };
                
                // Special case: assigns.inner_content becomes @inner_content in Phoenix
                if (fieldName == "inner_content" && isAssignsObject(obj)) {
                    return VariableNode("@inner_content");
                }
                
                var objNode = walkAST(obj, context);
                var elixirField = NamingHelper.toSnakeCase(fieldName);
                return InterpolationNode(objNode, elixirField);
                
            case TLocal(v):
                // Local variable: userName → {user_name}
                var elixirVar = NamingHelper.toSnakeCase(v.name);
                return VariableNode(elixirVar);
                
            case TBinop(OpAdd, left, right):
                // String concatenation - recursively process both sides
                var leftNode = walkAST(left, context);
                var rightNode = walkAST(right, context);
                return ConcatNode([leftNode, rightNode]);
                
            case TIf(cond, ifExpr, elseExpr):
                // Conditional expression: condition ? true : false
                var condNode = walkAST(cond, context);
                var thenNode = walkAST(ifExpr, context);
                var elseNode = elseExpr != null ? walkAST(elseExpr, context) : null;
                return ConditionalNode(condNode, thenNode, elseNode);
                
            case TCall(e, args):
                // Check if this is a Std.string() wrapper (Haxe adds these for type safety in string interpolation)
                switch (e.expr) {
                    case TField({expr: TTypeExpr(TClassDecl(c))}, FStatic(_, cf)) if (c.get().name == "Std" && cf.get().name == "string"):
                        // This is Std.string(expr) - unwrap and process the inner expression
                        if (args.length > 0) {
                            // Special handling for assigns.field pattern
                            switch (args[0].expr) {
                                case TField(obj, field) if (isAssignsObject(obj)):
                                    // assigns.field should become @field in Phoenix templates
                                    var fieldName = switch (field) {
                                        case FInstance(_, _, cf) | FStatic(_, cf) | FClosure(_, cf): cf.get().name;
                                        case FAnon(cf): cf.get().name;
                                        case FEnum(_, ef): ef.name;
                                        case FDynamic(s): s;
                                    };
                                    
                                    // Special case: assigns.inner_content becomes @inner_content
                                    if (fieldName == "inner_content") {
                                        return VariableNode("@inner_content");
                                    }
                                    
                                    // Other assigns.field become @field
                                    var elixirField = NamingHelper.toSnakeCase(fieldName);
                                    return VariableNode('@${elixirField}');
                                    
                                default:
                                    // For other Std.string() calls, just process the inner expression
                                    return walkAST(args[0], context);
                            }
                        }
                        return walkAST(args[0], context);
                    default:
                        // Regular function calls
                        return compileFunctionCall(e, args, context);
                }
                
            case TBinop(op, left, right):
                // Other binary operations: ==, !=, >, <, etc.
                var leftNode = walkAST(left, context);
                var rightNode = walkAST(right, context);
                return BinaryOpNode(op, leftNode, rightNode);
                
            case TObjectDecl(fields):
                // Object literal: {key: value, ...} → %{key: value, ...}
                var objectFields = fields.map(f -> {
                    key: f.name,
                    value: walkAST(f.expr, context)
                });
                return ObjectNode(objectFields);
                
            case _:
                // Unknown expression type - wrap in generic interpolation
                Context.warning('Unknown AST node type in HXX template: ${expr.expr.getName()}', expr.pos);
                return RawExpressionNode(expr);
        }
    }
    
    /**
     * Compiles function call expressions to appropriate Elixir syntax
     */
    private static function compileFunctionCall(callExpr: TypedExpr, args: Array<TypedExpr>, context: TemplateContext): TemplateNode {
        var argNodes = args.map(arg -> walkAST(arg, context));
        
        // Handle different types of function calls
        switch (callExpr.expr) {
            case TField(obj, field):
                // Method call on object: obj.method(args)
                var objNode = walkAST(obj, context);
                var fieldName = switch (field) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FClosure(_, cf): cf.get().name;
                    case FAnon(cf): cf.get().name;
                    case FEnum(_, ef): ef.name;
                    case FDynamic(s): s;
                };
                var elixirMethod = NamingHelper.toSnakeCase(fieldName);
                
                // Special case: Static method calls should become standalone function calls
                switch (field) {
                    case FStatic(_, _):
                        // Static method call - treat as standalone function
                        return FunctionCallNode(null, elixirMethod, argNodes);
                    case _:
                        // Continue with other checks
                }
                
                // Special case: Template helper function calls should become standalone function calls
                // Check if this is a call to a function marked with @:templateHelper metadata
                if (isTemplateHelperCall(obj, field)) {
                    // Template helper calls compile directly to template functions
                    return FunctionCallNode(null, elixirMethod, argNodes);
                }
                
                // Special case: method calls on the current module should become standalone function calls in templates
                if (objNode != null) {
                    switch (objNode) {
                        case VariableNode("__MODULE__"):
                            // Convert module method call to standalone function call
                            return FunctionCallNode(null, elixirMethod, argNodes);
                        case VariableNode(varName):
                            // Check if this is a module name (like app_layout, root_layout)
                            // These are generated from __MODULE__ and should become standalone function calls
                            if (varName.endsWith("_layout") || varName == "app_layout" || varName == "root_layout") {
                                return FunctionCallNode(null, elixirMethod, argNodes);
                            }
                            // Regular method call
                            return FunctionCallNode(objNode, elixirMethod, argNodes);
                        case _:
                            // Regular method call
                            return FunctionCallNode(objNode, elixirMethod, argNodes);
                    }
                } else {
                    return FunctionCallNode(objNode, elixirMethod, argNodes);
                }
                
            case TLocal(v):
                // Local function call: func(args)
                var elixirFunc = NamingHelper.toSnakeCase(v.name);
                return FunctionCallNode(null, elixirFunc, argNodes);
                
            case _:
                // Other function calls - treat as generic expression
                return RawExpressionNode(callExpr);
        }
    }
    
    /**
     * Applies Phoenix-specific pattern transformations
     * 
     * @param templateData Reconstructed template structure
     * @return String Processed template with Phoenix conventions
     */
    private static function processPhoenixPatterns(templateData: TemplateNode): String {
        var content = generateTemplateContent(templateData);
        
        // Apply Phoenix-specific transformations
        content = convertAssignsPatterns(content);
        content = convertMapSyntax(content);
        content = convertFunctionNames(content);
        content = preservePhoenixComponents(content);
        content = optimizeElixirExpressions(content);
        
        return content;
    }
    
    /**
     * Strip interpolation wrapper from content to avoid nesting
     * 
     * @param content Content that might already be wrapped in <%= %>
     * @return String Content without <%= %> wrapper
     */
    private static function stripInterpolationWrapper(content: String): String {
        if (content.startsWith('<%= ') && content.endsWith(' %>')) {
            return content.substring(4, content.length - 3);
        }
        return content;
    }
    
    /**
     * Generates template content from structured template nodes
     */
    private static function generateTemplateContent(node: TemplateNode): String {
        switch (node) {
            case TextNode(text):
                return text;
                
            case InterpolationNode(obj, field):
                var objStr = generateTemplateContent(obj);
                
                // Fix nested interpolation: avoid double-wrapping <%= %>
                var cleanObjStr = stripInterpolationWrapper(objStr);
                return '<%= ${cleanObjStr}.${field} %>';
                
            case VariableNode(name):
                return '<%= ${name} %>';
                
            case ConcatNode(nodes):
                return nodes.map(n -> generateTemplateContent(n)).join('');
                
            case ConditionalNode(cond, thenNode, elseNode):
                var condStr = generateElixirExpression(cond);
                var thenStr = generateTemplateContent(thenNode);
                var elseStr = elseNode != null ? generateTemplateContent(elseNode) : '""';
                return '<%= if ${condStr}, do: ${thenStr}, else: ${elseStr} %>';
                
            case FunctionCallNode(obj, method, args):
                var argStrs = args.map(arg -> generateElixirExpression(arg));
                
                // Handle both object methods and standalone functions
                if (obj != null) {
                    var objStr = generateElixirExpression(obj);
                    if (objStr != null && objStr != "") {
                        // Object method call: obj.method(args)
                        var allArgs = [objStr].concat(argStrs);
                        return '<%= ${method}(${allArgs.join(", ")}) %>';
                    }
                }
                
                // Standalone function call: method(args)
                return '<%= ${method}(${argStrs.join(", ")}) %>';
                
            case BinaryOpNode(op, left, right):
                var leftStr = generateElixirExpression(left);
                var rightStr = generateElixirExpression(right);
                var opStr = getElixirOperator(op);
                return '<%= ${leftStr} ${opStr} ${rightStr} %>';
                
            case ObjectNode(fields):
                // Generate object literal with Phoenix-appropriate key format
                var fieldStrs = fields.map(f -> {
                    var valueStr = generateElixirExpression(f.value);
                    // Use atom keys for template contexts (Phoenix convention)
                    return '${f.key}: ${valueStr}';
                });
                return '<%= %{${fieldStrs.join(", ")}} %>';
                
            case RawExpressionNode(expr):
                // Fallback - this should be minimized
                return '<%= raw_expression %>';  // Placeholder
        }
    }
    
    /**
     * Generates Elixir expressions for interpolation context
     */
    private static function generateElixirExpression(node: TemplateNode): String {
        if (node == null) return "";
        
        // Similar to generateTemplateContent but without wrapping in interpolation syntax
        switch (node) {
            case TextNode(text):
                return '"${text}"';  // Quote string literals in expressions
                
            case VariableNode(name):
                return name;
                
            case InterpolationNode(obj, field):
                var objStr = generateElixirExpression(obj);
                return '${objStr}.${field}';
                
            case FunctionCallNode(obj, method, args):
                // Generate function calls without interpolation wrapper
                var argStrs = args.map(arg -> generateElixirExpression(arg));
                
                // Handle both object methods and standalone functions
                if (obj != null) {
                    var objStr = generateElixirExpression(obj);
                    if (objStr != null && objStr != "") {
                        // Object method call: obj.method(args)
                        var allArgs = [objStr].concat(argStrs);
                        return '${method}(${allArgs.join(", ")})';
                    }
                }
                
                // Standalone function call: method(args)
                return '${method}(${argStrs.join(", ")})';
                
            case BinaryOpNode(op, left, right):
                var leftStr = generateElixirExpression(left);
                var rightStr = generateElixirExpression(right);
                var opStr = getElixirOperator(op);
                return '${leftStr} ${opStr} ${rightStr}';
                
            case ObjectNode(fields):
                // Generate object literal without interpolation wrapper (for use in expressions)
                var fieldStrs = fields.map(f -> {
                    var valueStr = generateElixirExpression(f.value);
                    // Use atom keys for template contexts (Phoenix convention)
                    return '${f.key}: ${valueStr}';
                });
                return '%{${fieldStrs.join(", ")}}';
                
            case ConditionalNode(cond, thenNode, elseNode):
                var condStr = generateElixirExpression(cond);
                var thenStr = generateElixirExpression(thenNode);
                var elseStr = elseNode != null ? generateElixirExpression(elseNode) : '""';
                return 'if ${condStr}, do: ${thenStr}, else: ${elseStr}';
                
            case ConcatNode(nodes):
                return nodes.map(n -> generateElixirExpression(n)).join(' <> ');
                
            case _:
                // For other node types, generate and strip outer interpolation wrapper
                var content = generateTemplateContent(node);
                if (content.startsWith('<%= ') && content.endsWith(' %>')) {
                    return content.substring(4, content.length - 3);
                }
                return content;
        }
    }
    
    /**
     * Convert Haxe binary operators to Elixir equivalents
     */
    private static function getElixirOperator(op: Binop): String {
        return switch (op) {
            case OpAdd: "+";
            case OpMult: "*";
            case OpDiv: "/";
            case OpSub: "-";
            case OpAssign: "=";
            case OpEq: "==";
            case OpNotEq: "!=";
            case OpGt: ">";
            case OpGte: ">=";
            case OpLt: "<";
            case OpLte: "<=";
            case OpAnd: "&&";
            case OpOr: "||";
            case OpXor: "!=";  // Elixir doesn't have XOR for booleans, use !=
            case OpBoolAnd: "and";
            case OpBoolOr: "or";
            case OpShl: "<<<";  // Bitwise left shift
            case OpShr: ">>>";  // Bitwise right shift
            case OpUShr: ">>>";  // Unsigned right shift (same as signed in Elixir)
            case OpMod: "rem";  // Elixir uses 'rem' for remainder
            case OpAssignOp(op): getElixirOperator(op);
            case OpInterval: "..";  // Range operator
            case OpArrow: "->";  // Function arrow
            case OpIn: "in";  // Membership test
            case OpNullCoal: "||";  // Null coalescing - use || as approximation
        };
    }
    
    /**
     * Convert assigns patterns to Phoenix conventions
     * assigns.field → @field (in LiveView context)
     */
    private static function convertAssignsPatterns(content: String): String {
        // Convert <%= assigns.field %> to <%= @field %> for LiveView templates
        var assignsPattern = ~/<%= assigns\.([a-zA-Z_][a-zA-Z0-9_]*) %>/g;
        var result = assignsPattern.replace(content, '<%= @$1 %>');
        
        // Also handle cases without spaces for backward compatibility
        var assignsPattern2 = ~/<%=assigns\.([a-zA-Z_][a-zA-Z0-9_]*)%>/g;
        result = assignsPattern2.replace(result, '<%= @$1 %>');
        
        return result;
    }
    
    /**
     * Convert Haxe map syntax to Elixir atom key syntax
     * %{user => user} → %{user: user} (for Phoenix assigns)
     */
    private static function convertMapSyntax(content: String): String {
        // Convert map literals with => to : syntax for Phoenix convention
        var mapPattern = ~/%\{([a-zA-Z_][a-zA-Z0-9_]*) => ([^}]+)\}/g;
        return mapPattern.replace(content, '%{$1: $2}');
    }
    
    /**
     * Convert function names to snake_case in templates
     * getStatusClass(args) → get_status_class(args)
     */
    private static function convertFunctionNames(content: String): String {
        // Convert camelCase function names to snake_case (target function calls only)
        var functionPattern = ~/([a-z])([A-Z])([a-zA-Z]*)(\s*\()/g;
        return functionPattern.map(content, function(r) {
            var prefix = r.matched(1);
            var upperChar = r.matched(2).toLowerCase();
            var suffix = r.matched(3).toLowerCase();
            var args = r.matched(4);
            return prefix + '_' + upperChar + suffix + args;
        });
    }
    
    /**
     * Preserve Phoenix component syntax and LiveView attributes
     */
    private static function preservePhoenixComponents(content: String): String {
        // Phoenix components and LiveView attributes should be preserved as-is
        // <.button phx-click="action"> → <.button phx-click="action">
        // This function ensures they're not modified by other transformations
        
        // For now, return as-is since our AST approach should preserve them naturally
        return content;
    }
    
    /**
     * Optimize Elixir expressions for idiomatic code generation
     */
    private static function optimizeElixirExpressions(content: String): String {
        // Optimize common patterns for better Elixir code
        
        // Simplify string concatenation: "a" <> "b" → "ab"
        content = ~/(["'][^"']*["'])\s*<>\s*(["'][^"']*["'])/g.map(content, function(r) {
            var left = r.matched(1);
            var right = r.matched(2);
            // Remove quotes and concatenate
            var leftStr = left.substring(1, left.length - 1);
            var rightStr = right.substring(1, right.length - 1);
            return '"${leftStr}${rightStr}"';
        });
        
        return content;
    }
    
    /**
     * Check if an expression represents the assigns object in Phoenix templates
     */
    private static function isAssignsObject(expr: TypedExpr): Bool {
        switch (expr.expr) {
            case TLocal(v):
                return v.name == "assigns";
            case _:
                return false;
        }
    }
    
    /**
     * Check if a function call is to a template helper function
     * 
     * Detects calls to functions marked with @:templateHelper metadata that should be compiled
     * directly to template functions rather than module-prefixed calls.
     * 
     * @param obj The object being called (e.g., Component in Component.get_csrf_token())
     * @param field The field reference containing metadata information
     * @return Bool True if this is a template helper function call
     */
    private static function isTemplateHelperCall(obj: TypedExpr, field: FieldAccess): Bool {
        switch (obj.expr) {
            case TTypeExpr(moduleType):
                // Check if this is a type expression for an extern class
                switch (moduleType) {
                    case TClassDecl(classRef):
                        var cls = classRef.get();
                        
                        // Only check extern classes for template helpers
                        if (!cls.isExtern) {
                            return false;
                        }
                        
                        // Get the ClassField for this specific method
                        var fieldName = switch (field) {
                            case FInstance(_, _, cf) | FStatic(_, cf) | FClosure(_, cf): cf.get();
                            case FAnon(cf): cf.get();
                            case _: return false; // Can't check metadata for dynamic fields
                        };
                        
                        // Check if the field has @:templateHelper metadata
                        return fieldName.meta.has(":templateHelper");
                        
                    case _:
                        // Not a class, so can't have template helper methods
                        return false;
                }
                
            case _:
                // Not a type expression, so not a template helper call
                return false;
        }
    }
    
    /**
     * Wrap template content in HEEx ~H sigil
     */
    private static function wrapInHEExSigil(content: String): String {
        // Clean up whitespace and format properly
        var lines = content.split('\n');
        var cleanedLines = [];
        
        for (line in lines) {
            var trimmed = line.trim();
            if (trimmed.length > 0) {
                cleanedLines.push('  ' + trimmed);  // Indent for readability
            } else if (cleanedLines.length > 0 && line.length == 0) {
                cleanedLines.push('');  // Preserve empty lines for spacing
            }
        }
        
        // Build final ~H sigil
        if (cleanedLines.length == 0) {
            return '~H""""""';  // Empty template
        } else if (cleanedLines.length == 1 && !cleanedLines[0].contains('\n')) {
            // Single line template
            return '~H"${cleanedLines[0].trim()}"';
        } else {
            // Multi-line template
            var cleanContent = cleanedLines.join('\n');
            return '~H"""\n${cleanContent}\n  """';
        }
    }
}

/**
 * Template compilation context - tracks state during compilation
 */
class TemplateContext {
    public var isInLiveView: Bool = false;
    public var isInComponent: Bool = false;
    public var isInAttributeValue: Bool = false;
    public var depth: Int = 0;
    
    public function new() {}
}

/**
 * Template node types for structured representation
 */
enum TemplateNode {
    /** Raw text content (HTML, whitespace, etc.) */
    TextNode(text: String);
    
    /** Variable interpolation: {variable_name} */
    VariableNode(name: String);
    
    /** Object field access: {object.field} */
    InterpolationNode(object: TemplateNode, field: String);
    
    /** String concatenation */
    ConcatNode(nodes: Array<TemplateNode>);
    
    /** Conditional expression: {if cond, do: then, else: else} */
    ConditionalNode(condition: TemplateNode, thenNode: TemplateNode, elseNode: Null<TemplateNode>);
    
    /** Function call: {function(args)} */
    FunctionCallNode(object: TemplateNode, method: String, args: Array<TemplateNode>);
    
    /** Binary operation: {left op right} */
    BinaryOpNode(op: Binop, left: TemplateNode, right: TemplateNode);
    
    /** Object literal: %{key: value} */
    ObjectNode(fields: Array<{key: String, value: TemplateNode}>);
    
    /** Raw expression fallback */
    RawExpressionNode(expr: TypedExpr);
}

/**
 * Simplified template data structure
 */
typedef TemplateData = TemplateNode;

#end