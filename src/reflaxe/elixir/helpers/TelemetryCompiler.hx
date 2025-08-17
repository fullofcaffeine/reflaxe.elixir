package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.ClassType;
import reflaxe.data.ClassFuncData;
import reflaxe.elixir.helpers.FormatHelper;
import reflaxe.elixir.helpers.AnnotationSystem;

/**
 * Compiler for @:telemetry annotated classes
 * Generates Phoenix telemetry supervisor modules with metrics configuration
 * 
 * Handles compilation of Haxe classes marked with @:telemetry annotation
 * to generate telemetry supervisors for application monitoring and observability.
 */
class TelemetryCompiler {
    /**
     * Check if a class has @:telemetry annotation
     */
    public static function isTelemetryClass(classType: ClassType): Bool {
        return classType.meta.has(":telemetry");
    }
    
    /**
     * Compile @:telemetry class to telemetry supervisor module
     * 
     * Generates a telemetry supervisor with:
     * - Supervisor behavior implementation
     * - Phoenix and Ecto metrics configuration
     * - Custom application metrics setup
     * - Proper error handling and monitoring
     * 
     * @param classType The Haxe class with @:telemetry annotation
     * @param className The target Elixir module name
     * @param funcFields Function definitions from the class
     * @return Generated Elixir module code
     */
    public static function compileTelemetryModule(classType: ClassType, className: String, funcFields: Array<ClassFuncData>): String {
        var result = new StringBuf();
        
        // Get app name from annotation
        var appName = AnnotationSystem.getEffectiveAppName(classType);
        var otpApp = appName.toLowerCase();
        
        // Module definition
        result.add('defmodule ${className} do\n');
        
        // Module documentation
        var docString = 'Telemetry supervisor for ${appName}\n\n';
        docString += 'Handles application metrics, monitoring, and observability.\n';
        docString += 'Configures telemetry for Phoenix endpoints, Ecto repositories, and custom events.';
        
        if (classType.doc != null) {
            docString = classType.doc;
        }
        
        result.add(FormatHelper.formatDoc(docString, true, 1) + '\n');
        
        // Use Supervisor behavior
        result.add('  use Supervisor\n\n');
        
        // Telemetry event definitions
        result.add('  @doc """\n');
        result.add('  Start the telemetry supervisor\n');
        result.add('  """\n');
        result.add('  def start_link(init_arg) do\n');
        result.add('    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)\n');
        result.add('  end\n\n');
        
        // Supervisor init callback
        result.add('  @impl true\n');
        result.add('  def init(_init_arg) do\n');
        result.add('    children = [\n');
        result.add('      # Telemetry metrics for Phoenix endpoint\n');
        result.add('      {TelemetryMetricsPrometheus.Core, metrics: metrics()}\n');
        result.add('    ]\n\n');
        result.add('    Supervisor.init(children, strategy: :one_for_one)\n');
        result.add('  end\n\n');
        
        // Metrics configuration
        result.add('  @doc """\n');
        result.add('  Return the list of telemetry metrics to track\n');
        result.add('  """\n');
        result.add('  def metrics do\n');
        result.add('    [\n');
        result.add('      # Phoenix Endpoint metrics\n');
        result.add('      Telemetry.Metrics.counter("phoenix.endpoint.start.system_time"),\n');
        result.add('      Telemetry.Metrics.counter("phoenix.endpoint.stop.duration"),\n');
        result.add('      Telemetry.Metrics.counter("phoenix.router_dispatch.start.system_time"),\n');
        result.add('      Telemetry.Metrics.counter("phoenix.router_dispatch.exception.duration"),\n\n');
        
        result.add('      # Database metrics\n');
        result.add('      Telemetry.Metrics.counter("${otpApp}.repo.query.total_time"),\n');
        result.add('      Telemetry.Metrics.counter("${otpApp}.repo.query.decode_time"),\n');
        result.add('      Telemetry.Metrics.counter("${otpApp}.repo.query.query_time"),\n');
        result.add('      Telemetry.Metrics.counter("${otpApp}.repo.query.queue_time"),\n');
        result.add('      Telemetry.Metrics.counter("${otpApp}.repo.query.idle_time"),\n\n');
        
        result.add('      # LiveView metrics\n');
        result.add('      Telemetry.Metrics.counter("phoenix.live_view.mount.start.system_time"),\n');
        result.add('      Telemetry.Metrics.counter("phoenix.live_view.mount.stop.duration"),\n');
        result.add('      Telemetry.Metrics.counter("phoenix.live_view.handle_event.start.system_time"),\n');
        result.add('      Telemetry.Metrics.counter("phoenix.live_view.handle_event.stop.duration")\n');
        result.add('    ]\n');
        result.add('  end\n');
        
        // Add any custom functions from the Haxe class
        for (func in funcFields) {
            if (func.field.name != "start_link" && func.field.name != "metrics") {
                result.add('\n  # Custom function: ${func.field.name}\n');
                result.add('  # Implementation would be generated here\n');
            }
        }
        
        result.add('end');
        
        return result.toString();
    }
}

#end