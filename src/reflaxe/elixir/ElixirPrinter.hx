package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.FormatHelper;

/**
 * Options for class printing
 */
typedef PrintClassOptions = {
    ?documentation: String,
    ?superClass: String,
    ?interfaces: Array<String>,
    ?isStruct: Bool,
    ?isGenServer: Bool
}

/**
 * Context information for expression printing
 */
typedef ExpressionContext = {
    ?isElixirNative: Bool,
    ?isTopLevel: Bool,
    ?inPipe: Bool,
    ?expectedType: String
}

/**
 * ElixirPrinter - AST to Elixir string conversion utilities
 * Handles conversion of Haxe AST elements to idiomatic Elixir code strings
 */
class ElixirPrinter {
    
    /**
     * Print a Haxe class as an Elixir module
     * @param className The class name
     * @param varFields Array of variable field data (can be structured data)
     * @param funcFields Array of function field data (can be structured data)
     * @param options Additional options like documentation, inheritance info
     * @return Generated Elixir module string
     */
    public function printClass(className: String, varFields: Array<Dynamic>, funcFields: Array<Dynamic>, ?options: PrintClassOptions): String {
        var moduleName = NamingHelper.getElixirModuleName(className);
        var result = 'defmodule ${moduleName} do\n';
        
        // Add module documentation with enhanced formatting
        var docString = options?.documentation ?? '${className} module generated from Haxe';
        result += FormatHelper.formatDoc(docString, true, 1) + '\n\n';
        
        // Add inheritance comments if provided
        if (options?.superClass != null) {
            result += FormatHelper.indent('# Inherits from ${options.superClass}', 1) + '\n';
        }
        
        if (options?.interfaces != null && options.interfaces.length > 0) {
            result += FormatHelper.indent('# Implements interfaces:', 1) + '\n';
            for (interface in options.interfaces) {
                result += FormatHelper.indent('# - ${interface}', 1) + '\n';
            }
            result += '\n';
        }
        
        // Add type definitions if needed
        if (hasInstanceVars(varFields)) {
            result += printTypeSpec(className, varFields);
        }
        
        // Add struct definition if there are instance variables
        if (hasInstanceVars(varFields)) {
            result += printStruct(varFields);
        }
        
        // Separate static and instance functions
        var staticFuncs = [];
        var instanceFuncs = [];
        
        // For now, treat all as instance functions (will be enhanced when we have proper data structures)
        instanceFuncs = funcFields;
        
        // Print static functions first
        if (staticFuncs.length > 0) {
            result += FormatHelper.indent('# Static functions', 1) + '\n';
            for (funcField in staticFuncs) {
                result += printFunctionFromData(funcField, true);
            }
            result += '\n';
        }
        
        // Print instance functions
        if (instanceFuncs.length > 0) {
            result += FormatHelper.indent('# Instance functions', 1) + '\n';
            for (funcField in instanceFuncs) {
                result += printFunctionFromData(funcField, false);
            }
        }
        
        // If no content, add placeholder
        if (varFields.length == 0 && funcFields.length == 0) {
            result += FormatHelper.indent('@doc "Empty module - generated as placeholder"', 1) + '\n';
            result += FormatHelper.indent('def __info__(:module), do: __MODULE__', 1) + '\n';
        }
        
        result += 'end\n';
        return result;
    }
    
    /**
     * Print a function definition with enhanced formatting
     * @param funcName The function name
     * @param args Array of function arguments
     * @param returnType The return type
     * @param isStatic Whether the function is static
     * @param documentation Optional documentation string
     * @param body Optional function body
     * @return Generated function string
     */
    public function printFunction(funcName: String, args: Array<String>, returnType: String, isStatic: Bool, ?documentation: String, ?body: String): String {
        var elixirFuncName = NamingHelper.getElixirFunctionName(funcName);
        var result = "";
        
        // Add type specification
        var paramTypes = args.map(arg -> "any()"); // Default - will be enhanced with actual type mapping
        result += FormatHelper.formatSpec(elixirFuncName, paramTypes, returnType, 1) + '\n';
        
        // Add documentation
        var docString = documentation ?? 'Generated function ${funcName}';
        result += FormatHelper.formatDoc(docString, false, 1) + '\n';
        
        // Add function definition
        var paramStr = FormatHelper.formatParams(args, args.length > 4);
        var funcDef = 'def ${elixirFuncName}(${paramStr})';
        result += FormatHelper.indent(funcDef, 1);
        
        // Add function body
        var funcBody = body ?? '# TODO: Implement function body\n:ok';
        result += ' do\n';
        result += FormatHelper.indentLines(funcBody, 2) + '\n';
        result += FormatHelper.indent('end', 1) + '\n\n';
        
        return result;
    }
    
    /**
     * Print an expression with Elixir formatting
     * @param expr The expression to print
     * @param context Optional context information
     * @return Formatted expression string
     */
    public function printExpression(expr: String, ?context: ExpressionContext): String {
        if (context?.isElixirNative == true) {
            // Already valid Elixir syntax
            return expr;
        }
        
        // Apply basic transformations for common patterns
        var result = expr;
        
        // Convert common Haxe patterns to Elixir equivalents
        result = StringTools.replace(result, "null", "nil");
        result = StringTools.replace(result, "true", "true");
        result = StringTools.replace(result, "false", "false");
        
        return result;
    }
    
    /**
     * Print a list/array expression
     * @param elements Array of element expressions
     * @param multiline Whether to format as multiline
     * @return Formatted list expression
     */
    public function printList(elements: Array<String>, multiline: Bool = false): String {
        if (elements.length == 0) {
            return "[]";
        }
        
        if (multiline && elements.length > 3) {
            return "[\n" + elements.map(elem -> FormatHelper.indent(elem, 1)).join(",\n") + "\n]";
        } else {
            return "[" + elements.join(", ") + "]";
        }
    }
    
    /**
     * Print a map/object expression
     * @param pairs Array of key-value pairs
     * @param multiline Whether to format as multiline
     * @return Formatted map expression
     */
    public function printMap(pairs: Array<{key: String, value: String}>, multiline: Bool = false): String {
        if (pairs.length == 0) {
            return "%{}";
        }
        
        var pairStrings = pairs.map(pair -> '${pair.key}: ${pair.value}');
        
        if (multiline && pairs.length > 2) {
            return "%{\n" + pairStrings.map(pair -> FormatHelper.indent(pair, 1)).join(",\n") + "\n}";
        } else {
            return "%{" + pairStrings.join(", ") + "}";
        }
    }
    
    /**
     * Print a function call expression
     * @param funcName The function name
     * @param args Array of argument expressions
     * @param isModuleCall Whether this is a module function call
     * @return Formatted function call
     */
    public function printFunctionCall(funcName: String, args: Array<String>, isModuleCall: Bool = false): String {
        var argStr = args.length > 4 
            ? "\n" + args.map(arg -> FormatHelper.indent(arg, 1)).join(",\n") + "\n"
            : args.join(", ");
            
        return '${funcName}(${argStr})';
    }
    
    /**
     * Print a type specification
     * @param haxeType The Haxe type name
     * @return Elixir type specification
     */
    public function printType(haxeType: String): String {
        // Basic type mapping for GREEN phase
        return switch (haxeType) {
            case "String": "String.t()";
            case "Int": "integer()";
            case "Float": "float()";
            case "Bool": "boolean()";
            case "Void": "nil";
            case _: "any()";
        }
    }
    
    /**
     * Format module documentation
     * @param docString The documentation string
     * @return Formatted @moduledoc
     */
    public function formatModuleDoc(docString: String): String {
        return '  @moduledoc """\n  ${docString}\n  """';
    }
    
    /**
     * Format function documentation
     * @param docString The documentation string
     * @return Formatted @doc
     */
    public function formatFunctionDoc(docString: String): String {
        return FormatHelper.formatDoc(docString, false, 1) + '\n';
    }
    
    /**
     * Print struct definition for class variables
     * @param varFields Array of variable fields
     * @return Generated defstruct string
     */
    private function printStruct(varFields: Array<Dynamic>): String {
        var result = FormatHelper.indent('defstruct [', 1);
        var fieldNames = [];
        
        // Enhanced field processing (will be improved when we have proper field data)
        for (i in 0...varFields.length) {
            var fieldName = 'field${i}'; // Placeholder - will use actual field data later
            fieldNames.push('${fieldName}: nil');
        }
        
        if (fieldNames.length > 3) {
            // Multi-line format for many fields
            result = FormatHelper.indent('defstruct [', 1) + '\n';
            for (i in 0...fieldNames.length) {
                var fieldName = fieldNames[i];
                var comma = (i < fieldNames.length - 1) ? ',' : '';
                result += FormatHelper.indent('${fieldName}${comma}', 2) + '\n';
            }
            result += FormatHelper.indent(']', 1) + '\n\n';
        } else {
            // Single-line format for few fields
            result += fieldNames.join(', ') + ']\n\n';
        }
        
        return result;
    }
    
    /**
     * Check if class has instance variables (non-static fields)
     * @param varFields Array of variable fields
     * @return True if has instance variables
     */
    private function hasInstanceVars(varFields: Array<Dynamic>): Bool {
        // For now, assume any variables are instance variables
        // This will be enhanced when we have proper field data structures
        return varFields.length > 0;
    }
    
    /**
     * Print type specification for a class
     * @param className The class name
     * @param varFields The variable fields for type info
     * @return Generated @type specification
     */
    private function printTypeSpec(className: String, varFields: Array<Dynamic>): String {
        var typeName = NamingHelper.toSnakeCase(className);
        var result = FormatHelper.indent('@type t() :: %__MODULE__{', 1) + '\n';
        
        // Add field type specifications
        for (i in 0...varFields.length) {
            var fieldName = 'field${i}'; // Placeholder
            var fieldType = 'any()'; // Default type
            var comma = (i < varFields.length - 1) ? ',' : '';
            result += FormatHelper.indent('${fieldName}: ${fieldType}${comma}', 2) + '\n';
        }
        
        result += FormatHelper.indent('}', 1) + '\n\n';
        return result;
    }
    
    /**
     * Print function from structured data
     * @param funcData The function data (placeholder for now)
     * @param isStatic Whether the function is static
     * @return Generated function string
     */
    private function printFunctionFromData(funcData: Dynamic, isStatic: Bool): String {
        // This is a placeholder implementation - will be enhanced when we have proper function data
        return printFunction("example_function", [], "any()", isStatic);
    }
}

#end