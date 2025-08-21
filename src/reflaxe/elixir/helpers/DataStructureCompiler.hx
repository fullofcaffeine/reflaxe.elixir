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
 * Data Structure Compiler for Reflaxe.Elixir
 * 
 * WHY: The compileElixirExpressionInternal function contained ~250 lines of data structure compilation
 * logic scattered across TArrayDecl, TObjectDecl, and TArray cases, plus extensive OTP pattern
 * detection helpers (~200 lines). This complexity included child spec detection, supervisor options
 * compilation, atom key determination, and sophisticated Elixir-specific optimizations. Having all
 * this data structure logic mixed with expression compilation violated Single Responsibility Principle.
 * 
 * WHAT: Specialized compiler for all data structure constructs in Haxe-to-Elixir transpilation:
 * - Array literals (TArrayDecl) → Idiomatic Elixir list syntax with proper element compilation
 * - Object declarations (TObjectDecl) → Context-aware map compilation with OTP pattern detection
 * - Array indexing (TArray) → Functional Enum.at operations instead of imperative indexing
 * - Child spec detection → Modern tuple format vs traditional map format based on structure
 * - Supervisor options → Proper keyword list generation for OTP compliance
 * - Atom key optimization → Smart detection of when to use atom keys vs string keys
 * - OTP pattern recognition → Specialized handling for Phoenix.PubSub, Supervisor configs
 * 
 * HOW: The compiler implements sophisticated data structure transformation patterns:
 * 1. Receives TArrayDecl/TObjectDecl/TArray expressions from ExpressionDispatcher
 * 2. Applies pattern-specific analysis for OTP framework integration
 * 3. Detects child spec patterns and chooses appropriate Elixir format
 * 4. Handles supervisor option compilation with proper keyword list syntax
 * 5. Optimizes object key formats (atom vs string) based on usage patterns
 * 6. Generates idiomatic Elixir data structures with functional operations
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on data structure compilation
 * - OTP Pattern Expertise: Specialized knowledge of Elixir/OTP conventions
 * - Framework Integration: Deep understanding of Phoenix and OTP patterns
 * - Type Safety: Proper handling of Elixir's atom/string key distinctions
 * - Maintainability: Clear separation from expression and control flow logic
 * - Testability: Data structure logic can be independently tested and verified
 * - Performance: Optimized for idiomatic Elixir data access patterns
 * 
 * EDGE CASES:
 * - Child spec format detection (modern tuple vs traditional map)
 * - Atom key validation and automatic string key fallback
 * - Phoenix.PubSub special configuration handling
 * - Supervisor strategy atom conversion and validation
 * - Nested object compilation with proper recursion
 * - Variable name resolution in complex OTP configurations
 * 
 * @see documentation/DATA_STRUCTURE_COMPILATION_PATTERNS.md - Complete data structure transformation patterns
 */
@:nullSafety(Off)
class DataStructureCompiler {
    
    var compiler: Dynamic; // ElixirCompiler reference
    
    /**
     * Create a new data structure compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: Dynamic) {
        this.compiler = compiler;
    }
    
    /**
     * Compile TArrayDecl array literal expressions
     * 
     * WHY: Array literals need clean transformation to Elixir list syntax
     * 
     * WHAT: Transform Haxe array literals to idiomatic Elixir list expressions
     * 
     * HOW:
     * 1. Compile each element expression recursively
     * 2. Join elements with proper Elixir list syntax
     * 3. Generate clean [element1, element2, ...] format
     * 
     * @param el Array of TypedExpr representing array elements
     * @return Compiled Elixir array literal
     */
    public function compileArrayLiteral(el: Array<TypedExpr>): String {
        #if debug_data_structure_compiler
        trace("[XRay DataStructureCompiler] ARRAY LITERAL COMPILATION START");
        trace('[XRay DataStructureCompiler] Element count: ${el.length}');
        #end
        
        var result = "[" + el.map(expr -> compiler.compileExpression(expr)).join(", ") + "]";
        
        #if debug_data_structure_compiler
        trace('[XRay DataStructureCompiler] Generated array: ${result}');
        trace("[XRay DataStructureCompiler] ARRAY LITERAL COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile TObjectDecl object declaration expressions with OTP pattern detection
     * 
     * WHY: Object declarations require sophisticated analysis for proper Elixir compilation
     * 
     * WHAT: Transform Haxe object declarations to appropriate Elixir map/keyword formats
     * 
     * HOW:
     * 1. Detect special OTP patterns (child specs, supervisor options)
     * 2. Determine appropriate key format (atoms vs strings)
     * 3. Apply pattern-specific compilation rules
     * 4. Generate idiomatic Elixir maps or keyword lists
     * 
     * @param fields Array of object field declarations
     * @return Compiled Elixir object declaration
     */
    public function compileObjectDeclaration(fields: Array<{name: String, expr: TypedExpr}>): String {
        #if debug_data_structure_compiler
        trace("[XRay DataStructureCompiler] OBJECT DECLARATION COMPILATION START");
        trace('[XRay DataStructureCompiler] Field count: ${fields.length}');
        #end
        
        // Check if this is a Supervisor child spec object
        if (isChildSpecObject(fields)) {
            #if debug_data_structure_compiler
            trace("[XRay DataStructureCompiler] ✓ CHILD SPEC PATTERN DETECTED");
            #end
            return compileChildSpec(fields, compiler.currentClassType);
        }
        
        // Check if this is a Supervisor options object
        if (isSupervisorOptionsObject(fields)) {
            #if debug_data_structure_compiler
            trace("[XRay DataStructureCompiler] ✓ SUPERVISOR OPTIONS PATTERN DETECTED");
            #end
            return compileSupervisorOptions(fields, compiler.currentClassType);
        }
        
        // Determine if this object should use atom keys (for OTP patterns, etc.)
        var useAtoms = shouldUseAtomKeys(fields);
        
        #if debug_data_structure_compiler
        trace('[XRay DataStructureCompiler] Using atom keys: ${useAtoms}');
        #end
        
        var compiledFields = fields.map(f -> {
            if (useAtoms && isValidAtomName(f.name)) {
                // Use idiomatic colon syntax for atom keys: %{name: value}
                f.name + ": " + compiler.compileExpression(f.expr);
            } else {
                // Use arrow syntax for string keys: %{"key" => value}
                '"' + f.name + '"' + " => " + compiler.compileExpression(f.expr);
            }
        });
        
        var result = "%{" + compiledFields.join(", ") + "}";
        
        #if debug_data_structure_compiler
        trace('[XRay DataStructureCompiler] Generated object: ${result.substring(0, 100)}${result.length > 100 ? "..." : ""}');
        trace("[XRay DataStructureCompiler] OBJECT DECLARATION COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile TArray array indexing expressions
     * 
     * WHY: Array indexing needs functional transformation to Elixir list operations
     * 
     * WHAT: Transform imperative array indexing to functional Enum.at operations
     * 
     * HOW:
     * 1. Compile array expression to get the list
     * 2. Compile index expression to get the position
     * 3. Generate Enum.at(list, index) functional operation
     * 
     * @param e1 Array expression
     * @param e2 Index expression
     * @return Compiled Elixir array indexing operation
     */
    public function compileArrayIndexing(e1: TypedExpr, e2: TypedExpr): String {
        #if debug_data_structure_compiler
        trace("[XRay DataStructureCompiler] ARRAY INDEXING COMPILATION START");
        #end
        
        var arrayExpr = compiler.compileExpression(e1);
        var indexExpr = compiler.compileExpression(e2);
        var result = 'Enum.at(${arrayExpr}, ${indexExpr})';
        
        #if debug_data_structure_compiler
        trace('[XRay DataStructureCompiler] Generated indexing: ${result}');
        trace("[XRay DataStructureCompiler] ARRAY INDEXING COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Utility: Validate if a string is a valid Elixir atom name
     * 
     * WHY: Elixir has strict rules for atom names - invalid names must use string keys
     * 
     * @param name The string to validate
     * @return True if the name can be used as an atom
     */
    private function isValidAtomName(name: String): Bool {
        if (name == null || name.length == 0) return false;
        
        // Check first character: must be lowercase letter or underscore
        var firstChar = name.charAt(0);
        if (!((firstChar >= 'a' && firstChar <= 'z') || firstChar == '_')) {
            return false;
        }
        
        // Check remaining characters: alphanumeric or underscore
        for (i in 1...name.length) {
            var char = name.charAt(i);
            if (!((char >= 'a' && char <= 'z') || 
                  (char >= 'A' && char <= 'Z') || 
                  (char >= '0' && char <= '9') || 
                  char == '_')) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Utility: Determine if an object should use atom keys based on field patterns
     * 
     * WHY: Takes a conservative approach - defaults to string keys unless we're certain
     * Only uses atoms for very specific OTP patterns to avoid breaking user code
     * 
     * @param fields Array of object field declarations
     * @return True if atom keys should be used
     */
    private function shouldUseAtomKeys(fields: Array<{name: String, expr: TypedExpr}>): Bool {
        if (fields == null || fields.length == 0) return false;
        
        var fieldNames = fields.map(f -> f.name);
        
        // Only use atom keys for the most obvious OTP supervisor option pattern
        // This requires all three supervisor configuration fields to be present
        var supervisorFields = ["strategy", "max_restarts", "max_seconds"];
        var hasAllSupervisorFields = true;
        for (field in supervisorFields) {
            if (fieldNames.indexOf(field) == -1) {
                hasAllSupervisorFields = false;
                break;
            }
        }
        
        if (hasAllSupervisorFields && fieldNames.length == 3) {
            // Verify all field names can be atoms
            for (field in fields) {
                if (!isValidAtomName(field.name)) {
                    return false;
                }
            }
            return true;
        }
        
        // Check for Phoenix.PubSub configuration pattern
        // Objects with just a "name" field are typically PubSub configs
        if (fieldNames.length == 1 && fieldNames[0] == "name") {
            return isValidAtomName("name");
        }
        
        // Default to string keys for all other cases
        // This is safer and more predictable than trying to guess OTP patterns
        return false;
    }
    
    /**
     * Utility: Check if an object declaration represents a Supervisor child spec
     * 
     * WHY: Child specs have specific "id" and "start" fields that require special compilation
     * 
     * @param fields Array of object field declarations
     * @return True if this is a child spec pattern
     */
    private function isChildSpecObject(fields: Array<{name: String, expr: TypedExpr}>): Bool {
        if (fields == null || fields.length == 0) return false;
        
        var fieldNames = fields.map(f -> f.name);
        return fieldNames.indexOf("id") != -1 && fieldNames.indexOf("start") != -1;
    }
    
    /**
     * Utility: Check if an object declaration represents supervisor options
     * 
     * WHY: Supervisor options require keyword list compilation instead of map syntax
     * 
     * @param fields Array of object field declarations
     * @return True if this is a supervisor options pattern
     */
    private function isSupervisorOptionsObject(fields: Array<{name: String, expr: TypedExpr}>): Bool {
        if (fields == null || fields.length == 0) return false;
        
        var fieldNames = fields.map(f -> f.name);
        return fieldNames.indexOf("strategy") != -1;
    }
    
    /**
     * Specialized: Compile a child spec object to proper Elixir child specification format
     * 
     * WHY: Converts from Haxe objects to Elixir maps as expected by Supervisor.start_link
     * 
     * @param fields Array of object field declarations
     * @param classType Current class type for annotation access
     * @return Compiled Elixir child specification
     */
    private function compileChildSpec(fields: Array<{name: String, expr: TypedExpr}>, classType: Null<ClassType>): String {
        // For now, delegate back to original function to maintain functionality
        // TODO: Extract the full child spec compilation logic
        return compiler.compileChildSpec(fields, classType);
    }
    
    /**
     * Specialized: Compile supervisor options object to proper Elixir keyword list format
     * 
     * WHY: Converts from Haxe objects to Elixir keyword lists as expected by Supervisor.start_link
     * 
     * @param fields Array of object field declarations
     * @param classType Current class type for annotation access
     * @return Compiled Elixir supervisor options
     */
    private function compileSupervisorOptions(fields: Array<{name: String, expr: TypedExpr}>, classType: Null<ClassType>): String {
        // For now, delegate back to original function to maintain functionality
        // TODO: Extract the full supervisor options compilation logic
        return compiler.compileSupervisorOptions(fields, classType);
    }
    
    /**
     * TODO: Future implementation will contain the extracted logic:
     * 
     * - Full child spec compilation with modern tuple vs traditional map detection
     * - Supervisor options compilation with proper keyword list generation
     * - Complex OTP pattern analysis and optimization
     * - Phoenix.PubSub special handling and configuration
     * - Advanced atom key optimization with validation
     * - Nested object compilation with proper recursion
     * - Variable resolution in complex OTP configurations
     * 
     * Each method above will be filled with the actual extracted logic
     * from the original compileElixirExpressionInternal function.
     */
}

#end