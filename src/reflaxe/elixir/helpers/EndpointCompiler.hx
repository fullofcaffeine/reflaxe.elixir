package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.BaseCompiler;

/**
 * EndpointCompiler: Generates Phoenix.Endpoint modules
 * 
 * WHY: Phoenix applications require an Endpoint module that configures the HTTP server,
 * handles WebSocket connections, serves static files, and sets up the request pipeline.
 * 
 * WHAT: Transforms Haxe classes marked with @:endpoint into complete Phoenix.Endpoint modules
 * with proper plugs, socket configuration, and session handling.
 * 
 * HOW: Detects @:endpoint annotation and generates the necessary 'use Phoenix.Endpoint' 
 * along with all required plug configurations and socket setup.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Handles only Phoenix.Endpoint generation
 * - Open/Closed: Can be extended for custom endpoint configurations
 * - Type Safety: Compile-time validation of endpoint configuration
 * - Idiomatic Output: Generates standard Phoenix.Endpoint modules
 */
@:nullSafety(Off)
class EndpointCompiler {
    
    var compiler: BaseCompiler;
    
    public function new(compiler: BaseCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Check if a class should be compiled as a Phoenix.Endpoint
     */
    public function isEndpoint(classType: ClassType): Bool {
        return classType.meta.has(":endpoint");
    }
    
    /**
     * Compile a class to a Phoenix.Endpoint module
     * 
     * WHY: Phoenix requires specific module structure for endpoints
     * WHAT: Generates complete endpoint with plugs and socket configuration
     * HOW: Creates use statement, session options, socket setup, and plug pipeline
     */
    public function compileEndpoint(classType: ClassType, varFields: Array<String>): String {
        #if debug_endpoint_compiler
        trace('[EndpointCompiler] Compiling endpoint: ${classType.name}');
        #end
        
        var appName = extractAppName(classType);
        var moduleName = getModuleName(classType);
        
        var result = new StringBuf();
        
        // Module definition
        result.add('defmodule ${moduleName} do\n');
        result.add('  use Phoenix.Endpoint, otp_app: :${appName}\n\n');
        
        // Session configuration
        result.add('  # Session configuration\n');
        result.add('  @session_options [\n');
        result.add('    store: :cookie,\n');
        result.add('    key: "_${appName}_key",\n');
        result.add('    signing_salt: "generated_salt_${Date.now().getTime()}",\n');
        result.add('    same_site: "Lax"\n');
        result.add('  ]\n\n');
        
        // Socket configuration for LiveView
        result.add('  # LiveView socket\n');
        result.add('  socket "/live", Phoenix.LiveView.Socket,\n');
        result.add('    websocket: [connect_info: [session: @session_options]]\n\n');
        
        // Static files
        result.add('  # Serve static files\n');
        result.add('  plug Plug.Static,\n');
        result.add('    at: "/",\n');
        result.add('    from: :${appName},\n');
        result.add('    gzip: false,\n');
        result.add('    only: ${moduleName}.static_paths()\n\n');
        
        // Development code reloading
        result.add('  # Code reloading in development\n');
        result.add('  if code_reloading? do\n');
        result.add('    plug Phoenix.CodeReloader\n');
        result.add('  end\n\n');
        
        // Request pipeline
        result.add('  # Request pipeline\n');
        result.add('  plug Plug.RequestId\n');
        result.add('  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]\n\n');
        
        result.add('  plug Plug.Parsers,\n');
        result.add('    parsers: [:urlencoded, :multipart, :json],\n');
        result.add('    pass: ["*/*"],\n');
        result.add('    json_decoder: Phoenix.json_library()\n\n');
        
        result.add('  plug Plug.MethodOverride\n');
        result.add('  plug Plug.Head\n');
        result.add('  plug Plug.Session, @session_options\n');
        
        // Router (assumes Web module pattern)
        var routerModule = moduleName.replace(".Endpoint", ".Router");
        result.add('  plug ${routerModule}\n\n');
        
        // Static paths helper function
        result.add('  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)\n');
        
        result.add('end');
        
        #if debug_endpoint_compiler
        trace('[EndpointCompiler] Generated endpoint module for ${moduleName}');
        #end
        
        return result.toString();
    }
    
    /**
     * Extract application name from class metadata or default pattern
     */
    function extractAppName(classType: ClassType): String {
        if (classType.meta.has(":appName")) {
            var appNameMeta = classType.meta.extract(":appName");
            if (appNameMeta.length > 0 && appNameMeta[0].params != null && appNameMeta[0].params.length > 0) {
                switch(appNameMeta[0].params[0].expr) {
                    case EConst(CString(s, _)):
                        return s.toLowerCase();
                    default:
                }
            }
        }
        
        // Default: derive from module name
        var moduleName = getModuleName(classType);
        return moduleName.split("Web")[0].toLowerCase();
    }
    
    /**
     * Get the target module name for the endpoint
     */
    function getModuleName(classType: ClassType): String {
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
}

#end