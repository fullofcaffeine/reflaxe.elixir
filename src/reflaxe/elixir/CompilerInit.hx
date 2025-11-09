package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import reflaxe.ReflectCompiler;
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.io.Path;
import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.macros.LiveViewPreserver;
import haxe.macro.Type;
import haxe.macro.Expr; // for TypedExprTools

// Import preprocessor types
import reflaxe.preprocessors.ExpressionPreprocessor;
import reflaxe.preprocessors.ExpressionPreprocessor.*;
import reflaxe.preprocessors.implementations.RemoveTemporaryVariablesImpl.RemoveTemporaryVariablesMode;
import reflaxe.elixir.preprocessors.PreserveSwitchReturnsImpl;
import reflaxe.elixir.preprocessors.RemoveOrphanedEnumParametersImpl;

/**
 * Initialization and registration of the Elixir compiler
 */
class CompilerInit {
    /**
     * Initialize the Elixir compiler
     * Use --macro reflaxe.elixir.CompilerInit.Start() in your hxml
     */
    public static function Start() {
        #if sys
        // DEBUG ONLY: marker file to confirm CompilerInit.Start() invocation
        try sys.io.File.append('/tmp/compiler_init_called.log', true).writeString('Start() invoked\n') catch (_:Dynamic) {}
        #end
        // TracePreserve attachment is handled by TraceAttach via haxe_libraries/reflaxe.hxml.
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
        
        // Initialize LiveView preservation to prevent DCE from removing Phoenix methods
        LiveViewPreserver.init();

        // (Presence trace parity): build-macro based rewrite remains primary mechanism.

        // Ensure @:repo externs are kept by DCE so they can be scheduled normally
        // for compilation via the AST pipeline (repoTransformPass).
        //
        // WHAT are @:repo externs?
        // - They are Haxe extern classes (no Haxe implementation/body) annotated with @:repo
        //   that describe your Phoenix/Ecto repository module (e.g., TodoApp.Repo).
        // - Example (project code):
        //     @:native("TodoApp.Repo")
        //     @:repo({ adapter: Postgres, json: Jason, extensions: [], poolSize: 10 })
        //     extern class Repo {}
        //
        // WHY must we keep them?
        // - Because externs don’t necessarily create typed references at usage sites, Haxe DCE
        //   may drop them if they appear “unused”, even though the Repo module must exist at runtime
        //   (e.g., in the supervision tree).
        // - Marking them @:keep (and @:used) guarantees they survive DCE and reach our compiler.
        //
        // HOW does compilation proceed?
        // - Our filterTypes() schedules these externs for normal compilation.
        // - The repoTransformPass (in AnnotationTransforms) then converts the extern into an
        //   idiomatic Elixir module that calls `use Ecto.Repo, otp_app: :<app>, adapter: ...` and
        //   writes it to `lib/<app_snake>/repo.ex`.
        try {
            Compiler.addGlobalMetadata("", "@:build(reflaxe.elixir.macros.RepoEnumerator.ensureRepoKept())");
        } catch (e:Dynamic) {}

        // Macro-phase discovery: force-type @:repo externs so they join normal compilation
        try {
            reflaxe.elixir.macros.RepoDiscovery.run();
        } catch (e:Dynamic) {}

        // Compute repo root and staged std path once
        var targetName = Context.definedValue("target.name");
        var stagedStd:String = null;
        try {
            var thisFile = Context.resolvePath("reflaxe/elixir/CompilerInit.hx");
            var d0 = Path.directory(thisFile);
            var d1 = Path.directory(d0);
            var d2 = Path.directory(d1);
            var repoRoot = Path.directory(d2);
            stagedStd = Path.normalize(Path.join([repoRoot, "std/_std"]));
        } catch (_:Dynamic) {}

        // Haxe 5+: add staged std path at onBeforeTyping; TracePreserve handled by TraceAttach.
        #if (haxe >= version("5.0.0"))
        Context.onBeforeTyping(function() {
            var isElixir = (Context.definedValue("target.name") == "elixir") || Context.defined("elixir_output");
            if (!isElixir) return;
            if (stagedStd != null) {
                try Compiler.addClassPath(stagedStd) catch (_:Dynamic) {}
            }
        });
        #end


        // Register the Elixir compiler with Reflaxe
        ReflectCompiler.AddCompiler(new ElixirCompiler(), {
            fileOutputExtension: ".ex",
            outputDirDefineName: "elixir_output",
            fileOutputType: FilePerModule,
            ignoreTypes: [],
            targetCodeInjectionName: "__elixir__",
            ignoreBodilessFunctions: false,
            // Keep ignoring externs by default; @:repo externs are scheduled via RepoEnumerator + filterTypes
            ignoreExterns: true,
            
            // Configure Reflaxe 4.0 preprocessors for optimized code generation
            // These preprocessors clean up the AST before we compile it to Elixir
            expressionPreprocessors: [
                // CRITICAL: PreserveSwitchReturns MUST run FIRST before any other preprocessors
                // This prevents Haxe's typer from simplifying switch-in-return expressions
                // which would lose all pattern matching structure needed for Elixir
                Custom(new PreserveSwitchReturnsImpl()),                 // Preserve switch expressions in return position

                // DISABLED: EverythingIsExprSanitizer is for statement-oriented targets (C++, Java)
                // Elixir is expression-oriented like Haxe - expressions can appear everywhere
                // This sanitizer was causing bugs like losing switch bodies in return statements
                // SanitizeEverythingIsExpression({}),  // NOT needed for Elixir

                RemoveTemporaryVariables(RemoveTemporaryVariablesMode.AllTempVariables), // Remove only "temp" prefixed variables
                PreventRepeatVariables({}),                              // Ensure unique variable names
                RemoveSingleExpressionBlocks,                            // Simplify single-expression blocks
                RemoveConstantBoolIfs,                                   // Remove constant conditional checks
                RemoveUnnecessaryBlocks,                                 // Remove redundant blocks
                RemoveReassignedVariableDeclarations,                    // Optimize variable declarations
                RemoveLocalVariableAliases,                              // Remove unnecessary aliases
                // IMPORTANT: Fix variable usage detection before marking unused variables
                Custom(new reflaxe.elixir.preprocessors.FixVariableUsageDetection()),
                MarkUnusedVariables,                                     // Mark unused variables for removal
                Custom(new RemoveOrphanedEnumParametersImpl())          // Remove orphaned enum parameter extractions
            ]
        });
    }
}

#end
