package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.EKeywordPair;
import reflaxe.elixir.ast.ElixirAST.EMapPair;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.ast.NameUtils;

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
 * - @:repo - Ecto.Repo with database access functions
 * - @:postgrexTypes - Postgrex precompiled types module (Types.define)
 * - @:application - OTP Application with supervision tree configuration
 * - @:phoenixWeb - Phoenix Web module with router/controller/live_view macros
 * - @:controller - Phoenix.Controller with action functions
 * - @:channel - Phoenix.Channel with join/handle_in/handle_out callbacks
 * - @:presence - Phoenix.Presence with tracking and listing callbacks
 * - @:exunit - ExUnit.Case test modules with test functions
 * 
 * TRANSFORMATION PASSES:
 * 1. phoenixWebTransformPass - Adds defmacro definitions for Phoenix DSL
 * 2. endpointTransformPass - Configures Phoenix.Endpoint module structure
 * 3. liveViewTransformPass - Sets up Phoenix.LiveView use statement
 * 4. schemaTransformPass - Adds Ecto.Schema use and schema block
 * 5. repoTransformPass - Adds Ecto.Repo use with otp_app and adapter
 * 6. applicationTransformPass - Configures OTP Application callbacks
 * 7. controllerTransformPass - Sets up Phoenix.Controller use statement
 * 8. routerTransformPass - Sets up Phoenix.Router with pipelines and routes
 * 9. presenceTransformPass - Sets up Phoenix.Presence use statement
 * 10. exunitTransformPass - Sets up ExUnit.Case with test functions
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
        // DISABLED: trace('[XRay Endpoint Transform] Checking AST node type: ${ast.def}');
        if (ast.metadata?.isEndpoint == true) {
            // DISABLED: trace('[XRay Endpoint Transform] Found endpoint module with metadata');
        }
        #end
        
        // Check the top-level node first for Endpoint modules
        switch(ast.def) {
            case EModule(name, attrs, exprs) if (ast.metadata?.isEndpoint == true):
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Endpoint Transform] Processing endpoint EModule: ${name}');
                #end
                
                var appName = (ast.metadata != null && ast.metadata.appName != null) ? ast.metadata.appName : extractAppName(name);
                var endpointBody = buildEndpointBody(name, appName);
                // EModule expects Array<ElixirAST> body; unwrap block to statements
                var stmts = switch (endpointBody.def) {
                    case EBlock(s): s;
                    default: [endpointBody];
                };
                return makeASTWithMeta(EModule(name, attrs, stmts), ast.metadata, ast.pos);
                
            case EDefmodule(name, body) if (ast.metadata?.isEndpoint == true):
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Endpoint Transform] Processing endpoint EDefmodule: ${name}');
                #end
                
                var appName = (ast.metadata != null && ast.metadata.appName != null) ? ast.metadata.appName : extractAppName(name);
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
     * Build complete Phoenix.Endpoint module body as array of statements
     */
    static function buildEndpointBodyStatements(moduleName: String, appName: String): Array<ElixirAST> {
        var statements = [];
        
        // use Phoenix.Endpoint, otp_app: :app_name
        var useOptions = makeAST(EKeywordList([
            {key: "otp_app", value: makeAST(EAtom(appName))}
        ]));
        statements.push(makeAST(EUse("Phoenix.Endpoint", [useOptions])));
        
        // The rest of the endpoint configuration continues in buildEndpointBody
        // For now, just add the use statement which is most critical
        
        return statements;
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
            {key: "store", value: makeAST(EAtom(ElixirAtom.raw("cookie")))},
            {key: "key", value: makeAST(EString('_${appName}_key'))},
            // NOTE: Must be stable across builds; generating this randomly causes session cookies
            // (and therefore LiveView user tokens) to become invalid on every compile/run.
            // Phoenix salts are not secrets (secret_key_base is); keep it deterministic per app.
            {key: "signing_salt", value: makeAST(EString('${appName}_signing_salt'))},
            {key: "same_site", value: makeAST(EString("Lax"))}
        ]));
        // Module attribute for session options
        statements.push(makeAST(EModuleAttribute("session_options", sessionOptions)));
        
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
            // Use a list of strings instead of ~w sigil (heredoc printing issue)
            {key: "only", value: makeAST(EList([
                makeAST(EString("assets")),
                makeAST(EString("fonts")),
                makeAST(EString("images")),
                makeAST(EString("favicon.ico")),
                makeAST(EString("robots.txt"))
            ]))}
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
                makeAST(EAtom(ElixirAtom.raw("phoenix"))),
                makeAST(EAtom(ElixirAtom.raw("endpoint")))
            ]))}
        ]));
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(EVar("Plug.Telemetry")),
            telemetryOptions
        ])));
        
        // plug Plug.Parsers
        var parsersOptions = makeAST(EKeywordList([
            {key: "parsers", value: makeAST(EList([
                makeAST(EAtom(ElixirAtom.raw("urlencoded"))),
                makeAST(EAtom(ElixirAtom.raw("multipart"))),
                makeAST(EAtom(ElixirAtom.raw("json")))
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
                #end
                
                var liveViewBody = buildLiveViewBody(name, body);
                
                return makeASTWithMeta(
                    EDefmodule(name, liveViewBody),
                    ast.metadata,
                    ast.pos
                );
            case EModule(name, attrs, body) if (ast.metadata?.isLiveView == true):
                // Shape-matched LiveView module using direct Phoenix.LiveView use
                var webIndex = name.indexOf("Web");
                var appWebModule = if (webIndex > 0) name.substring(0, webIndex + "Web".length) else name;
                var liveViewOptions = makeAST(EKeywordList([
                    {
                        key: "layout",
                        value: makeAST(ETuple([
                            makeAST(EVar(appWebModule + ".Layouts")),
                            makeAST(EAtom(ElixirAtom.raw("app")))
                        ]))
                    }
                ]));
                var newBody: Array<ElixirAST> = [];
                newBody.push(makeAST(EUse("Phoenix.LiveView", [liveViewOptions])));
                // Ensure Ecto.Query macros are available for LiveViews
                newBody.push(makeAST(ERequire("Ecto.Query", null)));
                for (stmt in body) newBody.push(stmt);
                return makeASTWithMeta(EModule(name, attrs, newBody), ast.metadata, ast.pos);
            default:
                // Not a LiveView module, just pass through
                return ast;
        }
    }

    /**
     * Transform channel modules into Phoenix.Channel structure
     *
     * WHAT
     * - Adds `use <App>Web, :channel` to modules shaped like Phoenix channels.
     *
     * WHY
     * - Ensure idiomatic Phoenix channel setup without app-specific name heuristics.
     *   We rely on the framework naming convention "<App>Web.*Channel".
     *
     * HOW
     * - For EDefmodule/EModule whose name contains "Web." and "Channel",
     *   prepend use <App>Web, :channel and preserve existing body.
     */
    public static function channelTransformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDefmodule(name, body) if (name != null && name.indexOf("Web.") > 0 && name.indexOf("Channel") > 0):
                    var webIndex = name.indexOf("Web");
                    var appNamePart = if (webIndex > 0) name.substring(0, webIndex) else name;
                    var useStmt = makeAST(EUse(appNamePart + "Web", [ makeAST(EAtom(ElixirAtom.raw("channel"))) ]));
                    var newBody = switch (body.def) {
                        case EBlock(stmts): makeAST(EBlock([useStmt].concat(stmts)));
                        case EDo(stmts2): makeAST(EDo([useStmt].concat(stmts2)));
                        default: makeAST(EBlock([useStmt, body]));
                    };
                    makeASTWithMeta(EDefmodule(name, newBody), n.metadata, n.pos);
                case EModule(name, attrs, stmts) if (name != null && name.indexOf("Web.") > 0 && name.indexOf("Channel") > 0):
                    var webIndex2 = name.indexOf("Web");
                    var appNamePart2 = if (webIndex2 > 0) name.substring(0, webIndex2) else name;
                    var useStmt2 = makeAST(EUse(appNamePart2 + "Web", [ makeAST(EAtom(ElixirAtom.raw("channel"))) ]));
                    makeASTWithMeta(EModule(name, attrs, [useStmt2].concat(stmts)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
    
    /**
     * Build LiveView module body
     *
     * WHAT
     * - Emits idiomatic LiveView modules that depend only on `Phoenix.LiveView`
     *   rather than `AppWeb` macros for core behavior.
     *
     * WHY
     * - `use AppWeb, :live_view` is the Phoenix generator default, but it
     *   introduces a compile‑time dependency on the web hub module being
     *   compiled and loaded first. In isolated build roots (e.g. QA sentinel
     *   using per‑run MIX_BUILD_ROOT), this can surface as
     *   “module <App>Web is not loaded and could not be found” even though the
     *   generated AppWeb module exists as a normal .ex file.
     *
     * - Using `Phoenix.LiveView` directly keeps the generated code fully
     *   idiomatic while avoiding fragile compile ordering between the web hub
     *   and individual LiveViews. The hub module (`<App>Web`) is still
     *   generated for controllers, HTML helpers, etc., but LiveViews no longer
     *   require it during compilation.
     *
     * HOW
     * - Derives the `<App>Web` prefix from the LiveView module name
     *   (e.g. `TodoAppWeb.TodoLive` → `TodoAppWeb`) and uses it only to build
     *   the layout module name for options.
     * - Emits:
     *
     *   use Phoenix.LiveView, layout: {AppWeb.Layouts, :app}
     *
     * - Then appends the existing function body so that HXX/HXX‑generated
     *   render functions are preserved unchanged.
     *
     * EXAMPLES
     * Haxe:
     *   @:liveview @:native("TodoAppWeb.TodoLive")
     *   class TodoLive { ... }
     *
     * Elixir (before):
     *   defmodule TodoAppWeb.TodoLive do
     *     use TodoAppWeb, :live_view
     *     ...
     *   end
     *
     * Elixir (after):
     *   defmodule TodoAppWeb.TodoLive do
     *     use Phoenix.LiveView, layout: {TodoAppWeb.Layouts, :app}
     *     ...
     *   end
     */
    static function buildLiveViewBody(moduleName: String, existingBody: ElixirAST): ElixirAST {
        var statements = [];

        // Extract AppWeb module name from module name (e.g., TodoAppWeb.TodoLive -> TodoAppWeb)
        var webIndex = moduleName.indexOf("Web");
        var appWebModule = if (webIndex > 0) moduleName.substring(0, webIndex + "Web".length) else moduleName;

        // use Phoenix.LiveView, layout: {AppWeb.Layouts, :app}
        var liveViewOptions = makeAST(EKeywordList([
            {
                key: "layout",
                value: makeAST(ETuple([
                    makeAST(EVar(appWebModule + ".Layouts")),
                    makeAST(EAtom(ElixirAtom.raw("app")))
                ]))
            }
        ]));
        statements.push(makeAST(EUse("Phoenix.LiveView", [liveViewOptions])));

        // Ensure Ecto.Query macros are available for LiveViews that use queries
        // Safe to include even if not used; avoids macro require errors
        statements.push(makeAST(ERequire("Ecto.Query", null)));
        
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
     * Transform @:presence modules into Phoenix.Presence structure
     * 
     * WHY: Phoenix Presence modules need use Phoenix.Presence with otp_app configuration
     * WHAT: Adds use statement to enable track/update/list functions
     * HOW: Detects isPresence metadata and adds Phoenix.Presence use statement
     */
    public static function presenceTransformPass(ast: ElixirAST): ElixirAST {
        // Use transformNode for recursive transformation
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDefmodule(name, body):
                    var looksLikePresence = node.metadata?.isPresence == true || (name != null && name.indexOf("Web.Presence") > 0);
                    if (looksLikePresence) {
                        var presenceBody = buildPresenceBody(name, body);
                        return makeASTWithMeta(EDefmodule(name, presenceBody), node.metadata, node.pos);
                    }
                    return node;
                case EModule(name, attrs, bodyExprs):
                    var looksLikePresence2 = node.metadata?.isPresence == true || (name != null && name.indexOf("Web.Presence") > 0);
                    if (looksLikePresence2) {
                        var presenceBody2 = buildPresenceBody(name, makeAST(EBlock(bodyExprs)));
                        return makeASTWithMeta(EDefmodule(name, presenceBody2), node.metadata, node.pos);
                    }
                    return node;
                default:
                    return node;
            }
        });
    }
    
    /**
     * Build Phoenix Presence module body with use statement
     */
    static function buildPresenceBody(moduleName: String, existingBody: ElixirAST): ElixirAST {
        var statements = [];
        
        // Extract app name from module name (e.g., TodoAppWeb.Presence -> todo_app)
        var appName = extractAppName(moduleName);
        
        // use Phoenix.Presence, otp_app: :todo_app
        var useStatement = makeAST(EUse("Phoenix.Presence", [
            makeAST(EKeywordList([
                {key: "otp_app", value: makeAST(EAtom(appName))}
            ]))
        ]));
        statements.push(useStatement);
        
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
     * Transform @:router modules into Phoenix.Router structure
     * 
     * WHY: Phoenix routers require specific structure with use statement, pipelines, and scopes
     * WHAT: Replaces generated stub functions with complete Phoenix router setup
     * HOW: Detects isRouter metadata and builds proper Phoenix.Router AST
     */
    public static function routerTransformPass(ast: ElixirAST): ElixirAST {
        #if debug_annotation_transforms
        #end
        
        switch(ast.def) {
            case EDefmodule(name, body) if (ast.metadata?.isRouter == true):
                #if debug_annotation_transforms
                #end
                
                var routerBody = buildRouterBody(name, body, ast.metadata);
                return makeASTWithMeta(EDefmodule(name, routerBody), ast.metadata, ast.pos);
            case EModule(name, attrs, body) if (ast.metadata?.isRouter == true):
                #if debug_annotation_transforms
                #end
                var routerBody2 = buildRouterBody(name, makeAST(EBlock(body)), ast.metadata);
                return makeASTWithMeta(EDefmodule(name, routerBody2), ast.metadata, ast.pos);
                
            default:
                return ast;
        }
    }
    
    /**
     * Build Phoenix router body with pipelines and routes
     */
    static function buildRouterBody(moduleName: String, existingBody: ElixirAST, metadata: ElixirMetadata): ElixirAST {
        var statements = [];
        
        // Add use Phoenix.Router
        statements.push(makeAST(EUse("Phoenix.Router", [])));
        
        // Import LiveView router helpers
        statements.push(makeAST(EImport("Phoenix.LiveView.Router", null, null)));

        var webModuleName = StringTools.endsWith(moduleName, ".Router")
            ? moduleName.substr(0, moduleName.length - ".Router".length)
            : moduleName;

        // pipeline :browser do ... end
        var browserPlugs = [
            makeAST(ECall(null, "plug", [makeAST(EAtom(ElixirAtom.raw("accepts"))), makeAST(EList([makeAST(EString("html"))]))])),
            makeAST(ECall(null, "plug", [makeAST(EAtom(ElixirAtom.raw("fetch_session")))])),
            makeAST(ECall(null, "plug", [makeAST(EAtom(ElixirAtom.raw("fetch_live_flash")))])),
            makeAST(ECall(null, "plug", [
                makeAST(EAtom(ElixirAtom.raw("put_root_layout"))),
                makeAST(ETuple([
                    makeAST(EVar(webModuleName + ".Layouts")),
                    makeAST(EAtom(ElixirAtom.raw("root")))
                ]))
            ])),
            makeAST(ECall(null, "plug", [makeAST(EAtom(ElixirAtom.raw("protect_from_forgery")))])),
            makeAST(ECall(null, "plug", [makeAST(EAtom(ElixirAtom.raw("put_secure_browser_headers")))]))
        ];
        statements.push(makeAST(EMacroCall("pipeline", [makeAST(EAtom(ElixirAtom.raw("browser")))], makeAST(EBlock(browserPlugs)))));

        var routes = metadata != null ? metadata.routerRoutes : null;
        var browserRouteCalls: Array<ElixirAST> = [];
        var apiRouteCalls: Array<ElixirAST> = [];
        var dashboardRoutes: Array<{scopePath: String, routePath: String}> = [];

        if (routes != null) {
            for (route in routes) {
                var method = route.method != null ? route.method.toUpperCase() : "";
                var path = route.path;
                if (path == null) continue;

                if (method == "LIVE_DASHBOARD") {
                    // Split "/dev/dashboard" -> scope "/dev", route "/dashboard"
                    var lastSlash = path.lastIndexOf("/");
                    var scopePath = (lastSlash > 0) ? path.substr(0, lastSlash) : "/";
                    var routePath = (lastSlash > 0) ? path.substr(lastSlash) : path;
                    dashboardRoutes.push({scopePath: scopePath, routePath: routePath});
                    continue;
                }

                var pipeline = route.pipeline != null ? route.pipeline : (StringTools.startsWith(path, "/api") ? "api" : "browser");
                var targetCalls = (pipeline == "api") ? apiRouteCalls : browserRouteCalls;

                var controllerName = route.controller != null ? NameUtils.getElixirModuleName(route.controller) : null;
                var actionName = route.action;
                if (controllerName == null || actionName == null) {
                    continue;
                }
                if (StringTools.startsWith(actionName, ":")) actionName = actionName.substr(1);
                actionName = NameUtils.toSnakeCase(actionName);

                var routeMacro = switch (method) {
                    case "LIVE": "live";
                    case "GET": "get";
                    case "POST": "post";
                    case "PUT": "put";
                    case "PATCH": "patch";
                    case "DELETE": "delete";
                    default: null;
                };
                if (routeMacro == null) continue;

                var routePathFinal = (pipeline == "api" && StringTools.startsWith(path, "/api"))
                    ? path.substr("/api".length)
                    : path;
                if (routePathFinal == "") routePathFinal = "/";

                targetCalls.push(makeAST(ECall(null, routeMacro, [
                    makeAST(EString(routePathFinal)),
                    makeAST(EVar(controllerName)),
                    makeAST(EAtom(ElixirAtom.raw(actionName)))
                ])));
            }
        }

        // pipeline :api do ... end (only if needed)
        if (apiRouteCalls.length > 0) {
            var apiPlugs = [
                makeAST(ECall(null, "plug", [makeAST(EAtom(ElixirAtom.raw("accepts"))), makeAST(EList([makeAST(EString("json"))]))]))
            ];
            statements.push(makeAST(EMacroCall("pipeline", [makeAST(EAtom(ElixirAtom.raw("api")))], makeAST(EBlock(apiPlugs)))));
        }

        // scope "/", WebModule do ... end (browser)
        if (browserRouteCalls.length > 0) {
            var scopeBody = [makeAST(ECall(null, "pipe_through", [makeAST(EAtom(ElixirAtom.raw("browser")))]))].concat(browserRouteCalls);
            statements.push(makeAST(EMacroCall("scope", [makeAST(EString("/")), makeAST(EVar(webModuleName))], makeAST(EBlock(scopeBody)))));
        }

        // scope "/api", WebModule do ... end (api)
        if (apiRouteCalls.length > 0) {
            var scopeBodyApi = [makeAST(ECall(null, "pipe_through", [makeAST(EAtom(ElixirAtom.raw("api")))]))].concat(apiRouteCalls);
            statements.push(makeAST(EMacroCall("scope", [makeAST(EString("/api")), makeAST(EVar(webModuleName))], makeAST(EBlock(scopeBodyApi)))));
        }

        // LiveDashboard in dev/test
        if (dashboardRoutes.length > 0) {
            var thenStmts: Array<ElixirAST> = [makeAST(EImport("Phoenix.LiveDashboard.Router", null, null))];
            // Group by scope path
            var scopeMap: Map<String, Array<String>> = new Map();
            for (d in dashboardRoutes) {
                var arr = scopeMap.exists(d.scopePath) ? scopeMap.get(d.scopePath) : [];
                arr.push(d.routePath);
                scopeMap.set(d.scopePath, arr);
            }

            for (scopePath => routePaths in scopeMap) {
                var calls: Array<ElixirAST> = [makeAST(ECall(null, "pipe_through", [makeAST(EAtom(ElixirAtom.raw("browser")))]))];
                for (rp in routePaths) {
                    calls.push(makeAST(ECall(null, "live_dashboard", [
                        makeAST(EString(rp)),
                        makeAST(EKeywordList([{key: "metrics", value: makeAST(EVar(webModuleName + ".Telemetry"))}]))
                    ])));
                }
                thenStmts.push(makeAST(EMacroCall("scope", [makeAST(EString(scopePath))], makeAST(EBlock(calls)))));
            }

            var envCall = makeAST(ERemoteCall(makeAST(EVar("Mix")), "env", []));
            var condition = makeAST(EBinary(In, envCall, makeAST(EList([makeAST(EAtom(ElixirAtom.raw("dev"))), makeAST(EAtom(ElixirAtom.raw("test")))]))));
            statements.push(makeAST(EIf(condition, makeAST(EBlock(thenStmts)), null)));
        }

        // Preserve any user-defined/generated defs after router DSL.
        switch (existingBody.def) {
            case EBlock(existingStmts):
                statements = statements.concat(existingStmts);
            default:
                statements.push(existingBody);
        }

        return makeAST(EBlock(statements));
    }
    
    /**
     * Transform @:controller modules into Phoenix.Controller structure
     * 
     * WHY: Phoenix controllers need the use statement for controller functionality
     * WHAT: Adds use AppNameWeb, :controller at the beginning of the module
     * HOW: Detects isController metadata and adds the use statement
     */
    public static function controllerTransformPass(ast: ElixirAST): ElixirAST {
        // Check the top-level node first for Controller modules
        switch(ast.def) {
            case EDefmodule(name, body) if (ast.metadata?.isController == true || (name != null && name.indexOf("Web.") > 0 && name.indexOf("Controller") > 0)):
                #if debug_annotation_transforms
                #end
                
                var appName = ast.metadata.appName ?? "app";
                var controllerBody = buildControllerBody(name, appName, body);
                
                return makeASTWithMeta(
                    EDefmodule(name, controllerBody),
                    ast.metadata,
                    ast.pos
                );
            case EModule(name, attrs, exprs) if (ast.metadata?.isController == true || (name != null && name.indexOf("Web.") > 0 && name.indexOf("Controller") > 0)):
                var appName2 = ast.metadata.appName ?? "app";
                var controllerBody2 = buildControllerBody(name, appName2, makeAST(EBlock(exprs)));
                return makeASTWithMeta(EDefmodule(name, controllerBody2), ast.metadata, ast.pos);
            default:
                // Not a Controller module, just pass through
                return ast;
        }
    }
    
    /**
     * Build Phoenix Controller module body with use statement
     */
    static function buildControllerBody(moduleName: String, appName: String, existingBody: ElixirAST): ElixirAST {
        var statements = [];
        
        // Extract app module name (e.g., "TodoApp" from "TodoAppWeb.UserController")
        var parts = moduleName.split(".");
        var webModuleName = parts.length > 0 ? parts[0] : '${capitalize(appName)}Web';
        
        // Add: use AppNameWeb, :controller
        statements.push(makeAST(EUse(
            webModuleName,
            [makeAST(EAtom(ElixirAtom.raw("controller")))]
        )));
        
        // Add the existing body
        switch(existingBody.def) {
            case EBlock(bodyStatements):
                statements = statements.concat(bodyStatements);
            default:
                statements.push(existingBody);
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Helper to capitalize first letter
     */
    static function capitalize(s: String): String {
        if (s.length == 0) return s;
        return s.charAt(0).toUpperCase() + s.substr(1);
    }
    
    /**
     * Transform @:schema modules into Ecto.Schema structure
     * 
     * WHY: Ecto schemas need specific structure with schema block and changeset
     * WHAT: Adds use Ecto.Schema, schema block with fields, and changeset function
     * HOW: Detects isSchema metadata and transforms module body
     */
    public static function schemaTransformPass(ast: ElixirAST): ElixirAST {
        #if debug_annotation_transforms
        if (ast.metadata != null && ast.metadata.isSchema == true) {
            // DISABLED: trace('[XRay Schema Transform] Found schema module with isSchema metadata');
        }
        #end
        
        // Check the top-level node first for Schema modules
        switch(ast.def) {
            case EDefmodule(name, body) if (ast.metadata?.isSchema == true):
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Schema Transform] Processing schema EDefmodule: ${name}');
                #end
                
                var tableName = ast.metadata.tableName ?? "items";
                var lookupName = ast.metadata?.haxeFqcn != null ? ast.metadata.haxeFqcn : name;
                var schemaBody = buildSchemaBody(name, tableName, body, lookupName, ast.metadata);
                
                return makeASTWithMeta(
                    EDefmodule(name, schemaBody),
                    ast.metadata,
                    ast.pos
                );
            
            case EModule(name, attrs, exprs) if (ast.metadata?.isSchema == true):
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Schema Transform] Processing schema EModule: ${name}');
                #end
                
                var tableName = ast.metadata.tableName ?? "items";
                var lookupName = ast.metadata?.haxeFqcn != null ? ast.metadata.haxeFqcn : name;
                
                // Build the schema body with existing expressions
                var bodyStatements = [];
                
                // Add use Ecto.Schema and import Ecto.Changeset
                bodyStatements.push(makeAST(EUse("Ecto.Schema", [])));
                bodyStatements.push(makeAST(EImport("Ecto.Changeset", null, null)));
                
                // Build and add the schema block
                var schemaFieldStatements = [];
                if (ast.metadata != null && ast.metadata.schemaFields != null) {
                    for (f in ast.metadata.schemaFields) {
                        // Skip primary key id (Ecto adds by default)
                        if (f.name == "id") continue;
                        var elixirFieldName = reflaxe.elixir.ast.NameUtils.toSnakeCase(f.name);
                        var atomFieldName = makeAST(EAtom(elixirFieldName));
                        var fieldTypeAST = mapHaxeTypeToEctoFieldType(f.type);
                        schemaFieldStatements.push(makeAST(ECall(null, "field", [
                            atomFieldName,
                            fieldTypeAST
                        ])));
                    }
                }
                
                // Add timestamps if specified
                if (ast.metadata?.hasTimestamps == true) {
                    schemaFieldStatements.push(makeAST(ECall(null, "timestamps", [])));
                }
                
                var schemaFields = makeAST(EBlock(schemaFieldStatements));
                var schemaBlock = makeAST(EMacroCall(
                    "schema",
                    [makeAST(EString(tableName))],
                    schemaFields
                ));
                bodyStatements.push(schemaBlock);

                // Add the existing functions
                for (expr in exprs) {
                    bodyStatements.push(expr);
                }

                // Generate changeset function if user didn't provide one
                // Check metadata for user-defined changeset (hasUserChangeset flag)
                var hasChangeset = ast.metadata?.hasUserChangeset == true;

                if (!hasChangeset) {
                    var castFields:Array<String> = [];
                    var requiredFields:Array<String> = [];

                    // PRIORITY 1: Use explicit @:changeset annotation if present
                    if (ast.metadata?.changesetCastFields != null && ast.metadata.changesetCastFields.length > 0) {
                        for (field in ast.metadata.changesetCastFields) {
                            var snakeField = reflaxe.elixir.ast.NameUtils.toSnakeCase(field);
                            castFields.push(':$snakeField');
                        }
                        if (ast.metadata?.changesetRequiredFields != null) {
                            for (field in ast.metadata.changesetRequiredFields) {
                                var snakeField = reflaxe.elixir.ast.NameUtils.toSnakeCase(field);
                                requiredFields.push(snakeField);
                            }
                        }
                    }
                    // PRIORITY 2: Fall back to schema field inference
                    else if (ast.metadata?.schemaFields != null) {
                        for (field in ast.metadata.schemaFields) {
                            if (field.name != "id" && field.name != "insertedAt" && field.name != "updatedAt") {
                                var snakeField = reflaxe.elixir.ast.NameUtils.toSnakeCase(field.name);
                                castFields.push(':$snakeField');
                                if (field.type != null && field.type.indexOf("Null") == -1 && field.type.indexOf("array") == -1) {
                                    requiredFields.push(snakeField);
                                }
                            }
                        }
                    }

                    // Generate changeset function if we have fields to cast
                    if (castFields.length > 0) {
                        var castFieldsStr = castFields.join(", ");
                        var requiredFieldsStr = requiredFields.map(f -> ':$f').join(", ");
                        var paramName = name.toLowerCase();
                        // Extract just the last part for param name (e.g., "TodoApp.Todo" -> "todo")
                        var lastDot = paramName.lastIndexOf(".");
                        if (lastDot != -1) {
                            paramName = paramName.substr(lastDot + 1);
                        }

                        var changesetCode = '
  def changeset($paramName, attrs) do
    $paramName
    |> Ecto.Changeset.cast(attrs, [$castFieldsStr])' +
    (requiredFields.length > 0 ? '\n    |> Ecto.Changeset.validate_required([$requiredFieldsStr])' : '') + '
  end';
                        bodyStatements.push(makeAST(ERaw(changesetCode)));
                    }
                }

                // Return the transformed module
                return makeASTWithMeta(
                    EModule(name, attrs, bodyStatements),
                    ast.metadata,
                    ast.pos
                );
                
            default:
                // Not a Schema module, just pass through
                return ast;
        }
    }
    
    /**
     * Map Haxe types to Ecto field types
     * Returns an ElixirAST node for the field type (atom or tuple for complex types)
     */
    static function mapHaxeTypeToEctoFieldType(haxeType: String): ElixirAST {
        // Handle generic-like strings (e.g., "Array<String>") and aliases (e.g., "NaiveDateTime")
        if (haxeType == null) return makeAST(EAtom("string"));
        switch(haxeType) {
            case "String": return makeAST(EAtom("string"));
            case "Int": return makeAST(EAtom("integer"));
            case "Float": return makeAST(EAtom("float"));
            case "Bool": return makeAST(EAtom("boolean"));
            case "Date" | "NaiveDateTime": return makeAST(EAtom("naive_datetime"));
            case _:
                // Detect Array<...>
                if (StringTools.startsWith(haxeType, "Array<") && StringTools.endsWith(haxeType, ">")) {
                    var inner = haxeType.substr(6, haxeType.length - 7);
                    var innerAtom = switch (inner) {
                        case "String": "string";
                        case "Int": "integer";
                        case "Float": "float";
                        case "Bool": "boolean";
                        case "Date" | "NaiveDateTime": "naive_datetime";
                        case _: "string";
                    };
                    return makeAST(ETuple([
                        makeAST(EAtom("array")),
                        makeAST(EAtom(innerAtom))
                    ]));
                }
                // Fallback to string
                return makeAST(EAtom("string"));
        }
    }
    
    /**
     * Build Ecto.Schema module body
     */
    static function buildSchemaBody(moduleName: String, tableName: String, existingBody: ElixirAST, lookupName: String, meta: reflaxe.elixir.ast.ElixirMetadata): ElixirAST {
        var statements = [];
        
        // use Ecto.Schema
        statements.push(makeAST(EUse("Ecto.Schema", [])));
        
        // import Ecto.Changeset
        statements.push(makeAST(EImport("Ecto.Changeset", null, null)));
        
        // Extract schema fields from metadata (populated by ModuleBuilder)
        var schemaFieldStatements = [];
        var hasTimestamps: Bool = meta != null && meta.hasTimestamps == true;
        
        // Look for field metadata that might have been passed along
        // For now, we'll generate basic fields and rely on the functions being added below
        // The actual field extraction would require accessing the ClassType data
        // which would need to be passed through metadata
        
        // Use schemaFields provided in metadata. General, app-agnostic.
        if (meta != null && meta.schemaFields != null) {
            for (f in meta.schemaFields) {
                // Skip primary key id (Ecto adds by default)
                if (f.name == "id") continue;
                switch (f.type) {
                    case "Int":
                        schemaFieldStatements.push(makeAST(ECall(null, "field", [ makeAST(EAtom(f.name)), makeAST(EAtom(ElixirAtom.raw("integer"))) ])));
                    case "Bool":
                        schemaFieldStatements.push(makeAST(ECall(null, "field", [ makeAST(EAtom(f.name)), makeAST(EAtom(ElixirAtom.raw("boolean"))) ])));
                    case "NaiveDateTime":
                        schemaFieldStatements.push(makeAST(ECall(null, "field", [ makeAST(EAtom(f.name)), makeAST(EAtom(ElixirAtom.raw("naive_datetime"))) ])));
                    case "Float":
                        schemaFieldStatements.push(makeAST(ECall(null, "field", [ makeAST(EAtom(f.name)), makeAST(EAtom(ElixirAtom.raw("float"))) ])));
                    case "Array<String>":
                        // Use {:array, :string}
                        schemaFieldStatements.push(makeAST(ECall(null, "field", [ makeAST(EAtom(f.name)), makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("array"))), makeAST(EAtom(ElixirAtom.raw("string")))])) ])));
                    case _:
                        schemaFieldStatements.push(makeAST(ECall(null, "field", [ makeAST(EAtom(f.name)), makeAST(EAtom(ElixirAtom.raw("string"))) ])));
                }
            }
        }
        
        // Add timestamps only if class had @:timestamps
        if (hasTimestamps) schemaFieldStatements.push(makeAST(ECall(null, "timestamps", [])));
        
        var schemaFields = makeAST(EBlock(schemaFieldStatements));
        
        var schemaBlock = makeAST(EMacroCall(
            "schema",
            [makeAST(EString(tableName))],
            schemaFields
        ));
        statements.push(schemaBlock);
        
        // Add existing functions (including changeset functions)
        switch(existingBody.def) {
            case EBlock(stmts):
                for (stmt in stmts) {
                    switch(stmt.def) {
                        case ENil:
                            // Skip empty statements
                        default:
                            statements.push(stmt);
                    }
                }
            default:
                // Add the body if it's not empty
                if (existingBody.def != ENil) {
                    statements.push(existingBody);
                }
        }
        
        // Check if user defined their own changeset function via metadata
        // WHY: This is the clean, metadata-driven approach. The hasUserChangeset flag is set at compile time
        //      in ElixirCompiler.hx when funcFields are available, so we don't need to do string matching
        //      on ERaw nodes here. This follows the "metadata first" architectural principle.
        // WHAT: If hasUserChangeset is true, skip auto-generation; user's changeset will be preserved
        // HOW: Simple metadata check - no AST traversal needed at transform time
        var hasChangeset = meta?.hasUserChangeset == true;

        // If no changeset function was found, add a basic one
        // This ensures schemas always have a changeset function for Ecto compatibility
        if (!hasChangeset) {
            var castFields:Array<String> = [];
            var requiredFields:Array<String> = [];

            // PRIORITY 1: Use explicit @:changeset annotation if present
            // Format: @:changeset(["field1", "field2"], ["required1"])
            if (meta?.changesetCastFields != null && meta.changesetCastFields.length > 0) {
                // Use fields from @:changeset annotation - convert to snake_case atoms
                for (field in meta.changesetCastFields) {
                    var snakeField = NameUtils.toSnakeCase(field);
                    castFields.push(':$snakeField');
                }
                // Required fields from annotation
                if (meta?.changesetRequiredFields != null) {
                    for (field in meta.changesetRequiredFields) {
                        var snakeField = NameUtils.toSnakeCase(field);
                        requiredFields.push(snakeField);
                    }
                }
            }
            // PRIORITY 2: Fall back to schema field inference
            else if (meta?.schemaFields != null) {
                for (field in meta.schemaFields) {
                    if (field.name != "id" && field.name != "insertedAt" && field.name != "updatedAt") {
                        var snakeField = NameUtils.toSnakeCase(field.name);
                        castFields.push(':$snakeField');
                        // Make some fields required based on type
                        if (field.type != null && field.type.indexOf("Null") == -1 && field.type.indexOf("array") == -1) {
                            requiredFields.push(snakeField);
                        }
                    }
                }
            }

            // Generate changeset function if we have fields to cast
            if (castFields.length > 0) {
                var castFieldsStr = castFields.join(", ");
                var requiredFieldsStr = requiredFields.map(f -> ':$f').join(", ");
                var paramName = moduleName.toLowerCase();

                var changesetCode = '
  def changeset($paramName, attrs) do
    $paramName
    |> cast(attrs, [$castFieldsStr])' +
    (requiredFields.length > 0 ? '\n    |> validate_required([$requiredFieldsStr])' : '') + '
  end';
                statements.push(makeAST(ERaw(changesetCode)));
            }
        }
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Transform @:repo modules into Ecto.Repo structure
     * 
     * WHY: Ecto repositories need use Ecto.Repo with otp_app and adapter configuration
     * WHAT: Adds use statement to enable database access functions (all/2, get/3, insert/2, etc.)
     * HOW: Detects isRepo metadata and adds Ecto.Repo use statement with configuration
     */
    public static function repoTransformPass(ast: ElixirAST): ElixirAST {
        #if debug_annotation_transforms
        // DISABLED: trace("[XRay Repo Transform] PASS START");
        if (ast.metadata?.isRepo == true) {
            // DISABLED: trace('[XRay Repo Transform] Found isRepo metadata on AST type: ${Type.enumConstructor(ast.def)}');
        }
        #end
        
        // Check the top-level node first for Repo modules
        switch(ast.def) {
            case EModule(name, attributes, body) if (ast.metadata?.isRepo == true):
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Repo Transform] ✓ Processing @:repo EModule: $name');
                #end
                
                var appName = extractAppName(name);
                var repoBodyAST = buildRepoBody(name, appName);
                
                // EModule expects Array<ElixirAST> for body, so extract statements from EBlock
                var repoStatements = switch(repoBodyAST.def) {
                    case EBlock(stmts): stmts;
                    default: [repoBodyAST];
                };
                
                return makeASTWithMeta(
                    EModule(name, attributes, repoStatements),
                    ast.metadata,
                    ast.pos
                );
                
            case EDefmodule(name, body) if (ast.metadata?.isRepo == true):
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Repo Transform] ✓ Processing @:repo module: $name');
                #end
                
                var appName = extractAppName(name);
                var repoBody = buildRepoBody(name, appName);
                
                return makeASTWithMeta(
                    EDefmodule(name, repoBody),
                    ast.metadata,
                    ast.pos
                );
                
            default:
                // Not a Repo module, just pass through
                return ast;
        }
    }

    /**
     * Transform @:postgrexTypes modules into a precompiled Postgrex types module
     *
     * WHY: Avoid runtime TypeManager races and allow custom JSON codecs
     * WHAT: Adds a module-level call to Postgrex.Types.define(__MODULE__, [], json: <jsonModule>)
     * HOW: Detects isPostgrexTypes metadata and builds a minimal module body
     */
    public static function postgrexTypesTransformPass(ast: ElixirAST): ElixirAST {
        switch (ast.def) {
            case EDefmodule(name, body) if (ast.metadata?.isPostgrexTypes == true):
                var jsonLib = ast.metadata.jsonModule != null ? ast.metadata.jsonModule : "Jason";
                var typesBody = buildDbTypesBody(name, "postgrex", jsonLib, []);
                return makeASTWithMeta(
                    EDefmodule(name, typesBody),
                    ast.metadata,
                    ast.pos
                );
            default:
                return ast;
        }
    }

    /** Generic DB types transformer */
    public static function dbTypesTransformPass(ast: ElixirAST): ElixirAST {
        switch (ast.def) {
            case EDefmodule(name, body) if (ast.metadata?.isDbTypes == true):
                var adapter = ast.metadata.dbAdapter != null ? ast.metadata.dbAdapter : "postgrex";
                var jsonLib = ast.metadata.jsonModule != null ? ast.metadata.jsonModule : "Jason";
                var exts = ast.metadata.extensions != null ? ast.metadata.extensions : [];
                
                // For Postgrex, the Types.define macro creates the module itself
                // So we return just the macro call without the defmodule wrapper
                switch(adapter.toLowerCase()) {
                    case "postgrex":
                        var opts = 'json: ' + jsonLib;
                        if (exts != null && exts.length > 0) {
                            var extList = '[' + exts.join(", ") + ']';
                            opts = opts + ', extensions: ' + extList;
                        }
                        // Generate the macro call with the module name directly
                        var line = 'Postgrex.Types.define(' + name + ', [], ' + opts + ')';
                        return makeAST(ERaw(line));
                    default:
                        // For other adapters, keep the module wrapper (they might need it)
                        var typesBody = buildDbTypesBody(name, adapter, jsonLib, exts);
                        return makeASTWithMeta(
                            EDefmodule(name, typesBody),
                            ast.metadata,
                            ast.pos
                        );
                }
            default:
                return ast;
        }
    }

    static function buildDbTypesBody(moduleName: String, adapter: String, jsonLib: String, extensions: Array<String>): ElixirAST {
        var statements = [];
        switch(adapter.toLowerCase()) {
            case "postgrex":
                // This case is now handled above, but keep for completeness
                var opts = 'json: ' + jsonLib;
                if (extensions != null && extensions.length > 0) {
                    var extList = '[' + extensions.join(", ") + ']';
                    opts = opts + ', extensions: ' + extList;
                }
                var line = 'Postgrex.Types.define(__MODULE__, [], ' + opts + ')';
                statements.push(makeAST(ERaw(line)));
            default:
                // Unknown adapter → emit a compile error as a clear message
                var err = 'raise("Unsupported DB adapter for @:dbTypes: ' + adapter + '")';
                statements.push(makeAST(ERaw(err)));
        }
        return makeAST(EBlock(statements));
    }
    
    /**
     * Build Ecto.Repo module body
     * 
     * WHY: Ecto repositories need use statement to inject database functions
     * WHAT: Creates minimal module with use Ecto.Repo and configuration
     * HOW: Generates use statement with otp_app and adapter options
     */
    static function buildRepoBody(moduleName: String, appName: String): ElixirAST {
        var statements = [];
        
        // use Ecto.Repo, otp_app: :app_name, adapter: Ecto.Adapters.Postgres
        var useOptions = makeAST(EKeywordList([
            {key: "otp_app", value: makeAST(EAtom(appName))},
            {key: "adapter", value: makeAST(EField(
                makeAST(EField(makeAST(EVar("Ecto")), "Adapters")),
                "Postgres"
            ))}
        ]));
        
        // EUse expects an array of options, with the keyword list as one element
        statements.push(makeAST(EUse("Ecto.Repo", [useOptions])));
        
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
        #if debug_annotation_transforms
        if (ast.metadata != null && ast.metadata.isApplication == true) {
            // DISABLED: trace('[XRay Application Transform] PASS START - Found Application module with metadata');
            // DISABLED: trace('[XRay Application Transform] AST type: ${Type.enumConstructor(ast.def)}');
        }
        #end
        
        // Check the top-level node first for Application modules
        switch(ast.def) {
            case EModule(name, attributes, body) if (ast.metadata?.isApplication == true):
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Application Transform] Processing EModule: $name');
                #end
                
                // For EModule, body is Array<ElixirAST>, need to handle differently
                var appBody = buildApplicationBodyFromArray(name, body);
                
                return makeASTWithMeta(
                    EModule(name, attributes, appBody),
                    ast.metadata,
                    ast.pos
                );
                
            case EDefmodule(name, body) if (ast.metadata?.isApplication == true):
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Application Transform] Processing EDefmodule: $name');
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
     * Build OTP Application module body for Array<ElixirAST> (from EModule)
     */
    static function buildApplicationBodyFromArray(moduleName: String, existingBody: Array<ElixirAST>): Array<ElixirAST> {
        var result = [];
        
        #if debug_annotation_transforms
        // DISABLED: trace('[XRay Application Transform] buildApplicationBodyFromArray - existing functions: ${existingBody.length}');
        #end
        
        // Add use Application
        result.push(makeAST(EUse("Application", [])));
        
        // Add existing functions
        for (func in existingBody) {
            #if debug_annotation_transforms
            if (func.def != null) {
                // DISABLED: trace('[XRay Application Transform] Adding existing function: ${Type.enumConstructor(func.def)}');
            }
            #end
            result.push(func);
        }
        
        return result;
    }
    
    /**
     * Build OTP Application module body for ElixirAST (from EDefmodule)
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
                        {key: "strategy", value: makeAST(EAtom(ElixirAtom.raw("one_for_one")))},
                        {key: "name", value: makeAST(EVar(moduleName + ".Supervisor"))}
                    ]))
                )),
                // Supervisor.start_link(children, opts)
                makeAST(ERemoteCall(
                    makeAST(EVar("Supervisor")),
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
        #end
        
        // Check the top-level node first for PhoenixWeb modules
        switch(ast.def) {
            case EDefmodule(name, body) if (ast.metadata?.isPhoenixWeb == true || (name != null && (StringTools.endsWith(name, "Web") && name.indexOf(".") == -1))):
                var phoenixWebBody = buildPhoenixWebBody(name, body);
                // Extract statements from EBlock
                var stmts:Array<ElixirAST> = switch (phoenixWebBody.def) { case EBlock(es): es; default: [phoenixWebBody]; };
                // Inject @compile {:nowarn_unused_function, [html_helpers: 0]}
                var compileAttr:EAttribute = {
                    name: "compile",
                    value: makeAST(ETuple([
                        makeAST(EAtom("nowarn_unused_function")),
                        makeAST(EKeywordList([{key: "html_helpers", value: makeAST(EInteger(0))}]))
                    ]))
                };
                return makeASTWithMeta(EModule(name, [compileAttr], stmts), ast.metadata, ast.pos);
            case EModule(name, attrs, exprs) if (ast.metadata?.isPhoenixWeb == true || (name != null && (StringTools.endsWith(name, "Web") && name.indexOf(".") == -1))):
                var phoenixWebBody2 = buildPhoenixWebBody(name, makeAST(EBlock(exprs)));
                var stmts2:Array<ElixirAST> = switch (phoenixWebBody2.def) { case EBlock(es): es; default: [phoenixWebBody2]; };
                var compileAttr2:EAttribute = {
                    name: "compile",
                    value: makeAST(ETuple([
                        makeAST(EAtom("nowarn_unused_function")),
                        makeAST(EKeywordList([{key: "html_helpers", value: makeAST(EInteger(0))}]))
                    ]))
                };
                return makeASTWithMeta(EModule(name, [compileAttr2], stmts2), ast.metadata, ast.pos);
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
                    {key: "formats", value: makeAST(EList([makeAST(EAtom(ElixirAtom.raw("html"))), makeAST(EAtom(ElixirAtom.raw("json")))]))},
                    {key: "layouts", value: makeAST(EKeywordList([
                        {key: "html", value: makeAST(ETuple([
                            makeAST(EVar(moduleName + ".Layouts")),
                            makeAST(EAtom(ElixirAtom.raw("app")))
                        ]))}
                    ]))}
                ]))
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
                        makeAST(EAtom(ElixirAtom.raw("app")))
                    ]))}
                ]))
            ])),
            makeAST(ECall(null, "unquote", [makeAST(ECall(null, "html_helpers", []))]))
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
                    {key: "endpoint", value: makeAST(EVar(moduleName + ".Endpoint"))},
                    {key: "router", value: makeAST(EVar(moduleName + ".Router"))},
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
        
        // def static_paths do
        // This function is expected by Phoenix.VerifiedRoutes
        statements.push(makeAST(EDef(
            "static_paths",
            [],
            null,
            makeAST(EList([
                makeAST(EString("assets")),
                makeAST(EString("fonts")),
                makeAST(EString("images")),
                makeAST(EString("favicon.ico")),
                makeAST(EString("robots.txt"))
            ]))
        )));
        
        return makeAST(EBlock(statements));
    }
    
    /**
     * Extract app name from module name
     * 
     * Examples:
     * - TodoAppWeb.Presence -> todo_app
     * - MyApp.Presence -> my_app
     * - SomeModuleWeb.Presence -> some_module
     */
    static function extractAppName(moduleName: String): String {
        // Remove Web suffix if present
        var name = moduleName;
        var webIndex = name.indexOf("Web.");
        if (webIndex > 0) {
            name = name.substring(0, webIndex);
        }
        
        // Remove module path after last dot
        var lastDotIndex = name.lastIndexOf(".");
        if (lastDotIndex > 0) {
            name = name.substring(0, lastDotIndex);
        }
        
        // Convert CamelCase to snake_case
        var result = "";
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (i > 0 && char == char.toUpperCase() && char != char.toLowerCase()) {
                result += "_";
            }
            result += char.toLowerCase();
        }
        
        return result;
    }
    
    /**
     * Transform @:exunit modules into ExUnit.Case test modules
     * 
     * WHY: ExUnit tests require specific structure with use statement and test macros
     * WHAT: Transforms classes marked with @:exunit into proper ExUnit test modules
     * HOW: Detects isExunit metadata and transforms methods with @:test into test blocks
     */
    public static function exunitTransformPass(ast: ElixirAST): ElixirAST {
        #if debug_annotation_transforms
        // DISABLED: trace("[XRay ExUnit Transform] PASS START");
        // DISABLED: trace('[XRay ExUnit Transform] AST type: ${Type.enumConstructor(ast.def)}');
        if (ast.metadata != null) {
            // DISABLED: trace('[XRay ExUnit Transform] AST has metadata: isExunit=${ast.metadata.isExunit}');
        } else {
            // DISABLED: trace('[XRay ExUnit Transform] AST has NO metadata');
        }
        #end
        
        // Check the top-level node first for ExUnit modules
        switch(ast.def) {
            case EModule(name, attributes, bodyExprs):
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay ExUnit Transform] Found EModule: $name');
                if (ast.metadata != null) {
                    // DISABLED: trace('[XRay ExUnit Transform] Module metadata exists, isExunit=${ast.metadata.isExunit}');
                } else {
                    // DISABLED: trace('[XRay ExUnit Transform] Module has NO metadata!');
                }
                #end

                // Check if metadata indicates ExUnit module
                var isExunit = ast.metadata?.isExunit == true;

                if (isExunit) {
                    #if debug_annotation_transforms
                    // DISABLED: trace('[XRay ExUnit Transform] ✓ Processing @:exunit module: $name');
                    #end

                    // Create a block from the body expressions
                    var bodyBlock = makeAST(EBlock(bodyExprs));
                    var exunitBody = buildExUnitBody(name, bodyBlock);

                    // Convert EModule to EDefmodule for ExUnit output
                    return makeASTWithMeta(
                        EDefmodule(name, exunitBody),
                        ast.metadata,
                        ast.pos
                    );
                }
                // Not an ExUnit module, return as-is
                return ast;

            case EDefmodule(name, body):
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay ExUnit Transform] Found EDefmodule: $name');
                if (ast.metadata != null) {
                    // DISABLED: trace('[XRay ExUnit Transform] Module metadata exists, isExunit=${ast.metadata.isExunit}');
                } else {
                    // DISABLED: trace('[XRay ExUnit Transform] Module has NO metadata!');
                }
                #end

                // Check if metadata indicates ExUnit module
                var isExunit = ast.metadata?.isExunit == true;
                
                // WORKAROUND: If metadata is missing, detect ExUnit module by checking for test functions
                if (!isExunit) {
                    switch(body.def) {
                        case EBlock(exprs):
                            for (expr in exprs) {
                                if (expr.metadata?.isTest == true || 
                                    expr.metadata?.isSetup == true || 
                                    expr.metadata?.isSetupAll == true ||
                                    expr.metadata?.isTeardown == true ||
                                    expr.metadata?.isTeardownAll == true) {
                                    #if debug_annotation_transforms
                                    // DISABLED: trace('[XRay ExUnit Transform] ✓ Detected ExUnit module by test function metadata');
                                    #end
                                    isExunit = true;
                                    break;
                                }
                            }
                        default:
                    }
                }
                
                if (isExunit) {
                    #if debug_annotation_transforms
                    // DISABLED: trace('[XRay ExUnit Transform] ✓ Processing @:exunit module: $name');
                    #end
                    
                    var exunitBody = buildExUnitBody(name, body);
                    
                    return makeASTWithMeta(
                        EDefmodule(name, exunitBody),
                        ast.metadata,
                        ast.pos
                    );
                }
                // Not an ExUnit module, return as-is
                return ast;
                
            default:
                // Not a module, just pass through
                return ast;
        }
    }
    
    /**
     * Build ExUnit.Case module body
     * 
     * WHY: ExUnit modules need use ExUnit.Case and test macros
     * WHAT: Transforms regular functions into test blocks with support for describe blocks, async, and tags
     * HOW: Adds use statement, groups tests by describe blocks, and transforms @:test methods with proper attributes
     */
    static function buildExUnitBody(moduleName: String, existingBody: ElixirAST): ElixirAST {
        var statements = [];
        
        // Check if module should be async by scanning for any async tests
        var hasAsyncTests = false;
        switch(existingBody.def) {
            case EBlock(exprs):
                for (expr in exprs) {
                    if (expr.metadata?.isAsync == true) {
                        hasAsyncTests = true;
                        break;
                    }
                }
            default:
        }
        
        // use ExUnit.Case with async option if needed
        if (hasAsyncTests) {
            // Create keyword list [async: true] for ExUnit.Case options
            statements.push(makeAST(EUse("ExUnit.Case", [
                makeAST(EKeywordList([
                    {key: "async", value: makeAST(EAtom(ElixirAtom.true_()))}
                ]))
            ])));
        } else {
            statements.push(makeAST(EUse("ExUnit.Case", [])));
        }

        // Optional Phoenix test helpers: only inject when app_name is defined (indicates Phoenix app context)
        var appName = Context.definedValue("app_name");
        var needsLiveViewHelpers = usesLiveViewHelpers(existingBody);
        if (appName != null && appName.length > 0) {
            // Import brings functions like build_conn/0 into scope; alias supports ConnTest.* calls.
            statements.push(makeAST(EImport("Phoenix.ConnTest", null, null)));
            statements.push(makeAST(EAlias("Phoenix.ConnTest", "ConnTest")));
            // ExUnit.ConnCase expects @endpoint to be set for request helpers
            var endpointModule = appName + "Web.Endpoint";
            statements.push(makeAST(EModuleAttribute("endpoint", makeAST(EVar(endpointModule)))));
            if (needsLiveViewHelpers) {
                // Inject Phoenix.LiveViewTest helpers and alias for LiveViewTest.* calls
                statements.push(makeAST(EImport("Phoenix.LiveViewTest", null, null)));
                statements.push(makeAST(EAlias("Phoenix.LiveViewTest", "LiveViewTest")));
            }
        }
        
        // Group tests by describe blocks
        var testsWithoutDescribe = [];
        var describeGroups = new Map<String, Array<ElixirAST>>();
        
        // Process existing body to transform test methods
        switch(existingBody.def) {
            case EBlock(exprs):
                for (expr in exprs) {
                    switch(expr.def) {
                        case EDef(name, params, guards, body) | EDefp(name, params, guards, body) if (expr.metadata?.isTest == true):
                            // Transform function into test block
                            var testName = name;
                            // Remove "test" prefix if present
                            if (StringTools.startsWith(testName, "test_")) {
                                testName = testName.substring(5);
                            } else if (StringTools.startsWith(testName, "test")) {
                                testName = testName.substring(4);
                            }
                            // Convert to readable name (snake_case to spaces)
                            testName = StringTools.replace(testName, "_", " ");
                            
                            // Check for tags
                            var testTags = expr.metadata?.testTags;
                            var taggedTestName = testName;
                            if (testTags != null && testTags.length > 0) {
                                // Add tags as @tag annotations before the test
                                for (tag in testTags) {
                                    taggedTestName = '@tag $tag\n  $taggedTestName';
                                }
                            }
                            
                            var testBlock = makeAST(
                                EMacroCall(
                                    "test",
                                    [makeAST(EString(testName))],
                                    body
                                )
                            );
                            
                            // Check if this test belongs to a describe block
                            var describeBlock = expr.metadata?.describeBlock;
                            if (describeBlock != null) {
                                if (!describeGroups.exists(describeBlock)) {
                                    describeGroups.set(describeBlock, []);
                                }
                                describeGroups.get(describeBlock).push(testBlock);
                            } else {
                                testsWithoutDescribe.push(testBlock);
                            }
                            
                        case EDef(name, params, guards, body) | EDefp(name, params, guards, body) if (expr.metadata?.isSetup == true):
                            // Transform @:setup function into ExUnit setup callback
                            var setupBlock = makeAST(
                                EMacroCall(
                                    "setup",
                                    [makeAST(EVar("context"))],
                                    body
                                )
                            );
                            statements.push(setupBlock);
                            
                        case EDef(name, params, guards, body) | EDefp(name, params, guards, body) if (expr.metadata?.isSetupAll == true):
                            // Transform @:setupAll function into ExUnit setup_all callback
                            var setupAllBlock = makeAST(
                                EMacroCall(
                                    "setup_all",
                                    [makeAST(EVar("context"))],
                                    body
                                )
                            );
                            statements.push(setupAllBlock);
                            
                        case EDef(name, params, guards, body) | EDefp(name, params, guards, body) if (expr.metadata?.isTeardown == true):
                            // Transform @:teardown function into ExUnit on_exit callback
                            var teardownBody = makeAST(
                                EBlock([
                                    makeAST(
                                        ECall(
                                            null,  // No target needed for on_exit
                                            "on_exit",
                                            [makeAST(EFn([{args: [], guard: null, body: body}]))]
                                        )
                                    ),
                                    makeAST(EAtom(ElixirAtom.ok()))
                                ])
                            );
                            var teardownBlock = makeAST(
                                EMacroCall(
                                    "setup",
                                    [makeAST(EVar("context"))],
                                    teardownBody
                                )
                            );
                            statements.push(teardownBlock);
                            
                        case EDef(name, params, guards, body) | EDefp(name, params, guards, body) if (expr.metadata?.isTeardownAll == true):
                            // Transform @:teardownAll function into ExUnit on_exit callback in setup_all
                            var teardownAllBody = makeAST(
                                EBlock([
                                    makeAST(
                                        ECall(
                                            null,  // No target needed for on_exit
                                            "on_exit",
                                            [makeAST(EFn([{args: [], guard: null, body: body}]))]
                                        )
                                    ),
                                    makeAST(EAtom(ElixirAtom.ok()))
                                ])
                            );
                            var teardownAllBlock = makeAST(
                                EMacroCall(
                                    "setup_all",
                                    [makeAST(EVar("context"))],
                                    teardownAllBody
                                )
                            );
                            statements.push(teardownAllBlock);
                            
                        case EDef(name, _, _, _) if (name == "setup" || name == "setupAll"):
                            // Keep setup functions as-is for backward compatibility
                            statements.push(expr);
                            
                        case EDefp(name, _, _, _) if (name == "setup" || name == "setupAll"):
                            // Keep private setup functions as-is for backward compatibility
                            statements.push(expr);
                            
                        default:
                            // Keep other expressions (but not in main statements yet)
                            // They'll be added after describe blocks
                    }
                }
                
                // First add setup/teardown blocks
                for (expr in exprs) {
                    switch(expr.def) {
                        case EDef(name, params, guards, body) | EDefp(name, params, guards, body) if (expr.metadata?.isSetup == true || 
                                                                                                       expr.metadata?.isSetupAll == true ||
                                                                                                       expr.metadata?.isTeardown == true ||
                                                                                                       expr.metadata?.isTeardownAll == true):
                            // Already processed above, skip
                        case EDef(name, params, guards, body) | EDefp(name, params, guards, body) if (expr.metadata?.isTest == true):
                            // Already processed above, skip
                        default:
                            // Keep other expressions
                            statements.push(expr);
                    }
                }
                
                // Add tests without describe blocks
                for (test in testsWithoutDescribe) {
                    statements.push(test);
                }
                
                // Add describe blocks with their grouped tests
                for (describeName in describeGroups.keys()) {
                    var tests = describeGroups.get(describeName);
                    if (tests.length > 0) {
                        // Create describe block containing all tests in this group
                        var describeBlock = makeAST(
                            EMacroCall(
                                "describe",
                                [makeAST(EString(describeName))],
                                makeAST(EBlock(tests))
                            )
                        );
                        statements.push(describeBlock);
                    }
                }
                
            default:
                // Single expression body
                statements.push(existingBody);
        }
        
        return makeAST(EBlock(statements));
    }

    /**
     * Detect whether an ExUnit module body references Phoenix.LiveViewTest helpers.
     *
     * WHAT: Walks the existing body AST to find any use/import/alias of LiveViewTest (or LiveView).
     * WHY: Avoid injecting unused imports/aliases/@endpoint into tests that don't exercise LiveView,
     *      which produces Elixir compiler warnings and slows test runs.
     * HOW: Shallow recursive traversal of the ElixirAST node tree with early exit once a match is found.
     */
    static function usesLiveViewHelpers(ast: ElixirAST): Bool {
        var found = false;
        function visit(e: ElixirAST): Void {
            if (found || e == null) return;
            switch (e.def) {
                case EVar(name):
                    if (name == "LiveViewTest" || name == "Phoenix.LiveViewTest" || name == "LiveView") {
                        found = true;
                        return;
                    }
                case EImport(moduleName, _, _):
                    if (moduleName == "Phoenix.LiveViewTest") {
                        found = true;
                        return;
                    }
                case EAlias(moduleName, aliasName):
                    if (moduleName == "Phoenix.LiveViewTest" || aliasName == "LiveViewTest") {
                        found = true;
                        return;
                    }
                case ECall(target, _, args):
                    if (target != null) visit(target);
                    if (args != null) for (a in args) visit(a);
                case ERemoteCall(targetExpr, _, argsList):
                    visit(targetExpr);
                    if (argsList != null) for (a in argsList) visit(a);
                case EBlock(exprs):
                    for (expr in exprs) visit(expr);
                case EIf(condition, thenExpr, elseExpr):
                    visit(condition); visit(thenExpr); if (elseExpr != null) visit(elseExpr);
                case ECase(scrutinee, clauses):
                    visit(scrutinee);
                    for (c in clauses) {
                        if (c.guard != null) visit(c.guard);
                        visit(c.body);
                    }
                case EDef(_, _, _, body) | EDefp(_, _, _, body):
                    visit(body);
                case EKeywordList(kvs):
                    for (kv in kvs) visit(kv.value);
                case EList(items):
                    for (item in items) visit(item);
                case ETuple(items):
                    for (item in items) visit(item);
                case EMap(kvs):
                    for (kv in kvs) { visit(kv.key); visit(kv.value); }
                case EPipe(left, right):
                    visit(left); visit(right);
                case EModuleAttribute(_, value):
                    visit(value);
                default:
            }
        }
        visit(ast);
        return found;
    }
    
    /**
     * supervisorTransformPass: Preserve supervisor functions from dead code elimination
     * 
     * WHY: Phoenix/OTP calls child_spec/1 and start_link/1 at runtime via supervision tree
     * WHAT: Ensures these functions are marked with @:keep metadata to prevent DCE
     * HOW: Detects isSupervisor metadata and marks critical functions for preservation
     * 
     * BACKGROUND: Haxe's Dead Code Elimination (DCE) removes "unused" functions. But
     * supervisor child_spec and start_link are called by the OTP framework at runtime,
     * not from our Haxe code. Without @:keep, they get deleted and Phoenix crashes.
     */
    public static function supervisorTransformPass(ast: ElixirAST): ElixirAST {
        #if debug_annotation_transforms
        if (ast.metadata?.isSupervisor == true) {
            // DISABLED: trace('[XRay Supervisor Transform] PASS START - Found Supervisor module');
            // DISABLED: trace('[XRay Supervisor Transform] AST type: ${Type.enumConstructor(ast.def)}');
        }
        #end
        
        // Check if this is a supervisor module
        var isSupervisor = ast.metadata?.isSupervisor == true;
        if (!isSupervisor) {
            // Not a supervisor, pass through unchanged
            return ast;
        }
        
        // Process the module to ensure critical functions are preserved
        switch(ast.def) {
            case EModule(name, attributes, body):
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Supervisor Transform] Processing supervisor EModule: $name');
                #end
                
                // Transform the body array to preserve supervisor functions
                var transformedBody = preserveSupervisorFunctionsInArray(body, name, ast.metadata);
                
                // Return the module with transformed body
                return makeASTWithMeta(
                    EModule(name, attributes, transformedBody),
                    ast.metadata,
                    ast.pos
                );
                
            case EDefmodule(name, body):
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Supervisor Transform] Processing supervisor EDefmodule: $name');
                #end
                
                // Transform the body to preserve supervisor functions
                var transformedBody = preserveSupervisorFunctionsInAST(body, name, ast.metadata);
                
                // Return the module with transformed body
                return makeASTWithMeta(
                    EDefmodule(name, transformedBody),
                    ast.metadata,
                    ast.pos
                );
                
            default:
                // Not a module definition, pass through
                return ast;
        }
    }
    
    /**
     * Helper to preserve supervisor functions from DCE in Array body (EModule)
     */
    static function preserveSupervisorFunctionsInArray(body: Array<ElixirAST>, moduleName: String, metadata: ElixirMetadata): Array<ElixirAST> {
        var statements = [];
        var hasChildSpec = false;
        var hasStartLink = false;
        
        // Process each statement in the array
        for (expr in body) {
            switch(expr.def) {
                case EDef(name, params, guards, fnBody) | EDefp(name, params, guards, fnBody):
                    if (name == "child_spec") {
                        hasChildSpec = true;
                        // Mark with keep metadata
                        var newMetadata = if (expr.metadata != null) {
                            var meta = Reflect.copy(expr.metadata);
                            meta.isKeep = true;
                            meta;
                        } else {
                            {isKeep: true};
                        };
                        
                        var preservedFunc = makeASTWithMeta(
                            expr.def,
                            newMetadata,
                            expr.pos
                        );
                        statements.push(preservedFunc);
                        #if debug_annotation_transforms
                        // DISABLED: trace('[XRay Supervisor Transform] Marked child_spec for preservation');
                        #end
                    } else if (name == "start_link") {
                        hasStartLink = true;
                        // Mark with keep metadata
                        var newMetadata = if (expr.metadata != null) {
                            var meta = Reflect.copy(expr.metadata);
                            meta.isKeep = true;
                            meta;
                        } else {
                            {isKeep: true};
                        };
                        
                        var preservedFunc = makeASTWithMeta(
                            expr.def,
                            newMetadata,
                            expr.pos
                        );
                        statements.push(preservedFunc);
                        #if debug_annotation_transforms
                        // DISABLED: trace('[XRay Supervisor Transform] Marked start_link for preservation');
                        #end
                    } else {
                        // Keep other functions as-is
                        statements.push(expr);
                    }
                default:
                    // Keep other expressions
                    statements.push(expr);
            }
        }
        
        // If supervisor module needs use Supervisor statement, add it
        var needsUseSupervisor = metadata?.isSupervisor == true && 
                                 metadata?.isEndpoint != true && 
                                 metadata?.isApplication != true;
        
        if (needsUseSupervisor) {
            // Check if we already have use Supervisor and init/1
            var hasUseSupervisor = false;
            var hasInit = false;
            
            for (stmt in statements) {
                switch(stmt.def) {
                    case EUse("Supervisor", _):
                        hasUseSupervisor = true;
                    case EDef("init", _, _, _):
                        hasInit = true;
                    default:
                }
            }
            
            if (!hasUseSupervisor) {
                // Add use Supervisor at the beginning
                statements.insert(0, makeAST(EUse("Supervisor", [])));
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Supervisor Transform] Added use Supervisor statement');
                #end
            }
            
            if (!hasInit) {
                // Add default init/1 callback that delegates to start_link
                var initBody = makeAST(
                    ETuple([
                        makeAST(EAtom("ok")),
                        makeAST(ETuple([
                            makeAST(EList([])),  // Empty children list
                            makeAST(EKeywordList([
                                {key: "strategy", value: makeAST(EAtom("one_for_one"))},
                                {key: "max_restarts", value: makeAST(EInteger(3))},
                                {key: "max_seconds", value: makeAST(EInteger(5))}
                            ]))
                        ]))
                    ])
                );
                
                var initFunc = makeAST(
                    EDef("init", [PVar("_args")], null, initBody)
                );
                
                statements.push(initFunc);
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Supervisor Transform] Added default init/1 callback');
                #end
            }
        }
        
        return statements;
    }
    
    /**
     * Helper to preserve supervisor functions from DCE in AST body (EDefmodule)
     */
    static function preserveSupervisorFunctionsInAST(body: ElixirAST, moduleName: String, metadata: ElixirMetadata): ElixirAST {
        var statements = [];
        var hasChildSpec = false;
        var hasStartLink = false;
        
        // First, check what functions exist and mark them for preservation
        switch(body.def) {
            case EBlock(exprs):
                for (expr in exprs) {
                    switch(expr.def) {
                        case EDef(name, params, guards, fnBody) | EDefp(name, params, guards, fnBody):
                            if (name == "child_spec") {
                                hasChildSpec = true;
                                // Mark with keep metadata
                                var newMetadata = if (expr.metadata != null) {
                                    var meta = Reflect.copy(expr.metadata);
                                    meta.isKeep = true;
                                    meta;
                                } else {
                                    {isKeep: true};
                                };
                                
                                var preservedFunc = makeASTWithMeta(
                                    expr.def,
                                    newMetadata,
                                    expr.pos
                                );
                                statements.push(preservedFunc);
                                #if debug_annotation_transforms
                                // DISABLED: trace('[XRay Supervisor Transform] Marked child_spec for preservation');
                                #end
                            } else if (name == "start_link") {
                                hasStartLink = true;
                                // Mark with keep metadata
                                var newMetadata = if (expr.metadata != null) {
                                    var meta = Reflect.copy(expr.metadata);
                                    meta.isKeep = true;
                                    meta;
                                } else {
                                    {isKeep: true};
                                };
                                
                                var preservedFunc = makeASTWithMeta(
                                    expr.def,
                                    newMetadata,
                                    expr.pos
                                );
                                statements.push(preservedFunc);
                                #if debug_annotation_transforms
                                // DISABLED: trace('[XRay Supervisor Transform] Marked start_link for preservation');
                                #end
                            } else {
                                // Keep other functions as-is
                                statements.push(expr);
                            }
                        default:
                            // Keep other expressions
                            statements.push(expr);
                    }
                }
            default:
                // Single expression body
                return body;
        }
        
        // If supervisor module needs use Supervisor statement, add it
        // (This would typically be done in a separate pass, but we can ensure it here)
        var needsUseSupervisor = metadata?.isSupervisor == true && 
                                 metadata?.isEndpoint != true && 
                                 metadata?.isApplication != true;
        
        if (needsUseSupervisor) {
            // Check if we already have use Supervisor and init/1
            var hasUseSupervisor = false;
            var hasInit = false;
            
            for (stmt in statements) {
                switch(stmt.def) {
                    case EUse("Supervisor", _):
                        hasUseSupervisor = true;
                    case EDef("init", _, _, _):
                        hasInit = true;
                    default:
                }
            }
            
            if (!hasUseSupervisor) {
                // Add use Supervisor at the beginning
                statements.insert(0, makeAST(EUse("Supervisor", [])));
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Supervisor Transform] Added use Supervisor statement');
                #end
            }
            
            if (!hasInit) {
                // Add default init/1 callback that delegates to start_link
                var initBody = makeAST(
                    ETuple([
                        makeAST(EAtom("ok")),
                        makeAST(ETuple([
                            makeAST(EList([])),  // Empty children list
                            makeAST(EKeywordList([
                                {key: "strategy", value: makeAST(EAtom("one_for_one"))},
                                {key: "max_restarts", value: makeAST(EInteger(3))},
                                {key: "max_seconds", value: makeAST(EInteger(5))}
                            ]))
                        ]))
                    ])
                );
                
                var initFunc = makeAST(
                    EDef("init", [PVar("_args")], null, initBody)
                );
                
                statements.push(initFunc);
                #if debug_annotation_transforms
                // DISABLED: trace('[XRay Supervisor Transform] Added default init/1 callback');
                #end
            }
        }
        
        return makeAST(EBlock(statements));
    }
}

#end
