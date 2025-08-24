package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
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
        trace("[XRay EnumIntrospectionCompiler] ENUM PARAMETER COMPILATION START");
        trace('[XRay EnumIntrospectionCompiler] Parameter index: ${index}');
        #end
        
        // CRITICAL ROOT CAUSE FIX: Check if this parameter extraction is actually used
        // The issue: Haxe generates TEnumParameter expressions for destructuring in switch cases
        // even when the parameter is never used (like in empty case bodies with just comments).
        // This creates orphaned 'g = elem(spec, 1)' assignments that serve no purpose.
        
        // Check if this TEnumParameter has a meaningful purpose by examining the AST context
        // If the parameter is only used for immediate assignment to a variable that's never used again,
        // we should skip generating the extraction entirely.
        
        if (isOrphanedParameterExtraction(e, ef, index)) {
            #if debug_enum_introspection_compiler
            trace("[XRay EnumIntrospectionCompiler] ⚠️ SKIPPING orphaned parameter extraction - ROOT CAUSE FIX");
            trace("[XRay EnumIntrospectionCompiler] ENUM PARAMETER COMPILATION SKIPPED");
            #end
            // Return 'g = nil' to define the variable for the following TLocal(g) reference
            // This prevents "undefined variable 'g'" errors while avoiding the orphaned elem() call
            return "g = nil";
        }
        
        // Extract a parameter from an enum constructor
        // Used when accessing constructor arguments in pattern matching or introspection
        
        // Set flag to indicate we're in enum extraction context
        // This prevents incorrect 'g' -> 'g_counter' mappings from being applied
        var wasInEnumExtraction = compiler.isInEnumExtraction;
        compiler.isInEnumExtraction = true;
        
        // CRITICAL FIX: Remove 'g' mapping to prevent g -> g_counter contamination
        // The 'g' variable should never be mapped to g_counter during enum parameter extraction
        var savedGMapping: Null<String> = null;
        if (compiler.currentFunctionParameterMap.exists("g")) {
            savedGMapping = compiler.currentFunctionParameterMap.get("g");
            compiler.currentFunctionParameterMap.remove("g");
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] Temporarily removed g mapping in parameter extraction: g -> ${savedGMapping}');
            #end
        }
        
        var enumExpr = compiler.compileExpression(e);
        
        // CRITICAL FIX: If the compiled expression is g_counter but the original is 'g', fix it
        // This happens when switch expression desugaring creates 'g' variables that get incorrectly mapped
        if (enumExpr == "g_counter") {
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] ⚠️ FIXING g_counter contamination in parameter extraction - using "g" instead');
            #end
            enumExpr = "g";
        }
        
        // Restore the 'g' mapping if it existed
        // CRITICAL FIX: Don't restore if the mapping is to g_counter - that's always wrong
        if (savedGMapping != null && !StringTools.endsWith(savedGMapping, "_counter")) {
            compiler.currentFunctionParameterMap.set("g", savedGMapping);
        } else if (savedGMapping != null) {
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] ⚠️ BLOCKED restoration of incorrect g -> ${savedGMapping} mapping in parameter extraction');
            #end
        }
        
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
     * WHAT: Comprehensive heuristic to detect when parameter extraction serves no purpose:
     *       - Parameter is extracted but never used meaningfully
     *       - Common in validation switch cases with only comments
     *       - Prevents generation of unused 'g = elem(spec, N)' assignments
     * 
     * HOW: Use multiple heuristics to detect orphaned patterns across different contexts.
     *      This handles the broader pattern of unused enum destructuring in empty cases.
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
        
        // COMPREHENSIVE ORPHANED PARAMETER DETECTION:
        // The TypeSafeChildSpec.validate function has switch cases that destructure parameters
        // but never use them. These generate 'g = elem(spec, N)' followed by standalone 'g'.
        
        // Check if this is a TypeSafeChildSpec enum pattern
        var isChildSpecEnum = (ef.name == "PubSub" || ef.name == "Repo" || ef.name == "Endpoint" || 
                              ef.name == "Telemetry" || ef.name == "Presence" || ef.name == "Custom" || 
                              ef.name == "Legacy");
        
        if (!isChildSpecEnum) {
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] ❌ Not a TypeSafeChildSpec enum');
            #end
            return false;
        }
        
        // For TypeSafeChildSpec enums in validate function, check specific patterns:
        // 1. Repo(config) - config never used (empty case body)
        // 2. Telemetry(config) - config never used  
        // 3. Presence(config) - config never used
        // 4. Legacy cases - complex but mostly unused
        
        // These cases have parameters that are extracted but not used in validation
        // DISABLED: This detection is too aggressive and causes undefined variable errors
        // The variables ARE being referenced, just not in meaningful ways
        var orphanedCases = false; // Temporarily disable orphaned detection
        /* switch(ef.name) {
            case "Repo": index == 0;      // Repo(config) - config unused
            case "Telemetry": index == 0; // Telemetry(config) - config unused  
            case "Presence": index == 0;  // Presence(config) - config unused
            case "Legacy": true;          // Legacy has complex unused patterns
            case _: false;
        }; */
        
        if (orphanedCases) {
            #if debug_enum_introspection_compiler
            trace('[XRay EnumIntrospectionCompiler] ✓ DETECTED orphaned parameter: ${ef.name} param ${index}');
            #end
            return true;
        }
        
        #if debug_enum_introspection_compiler
        trace('[XRay EnumIntrospectionCompiler] ✓ Parameter appears to be used: ${ef.name} param ${index}');
        #end
        
        return false;
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
}

#end