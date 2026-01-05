package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

typedef ModuleFunction = {
    name: String,
    args: Array<String>,
    body: String,
    isPrivate: Bool
};

typedef ModuleData = {
    name: String,
    imports: Array<String>,
    functions: Array<ModuleFunction>
};

/**
 * @:module macro for eliminating public static boilerplate
 * Provides Elixir-like function syntax with automatic static modifier addition
 * Enables cleaner code generation and module-level organization
 */
class ModuleMacro {
    static inline function isFastBoot(): Bool {
        #if macro
        return haxe.macro.Context.defined("fast_boot");
        #else
        return false;
        #end
    }
    
    /**
     * Main build macro that processes @:module annotation
     * Transforms class functions to eliminate public static boilerplate
     */
    @:build
    public static macro function build(): Array<Field> {
        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        var __classPos: haxe.macro.Expr.Position = Context.currentPos();
        #end
        // Prefer cheap metadata checks before touching fields
        var classType = Context.getLocalClass().get();
        if (!hasModuleAnnotation(classType)) {
            return Context.getBuildFields();
        }
        // Under fast_boot we still honor @:module, but keep work minimal
        var fields = Context.getBuildFields();
        
        // Transform all functions to add public static automatically
        for (field in fields) {
            switch (field.kind) {
                case FFun(func):
                    // Add public access if not specified
                    if (field.access == null) {
                        field.access = [APublic, AStatic];
                    } else if (!hasAccess(field.access, APublic)) {
                        field.access.push(APublic);
                    }
                    if (!hasAccess(field.access, AStatic)) {
                        field.access.push(AStatic);
                    }
                    
                    // Handle @:private annotation for defp generation
                    if (hasPrivateAnnotation(field)) {
                        // Mark for defp generation in compiler
                        field.access = [APrivate, AStatic];
                    }
                    
                case _:
                    // Non-function fields are not modified
            }
        }

        #if hxx_instrument_sys
        var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
        Sys.println('[MacroTiming] name=ModuleMacro.build fields=' + fields.length + ' elapsed_ms=' + Std.int(__elapsed));
        #end

        return fields;
    }
    
    /**
     * Process module annotation and generate basic module structure
     */
    public static function processModuleAnnotation(moduleName: String, imports: Array<String>): String {
        if (moduleName == null || moduleName.trim() == "") {
            throw "Module name cannot be null or empty";
        }
        
        // Validate module name follows Elixir conventions
        if (!isValidElixirModuleName(moduleName)) {
            throw 'Invalid Elixir module name: ${moduleName}. Must start with uppercase letter.';
        }
        
        var result = 'defmodule ${moduleName} do\n';
        
        // Add imports/aliases with validation
        if (imports != null) {
            for (imp in imports) {
                if (imp != null && imp.trim() != "") {
                    result += '  alias Elixir.${imp}\n';
                }
            }
            
            if (imports.length > 0) {
                result += '\n';
            }
        }
        
        result += 'end\n';
        return result;
    }
    
    /**
     * Process module functions and generate def/defp syntax
     */
    public static function processModuleFunctions(functions: Array<ModuleFunction>): String {
        var result = "";
        
        for (func in functions) {
            var defKeyword = func.isPrivate ? "defp" : "def";
            var argsList = func.args.join(", ");
            
            result += '  ${defKeyword} ${func.name}(${argsList}) do\n';
            result += '    ${func.body}\n';
            result += '  end\n\n';
        }
        
        return result;
    }
    
    /**
     * Process pipe operator expressions (pass through for Elixir compatibility)
     */
    public static function processPipeOperator(expression: String): String {
        // Pipe operators are native in Elixir, so pass through unchanged
        return expression;
    }
    
    /**
     * Process import statements and convert to Elixir aliases
     */
    public static function processImports(imports: Array<String>): String {
        var result = "";
        
        for (imp in imports) {
            result += '  alias Elixir.${imp}\n';
        }
        
        return result;
    }
    
    /**
     * Transform complete module data into Elixir module
     */
    public static function transformModule(moduleData: ModuleData): String {
        var result = 'defmodule ${moduleData.name} do\n';
        
        // Add imports
        if (moduleData.imports.length > 0) {
            result += processImports(moduleData.imports);
            result += '\n';
        }
        
        // Add functions
        result += processModuleFunctions(moduleData.functions);
        
        result += 'end\n';
        return result;
    }
    
    /**
     * @:module annotation for class-level usage
     * Usage: @:module class MyModule { ... }
     */
    public static macro function module(): Expr {
        // This is processed by the build macro
        return macro null;
    }
    
    /**
     * @:private annotation for function-level usage
     * Usage: @:private function helper() { ... }
     */
    public static macro function makePrivate(): Expr {
        // This is processed by the build macro
        return macro null;
    }
    
    // Helper functions for macro processing
    
    /**
     * Check if class has @:module annotation
     */
    private static function hasModuleAnnotation(classType: ClassType): Bool {
        for (meta in classType.meta.get()) {
            if (meta.name == ":module") {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Check if field has @:private annotation
     */
    private static function hasPrivateAnnotation(field: Field): Bool {
        for (meta in field.meta) {
            if (meta.name == ":private") {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Check if field access array contains specific access modifier
     */
    private static function hasAccess(access: Array<Access>, targetAccess: Access): Bool {
        for (acc in access) {
            if (Type.enumEq(acc, targetAccess)) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Validate Elixir module name follows conventions
     */
    private static function isValidElixirModuleName(name: String): Bool {
        if (name == null || name.length == 0) {
            return false;
        }
        
        // Must start with uppercase letter
        var firstChar = name.charAt(0);
        if (firstChar < "A" || firstChar > "Z") {
            return false;
        }
        
        // Can contain letters, numbers, underscores, and dots for nested modules
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (!isValidModuleNameChar(char)) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Check if character is valid in Elixir module name
     */
    private static function isValidModuleNameChar(char: String): Bool {
        return (char >= "A" && char <= "Z") ||
               (char >= "a" && char <= "z") ||
               (char >= "0" && char <= "9") ||
               char == "_" || char == ".";
    }
}

#end
