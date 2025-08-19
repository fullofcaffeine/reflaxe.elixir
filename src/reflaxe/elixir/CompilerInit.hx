package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import reflaxe.ReflectCompiler;
import reflaxe.elixir.ElixirCompiler;

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
            ignoreBodilessFunctions: false
        });
    }
}

#end