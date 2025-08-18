package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

using StringTools;

/**
 * OTP Application compilation support for Phoenix and Elixir applications
 * Handles @:application annotation and proper child spec generation
 */
class ApplicationCompiler {
    
    /**
     * Check if a class is an OTP application module
     */
    public static function isApplicationClass(className: String): Bool {
        if (className == null || className == "") return false;
        return className.indexOf("Application") != -1 || 
               className.endsWith("App");
    }
    
    /**
     * Generate proper OTP application module with Phoenix conventions
     * Accepts appName parameter for generic application support
     */
    public static function generateApplicationModule(className: String, children: Array<Dynamic>, appName: String = "App"): String {
        var moduleName = className.indexOf(".") > -1 ? className : className + ".Application";
        var result = new StringBuf();
        
        result.add('defmodule ${moduleName} do\n');
        result.add('  @moduledoc false\n');
        result.add('\n');
        result.add('  use Application\n');
        result.add('\n');
        result.add('  @impl true\n');
        result.add('  def start(_type, _args) do\n');
        result.add('    children = [\n');
        
        // Generate proper child specifications
        var childSpecs = [];
        for (child in children) {
            childSpecs.push(generateChildSpec(child, appName));
        }
        
        result.add(childSpecs.join(',\n'));
        result.add('\n    ]\n');
        result.add('\n');
        result.add('    opts = [strategy: :one_for_one, name: ${appName}.Supervisor]\n');
        result.add('    Supervisor.start_link(children, opts)\n');
        result.add('  end\n');
        
        // Add config_change callback for Phoenix
        if (className.indexOf("Web") > -1 || className.indexOf("Phoenix") > -1) {
            result.add('\n');
            result.add('  @impl true\n');
            result.add('  def config_change(changed, _new, removed) do\n');
            result.add('    ${appName}Web.Endpoint.config_change(changed, removed)\n');
            result.add('    :ok\n');
            result.add('  end\n');
        }
        
        result.add('end\n');
        
        return result.toString();
    }
    
    /**
     * Generate a proper OTP child specification
     * Uses dynamic app name resolution to remain generic across different applications
     */
    public static function generateChildSpec(child: Dynamic, appName: String = "App"): String {
        // Handle different child spec formats
        if (child.id != null) {
            var id = child.id;
            
            // Check for special Phoenix modules
            if (id.indexOf(".Repo") > -1) {
                // Simple module reference for Repo - use provided app name
                var repoModule = id.indexOf(appName) > -1 ? id : '${appName}.Repo';
                return '      ${repoModule}';
            }
            else if (id == "Phoenix.PubSub" || id.indexOf("PubSub") > -1) {
                // Tuple format for PubSub with configuration
                var defaultPubSubName = '${appName}.PubSub';
                var name = child.start != null && child.start.args != null && 
                          child.start.args[0] != null ? child.start.args[0].name : defaultPubSubName;
                return '      {Phoenix.PubSub, name: ${name}}';
            }
            else if (id.indexOf("Telemetry") > -1) {
                // Simple module reference for Telemetry - use dynamic app name
                var telemetryModule = id.indexOf(appName) > -1 ? id : '${appName}Web.Telemetry';
                return '      ${telemetryModule}';
            }
            else if (id.indexOf("Endpoint") > -1) {
                // Simple module reference for Endpoint - use dynamic app name
                var endpointModule = id.indexOf(appName) > -1 ? id : '${appName}Web.Endpoint';
                return '      ${endpointModule}';
            }
            else {
                // Generic child spec - try to determine format
                var module = child.start != null && child.start.module != null ? 
                            child.start.module : id;
                            
                // Remove quotes if present
                module = module.split('"').join('');
                
                // Check if we need tuple format
                if (child.start != null && child.start.args != null && 
                    child.start.args.length > 0) {
                    // Has arguments - use tuple format
                    return '      {${module}, ${formatArgs(child.start.args)}}';
                } else {
                    // No arguments - simple module reference
                    return '      ${module}';
                }
            }
        }
        
        // Fallback for unknown format
        return '      # Fallback: Unknown child spec format - define properly in Haxe source';
    }
    
    /**
     * Format arguments for child specs
     */
    private static function formatArgs(args: Array<Dynamic>): String {
        if (args == null || args.length == 0) return '[]';
        
        var formatted = [];
        for (arg in args) {
            if (arg.name != null) {
                // Named argument like {name: "TodoApp.PubSub"}
                formatted.push('name: ${arg.name}');
            } else {
                // Other argument types
                formatted.push(Std.string(arg));
            }
        }
        
        if (formatted.length == 1 && formatted[0].indexOf(":") > -1) {
            // Single keyword argument
            return formatted[0];
        } else {
            // Multiple arguments or non-keyword
            return '[' + formatted.join(', ') + ']';
        }
    }
    
    /**
     * Convert Haxe-style supervisor options to Elixir format
     */
    public static function convertSupervisorOptions(opts: Dynamic): String {
        var strategy = opts.strategy != null ? opts.strategy : "one_for_one";
        var name = opts.name != null ? opts.name : "__MODULE__.Supervisor";
        
        // Convert string strategy to atom
        strategy = strategy.split('"').join('');
        name = name.split('"').join('');
        
        return '[strategy: :${strategy}, name: ${name}]';
    }
}

#end