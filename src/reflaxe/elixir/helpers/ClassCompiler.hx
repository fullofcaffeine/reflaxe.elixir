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
import reflaxe.elixir.helpers.RepoCompiler;
import reflaxe.elixir.helpers.TelemetryCompiler;
import reflaxe.elixir.helpers.EndpointCompiler;
import reflaxe.elixir.helpers.WebModuleCompiler;
import reflaxe.elixir.helpers.MutabilityAnalyzer;

using StringTools;

/**
 * ClassCompiler - Helper for class→struct/module compilation
 * Handles both @:struct classes (defstruct) and regular classes (module with functions)
 */
class ClassCompiler {
    
    private var typer: ElixirTyper;
    private var compiler: Null<reflaxe.elixir.ElixirCompiler> = null;
    private var currentClassName: Null<String> = null;
    private var importOptimizer: Null<reflaxe.elixir.helpers.ImportOptimizer> = null;
    private var mutabilityAnalyzer: Null<MutabilityAnalyzer> = null;
    
    public function new(?typer: ElixirTyper) {
        this.typer = (typer != null) ? typer : new ElixirTyper();
    }
    
    public function setCompiler(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
        if (compiler != null) {
            this.mutabilityAnalyzer = new MutabilityAnalyzer(compiler);
        }
    }
    
    public function setImportOptimizer(importOptimizer: reflaxe.elixir.helpers.ImportOptimizer) {
        this.importOptimizer = importOptimizer;
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
        
        // CRITICAL: Automatically detect instance classes and treat them as structs
        // This fixes JsonPrinter, StringBuf, and all other instance-based classes
        var isStruct = hasStructMetadata(classType) || isInstanceClass(classType, varFields, funcFields);
        
        #if debug_state_threading
        if (className == "JsonPrinter") {
            trace('[XRay ClassCompiler] ====== JSONPRINTER ANALYSIS ======');
            trace('[XRay ClassCompiler] hasStructMetadata: ${hasStructMetadata(classType)}');
            trace('[XRay ClassCompiler] isInstanceClass: ${isInstanceClass(classType, varFields, funcFields)}');
            trace('[XRay ClassCompiler] Final isStruct: ${isStruct}');
        }
        #end
        var isModule = hasModuleMetadata(classType);
        var isApplication = hasApplicationMetadata(classType);
        var isInterface = classType.isInterface;
        var result = new StringBuf();
        
        // For interfaces, compile as behavior definition
        if (isInterface) {
            return compileInterface(classType, funcFields);
        }
        
        // Check for Phoenix infrastructure annotations
        if (RepoCompiler.isRepoClass(classType)) {
            return RepoCompiler.compileRepoModule(classType, className);
        }
        
        if (TelemetryCompiler.isTelemetryClass(classType)) {
            return TelemetryCompiler.compileTelemetryModule(classType, className, funcFields);
        }
        
        if (EndpointCompiler.isEndpointClass(classType)) {
            return EndpointCompiler.compileEndpointModule(classType, className);
        }
        
        if (WebModuleCompiler.isWebModuleClass(classType)) {
            return WebModuleCompiler.compileWebModule(classType, className);
        }
        
        // Note: @:application classes are now compiled normally, 
        // with app name replacement handled in post-processing
        
        // Module definition
        result.add('defmodule ${className} do\n');
        
        // Add optimized import statements
        if (importOptimizer != null && importOptimizer.hasImports()) {
            var importSection = importOptimizer.generateImportSection();
            if (importSection.trim().length > 0) {
                result.add('\n  # Import statements\n');
                var importLines = importSection.split('\n');
                for (line in importLines) {
                    if (line.trim().length > 0) {
                        result.add('  ${line}\n');
                    }
                }
                result.add('\n');
            }
        }
        
        // Add Application use statement for @:application classes
        if (isApplication) {
            // Application classes should have proper documentation, not @moduledoc false
            result.add('  use Application\n\n');
        } else {
            // Add use Bitwise only if the module uses bitwise operations
            if (usesBitwiseOperations(classType)) {
                result.add('  use Bitwise\n');
            }
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
        
        // Check if this class uses HXX templates (contains HXX.hxx calls)
        // HXX templates compile to Phoenix HEEx format and require Phoenix.Component
        if (usesHxxTemplates(classType, funcFields)) {
            result.add('  use Phoenix.Component\n\n');
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
        var generatedFunctions = "";
        if (funcFields != null && funcFields.length > 0) {
            if (isModule) {
                generatedFunctions = generateModuleFunctions(funcFields);
            } else {
                generatedFunctions = generateFunctions(funcFields, isStruct);
            }
            result.add(generatedFunctions);
        }
        
        // Generate while loop helper functions if needed
        // Check both the AST and the generated code for while_loop calls
        if (needsWhileLoopHelpers(funcFields) || generatedFunctions.indexOf("while_loop(") >= 0) {
            result.add(generateWhileLoopHelpers());
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
     * CRITICAL: Detect if a class should be compiled as a struct
     * This fixes JsonPrinter, StringBuf, and all instance-based classes
     * 
     * A class is considered an "instance class" if it has:
     * - Instance fields (non-static variables)
     * - A constructor that initializes instance state
     * - Instance methods that operate on the instance
     * 
     * These classes need struct-based compilation to work correctly in Elixir
     */
    private function isInstanceClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Bool {
        // Skip extern classes - they use different compilation patterns
        if (classType.isExtern) return false;
        
        // Skip abstract types - they compile differently
        if (classType.isAbstract) return false;
        
        // Skip interfaces - they become behaviors
        if (classType.isInterface) return false;
        
        // Check for instance fields
        var hasInstanceFields = false;
        if (varFields != null) {
            for (field in varFields) {
                if (!field.isStatic) {
                    hasInstanceFields = true;
                    break;
                }
            }
        }
        
        // Check for constructor
        var hasConstructor = false;
        if (funcFields != null) {
            for (field in funcFields) {
                if (field.field.name == "new" && !field.isStatic) {
                    hasConstructor = true;
                    break;
                }
            }
        }
        
        // Check for instance methods
        var hasInstanceMethods = false;
        if (funcFields != null) {
            for (field in funcFields) {
                if (!field.isStatic && field.field.name != "new") {
                    hasInstanceMethods = true;
                    break;
                }
            }
        }
        
        // A class is an instance class if it has any instance-based features
        // This ensures classes like JsonPrinter and StringBuf compile as structs
        return hasInstanceFields || hasConstructor || hasInstanceMethods;
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
     * Generate module documentation with proper formatting
     */
    private function generateModuleDoc(className: String, classType: Dynamic, isStruct: Bool): String {
        // Always start with the standard header
        var docString = '${className} ${isStruct ? "struct" : "module"} generated from Haxe';
        
        // Add the actual class documentation if available
        if (classType.doc != null) {
            // Add spacing and then the original documentation with proper bullet formatting
            docString += '\n\n\n * ' + classType.doc.split('\n').join('\n * ') + '\n ';
        } else if (isStruct) {
            // Add default struct documentation
            docString += '\n\nThis module defines a struct with typed fields and constructor functions.';
        }
        
        // Use FormatHelper for proper formatting
        return FormatHelper.formatDoc(docString, true, 1) + '\n\n';
    }
    
    /**
     * Generate defstruct definition
     * 
     * WHY: Elixir requires fields with defaults to come last in defstruct
     * WHAT: Separate fields into two groups and order them correctly
     * HOW: Process fields without defaults first, then fields with defaults
     */
    private function generateDefstruct(varFields: Array<ClassVarData>): String {
        var result = new StringBuf();
        result.add('  defstruct [');
        
        // Separate fields into two groups for proper ordering
        var fieldsWithoutDefaults = [];
        var fieldsWithDefaults = [];
        
        for (field in varFields) {
            var fieldName = NamingHelper.toSnakeCase(field.field.name);
            
            // Check if field has default value
            if (field.hasDefaultValue()) {
                // Extract the actual default value from the AST
                var defaultValue = extractActualDefaultValue(field);
                fieldsWithDefaults.push('${fieldName}: ${defaultValue}');
            } else {
                fieldsWithoutDefaults.push(':${fieldName}');
            }
        }
        
        // Combine fields in the correct order: without defaults first, then with defaults
        var allFields = fieldsWithoutDefaults.concat(fieldsWithDefaults);
        result.add(allFields.join(', '));
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
        result.add('    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))\n');
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
     * Generate a single function with state threading transformation for mutable methods
     * 
     * WHY: Elixir's immutable data structures require transforming mutable Haxe methods
     * that modify struct fields into functions that return the updated struct. This enables
     * functional state threading while preserving the imperative programming style in Haxe.
     * 
     * WHAT: Analyzes methods for field mutations and transforms them:
     * - Detects field assignments (this.field = value)
     * - Changes return type from void to struct type
     * - Ensures the method returns the updated struct
     * - Enables state threading mode in the compiler
     * 
     * HOW: 
     * 1. Uses MutabilityAnalyzer to detect field mutations
     * 2. Transforms return type to t() for mutating methods
     * 3. Sets up parameter mapping (this -> struct)
     * 4. Enables state threading mode during compilation
     * 5. Ensures struct is returned at method end
     * 
     * EDGE CASES:
     * - Methods that already return the struct type
     * - Empty method bodies
     * - Methods with explicit return statements
     * - Nested field mutations (this.data.value = x)
     * 
     * @param funcField The function data to compile
     * @param isInstance Whether this is an instance method
     * @param isStructClass Whether the containing class is a struct
     * @return Generated Elixir function code
     */
    private function generateFunction(funcField: ClassFuncData, isInstance: Bool, isStructClass: Bool): String {
        var result = new StringBuf();
        var funcName = NamingHelper.getElixirFunctionName(funcField.field.name);
        
        /**
         * MUTABILITY ANALYSIS
         * 
         * WHY: Detect which methods mutate struct fields so we can transform them
         * WHAT: Analyze the method's AST for field assignments
         * HOW: MutabilityAnalyzer recursively traverses the expression tree
         */
        var mutabilityInfo = null;
        var shouldTransform = false;
        if (isInstance && isStructClass && mutabilityAnalyzer != null && funcField.expr != null) {
            mutabilityInfo = mutabilityAnalyzer.analyzeMethod(funcField.expr);
            shouldTransform = MutabilityAnalyzer.shouldTransformMethod(mutabilityInfo, isStructClass);
            
            #if debug_state_threading
            if (currentClassName == "JsonPrinter") {
                trace('[XRay ClassCompiler] JsonPrinter method ${funcName}:');
                trace('[XRay ClassCompiler]   - isInstance: ${isInstance}');
                trace('[XRay ClassCompiler]   - isStructClass: ${isStructClass}');
                trace('[XRay ClassCompiler]   - isMutating: ${mutabilityInfo.isMutating}');
                trace('[XRay ClassCompiler]   - mutatedFields: ${mutabilityInfo.mutatedFields}');
                trace('[XRay ClassCompiler]   - shouldTransform: ${shouldTransform}');
            }
            #end
            
            #if debug_mutability
            trace('[ClassCompiler] Method ${funcName} mutability analysis:');
            trace('  - isMutating: ${mutabilityInfo.isMutating}');
            trace('  - mutatedFields: ${mutabilityInfo.mutatedFields}');
            trace('  - shouldTransform: ${shouldTransform}');
            #end
        }
        
        // Build parameter list
        var params = [];
        var paramTypes = [];
        
        // Instance methods take struct as first parameter
        if (isInstance && isStructClass) {
            params.push('%__MODULE__{} = struct');
            paramTypes.push('t()');
        }
        
        // CRITICAL: Detect unused parameters to prefix with underscore
        var usedParams = if (funcField.expr != null && funcField.args != null) {
            detectUsedParameters(funcField.expr, funcField.args);
        } else {
            new Map<String, Bool>(); // Empty function, all params unused
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
                
                // Check if parameter is used in function body
                var isUsed = usedParams.exists(originalName) && usedParams.get(originalName);
                
                // Convert to snake_case and prefix with underscore if unused
                var paramName = NamingHelper.toSnakeCase(originalName);
                if (!isUsed) {
                    // Prefix with underscore to indicate intentionally unused
                    paramName = "_" + paramName;
                }
                
                params.push(paramName);
                
                var argType = getArgType(arg);
                var elixirType = typer.compileType(argType);
                paramTypes.push(elixirType);
            }
        }
        
        // Get return type
        var returnType = getReturnType(funcField);
        var elixirReturnType = typer.compileType(returnType);
        
        // Transform return type for mutable methods to return the updated struct
        if (shouldTransform) {
            elixirReturnType = 't()';
        } else if (isInstance && isStructClass && returnType == classNameFromFunc(funcField)) {
            elixirReturnType = 't()';
        }
        
        // Generate function with @spec
        var paramStr = params.join(', ');
        var typeStr = paramTypes.join(', ');
        
        var docString = funcField.field.doc != null ? funcField.field.doc : 'Function ${funcName}';
        var formattedDoc = FormatHelper.formatDoc(docString, false, 1);
        if (formattedDoc != "") {
            result.add(formattedDoc + '\n');
        }
        result.add('  @spec ${funcName}(${typeStr}) :: ${elixirReturnType}\n');
        result.add('  def ${funcName}(${paramStr}) do\n');
        
        /**
         * FUNCTION BODY COMPILATION WITH STATE THREADING
         * 
         * WHY: Transform mutable field assignments into immutable struct updates
         * WHAT: Configure compiler for state threading when processing mutating methods
         * HOW: Set up parameter mappings and enable state threading mode
         */
        if (funcField.expr != null) {
            /**
             * PARAMETER MAPPING SETUP
             * 
             * WHY: Haxe uses 'this' but Elixir structs use explicit parameter names
             * WHAT: Map 'this' references to the 'struct' parameter
             * HOW: Configure compiler's parameter mapping and inline context
             */
            if (isInstance && isStructClass && compiler != null) {
                // GLOBAL FIX: Start global struct method compilation
                compiler.startCompilingStructMethod("struct");
                
                // Map this -> struct for consistent variable references
                compiler.setThisParameterMapping("struct");
                // Replace _this variables (from Haxe desugaring) with struct
                compiler.setInlineContext("struct", "struct");
                // CRITICAL: Also map _this to struct for switch case transformations
                compiler.currentFunctionParameterMap.set("_this", "struct");
                
                #if debug_state_threading
                trace('[XRay ClassCompiler] ✓ SET _this → struct mapping for method: ${funcField.field.name}');
                trace('[XRay ClassCompiler] ✓ GLOBAL struct method compilation started');
                trace('[XRay ClassCompiler] Current map size: ${Lambda.count(compiler.currentFunctionParameterMap)}');
                for (key in compiler.currentFunctionParameterMap.keys()) {
                    trace('[XRay ClassCompiler] Map entry: ${key} → ${compiler.currentFunctionParameterMap.get(key)}');
                }
                #end
                
                /**
                 * STATE THREADING MODE
                 * 
                 * WHY: Mutating methods need to return updated structs
                 * WHAT: Enable transformation of field assignments
                 * HOY: Compiler will transform this.field = value to struct = %{struct | field: value}
                 */
                if (shouldTransform) {
                    compiler.enableStateThreadingMode(mutabilityInfo);
                }
            }
            
            // Compile the actual function expression
            var compiledBody = compileExpressionForFunction(funcField.expr, funcField.args);
            
            
            if (compiledBody != null && compiledBody.trim() != "") {
                // For mutating methods, ensure we return the struct at the end
                if (shouldTransform) {
                    // Check if the body already returns something
                    var trimmedBody = compiledBody.trim();
                    if (!trimmedBody.endsWith("struct")) {
                        // Add struct return at the end
                        var indentedBody = compiledBody.split("\n").map(line -> line.length > 0 ? "    " + line : line).join("\n");
                        result.add('${indentedBody}\n');
                        result.add('    struct\n');
                    } else {
                        var indentedBody = compiledBody.split("\n").map(line -> line.length > 0 ? "    " + line : line).join("\n");
                        result.add('${indentedBody}\n');
                    }
                } else {
                    // Indent the function body properly
                    var indentedBody = compiledBody.split("\n").map(line -> line.length > 0 ? "    " + line : line).join("\n");
                    result.add('${indentedBody}\n');
                }
            } else {
                // Only use default return if compilation failed/returned empty
                // For struct update methods, return updated struct
                if (isInstance && isStructClass && (elixirReturnType == 't()' || shouldTransform)) {
                    result.add('    struct\n');
                } else {
                    result.add('    nil\n');
                }
            }
        } else {
            // No expression provided - this is a truly empty function
            if (shouldTransform) {
                result.add('    struct\n');
            } else {
                result.add('    nil\n');
            }
        }
        
        result.add('  end\n\n');
        
        // Clear any this parameter mapping and inline context after ALL compilation is complete
        if (isInstance && isStructClass && compiler != null) {
            compiler.clearThisParameterMapping();
            compiler.clearInlineContext();
            if (shouldTransform) {
                compiler.disableStateThreadingMode();
                #if debug_state_threading
                trace('[XRay ClassCompiler] ✓ State threading cleanup completed for: ${funcField.field.name}');
                #end
            }
            
            // GLOBAL FIX: Stop global struct method compilation
            compiler.stopCompilingStructMethod();
            #if debug_state_threading
            trace('[XRay ClassCompiler] ✓ GLOBAL struct method compilation stopped');
            #end
        }
        
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
            var docString = func.field.doc != null ? func.field.doc : 'Function ${funcName}';
            var formattedDoc = FormatHelper.formatDoc(docString, false, 1);
            if (formattedDoc != "") {
                result.add(formattedDoc + '\n');
            }
            
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
     * Extract default value for field (legacy method - kept for compatibility)
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
     * Extract the actual default value from the field's AST
     * 
     * WHY: Need to use the actual default values from Haxe source, not generic ones
     * WHAT: Extract and compile the default expression from the field
     * HOW: Use ClassVarData's findDefaultExpr() to get TypedExpr, then compile it
     */
    private function extractActualDefaultValue(field: ClassVarData): String {
        // Try to find the default expression from the AST
        var defaultExpr = field.findDefaultExpr();
        
        if (defaultExpr != null && compiler != null) {
            // Compile the default expression to Elixir code
            var compiledDefault = compiler.compileExpression(defaultExpr);
            
            // Handle some common transformations for defstruct context
            if (compiledDefault == "[]") {
                // Empty array defaults need to be nil in defstruct, [] in constructor
                return "nil";
            }
            
            return compiledDefault;
        }
        
        // Fallback to type-based defaults if we can't find the expression
        var fieldType = getFieldType(field);
        
        // Check for array types
        if (fieldType.indexOf("Array") >= 0) {
            return "nil"; // Arrays default to nil in defstruct
        }
        
        return switch(fieldType) {
            case "Bool": "false";
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
            /**
             * PARAMETER MAPPING PRESERVATION
             * 
             * WHY: We need to preserve existing mappings like _this -> struct
             * WHAT: Save current mappings, add function parameters, then restore
             * HOW: Copy map before modifying, restore after compilation
             */
            // Save the current parameter map (includes _this -> struct mapping)
            var savedMap = new Map<String, String>();
            for (key in compiler.currentFunctionParameterMap.keys()) {
                savedMap.set(key, compiler.currentFunctionParameterMap.get(key));
            }
            
            #if debug_state_threading
            trace('[XRay ClassCompiler] compileExpressionForFunction - BEFORE parameter mapping');
            trace('[XRay ClassCompiler] Saved map size: ${Lambda.count(savedMap)}');
            for (key in savedMap.keys()) {
                trace('[XRay ClassCompiler] Saved: ${key} → ${savedMap.get(key)}');
            }
            #end
            
            // Always set up parameter mapping when we generate standardized arg names
            // This ensures TLocal variables in the function body use the correct parameter names
            if (args != null && args.length > 0) {
                compiler.setFunctionParameterMapping(args);
                
                #if debug_state_threading
                trace('[XRay ClassCompiler] AFTER setFunctionParameterMapping');
                trace('[XRay ClassCompiler] Current map size: ${Lambda.count(compiler.currentFunctionParameterMap)}');
                for (key in compiler.currentFunctionParameterMap.keys()) {
                    trace('[XRay ClassCompiler] Current: ${key} → ${compiler.currentFunctionParameterMap.get(key)}');
                }
                #end
            }
            
            #if debug_temp_var
            trace('[ClassCompiler] About to compile function body expression');
            trace('[ClassCompiler] Expression type: ${expr.expr}');
            #end
            
            // CRITICAL FIX: Check if function body is just a return switch
            // This detects `return switch(...)` pattern to avoid temp variable shadowing
            var result = switch (expr.expr) {
                case TReturn(retExpr) if (retExpr != null):
                    switch (retExpr.expr) {
                        case TSwitch(switchExpr, cases, defaultExpr):
                            #if debug_temp_var
                            trace('[ClassCompiler] ✓ DETECTED function body is return switch - compiling as value expression');
                            #end
                            
                            // Mark that we're compiling a switch as a value expression
                            var wasCompilingCaseArm = compiler.isCompilingCaseArm;
                            compiler.isCompilingCaseArm = true;
                            
                            // Compile the switch directly as a value-returning expression
                            var switchResult = compiler.compileSwitchExpression(switchExpr, cases, defaultExpr);
                            
                            // Restore context
                            compiler.isCompilingCaseArm = wasCompilingCaseArm;
                            
                            switchResult;
                        case _:
                            compiler.compileExpression(expr);
                    }
                case _:
                    compiler.compileExpression(expr);
            };
            
            #if debug_state_threading
            trace('[XRay ClassCompiler] AFTER compileExpression, BEFORE restore');
            trace('[XRay ClassCompiler] Current map size: ${Lambda.count(compiler.currentFunctionParameterMap)}');
            for (key in compiler.currentFunctionParameterMap.keys()) {
                trace('[XRay ClassCompiler] Current: ${key} → ${compiler.currentFunctionParameterMap.get(key)}');
            }
            #end
            
            // Restore the saved parameter map instead of clearing completely
            compiler.currentFunctionParameterMap.clear();
            for (key in savedMap.keys()) {
                compiler.currentFunctionParameterMap.set(key, savedMap.get(key));
            }
            
            #if debug_state_threading
            trace('[XRay ClassCompiler] AFTER restore');
            trace('[XRay ClassCompiler] Restored map size: ${Lambda.count(compiler.currentFunctionParameterMap)}');
            for (key in compiler.currentFunctionParameterMap.keys()) {
                trace('[XRay ClassCompiler] Restored: ${key} → ${compiler.currentFunctionParameterMap.get(key)}');
            }
            #end
            
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
     * Check if a class uses HXX templates by looking for HXX.hxx() calls
     * HXX templates compile to Phoenix HEEx format with ~H sigils
     * This determines if we should import Phoenix.Component for HEEx template support
     */
    public function usesHxxTemplates(classType: ClassType, funcFields: Array<ClassFuncData>): Bool {
        var className = classType.name;
        #if debug_hxx
        trace('usesHxxTemplates: Checking ${className}');
        #end
        
        // For now, check if this is a layout class by name pattern
        // Layout classes always need Phoenix.Component for HEEx templates
        var classNameLower = className.toLowerCase();
        if (classNameLower.indexOf("layout") >= 0) {
            #if debug_hxx
            trace('usesHxxTemplates: ${className} detected as layout');
            #end
            return true;
        }
        
        // Check all function bodies for HXX.hxx() calls
        if (funcFields != null) {
            #if debug_hxx
            trace('usesHxxTemplates: ${className} checking ${funcFields.length} function fields');
            #end
            for (i in 0...funcFields.length) {
                var func = funcFields[i];
                #if debug_hxx
                trace('usesHxxTemplates: ${className} checking function ${func.field.name}');
                #end
                if (func.expr != null) {
                    var hasHxx = containsHxxCall(func.expr);
                    #if debug_hxx
                    trace('usesHxxTemplates: ${className}.${func.field.name} HXX = ${hasHxx}');
                    #end
                    if (hasHxx) {
                        #if debug_hxx
                        trace('usesHxxTemplates: ${className} found HXX in ${func.field.name}');
                        #end
                        return true;
                    }
                } else {
                    #if debug_hxx
                    trace('usesHxxTemplates: ${className}.${func.field.name} has null expr');
                    #end
                }
            }
        } else {
            #if debug_hxx
            trace('usesHxxTemplates: ${className} has null funcFields');
            #end
        }
        
        // Also check static fields that might be initialized with HXX
        var staticFields = classType.statics.get();
        #if debug_hxx
        trace('usesHxxTemplates: ${className} checking ${staticFields.length} static fields');
        #end
        for (field in staticFields) {
            if (field.expr() != null && containsHxxCall(field.expr())) {
                #if debug_hxx
                trace('usesHxxTemplates: ${className} found HXX in static field ${field.name}');
                #end
                return true;
            }
        }
        
        #if debug_hxx
        trace('usesHxxTemplates: ${className} no HXX found');
        #end
        return false;
    }
    
    /**
     * Recursively check if an expression contains HXX.hxx() calls
     * HXX templates compile to Phoenix HEEx format via ~H sigils
     * Uses proper TypedExpr AST traversal for reliable detection
     */
    public function containsHxxCall(expr: TypedExpr): Bool {
        if (expr == null) return false;
        return containsHxxCallInTypedExpr(expr);
    }
    
    /**
     * Properly traverse TypedExpr AST to find HXX.hxx() calls
     * This mirrors the successful detection logic in ElixirCompiler.hx
     */
    private function containsHxxCallInTypedExpr(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TCall(e, el):
                // Check if this is a call to HXX.hxx() - the exact pattern from ElixirCompiler
                switch (e.expr) {
                    case TField({expr: TTypeExpr(_)}, FStatic(clsRef, cf)):
                        // Static call like HXX.hxx()
                        var cls = clsRef.get();
                        if (cls.name == "HXX" && cf.get().name == "hxx") {
                            return true;
                        }
                    case TField(obj, FInstance(_, _, cf)):
                        // Instance call (less likely for HXX)
                        if (cf.get().name == "hxx") {
                            // Check if obj refers to HXX by string inspection
                            var objStr = Std.string(obj);
                            if (objStr.indexOf("HXX") >= 0) {
                                return true;
                            }
                        }
                    case _:
                }
                
                // Recursively check the call target and arguments
                if (containsHxxCallInTypedExpr(e)) return true;
                for (arg in el) {
                    if (containsHxxCallInTypedExpr(arg)) return true;
                }
                
            case TBlock(el):
                // Check all expressions in block
                for (e in el) {
                    if (containsHxxCallInTypedExpr(e)) return true;
                }
                
            case TReturn(e):
                // Check return expression
                if (e != null && containsHxxCallInTypedExpr(e)) return true;
                
            case TIf(econd, eif, eelse):
                // Check all branches
                if (containsHxxCallInTypedExpr(econd)) return true;
                if (containsHxxCallInTypedExpr(eif)) return true;
                if (eelse != null && containsHxxCallInTypedExpr(eelse)) return true;
                
            case TVar(v, e):
                // Check variable initialization
                if (e != null && containsHxxCallInTypedExpr(e)) return true;
                
            case TFunction(f):
                // Check function body
                if (f.expr != null && containsHxxCallInTypedExpr(f.expr)) return true;
                
            case TFor(v, it, expr):
                // Check iterator and body
                if (containsHxxCallInTypedExpr(it)) return true;
                if (containsHxxCallInTypedExpr(expr)) return true;
                
            case TWhile(econd, e, normalWhile):
                // Check condition and body
                if (containsHxxCallInTypedExpr(econd)) return true;
                if (containsHxxCallInTypedExpr(e)) return true;
                
            case TSwitch(e, cases, edef):
                // Check switch expression and cases
                if (containsHxxCallInTypedExpr(e)) return true;
                for (c in cases) {
                    if (c.expr != null && containsHxxCallInTypedExpr(c.expr)) return true;
                }
                if (edef != null && containsHxxCallInTypedExpr(edef)) return true;
                
            case TBinop(op, e1, e2):
                // Check both operands
                if (containsHxxCallInTypedExpr(e1)) return true;
                if (containsHxxCallInTypedExpr(e2)) return true;
                
            case TUnop(op, postFix, e):
                // Check operand
                if (containsHxxCallInTypedExpr(e)) return true;
                
            case TArrayDecl(el):
                // Check array elements
                for (e in el) {
                    if (containsHxxCallInTypedExpr(e)) return true;
                }
                
            case TObjectDecl(fields):
                // Check object field values  
                for (f in fields) {
                    if (containsHxxCallInTypedExpr(f.expr)) return true;
                }
                
            case _:
                // For other expression types, no recursive check needed
        }
        
        return false;
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
    
    /**
     * Check if a class uses bitwise operations
     */
    static function usesBitwiseOperations(classType: ClassType): Bool {
        // Check all fields for bitwise operators
        for (field in classType.fields.get()) {
            if (fieldContainsBitwiseOps(field)) {
                return true;
            }
        }
        
        // Check static fields
        for (field in classType.statics.get()) {
            if (fieldContainsBitwiseOps(field)) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * Check if a field contains bitwise operations by examining its expression
     */
    static function fieldContainsBitwiseOps(field: ClassField): Bool {
        if (field.expr() == null) return false;
        
        return exprContainsBitwiseOps(field.expr());
    }
    
    /**
     * Recursively check if an expression contains bitwise operations
     */
    static function exprContainsBitwiseOps(expr: TypedExpr): Bool {
        switch (expr.expr) {
            case TBinop(op, e1, e2):
                // Check for bitwise operators
                switch (op) {
                    case OpAnd | OpOr | OpXor | OpShl | OpShr | OpUShr:
                        return true;
                    case _:
                        // Recursively check sub-expressions
                        return exprContainsBitwiseOps(e1) || exprContainsBitwiseOps(e2);
                }
            case TUnop(op, postFix, e):
                switch (op) {
                    case OpNot: // Bitwise NOT (~)
                        return true;
                    case _:
                        return exprContainsBitwiseOps(e);
                }
            // Recursively check other expression types
            case TBlock(el):
                for (e in el) {
                    if (exprContainsBitwiseOps(e)) return true;
                }
                return false;
            case TIf(econd, eif, eelse):
                return exprContainsBitwiseOps(econd) || 
                       exprContainsBitwiseOps(eif) || 
                       (eelse != null ? exprContainsBitwiseOps(eelse) : false);
            case TFor(v, it, expr):
                return exprContainsBitwiseOps(it) || exprContainsBitwiseOps(expr);
            case TWhile(econd, e, normalWhile):
                return exprContainsBitwiseOps(econd) || exprContainsBitwiseOps(e);
            case TCall(e, el):
                if (exprContainsBitwiseOps(e)) return true;
                for (arg in el) {
                    if (exprContainsBitwiseOps(arg)) return true;
                }
                return false;
            case _:
                return false;
        }
    }
    
    /**
     * Check if any function in the class needs while loop helper functions
     * 
     * WHY: while_loop helper functions should only be generated when actually needed
     * WHAT: Scan all function bodies for while_loop() calls generated by ControlFlowCompiler
     * HOW: Check function expressions for pattern: while_loop(
     * 
     * @param funcFields Array of function data to analyze
     * @return True if while loop helpers are needed
     */
    private function needsWhileLoopHelpers(funcFields: Array<ClassFuncData>): Bool {
        if (funcFields == null || compiler == null) return false;
        
        for (func in funcFields) {
            if (func.tfunc != null && func.tfunc.expr != null) {
                if (containsWhileLoopCalls(func.tfunc.expr)) {
                    return true;
                }
            }
        }
        return false;
    }
    
    /**
     * Recursively check if expression contains while_loop() function calls
     * 
     * @param expr Expression to analyze
     * @return True if contains while_loop calls
     */
    private function containsWhileLoopCalls(expr: haxe.macro.Type.TypedExpr): Bool {
        if (expr == null) return false;
        
        // Check if this is a while loop that will generate while_loop() calls
        switch (expr.expr) {
            case TWhile(econd, ebody, normalWhile):
                return true; // TWhile expressions generate while_loop calls
            case TBlock(el):
                for (e in el) {
                    if (containsWhileLoopCalls(e)) return true;
                }
                return false;
            case TIf(econd, eif, eelse):
                return containsWhileLoopCalls(econd) || 
                       containsWhileLoopCalls(eif) || 
                       (eelse != null ? containsWhileLoopCalls(eelse) : false);
            case TFor(v, it, expr):
                return containsWhileLoopCalls(it) || containsWhileLoopCalls(expr);
            case TCall(e, el):
                if (containsWhileLoopCalls(e)) return true;
                for (arg in el) {
                    if (containsWhileLoopCalls(arg)) return true;
                }
                return false;
            case TBinop(op, e1, e2):
                return containsWhileLoopCalls(e1) || containsWhileLoopCalls(e2);
            case TVar(v, expr):
                return expr != null ? containsWhileLoopCalls(expr) : false;
            case TReturn(expr):
                return expr != null ? containsWhileLoopCalls(expr) : false;
            case _:
                return false;
        }
    }
    
    /**
     * Generate while loop helper functions for tail-recursive loop patterns
     * 
     * WHY: ControlFlowCompiler generates calls to while_loop() and do_while_loop() but doesn't generate the implementations
     * WHAT: Creates private helper functions that implement tail-recursive loop patterns
     * HOW: Generate defp functions that use condition and body lambdas for proper tail recursion
     * 
     * @return String containing the helper function definitions
     */
    private function generateWhileLoopHelpers(): String {
        var result = new StringBuf();
        
        result.add('\n  # While loop helper functions\n');
        result.add('  # Generated automatically for tail-recursive loop patterns\n\n');
        
        // Standard while loop helper
        result.add('  @doc false\n');
        result.add('  defp while_loop(condition_fn, body_fn) do\n');
        result.add('    if condition_fn.() do\n');
        result.add('      body_fn.()\n');
        result.add('      while_loop(condition_fn, body_fn)\n');
        result.add('    else\n');
        result.add('      nil\n');
        result.add('    end\n');
        result.add('  end\n\n');
        
        // Do-while loop helper  
        result.add('  @doc false\n');
        result.add('  defp do_while_loop(body_fn, condition_fn) do\n');
        result.add('    body_fn.()\n');
        result.add('    if condition_fn.() do\n');
        result.add('      do_while_loop(body_fn, condition_fn)\n');
        result.add('    else\n');
        result.add('      nil\n');
        result.add('    end\n');
        result.add('  end\n\n');
        
        return result.toString();
    }
    
    /**
     * Detect which parameters are actually used in the function body
     * 
     * WHY: Unused parameters should be prefixed with underscore in Elixir
     * to avoid compiler warnings and follow idiomatic conventions
     * 
     * WHAT: Recursively traverse the function expression tree to find
     * all TLocal references to parameter variables
     * 
     * HOW: Pattern match on TypedExpr types and collect TLocal references
     * that match parameter names
     * 
     * @param expr The function body expression
     * @param args The function arguments to check against
     * @return Map of parameter names to usage status (true if used)
     */
    private function detectUsedParameters(expr: TypedExpr, args: Array<ClassFuncArg>): Map<String, Bool> {
        var usedParams = new Map<String, Bool>();
        
        // Build a set of parameter names for quick lookup
        var paramNames = new Map<String, Bool>();
        for (arg in args) {
            var name = if (arg.tvar != null) {
                arg.tvar.name;
            } else {
                arg.getName();
            };
            paramNames.set(name, true);
            usedParams.set(name, false); // Initially mark as unused
        }
        
        // Recursive function to traverse expression tree
        function checkExpression(e: TypedExpr): Void {
            if (e == null) return;
            
            switch (e.expr) {
                case TLocal(tvar):
                    // Check if this local variable is a parameter
                    if (paramNames.exists(tvar.name)) {
                        usedParams.set(tvar.name, true);
                    }
                    
                case TBlock(exprs):
                    for (subExpr in exprs) {
                        checkExpression(subExpr);
                    }
                    
                case TIf(condExpr, ifExpr, elseExpr):
                    checkExpression(condExpr);
                    checkExpression(ifExpr);
                    if (elseExpr != null) checkExpression(elseExpr);
                    
                case TWhile(condExpr, bodyExpr, normalWhile):
                    checkExpression(condExpr);
                    checkExpression(bodyExpr);
                    
                case TFor(tvar, iterExpr, bodyExpr):
                    checkExpression(iterExpr);
                    checkExpression(bodyExpr);
                    
                case TSwitch(switchExpr, cases, defaultCase):
                    checkExpression(switchExpr);
                    for (c in cases) {
                        checkExpression(c.expr);
                    }
                    if (defaultCase != null) checkExpression(defaultCase);
                    
                case TCall(e, el):
                    checkExpression(e);
                    for (arg in el) {
                        checkExpression(arg);
                    }
                    
                case TFunction(tfunc):
                    // Check function body but don't include its own params
                    if (tfunc.expr != null) {
                        checkExpression(tfunc.expr);
                    }
                    
                case TReturn(e):
                    if (e != null) checkExpression(e);
                    
                case TBinop(op, e1, e2):
                    checkExpression(e1);
                    checkExpression(e2);
                    
                case TUnop(op, postFix, e):
                    checkExpression(e);
                    
                case TField(e, field):
                    checkExpression(e);
                    
                case TArrayDecl(values):
                    for (v in values) {
                        checkExpression(v);
                    }
                    
                case TObjectDecl(fields):
                    for (f in fields) {
                        checkExpression(f.expr);
                    }
                    
                case TNew(classTypeRef, params, el):
                    for (e in el) {
                        checkExpression(e);
                    }
                    
                case TVar(tvar, expr):
                    if (expr != null) checkExpression(expr);
                    
                case TParenthesis(e):
                    checkExpression(e);
                    
                case TTry(e, catches):
                    checkExpression(e);
                    for (c in catches) {
                        checkExpression(c.expr);
                    }
                    
                case TThrow(e):
                    checkExpression(e);
                    
                case TCast(e, moduleType):
                    checkExpression(e);
                    
                case TMeta(metadataEntry, e):
                    checkExpression(e);
                    
                default:
                    // TConst, TTypeExpr, TBreak, TContinue, TIdent don't need recursion
            }
        }
        
        // Start the traversal
        checkExpression(expr);
        
        return usedParams;
    }
}

#end