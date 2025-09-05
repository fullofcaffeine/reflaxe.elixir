package reflaxe.elixir;

#if (macro || elixir_runtime)

import reflaxe.output.DataAndFileInfo;
import reflaxe.output.StringOrBytes;
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
     * Current position in the iteration
     */
    var index: Int;
    
    /**
     * Total number of items to iterate
     */
    var maxIndex: Int;
    
    /**
     * Constructor
     * @param compiler The ElixirCompiler instance with compiled AST nodes
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
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
    }
    
    /**
     * Check if there are more items to iterate
     * @return True if there are more items
     */
    public function hasNext(): Bool {
        return index < maxIndex;
    }
    
    /**
     * Get the next item and convert it to string output
     * @return DataAndFileInfo with string output
     */
    public function next(): DataAndFileInfo<StringOrBytes> {
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
        final transformedAST = ElixirASTTransformer.transform(astData.data);
        
        #if debug_output_iterator
        trace('[ElixirOutputIterator] Transformation complete');
        #end
        
        // Convert AST to string
        final output = ElixirASTPrinter.print(transformedAST, 0);
        
        #if debug_output_iterator
        trace('[ElixirOutputIterator] Generated ${output.length} characters of output');
        #end
        
        // Return the same DataAndFileInfo but with string output instead of AST
        return astData.withOutput(output);
    }
}

#end