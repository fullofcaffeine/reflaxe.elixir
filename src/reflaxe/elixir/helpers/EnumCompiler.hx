package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.data.EnumOptionData;
import reflaxe.elixir.ElixirTyper;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.FormatHelper;
import reflaxe.elixir.helpers.AlgebraicDataTypeCompiler;

using StringTools;

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
    public function compileEnum(enumType: EnumType, options: Array<EnumOptionData>): String {
        if (enumType == null || options == null) return "";
        
        var enumName = NamingHelper.getElixirModuleName(enumType.name);
        var result = new StringBuf();
        
        // Module definition with documentation
        result.add('defmodule ${enumName} do\n');
        result.add(generateModuleDoc(enumName, enumType));
        
        // Generate @type definition with proper types
        result.add(generateTypeDefinition(options, enumType));
        
        // Generate constructor functions  
        for (option in options) {
            result.add(generateConstructorFunction(option, enumType));
        }
        
        // Generate utility functions
        result.add(generateUtilityFunctions(options, enumType));
        
        result.add('end\n');
        
        return result.toString();
    }
    
    /**
     * Generate module documentation
     */
    private function generateModuleDoc(enumName: String, enumType: EnumType): String {
        var result = new StringBuf();
        result.add('  @moduledoc """\n');
        result.add('  ${enumName} enum generated from Haxe\n');
        
        // EnumType.doc field access
        if (enumType.doc != null && enumType.doc.length > 0) {
            result.add('  \n');
            // Ensure proper indentation for heredoc content
            var docLines = enumType.doc.split('\n');
            for (line in docLines) {
                result.add('  ${line}\n');
            }
        }
        
        result.add('  \n');
        result.add('  This module provides tagged tuple constructors and pattern matching helpers.\n');
        result.add('  """\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate @type definition with proper ElixirTyper integration
     */
    private function generateTypeDefinition(options: Array<EnumOptionData>, enumType: EnumType): String {
        var result = new StringBuf();
        result.add('  @type t() ::\n');
        
        // Check if this is an Option-like enum that should use idiomatic patterns
        var isOptionLike = AlgebraicDataTypeCompiler.isADTType(enumType);
        var adtConfig = isOptionLike ? AlgebraicDataTypeCompiler.getADTConfig(enumType) : null;
        
        var typeVariants = [];
        for (option in options) {
            var optionName = NamingHelper.toSnakeCase(option.field.name);
            
            if (isOptionLike && adtConfig != null) {
                // Use idiomatic ADT type patterns
                var constructorConfig = adtConfig.constructors.get(optionName);
                if (constructorConfig != null) {
                    if (option.args.length == 0) {
                        // No arguments - use the pattern as-is (e.g., :error)
                        typeVariants.push('    ${constructorConfig.elixirPattern}');
                    } else {
                        // With arguments - substitute term() for the arguments
                        var argTypes = [];
                        for (arg in option.args) {
                            var haxeType = getArgType(arg);
                            var elixirType = typer.compileType(haxeType);
                            argTypes.push(elixirType);
                        }
                        var argTypeStr = argTypes.join(', ');
                        var typePattern = constructorConfig.elixirPattern.replace("%s", argTypeStr);
                        typeVariants.push('    ${typePattern}');
                    }
                } else {
                    // Fallback to default patterns
                    if (option.args.length == 0) {
                        typeVariants.push('    :${optionName}');
                    } else {
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
            } else {
                // Default enum patterns
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
        }
        
        result.add(typeVariants.join(' |\n'));
        result.add('\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate constructor function for an enum option
     */
    private function generateConstructorFunction(option: Dynamic, enumType: EnumType): String {
        var result = new StringBuf();
        var optionName = NamingHelper.toSnakeCase(option.field.name);
        var originalName = option.field.name;
        
        // Check if this is an Option-like enum that should use idiomatic patterns
        var isOptionLike = AlgebraicDataTypeCompiler.isADTType(enumType);
        var adtConfig = isOptionLike ? AlgebraicDataTypeCompiler.getADTConfig(enumType) : null;
        
        if (option.args.length == 0) {
            // Simple enum constructor returning atom
            if (isOptionLike && adtConfig != null) {
                // Use idiomatic ADT pattern (e.g., :error for None)
                var constructorConfig = adtConfig.constructors.get(optionName);
                if (constructorConfig != null) {
                    var pattern = constructorConfig.elixirPattern;
                    result.add('  @doc "Creates ${optionName} enum value"\n');
                    result.add('  @spec ${optionName}() :: ${pattern}\n');
                    result.add('  def ${optionName}(), do: ${pattern}\n\n');
                } else {
                    // Fallback to default pattern
                    result.add('  @doc "Creates ${optionName} enum value"\n');
                    result.add('  @spec ${optionName}() :: :${optionName}\n');
                    result.add('  def ${optionName}(), do: :${optionName}\n\n');
                }
            } else {
                // Default enum pattern
                result.add('  @doc "Creates ${optionName} enum value"\n');
                result.add('  @spec ${optionName}() :: :${optionName}\n');
                result.add('  def ${optionName}(), do: :${optionName}\n\n');
            }
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
            if (isOptionLike && adtConfig != null) {
                // Use idiomatic ADT pattern (e.g., {:ok, value} for Some)
                var constructorConfig = adtConfig.constructors.get(optionName);
                if (constructorConfig != null) {
                    var pattern = constructorConfig.elixirPattern.replace("%s", paramStr);
                    var returnType = constructorConfig.elixirPattern.replace("%s", typeStr);
                    result.add('  @spec ${optionName}(${typeStr}) :: ${returnType}\n');
                    result.add('  def ${optionName}(${paramStr}) do\n');
                    result.add('    ${pattern}\n');
                    result.add('  end\n\n');
                } else {
                    // Fallback to default pattern
                    result.add('  @spec ${optionName}(${typeStr}) :: {:${optionName}, ${typeStr}}\n');
                    result.add('  def ${optionName}(${paramStr}) do\n');
                    result.add('    {:${optionName}, ${paramStr}}\n');
                    result.add('  end\n\n');
                }
            } else {
                // Default enum pattern
                result.add('  @spec ${optionName}(${typeStr}) :: {:${optionName}, ${typeStr}}\n');
                result.add('  def ${optionName}(${paramStr}) do\n');
                result.add('    {:${optionName}, ${paramStr}}\n');
                result.add('  end\n\n');
            }
        }
        
        return result.toString();
    }
    
    /**
     * Generate utility functions for pattern matching and introspection
     */
    private function generateUtilityFunctions(options: Array<EnumOptionData>, enumType: EnumType): String {
        var result = new StringBuf();
        
        // Check if this is an Option-like enum that should use idiomatic patterns
        var isOptionLike = AlgebraicDataTypeCompiler.isADTType(enumType);
        var adtConfig = isOptionLike ? AlgebraicDataTypeCompiler.getADTConfig(enumType) : null;
        
        // is_* predicate functions for each variant
        result.add('  # Predicate functions for pattern matching\n');
        for (option in options) {
            var optionName = NamingHelper.toSnakeCase(option.field.name);
            
            result.add('  @doc "Returns true if value is ${optionName} variant"\n');
            result.add('  @spec is_${optionName}(t()) :: boolean()\n');
            
            if (isOptionLike && adtConfig != null) {
                // Use idiomatic ADT patterns for predicate functions
                var constructorConfig = adtConfig.constructors.get(optionName);
                if (constructorConfig != null) {
                    if (constructorConfig.isAtom) {
                        // Atom patterns like :error
                        result.add('  def is_${optionName}(${constructorConfig.elixirPattern}), do: true\n');
                    } else {
                        // Tuple patterns like {:ok, _}
                        var pattern = constructorConfig.elixirPattern.replace("%s", "_");
                        result.add('  def is_${optionName}(${pattern}), do: true\n');
                    }
                } else {
                    // Fallback to default patterns
                    if (option.args.length == 0) {
                        result.add('  def is_${optionName}(:${optionName}), do: true\n');
                    } else {
                        result.add('  def is_${optionName}({:${optionName}, _}), do: true\n');
                    }
                }
            } else {
                // Default enum patterns
                if (option.args.length == 0) {
                    result.add('  def is_${optionName}(:${optionName}), do: true\n');
                } else {
                    result.add('  def is_${optionName}({:${optionName}, _}), do: true\n');
                }
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
                
                if (isOptionLike && adtConfig != null) {
                    // Use idiomatic ADT patterns for extraction functions
                    var constructorConfig = adtConfig.constructors.get(optionName);
                    if (constructorConfig != null && !constructorConfig.isAtom) {
                        if (option.args.length == 1) {
                            var pattern = constructorConfig.elixirPattern.replace("%s", "value");
                            result.add('  def get_${optionName}_value(${pattern}), do: {:ok, value}\n');
                        } else {
                            var argPattern = [];
                            for (i in 0...option.args.length) {
                                argPattern.push('arg${i}');
                            }
                            var pattern = constructorConfig.elixirPattern.replace("%s", argPattern.join(', '));
                            result.add('  def get_${optionName}_value(${pattern}), do: {:ok, {${argPattern.join(', ')}}}\n');
                        }
                    } else {
                        // Fallback to default patterns
                        if (option.args.length == 1) {
                            result.add('  def get_${optionName}_value({:${optionName}, value}), do: {:ok, value}\n');
                        } else {
                            var argPattern = [];
                            for (i in 0...option.args.length) {
                                argPattern.push('arg${i}');
                            }
                            result.add('  def get_${optionName}_value({:${optionName}, ${argPattern.join(', ')}}), do: {:ok, {${argPattern.join(', ')}}}\n');
                        }
                    }
                } else {
                    // Default enum patterns
                    if (option.args.length == 1) {
                        result.add('  def get_${optionName}_value({:${optionName}, value}), do: {:ok, value}\n');
                    } else {
                        var argPattern = [];
                        for (i in 0...option.args.length) {
                            argPattern.push('arg${i}');
                        }
                        result.add('  def get_${optionName}_value({:${optionName}, ${argPattern.join(', ')}}), do: {:ok, {${argPattern.join(', ')}}}\n');
                    }
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