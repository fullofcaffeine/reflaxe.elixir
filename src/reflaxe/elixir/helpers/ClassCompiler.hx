package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.ClassType;
import haxe.macro.Type.ClassField;
import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassFuncArg;
import reflaxe.data.ClassVarData;
import reflaxe.elixir.ElixirTyper;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.FormatHelper;
import reflaxe.elixir.helpers.AnnotationSystem;
import reflaxe.elixir.PhoenixMapper;

using StringTools;

/**
 * ClassCompiler - Helper for class→struct/module compilation
 * Handles both @:struct classes (defstruct) and regular classes (module with functions)
 */
class ClassCompiler {
    
    private var typer: ElixirTyper;
    private var compiler: Null<reflaxe.elixir.ElixirCompiler> = null;
    private var currentClassName: Null<String> = null;
    
    public function new(?typer: ElixirTyper) {
        this.typer = (typer != null) ? typer : new ElixirTyper();
    }
    
    public function setCompiler(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Compile class to Elixir module with struct or functions
     * @param classType The class type information
     * @param varFields Array of class variables
     * @param funcFields Array of class functions
     * @return Generated Elixir module code
     */
    public function compileClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        if (classType == null) return "";
        
        // Check for @:native annotation to override module name
        var className = getNativeModuleName(classType);
        if (className == null) {
            className = NamingHelper.getElixirModuleName(classType.name);
        }
        this.currentClassName = className;
        var isStruct = hasStructMetadata(classType);
        var isModule = hasModuleMetadata(classType);
        var isApplication = hasApplicationMetadata(classType);
        var isInterface = classType.isInterface;
        var result = new StringBuf();
        
        // For interfaces, compile as behavior definition
        if (isInterface) {
            return compileInterface(classType, funcFields);
        }
        
        // Note: @:application classes are now compiled normally, 
        // with app name replacement handled in post-processing
        
        // Module definition
        result.add('defmodule ${className} do\n');
        
        // Add Application use statement for @:application classes
        if (isApplication) {
            result.add('  @moduledoc false\n\n');
            result.add('  use Application\n\n');
        } else {
            // Add use Bitwise for bitwise operators if needed
            // TODO: Only add this if the module actually uses bitwise operations
            result.add('  use Bitwise\n');
        }
        
        // Add @behaviour annotations for implemented interfaces
        if (classType.interfaces != null && classType.interfaces.length > 0) {
            for (interfaceRef in classType.interfaces) {
                var interfaceName = NamingHelper.getElixirModuleName(interfaceRef.t.get().name);
                result.add('  @behaviour ${interfaceName}\n');
            }
            result.add('\n');
        }
        
        // Add Phoenix-specific use statements
        if (PhoenixMapper.isPhoenixContext(classType)) {
            result.add('  @moduledoc """\n');
            result.add('  The ${PhoenixMapper.getPhoenixContextName(classType)} context\n');
            result.add('  """\n\n');
            result.add('  import Ecto.Query, warn: false\n');
            result.add('  alias ${PhoenixMapper.getRepoModuleName()}\n\n');
        } else if (PhoenixMapper.isPhoenixController(classType)) {
            result.add('  use ${PhoenixMapper.getAppModuleName()}Web, :controller\n\n');
        } else if (PhoenixMapper.isPhoenixLiveView(classType)) {
            result.add('  use ${PhoenixMapper.getAppModuleName()}Web, :live_view\n\n');
            result.add('  alias Phoenix.LiveView.Socket\n\n');
        } else if (hasSchemaMetadata(classType)) {
            result.add('  use Ecto.Schema\n');
            result.add('  import Ecto.Changeset\n\n');
        }
        
        // Module documentation (skip for Phoenix contexts as they generate their own)
        if (!PhoenixMapper.isPhoenixContext(classType)) {
            result.add(generateModuleDoc(className, classType, isStruct));
        }
        
        if (isStruct && varFields != null && varFields.length > 0) {
            // Generate defstruct and @type for struct classes
            result.add(generateDefstruct(varFields));
            result.add(generateStructType(className, varFields));
            
            // Generate constructor functions
            result.add(generateConstructors(className, varFields, funcFields));
        }
        
        // Generate functions (both static and instance)
        if (funcFields != null && funcFields.length > 0) {
            if (isModule) {
                result.add(generateModuleFunctions(funcFields));
            } else {
                result.add(generateFunctions(funcFields, isStruct));
            }
        }
        
        result.add('end\n');
        
        return result.toString();
    }
    
    /**
     * Check if class has @:struct metadata
     */
    private function hasStructMetadata(classType: ClassType): Bool {
        if (classType.meta == null) return false;
        
        var metaEntries = classType.meta.extract(":struct");
        return metaEntries.length > 0;
    }
    
    /**
     * Check if class has @:module metadata
     */
    private function hasModuleMetadata(classType: ClassType): Bool {
        if (classType.meta == null) return false;
        
        var metaEntries = classType.meta.extract(":module");
        return metaEntries.length > 0;
    }
    
    /**
     * Check if class has @:schema metadata (for Ecto schemas)
     */
    private function hasSchemaMetadata(classType: ClassType): Bool {
        if (classType.meta == null) return false;
        
        var metaEntries = classType.meta.extract(":schema");
        return metaEntries.length > 0;
    }
    
    /**
     * Get native module name from @:native annotation
     */
    private function getNativeModuleName(classType: ClassType): Null<String> {
        if (classType.meta == null) return null;
        
        var metaEntries = classType.meta.extract(":native");
        if (metaEntries.length > 0) {
            var meta = metaEntries[0];
            if (meta.params != null && meta.params.length > 0) {
                // Extract module name from first parameter
                var param = meta.params[0];
                
                // Handle Haxe expression types to extract string values
                return switch(param.expr) {
                    case EConst(CString(s, _)): s; // String literal like "TodoAppWeb.Router"
                    case EConst(CIdent(s)): s;     // Identifier
                    case _: 
                        // Fallback - use Std.string but remove quotes
                        var str = Std.string(param);
                        if (str.indexOf('"') == 0 && str.lastIndexOf('"') == str.length - 1) {
                            str.substring(1, str.length - 1);
                        } else {
                            str;
                        }
                }
            }
        }
        return null;
    }
    
    /**
     * Get schema table name from @:schema metadata
     */
    private function getSchemaTable(classType: ClassType): Null<String> {
        if (classType.meta == null) return null;
        
        var metaEntries = classType.meta.extract(":schema");
        if (metaEntries.length > 0) {
            var meta = metaEntries[0];
            if (meta.params != null && meta.params.length > 0) {
                // Extract table name from first parameter
                return Std.string(meta.params[0]);
            }
        }
        return null;
    }
    
    /**
     * Generate module documentation
     */
    private function generateModuleDoc(className: String, classType: Dynamic, isStruct: Bool): String {
        var result = new StringBuf();
        result.add('  @moduledoc """\n');
        result.add('  ${className} ');
        result.add(isStruct ? 'struct' : 'module');
        result.add(' generated from Haxe\n');
        
        if (classType.doc != null) {
            result.add('  \n');
            result.add('  ${classType.doc}\n');
        }
        
        if (isStruct) {
            result.add('  \n');
            result.add('  This module defines a struct with typed fields and constructor functions.\n');
        }
        
        result.add('  """\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate defstruct definition
     */
    private function generateDefstruct(varFields: Array<ClassVarData>): String {
        var result = new StringBuf();
        result.add('  defstruct [');
        
        var fields = [];
        for (field in varFields) {
            var fieldName = NamingHelper.toSnakeCase(field.field.name);
            
            // Check if field has default value
            if (field.hasDefaultValue()) {
                // Extract default value - this is simplified
                var defaultValue = getDefaultValue(field);
                fields.push('${fieldName}: ${defaultValue}');
            } else {
                fields.push(':${fieldName}');
            }
        }
        
        result.add(fields.join(', '));
        result.add(']\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate @type definition for struct
     */
    private function generateStructType(className: String, varFields: Array<ClassVarData>): String {
        var result = new StringBuf();
        result.add('  @type t() :: %__MODULE__{\n');
        
        for (i in 0...varFields.length) {
            var field = varFields[i];
            var fieldName = NamingHelper.toSnakeCase(field.field.name);
            var fieldType = getFieldType(field);
            var elixirType = typer.compileType(fieldType);
            
            // Handle nullable types with default nil
            if (!field.hasDefaultValue() && fieldType.indexOf("Null<") != 0) {
                elixirType = '${elixirType} | nil';
            }
            
            var comma = (i < varFields.length - 1) ? ',' : '';
            result.add('    ${fieldName}: ${elixirType}${comma}\n');
        }
        
        result.add('  }\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate constructor functions (new/N)
     */
    private function generateConstructors(className: String, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var result = new StringBuf();
        
        // Find "new" function in funcFields
        var newFunc = null;
        for (func in funcFields) {
            if (func.field.name == "new") {
                newFunc = func;
                break;
            }
        }
        
        if (newFunc != null) {
            result.add(generateConstructorFunction(newFunc, varFields));
        } else {
            // Generate default constructor if none provided
            result.add(generateDefaultConstructor(varFields));
        }
        
        // Generate update functions for struct manipulation
        result.add(generateUpdateHelpers());
        
        return result.toString();
    }
    
    /**
     * Generate constructor function from new method
     */
    private function generateConstructorFunction(newFunc: ClassFuncData, varFields: Array<ClassVarData>): String {
        var result = new StringBuf();
        
        // Generate @spec
        var paramTypes = [];
        if (newFunc.args != null) {
            for (arg in newFunc.args) {
                var argType = getArgType(arg);
                var elixirType = typer.compileType(argType);
                paramTypes.push(elixirType);
            }
        }
        
        var specStr = paramTypes.join(', ');
        
        result.add('  @doc "Creates a new struct instance"\n');
        result.add('  @spec new(${specStr}) :: t()\n');
        result.add('  def new(');
        
        // Parameter names
        var paramNames = [];
        for (i in 0...newFunc.args.length) {
            paramNames.push('arg${i}');
        }
        result.add(paramNames.join(', '));
        result.add(') do\n');
        
        // Build struct initialization
        result.add('    %__MODULE__{\n');
        
        // Map constructor parameters to struct fields
        // This is simplified - real implementation would analyze constructor body
        for (i in 0...Math.floor(Math.min(varFields.length, paramNames.length))) {
            var field = varFields[i];
            var fieldName = NamingHelper.toSnakeCase(field.field.name);
            var paramName = paramNames[i];
            var comma = (i < varFields.length - 1) ? ',' : '';
            result.add('      ${fieldName}: ${paramName}${comma}\n');
        }
        
        result.add('    }\n');
        result.add('  end\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate default constructor if none provided
     */
    private function generateDefaultConstructor(varFields: Array<ClassVarData>): String {
        var result = new StringBuf();
        
        result.add('  @doc "Creates a new struct with default values"\n');
        result.add('  @spec new() :: t()\n');
        result.add('  def new() do\n');
        result.add('    %__MODULE__{}\n');
        result.add('  end\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate struct update helper functions
     */
    private function generateUpdateHelpers(): String {
        var result = new StringBuf();
        
        result.add('  @doc "Updates struct fields using a map of changes"\n');
        result.add('  @spec update(t(), map()) :: t()\n');
        result.add('  def update(struct, changes) when is_map(changes) do\n');
        result.add('    struct |> Map.merge(changes) |> struct(__MODULE__, _1)\n');
        result.add('  end\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate module functions (static and instance)
     */
    private function generateFunctions(funcFields: Array<ClassFuncData>, isStruct: Bool): String {
        var result = new StringBuf();
        
        // Separate static and instance functions
        var staticFuncs = [];
        var instanceFuncs = [];
        
        for (func in funcFields) {
            if (func.field.name == "new") continue; // Skip constructor
            
            if (func.isStatic) {
                staticFuncs.push(func);
            } else {
                instanceFuncs.push(func);
            }
        }
        
        // Generate static functions
        if (staticFuncs.length > 0) {
            result.add('  # Static functions\n');
            for (func in staticFuncs) {
                result.add(generateFunction(func, false, isStruct));
            }
        }
        
        // Generate instance functions
        if (instanceFuncs.length > 0) {
            result.add('  # Instance functions\n');
            for (func in instanceFuncs) {
                result.add(generateFunction(func, true, isStruct));
            }
        }
        
        return result.toString();
    }
    
    /**
     * Generate a single function
     */
    private function generateFunction(funcField: ClassFuncData, isInstance: Bool, isStructClass: Bool): String {
        var result = new StringBuf();
        var funcName = NamingHelper.getElixirFunctionName(funcField.field.name);
        
        // Build parameter list
        var params = [];
        var paramTypes = [];
        
        // Instance methods take struct as first parameter
        if (isInstance && isStructClass) {
            params.push('%__MODULE__{} = struct');
            paramTypes.push('t()');
        }
        
        // Add regular parameters
        if (funcField.args != null) {
            for (i in 0...funcField.args.length) {
                var arg = funcField.args[i];
                // Extract the actual parameter name - try multiple sources
                var originalName = if (arg.tvar != null) {
                    arg.tvar.name;
                } else if (funcField.tfunc != null && funcField.tfunc.args != null && i < funcField.tfunc.args.length) {
                    funcField.tfunc.args[i].v.name;
                } else {
                    arg.getName();
                }
                var paramName = NamingHelper.toSnakeCase(originalName);
                params.push(paramName);
                
                var argType = getArgType(arg);
                var elixirType = typer.compileType(argType);
                paramTypes.push(elixirType);
            }
        }
        
        // Get return type
        var returnType = getReturnType(funcField);
        var elixirReturnType = typer.compileType(returnType);
        
        // Handle struct-returning instance methods (for immutable updates)
        if (isInstance && isStructClass && returnType == classNameFromFunc(funcField)) {
            elixirReturnType = 't()';
        }
        
        // Generate function with @spec
        var paramStr = params.join(', ');
        var typeStr = paramTypes.join(', ');
        
        result.add('  @doc "');
        result.add(funcField.field.doc != null ? funcField.field.doc : 'Function ${funcName}');
        result.add('"\n');
        result.add('  @spec ${funcName}(${typeStr}) :: ${elixirReturnType}\n');
        result.add('  def ${funcName}(${paramStr}) do\n');
        
        // Function body
        if (funcField.expr != null) {
            // Compile the actual function expression
            var compiledBody = compileExpressionForFunction(funcField.expr, funcField.args);
            if (compiledBody != null && compiledBody.trim() != "") {
                // Indent the function body properly
                var indentedBody = compiledBody.split("\n").map(line -> line.length > 0 ? "    " + line : line).join("\n");
                result.add('${indentedBody}\n');
            } else {
                // Only use default return if compilation failed/returned empty
                // For struct update methods, return updated struct
                if (isInstance && isStructClass && elixirReturnType == 't()') {
                    result.add('    %{struct | }\n');
                } else {
                    result.add('    nil\n');
                }
            }
        } else {
            // No expression provided - this is a truly empty function
            result.add('    nil\n');
        }
        
        result.add('  end\n\n');
        
        return result.toString();
    }
    
    /**
     * Extract field type information with proper type name extraction
     */
    private function getFieldType(field: ClassVarData): String {
        if (field.field.type != null) {
            return extractTypeName(field.field.type);
        }
        return "Dynamic";
    }
    
    /**
     * Extract argument type information with proper type name extraction
     */
    private function getArgType(arg: ClassFuncArg): String {
        if (arg.type != null) {
            return extractTypeName(arg.type);
        }
        return "Dynamic";
    }
    
    /**
     * Extract the actual type name from a Haxe Type for use with ElixirTyper
     * Fixes bug where Std.string(type) produces "TDynamic(null)" instead of "Dynamic"
     */
    private function extractTypeName(type: Type): String {
        return switch(type) {
            case TDynamic(_): "Dynamic";
            case TInst(_.get() => c, params): c.name;
            case TAbstract(_.get() => a, params): a.name;
            case TEnum(_.get() => e, params): e.name;
            case TType(_.get() => t, params): t.name;
            case TFun(args, ret): "Function"; // Could be improved to generate proper function types
            case TMono(_.get() => t): t != null ? extractTypeName(t) : "Dynamic";
            case TLazy(f): extractTypeName(f());
            case TAnonymous(_): "Dynamic"; // Anonymous objects  
            case _: "Dynamic"; // Fallback for any other types
        }
    }
    
    /**
     * Generate functions for @:module classes with clean syntax
     * Handles automatic public static addition and @:private annotations
     */
    private function generateModuleFunctions(funcFields: Array<ClassFuncData>): String {
        var result = new StringBuf();
        
        result.add('  # Module functions - generated with @:module syntax sugar\n\n');
        
        for (func in funcFields) {
            if (func.field.name == "new") continue; // Skip constructor
            
            var funcName = NamingHelper.toSnakeCase(func.field.name);
            var isPrivate = hasPrivateAnnotation(func.field);
            
            // Generate function parameters
            var params = [];
            var paramTypes = [];
            
            if (func.args != null) {
                for (i in 0...func.args.length) {
                    var arg = func.args[i];
                    // Extract the actual parameter name - try multiple sources
                    var originalName = if (arg.tvar != null) {
                        arg.tvar.name;
                    } else if (func.tfunc != null && func.tfunc.args != null && i < func.tfunc.args.length) {
                        func.tfunc.args[i].v.name;
                    } else {
                        arg.getName();
                    }
                    var argName = NamingHelper.toSnakeCase(originalName);
                    params.push(argName);
                    
                    var argType = getArgType(arg);
                    var elixirType = typer.compileType(argType);
                    paramTypes.push(elixirType);
                }
            }
            
            // Generate function with clean @:module syntax
            var defKeyword = isPrivate ? "defp" : "def";
            var paramStr = params.join(', ');
            var typeStr = paramTypes.join(', ');
            
            // Get return type
            var returnType = func.ret != null ? extractTypeName(func.ret) : "any()";
            var elixirReturnType = typer.compileType(returnType);
            
            // Add documentation
            result.add('  @doc "');
            result.add(func.field.doc != null ? func.field.doc : 'Function ${funcName}');
            result.add('"\n');
            
            // Add spec only for public functions
            if (!isPrivate) {
                result.add('  @spec ${funcName}(${typeStr}) :: ${elixirReturnType}\n');
            }
            
            result.add('  ${defKeyword} ${funcName}(${paramStr}) do\n');
            
            // Function body - compile the actual expression
            if (func.expr != null) {
                var compiledBody = compileExpressionForFunction(func.expr, func.args);
                if (compiledBody != null && compiledBody.trim() != "") {
                    // Indent the function body properly
                    var indentedBody = compiledBody.split("\n").map(line -> line.length > 0 ? "    " + line : line).join("\n");
                    result.add('${indentedBody}\n');
                } else {
                    // Only use nil if compilation actually failed/returned empty
                    result.add('    nil\n');
                }
            } else {
                result.add('    nil\n');
            }
            
            result.add('  end\n\n');
        }
        
        return result.toString();
    }
    
    /**
     * Check if function field has @:private annotation
     */
    private function hasPrivateAnnotation(field: ClassField): Bool {
        if (field.meta == null) return false;
        
        var metaEntries = field.meta.extract(":private");
        return metaEntries.length > 0;
    }
    
    /**
     * Extract return type information with proper type name extraction
     */
    private function getReturnType(funcField: ClassFuncData): String {
        if (funcField.ret != null) {
            return extractTypeName(funcField.ret);
        }
        return "Dynamic";
    }
    
    /**
     * Get class name from function context
     */
    private function classNameFromFunc(funcField: Dynamic): String {
        // This would need to be passed in or derived from context
        return "Dynamic";
    }
    
    /**
     * Extract default value for field
     */
    private function getDefaultValue(field: ClassVarData): String {
        // Simplified - real implementation would analyze the expression
        var fieldType = getFieldType(field);
        
        return switch(fieldType) {
            case "Bool": "true";
            case "Int": "0";
            case "Float": "0.0";
            case "String": '""';
            case _: "nil";
        }
    }
    
    /**
     * Compile expression for function body with parameter mapping
     */
    private function compileExpressionForFunction(expr: Dynamic, args: Array<ClassFuncArg>): Null<String> {
        if (compiler != null) {
            // Always set up parameter mapping when we generate standardized arg names
            // This ensures TLocal variables in the function body use the correct parameter names
            if (args != null && args.length > 0) {
                compiler.setFunctionParameterMapping(args);
            }
            
            var result = compiler.compileExpression(expr);
            
            // Clear parameter mapping
            if (args != null && args.length > 0) {
                compiler.clearFunctionParameterMapping();
            }
            
            return result;
        }
        return null;
    }
    
    /**
     * Check if we're currently compiling an abstract implementation class
     */
    private function checkIfAbstractImplementationClass(): Bool {
        // Abstract implementation classes have names ending with "_Impl_"
        // We need to track the current class context for this determination
        return currentClassName != null && currentClassName.endsWith("_Impl_");
    }
    
    /**
     * Check if this is an abstract type implementation method (deprecated)
     */
    private function checkIfAbstractImplementationMethod(expr: Dynamic): Bool {
        return false; // Deprecated - use checkIfAbstractImplementationClass instead
    }
    
    /**
     * Check if class has @:application metadata
     */
    private function hasApplicationMetadata(classType: ClassType): Bool {
        if (classType.meta == null) return false;
        return classType.meta.has(":application");
    }
    
    
    /**
     * Compile interface to Elixir behavior
     */
    private function compileInterface(classType: ClassType, funcFields: Array<ClassFuncData>): String {
        var className = NamingHelper.getElixirModuleName(classType.name);
        var result = new StringBuf();
        
        result.add('defmodule ${className} do\n');
        result.add('  @moduledoc """\n');
        result.add('  ${className} behavior generated from Haxe interface\n');
        if (classType.doc != null) {
            result.add('  \n');
            result.add('  ${classType.doc}\n');
        }
        result.add('  """\n\n');
        
        // Generate @callback specifications for each interface method
        for (func in funcFields) {
            var funcName = NamingHelper.getElixirFunctionName(func.field.name);
            var params = [];
            var paramTypes = [];
            
            // Generate parameter list and types
            if (func.args != null) {
                for (i in 0...func.args.length) {
                    var arg = func.args[i];
                    params.push('arg${i}');
                    
                    // Get parameter type using ElixirTyper
                    var argType = arg.type != null ? extractTypeName(arg.type) : "Dynamic";
                    var elixirType = typer.compileType(argType);
                    paramTypes.push(elixirType);
                }
            }
            
            // Get return type using ElixirTyper
            var returnType = func.ret != null ? extractTypeName(func.ret) : "Dynamic";
            var elixirReturnType = typer.compileType(returnType);
            
            // Generate @callback
            if (paramTypes.length > 0) {
                result.add('  @callback ${funcName}(${paramTypes.join(", ")}) :: ${elixirReturnType}\n');
            } else {
                result.add('  @callback ${funcName}() :: ${elixirReturnType}\n');
            }
        }
        
        result.add('end\n');
        
        return result.toString();
    }
}

#end