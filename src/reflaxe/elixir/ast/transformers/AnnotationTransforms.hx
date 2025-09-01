package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.EKeywordPair;
import reflaxe.elixir.ast.ElixirAST.EMapPair;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AnnotationTransforms: AST transformation passes for annotation-based modules
 * 
 * WHY: Framework-specific modules (@:endpoint, @:liveview, @:schema) need specialized
 *      transformation from basic module structure to framework-compliant code.
 * 
 * WHAT: Contains transformation passes that detect metadata flags set by ModuleBuilder
 *       and transform the AST to generate proper Phoenix/Ecto/OTP structures.
 * 
 * HOW: Each pass checks for specific metadata flags and transforms the module body
 *      to include framework-specific directives, configurations, and callbacks.
 * 
 * ARCHITECTURE BENEFITS:
 * - Separation of Concerns: Building (ModuleBuilder) vs Transformation (this file)
 * - Single Responsibility: Each pass handles one annotation type
 * - Predictable Pipeline: Metadata-driven, no string manipulation
 * - Maintainable: Small focused functions instead of monolithic code
 * - Extensible: Easy to add new annotation types
 * 
 * SUPPORTED ANNOTATIONS:
 * - @:endpoint - Phoenix.Endpoint with plugs, sockets, and static configuration
 * - @:liveview - Phoenix.LiveView with mount/handle_event/render callbacks
 * - @:schema - Ecto.Schema with field definitions and changeset functions
 * - @:application - OTP Application with supervision tree configuration
 * - @:phoenixWeb - Phoenix Web module with router/controller/live_view macros
 * 
 * TRANSFORMATION PASSES:
 * 1. phoenixWebTransformPass - Adds defmacro definitions for Phoenix DSL
 * 2. endpointTransformPass - Configures Phoenix.Endpoint module structure
 * 3. liveViewTransformPass - Sets up Phoenix.LiveView use statement
 * 4. schemaTransformPass - Adds Ecto.Schema use and schema block
 * 5. applicationTransformPass - Configures OTP Application callbacks
 * 
 * METADATA FLOW:
 * 1. ModuleBuilder detects annotations and sets metadata flags
 * 2. Each transformation pass checks its specific metadata flag
 * 3. If flag is set, module body is transformed with framework code
 * 4. Original module functions are preserved and integrated
 * 
 * EDGE CASES:
 * - Multiple annotations on same module: First match wins
 * - Missing required functions: Default implementations added
 * - Conflicting metadata: Logged and first annotation takes precedence
 */
@:nullSafety(Off)
class AnnotationTransforms {
    
    /**
     * Transform @:endpoint modules into Phoenix.Endpoint structure
     * 
     * WHY: Phoenix endpoints require specific structure with use statement, plugs, and sockets
     * WHAT: Replaces minimal module body with complete endpoint configuration
     * HOW: Detects isEndpoint metadata and builds proper Phoenix.Endpoint AST
     */
    public static function endpointTransformPass(ast: ElixirAST): ElixirAST {
        #if debug_annotation_transforms
        trace('[AnnotationTransforms] EndpointTransformPass starting, checking for endpoint modules');
        trace('[AnnotationTransforms] AST metadata: ${ast.metadata}');
        #end
        
        // Check the top-level node first for Endpoint modules
        switch(ast.def) {
            case EDefmodule(name, body) if (ast.metadata?.isEndpoint == true):
                #if debug_annotation_transforms
                trace('[AnnotationTransforms] Transforming endpoint module: $name');
                trace('[AnnotationTransforms] App name: ${ast.metadata.appName}');
                #end
                
                var appName = ast.metadata.appName ?? "app";
                var endpointBody = buildEndpointBody(name, appName);
                
                // Create new module with endpoint body, preserving metadata
                return makeASTWithMeta(
                    EDefmodule(name, endpointBody),
                    ast.metadata,
                    ast.pos
                );
                
            default:
                // Not an Endpoint module, just pass through
                return ast;
        }
    }
    
    /**
     * Build complete Phoenix.Endpoint module body
     */
    static function buildEndpointBody(moduleName: String, appName: String): ElixirAST {
        var statements = [];
        
        // use Phoenix.Endpoint, otp_app: :app_name
        var useOptions = makeAST(EKeywordList([
            {key: "otp_app", value: makeAST(EAtom(appName))}
        ]));
        statements.push(makeAST(EUse("Phoenix.Endpoint", [useOptions])));
        
        // @session_options configuration
        var sessionOptions = makeAST(EKeywordList([
            {key: "store", value: makeAST(EAtom("cookie"))},
            {key: "key", value: makeAST(EString('_${appName}_key'))},
            {key: "signing_salt", value: makeAST(EString('generated_salt_' + Date.now().getTime()))},
            {key: "same_site", value: makeAST(EString("Lax"))}
        ]));
        // Module attribute as assignment for now (TODO: add proper EModuleAttribute node)
        statements.push(makeAST(EMatch(
            EPattern.PVar("@session_options"),
            sessionOptions
        )));
        
        // socket "/live", Phoenix.LiveView.Socket configuration
        var socketOptions = makeAST(EKeywordList([
            {key: "websocket", value: makeAST(EKeywordList([
                {key: "connect_info", value: makeAST(EKeywordList([
                    {key: "session", value: makeAST(EVar("@session_options"))}
                ]))}
            ]))}
        ]));
        statements.push(makeAST(ECall(null, "socket", [
            makeAST(EString("/live")),
            makeAST(EVar("Phoenix.LiveView.Socket")),
            socketOptions
        ])));
        
        // plug Plug.Static configuration
        // Use the sigil directly for the only option instead of calling a function
        var staticOptions = makeAST(EKeywordList([
            {key: "at", value: makeAST(EString("/"))},
            {key: "from", value: makeAST(EAtom(appName))},
            {key: "gzip", value: makeAST(EBoolean(false))},
            {key: "only", value: makeAST(ESigil(
                "w",
                "assets fonts images favicon.ico robots.txt",
                ""
            ))}
        ]));
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(EVar("Plug.Static")),
            staticOptions
        ])));
        
        // if code_reloading? do plug Phoenix.CodeReloader end
        // Note: code_reloading? is imported by use Phoenix.Endpoint but might need explicit reference
        var codeReloadingBlock = makeAST(EIf(
            makeAST(ECall(null, "Code.ensure_loaded?", [makeAST(EVar("Phoenix.CodeReloader"))])),
            makeAST(ECall(null, "plug", [
                makeAST(EVar("Phoenix.CodeReloader"))
            ])),
            null
        ));
        statements.push(codeReloadingBlock);
        
        // Request pipeline plugs
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(EVar("Plug.RequestId"))
        ])));
        
        var telemetryOptions = makeAST(EKeywordList([
            {key: "event_prefix", value: makeAST(EList([
                makeAST(EAtom("phoenix")),
                makeAST(EAtom("endpoint"))
            ]))}
        ]));
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(EVar("Plug.Telemetry")),
            telemetryOptions
        ])));
        
        // plug Plug.Parsers
        var parsersOptions = makeAST(EKeywordList([
            {key: "parsers", value: makeAST(EList([
                makeAST(EAtom("urlencoded")),
                makeAST(EAtom("multipart")),
                makeAST(EAtom("json"))
            ]))},
            {key: "pass", value: makeAST(EList([makeAST(EString("*/*"))]))},
            {key: "json_decoder", value: makeAST(ERemoteCall(
                makeAST(EVar("Phoenix")),
                "json_library",
                []
            ))}
        ]));
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(EVar("Plug.Parsers")),
            parsersOptions
        ])));
        
        // Other standard plugs
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(EVar("Plug.MethodOverride"))
        ])));
        
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(EVar("Plug.Head"))
        ])));
        
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(EVar("Plug.Session")),
            makeAST(EVar("@session_options"))
        ])));
        
        // Router plug (assumes Web module pattern)
        var routerModule = StringTools.replace(moduleName, ".Endpoint", ".Router");
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(EVar(routerModule))
        ])));
        
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Transform @:liveview modules into Phoenix.LiveView structure
     * 
     * WHY: LiveView modules need specific callbacks and use statement
     * WHAT: Adds use Phoenix.LiveView and ensures proper callback structure
     * HOW: Detects isLiveView metadata and transforms module body
     */
    public static function liveViewTransformPass(ast: ElixirAST): ElixirAST {
        // Check the top-level node first for LiveView modules
        switch(ast.def) {
            case EDefmodule(name, body) if (ast.metadata?.isLiveView == true):
                #if debug_annotation_transforms
                trace('[AnnotationTransforms] Transforming LiveView module: $name');
                #end
                
                var liveViewBody = buildLiveViewBody(name, body);
                
                return makeASTWithMeta(
                    EDefmodule(name, liveViewBody),
                    ast.metadata,
                    ast.pos
                );
                
            default:
                // Not a LiveView module, just pass through
                return ast;
        }
    }
    
    /**
     * Build LiveView module body with proper use statement
     */
    static function buildLiveViewBody(moduleName: String, existingBody: ElixirAST): ElixirAST {
        var statements = [];
        
        // Extract app name from module name (e.g., TodoAppWeb.TodoLive -> todo_app)
        var webIndex = moduleName.indexOf("Web");
        var appNamePart = if (webIndex > 0) {
            moduleName.substring(0, webIndex);
        } else {
            moduleName;
        };
        
        // use TodoAppWeb, :live_view
        statements.push(makeAST(EUse(appNamePart + "Web", [
            makeAST(EAtom("live_view"))
        ])));
        
        // Add existing functions from the body
        switch(existingBody.def) {
            case EBlock(stmts):
                for (stmt in stmts) {
                    // Skip empty statements
                    switch(stmt.def) {
                        case ENil:
                            // Skip
                        default:
                            statements.push(stmt);
                    }
                }
            default:
                statements.push(existingBody);
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Transform @:schema modules into Ecto.Schema structure
     * 
     * WHY: Ecto schemas need specific structure with schema block and changeset
     * WHAT: Adds use Ecto.Schema, schema block with fields, and changeset function
     * HOW: Detects isSchema metadata and transforms module body
     */
    public static function schemaTransformPass(ast: ElixirAST): ElixirAST {
        // Check the top-level node first for Schema modules
        switch(ast.def) {
            case EDefmodule(name, body) if (ast.metadata?.isSchema == true):
                #if debug_annotation_transforms
                trace('[AnnotationTransforms] Transforming schema module: $name');
                trace('[AnnotationTransforms] Table name: ${ast.metadata.tableName}');
                #end
                
                var tableName = ast.metadata.tableName ?? "items";
                var schemaBody = buildSchemaBody(name, tableName, body);
                
                return makeASTWithMeta(
                    EDefmodule(name, schemaBody),
                    ast.metadata,
                    ast.pos
                );
                
            default:
                // Not a Schema module, just pass through
                return ast;
        }
    }
    
    /**
     * Build Ecto.Schema module body
     */
    static function buildSchemaBody(moduleName: String, tableName: String, existingBody: ElixirAST): ElixirAST {
        var statements = [];
        
        // use Ecto.Schema
        statements.push(makeAST(EUse("Ecto.Schema", [])));
        
        // import Ecto.Changeset
        statements.push(makeAST(EImport("Ecto.Changeset", null, null)));
        
        // schema "table_name" do ... end
        // Use EMacroCall for proper do-block syntax
        var schemaFields = makeAST(EBlock([
            // Fields would go here based on class analysis
            makeAST(ECall(null, "field", [
                makeAST(EAtom("name")),
                makeAST(EAtom("string"))
            ])),
            makeAST(ECall(null, "timestamps", []))
        ]));
        
        var schemaBlock = makeAST(EMacroCall(
            "schema",
            [makeAST(EString(tableName))],
            schemaFields
        ));
        statements.push(schemaBlock);
        
        // Add existing functions
        switch(existingBody.def) {
            case EBlock(stmts):
                for (stmt in stmts) {
                    switch(stmt.def) {
                        case ENil:
                            // Skip
                        default:
                            statements.push(stmt);
                    }
                }
            default:
                // Add the body if it's not empty
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Transform @:application modules into OTP Application structure
     * 
     * WHY: OTP applications need specific callbacks and supervision tree
     * WHAT: Adds use Application and start/2 callback
     * HOW: Detects isApplication metadata and transforms module body
     */
    public static function applicationTransformPass(ast: ElixirAST): ElixirAST {
        // Check the top-level node first for Application modules
        switch(ast.def) {
            case EDefmodule(name, body) if (ast.metadata?.isApplication == true):
                #if debug_annotation_transforms
                trace('[AnnotationTransforms] Transforming application module: $name');
                #end
                
                var appBody = buildApplicationBody(name, body);
                
                return makeASTWithMeta(
                    EDefmodule(name, appBody),
                    ast.metadata,
                    ast.pos
                );
                
            default:
                // Not an Application module, just pass through
                return ast;
        }
    }
    
    /**
     * Build OTP Application module body
     */
    static function buildApplicationBody(moduleName: String, existingBody: ElixirAST): ElixirAST {
        var statements = [];
        
        // use Application
        statements.push(makeAST(EUse("Application", [])));
        
        // Add existing functions or create default start/2
        var hasStart = false;
        switch(existingBody.def) {
            case EBlock(stmts):
                for (stmt in stmts) {
                    switch(stmt.def) {
                        case EDef(name, _, _, _) if (name == "start"):
                            hasStart = true;
                            statements.push(stmt);
                        case ENil:
                            // Skip
                        default:
                            statements.push(stmt);
                    }
                }
            default:
                // Add the body if it's not empty
        }
        
        // Add default start/2 if not present
        if (!hasStart) {
            var startBody = makeAST(EBlock([
                // children = []
                makeAST(EMatch(
                    EPattern.PVar("children"),
                    makeAST(EList([]))
                )),
                // opts = [strategy: :one_for_one, name: Module.Supervisor]
                makeAST(EMatch(
                    EPattern.PVar("opts"),
                    makeAST(EKeywordList([
                        {key: "strategy", value: makeAST(EAtom("one_for_one"))},
                        {key: "name", value: makeAST(EVar(moduleName + ".Supervisor"))}
                    ]))
                )),
                // Supervisor.start_link(children, opts)
                makeAST(ERemoteCall(
                    makeAST(EAtom("Supervisor")),
                    "start_link",
                    [
                        makeAST(EVar("children")),
                        makeAST(EVar("opts"))
                    ]
                ))
            ]));
            
            statements.push(makeAST(EDef(
                "start",
                [EPattern.PVar("_type"), EPattern.PVar("_args")],
                null,
                startBody
            )));
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Transform @:phoenixWeb modules into Phoenix Web helper module
     * 
     * WHY: Phoenix Web modules need specific macro definitions for router, controller, etc.
     * WHAT: Adds defmacro definitions that Phoenix expects for 'use TodoAppWeb, :router'
     * HOW: Detects isPhoenixWeb metadata and transforms module body
     */
    public static function phoenixWebTransformPass(ast: ElixirAST): ElixirAST {
        #if debug_annotation_transforms
        trace('[AnnotationTransforms] phoenixWebTransformPass starting');
        trace('[AnnotationTransforms] AST def type: ${ast.def}');
        trace('[AnnotationTransforms] AST metadata: ${ast.metadata}');
        #end
        
        // Check the top-level node first for PhoenixWeb modules
        switch(ast.def) {
            case EDefmodule(name, body) if (ast.metadata?.isPhoenixWeb == true):
                #if debug_annotation_transforms
                trace('[AnnotationTransforms] MATCH! Transforming PhoenixWeb module: $name');
                trace('[AnnotationTransforms] Building Phoenix Web body with macros');
                #end
                
                var phoenixWebBody = buildPhoenixWebBody(name, body);
                
                return makeASTWithMeta(
                    EDefmodule(name, phoenixWebBody),
                    ast.metadata,
                    ast.pos
                );
                
            default:
                // Not a PhoenixWeb module, just pass through
                return ast;
        }
    }
    
    /**
     * Build Phoenix Web module body with macro definitions
     */
    static function buildPhoenixWebBody(moduleName: String, existingBody: ElixirAST): ElixirAST {
        var statements = [];
        
        // Add existing functions first (like static_paths)
        switch(existingBody.def) {
            case EBlock(stmts):
                for (stmt in stmts) {
                    switch(stmt.def) {
                        case ENil:
                            // Skip
                        default:
                            statements.push(stmt);
                    }
                }
            default:
                if (existingBody.def != ENil) {
                    statements.push(existingBody);
                }
        }
        
        // defmacro __using__(which) when is_atom(which) do
        var usingMacroBody = makeAST(ECall(null, "apply", [
            makeAST(EVar("__MODULE__")),
            makeAST(EVar("which")),
            makeAST(EList([]))
        ]));
        
        statements.push(makeAST(EDefmacro(
            "__using__",
            [EPattern.PVar("which")],
            makeAST(ECall(null, "is_atom", [makeAST(EVar("which"))])),
            usingMacroBody
        )));
        
        // Extract base app name from module name (e.g., "TodoAppWeb" -> "TodoApp")
        var appBaseName = StringTools.replace(moduleName, "Web", "");
        
        // def router do
        var routerBody = makeAST(EQuote([], makeAST(EBlock([
            makeAST(EUse("Phoenix.Router", [])),
            makeAST(EImport("Phoenix.LiveView.Router", null, null)),
            makeAST(EImport(moduleName, null, [
                {name: "controller", arity: 0},
                {name: "live_view", arity: 0}, 
                {name: "live_component", arity: 0}
            ])),
            makeAST(ECall(null, "unquote", [makeAST(ECall(null, "verified_routes", []))]))
        ]))));
        
        statements.push(makeAST(EDef(
            "router",
            [],
            null,
            routerBody
        )));
        
        // def controller do
        var controllerBody = makeAST(EQuote([], makeAST(EBlock([
            makeAST(EUse("Phoenix.Controller", [
                makeAST(EKeywordList([
                    {key: "formats", value: makeAST(EList([makeAST(EAtom("html")), makeAST(EAtom("json"))]))},
                    {key: "layouts", value: makeAST(EList([makeAST(EKeywordList([
                        {key: "html", value: makeAST(ETuple([
                            makeAST(EVar(moduleName + ".Layouts")),
                            makeAST(EAtom("app"))
                        ]))}
                    ]))]))}                ]))
            ])),
            makeAST(EImport("Plug.Conn", null, null)),
            makeAST(ECall(null, "unquote", [makeAST(ECall(null, "verified_routes", []))]))
        ]))));
        
        statements.push(makeAST(EDef(
            "controller",
            [],
            null,
            controllerBody
        )));
        
        // def live_view do
        var liveViewBody = makeAST(EQuote([], makeAST(EBlock([
            makeAST(EUse("Phoenix.LiveView", [
                makeAST(EKeywordList([
                    {key: "layout", value: makeAST(ETuple([
                        makeAST(EVar(moduleName + ".Layouts")),
                        makeAST(EAtom("app"))
                    ]))}
                ]))
            ])),
            makeAST(ECall(null, "unquote", [makeAST(ECall(null, "html_helpers", []))])),
            makeAST(EMatch(EPattern.PVar("_"), makeAST(EBlock([]))))
        ]))));
        
        statements.push(makeAST(EDef(
            "live_view",
            [],
            null,
            liveViewBody
        )));
        
        // def live_component do
        var liveComponentBody = makeAST(EQuote([], makeAST(EBlock([
            makeAST(EUse("Phoenix.LiveComponent", [])),
            makeAST(ECall(null, "unquote", [makeAST(ECall(null, "html_helpers", []))]))
        ]))));
        
        statements.push(makeAST(EDef(
            "live_component",
            [],
            null,
            liveComponentBody
        )));
        
        // def html do
        var htmlBody = makeAST(EQuote([], makeAST(EBlock([
            makeAST(EUse("Phoenix.Component", [])),
            makeAST(EImport(moduleName + ".CoreComponents", null, null)),
            makeAST(EImport(moduleName + ".Gettext", null, null)),
            makeAST(ECall(null, "unquote", [makeAST(ECall(null, "html_helpers", []))])),
            makeAST(ECall(null, "unquote", [makeAST(ECall(null, "verified_routes", []))]))
        ]))));
        
        statements.push(makeAST(EDef(
            "html",
            [],
            null,
            htmlBody
        )));
        
        // defp html_helpers do
        var htmlHelpersBody = makeAST(EQuote([], makeAST(EBlock([
            makeAST(EImport("Phoenix.HTML", null, null)),
            makeAST(EImport("Phoenix.HTML.Form", null, null)),
            makeAST(EAlias("Phoenix.HTML.Form", "Form"))
        ]))));
        
        statements.push(makeAST(EDefp(
            "html_helpers",
            [],
            null,
            htmlHelpersBody
        )));
        
        // def verified_routes do
        var verifiedRoutesBody = makeAST(EQuote([], makeAST(EBlock([
            makeAST(EUse("Phoenix.VerifiedRoutes", [
                makeAST(EKeywordList([
                    {key: "endpoint", value: makeAST(EAtom(moduleName + ".Endpoint"))},
                    {key: "router", value: makeAST(EAtom(moduleName + ".Router"))},
                    {key: "statics", value: makeAST(ERemoteCall(
                        makeAST(EVar(moduleName)),
                        "static_paths",
                        []
                    ))}
                ]))
            ]))
        ]))));
        
        statements.push(makeAST(EDef(
            "verified_routes",
            [],
            null,
            verifiedRoutesBody
        )));
        
        // def channel do
        var channelBody = makeAST(EQuote([], makeAST(EBlock([
            makeAST(EUse("Phoenix.Channel", [])),
            makeAST(EImport(moduleName + ".Gettext", null, null))
        ]))));
        
        statements.push(makeAST(EDef(
            "channel",
            [],
            null,
            channelBody
        )));
        
        return makeAST(EBlock(statements));
    }
}

#end