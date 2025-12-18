package elixir;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

/**
 * System module extern definitions for Elixir standard library
 * Provides type-safe interfaces for system interaction and environment management
 * 
 * Maps to Elixir's System module functions with proper type signatures
 * Essential for command execution, environment variables, and system information
 */
@:native("System")
extern class System {
    
    // Command execution
    @:native("cmd")
    static function cmd(command: String, args: Array<String>, ?options: SystemCmdOptions): {_0: String, _1: Int}; // {output, exit_code}
    
    @:native("cmd")
    static function cmdSimple(command: String): {_0: String, _1: Int};
    
    @:native("shell")
    static function shell(command: String, ?options: SystemCmdOptions): {_0: String, _1: Int};
    
    // Environment variables
    @:native("get_env")
    static function getEnv(): Map<String, String>; // Get all env vars
    
    @:native("get_env")
    static function getEnvVar(varname: String): Null<String>; // Get specific env var
    
    @:native("get_env")
    static function getEnvVarWithDefault(varname: String, defaultValue: String): String;
    
    @:native("put_env")
    static function putEnv(varname: String, value: String): Term; // Returns :ok
    
    @:native("put_env")
    static function putEnvMap(env: Map<String, String>): Term; // Set multiple env vars
    
    @:native("delete_env")
    static function deleteEnv(varname: String): Term; // Returns :ok
    
    // System information
    @:native("otp_release")
    static function otpRelease(): String; // OTP version
    
    @:native("version")
    static function version(): String; // Elixir version
    
    @:native("build_info")
    static function buildInfo(): Map<String, Term>; // Build information
    
    @:native("compiled_endianness")
    static function compiledEndianness(): String; // :big or :little
    
    // Process and system control
    @:native("argv")
    static function argv(): Array<String>; // Command line arguments
    
    @:native("argv")
    static function setArgv(args: Array<String>): Void; // Set command line arguments
    
    @:native("at_exit")
    static function atExit(callback: Int -> Void): Void; // Register exit callback
    
    @:native("halt")
    static function halt(?status: Int): Void; // Halt the system
    
    @:native("stop")
    static function stop(?status: Int): Void; // Stop the system gracefully
    
    @:native("restart")
    static function restart(): Void; // Restart the system
    
    @:native("pid")
    static function pid(): String; // Current OS process ID
    
    // Time and scheduling
    @:native("os_time")
    static function osTime(): Int; // OS time in native unit
    
    @:native("os_time")
    static function osTimeUnit(unit: TimeUnit): Int; // OS time in specified unit
    
    @:native("system_time")
    static function systemTime(): Int; // System time in native unit
    
    @:native("system_time")
    static function systemTimeUnit(unit: TimeUnit): Int; // System time in specified unit
    
    @:native("monotonic_time")
    static function monotonicTime(): Int; // Monotonic time in native unit
    
    @:native("monotonic_time")
    static function monotonicTimeUnit(unit: TimeUnit): Int; // Monotonic time in specified unit
    
    @:native("unique_integer")
    static function uniqueInteger(): Int; // Generate unique integer
    
    @:native("unique_integer")
    static function uniqueIntegerWithOptions(options: Array<String>): Int; // With options [:positive, :monotonic]
    
    // Time conversion
    @:native("convert_time_unit")
    static function convertTimeUnit(time: Int, fromUnit: TimeUnit, toUnit: TimeUnit): Int;
    
    // Scheduler information
    @:native("schedulers")
    static function schedulers(): Int; // Number of schedulers
    
    @:native("schedulers_online")
    static function schedulersOnline(): Int; // Number of online schedulers
    
    // Memory information (returns bytes)
    @:native("memory")
    static function memory(): Map<String, Int>; // All memory info
    
    @:native("stacktrace")
    static function stacktrace(): Array<Term>; // Current stacktrace
    
    // User home directory
    @:native("user_home")
    static function userHome(): Null<String>; // User's home directory
    
    @:native("user_home!")
    static function userHomeBang(): String; // User's home directory or raises
    
    // Temporary directory
    @:native("tmp_dir")
    static function tmpDir(): Null<String>; // System temp directory
    
    @:native("tmp_dir!")
    static function tmpDirBang(): String; // System temp directory or raises
    
    // Current working directory
    @:native("cwd")
    static function cwd(): Null<String>; // Current working directory
    
    @:native("cwd!")
    static function cwdBang(): String; // Current working directory or raises
    
    // Helper functions for common operations
    public static inline function requireEnv(varname: String): String {
        var value = getEnvVar(varname);
        if (value == null) {
            throw 'Required environment variable $varname is not set';
        }
        return value;
    }
    
    public static inline function hasEnv(varname: String): Bool {
        return getEnvVar(varname) != null;
    }
    
    public static inline function execCommand(command: String, args: Array<String> = null): String {
        if (args == null) args = [];
        var result = cmd(command, args);
        if (result._1 != 0) {
            throw 'Command failed with exit code ${result._1}: $command';
        }
        return result._0;
    }
    
    public static inline function execShell(command: String): String {
        var result = shell(command);
        if (result._1 != 0) {
            throw 'Shell command failed with exit code ${result._1}: $command';
        }
        return result._0;
    }
    
    public static inline function isWindows(): Bool {
        // Check if running on Windows
        var os = getEnvVar("OS");
        return os != null && os.toLowerCase().indexOf("windows") >= 0;
    }
    
    public static inline function isMac(): Bool {
        // Check if running on macOS
        var result = cmd("uname", ["-s"]);
        return result._0.indexOf("Darwin") >= 0;
    }
    
    public static inline function isLinux(): Bool {
        // Check if running on Linux
        var result = cmd("uname", ["-s"]);
        return result._0.indexOf("Linux") >= 0;
    }
}

/**
 * Options for System.cmd and System.shell functions
 */
typedef SystemCmdOptions = {
    ?into: Term,            // Collectable to stream output into
    ?cd: String,            // Directory to run the command in
    ?env: Array<{_0: String, _1: String}>, // Environment variables as tuples
    ?arg0: String,          // Program name to use as argv[0]
    ?stderr_to_stdout: Bool, // Redirect stderr to stdout
    ?parallelism: Bool      // Whether to run in parallel
}

/**
 * Time units for System time functions
 */
enum abstract TimeUnit(String) to String {
    var Second = "second";
    var Millisecond = "millisecond";
    var Microsecond = "microsecond";
    var Nanosecond = "nanosecond";
    var Native = "native";
}

#end
