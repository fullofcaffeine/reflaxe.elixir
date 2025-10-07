package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;

/**
 * Bootstrap strategy for module loading
 */
enum BootstrapStrategy {
    None;                    // No bootstrap needed
    InlineDeterministic;     // Inline require statements
    External;                // External bootstrap file
}

/**
 * ModuleBuilder: Builds Elixir module structures
 *
 * WHY: Module generation is complex with many concerns: naming, imports,
 * attributes, functions, and bootstrap strategies. This builder centralizes
 * that logic.
 *
 * WHAT: Handles all aspects of Elixir module generation including defmodule
 * structure, use statements, imports, and bootstrap code generation.
 *
 * HOW: Provides a builder API for constructing modules piece by piece,
 * then generates the appropriate AST structure.
 *
 * ARCHITECTURE BENEFITS:
 * - Single responsibility for module generation
 * - Consistent module structure across all types
 * - Bootstrap strategy abstraction
 *
 * NOTE: This is a CONSERVATIVE stub implementation for Phase 2 integration.
 * Returns minimal, safe module structures. Full implementation in Phase 3.
 */
class ModuleBuilder {
    private static var bootstrapStrategy: BootstrapStrategy = None;

    /**
     * Get the current bootstrap strategy
     */
    public static function getBootstrapStrategy(): BootstrapStrategy {
        return bootstrapStrategy;
    }

    /**
     * Set the bootstrap strategy
     */
    public static function setBootstrapStrategy(strategy: BootstrapStrategy): Void {
        bootstrapStrategy = strategy;
    }

    /**
     * Extract module name from a ClassType
     *
     * @param classType The class to extract name from
     * @return The module name
     */
    public static function extractModuleName(classType: ClassType): String {
        // Check for @:native annotation first
        if (classType.meta.has(":native")) {
            var nativeMeta = classType.meta.extract(":native");
            if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                switch(nativeMeta[0].params[0].expr) {
                    case EConst(CString(s, _)):
                        return s;
                    default:
                }
            }
        }
        
        // For @:application classes without @:native, append ".Application" to module name
        // This follows Phoenix/OTP convention where applications are named AppName.Application
        if (classType.meta.has(":application") && !classType.meta.has(":native")) {
            return classType.name + ".Application";
        }

        // Default to class name
        return classType.name;
    }

    /**
     * Build a class module AST with support for exception classes
     *
     * @param classType The class type to compile
     * @param fields Module fields (functions, properties, etc.)
     * @param metadata Optional metadata containing inheritance info
     * @return Module AST with appropriate structure (regular module or exception)
     * 
     * @example Building a regular class:
     * ```haxe
     * var moduleAST = ModuleBuilder.buildClassModule(classType, fields, null);
     * ```
     * 
     * @example Building an exception class:
     * ```haxe
     * var metadata = { isException: true, parentModule: "Exception" };
     * var moduleAST = ModuleBuilder.buildClassModule(classType, fields, metadata);
     * ```
     */
    public static function buildClassModule(classType: ClassType, fields: Array<ElixirAST>, ?metadata: ElixirMetadata): ElixirAST {
        #if debug_compilation_hang
        Sys.println('[HANG DEBUG] 🏗️ ModuleBuilder.buildClassModule START - Class: ${classType.name}, Fields: ${fields.length}');
        var moduleStartTime = haxe.Timer.stamp() * 1000;
        #end

        var moduleName = extractModuleName(classType);
        var attributes: Array<EAttribute> = [];

        // Use provided metadata or create empty object
        var moduleMetadata = metadata != null ? metadata : {};

        // Ensure critical annotation flags propagate even if caller forgot to set them
        // This keeps downstream AnnotationTransforms robust.
        #if (macro)
        try {
            // classType.meta is available at macro-time
            if (classType.meta.has(":router")) {
                moduleMetadata.isRouter = true;
            }
        } catch (e: Dynamic) {
            // Ignore meta inspection failures
        }
        #end

        // Check if this is an exception class
        if (moduleMetadata.isException == true) {
            #if debug_inheritance
            trace('[ModuleBuilder] Generating exception module for ${moduleName}');
            #end
            
            // Don't add defstruct for exceptions - defexception handles it automatically
            // The ElixirASTPrinter will handle the defexception macro when it sees isException metadata
            // Just keep the regular fields (methods like toString)
        }

        var result: ElixirAST = null;

        // Prefer EDefmodule form for special annotated modules that downstream transforms expect
        if (moduleMetadata != null && (moduleMetadata.isRouter == true || moduleMetadata.isPresence == true)) {
            // Wrap provided fields in a block as the module body
            var body = makeAST(EBlock(fields));
            result = {
                def: EDefmodule(moduleName, body),
                metadata: moduleMetadata,
                pos: classType.pos
            };
        } else {
            result = {
                def: EModule(moduleName, attributes, fields),
                metadata: moduleMetadata,
                pos: classType.pos
            };
        }

        #if debug_compilation_hang
        var elapsed = (haxe.Timer.stamp() * 1000) - moduleStartTime;
        Sys.println('[HANG DEBUG] ✅ ModuleBuilder.buildClassModule END - Took ${elapsed}ms');
        #end

        return result;
    }
    
    /**
     * Create the defstruct definition for exception classes
     * 
     * @return AST node representing defstruct with message field
     * 
     * Generates: `defstruct message: ""`
     */
    static function makeExceptionStructDefinition(): ElixirAST {
        // Create the struct definition with message field
        // This simulates defexception which creates a struct with message
        return makeAST(ECall(
            null,
            "defstruct",
            [makeAST(EKeywordList([
                {key: "message", value: makeAST(EString(""))}
            ]))]
        ));
    }
    
    /**
     * Helper function to create AST nodes
     * 
     * @param def The AST definition
     * @return ElixirAST node with empty metadata
     */
    static inline function makeAST(def: ElixirASTDef): ElixirAST {
        return {
            def: def,
            metadata: {},
            pos: null
        };
    }
}

#end
