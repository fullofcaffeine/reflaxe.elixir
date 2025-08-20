package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.ClassType;
import reflaxe.elixir.helpers.FormatHelper;
import reflaxe.elixir.helpers.AnnotationSystem;

/**
 * Compiler for @:endpoint annotated classes
 * Generates Phoenix.Endpoint modules with proper HTTP and WebSocket configuration
 * 
 * Handles compilation of Haxe classes marked with @:endpoint annotation
 * to generate Phoenix endpoint modules with LiveView support, session handling,
 * and standard Phoenix plugs.
 */
class EndpointCompiler {
    /**
     * Check if a class has @:endpoint annotation
     */
    public static function isEndpointClass(classType: ClassType): Bool {
        return classType.meta.has(":endpoint");
    }
    
    /**
     * Compile @:endpoint class to Phoenix.Endpoint module
     * 
     * Generates a Phoenix endpoint module with:
     * - use Phoenix.Endpoint with otp_app configuration
     * - LiveView socket configuration
     * - Static file serving configuration
     * - Session and cookie configuration
     * - Standard Phoenix plugs pipeline
     * - Router integration
     * 
     * @param classType The Haxe class with @:endpoint annotation
     * @param className The target Elixir module name
     * @return Generated Elixir module code
     */
    public static function compileEndpointModule(classType: ClassType, className: String): String {
        var result = new StringBuf();
        
        // Get app name from annotation
        var appName = AnnotationSystem.getEffectiveAppName(classType);
        var otpApp = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(appName);
        var webModule = '${appName}Web';
        
        // Module definition
        result.add('defmodule ${className} do\n');
        
        // Module documentation
        var docString = 'HTTP endpoint for ${appName}\n\n';
        docString += 'Handles incoming HTTP requests and WebSocket connections.\n';
        docString += 'Configured with LiveView support, session handling, and standard Phoenix plugs.';
        
        if (classType.doc != null) {
            docString = classType.doc;
        }
        
        result.add(FormatHelper.formatDoc(docString, true, 1) + '\n');
        
        // Use Phoenix.Endpoint
        result.add('  use Phoenix.Endpoint, otp_app: :${otpApp}\n\n');
        
        // Session configuration
        result.add('  # The session will be stored in the cookie and signed,\n');
        result.add('  # this means its contents can be read but not tampered with.\n');
        result.add('  # Set :encryption_salt if you would also like to encrypt it.\n');
        result.add('  @session_options [\n');
        result.add('    store: :cookie,\n');
        result.add('    key: "_${otpApp}_key",\n');
        result.add('    signing_salt: "${generateSigningSalt()}"\n');
        result.add('  ]\n\n');
        
        // LiveView socket configuration
        result.add('  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]\n\n');
        
        // Static file serving
        result.add('  # Serve at "/" the static files from "priv/static" directory.\n');
        result.add('  #\n');
        result.add('  # You should set gzip to true if you are running phx.digest\n');
        result.add('  # when deploying your static files in production.\n');
        result.add('  plug Plug.Static,\n');
        result.add('    at: "/",\n');
        result.add('    from: :${otpApp},\n');
        result.add('    gzip: false,\n');
        result.add('    only: ~w(assets fonts images favicon.ico robots.txt)\n\n');
        
        // Development-only plugs
        result.add('  # Code reloading can be explicitly enabled under the\n');
        result.add('  # :code_reloader configuration of your endpoint.\n');
        result.add('  if code_reloading? do\n');
        result.add('    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket\n');
        result.add('    plug Phoenix.LiveReloader\n');
        result.add('    plug Phoenix.CodeReloader\n');
        result.add('    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :${otpApp}\n');
        result.add('  end\n\n');
        
        // Standard Phoenix plugs
        result.add('  plug Plug.RequestId\n');
        result.add('  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]\n\n');
        
        result.add('  plug Plug.Parsers,\n');
        result.add('    parsers: [:urlencoded, :multipart, :json],\n');
        result.add('    pass: ["*/*"],\n');
        result.add('    json_decoder: Phoenix.json_library()\n\n');
        
        result.add('  plug Plug.MethodOverride\n');
        result.add('  plug Plug.Head\n');
        result.add('  plug Plug.Session, @session_options\n');
        result.add('  plug ${webModule}.Router\n');
        
        result.add('end');
        
        return result.toString();
    }
    
    /**
     * Generate a random signing salt for session security
     * In production, this should be configured via environment variables
     */
    private static function generateSigningSalt(): String {
        // Generate a simple 8-character salt for demo purposes
        // In real applications, this should be a secure random string
        var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        var salt = "";
        for (i in 0...8) {
            salt += chars.charAt(Std.random(chars.length));
        }
        return salt;
    }
}

#end