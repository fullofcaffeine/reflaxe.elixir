package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.ClassField;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.NameUtils;

/**
 * ModuleBuilder: Responsible for building Elixir module AST nodes from Haxe classes
 * 
 * WHY: Separation of concerns - extract module building logic from the monolithic ElixirASTBuilder
 *      to keep files under 1000 lines and maintain single responsibility principle.
 * 
 * WHAT: Converts Haxe ClassType to Elixir module AST (EDefmodule) with proper metadata
 *       for annotations like @:endpoint, @:liveview, @:schema, @:application, @:phoenixWeb, etc.
 * 
 * HOW: Detects class annotations and sets metadata flags that transformers will use
 *      to apply framework-specific transformations. This builder ONLY builds structure,
 *      never transforms or generates framework-specific code.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only builds module structure
 * - Metadata-Driven: Sets flags for transformers to act upon
 * - Clean Separation: Building vs transformation logic separated
 * - Maintainable Size: Keeps files under 1000 lines
 * - Testable: Can test module building independently
 * 
 * SUPPORTED ANNOTATIONS:
 * - @:endpoint - Phoenix.Endpoint module with web server configuration
 * - @:liveview - Phoenix.LiveView module with mount/handle_event/render
 * - @:schema - Ecto.Schema module with database field definitions
 * - @:repo - Ecto.Repo module with database access functions
 * - @:application - OTP Application module with supervision tree
 * - @:phoenixWeb - Phoenix Web helper module with DSL macros
 * - @:genserver - GenServer behavior module
 * - @:router - Phoenix.Router module with routing DSL
 * - @:controller - Phoenix.Controller module with action functions
 * - @:presence - Phoenix.Presence module with tracking and listing functions
 * 
 * BOOTSTRAP CODE GENERATION:
 * The ModuleBuilder automatically adds bootstrap code for classes with static main() functions,
 * allowing standalone scripts to auto-execute when run with the Elixir command:
 * 
 * ```haxe
 * class Main {
 *     static function main() {
 *         trace("Hello World");
 *     }
 * }
 * ```
 * 
 * Generates:
 * ```elixir
 * defmodule Main do
 *   def main() do
 *     IO.puts("Hello World")
 *   end
 * end
 * Main.main()  # Bootstrap code - auto-executes when script is run
 * ```
 * 
 * This allows running scripts directly: `elixir main.ex`
 * 
 * Bootstrap code is NOT added for:
 * - Classes with @:application annotation (OTP apps have their own startup)
 * - Classes without static main() function
 * - Instance methods named main() (must be static)
 * 
 * METADATA FIELDS SET:
 * - isEndpoint: Boolean flag for @:endpoint annotation
 * - isLiveView: Boolean flag for @:liveview annotation  
 * - isSchema: Boolean flag for @:schema annotation
 * - isRepo: Boolean flag for @:repo annotation
 * - isApplication: Boolean flag for @:application annotation
 * - isPhoenixWeb: Boolean flag for @:phoenixWeb annotation
 * - isGenServer: Boolean flag for @:genserver annotation
 * - isRouter: Boolean flag for @:router annotation
 * - isController: Boolean flag for @:controller annotation
 * - isPresence: Boolean flag for @:presence annotation
 * - appName: String with application name (for endpoint/application/repo)
 * - tableName: String with database table name (for schema)
 * 
 * USAGE:
 * This is called by ElixirCompiler.buildClassAST() when hasSpecialAnnotations() returns true.
 * The metadata set here is consumed by AnnotationTransforms transformation passes.
 * 
 * EDGE CASES:
 * - Class without annotations: Returns regular module body structure
 * - Multiple annotations: First annotation wins (shouldn't happen in practice)
 * - Invalid annotation parameters: Falls back to default values
 */
@:nullSafety(Off)

// Entry point mode for compiled modules
enum EntrypointMode {
    Main; // Standalone script: emit requires + call main()
    Otp;  // OTP application: managed by Mix/OTP, no bootstrap
    None; // Library/module: no bootstrap
}

// Bootstrap emission strategy
enum BootstrapStrategy {
    Inline;   // Emit requires + Main.main() inline in module file
    External; // Defer to final output phase (bootstrap file per module)
}

class ModuleBuilder {
    
    /**
     * Build a module AST from a Haxe class
     * 
     * WHY: Classes need to be converted to Elixir modules with proper structure
     * WHAT: Creates EDefmodule node with metadata for annotations
     * HOW: Extracts class metadata, builds module body, sets transformation flags
     */
    public static function buildClassModule(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        #if debug_module_builder
        #end
        
        // Extract module name
        var moduleName = extractModuleName(classType);
        
        // Set current module context for ElixirASTBuilder
        var previousModule = reflaxe.elixir.ast.ElixirASTBuilder.currentModule;
        reflaxe.elixir.ast.ElixirASTBuilder.currentModule = classType.name;
        
        // Create metadata for the module
        var metadata = createModuleMetadata(classType);
        
        // Build module body based on annotations
        var moduleBody = if (metadata.isPhoenixWeb) {
            // For @:phoenixWeb, create minimal structure - transformer will add macros
            buildMinimalBody(classType, varFields, funcFields);
        } else if (metadata.isEndpoint) {
            // For @:endpoint, create minimal structure - transformer will add the rest
            buildMinimalBody(classType, varFields, funcFields);
        } else if (metadata.isController) {
            // For @:controller, build controller action functions
            buildControllerBody(classType, varFields, funcFields);
        } else if (metadata.isLiveView) {
            // For @:liveview, build basic function structure
            buildLiveViewBody(classType, varFields, funcFields);
        } else if (metadata.isSchema) {
            // For @:schema, build schema structure
            buildSchemaBody(classType, varFields, funcFields);
        } else if (metadata.isRepo) {
            // For @:repo, build minimal structure - transformer will add Ecto.Repo
            buildMinimalBody(classType, varFields, funcFields);
        } else if (metadata.isApplication) {
            // For @:application, build OTP application structure
            buildApplicationBody(classType, varFields, funcFields);
        } else if (metadata.isPresence) {
            // For @:presence, build regular module body - transformer will add Phoenix.Presence
            buildRegularModuleBody(classType, varFields, funcFields);
        } else if (metadata.isExunit) {
            // For @:exunit, build test module body - transformer will add ExUnit.Case
            buildExUnitBody(classType, varFields, funcFields);
        } else {
            // Regular module
            buildRegularModuleBody(classType, varFields, funcFields);
        }
        
        // Create the module AST with metadata
        #if debug_module_builder
        trace('[ModuleBuilder] About to create module AST with metadata: ${metadata}');
        #end
        var moduleAST = makeASTWithMeta(
            EDefmodule(moduleName, moduleBody),
            metadata,
            null
        );
        
        /**
         * BOOTSTRAP CODE GENERATION
         * 
         * WHY: Elixir doesn't automatically execute main() functions like Java or C. 
         *      Users expect to run scripts with `elixir script.ex` and have them execute.
         * 
         * WHAT: Adds a module-level call to ModuleName.main() after the module definition.
         *       This makes the script auto-execute when loaded by the Elixir runtime.
         * 
         * HOW: 
         * 1. Detect if class has static main() function
         * 2. Exclude @:application classes (they have OTP startup)  
         * 3. Generate ECall AST node for ModuleName.main()
         * 4. Wrap module and bootstrap in EBlock
         * 
         * EXAMPLE OUTPUT:
         * ```elixir
         * defmodule MyScript do
         *   def main() do
         *     IO.puts("Hello")
         *   end
         * end
         * MyScript.main()  # <-- Bootstrap code
         * ```
         * 
         * EDGE CASES:
         * - @:application classes are excluded (OTP apps manage their own startup)
         * - Only static main() triggers bootstrap (instance methods don't count)
         * - main() is forced to be public (def) even if marked private in Haxe
         * 
         * DEBUG: Use -D debug_bootstrap to trace bootstrap code generation
         */
        
        // Check for static main() function
        var hasStaticMain = false;
        for (staticField in classType.statics.get()) {
            if (staticField.name == "main") {
                hasStaticMain = true;
                break;
            }
        }

        // Decide entrypoint mode in a single place
        var entrypointMode = determineEntrypointMode(classType, hasStaticMain);

        // Track bootstrap modules regardless of strategy; external writer needs this
        if (entrypointMode == EntrypointMode.Main && ElixirASTBuilder.compiler != null) {
            if (ElixirASTBuilder.compiler.modulesWithBootstrap.indexOf(moduleName) < 0) {
                ElixirASTBuilder.compiler.modulesWithBootstrap.push(moduleName);
            }
        }

        // Add bootstrap code for standalone scripts only, based on strategy
        if (entrypointMode == EntrypointMode.Main && getBootstrapStrategy() == BootstrapStrategy.Inline) {
            #if debug_bootstrap
            trace('[ModuleBuilder] Adding bootstrap code for static main() in ${moduleName}');
            #end
            
            var blockElements: Array<ElixirAST> = [];
            
            // Add Code.require_file statements for dependencies (inline strategy only)
            blockElements = blockElements.concat(generateRequireStatements(classType, moduleName));
            
            // Add the module definition
            blockElements.push(moduleAST);
            
            // Create the bootstrap code that calls main() after the module loads
            // Generate: ModuleName.main() after the module definition
            var bootstrapCode = makeAST(
                ECall(
                    null,  // No receiver (module-level call)
                    moduleName + ".main",  // Full module path (e.g., "Main.main")
                    []  // No arguments to main()
                )
            );
            blockElements.push(bootstrapCode);
            
            // Wrap everything in a block
            // This creates the structure: 
            // Code.require_file("std.ex", __DIR__)  # if needed
            // Code.require_file("haxe/log.ex", __DIR__)  # if needed
            // defmodule Main do ... end
            // Main.main()
            moduleAST = makeAST(EBlock(blockElements));
            
            #if debug_bootstrap  
            trace('[ModuleBuilder] Bootstrap code added after module for ${moduleName}');
            #end
        }
        
        // Restore previous module context
        reflaxe.elixir.ast.ElixirASTBuilder.currentModule = previousModule;
        
        #if debug_module_builder
        trace('[ModuleBuilder] Created module AST for ${moduleName} with metadata: ${metadata}');
        trace('[ModuleBuilder] Module AST metadata check: ${moduleAST.metadata}');
        #end
        
        return moduleAST;
    }

    /**
     * Determine the entrypoint mode for a compiled class.
     * Returns one of: "main" (standalone script), "otp" (OTP application), "none" (library/module).
     * Centralizing this decision keeps bootstrap/require logic in one place.
     */
    static function determineEntrypointMode(classType: ClassType, hasStaticMain: Bool): EntrypointMode {
        // OTP applications manage startup themselves via start/2
        if (classType.meta.has(":application")) return EntrypointMode.Otp;
        // Standalone script mode when a static main() is present
        if (hasStaticMain) {
            // Allow override via -D entrypoint=main|none|otp
            var ep = haxe.macro.Context.definedValue("entrypoint");
            if (ep != null) {
                switch(ep.toLowerCase()) {
                    case "none": return EntrypointMode.None;
                    case "otp": return EntrypointMode.Otp;
                    case "main": return EntrypointMode.Main;
                    default:
                }
            }
            return EntrypointMode.Main;
        }
        return EntrypointMode.None;
    }

    /**
     * Determine bootstrap emission strategy from defines.
     * Priority:
     * 1) bootstrap_strategy=inline|external (string define)
     * 2) inline_bootstrap (boolean define) → Inline
     * 3) Default → External for stricter, deterministic dependency loading
     */
    public static function getBootstrapStrategy(): BootstrapStrategy {
        var val = haxe.macro.Context.definedValue("bootstrap_strategy");
        if (val != null) {
            var v = val.toLowerCase();
            if (v == "inline") return BootstrapStrategy.Inline;
            if (v == "external") return BootstrapStrategy.External;
        }
        if (haxe.macro.Context.defined("inline_bootstrap")) return BootstrapStrategy.Inline;
        return BootstrapStrategy.External;
    }
    
    /**
     * Generate Code.require_file statements for module dependencies
     * 
     * WHY: Standalone scripts need to explicitly load their dependencies
     * WHAT: Creates Code.require_file calls for modules that are actually used
     * HOW: Uses the compiler's dependency tracking to only load needed modules
     * 
     * NOTE: Dependencies are tracked during AST building when ERemoteCall nodes are generated.
     * Only modules that are actually referenced in the code will be required.
     */
    static function generateRequireStatements(classType: ClassType, moduleName: String): Array<ElixirAST> {
        var requires: Array<ElixirAST> = [];
        
        // Get the actual dependencies from the compiler's tracking
        if (ElixirASTBuilder.compiler != null) {
            var deps = ElixirASTBuilder.compiler.moduleDependencies.get(moduleName);
            
            #if debug_bootstrap
            trace('[ModuleBuilder] generateRequireStatements for ${moduleName}');
            trace('[ModuleBuilder] compiler.moduleDependencies has ${[for (k in ElixirASTBuilder.compiler.moduleDependencies.keys()) k].length} modules');
            trace('[ModuleBuilder] Dependencies for ${moduleName}: ${deps != null ? [for (k in deps.keys()) k].join(", ") : "none"}');
            #end
            
            if (deps != null) {
                // Compute transitive closure of dependencies for deterministic and robust loading
                var closure = computeTransitiveDependencies(moduleName);
                
                // Determine output paths
                var outputPaths = ElixirASTBuilder.compiler.moduleOutputPaths;
                
                // Use global topological order and filter to this module's closure for stable ordering
                var topo = ElixirASTBuilder.compiler.getSortedModules();
                
                var ordered: Array<String> = [];
                for (depModule in topo) if (closure.exists(depModule)) ordered.push(depModule);
                // Fallback: if sorted list is incomplete (graph may be partial), use alpha order of closure keys
                if (ordered.length < Lambda.count(closure)) {
                    var allKeys: Array<String> = [for (k in closure.keys()) k];
                    allKeys.sort(function(a, b) return Reflect.compare(a, b));
                    ordered = allKeys;
                }
                for (depModule in ordered) {
                    var filePath = outputPaths.get(depModule);
                    if (filePath == null) {
                        var modulePack = ElixirASTBuilder.compiler.modulePackages.get(depModule);
                        filePath = ElixirASTBuilder.compiler.getModuleOutputPath(depModule, modulePack);
                    }
                    if (filePath != null) {
                        requires.push(makeAST(
                            ECall(
                                null,
                                "Code.require_file",
                                [
                                    makeAST(EString(filePath)),
                                    makeAST(EVar("__DIR__"))
                                ]
                            )
                        ));
                        #if debug_bootstrap
                        trace('[ModuleBuilder] Added require for ${depModule} at ${filePath}');
                        #end
                    }
                }
            }
        }
        
        return requires;
    }

    /**
     * Compute transitive dependency closure for a module using compiler.moduleDependencies
     */
    static function computeTransitiveDependencies(root: String): Map<String, Bool> {
        var result = new Map<String, Bool>();
        if (ElixirASTBuilder.compiler == null) return result;
        var graph = ElixirASTBuilder.compiler.moduleDependencies;
        
        // DFS stack
        var stack: Array<String> = [];
        // Seed with direct deps of root
        var direct = graph.get(root);
        if (direct != null) for (k in direct.keys()) stack.push(k);
        
        while (stack.length > 0) {
            var m = stack.pop();
            if (m == null) break;
            if (m == root) continue; // avoid self
            if (result.exists(m)) continue;
            result.set(m, true);
            var next = graph.get(m);
            if (next != null) for (n in next.keys()) if (!result.exists(n)) stack.push(n);
        }
        return result;
    }
    
    /**
     * Extract the module name from a class, checking for @:native annotation
     */
    static function extractModuleName(classType: ClassType): String {
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
        return classType.name;
    }
    
    /**
     * Create metadata based on class annotations
     * 
     * WHY: Transformers need to know what kind of module this is
     * WHAT: Sets boolean flags and extracts annotation parameters
     * HOW: Checks for known annotations and extracts their parameters
     */
    static function createModuleMetadata(classType: ClassType): ElixirMetadata {
        var metadata: ElixirMetadata = {};
        
        // Check for Phoenix Endpoint
        if (classType.meta.has(":endpoint")) {
            metadata.isEndpoint = true;
            metadata.appName = extractAppName(classType);
            #if debug_module_builder
            #end
        }
        
        // Check for Phoenix LiveView
        if (classType.meta.has(":liveview")) {
            metadata.isLiveView = true;
            #if debug_module_builder
            #end
        }
        
        // Check for Ecto Schema
        if (classType.meta.has(":schema")) {
            metadata.isSchema = true;
            metadata.tableName = extractTableName(classType);
            #if debug_module_builder
            #end
        }
        
        // Check for Ecto Repo
        if (classType.meta.has(":repo")) {
            metadata.isRepo = true;
            metadata.appName = extractAppName(classType);
            #if debug_module_builder
            trace('[ModuleBuilder] ✓ Found @:repo annotation on class: ${classType.name}');
            #end
        }
        
        // Check for OTP Application
        if (classType.meta.has(":application")) {
            metadata.isApplication = true;
            metadata.appName = extractAppName(classType);
            #if debug_module_builder
            #end
        }
        
        // Check for GenServer
        if (classType.meta.has(":genserver")) {
            metadata.isGenServer = true;
            #if debug_module_builder
            #end
        }
        
        // Check for Router
        if (classType.meta.has(":router")) {
            metadata.isRouter = true;
            #if debug_module_builder
            #end
        }
        
        // Check for Controller
        if (classType.meta.has(":controller")) {
            metadata.isController = true;
            metadata.appName = extractAppName(classType);
            #if debug_module_builder
            #end
        }
        
        // Check for Presence
        if (classType.meta.has(":presence")) {
            metadata.isPresence = true;
            metadata.appName = extractAppName(classType);
        }
        
        // Check for PhoenixWeb (supports both @:phoenixWeb and @:phoenixWebModule)
        if (classType.meta.has(":phoenixWeb") || classType.meta.has(":phoenixWebModule")) {
            metadata.isPhoenixWeb = true;
            metadata.appName = extractAppName(classType);
            #if debug_module_builder
            #end
        }
        
        // Check for ExUnit test module
        if (classType.meta.has(":exunit") || classType.meta.has(":elixir.exunit")) {
            metadata.isExunit = true;
            #if debug_module_builder
            trace('[ModuleBuilder] ✓ Found @:exunit on class: ${classType.name}');
            #end
        }
        
        return metadata;
    }
    
    /**
     * Extract application name from class metadata or derive from module name
     */
    static function extractAppName(classType: ClassType): String {
        if (classType.meta.has(":appName")) {
            var appNameMeta = classType.meta.extract(":appName");
            if (appNameMeta.length > 0 && appNameMeta[0].params != null && appNameMeta[0].params.length > 0) {
                switch(appNameMeta[0].params[0].expr) {
                    case EConst(CString(s, _)):
                        return NameUtils.toSnakeCase(s);
                    default:
                }
            }
        }
        
        // Default: derive from module name
        var moduleName = extractModuleName(classType);
        // Remove "Web" suffix if present for Phoenix conventions
        var appName = moduleName.split("Web")[0];
        return NameUtils.toSnakeCase(appName);
    }
    
    /**
     * Extract table name from @:schema annotation or derive from class name
     */
    static function extractTableName(classType: ClassType): String {
        var schemaMeta = classType.meta.extract(":schema");
        if (schemaMeta.length > 0 && schemaMeta[0].params != null && schemaMeta[0].params.length > 0) {
            switch(schemaMeta[0].params[0].expr) {
                case EConst(CString(s, _)):
                    return s;
                default:
            }
        }
        
        // Default: pluralize snake_case class name
        var className = NameUtils.toSnakeCase(classType.name);
        // Simple pluralization (add 's' - could be improved)
        return className + "s";
    }
    
    /**
     * Build minimal body for modules that will be heavily transformed
     * 
     * WHY: Some modules like @:endpoint need complete transformation
     * WHAT: Creates empty or minimal structure
     * HOW: Returns simple block that transformer will replace
     */
    static function buildMinimalBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        // For endpoint and similar, just create an empty block
        // The transformer will add all the necessary structure
        return makeAST(EBlock([]));
    }
    
    /**
     * Build body for Controller modules
     * 
     * WHY: Phoenix controllers need their action functions compiled with proper signatures
     * WHAT: Builds controller action functions that receive conn and params
     * HOW: Compiles each public function as a controller action
     */
    static function buildControllerBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        #if debug_module_builder
        #end
        
        // Compile all functions (public and private) in controllers
        for (func in funcFields) {
            #if debug_module_builder
            #end
            
            if (func.expr() != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                var funcExpr = func.expr();
                
                // Extract parameters and body from the function expression
                switch(funcExpr.expr) {
                    case TFunction(tfunc):
                        var args = [];
                        
                        // Controller actions always take conn and params
                        // The Haxe function should declare these parameters
                        for (arg in tfunc.args) {
                            var paramName = NameUtils.toSnakeCase(arg.v.name);
                            args.push(PVar(paramName));
                        }
                        
                        // Build the function body using ElixirASTBuilder
                        // First analyze variable usage for proper underscore prefixing
                        var functionUsageMap = if (tfunc.expr != null) {
                            reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                        } else {
                            null;
                        };
                        
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr, functionUsageMap);
                        } else {
                            makeAST(ENil);
                        }
                        
                        // Create the function definition (use defp for private functions)
                        if (func.isPublic) {
                            statements.push(makeAST(EDef(funcName, args, null, body)));
                        } else {
                            statements.push(makeAST(EDefp(funcName, args, null, body)));
                        }
                        
                    default:
                        // Not a function, skip
                }
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build body for LiveView modules
     */
    static function buildLiveViewBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        #if debug_module_builder
        #end
        
        // Common Phoenix.Component functions that shouldn't be compiled as local functions
        // These are provided by Phoenix.Component and would conflict if defined locally
        var phoenixComponentFunctions = [
            "assign",
            "assign_multiple", 
            "assign_new",
            "update",
            "get_assign"
        ];
        
        // Add functions (mount, handle_event, render, etc.)
        for (func in funcFields) {
            #if debug_module_builder
            #end
            
            // Skip Phoenix.Component placeholder functions
            if (phoenixComponentFunctions.indexOf(func.name) != -1) {
                #if debug_module_builder
                #end
                continue;
            }
            
            if (func.expr() != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                var funcExpr = func.expr();
                
                // Extract parameters and body from the function expression
                switch(funcExpr.expr) {
                    case TFunction(tfunc):
                        var args = [];
                        
                        // Build parameter patterns for the function
                        for (arg in tfunc.args) {
                            var paramName = NameUtils.toSnakeCase(arg.v.name);
                            args.push(PVar(paramName));
                        }
                        
                        // Build the function body using ElixirASTBuilder
                        // First analyze variable usage for proper underscore prefixing
                        var functionUsageMap = if (tfunc.expr != null) {
                            reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                        } else {
                            null;
                        };
                        
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr, functionUsageMap);
                        } else {
                            makeAST(ENil);
                        }
                        
                        // Check if this is a test function
                        var isTestFunction = func.meta.has(":test");
                        #if debug_module_builder
                        trace('[XRay ModuleBuilder] Function ${funcName} has metadata: ${[for (m in func.meta.get()) m.name].join(", ")}');
                        trace('[XRay ModuleBuilder] isTestFunction: $isTestFunction');
                        #end
                        
                        // Create function definition with metadata
                        // In LiveView modules, ALL functions must be public (def) because
                        // Phoenix framework needs to access them via callbacks
                        var funcAst = makeAST(EDef(funcName, args, null, body));
                        
                        // Add test metadata if this is a test function
                        if (isTestFunction) {
                            var metadata = funcAst.metadata != null ? funcAst.metadata : {};
                            metadata.isTest = true;
                            funcAst = makeASTWithMeta(funcAst.def, metadata, funcAst.pos);
                        }
                        
                        statements.push(funcAst);
                        
                    default:
                        // Not a function, skip
                        #if debug_module_builder
                        #end
                }
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build body for Ecto Schema modules
     */
    static function buildSchemaBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        #if debug_module_builder
        for (func in funcFields) {
        }
        #end
        
        // Schema structure will be added by transformer
        // Build the changeset and other functions with their actual bodies
        for (func in funcFields) {
            var funcExpr = func.expr();
            if (funcExpr != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                
                // Extract the function body from the TypedExpr
                switch(funcExpr.expr) {
                    case TFunction(tfunc):
                        // Extract arguments
                        var args = [];
                        for (arg in tfunc.args) {
                            var paramName = NameUtils.toSnakeCase(arg.v.name);
                            args.push(PVar(paramName));
                        }
                        
                        // Build the function body using ElixirASTBuilder
                        // First analyze variable usage for proper underscore prefixing
                        var functionUsageMap = if (tfunc.expr != null) {
                            reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                        } else {
                            null;
                        };
                        
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr, functionUsageMap);
                        } else {
                            makeAST(ENil);
                        }
                        
                        // Create the function definition (use defp for private functions)
                        if (func.isPublic) {
                            statements.push(makeAST(EDef(funcName, args, null, body)));
                        } else {
                            statements.push(makeAST(EDefp(funcName, args, null, body)));
                        }
                        
                    default:
                        // Not a function, skip
                }
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build body for OTP Application modules
     */
    static function buildApplicationBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        // Build actual functions with their bodies
        for (func in funcFields) {
            var funcExpr = func.expr();
            if (funcExpr != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                
                // Extract the function body from the TypedExpr
                switch(funcExpr.expr) {
                    case TFunction(tfunc):
                        // Extract arguments
                        var args = [];
                        for (arg in tfunc.args) {
                            var paramName = NameUtils.toSnakeCase(arg.v.name);
                            args.push(PVar(paramName));
                        }
                        
                        // Build the function body using ElixirASTBuilder
                        // First analyze variable usage for proper underscore prefixing
                        var functionUsageMap = if (tfunc.expr != null) {
                            reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                        } else {
                            null;
                        };
                        
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr, functionUsageMap);
                        } else {
                            makeAST(ENil);
                        }
                        
                        // Create the function definition (use defp for private functions)
                        if (func.isPublic) {
                            statements.push(makeAST(EDef(funcName, args, null, body)));
                        } else {
                            statements.push(makeAST(EDefp(funcName, args, null, body)));
                        }
                        
                    default:
                        // Not a function, skip
                }
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build body for regular modules (no special annotations)
     * 
     * WHY: Regular modules may have static main() functions that need bootstrap code
     * WHAT: Builds module body and detects if main() exists for bootstrap generation
     * HOW: Checks static fields for main() and stores flag in metadata for later use
     * 
     * BOOTSTRAP DETECTION:
     * This function identifies if a class has a static main() function that should
     * be auto-executed when the script is run with `elixir module.ex`. The detection
     * happens here but the actual bootstrap code is added in buildClassModule().
     */
    static function buildRegularModuleBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        // Check if this module has a static main() function for bootstrap generation
        // Note: We check for main() regardless of visibility since it's a special function
        // that should be callable as the entry point (we force it to be public later)
        var hasStaticMain = false;
        
        // Check in the actual static fields from the class type
        #if debug_bootstrap
        trace('[ModuleBuilder] Checking statics for class ${classType.name}');
        #end
        
        for (staticField in classType.statics.get()) {
            #if debug_bootstrap
            trace('[ModuleBuilder] Found static field: ${staticField.name}');
            #end
            if (staticField.name == "main") {
                hasStaticMain = true;
                #if debug_bootstrap
                trace('[ModuleBuilder] Found static main() function - will add bootstrap code');
                #end
                break;
            }
        }
        
        #if debug_bootstrap
        trace('[ModuleBuilder] Finished checking statics, hasStaticMain: ${hasStaticMain}');
        #end
        
        // Store hasStaticMain in the module's metadata for bootstrap generation
        // This is accessed later in buildClassModule to add bootstrap code after the module
        if (hasStaticMain) {
            // We need to pass this information up to buildClassModule
            // Since we can't modify metadata here, we'll handle it differently
        }
        
        // Add module attributes for fields
        for (field in varFields) {
            var fieldName = NameUtils.toSnakeCase(field.name);
            // For now, just create nil - actual value would come from field.expr()
            statements.push(makeAST(EModuleAttribute(fieldName, makeAST(ENil))));
        }
        
        // Add functions
        for (func in funcFields) {
            var funcExpr = func.expr();
            if (funcExpr != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                
                // Get usage map for proper parameter naming
                var functionUsageMap = switch(funcExpr.expr) {
                    case TFunction(tfunc) if (tfunc.expr != null):
                        reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                    case _:
                        null;
                };
                
                // Build the entire function using ElixirASTBuilder which handles reserved keywords
                var funcAst = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(funcExpr, functionUsageMap);
                
                // The AST builder returns a function, extract it and wrap in def/defp
                switch(funcAst.def) {
                    case EFn(clauses) if (clauses.length > 0):
                        // Extract the first clause (functions typically have one clause)
                        var clause = clauses[0];
                        
                        // Check if this is an instance method (non-static) that needs struct parameter
                        var args = clause.args;
                        // Check if this function is in the static fields list
                        // Instance fields are not in classType.statics
                        var isStatic = false;
                        for (staticField in classType.statics.get()) {
                            if (staticField.name == func.name) {
                                isStatic = true;
                                break;
                            }
                        }
                        if (!isStatic && func.name != "new") {
                            // Instance methods need the struct as first parameter
                            // Check if "this" is used in the function body
                            var thisIsUsed = switch(funcExpr.expr) {
                                case TFunction(tfunc):
                                    reflaxe.elixir.helpers.VariableUsageAnalyzer.containsThisReference(tfunc.expr);
                                default:
                                    true; // Assume it's used if we can't analyze
                            };
                            
                            // Use underscore prefix if "this" is not used
                            var structParamName = thisIsUsed ? "struct" : "_struct";
                            
                            // Add struct parameter as first argument
                            args = [EPattern.PVar(structParamName)].concat(args);
                        }
                        
                        // Create the function definition (use defp for private functions)
                        // Special case: static main() must always be public for bootstrap code to work
                        var forcePublic = (funcName == "main" && isStatic);
                        
                        if (func.isPublic || forcePublic) {
                            statements.push(makeAST(EDef(funcName, args, null, clause.body)));
                        } else {
                            statements.push(makeAST(EDefp(funcName, args, null, clause.body)));
                        }
                    case _:
                        // If it's not a function AST, something went wrong, skip it
                }
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build ExUnit test module body
     * 
     * WHY: ExUnit test classes need special structure with test methods marked
     * WHAT: Processes methods and marks @:test methods with metadata
     * HOW: Adds metadata to test functions for transformer to handle
     */
    static function buildExUnitBody(classType: ClassType, varFields: Array<ClassField>, funcFields: Array<ClassField>): ElixirAST {
        var statements = [];
        
        // Add functions with test metadata
        for (func in funcFields) {
            var funcExpr = func.expr();
            if (funcExpr != null) {
                var funcName = NameUtils.toSnakeCase(func.name);
                
                // Check if this function has @:test or :elixir.test metadata
                var isTest = false;
                var isSetup = false;
                var isSetupAll = false;
                var isTeardown = false;
                var isTeardownAll = false;
                var describeBlock: String = null;
                var isAsync = false;
                var testTags: Array<String> = [];
                
                if (func.meta != null && func.meta.has != null) {
                    isTest = func.meta.has(":test") || func.meta.has("test") || func.meta.has(":elixir.test");
                    
                    // Check for setup/teardown metadata added by ExUnitBuilder
                    if (func.meta.has(":elixir.setup") || func.name == "setup") {
                        isSetup = true;
                    } else if (func.meta.has(":elixir.setupAll") || func.name == "setupAll") {
                        isSetupAll = true;
                    } else if (func.meta.has(":elixir.teardown") || func.name == "teardown") {
                        isTeardown = true;
                    } else if (func.meta.has(":elixir.teardownAll") || func.name == "teardownAll") {
                        isTeardownAll = true;
                    }
                    
                    // Check for describe block metadata
                    if (func.meta.has(":elixir.describe")) {
                        var describeMeta = func.meta.extract(":elixir.describe");
                        if (describeMeta != null && describeMeta.length > 0 && describeMeta[0].params != null && describeMeta[0].params.length > 0) {
                            switch(describeMeta[0].params[0].expr) {
                                case EConst(CString(s, _)): describeBlock = s;
                                default:
                            }
                        }
                    }
                    
                    // Check for async metadata
                    if (func.meta.has(":elixir.async")) {
                        isAsync = true;
                    }
                    
                    // Check for tag metadata (can have multiple tags)
                    if (func.meta.has(":elixir.tag")) {
                        var tagMetas = func.meta.extract(":elixir.tag");
                        if (tagMetas != null) {
                            for (tagMeta in tagMetas) {
                                if (tagMeta.params != null && tagMeta.params.length > 0) {
                                    switch(tagMeta.params[0].expr) {
                                        case EConst(CString(s, _)): testTags.push(s);
                                        default:
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Extract the function body from the TypedExpr
                switch(funcExpr.expr) {
                    case TFunction(tfunc):
                        // Extract arguments
                        var args = [];
                        for (arg in tfunc.args) {
                            var paramName = NameUtils.toSnakeCase(arg.v.name);
                            args.push(PVar(paramName));
                        }
                        
                        // Build the function body using ElixirASTBuilder
                        // First analyze variable usage for proper underscore prefixing
                        var functionUsageMap = if (tfunc.expr != null) {
                            reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(tfunc.expr);
                        } else {
                            null;
                        };
                        
                        var body = if (tfunc.expr != null) {
                            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(tfunc.expr, functionUsageMap);
                        } else {
                            makeAST(ENil);
                        }
                        
                        // Create the function definition (use defp for private functions)
                        var funcAST = if (func.isPublic) {
                            makeAST(EDef(funcName, args, null, body));
                        } else {
                            makeAST(EDefp(funcName, args, null, body));
                        }
                        
                        // Add appropriate metadata to the AST node
                        var metadata: Dynamic = {};
                        if (isTest) metadata.isTest = true;
                        if (isSetup) metadata.isSetup = true;
                        if (isSetupAll) metadata.isSetupAll = true;
                        if (isTeardown) metadata.isTeardown = true;
                        if (isTeardownAll) metadata.isTeardownAll = true;
                        if (describeBlock != null) metadata.describeBlock = describeBlock;
                        if (isAsync) metadata.isAsync = true;
                        if (testTags.length > 0) metadata.testTags = testTags;
                        
                        // Only add metadata if we have any flags set
                        if (isTest || isSetup || isSetupAll || isTeardown || isTeardownAll || describeBlock != null || isAsync || testTags.length > 0) {
                            funcAST = makeASTWithMeta(
                                funcAST.def,
                                metadata,
                                funcAST.pos
                            );
                        }
                        
                        statements.push(funcAST);
                        
                    default:
                        // Not a function, skip
                }
            }
        }
        
        // Return the statements block
        return makeAST(EBlock(statements));
    }
}

#end
