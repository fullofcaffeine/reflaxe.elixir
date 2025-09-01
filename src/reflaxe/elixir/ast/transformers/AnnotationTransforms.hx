package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.EKeywordPair;
import reflaxe.elixir.ast.ElixirAST.EMapPair;
import reflaxe.elixir.ast.ElixirASTHelpers.transformAST;

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
        return transformAST(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDefmodule(name, body) if (node.metadata?.isEndpoint == true):
                    #if debug_annotation_transforms
                    trace('[AnnotationTransforms] Transforming endpoint module: $name');
                    trace('[AnnotationTransforms] App name: ${node.metadata.appName}');
                    #end
                    
                    var appName = node.metadata.appName ?? "app";
                    var endpointBody = buildEndpointBody(name, appName);
                    
                    // Create new module with endpoint body, preserving metadata
                    return makeASTWithMeta(
                        EDefmodule(name, endpointBody),
                        node.metadata,
                        node.pos
                    );
                    
                default:
                    return node;
            }
        });
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
        statements.push(makeAST(EAttribute("session_options", sessionOptions)));
        
        // socket "/live", Phoenix.LiveView.Socket configuration
        var socketOptions = makeAST(EKeywordList([
            {key: "websocket", value: makeAST(EKeywordList([
                {key: "connect_info", value: makeAST(EKeywordList([
                    {key: "session", value: makeAST(EAttribute("session_options", null))}
                ]))}
            ]))}
        ]));
        statements.push(makeAST(ECall(null, "socket", [
            makeAST(EString("/live")),
            makeAST(ERemoteCall(
                makeAST(EAtom("Phoenix")),
                "LiveView.Socket",
                []
            )),
            socketOptions
        ])));
        
        // plug Plug.Static configuration
        var staticOptions = makeAST(EKeywordList([
            {key: "at", value: makeAST(EString("/"))},
            {key: "from", value: makeAST(EAtom(appName))},
            {key: "gzip", value: makeAST(EBoolean(false))},
            {key: "only", value: makeAST(ECall(
                makeAST(EAtom(moduleName)),
                "static_paths",
                []
            ))}
        ]));
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(ERemoteCall(
                makeAST(EAtom("Plug")),
                "Static",
                []
            )),
            staticOptions
        ])));
        
        // if code_reloading? do plug Phoenix.CodeReloader end
        var codeReloadingBlock = makeAST(EIf(
            makeAST(ECall(null, "code_reloading?", [])),
            makeAST(ECall(null, "plug", [
                makeAST(ERemoteCall(
                    makeAST(EAtom("Phoenix")),
                    "CodeReloader",
                    []
                ))
            ])),
            null
        ));
        statements.push(codeReloadingBlock);
        
        // Request pipeline plugs
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(ERemoteCall(makeAST(EAtom("Plug")), "RequestId", []))
        ])));
        
        var telemetryOptions = makeAST(EKeywordList([
            {key: "event_prefix", value: makeAST(EList([
                makeAST(EAtom("phoenix")),
                makeAST(EAtom("endpoint"))
            ]))}
        ]));
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(ERemoteCall(makeAST(EAtom("Plug")), "Telemetry", [])),
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
                makeAST(EAtom("Phoenix")),
                "json_library",
                []
            ))}
        ]));
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(ERemoteCall(makeAST(EAtom("Plug")), "Parsers", [])),
            parsersOptions
        ])));
        
        // Other standard plugs
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(ERemoteCall(makeAST(EAtom("Plug")), "MethodOverride", []))
        ])));
        
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(ERemoteCall(makeAST(EAtom("Plug")), "Head", []))
        ])));
        
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(ERemoteCall(makeAST(EAtom("Plug")), "Session", [])),
            makeAST(EAttribute("session_options", null))
        ])));
        
        // Router plug (assumes Web module pattern)
        var routerModule = moduleName.replace(".Endpoint", ".Router");
        statements.push(makeAST(ECall(null, "plug", [
            makeAST(EAtom(routerModule))
        ])));
        
        // def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)
        var staticPathsBody = makeAST(ESigil(
            "w",
            "assets fonts images favicon.ico robots.txt",
            ""
        ));
        statements.push(makeAST(EDef(
            "static_paths",
            [],
            null,
            staticPathsBody
        )));
        
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
        return transformAST(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDefmodule(name, body) if (node.metadata?.isLiveView == true):
                    #if debug_annotation_transforms
                    trace('[AnnotationTransforms] Transforming LiveView module: $name');
                    #end
                    
                    var liveViewBody = buildLiveViewBody(name, body);
                    
                    return makeASTWithMeta(
                        EDefmodule(name, liveViewBody),
                        node.metadata,
                        node.pos
                    );
                    
                default:
                    return node;
            }
        });
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
        return transformAST(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDefmodule(name, body) if (node.metadata?.isSchema == true):
                    #if debug_annotation_transforms
                    trace('[AnnotationTransforms] Transforming schema module: $name');
                    trace('[AnnotationTransforms] Table name: ${node.metadata.tableName}');
                    #end
                    
                    var tableName = node.metadata.tableName ?? "items";
                    var schemaBody = buildSchemaBody(name, tableName, body);
                    
                    return makeASTWithMeta(
                        EDefmodule(name, schemaBody),
                        node.metadata,
                        node.pos
                    );
                    
                default:
                    return node;
            }
        });
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
        // For now, create a simple schema block
        // In a real implementation, this would analyze the class fields
        var schemaBlock = makeAST(ECall(null, "schema", [
            makeAST(EString(tableName)),
            makeAST(EBlock([
                // Fields would go here based on class analysis
                makeAST(ECall(null, "field", [
                    makeAST(EAtom("name")),
                    makeAST(EAtom("string"))
                ])),
                makeAST(ECall(null, "timestamps", []))
            ]))
        ]));
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
        return transformAST(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDefmodule(name, body) if (node.metadata?.isApplication == true):
                    #if debug_annotation_transforms
                    trace('[AnnotationTransforms] Transforming application module: $name');
                    #end
                    
                    var appBody = buildApplicationBody(name, body);
                    
                    return makeASTWithMeta(
                        EDefmodule(name, appBody),
                        node.metadata,
                        node.pos
                    );
                    
                default:
                    return node;
            }
        });
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
                        {key: "name", value: makeAST(ERemoteCall(
                            makeAST(EAtom(moduleName)),
                            "Supervisor",
                            []
                        ))}
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
}

#end