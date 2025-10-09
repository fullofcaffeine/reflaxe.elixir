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
    
    /**
     * Constructor
     * @param compiler The ElixirCompiler instance with compiled AST nodes
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
        this.context = compiler.createCompilationContext();
        index = 0;
        
        // Calculate total items (classes + enums + typedefs + abstracts)
        maxIndex = compiler.classes.length + 
                   compiler.enums.length + 
                   compiler.typedefs.length + 
                   compiler.abstracts.length;
        
        #if debug_output_iterator
        trace('[ElixirOutputIterator] Initialized with ${maxIndex} items to process');
        trace('[ElixirOutputIterator] Classes: ${compiler.classes.length}');
        trace('[ElixirOutputIterator] Enums: ${compiler.enums.length}');
        trace('[ElixirOutputIterator] Typedefs: ${compiler.typedefs.length}');
        trace('[ElixirOutputIterator] Abstracts: ${compiler.abstracts.length}');
        #end

        // Prepare external bootstrap files if strategy requires it
        prepareExternalBootstraps();

        // Emit target-aware extern placeholders after collecting compiled modules
        prepareExternPlaceholders();
    }
    
    /**
     * Check if there are more items to iterate
     * @return True if there are more items
     */
    public function hasNext(): Bool {
        return index < maxIndex || extraIndex < extraOutputs.length;
    }
    
    /**
     * Get the next item and convert it to string output
     * @return DataAndFileInfo with string output
     */
    public function next(): DataAndFileInfo<StringOrBytes> {
        // If normal items are exhausted, serve extra outputs
        if (index >= maxIndex) {
            if (extraIndex < extraOutputs.length) {
                return extraOutputs[extraIndex++];
            }
            // Should not happen if hasNext() is respected
            return new DataAndFileInfo(StringOrBytes.fromString(""), null, "", null);
        }

        // Determine which collection to pull from based on current index
        final astData: DataAndFileInfo<ElixirAST> = if (index < compiler.classes.length) {
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
        trace('[ElixirOutputIterator] Processing item ${index}/${maxIndex}');
        trace('[ElixirOutputIterator] AST data type: ${astData.data.def}');
        trace('[ElixirOutputIterator] AST metadata: ${astData.data.metadata}');
        // Check if it's a module and print the exact metadata fields
        switch(astData.data.def) {
            case EDefmodule(name, _):
                trace('[ElixirOutputIterator] Module name: $name');
                if (astData.data.metadata != null) {
                    trace('[ElixirOutputIterator] Module metadata.isExunit: ${astData.data.metadata.isExunit}');
                    trace('[ElixirOutputIterator] Module metadata fields: ${Reflect.fields(astData.data.metadata)}');
                }
            default:
        }
        #end
        
        // Apply transformation passes to the AST
        // The metadata from the outer AST node needs to be preserved
        // when passing to the transformer
        // Pass the context to ensure metadata is available to transformation passes
        final transformedAST = ElixirASTTransformer.transform(astData.data, context);

        #if debug_output_iterator
        trace('[ElixirOutputIterator] Transformation complete');
        #end

        // Convert AST to string
        var output = ElixirASTPrinter.print(transformedAST, 0);

        // Debug: Check if we're getting empty output
        if (output == null || output.length == 0) {
            trace('[ElixirOutputIterator ERROR] Empty output for module!');
            trace('[ElixirOutputIterator] AST def: ${transformedAST.def}');
        }
        
        #if debug_output_iterator
        trace('[ElixirOutputIterator] Generated ${output.length} characters of output');
        #end
        
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
     * Emit zero-body placeholder modules for referenced Haxe std externs.
     *
     * WHY: Satisfy snapshot presence for std externs without authoring sources.
     * WHAT: For each tracked extern path (e.g., haxe/io/bytes), emit a minimal
     *       defmodule with a nil body under the correct output directory.
     * SAFETY: Skip any path already produced by normal compilation to avoid
     *         duplicate module definitions.
     */
    function prepareExternPlaceholders(): Void {
        if (compiler.externModulesReferenced == null) return;
        // Collect and sort paths for deterministic output ordering
        var externPaths: Array<String> = [];
        for (p in compiler.externModulesReferenced.keys()) externPaths.push(p);
        if (externPaths.length == 0) return;
        externPaths.sort((a, b) -> Reflect.compare(a, b));

        // Build a quick lookup set of existing output paths to avoid duplicates
        var existingPaths = new Map<String, Bool>();
        for (name in compiler.moduleOutputPaths.keys()) {
            var p = compiler.moduleOutputPaths.get(name);
            if (p != null) existingPaths.set(p, true);
        }

        // Helper: convert snake_name to Elixir module name
        inline function toModuleName(base: String): String {
            var isImplLike = base.indexOf("_impl_") >= 0 || (base.length > 0 && (base.charAt(0) == "_" || base.charAt(base.length - 1) == "_"));
            if (isImplLike) {
                var res = "";
                var cap = true;
                for (i in 0...base.length) {
                    var ch = base.charAt(i);
                    if (ch == "_") {
                        res += "_";
                        cap = true;
                    } else {
                        res += (cap ? ch.toUpperCase() : ch);
                        cap = false;
                    }
                }
                return res;
            } else {
                // PascalCase without underscores
                var parts = base.split("_");
                var out = "";
                for (p in parts) if (p.length > 0) out += p.charAt(0).toUpperCase() + p.substr(1);
                return out;
            }
        }

        var fallback = compiler.getFallbackBaseType();
        for (path in externPaths) {
            // Derive directory and file base
            var segments = path.split("/");
            if (segments.length == 0) continue;
            var fileBase = segments[segments.length - 1];
            var dir = segments.length > 1 ? segments.slice(0, segments.length - 1).join("/") : "";

            // Skip if a module already generated this exact relative path
            var candidate = (dir != null && dir.length > 0 ? dir + "/" : "") + fileBase + ".ex";
            if (existingPaths.exists(candidate)) continue;

            // Build minimal module content
            var modName = toModuleName(fileBase);
            var content = 'defmodule ' + modName + ' do\n  nil\nend\n';

            // SAFETY: Require a non-null BaseType to satisfy OutputManager
            if (fallback != null) {
                var data = new DataAndFileInfo<StringOrBytes>(StringOrBytes.fromString(content), fallback, fileBase, dir);
                extraOutputs.push(data);
            }
        }
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
