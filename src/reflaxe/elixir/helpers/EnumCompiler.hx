package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ElixirTyper;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.FormatHelper;

/**
 * EnumCompiler - Helper for enum→tagged tuple compilation
 * Handles both simple enums (atoms) and parameterized enums (tagged tuples)
 */
class EnumCompiler {
    
    private var typer: ElixirTyper;
    
    public function new(?typer: ElixirTyper) {
        this.typer = (typer != null) ? typer : new ElixirTyper();
    }
    
    /**
     * Compile enum to Elixir module with proper type definitions
     * @param enumType The enum type information
     * @param options Array of enum options/constructors
     * @return Generated Elixir module code
     */
    public function compileEnum(enumType: Dynamic, options: Array<Dynamic>): String {
        if (enumType == null || options == null) return "";
        
        var enumName = NamingHelper.getElixirModuleName(enumType.getNameOrNative());
        var result = new StringBuf();
        
        // Module definition with documentation
        result.add('defmodule ${enumName} do\n');
        result.add(generateModuleDoc(enumName, enumType));
        
        // Generate @type definition with proper types
        result.add(generateTypeDefinition(options));
        
        // Generate constructor functions
        for (option in options) {
            result.add(generateConstructorFunction(option));
        }
        
        // Generate utility functions
        result.add(generateUtilityFunctions(options));
        
        result.add('end\n');
        
        return result.toString();
    }
    
    /**
     * Generate module documentation
     */
    private function generateModuleDoc(enumName: String, enumType: Dynamic): String {
        var result = new StringBuf();
        result.add('  @moduledoc """\n');
        result.add('  ${enumName} enum generated from Haxe\n');
        
        if (enumType.doc != null) {
            result.add('  \n');
            result.add('  ${enumType.doc}\n');
        }
        
        result.add('  \n');
        result.add('  This module provides tagged tuple constructors and pattern matching helpers.\n');
        result.add('  """\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate @type definition with proper ElixirTyper integration
     */
    private function generateTypeDefinition(options: Array<Dynamic>): String {
        var result = new StringBuf();
        result.add('  @type t() ::\n');
        
        var typeVariants = [];
        for (option in options) {
            var optionName = NamingHelper.toSnakeCase(option.field.name);
            
            if (option.args.length == 0) {
                // Simple enum → atom
                typeVariants.push('    :${optionName}');
            } else {
                // Parameterized enum → tagged tuple with proper types
                var argTypes = [];
                for (arg in option.args) {
                    var haxeType = getArgType(arg);
                    var elixirType = typer.compileType(haxeType);
                    argTypes.push(elixirType);
                }
                var argTypeStr = argTypes.join(', ');
                typeVariants.push('    {:${optionName}, ${argTypeStr}}');
            }
        }
        
        result.add(typeVariants.join(' |\n'));
        result.add('\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate constructor function for an enum option
     */
    private function generateConstructorFunction(option: Dynamic): String {
        var result = new StringBuf();
        var optionName = NamingHelper.toSnakeCase(option.field.name);
        var originalName = option.field.name;
        
        if (option.args.length == 0) {
            // Simple enum constructor returning atom
            result.add('  @doc "Creates ${optionName} enum value"\n');
            result.add('  @spec ${optionName}() :: :${optionName}\n');
            result.add('  def ${optionName}(), do: :${optionName}\n\n');
        } else {
            // Parameterized enum constructor with proper type specs
            var params = [];
            var paramTypes = [];
            var paramDocs = [];
            
            for (i in 0...option.args.length) {
                var arg = option.args[i];
                var paramName = 'arg${i}';
                params.push(paramName);
                
                var haxeType = getArgType(arg);
                var elixirType = typer.compileType(haxeType);
                paramTypes.push(elixirType);
                paramDocs.push('  - `${paramName}`: ${elixirType}');
            }
            
            var paramStr = params.join(', ');
            var typeStr = paramTypes.join(', ');
            
            result.add('  @doc """\n');
            result.add('  Creates ${optionName} enum value with parameters\n');
            result.add('  \n');
            result.add('  ## Parameters\n');
            result.add('  ${paramDocs.join('\\n  ')}\n');
            result.add('  """\n');
            result.add('  @spec ${optionName}(${typeStr}) :: {:${optionName}, ${typeStr}}\n');
            result.add('  def ${optionName}(${paramStr}) do\n');
            result.add('    {:${optionName}, ${paramStr}}\n');
            result.add('  end\n\n');
        }
        
        return result.toString();
    }
    
    /**
     * Generate utility functions for pattern matching and introspection
     */
    private function generateUtilityFunctions(options: Array<Dynamic>): String {
        var result = new StringBuf();
        
        // is_* predicate functions for each variant
        result.add('  # Predicate functions for pattern matching\n');
        for (option in options) {
            var optionName = NamingHelper.toSnakeCase(option.field.name);
            
            result.add('  @doc "Returns true if value is ${optionName} variant"\n');
            result.add('  @spec is_${optionName}(t()) :: boolean()\n');
            
            if (option.args.length == 0) {
                result.add('  def is_${optionName}(:${optionName}), do: true\n');
            } else {
                result.add('  def is_${optionName}({:${optionName}, _}), do: true\n');
            }
            result.add('  def is_${optionName}(_), do: false\n\n');
        }
        
        // Value extraction functions for parameterized variants
        for (option in options) {
            if (option.args.length > 0) {
                var optionName = NamingHelper.toSnakeCase(option.field.name);
                
                result.add('  @doc "Extracts value from ${optionName} variant, returns {:ok, value} or :error"\n');
                result.add('  @spec get_${optionName}_value(t()) :: {:ok, ');
                
                if (option.args.length == 1) {
                    var haxeType = getArgType(option.args[0]);
                    var elixirType = typer.compileType(haxeType);
                    result.add('${elixirType}');
                } else {
                    var argTypes = [];
                    for (arg in option.args) {
                        var haxeType = getArgType(arg);
                        var elixirType = typer.compileType(haxeType);
                        argTypes.push(elixirType);
                    }
                    result.add('{${argTypes.join(', ')}}');
                }
                
                result.add('} | :error\n');
                
                if (option.args.length == 1) {
                    result.add('  def get_${optionName}_value({:${optionName}, value}), do: {:ok, value}\n');
                } else {
                    var argPattern = [];
                    for (i in 0...option.args.length) {
                        argPattern.push('arg${i}');
                    }
                    result.add('  def get_${optionName}_value({:${optionName}, ${argPattern.join(', ')}}), do: {:ok, {${argPattern.join(', ')}}}\n');
                }
                result.add('  def get_${optionName}_value(_), do: :error\n\n');
            }
        }
        
        return result.toString();
    }
    
    /**
     * Extract type information from argument, handling various Haxe type formats
     */
    private function getArgType(arg: Dynamic): String {
        if (arg.t != null) {
            return arg.t;
        }
        
        // Fallback - return a more specific type than any()
        return "term()";
    }
}

#end