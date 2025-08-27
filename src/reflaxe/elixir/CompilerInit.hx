package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import reflaxe.ReflectCompiler;
import reflaxe.elixir.ElixirCompiler;

// Import preprocessor types
import reflaxe.preprocessors.ExpressionPreprocessor;
import reflaxe.preprocessors.ExpressionPreprocessor.*;
import reflaxe.preprocessors.implementations.RemoveTemporaryVariablesImpl.RemoveTemporaryVariablesMode;

/**
 * Initialization and registration of the Elixir compiler
 */
class CompilerInit {
    /**
     * Initialize the Elixir compiler
     * Use --macro reflaxe.elixir.CompilerInit.Start() in your hxml
     */
    public static function Start() {
        haxe.macro.Context.onAfterInitMacros(Begin);
    }
    
    /**
     * Begin compiler registration
     */
    public static function Begin() {
        // Platform check for Haxe 5.0+ only: ensures compiler only runs when
        // --custom-target elixir=output_dir is specified in compilation command.
        // This prevents Reflaxe targets from activating on every compilation.
        // For Haxe 4.x, we skip this check and rely on macro registration only.
        #if (haxe >= version("5.0.0"))
        switch(haxe.macro.Compiler.getConfiguration().platform) {
            case CustomTarget("elixir"):
            case _: 
                return;
        }
        #end
        
        // Register the Elixir compiler with Reflaxe
        ReflectCompiler.AddCompiler(new ElixirCompiler(), {
            fileOutputExtension: ".ex",
            outputDirDefineName: "elixir_output",
            fileOutputType: FilePerModule,
            ignoreTypes: [],
            targetCodeInjectionName: "__elixir__",
            ignoreBodilessFunctions: false,
            
            // Configure Reflaxe 4.0 preprocessors for optimized code generation
            // These preprocessors clean up the AST before we compile it to Elixir
            expressionPreprocessors: [
                SanitizeEverythingIsExpression({}),                      // Convert "everything is expression" to imperative
                RemoveTemporaryVariables(RemoveTemporaryVariablesMode.AllTempVariables), // Remove only "temp" prefixed variables
                PreventRepeatVariables({}),                              // Ensure unique variable names
                RemoveSingleExpressionBlocks,                            // Simplify single-expression blocks
                RemoveConstantBoolIfs,                                   // Remove constant conditional checks
                RemoveUnnecessaryBlocks,                                 // Remove redundant blocks
                RemoveReassignedVariableDeclarations,                    // Optimize variable declarations
                RemoveLocalVariableAliases,                              // Remove unnecessary aliases
                MarkUnusedVariables                                      // Mark unused variables for removal
                // TODO: Fix map.set() operations to reassign in immutable Elixir
                // The issue: map.set(k,v) generates Map.put(map,k,v) without reassignment
                // This makes the map appear "unused" since it's never modified
            ]
        });
    }
}

#end