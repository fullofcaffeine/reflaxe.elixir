#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;
using StringTools;

/**
 * TypeResolutionCompiler: Centralized type mapping and resolution system
 * 
 * WHY: Type system mappings between Haxe and Elixir were scattered throughout ElixirCompiler.
 *      Centralized type resolution enables systematic type handling and easier extension of mappings.
 *      Separation of concerns: type resolution logic vs code generation logic.
 * WHAT: Provides comprehensive type mapping from Haxe types to Elixir type specifications,
 *       abstract type handling, standard library detection, and module content management.
 * HOW: Implements focused type analysis methods that examine Haxe Type structures and metadata
 *      to generate appropriate Elixir type representations and manage type definitions.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused entirely on type system mapping and resolution
 * - Open/Closed Principle: Easy to add new type mappings without modifying existing logic
 * - Testability: Type resolution logic can be tested independently from compilation
 * - Maintainability: Clear separation between type analysis and code generation
 * - Performance: Optimized type lookups with systematic caching opportunities
 * 
 * EDGE CASES:
 * - Complex generic type mappings with multiple type parameters
 * - Custom abstract types that need special Elixir representations
 * - Circular type dependencies and recursive type definitions
 * - Dynamic types that can't be statically mapped
 * - Platform-specific type variations between Haxe targets
 * 
 * @see docs/03-compiler-development/TYPE_RESOLUTION.md - Complete type mapping guide
 */
@:nullSafety(Off)
class TypeResolutionCompiler {
    var compiler: ElixirCompiler;

    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }

    /**
     * Get Elixir type representation from Haxe type
     * 
     * WHY: Haxe types need to be mapped to appropriate Elixir type specifications
     * WHAT: Converts Haxe Type structures to Elixir typespec strings
     * HOW: Pattern matches on Type variants and maps to corresponding Elixir types
     * 
     * @param type The Haxe type to convert
     * @return Elixir type specification string
     */
    public function getElixirTypeFromHaxeType(type: Type): String {
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Resolving Haxe type to Elixir: ${type}');
        #end
        
        var result = switch (type) {
            case TInst(_.get() => classType, _):
                switch (classType.name) {
                    case "String": "String.t()";
                    case "Array": "list()";
                    default: "term()";
                }
            case TAbstract(_.get() => abstractType, _):
                switch (abstractType.name) {
                    case "Int": "integer()";
                    case "Float": "float()";
                    case "Bool": "boolean()";
                    default: "term()";
                }
            default:
                "term()";
        };
        
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Type resolution result: ${result}');
        #end
        
        return result;
    }

    /**
     * Check if a type name represents a built-in abstract type
     * 
     * WHY: Built-in abstract types need special handling in compilation
     * WHAT: Identifies core Haxe abstract types that have special semantics
     * HOW: String comparison against known built-in abstract type names
     * 
     * @param name The type name to check
     * @return True if the type is a built-in abstract type
     */
    public function isBuiltinAbstractType(name: String): Bool {
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Checking if builtin abstract type: ${name}');
        #end
        
        var result = switch (name) {
            // Core Haxe types
            case "Int" | "Float" | "Bool" | "String" | "Dynamic" | "Void" | "Any" | "Null" | 
                 "Function" | "Class" | "Enum" | "EnumValue" | "Int32" | "Int64":
                true;
            
            // Standard library containers and collections  
            case "Array" | "Map" | "List" | "Vector" | "Stack" | "GenericStack":
                true;
                
            // Standard library iterators (handled by Elixir's Enum/Stream)
            case "IntIterator" | "ArrayIterator" | "StringIterator" | "MapIterator" |
                 "ArrayKeyValueIterator" | "StringKeyValueIterator" | "MapKeyValueIterator":
                true;
                
            // Standard library utility types (handled internally)
            case "StringBuf" | "StringTools" | "Math" | "Reflect" | "Type" | "Std":
                true;
                
            // Error/debugging types (handled by Elixir's error system)
            case "CallStack" | "Exception" | "Error":
                true;
                
            // Abstract implementation types (compiler-generated)
            case name if (name.endsWith("_Impl_")):
                true;
                
            // Haxe package types (handled separately if needed)
            case name if (name.startsWith("haxe.")):
                true;
                
            default:
                false;
        };
        
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Builtin abstract type check result: ${result}');
        #end
        
        return result;
    }

    /**
     * Check if a class name represents a standard library class
     * 
     * WHY: Standard library classes might need different handling than user classes
     * WHAT: Identifies core Haxe standard library classes
     * HOW: String comparison against known standard library class patterns
     * 
     * @param name The class name to check
     * @return True if the class is from the standard library
     */
    public function isStandardLibraryClass(name: String): Bool {
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Checking if standard library class: ${name}');
        #end
        
        var result = switch (name) {
            // Haxe standard library classes that should be skipped
            case name if (name.startsWith("haxe.") || name.startsWith("sys.") || name.startsWith("js.") || name.startsWith("flash.")):
                true;
                
            // Iterator implementation classes
            case "ArrayIterator" | "StringIterator" | "IntIterator" | "MapIterator" |
                 "ArrayKeyValueIterator" | "StringKeyValueIterator" | "MapKeyValueIterator":
                true;
                
            // Data structure implementation classes
            case "StringBuf" | "StringTools" | "List" | "GenericStack" | "BalancedTree" | "TreeNode":
                true;
                
            // Abstract implementation classes (compiler-generated)
            case name if (name.endsWith("_Impl_")):
                true;
                
            // Built-in type classes
            case "Class" | "Enum" | "Type" | "Reflect" | "Std" | "Math":
                true;
                
            // Regular expression class (has special compiler integration)
            case "EReg":
                true;
                
            default:
                false;
        };
        
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Standard library class check result: ${result}');
        #end
        
        return result;
    }

    /**
     * Get current module content for type definition management
     * 
     * WHY: Type definitions need to be managed within their containing modules
     * WHAT: Retrieves current module content for type definition insertion
     * HOW: Placeholder implementation for module content tracking
     * 
     * @param abstractType The abstract type context
     * @return Current module content or empty string
     */
    public function getCurrentModuleContent(abstractType: AbstractType): Null<String> {
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Getting current module content for: ${abstractType.name}');
        #end
        
        // For now, return a simple placeholder
        // In a full implementation, this would track module content state
        var result = "";
        
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Module content retrieved (length: ${result.length})');
        #end
        
        return result;
    }

    /**
     * Add type definition to module content
     * 
     * WHY: Type definitions need to be properly formatted within modules
     * WHAT: Adds a type alias definition to existing module content
     * HOW: String concatenation with proper formatting and indentation
     * 
     * @param content Existing module content
     * @param typeAlias The type alias definition to add
     * @return Updated module content with new type definition
     */
    public function addTypeDefinition(content: String, typeAlias: String): String {
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Adding type definition: ${typeAlias}');
        #end
        
        var result = content + "\n  " + typeAlias + "\n";
        
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Type definition added, new content length: ${result.length}');
        #end
        
        return result;
    }

    /**
     * Update current module content with new content
     * 
     * WHY: Module content needs to be tracked and updated during compilation
     * WHAT: Updates the module content tracking system with new content
     * HOW: Placeholder implementation for content update tracking
     * 
     * @param abstractType The abstract type context
     * @param content The new content to set
     */
    public function updateCurrentModuleContent(abstractType: AbstractType, content: String): Void {
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Updating module content for: ${abstractType.name} (length: ${content.length})');
        #end
        
        // For now, this is a placeholder - in a full implementation,
        // this would update the module's content in the output system
        
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Module content update completed');
        #end
    }

    /**
     * Compile typedef - Returns null to ignore typedefs as BaseCompiler recommends
     * 
     * WHY: Haxe typedefs should be ignored in Elixir compilation to prevent invalid output
     * WHAT: Handles typedef compilation by returning null (ignore)
     * HOW: Following BaseCompiler recommendation to ignore typedefs
     * 
     * @param defType The typedef to potentially compile
     * @return Always null to ignore typedef compilation
     */
    public function compileTypedefImpl(defType: DefType): Null<String> {
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Ignoring typedef compilation: ${defType.name}');
        #end
        
        // Following BaseCompiler recommendation: ignore typedefs since
        // "Haxe redirects all types automatically" - no standalone typedef files needed
        // 
        // Returning null prevents generating invalid StdTypes.ex files with 
        // @typedoc/@type directives outside modules.
        
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Typedef ignored as recommended by BaseCompiler');
        #end
        
        return null;
    }

    /**
     * Generate type alias definition for abstract types
     * 
     * WHY: Abstract types may need type alias definitions in generated Elixir
     * WHAT: Creates properly formatted type alias for abstract type
     * HOW: Analyzes abstract type and generates appropriate Elixir type alias
     * 
     * @param abstractType The abstract type to generate alias for
     * @return Type alias definition string
     */
    public function generateTypeAlias(abstractType: AbstractType): String {
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Generating type alias for: ${abstractType.name}');
        #end
        
        // Generate basic type alias based on underlying type
        var underlyingType = getElixirTypeFromHaxeType(abstractType.type);
        var result = "@type ${abstractType.name.toLowerCase()}() :: ${underlyingType}";
        
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Generated type alias: ${result}');
        #end
        
        return result;
    }

    /**
     * Resolve type for function parameters and returns
     * 
     * WHY: Function signatures need proper type annotations in generated Elixir
     * WHAT: Maps function parameter and return types to Elixir specs
     * HOW: Analyzes function type and generates appropriate parameter/return specs
     * 
     * @param funcType The function type to analyze
     * @return Function type specification for Elixir
     */
    public function resolveFunctionTypeSpec(funcType: Type): String {
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Resolving function type spec');
        #end
        
        // Simplified function type resolution
        // In a full implementation, this would analyze TFun structure
        var result = "(...) :: term()";
        
        #if debug_type_resolution
//         trace('[TypeResolutionCompiler] Function type spec: ${result}');
        #end
        
        return result;
    }
}

#end