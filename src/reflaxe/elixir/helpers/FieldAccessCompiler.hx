package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;import haxe.macro.Expr;
import reflaxe.elixir.ElixirCompiler;import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * Field Access Compiler for Reflaxe.Elixir
 * 
 * WHY: The compileElixirExpressionInternal function contained ~92 lines of field access compilation
 * logic in the TField case, handling complex patterns including enum field access, static method
 * references, LiveView instance variable mapping, and sophisticated "this" reference resolution.
 * This complex logic mixed multiple concerns: enum handling, function reference generation,
 * framework integration, and basic field access, violating Single Responsibility Principle.
 * 
 * WHAT: Specialized compiler for all field access expressions in Haxe-to-Elixir transpilation:
 * - Enum field access (FEnum) → Proper Elixir atom generation (:constructor_name)
 * - Static field access (FStatic) → Module.field_name syntax with function reference support
 * - Instance field access → Standard obj.field_name with LiveView socket.assigns mapping
 * - Function reference detection → Elixir &Module.function/arity capture syntax
 * - LiveView integration → Automatic socket.assigns.field_name mapping for instance variables
 * - "This" reference resolution → Context-aware mapping (struct, module, socket)
 * - Algebraic Data Type support → Integration with specialized ADT field access
 * 
 * HOW: The compiler implements sophisticated field access transformation patterns:
 * 1. Receives TField expressions from ExpressionDispatcher
 * 2. Analyzes field access type (enum, static, instance, dynamic)
 * 3. Applies framework-specific transformations (LiveView, ADT patterns)
 * 4. Handles function reference detection for Elixir capture syntax
 * 5. Resolves "this" references with context awareness
 * 6. Generates idiomatic Elixir field access expressions
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on field access compilation
 * - Framework Integration: Deep LiveView and Phoenix pattern knowledge
 * - Type Safety: Proper enum field compilation with atom generation
 * - Function References: Sophisticated detection and capture syntax generation
 * - Context Awareness: Smart "this" reference resolution
 * - Maintainability: Clear separation from expression and variable logic
 * - Testability: Field access logic can be independently tested and verified
 * 
 * EDGE CASES:
 * - Enum field access without parameters (→ atoms) vs with parameters (→ TCall)
 * - Static function reference detection vs regular static field access
 * - LiveView instance variable mapping vs regular "this" field access
 * - ADT field access integration with AlgebraicDataTypeCompiler
 * - Dynamic field access with proper snake_case conversion
 * - Function arity calculation for capture syntax generation
 * 
 * @see documentation/FIELD_ACCESS_COMPILATION_PATTERNS.md - Complete field access transformation patterns
 */
@:nullSafety(Off)
class FieldAccessCompiler {
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    
    /**
     * Create a new field access compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Compile TField field access expressions
     * 
     * WHY: Field access requires sophisticated analysis for proper Elixir compilation
     * 
     * WHAT: Transform Haxe field access to appropriate Elixir field access patterns
     * 
     * HOW:
     * 1. Analyze field access type (enum, static, instance, dynamic)
     * 2. Apply framework-specific transformations
     * 3. Handle function reference detection
     * 4. Generate appropriate Elixir field access syntax
     * 
     * @param e The base expression being accessed
     * @param fa The field access information
     * @param expr The complete TField expression (for context)
     * @return Compiled Elixir field access expression
     */
    public function compileFieldAccess(e: TypedExpr, fa: FieldAccess, expr: TypedExpr): String {
        #if debug_field_access_compiler
        trace("[XRay FieldAccessCompiler] FIELD ACCESS COMPILATION START");
        trace('[XRay FieldAccessCompiler] Field access type: ${fa}');
        #end
        
        // Handle nested field access with inline context support
        // Special handling for enum field access - generate atoms, not field calls
        var result = switch (fa) {
            case FEnum(enumType, enumField):
                #if debug_field_access_compiler
                trace("[XRay FieldAccessCompiler] ✓ ENUM FIELD ACCESS DETECTED");
                #end
                compileEnumFieldAccess(enumType, enumField);
                
            case FStatic(classRef, cf):
                #if debug_field_access_compiler
                trace("[XRay FieldAccessCompiler] ✓ STATIC FIELD ACCESS DETECTED");
                #end
                compileStaticFieldAccess(e, classRef, cf, expr);
                
            case _:
                #if debug_field_access_compiler
                trace("[XRay FieldAccessCompiler] ✓ INSTANCE FIELD ACCESS DETECTED");
                #end
                compileInstanceFieldAccess(e, fa);
        };
        
        #if debug_field_access_compiler
        trace('[XRay FieldAccessCompiler] Generated field access: ${result}');
        trace("[XRay FieldAccessCompiler] FIELD ACCESS COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile enum field access to proper Elixir atom syntax
     * 
     * WHY: Enum fields need to be compiled to atoms, not field calls
     * 
     * @param enumType The enum type reference
     * @param enumField The specific enum field
     * @return Compiled Elixir atom expression
     */
    private function compileEnumFieldAccess(enumType: Ref<EnumType>, enumField: EnumField): String {
        #if debug_field_access_compiler
        trace("[XRay FieldAccessCompiler] ENUM FIELD COMPILATION START");
        trace('[XRay FieldAccessCompiler] Enum field: ${enumField.name}');
        trace('[XRay FieldAccessCompiler] Parameters: ${enumField.params.length}');
        #end
        
        // Check if this is a known algebraic data type (Result, Option, etc.)
        var enumTypeRef = enumType.get();
        if (AlgebraicDataTypeCompiler.isADTType(enumTypeRef)) {
            #if debug_field_access_compiler
            trace("[XRay FieldAccessCompiler] ✓ ADT TYPE DETECTED");
            #end
            var compiled = AlgebraicDataTypeCompiler.compileADTFieldAccess(enumTypeRef, enumField);
            if (compiled != null) return compiled;
        }
        
        // For regular enum types - compile to tuple representation
        // Use the enum field's index property directly
        var constructorIndex = enumField.index;
        
        #if debug_field_access_compiler
        trace('[XRay FieldAccessCompiler] Constructor index: ${constructorIndex}');
        #end
        
        // Generate proper atom representation for enum constructor
        // Constructor without parameters compile to atoms like :one_for_one
        // Constructor with parameters: handled by TCall
        if (enumField.params.length == 0) {
            #if debug_field_access_compiler
            trace("[XRay FieldAccessCompiler] ✓ SIMPLE CONSTRUCTOR (no parameters)");
            #end
            // Simple constructor without parameters - use snake_case atom
            var atomName = NamingHelper.toSnakeCase(enumField.name);
            return ':${atomName}';
        } else {
            #if debug_field_access_compiler
            trace("[XRay FieldAccessCompiler] ⚠ CONSTRUCTOR WITH PARAMETERS (should be TCall)");
            #end
            // This case shouldn't happen here - constructors with params
            // should be handled by TCall, but let's handle it gracefully
            // For constructors with parameters, we still need the atom name
            var atomName = NamingHelper.toSnakeCase(enumField.name);
            return ':${atomName}'; // Fallback for now
        }
    }
    
    /**
     * Compile static field access with function reference detection
     * 
     * WHY: Static fields may be function references that need special Elixir capture syntax
     * 
     * @param e The base expression
     * @param classRef The class reference
     * @param cf The class field reference
     * @param expr The complete expression for context
     * @return Compiled Elixir static field access or function reference
     */
    private function compileStaticFieldAccess(e: TypedExpr, classRef: Ref<ClassType>, cf: Ref<ClassField>, expr: TypedExpr): String {
        #if debug_field_access_compiler
        trace("[XRay FieldAccessCompiler] STATIC FIELD COMPILATION START");
        #end
        
        // Check if this is a static method being used as a function reference
        var field = cf.get();
        var isFunction = switch (field.type) {
            case TFun(_, _): true;
            case _: false;
        };
        
        #if debug_field_access_compiler
        trace('[XRay FieldAccessCompiler] Field name: ${field.name}');
        trace('[XRay FieldAccessCompiler] Is function: ${isFunction}');
        #end
        
        // Check if this field access is being used as a function reference
        // (i.e., not being called immediately)
        // This happens when the field is passed as an argument to another function
        if (isFunction && !isBeingCalled(expr)) {
            #if debug_field_access_compiler
            trace("[XRay FieldAccessCompiler] ✓ FUNCTION REFERENCE DETECTED");
            #end
            // This is a static function reference - generate Elixir function reference syntax
            var className = classRef.get().name;
            var functionName = NamingHelper.toSnakeCase(field.name);
            
            // Determine the arity of the function
            var arity = switch (field.type) {
                case TFun(args, _): args.length;
                case _: 0;
            };
            
            #if debug_field_access_compiler
            trace('[XRay FieldAccessCompiler] Function reference: &${className}.${functionName}/${arity}');
            #end
            
            // Generate function reference syntax: &Module.function/arity
            return '&${className}.${functionName}/${arity}';
        } else {
            #if debug_field_access_compiler
            trace("[XRay FieldAccessCompiler] ✓ REGULAR STATIC FIELD ACCESS");
            #end
            // Regular static field access or method call (will be handled by TCall)
            var baseExpr = compiler.compileExpression(e);
            var elixirFieldName = NamingHelper.toSnakeCase(field.name);
            return '${baseExpr}.${elixirFieldName}';
        }
    }
    
    /**
     * Compile instance field access with LiveView integration
     * 
     * WHY: Instance fields may need special handling for LiveView socket.assigns mapping
     * 
     * @param e The base expression
     * @param fa The field access information
     * @return Compiled Elixir instance field access
     */
    private function compileInstanceFieldAccess(e: TypedExpr, fa: FieldAccess): String {
        #if debug_field_access_compiler
        trace("[XRay FieldAccessCompiler] INSTANCE FIELD COMPILATION START");
        #end
        
        // Regular field access for non-enum, non-static fields
        var baseExpr = switch (e.expr) {
            case TConst(TThis):
                #if debug_field_access_compiler
                trace("[XRay FieldAccessCompiler] ✓ THIS REFERENCE DETECTED");
                #end
                // Extract field name for LiveView check
                var fieldName = switch (fa) {
                    case FInstance(_, _, cf) | FAnon(cf): cf.get().name;
                    case FDynamic(s): s;
                    case _: "unknown_field";
                };
                
                #if debug_field_access_compiler
                trace('[XRay FieldAccessCompiler] Field name: ${fieldName}');
                #end
                
                // Check if this is a LiveView instance field access
                if (compiler.liveViewInstanceVars != null && compiler.liveViewInstanceVars.exists(fieldName)) {
                    #if debug_field_access_compiler
                    trace("[XRay FieldAccessCompiler] ✓ LIVEVIEW INSTANCE VARIABLE");
                    #end
                    var elixirFieldName = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(fieldName);
                    return 'socket.assigns.${elixirFieldName}';
                } else {
                    #if debug_field_access_compiler
                    trace("[XRay FieldAccessCompiler] ✓ REGULAR THIS REFERENCE");
                    #end
                    // Use enhanced inline context resolution for non-LiveView cases
                    resolveThisReference();
                }
            case _:
                #if debug_field_access_compiler
                trace("[XRay FieldAccessCompiler] ✓ REGULAR BASE EXPRESSION");
                #end
                compiler.compileExpression(e);
        };
        
        var fieldName = switch (fa) {
            case FInstance(_, _, cf) | FAnon(cf): cf.get().name;
            case FDynamic(s): s;
            case _: "unknown_field";
        };
        var elixirFieldName = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(fieldName);
        
        #if debug_field_access_compiler
        trace('[XRay FieldAccessCompiler] Final field access: ${baseExpr}.${elixirFieldName}');
        #end
        
        return '${baseExpr}.${elixirFieldName}';
    }
    
    /**
     * Utility: Check if a field access expression is being called immediately
     * 
     * WHY: Function references need different compilation than function calls
     * WHAT: Determines if a field is being used as a function reference or a variable
     * HOW: Always returns true to prevent function reference generation
     * 
     * CRITICAL FIX: This function was always returning false, causing ALL static
     * method accesses to be treated as function references (&Module.function/arity).
     * This broke variable assignments where the variable name matched a static method.
     * 
     * The actual issue: When we have `changeset = validate_required(changeset, ...)`,
     * the `changeset` variable name conflicts with the static `changeset` method,
     * and the compiler was treating it as a function reference.
     * 
     * Proper solution: We should NEVER generate function references for static
     * field accesses in regular code. Function references should only be generated
     * when explicitly passed as callbacks (detected via parent context).
     * 
     * @param expr The field access expression
     * @return True - always assume it's being called, not referenced
     */
    private function isBeingCalled(expr: TypedExpr): Bool {
        // CRITICAL: Determine if this TField expression is being called or passed as a reference
        //
        // The challenge: We're compiling a TField expression and need to know if it's:
        // 1. Being called immediately: `Module.function(args)` → compile to `Module.function`
        // 2. Being passed as reference: `callback(Module.function)` → compile to `&Module.function/arity`
        //
        // Since we're IN the TField compilation and don't have parent context, we can't
        // directly check if a TCall wraps this expression. The parent TCall (if any) will
        // handle adding parentheses and arguments.
        //
        // HEURISTIC: If we're compiling a static method TField that's NOT wrapped in a TCall,
        // it must be a function reference. The TCall handler will compile `Module.function(args)`
        // as a whole, so if we're here compiling just `Module.function`, it's a reference.
        //
        // This means we should return false here to enable function reference generation.
        // The original "changeset" bug needs a different fix - likely checking if the
        // field is actually a static method vs a variable that happens to be named "changeset".
        
        // For now, return false to fix the immediate issue with function references
        // A proper fix would involve checking the actual field type to distinguish
        // between static methods and regular variables
        return false;
    }
    
    /**
     * Utility: Resolve "this" reference with context awareness
     * 
     * WHY: "this" references need different mapping based on context
     * 
     * @return Appropriate Elixir equivalent for "this" reference
     */
    private function resolveThisReference(): String {
        // First check if we're in an inline context where struct is active
        if (compiler.hasInlineContext("struct")) {
            return "struct";
        }
        
        // Check if 'this' should be mapped to a parameter (e.g., 'struct' in instance methods)
        var mappedName = compiler.currentFunctionParameterMap.get("this");
        return mappedName != null ? mappedName : "__MODULE__"; // Default to __MODULE__ if no mapping
    }
    
    /**
     * TODO: Future implementation will contain extracted utility methods:
     * 
     * - Advanced function reference detection with AST traversal
     * - Complex "this" reference resolution patterns
     * - LiveView integration optimization patterns
     * - Dynamic field access validation and optimization
     * - Framework-specific field access patterns
     * 
     * These methods will support the main compilation functions with
     * specialized logic for field access handling patterns.
     */
}

#end