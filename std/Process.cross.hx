/**
 * Process module for interacting with BEAM processes
 * 
 * Provides access to Elixir's Process module functionality
 */
import elixir.types.Pid;
import elixir.types.Term;
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
    public static function self(): Pid;
    
    /**
     * Send a message to a process
     */
    @:native("Process.send")
    public static function send(pid: Pid, message: Term, ?options: Term): Term;
    
    /**
     * Check if a process is alive
     */
    @:native("Process.alive?")
    public static function alive(pid: Pid): Bool;
}
