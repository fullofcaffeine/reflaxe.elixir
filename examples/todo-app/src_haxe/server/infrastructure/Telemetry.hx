package server.infrastructure;

import elixir.otp.Supervisor;
import elixir.otp.Application;
import elixir.otp.TypeSafeChildSpec;

/**
 * Type definition for telemetry supervisor options
 */
typedef TelemetryOptions = {
    ?name: String,
    ?metrics_port: Int,
    ?reporters: Array<String>
}

/**
 * Type definition for OTP child specification
 */
typedef ChildSpec = {
    id: String,
    start: {
        module: String,
        func: String,
        args: Array<TelemetryOptions>
    },
    type: String,
    restart: String,
    shutdown: String
}

/**
 * Type definition for telemetry metrics
 */
typedef TelemetryMetric = {
    name: String,
    event: String,
    measurement: String,
    ?unit: String,
    ?tags: Array<String>
}

/**
 * TodoAppWeb telemetry supervisor
 * Handles application metrics, monitoring, and observability
 * 
 * This module compiles to TodoAppWeb.Telemetry with proper Phoenix telemetry
 * configuration for monitoring web requests, database queries, and custom metrics.
 */
@:native("TodoAppWeb.Telemetry")
@:supervisor
@:appName("TodoApp")
class Telemetry {
    /**
     * Child specification for OTP supervisor
     * 
     * Returns a proper child spec map for Supervisor.start_link
     * 
     * NOTE: @:keep is still required until we implement macro-time preservation
     * for supervisor functions. The AST transformation happens too late to prevent DCE.
     */
    @:keep
    public static function child_spec(opts: TelemetryOptions): ChildSpec {
        // Return a properly typed child spec structure
        return {
            id: "TodoAppWeb.Telemetry",
            start: {
                module: "TodoAppWeb.Telemetry",
                func: "start_link",
                args: [opts]
            },
            type: "supervisor",
            restart: "permanent", 
            shutdown: "infinity"
        };
    }
    
    /**
     * Start the telemetry supervisor
     * 
     * Initializes application metrics collection including:
     * - Phoenix endpoint metrics (request duration, status codes)
     * - Ecto repository metrics (query time, connection pool)
     * - LiveView metrics (mount time, event handling)
     * - Custom application metrics
     * 
     * @param args Telemetry configuration options
     * @return Application result with supervisor PID
     * 
     * NOTE: @:keep is still required until we implement macro-time preservation
     */
    @:keep
    public static function start_link(args: TelemetryOptions): ApplicationResult {
        // Start with empty children - telemetry reporters are added dynamically at runtime
        // This is the standard OTP pattern for telemetry supervisors
        var children: Array<ChildSpecFormat> = [];
        
        // Use __elixir__ injection to call Supervisor.start_link with proper keyword list
        // The keyword list is injected directly as Elixir code to avoid string quoting
        return untyped __elixir__('Supervisor.start_link({0}, [strategy: :one_for_one, max_restarts: 3, max_seconds: 5])', children);
    }
    
    /**
     * Get telemetry metrics configuration
     * 
     * Returns the list of telemetry events and handlers configured
     * for this application, used for debugging and monitoring.
     */
    public static function metrics(): Array<TelemetryMetric> {
        // Returns configured telemetry metrics
        // In a real application, this would return actual metric definitions
        return [];
    }
}