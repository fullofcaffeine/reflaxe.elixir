package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.TypedExpr;
import reflaxe.data.ClassFuncData;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.DebugHelper;

using StringTools;
using reflaxe.helpers.TypedExprHelper;

/**
 * FunctionCompiler: Specialized compilation of class functions to idiomatic Elixir
 * 
 * WHY: Function compilation involves complex logic including parameter mapping,
 * pipeline optimization, LiveView callback handling, and proper Elixir function
 * formatting. This was extracted from ElixirCompiler.hx to follow single 
 * responsibility principle and reduce main compiler complexity.
 * 
 * WHAT: Transforms Haxe class functions into idiomatic Elixir function definitions:
 * - Parameter name conversion (camelCase → snake_case)
 * - LiveView callback parameter override support
 * - Pipeline optimization for function body compilation
 * - Proper function documentation generation
 * - Body indentation and formatting for Elixir conventions
 * - Fallback handling for empty or null function bodies
 * 
 * HOW: 
 * 1. Extract function metadata (name, parameters, body)
 * 2. Apply parameter naming conversions with LiveView overrides
 * 3. Analyze function body for pipeline optimization opportunities
 * 4. Compile function body with proper context (topLevel = true)
 * 5. Format result with Elixir function definition syntax
 * 6. Handle edge cases (empty bodies, compilation failures)
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused only on function compilation logic
 * - Open/Closed Principle: Extensible for new function patterns
 * - Testability: Can be unit tested independently from main compiler
 * - Maintainability: Clear separation from class and expression compilation
 * - Performance: Specialized optimizations for function-specific patterns
 * 
 * EDGE CASES:
 * - LiveView callbacks require specific parameter naming
 * - Empty or null function bodies need proper nil fallback
 * - Pipeline optimization may not apply to all function bodies
 * - Compilation failures need graceful degradation
 * 
 * @see documentation/FUNCTION_COMPILATION.md - Detailed function compilation patterns
 */
@:nullSafety(Off)
class FunctionCompiler {
    
    private var compiler: reflaxe.elixir.ElixirCompiler;
    
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * FUNCTION COMPILATION: Transform Haxe class function to idiomatic Elixir function
     * 
     * WHY: Haxe functions need careful translation to Elixir to preserve semantics
     * while following Elixir conventions. Parameter names, documentation, and body
     * formatting all require specialized handling for different function types.
     * 
     * WHAT: Generates complete Elixir function definition with:
     * - @doc documentation from Haxe function name
     * - def function_name(parameters) do ... end structure
     * - Proper parameter name conversion (camelCase → snake_case)
     * - LiveView callback parameter override when applicable
     * - Pipeline-optimized function body compilation
     * - Appropriate indentation and formatting
     * - Instance method handling for struct classes
     * - State threading for mutable struct methods
     * 
     * HOW:
     * 1. Convert function name to snake_case using NamingHelper
     * 2. Check for LiveView callback parameter overrides
     * 3. Build parameter list with proper naming conversion
     * 4. Generate function documentation and signature
     * 5. Compile function body with pipeline optimization detection
     * 6. Apply proper indentation and formatting
     * 7. Handle edge cases (empty bodies, compilation failures)
     * 
     * LIVEVIEW INTEGRATION: LiveView callbacks like mount/3, handle_event/3
     * require specific parameter names (params, session, socket) rather than
     * generic camelCase conversions. This function checks for these patterns.
     * 
     * PIPELINE OPTIMIZATION: Multi-statement function bodies are analyzed for
     * pipeline patterns that can be compiled to idiomatic Elixir |> chains.
     * 
     * INSTANCE METHOD HANDLING: Instance methods for struct classes need special
     * handling - they take the struct as first parameter and may return updated
     * struct for state threading.
     * 
     * @param funcField The Haxe function data including name, parameters, and body
     * @param isStatic Whether this is a static function (default: false)
     * @param isInstance Whether this is an instance method (default: false)
     * @param isStructClass Whether the containing class is a struct (default: false)
     * @param className The name of the containing class for context (default: null)
     * @return Complete Elixir function definition string
     */
    public function compileFunction(funcField: ClassFuncData, isStatic: Bool = false, 
                                   isInstance: Bool = false, isStructClass: Bool = false,
                                   ?className: String): String {
        var originalFuncName = funcField.field.name;
        
        // CRITICAL FIX: LiveView classes should NOT have __struct__ functions
        // Instance variables in LiveView are socket assigns, not struct fields
        var funcName = if (originalFuncName == "new" && isLiveViewClass()) {
            #if debug_function_compilation
            DebugHelper.debugFunction("LiveView Constructor Skip", "Skipping __struct__ generation for LiveView class", 'Original: ${originalFuncName}');
            #end
            return ""; // Skip generating constructor for LiveView classes
        } else {
            NamingHelper.getElixirFunctionName(originalFuncName);
        }
        
        #if debug_function_compilation
        DebugHelper.debugFunction("compileFunction", "Starting compilation", 'Function: ${funcName}, Static: ${isStatic}, Instance: ${isInstance}, Struct: ${isStructClass}');
        #end
        
        // Build parameter list - check for LiveView callback override first
        var paramStr = "";
        var liveViewParams = reflaxe.elixir.LiveViewCompiler.getLiveViewCallbackParams(funcName);
        
        if (liveViewParams != null) {
            // Use LiveView-specific parameter names for callbacks
            paramStr = liveViewParams;
            #if debug_function_compilation
            DebugHelper.debugFunction("LiveView Override", "Using LiveView parameters", 'Params: ${paramStr}');
            #end
        } else {
            // Build parameter list starting with struct parameter for instance methods
            var params = [];
            
            // Instance methods of struct classes take the struct as first parameter
            if (isInstance && isStructClass) {
                params.push('%__MODULE__{} = struct');
                #if debug_function_compilation
                DebugHelper.debugFunction("Struct Method", "Added struct parameter", 'First param: %__MODULE__{} = struct');
                #end
            }
            
            // Use actual parameter names converted to snake_case for regular functions
            // CRITICAL: Detect unused parameters to prefix with underscore
            // 
            // WHY: Reflaxe's preprocessor marks parameters as unused with -reflaxe.unused,
            //      but it doesn't recognize patterns like elem(spec, 0) as using the parameter.
            //      Our detectUsedParameters function properly handles these patterns.
            //      
            // WHAT: Use our own AST traversal to detect parameter usage, which correctly
            //       identifies parameters used in function calls like elem(spec, 0).
            //       
            // HOW: detectUsedParameters recursively checks all expressions including TCall
            //      arguments to find parameter references. Only truly unused parameters
            //      get prefixed with underscore.
            
            var usedParams = if (funcField.expr != null) {
                var result = detectUsedParameters(funcField.expr, funcField.args);
                
                #if debug_parameter_detection
                if (funcName == "print" && className != null && className.indexOf("JsonPrinter") >= 0) {
//                     trace('[FunctionCompiler] ===== DEBUGGING JsonPrinter.print =====');
//                     trace('[FunctionCompiler] Function args: ${[for (arg in funcField.args) arg.tvar != null ? arg.tvar.name : arg.getName()].join(", ")}');
//                     trace('[FunctionCompiler] Detected used parameters:');
                    for (key in result.keys()) {
//                         trace('[FunctionCompiler]   ${key}: ${result.get(key) ? "USED" : "UNUSED"}');
                    }
                }
                #end
                
                result;
            } else {
                new Map<String, Bool>(); // Empty function, all params unused
            }
            
            // Now add regular function parameters
            for (i in 0...funcField.args.length) {
                var arg = funcField.args[i];
                // Get the actual parameter name from tvar (consistent with setFunctionParameterMapping)
                var originalName = if (arg.tvar != null) {
                    arg.tvar.name;
                } else {
                    // Fallback to getName() if tvar is not available
                    arg.getName();
                }
                
                // Check if parameter is actually used in function body
                var isUsed = usedParams.exists(originalName) && usedParams.get(originalName);
                
                // Convert to snake_case and prefix with underscore if unused
                var paramName = NamingHelper.toSnakeCase(originalName);
                var baseParamName = paramName; // Store the base name without default value syntax
                
                // CRITICAL FIX: LiveView functions using HXX/~H sigil need "assigns" without underscore
                // Even if the parameter appears unused in the function body, the ~H sigil template
                // references assigns directly and requires it to be available without prefix
                var usesHxxTemplate = funcField.expr != null && containsHxxCall(funcField.expr);
                var isAssignsParam = originalName == "assigns";
                
                if (!isUsed && !(usesHxxTemplate && isAssignsParam)) {
                    // Prefix with underscore to indicate intentionally unused
                    // EXCEPT for "assigns" parameter in functions that use HXX templates
                    paramName = "_" + paramName;
                    baseParamName = paramName; // Update base name with underscore
                    
                    #if debug_function_compilation
                    DebugHelper.debugFunction("Unused Parameter", "Prefixed with underscore", 'Param: ${baseParamName}');
                    #end
                }
                
                // CRITICAL FIX: Always set up parameter mapping for ALL parameters
                // This ensures that when VariableCompiler compiles variable references in the body,
                // it uses the correct name (with or without underscore prefix)
                compiler.currentFunctionParameterMap.set(originalName, baseParamName);
                
                #if debug_function_compilation
                DebugHelper.debugFunction("Parameter Mapping", "Added mapping", '${originalName} -> ${baseParamName}');
                #end
                
                // Handle optional parameters by adding Elixir default value syntax
                // IMPORTANT: This happens AFTER setting up the mapping, so the mapping
                // contains just the variable name, not the default value syntax
                if (arg.opt) {
                    // Optional parameters get \\ nil syntax in Elixir
                    paramName = paramName + " \\\\ nil";
                    #if debug_function_compilation
                    DebugHelper.debugFunction("Optional Parameter", "Added default value", 'Param: ${paramName}');
                    #end
                }
                
                params.push(paramName);
            }
            paramStr = params.join(", ");
            #if debug_function_compilation
            DebugHelper.debugFunction("Parameter Conversion", "Converted parameters", 'Params: ${paramStr}');
            #end
            
            // ARCHITECTURAL FIX: Handle underscore-prefixed parameters correctly
            // 
            // WHY: In Elixir, when a parameter is prefixed with underscore (_spec),
            //      ALL references in the function body MUST also use the prefixed name.
            //      Using the unprefixed name (spec) causes "undefined variable" errors.
            //      
            // WHAT: When we prefix a parameter with underscore in the signature,
            //       we need to ensure all TLocal references in the body use the
            //       prefixed name as well.
            //       
            // HOW: Map the original Haxe variable name to the prefixed Elixir name
            //      so that when TLocal compiles variable references, it uses the
            //      correct prefixed name.
            //      
            // EXAMPLE:
            //   Haxe: function toLegacy(spec: TypeSafeChildSpec, appName: String)
            //   Function signature: def to_legacy(_spec, app_name) do
            //   Function body: case elem(_spec, 0) do  # Must use _spec, not spec
            //   
            // NOTE: This will generate Elixir warnings about using underscore-prefixed
            //       variables, but that's better than compilation errors.
            // 
            // IMPLEMENTATION: The parameter mapping is added above when we detect unused
            //                 parameters and prefix them with underscore (see line 199). 
            // WHY: Since we're NOT prefixing parameters that are actually used
            //      (like 'spec' in elem(spec, 0)), the body references can use
            //      the original unprefixed names directly.
            //      
            // WHAT: We don't need to set up any parameter mapping here because
            //       only truly unused parameters get prefixed, and those don't
            //       have any references in the body anyway.
            //       
            // HOW: The body compilation will use the standard snake_case names
            //      for all parameters that are actually referenced.
        }
        
        // Generate function documentation and signature
        var result = '  @doc "Generated from Haxe ${funcField.field.name}"\n';
        result += '  def ${funcName}(${paramStr}) do\n';
        
        if (funcField.expr != null) {
            // Set function context in VariableMappingManager
            if (compiler.variableMappingManager != null) {
                compiler.variableMappingManager.compilationContext.currentFunction = funcName;
                #if debug_variable_mapping
                #if debug_function_compiler
//                 trace('[FunctionCompiler] Set function context: ${funcName}');
                #end
                #end
            }
            
            // ARCHITECTURAL FIX: Set up struct method context if needed
            // WHY: Instance methods on structs need special handling for 'this' references
            // WHAT: Map 'this' to 'struct' parameter for consistent compilation
            // HOW: Set up parameter mapping before compiling body
            if (isInstance && isStructClass) {
                // Map this -> struct for instance methods
                compiler.setThisParameterMapping("struct");
                compiler.setInlineContext("struct", "struct");
                // Also map _this (from Haxe desugaring) to struct
                compiler.currentFunctionParameterMap.set("_this", "struct");
                
                #if debug_function_compilation
                DebugHelper.debugFunction("Struct Method Setup", "Mapped this->struct", 'Instance method of struct class');
                #end
            }
            
            // Compile function body with topLevel = true for function bodies
            // NOTE: Reflaxe framework handles preprocessor application automatically in compileClass()
            var compiledBody = compiler.compileExpressionImpl(funcField.expr, true);
            
            // CRITICAL FIX: Generate pre-declarations AFTER body compilation
            // WHY: Variables are only tracked DURING compilation, so we need to analyze
            // WHAT: Extract scope-crossing variables and generate nil pre-declarations  
            // HOW: Use post-compilation analysis to identify variables needing outer scope
            var requiredDeclarations = [];
            if (compiler.variableMappingManager != null) {
                // Use the enhanced scope analysis to detect variables that need pre-declaration
                // Pass the compiled body for fallback temp variable scanning
                requiredDeclarations = compiler.variableMappingManager.generateAllRequiredDeclarations(compiledBody);
                
                // Also perform comprehensive function-level analysis using processed expression
                var functionExpressions = extractAllExpressions(funcField.expr);
                var additionalDeclarations = compiler.variableMappingManager.generateRequiredOuterScopeDeclarations(functionExpressions);
                
                // Combine and deduplicate declarations
                for (decl in additionalDeclarations) {
                    if (requiredDeclarations.indexOf(decl) == -1) {
                        requiredDeclarations.push(decl);
                    }
                }
                
                #if debug_variable_mapping
                if (requiredDeclarations.length > 0) {
                    #if debug_function_compiler
//                     trace('[FunctionCompiler] Post-compilation: Found ${requiredDeclarations.length} scope-crossing variables: [${requiredDeclarations.join(", ")}]');
                    #end
                }
                #end
            }
            
            #if debug_function_compilation
            DebugHelper.debugFunction("Body Compilation", "Regular compilation used", 'Expression type: ${funcField.expr.expr}');
            #end
            
            if (compiledBody != null && compiledBody.trim() != "") {
                // Add pre-declarations at function start if needed
                var bodyWithDeclarations = compiledBody;
                if (requiredDeclarations.length > 0) {
                    var declarationsStr = requiredDeclarations.join("\n") + "\n\n";
                    bodyWithDeclarations = declarationsStr + compiledBody;
                    #if debug_variable_mapping
                    #if debug_function_compiler
//                     trace('[FunctionCompiler] ✓ Added ${requiredDeclarations.length} pre-declarations to function body');
                    #end
                    #end
                }
                
                // Indent the function body properly
                var indentedBody = bodyWithDeclarations.split("\n").map(line -> line.length > 0 ? "    " + line : line).join("\n");
                result += '${indentedBody}\n';
                #if debug_function_compilation
                DebugHelper.debugFunction("Body Compilation", "✓ SUCCESS", 'Body length: ${compiledBody.length} chars');
                #end
            } else {
                // Only use nil if compilation actually failed/returned empty
                result += '    nil\n';
                #if debug_function_compilation
                DebugHelper.debugFunction("Body Compilation", "⚠ FALLBACK to nil", 'Compiled body was empty or null');
                #end
            }
        } else {
            // No expression provided - this is a truly empty function
            result += '    nil\n';
            #if debug_function_compilation
            DebugHelper.debugFunction("Function Body", "No expression provided", 'Using nil fallback');
            #end
        }
        result += '  end\n\n';
        
        // ARCHITECTURAL FIX: Clean up struct method context
        // WHY: We need to clear mappings after each function to prevent leaking
        // WHAT: Clear the this->struct mapping we set up earlier
        // HOW: Reset parameter mappings and inline context
        if (isInstance && isStructClass) {
            compiler.clearThisParameterMapping();
            compiler.clearInlineContext();
            
            #if debug_function_compilation
            DebugHelper.debugFunction("Struct Method Cleanup", "Cleared this->struct mapping", 'Completed instance method compilation');
            #end
        }
        
        #if debug_function_compilation
        DebugHelper.debugFunction("compileFunction", "✓ COMPLETION", 'Generated ${result.split("\n").length} lines');
        #end
        
        return result;
    }
    
    /**
     * Extract all expressions from a function body for comprehensive analysis
     * 
     * WHY: The VariableMappingManager needs to analyze all expressions in a function
     * to detect scope-crossing variables before compilation begins
     * 
     * WHAT: Recursively traverse the function expression tree to collect all sub-expressions
     * 
     * HOW: Pattern match on TypedExpr types and recursively collect expressions
     * 
     * @param expr The root expression (function body)
     * @return Array of all expressions found in the function body
     */
    private function extractAllExpressions(expr: TypedExpr): Array<TypedExpr> {
        var expressions = [expr];
        
        function collectExpressions(e: TypedExpr): Void {
            switch (e.expr) {
                case TBlock(exprs):
                    for (subExpr in exprs) {
                        expressions.push(subExpr);
                        collectExpressions(subExpr);
                    }
                case TIf(condExpr, ifExpr, elseExpr):
                    expressions.push(condExpr);
                    expressions.push(ifExpr);
                    collectExpressions(condExpr);
                    collectExpressions(ifExpr);
                    if (elseExpr != null) {
                        expressions.push(elseExpr);
                        collectExpressions(elseExpr);
                    }
                case TWhile(condExpr, bodyExpr, normalWhile):
                    expressions.push(condExpr);
                    expressions.push(bodyExpr);
                    collectExpressions(condExpr);
                    collectExpressions(bodyExpr);
                case TFor(tvar, iterExpr, bodyExpr):
                    expressions.push(iterExpr);
                    expressions.push(bodyExpr);
                    collectExpressions(iterExpr);
                    collectExpressions(bodyExpr);
                case TSwitch(switchExpr, cases, defaultCase):
                    expressions.push(switchExpr);
                    collectExpressions(switchExpr);
                    for (c in cases) {
                        expressions.push(c.expr);
                        collectExpressions(c.expr);
                    }
                    if (defaultCase != null) {
                        expressions.push(defaultCase);
                        collectExpressions(defaultCase);
                    }
                default:
                    // Simplified implementation - covers the main patterns
                    // Other expression types (TLocal, TConst, etc.) do not need recursion
            }
        }
        
        collectExpressions(expr);
        return expressions;
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
    private function detectUsedParameters(expr: TypedExpr, args: Array<reflaxe.data.ClassFuncArg>): Map<String, Bool> {
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
            
            #if debug_parameter_detection
//             trace('[detectUsedParameters] Added parameter to check: ${name}');
            #end
        }
        
        // Recursive function to traverse expression tree
        function checkExpression(e: TypedExpr): Void {
            if (e == null) return;
            
            switch (e.expr) {
                case TLocal(tvar):
                    // Check if this local variable is a parameter
                    if (paramNames.exists(tvar.name)) {
                        usedParams.set(tvar.name, true);
                        #if debug_parameter_detection
//                         trace('[detectUsedParameters] PARAMETER USED: ${tvar.name}');
                        #end
                    } else {
                        // CRITICAL FIX: Handle Haxe's variable renaming for shadowing avoidance
                        // When a parameter shadows another name, Haxe may rename it by adding a suffix
                        // For example: replacer -> replacer2, space -> space2
                        // We need to check if this is a renamed version of a parameter
                        
                        // Extract base name by removing trailing digits
                        var baseName = ~/[0-9]+$/.replace(tvar.name, "");
                        if (baseName != tvar.name && paramNames.exists(baseName)) {
                            // This is a renamed version of a parameter!
                            usedParams.set(baseName, true);
                            #if debug_parameter_detection
//                             trace('[detectUsedParameters] RENAMED PARAMETER DETECTED: ${tvar.name} -> ${baseName}');
                            #end
                        }
                        #if debug_parameter_detection
                        else {
//                             trace('[detectUsedParameters] TLocal found but not a parameter: ${tvar.name}');
//                             trace('[detectUsedParameters] Known parameters: ${[for (k in paramNames.keys()) k].join(", ")}');
                        }
                        #end
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
                    // CRITICAL: The switch expression contains the parameter being matched
                    // For example: switch(spec) generates elem(spec, 0) in Elixir
                    #if debug_function_compiler
//                     trace('[FunctionCompiler] TSwitch found, switchExpr type: ${switchExpr.expr}');
                    #end
                    checkExpression(switchExpr);
                    for (c in cases) {
                        // Also check case patterns - they might reference parameters
                        checkExpression(c.expr);
                    }
                    if (defaultCase != null) checkExpression(defaultCase);
                    
                case TCall(e, el):
                    /**
                     * CRITICAL FIX: Detect parameter usage in function calls
                     * 
                     * WHY: Parameters used as arguments in function calls like elem(spec, 0)
                     *      were not being detected as "used", causing incorrect underscore prefixing
                     * 
                     * WHAT: Check both the function expression AND all arguments for parameter references
                     * 
                     * HOW: Recursively traverse both the function being called and its arguments
                     *      to find any TLocal references that match our function parameters
                     * 
                     * EXAMPLE: In elem(spec, 0), we need to detect that 'spec' is being used
                     *          even though it's an argument to elem(), not a direct reference
                     */
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
                    #if debug_parameter_detection
//                     trace('[detectUsedParameters] TNew found with ${el.length} arguments');
                    for (i in 0...el.length) {
//                         trace('[detectUsedParameters] Arg ${i}: ${el[i].expr}');
                    }
                    #end
                    for (e in el) {
                        checkExpression(e);
                    }
                    
                case TVar(tvar, expr):
                    if (expr != null) checkExpression(expr);
                    
                case TParenthesis(e):
                    checkExpression(e);
                    
                case TMeta(meta, e):
                    // Handle metadata-wrapped expressions (like :exhaustive)
                    checkExpression(e);
                    
                case TEnumIndex(e):
                    // CRITICAL: TEnumIndex contains the actual enum variable reference
                    // For switch(spec), this will contain TLocal(spec)
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
                    
                default:
                    // TConst, TTypeExpr, TBreak, TContinue, TIdent don't need recursion
            }
        }
        
        // Start the traversal
        checkExpression(expr);
        
        return usedParams;
    }
    
    /**
     * Check if the current class being compiled is a LiveView class
     * 
     * WHY: LiveView classes should NOT have __struct__ functions because their
     * instance variables are socket assigns, not struct fields.
     * 
     * WHAT: Detect if the current class has @:liveview annotation
     * 
     * HOW: Check the compiler's current class type for LiveView annotation
     * 
     * @return True if current class is a LiveView class
     */
    private function isLiveViewClass(): Bool {
        if (compiler.currentClassType == null) return false;
        
        // Check for @:liveview annotation using AnnotationSystem
        var annotationInfo = reflaxe.elixir.helpers.AnnotationSystem.detectAnnotations(compiler.currentClassType);
        return annotationInfo.primaryAnnotation == ":liveview";
    }
    
    /**
     * Check if an expression contains HXX.hxx() calls
     * HXX templates compile to Phoenix HEEx format via ~H sigils
     * This detection is critical for preserving the "assigns" parameter name
     * 
     * @param expr The TypedExpr to recursively check for HXX calls
     * @return true if HXX.hxx() is found anywhere in the expression tree
     */
    private function containsHxxCall(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TCall(e, el):
                // Check if this is a call to HXX.hxx()
                switch (e.expr) {
                    case TField({expr: TTypeExpr(_)}, FStatic(clsRef, cf)):
                        // Static call like HXX.hxx()
                        var cls = clsRef.get();
                        if (cls.name == "HXX" && cf.get().name == "hxx") {
                            return true;
                        }
                    case _:
                }
                
                // Recursively check the call target and arguments
                if (containsHxxCall(e)) return true;
                for (arg in el) {
                    if (containsHxxCall(arg)) return true;
                }
                
            case TBlock(el):
                // Check all expressions in block
                for (e in el) {
                    if (containsHxxCall(e)) return true;
                }
                
            case TReturn(e):
                // Check return expression
                if (e != null && containsHxxCall(e)) return true;
                
            case TIf(econd, eif, eelse):
                // Check all branches
                if (containsHxxCall(econd)) return true;
                if (containsHxxCall(eif)) return true;
                if (eelse != null && containsHxxCall(eelse)) return true;
                
            case TVar(v, e):
                // Check variable initialization
                if (e != null && containsHxxCall(e)) return true;
                
            case TFunction(f):
                // Check function body
                if (f.expr != null && containsHxxCall(f.expr)) return true;
                
            case TFor(v, it, expr):
                // Check iterator and body
                if (containsHxxCall(it)) return true;
                if (containsHxxCall(expr)) return true;
                
            case TWhile(econd, e, normalWhile):
                // Check condition and body
                if (containsHxxCall(econd)) return true;
                if (containsHxxCall(e)) return true;
                
            case TSwitch(e, cases, edef):
                // Check switch expression and cases
                if (containsHxxCall(e)) return true;
                for (c in cases) {
                    if (c.expr != null && containsHxxCall(c.expr)) return true;
                }
                if (edef != null && containsHxxCall(edef)) return true;
                
            case TBinop(op, e1, e2):
                // Check both operands
                if (containsHxxCall(e1)) return true;
                if (containsHxxCall(e2)) return true;
                
            case TUnop(op, postFix, e):
                // Check operand
                if (containsHxxCall(e)) return true;
                
            case TArrayDecl(el):
                // Check array elements
                for (e in el) {
                    if (containsHxxCall(e)) return true;
                }
                
            case TObjectDecl(fields):
                // Check object field values  
                for (f in fields) {
                    if (containsHxxCall(f.expr)) return true;
                }
                
            case _:
                // Other expression types don't contain HXX calls directly
        }
        
        return false;
    }
}

#end