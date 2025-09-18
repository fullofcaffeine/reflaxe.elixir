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

        // Default to class name
        return classType.name;
    }

    /**
     * Build a class module AST
     *
     * @param classType The class type
     * @param fields Module fields
     * @return Module AST
     */
    public static function buildClassModule(classType: ClassType, fields: Array<ElixirAST>): ElixirAST {
        #if debug_compilation_hang
        Sys.println('[HANG DEBUG] 🏗️ ModuleBuilder.buildClassModule START - Class: ${classType.name}, Fields: ${fields.length}');
        var moduleStartTime = haxe.Timer.stamp() * 1000;
        #end

        // Stub implementation - return minimal module structure
        var moduleName = extractModuleName(classType);
        var attributes: Array<EAttribute> = []; // No attributes for stub

        var result = {
            def: EModule(moduleName, attributes, fields),
            metadata: {},
            pos: classType.pos
        };

        #if debug_compilation_hang
        var elapsed = (haxe.Timer.stamp() * 1000) - moduleStartTime;
        Sys.println('[HANG DEBUG] ✅ ModuleBuilder.buildClassModule END - Took ${elapsed}ms');
        #end

        return result;
    }
}

#end