package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;

/**
 * TemplateHelpers: HXX Template Processing Utilities
 * 
 * WHY: Centralize HXX → HEEx template transformation logic
 * - Separate template concerns from main AST builder
 * - Provide reusable template utilities
 * - Encapsulate HXX-specific patterns
 * 
 * WHAT: Template content collection and transformation
 * - Extract template strings and embedded expressions
 * - Process template arguments
 * - Detect HXX module usage
 * 
 * HOW: Pattern matching on AST nodes to extract template content
 * - Collect string literals for template body
 * - Process embedded <%= %> expressions
 * - Handle template function arguments
 */
class TemplateHelpers {
    
    /**
     * Collect template content from an ElixirAST node
     * 
     * Processes various AST patterns to extract template strings,
     * handling embedded expressions and string interpolation.
     */
    public static function collectTemplateContent(ast: ElixirAST): String {
        return switch(ast.def) {
            case EString(s): 
                // Simple string - return as-is
                s;
                
            case EBinary(StringConcat, left, right):
                // String concatenation - collect both sides
                collectTemplateContent(left) + collectTemplateContent(right);
                
            case EVar(name):
                // Variable reference - convert to EEx interpolation
                '<%= ' + name + ' %>';
                
            case ECall(module, func, args):
                // Function call - convert to EEx interpolation
                var callStr = if (module != null) {
                    switch(module.def) {
                        case EVar(m): m + "." + func;
                        default: func;
                    }
                } else {
                    func;
                }
                
                // Build the function call with arguments
                if (args.length > 0) {
                    var argStrs = [];
                    for (arg in args) {
                        argStrs.push(collectTemplateArgument(arg));
                    }
                    callStr += "(" + argStrs.join(", ") + ")";
                } else {
                    callStr += "()";
                }
                '<%= ' + callStr + ' %>';
                
            default:
                // For other expressions, try to convert to a string representation
                // This is a fallback - ideally all cases should be handled explicitly
                #if debug_hxx_transformation
                #if debug_ast_builder
                trace('[HXX] Unhandled AST type in template collection: ${ast.def}');
                #end
                #end
                '<%= [unhandled expression] %>';
        };
    }
    
    /**
     * Collect template argument for function calls within templates
     */
    public static function collectTemplateArgument(ast: ElixirAST): String {
        return switch(ast.def) {
            case EString(s): '"' + s + '"';
            case EVar(name): name;
            case EAtom(a): ":" + a;
            case EInteger(i): Std.string(i);
            case EFloat(f): Std.string(f);
            case EBoolean(b): b ? "true" : "false";
            case ENil: "nil";
            case EField(obj, field):
                switch(obj.def) {
                    case EVar(v): v + "." + field;
                    default: "[complex]." + field;
                }
            default: "[complex arg]";
        };
    }
    
    /**
     * Check if an expression is an HXX module access
     * 
     * Detects patterns like HXX.hxx() or hxx.HXX.hxx()
     */
    public static function isHXXModule(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TTypeExpr(m):
                // Check if this is the HXX module
                var moduleName = moduleTypeToString(m);
                #if debug_hxx_transformation
                #if debug_ast_builder
                trace('[HXX] Checking module: $moduleName against "HXX"');
                #end
                #end
                moduleName == "HXX";
            default: 
                #if debug_hxx_transformation
                #if debug_ast_builder
                trace('[HXX] Not a TTypeExpr, expr type: ${expr.expr}');
                #end
                #end
                false;
        };
    }
    
    /**
     * Convert a ModuleType to string representation
     * Helper function for isHXXModule
     */
    static function moduleTypeToString(m: ModuleType): String {
        return switch (m) {
            case TClassDecl(c):
                var cls = c.get();
                if (cls.pack.length > 0) {
                    cls.pack.join(".") + "." + cls.name;
                } else {
                    cls.name;
                }
            case TEnumDecl(e):
                var enm = e.get();
                if (enm.pack.length > 0) {
                    enm.pack.join(".") + "." + enm.name;
                } else {
                    enm.name;
                }
            case TAbstract(a):
                var abs = a.get();
                if (abs.pack.length > 0) {
                    abs.pack.join(".") + "." + abs.name;
                } else {
                    abs.name;
                }
            case TTypeDecl(t):
                var typ = t.get();
                if (typ.pack.length > 0) {
                    typ.pack.join(".") + "." + typ.name;
                } else {
                    typ.name;
                }
        };
    }
}

#end