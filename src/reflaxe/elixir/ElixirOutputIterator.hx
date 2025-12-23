package reflaxe.elixir;

#if (macro || elixir_runtime)

import reflaxe.output.DataAndFileInfo;
import reflaxe.output.StringOrBytes;
import reflaxe.elixir.ast.builders.ModuleBuilder; // For strategy
import reflaxe.elixir.ast.NameUtils; // snake_case helpers
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * ElixirOutputIterator: Handles AST to String Conversion
 * 
 * WHY: GenericCompiler returns AST nodes, but Reflaxe needs strings for file output.
 * This iterator bridges that gap by transforming and printing AST nodes to strings.
 * 
 * WHAT: Iterates through compiled AST nodes (classes, enums, etc.) and converts them
 * to properly formatted Elixir source code strings.
 * 
 * HOW: 
 * - Iterates through all compiled AST nodes from ElixirCompiler
 * - Applies transformation passes via ElixirASTTransformer
 * - Converts to strings via ElixirASTPrinter
 * - Returns DataAndFileInfo with string output for Reflaxe to write to files
 * - If bootstrap strategy is External, also emits bootstrap_<module>.ex files after
 *   module generation that load transitive dependencies in topological order and
 *   call Module.main(). This defers require generation to the final output phase
 *   for deterministic and complete loading semantics.
 * 
 * ARCHITECTURE BENEFITS:
 * - Clean separation between AST compilation and string generation
 * - Enables multi-pass transformations before final output
 * - Follows C# compiler's proven pattern
 * 
 * @see CSOutputIterator for the C# reference implementation
 */
@:access(reflaxe.elixir.ElixirCompiler)
class ElixirOutputIterator {
    /**
     * Reference to the compiler containing compiled AST nodes
     */
    var compiler: ElixirCompiler;

    /**
     * Compilation context for transformations
     */
    var context: reflaxe.elixir.CompilationContext;

    /**
     * Current position in the iteration
     */
    var index: Int;
    
    /**
     * Total number of items to iterate
     */
    var maxIndex: Int;

    // Extra outputs generated after all normal modules (e.g., bootstrap files)
    var extraOutputs: Array<DataAndFileInfo<StringOrBytes>> = [];
    var extraIndex: Int = 0;

    // Cached next output so `hasNext()` can accurately account for suppressed emissions.
    var preparedNext: Null<DataAndFileInfo<StringOrBytes>> = null;
    
    /**
     * Constructor
     * @param compiler The ElixirCompiler instance with compiled AST nodes
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
        this.context = compiler.createCompilationContext();
        index = 0;

        // Repo emission is now scheduled during normal compilation via filterTypes + repoTransformPass.
        // No extra outputs are synthesized here.

        // Calculate total items (classes + enums + typedefs + abstracts)
        maxIndex = compiler.classes.length + 
                   compiler.enums.length + 
                   compiler.typedefs.length + 
                   compiler.abstracts.length;
        
        #if debug_output_iterator
        #if debug_output_iterator trace('[ElixirOutputIterator] Initialized with ${maxIndex} items to process'); #end
        #if debug_output_iterator trace('[ElixirOutputIterator] Classes: ${compiler.classes.length}'); #end
        #if debug_output_iterator trace('[ElixirOutputIterator] Enums: ${compiler.enums.length}'); #end
        #if debug_output_iterator trace('[ElixirOutputIterator] Typedefs: ${compiler.typedefs.length}'); #end
        #if debug_output_iterator trace('[ElixirOutputIterator] Abstracts: ${compiler.abstracts.length}'); #end
        #end

        // Prepare external bootstrap files if strategy requires it
        prepareExternalBootstraps();
    }
    
    /**
     * Check if there are more items to iterate
     * @return True if there are more items
     */
    public function hasNext(): Bool {
        if (preparedNext != null) return true;
        preparedNext = prepareNextOutput();
        return preparedNext != null;
    }
    
    /**
     * Get the next item and convert it to string output
     * @return DataAndFileInfo with string output
     */
    public function next(): DataAndFileInfo<StringOrBytes> {
        if (preparedNext == null) {
            preparedNext = prepareNextOutput();
        }
        final result = preparedNext;
        preparedNext = null;
        if (result == null) {
            throw "ElixirOutputIterator.next() called with no remaining output";
        }
        return result;
    }

    function prepareNextOutput(): Null<DataAndFileInfo<StringOrBytes>> {
        while (true) {
            // If normal items are exhausted, serve extra outputs
            if (index >= maxIndex) {
                if (extraIndex < extraOutputs.length) {
                    return extraOutputs[extraIndex++];
                }
                return null;
            }

            // Determine which collection to pull from based on current index
            var astData: DataAndFileInfo<ElixirAST> = if (index < compiler.classes.length) {
                // Get from classes
                compiler.classes[index];
            } else if (index < compiler.classes.length + compiler.enums.length) {
                // Get from enums
                compiler.enums[index - compiler.classes.length];
            } else if (index < compiler.classes.length + compiler.enums.length + compiler.typedefs.length) {
                // Get from typedefs
                compiler.typedefs[index - compiler.classes.length - compiler.enums.length];
            } else {
                // Get from abstracts
                compiler.abstracts[index - compiler.classes.length - compiler.enums.length - compiler.typedefs.length];
            }

            index++;

            #if debug_output_iterator
            // DISABLED: trace('[ElixirOutputIterator] Processing item ${index}/${maxIndex}');
            // Debug the DataAndFileInfo overrides for this item
            var moduleName = switch(astData.data.def) {
                case EModule(name, _, _): name;
                case EDefmodule(name, _): name;
                default: "(unknown)";
            };
            var originalSize = switch (astData.data.def) {
                case EModule(_, _, body): body != null ? Std.string(body.length) : "null";
                case EDefmodule(_, doBlock):
                    switch (doBlock.def) {
                        case EBlock(exprs): exprs != null ? Std.string(exprs.length) : "null";
                        case EDo(exprs2): exprs2 != null ? Std.string(exprs2.length) : "null";
                        default: "unknown";
                    }
                default:
                    "unknown";
            };
            trace('[ElixirOutputIterator] Input module: ${moduleName} (size=${originalSize})');
            // DISABLED: trace('[ElixirOutputIterator] Module: ${moduleName}');
            // DISABLED: trace('[ElixirOutputIterator] overrideFileName: ${astData.overrideFileName}');
            // DISABLED: trace('[ElixirOutputIterator] overrideDirectory: ${astData.overrideDirectory}');
            #end

            // Apply transformation passes to the AST
            // The metadata from the outer AST node needs to be preserved
            // when passing to the transformer
            // Pass the context to ensure metadata is available to transformation passes
            final transformedAST = ElixirASTTransformer.transform(astData.data, context);

            #if debug_output_iterator trace('[ElixirOutputIterator] Transformation complete'); #end

            // Generic gating: suppress emission of compile-time-only empty modules
            // WHAT: Avoid generating `.ex` files for modules that have no runtime content
            // WHY: Macro-only helpers (e.g., std/ecto/*Macros, std/HXX) previously emitted empty stubs
            // HOW: Detect EDefmodule/EModule nodes with empty bodies and skip yielding output
            if (shouldSuppressEmission(transformedAST)) {
                #if debug_output_iterator
                // Get module name from AST for debug
                var moduleName = switch(transformedAST.def) {
                    case EModule(name, _, _): name;
                    case EDefmodule(name, _): name;
                    default: "(unknown)";
                };
                var reason = "structural";
                if (transformedAST.metadata != null) {
                    if (transformedAST.metadata.suppressEmission == true) reason = "metadata.suppressEmission";
                    else if (transformedAST.metadata.forceEmit == true) reason = "metadata.forceEmit";
                }
                var sizeInfo = switch (transformedAST.def) {
                    case EModule(_, _, body): body != null ? Std.string(body.length) : "null";
                    case EDefmodule(_, doBlock):
                        switch (doBlock.def) {
                            case EBlock(exprs): exprs != null ? Std.string(exprs.length) : "null";
                            case EDo(exprs2): exprs2 != null ? Std.string(exprs2.length) : "null";
                            default: "unknown";
                        }
                    default:
                        "unknown";
                };
                trace('[ElixirOutputIterator] SUPPRESSING emission of: ${moduleName} (reason=${reason}, size=${sizeInfo})');
                #end

                // Continue scanning for the next non-suppressed output.
                continue;
            }

            // Convert AST to string
            var output = ElixirASTPrinter.print(transformedAST, 0);

            // Debug: Check if we're getting empty output
            if (output == null || output.length == 0) { /* silent by default */ }

            #if debug_output_iterator trace('[ElixirOutputIterator] Generated ${output.length} characters of output'); #end

            // Inline-deterministic strategy: inject requires + Module.main() into the
            // module file AFTER compilation using the full dependency graph.
            //
            // WHY: Guarantees deterministic ordering (topological) and complete transitive
            // closure while keeping a single-file entrypoint (no .exs runner).
            if (ModuleBuilder.getBootstrapStrategy() == BootstrapStrategy.InlineDeterministic) {
                // Attempt to map the current BaseType back to the module name used in maps
                var moduleName: Null<String> = null;
                for (name in compiler.moduleBaseTypes.keys()) {
                    if (compiler.moduleBaseTypes.get(name) == astData.baseType) {
                        moduleName = name;
                        break;
                    }
                }
                if (moduleName != null && compiler.modulesWithBootstrap.indexOf(moduleName) >= 0) {
                    // Compute deterministic require list using transitive closure and topo order
                    var closure = computeTransitiveDependencies(moduleName);
                    var topo = compiler.getSortedModules();
                    var ordered: Array<String> = [];
                    for (m in topo) if (closure.exists(m)) ordered.push(m);
                    if (ordered.length < Lambda.count(closure)) {
                        var allKeys: Array<String> = [for (k in closure.keys()) k];
                        allKeys.sort((a, b) -> Reflect.compare(a, b));
                        ordered = allKeys;
                    }
                    var lines: Array<String> = [];
                    for (dep in ordered) {
                        // Skip self when injecting inline
                        if (dep == moduleName) continue;
                        var p = compiler.moduleOutputPaths.get(dep);
                        if (p == null) {
                            var pack = compiler.modulePackages.get(dep);
                            p = compiler.getModuleOutputPath(dep, pack);
                        }
                        if (p != null) lines.push('Code.require_file("' + p + '", __DIR__)');
                    }
                    // Build final inline output: requires + module + main call
                    var injected = (lines.length > 0 ? lines.join("\n") + "\n" : "")
                        + output + "\n" + moduleName + ".main()";
                    // Ensure trailing newline for consistent diffs
                    output = injected + "\n";
                }
            }

            // Return the same DataAndFileInfo but with string output instead of AST
            return astData.withOutput(output);
        }
    }

    /**
     * Returns true when the transformed AST corresponds to an empty module that
     * should not be emitted as a file (compile-time-only helpers, inline-only).
     */
    static function shouldSuppressEmission(ast: ElixirAST): Bool {
        if (ast == null) return false;
        // Honor explicit metadata first
        if (ast.metadata != null) {
            // If explicitly forced to emit, never suppress
            if (ast.metadata.forceEmit == true) return false;
            if (ast.metadata.suppressEmission == true) return true;
        }

        // Structural empty-module detection
        return switch (ast.def) {
            case EDefmodule(_, doBlock):
                switch (doBlock.def) {
                    case EBlock(exprs): exprs == null || exprs.length == 0;
                    case EDo(body): body == null || body.length == 0;
                    default: false;
                }
            case EModule(_, _, body):
                body == null || body.length == 0;
            default:
                false;
        }
    }

    /**
     * Prepare external bootstrap files when using the External strategy.
     * Aggregates dependency graph AFTER compilation for deterministic and complete requires.
     */
    function prepareExternalBootstraps(): Void {
        // Respect bootstrap strategy: only generate externals for External strategy
        if (ModuleBuilder.getBootstrapStrategy() != BootstrapStrategy.External) return;
        // Only emit scripts when explicitly requested to avoid cluttering snapshots
        #if macro
        if (!haxe.macro.Context.defined("emit_bootstrap_scripts")) return;
        #end
        if (compiler.modulesWithBootstrap.length == 0) return;

        // Build global topological order once
        var topo = compiler.getSortedModules();

        var generatedFor: Array<String> = [];
        for (moduleName in compiler.modulesWithBootstrap) {
            // Compute transitive closure for this module
            var closure = computeTransitiveDependencies(moduleName);
            // Ordered list filtered by topo
            var ordered: Array<String> = [];
            for (m in topo) if (closure.exists(m)) ordered.push(m);
            // Fallback: alpha order of closure keys if needed
            if (ordered.length < Lambda.count(closure)) {
                var allKeys: Array<String> = [for (k in closure.keys()) k];
                allKeys.sort((a, b) -> Reflect.compare(a, b));
                ordered = allKeys;
            }

            // Build bootstrap script content
            var lines: Array<String> = [];
            for (dep in ordered) {
                var filePath = compiler.moduleOutputPaths.get(dep);
                if (filePath == null) {
                    var pack = compiler.modulePackages.get(dep);
                    filePath = compiler.getModuleOutputPath(dep, pack);
                }
                if (filePath != null) {
                    lines.push('Code.require_file("' + filePath + '", __DIR__)');
                }
            }
            // Require the main module file itself
            var mainPath = compiler.moduleOutputPaths.get(moduleName);
            if (mainPath == null) {
                var pack = compiler.modulePackages.get(moduleName);
                mainPath = compiler.getModuleOutputPath(moduleName, pack);
            }
            if (mainPath != null) {
                lines.push('Code.require_file("' + mainPath + '", __DIR__)');
            }
            // Call Main.main()
            lines.push(moduleName + '.main()');

            var content = lines.join("\n");
            // Emit a separate bootstrap script to avoid colliding with module files.
            // Use a distinct name (bootstrap_<module>). Output manager will add .ex.
            var fileBase = 'bootstrap_' + NameUtils.toSnakeCase(moduleName);

            // Construct output info with override name/dir
            var baseType = compiler.moduleBaseTypes.exists(moduleName) ? compiler.moduleBaseTypes.get(moduleName) : null;
            // SAFETY: OutputManager requires a non-null BaseType for filename resolution.
            // If we cannot map a BaseType (unexpected), skip emitting the script to avoid crashes.
            if (baseType != null) {
                var data = new DataAndFileInfo<StringOrBytes>(StringOrBytes.fromString(content), baseType, fileBase, null);
                extraOutputs.push(data);
            }
            generatedFor.push(moduleName);
        }

        // No generic main file to avoid name collision with module file.
    }

    /**
     * Compute transitive dependency closure for a module using compiler.moduleDependencies
     */
    inline function computeTransitiveDependencies(root: String): Map<String, Bool> {
        var result = new Map<String, Bool>();
        var graph = compiler.moduleDependencies;
        var stack: Array<String> = [];
        var direct = graph.get(root);
        if (direct != null) for (k in direct.keys()) stack.push(k);
        while (stack.length > 0) {
            var m = stack.pop();
            if (m == null) break;
            if (m == root) continue;
            if (result.exists(m)) continue;
            result.set(m, true);
            var next = graph.get(m);
            if (next != null) for (n in next.keys()) if (!result.exists(n)) stack.push(n);
        }
        return result;
    }
}

#end
