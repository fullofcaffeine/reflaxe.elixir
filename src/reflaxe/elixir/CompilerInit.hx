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
        // Attach TracePreserve as early as possible to avoid losing race with type loading.
        try {
            var isElixirEarly = (Context.definedValue("target.name") == "elixir") || Context.defined("elixir_output");
            if (isElixirEarly) {
                Compiler.addGlobalMetadata("", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
                // Also register expression-level early rewrite so `trace(v)` is preserved under -D no_traces
                // This runs pre-typing via ExpressionModifier and uses Elixir-only gating here.
                try reflaxe.elixir.macros.TraceEarlyRewrite.register() catch (_:Dynamic) {}
            }
        } catch (_:Dynamic) {}
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

        // Haxe 5+: Attach metadata at onBeforeTyping to guarantee timing.
        // Haxe 4.x: onBeforeTyping is unavailable; attach immediately below.
        #if (haxe >= version("5.0.0"))
        Context.onBeforeTyping(function() {
            var isElixir = (Context.definedValue("target.name") == "elixir") || Context.defined("elixir_output");
            if (!isElixir) return;
            if (stagedStd != null) {
                try Compiler.addClassPath(stagedStd) catch (_:Dynamic) {}
            }
            try {
                #if debug_trace_preserve Sys.println('[CompilerInit] onBeforeTyping: Attaching TracePreserve globally'); #end
                Compiler.addGlobalMetadata("", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
            } catch (_:Dynamic) {}
        });
        #end

        // Attach TracePreserve immediately and also right after init macros, to cover all load timings.
        try {
            var isElixirNow = (Context.definedValue("target.name") == "elixir") || Context.defined("elixir_output");
            if (isElixirNow) {
                Compiler.addGlobalMetadata("", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
                Compiler.addGlobalMetadata("*", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
                Compiler.addGlobalMetadata("*.*", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
                Compiler.addGlobalMetadata("ExternalCaller", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
                Compiler.addGlobalMetadata("Main", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
                Compiler.addGlobalMetadata("TestPresence", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
                // Force-include modules from the current working directory only (test module) so
                // that metadata is applied before these modules are loaded/typed.
                try Compiler.include("", true, null, ["."]) catch (_:Dynamic) {}
            }
        } catch (_:Dynamic) {}

        // Attach TracePreserve right after init macros so it applies to all subsequently loaded types.
        Context.onAfterInitMacros(function() {
            var isElixir = (Context.definedValue("target.name") == "elixir") || Context.defined("elixir_output");
            if (!isElixir) return;
            try {
                Compiler.addGlobalMetadata("", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
                Compiler.addGlobalMetadata("*", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
                Compiler.addGlobalMetadata("*.*", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
                // Explicitly target common test classes used in snapshots
                Compiler.addGlobalMetadata("ExternalCaller", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
                Compiler.addGlobalMetadata("Main", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
                Compiler.addGlobalMetadata("TestPresence", "@:build(reflaxe.elixir.macros.TracePreserve.build())", true);
            } catch (_:Dynamic) {}
        });

        // DEBUG: Inspect metadata presence on key classes after typing
        #if eval
        Context.onAfterTyping(function(types) {
            try {
                var buf = new StringBuf();
                for (t in types) switch (t) {
                    case TClassDecl(c):
                        var cc = c.get();
                        var cn = cc.name;
                        if (cn == 'ExternalCaller' || cn == 'Main' || cn == 'TestPresence') {
                            var meta = cc.meta;
                            buf.add('[' + cn + '] meta entries:\n');
                            for (e in meta.get()) buf.add('  @' + e.name + '\n');
                        }
                    case _:
                }
                if (buf.length > 0) sys.io.File.append('/tmp/trace_meta_scan.log', true).writeString(buf.toString());
            } catch (_:Dynamic) {}
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
