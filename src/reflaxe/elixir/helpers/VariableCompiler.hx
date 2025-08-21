package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.BaseCompiler;

using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * Variable Compiler for Reflaxe.Elixir
 * 
 * WHY: The compileElixirExpressionInternal function contained ~123 lines of variable compilation
 * logic scattered across TLocal and TVar cases. This complex logic included LiveView instance
 * variable mapping, function reference detection, inline context management, variable collision
 * resolution for desugared loops, and sophisticated _this handling for struct updates. Having
 * all this variable-specific logic mixed with expression compilation violated Single Responsibility
 * Principle and made variable handling nearly impossible to maintain and extend.
 * 
 * WHAT: Specialized compiler for all variable-related expressions in Haxe-to-Elixir transpilation:
 * - Local variables (TLocal) → Context-aware variable name resolution and mapping
 * - Variable declarations (TVar) → Proper Elixir variable assignment with collision detection
 * - LiveView instance variables → Automatic socket.assigns mapping for Phoenix LiveView
 * - Function references → Capture syntax for function passing (&function/arity)
 * - Inline context management → _this variable handling for struct updates
 * - Variable collision resolution → Smart renaming for desugared loop variables (_g conflicts)
 * - Parameter mapping → Consistent variable naming across function boundaries
 * - Temporary variable optimization → Elimination of unnecessary temp assignments
 * 
 * HOW: The compiler implements sophisticated variable transformation patterns:
 * 1. Receives TLocal/TVar expressions from ExpressionDispatcher
 * 2. Applies context-sensitive variable name resolution and mapping
 * 3. Handles LiveView framework integration with socket.assigns
 * 4. Detects and resolves variable name collisions in desugared code
 * 5. Manages inline context for struct update optimizations
 * 6. Generates idiomatic Elixir variable assignments and references
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on variable expression compilation
 * - Framework Integration: Deep LiveView and Phoenix pattern knowledge
 * - Context Management: Sophisticated inline context tracking for optimizations
 * - Collision Resolution: Smart handling of Haxe's variable name conflicts
 * - Maintainability: Clear separation from expression and control flow logic
 * - Testability: Variable logic can be independently tested and verified
 * - Extensibility: Easy to add new variable patterns and framework integrations
 * 
 * EDGE CASES:
 * - Variable name collision resolution in desugared for-loops (_g variables)
 * - LiveView instance variable detection and socket.assigns mapping
 * - _this variable handling for inline struct update optimizations
 * - Function reference detection and capture syntax generation
 * - Temporary variable elimination in case arm expressions
 * - Parameter mapping for consistent naming across function boundaries
 * 
 * @see documentation/VARIABLE_COMPILATION_PATTERNS.md - Complete variable transformation patterns
 */
@:nullSafety(Off)
class VariableCompiler {
    
    var compiler: Dynamic; // ElixirCompiler reference
    
    /**
     * Create a new variable compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: Dynamic) {
        this.compiler = compiler;
    }
    
    /**
     * Compile TLocal local variable expressions
     * 
     * WHY: Local variables need context-aware compilation for proper Elixir integration
     * 
     * WHAT: Transform Haxe local variable references to appropriate Elixir equivalents
     * 
     * HOW:
     * 1. Get original variable name (before Haxe's renaming)
     * 2. Apply context-specific mappings (struct, LiveView, function references)
     * 3. Handle parameter mapping for consistent naming
     * 4. Generate appropriate Elixir variable reference
     * 
     * @param v The TVar representing the local variable
     * @return Compiled Elixir variable reference
     */
    public function compileLocalVariable(v: TVar): String {
        #if debug_variable_compiler
        trace("[XRay VariableCompiler] LOCAL VARIABLE COMPILATION START");
        trace('[XRay VariableCompiler] Variable: ${v.name}');
        #end
        
        // Get the original variable name (before Haxe's renaming for shadowing avoidance)
        var originalName = getOriginalVarName(v);
        
        #if debug_variable_compiler
        trace('[XRay VariableCompiler] Original name: ${originalName}');
        #end
        
        // Special handling for inline context variables
        if (originalName == "_this" && compiler.hasInlineContext("struct")) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ INLINE STRUCT CONTEXT DETECTED");
            #end
            return "struct";
        }
        
        // Check if this is a LiveView instance variable that should use socket.assigns
        if (compiler.liveViewInstanceVars != null && compiler.liveViewInstanceVars.exists(originalName)) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ LIVEVIEW INSTANCE VARIABLE DETECTED");
            #end
            var snakeCaseName = NamingHelper.toSnakeCase(originalName);
            return 'socket.assigns.${snakeCaseName}';
        }
        
        // Check if this is a function reference being passed as an argument
        if (compiler.isFunctionReference(v, originalName)) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ FUNCTION REFERENCE DETECTED");
            #end
            return compiler.generateFunctionReference(originalName);
        }
        
        // Use parameter mapping if available (for both abstract methods and regular functions with standardized arg names)
        var result = if (compiler.currentFunctionParameterMap.exists(originalName)) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ PARAMETER MAPPING DETECTED");
            #end
            compiler.currentFunctionParameterMap.get(originalName);
        } else {
            NamingHelper.toSnakeCase(originalName);
        }
        
        #if debug_variable_compiler
        trace('[XRay VariableCompiler] Generated local variable: ${result}');
        trace("[XRay VariableCompiler] LOCAL VARIABLE COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile TVar variable declaration expressions
     * 
     * WHY: Variable declarations require complex handling for optimizations and collision resolution
     * 
     * WHAT: Transform Haxe variable declarations to proper Elixir variable assignments
     * 
     * HOW:
     * 1. Check for unused variable optimization
     * 2. Resolve variable name collisions in desugared code
     * 3. Handle _this inline context management
     * 4. Generate appropriate Elixir variable assignment
     * 5. Optimize temporary variable elimination
     * 
     * @param tvar The TVar representing the variable
     * @param expr The initialization expression (nullable)
     * @return Compiled Elixir variable declaration
     */
    public function compileVariableDeclaration(tvar: TVar, expr: Null<TypedExpr>): String {
        #if debug_variable_compiler
        trace("[XRay VariableCompiler] VARIABLE DECLARATION COMPILATION START");
        trace('[XRay VariableCompiler] Variable: ${tvar.name}');
        trace('[XRay VariableCompiler] Has initialization: ${expr != null}');
        #end
        
        // Check if variable is marked as unused by optimizer
        if (tvar.meta != null && tvar.meta.has("-reflaxe.unused")) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ UNUSED VARIABLE OPTIMIZATION");
            #end
            // Skip generating unused variables, but still evaluate expression if it has side effects
            if (expr != null) {
                return compiler.compileExpression(expr);
            } else {
                return "";  // Don't generate anything for unused variables without init
            }
        }
        
        // Get the original variable name (before Haxe's renaming)
        var originalName = getOriginalVarName(tvar);
        
        #if debug_variable_compiler
        trace('[XRay VariableCompiler] Original name: ${originalName}');
        #end
        
        // CRITICAL FIX: Detect variable name collision in desugared loops
        // When Haxe desugars map/filter, it may reuse variable names like _g
        // for both the accumulator array and the loop counter
        if (StringTools.startsWith(originalName, "_g")) {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ COLLISION DETECTION FOR _g VARIABLES");
            #end
            // Check if this is an array initialization followed by integer reassignment
            if (expr != null) {
                switch (expr.expr) {
                    case TArrayDecl([]):
                        // This is array initialization - use a different name
                        originalName = originalName + "_array";
                        #if debug_variable_compiler
                        trace('[XRay VariableCompiler] Renamed to: ${originalName} (array)');
                        #end
                    case TConst(TInt(0)):
                        // This is counter initialization - use a different name
                        originalName = originalName + "_counter";
                        #if debug_variable_compiler
                        trace('[XRay VariableCompiler] Renamed to: ${originalName} (counter)');
                        #end
                    case _:
                }
            }
        }
        
        // Check if this is _this and needs special handling
        var preserveUnderscore = false;
        if (originalName == "_this") {
            #if debug_variable_compiler
            trace("[XRay VariableCompiler] ✓ _THIS VARIABLE SPECIAL HANDLING");
            #end
            // Check if this is an inline expansion of _this = this.someField
            var isInlineThisInit = switch(expr.expr) {
                case TField(e, _): switch(e.expr) {
                    case TConst(TThis): true;
                    case _: false;
                };
                case _: false;
            };
            
            // Also check if we already have an inline context (struct updates)
            var hasExistingContext = compiler.hasInlineContext("struct");
            
            // Preserve _this if it's an inline expansion OR if inline context is already active
            preserveUnderscore = isInlineThisInit || hasExistingContext;
            
            #if debug_variable_compiler
            trace('[XRay VariableCompiler] Inline init: ${isInlineThisInit}, Existing context: ${hasExistingContext}');
            trace('[XRay VariableCompiler] Preserve underscore: ${preserveUnderscore}');
            #end
        }
        
        var varName = preserveUnderscore ? originalName : NamingHelper.toSnakeCase(originalName);
        
        if (expr != null) {
            // Check if this is an inline expansion of _this = this.someField
            var isInlineThisInit = originalName == "_this" && switch(expr.expr) {
                case TField(e, _): switch(e.expr) {
                    case TConst(TThis): true;
                    case _: false;
                };
                case _: false;
            };
            
            if (isInlineThisInit) {
                #if debug_variable_compiler
                trace("[XRay VariableCompiler] ✓ INLINE THIS INITIALIZATION");
                #end
                // Temporarily disable any existing struct context to compile the right side correctly
                var savedContext = compiler.inlineContextMap.get("struct");
                compiler.inlineContextMap.remove("struct");
                var compiledExpr = compiler.compileExpression(expr);
                
                // Now set the context for future uses - mark struct as active
                compiler.setInlineContext("struct", "active");
                
                // Always use 'struct' for inline expansions instead of '_this'
                return 'struct = ${compiledExpr}';
            } else {
                var compiledExpr = compiler.compileExpression(expr);
                
                // If this is _this and we preserved the underscore, activate inline context
                if (originalName == "_this" && preserveUnderscore) {
                    #if debug_variable_compiler
                    trace("[XRay VariableCompiler] ✓ ACTIVATING INLINE CONTEXT");
                    #end
                    compiler.setInlineContext("struct", "active");
                }
                
                // In case arms, avoid temp variable assignments - return expressions directly
                if (compiler.isCompilingCaseArm && (StringTools.startsWith(originalName, "temp_") || StringTools.startsWith(originalName, "temp"))) {
                    #if debug_variable_compiler
                    trace("[XRay VariableCompiler] ✓ TEMPORARY VARIABLE OPTIMIZATION");
                    #end
                    return compiledExpr;
                }
                
                var result = '${varName} = ${compiledExpr}';
                
                #if debug_variable_compiler
                trace('[XRay VariableCompiler] Generated variable declaration: ${result}');
                trace("[XRay VariableCompiler] VARIABLE DECLARATION COMPILATION END");
                #end
                
                return result;
            }
        } else {
            // In case arms, skip temp variable nil assignments completely
            if (compiler.isCompilingCaseArm && (StringTools.startsWith(originalName, "temp_") || StringTools.startsWith(originalName, "temp"))) {
                #if debug_variable_compiler
                trace("[XRay VariableCompiler] ✓ TEMPORARY NIL OPTIMIZATION");
                #end
                return "nil";
            }
            
            var result = '${varName} = nil';
            
            #if debug_variable_compiler
            trace('[XRay VariableCompiler] Generated nil declaration: ${result}');
            trace("[XRay VariableCompiler] VARIABLE DECLARATION COMPILATION END");
            #end
            
            return result;
        }
    }
    
    /**
     * Get the original variable name before Haxe's internal renaming
     * 
     * WHY: Haxe compiler may rename variables internally, but we want the original names
     * 
     * WHAT: Extract original variable name from TVar metadata if available
     * 
     * HOW: Check :realPath metadata first, fallback to variable name
     * 
     * @param v The TVar to get the original name from
     * @return Original variable name
     */
    public function getOriginalVarName(v: TVar): String {
        #if debug_variable_compiler
        trace("[XRay VariableCompiler] GETTING ORIGINAL VAR NAME");
        trace('[XRay VariableCompiler] TVar name: ${v.name}');
        #end
        
        // Check if the variable has :realPath metadata
        // TVar has both name and meta properties, so we can use the helper
        var originalName = v.getNameOrMeta(":realPath");
        
        #if debug_variable_compiler
        trace('[XRay VariableCompiler] Original name resolved: ${originalName}');
        #end
        
        return originalName;
    }
    
    /**
     * TODO: Future implementation will contain additional extracted utility methods:
     * 
     * - Variable collision detection and resolution algorithms
     * - LiveView instance variable pattern recognition
     * - Function reference detection and capture syntax generation
     * - Inline context management for struct update optimizations
     * - Temporary variable elimination patterns
     * - Parameter mapping consistency utilities
     * - containsVariableReference() - Check if expression references a variable
     * - statementTargetsVariable() - Check if statement targets specific variable
     * - substituteVariableInExpression() - AST variable substitution
     * 
     * These methods will support the main compilation functions with
     * specialized logic for variable handling patterns.
     */
}

#end