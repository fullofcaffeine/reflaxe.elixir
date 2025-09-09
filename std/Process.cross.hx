/**
 * Process module for interacting with BEAM processes
 * 
 * Provides access to Elixir's Process module functionality
 */
@:native("Process")
extern class Process {
    /**
     * Sleep the current process for the given number of milliseconds
     */
    @:native("Process.sleep")
    public static function sleep(milliseconds: Int): Void;
    
    /**
     * Get the current process ID
     */
    @:native("Process.self")
    public static function self(): Dynamic;
    
    /**
     * Send a message to a process
     */
    @:native("Process.send")
    public static function send(pid: Dynamic, message: Dynamic, ?options: Dynamic): Dynamic;
    
    /**
     * Check if a process is alive
     */
    @:native("Process.alive?")
    public static function alive(pid: Dynamic): Bool;
}