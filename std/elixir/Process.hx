package elixir;

#if (macro || reflaxe_runtime)

/**
 * Process module extern definitions for Elixir standard library
 * Provides type-safe interfaces for basic OTP process operations
 * 
 * Maps to Elixir's Process module functions with proper type signatures
 */
@:native("Process")
extern class Process {
    
    // Process identification
    @:native("Process.self")
    public static function self(): Dynamic; // Pid represented as Dynamic
    
    @:native("Process.whereis")
    public static function whereis(name: String): Null<Dynamic>; // Pid or nil
    
    @:native("Process.pid_from_string")
    public static function pidFromString(string: String): Dynamic; // Convert string to pid
    
    // Process spawning
    @:native("Process.spawn")
    public static function spawn(func: Void -> Void): Dynamic; // Returns Pid
    
    @:native("Process.spawn")
    public static function spawnModule(module: String, func: String, args: Array<Dynamic>): Dynamic;
    
    @:native("Process.spawn_link")
    public static function spawnLink(func: Void -> Void): Dynamic;
    
    @:native("Process.spawn_link")
    public static function spawnLinkModule(module: String, func: String, args: Array<Dynamic>): Dynamic;
    
    @:native("Process.spawn_monitor") 
    public static function spawnMonitor(func: Void -> Void): {_0: Dynamic, _1: Dynamic}; // {pid, ref}
    
    @:native("Process.spawn_monitor")
    public static function spawnMonitorModule(module: String, func: String, args: Array<Dynamic>): {_0: Dynamic, _1: Dynamic};
    
    // Process lifecycle
    @:native("Process.exit")
    public static function exit(pid: Dynamic, reason: Dynamic): Bool;
    
    @:native("Process.kill")
    public static function kill(pid: Dynamic, reason: Dynamic): Bool;
    
    @:native("Process.alive?")
    public static function alive(pid: Dynamic): Bool;
    
    // Process linking and monitoring
    @:native("Process.link")
    public static function link(pid: Dynamic): Bool;
    
    @:native("Process.unlink")
    public static function unlink(pid: Dynamic): Bool;
    
    @:native("Process.monitor")
    public static function monitor(pid: Dynamic): Dynamic; // Returns reference
    
    @:native("Process.demonitor")
    public static function demonitor(ref: Dynamic): Bool;
    
    @:native("Process.demonitor")
    public static function demonitorWithOptions(ref: Dynamic, options: Array<String>): Bool;
    
    // Process communication
    @:native("Process.send")
    public static function send(dest: Dynamic, message: Dynamic): Dynamic; // Send message to pid/name
    
    @:native("Process.send")
    public static function sendWithOptions(dest: Dynamic, message: Dynamic, options: Array<String>): Dynamic;
    
    @:native("Process.send_after")
    public static function sendAfter(dest: Dynamic, message: Dynamic, time: Int): Dynamic; // Returns timer ref
    
    // Process registration
    @:native("Process.register")
    public static function register(pid: Dynamic, name: String): Bool;
    
    @:native("Process.unregister")
    public static function unregister(name: String): Bool;
    
    @:native("Process.registered")
    public static function registered(): Array<String>; // List all registered names
    
    // Process information
    @:native("Process.info")
    public static function info(pid: Dynamic): Null<Map<String, Dynamic>>; // Process info map
    
    @:native("Process.info")
    public static function infoKey(pid: Dynamic, key: String): Null<Dynamic>; // Specific info key
    
    @:native("Process.info")
    public static function infoKeys(pid: Dynamic, keys: Array<String>): Null<Map<String, Dynamic>>;
    
    // Process list operations
    @:native("Process.list")
    public static function list(): Array<Dynamic>; // All process pids
    
    // Process flags and options
    @:native("Process.flag")
    public static function flag(flag: String, value: Dynamic): Dynamic; // Set process flag, returns old value
    
    @:native("Process.get")
    public static function get(): Map<Dynamic, Dynamic>; // Get process dictionary
    
    @:native("Process.get")
    public static function getKey(key: Dynamic): Null<Dynamic>; // Get specific key
    
    @:native("Process.get")
    public static function getWithDefault(key: Dynamic, defaultValue: Dynamic): Dynamic;
    
    @:native("Process.put")
    public static function put(key: Dynamic, value: Dynamic): Null<Dynamic>; // Returns previous value
    
    @:native("Process.delete")
    public static function delete(key: Dynamic): Null<Dynamic>; // Delete and return value
    
    @:native("Process.get_keys")
    public static function getKeys(): Array<Dynamic>; // All dictionary keys
    
    @:native("Process.get_keys")
    public static function getKeysForValue(value: Dynamic): Array<Dynamic>; // Keys for specific value
    
    // Process sleeping and timing
    @:native("Process.sleep")
    public static function sleep(timeout: Int): String; // Returns :ok
    
    // Process hibernation
    @:native("Process.hibernate")
    public static function hibernate(module: String, func: String, args: Array<Dynamic>): Void;
    
    // Process cancellation
    @:native("Process.cancel_timer")
    public static function cancelTimer(ref: Dynamic): Null<Int>; // Returns remaining time or nil
    
    @:native("Process.read_timer")
    public static function readTimer(ref: Dynamic): Null<Int>; // Returns remaining time or nil
    
    // Group leader operations
    @:native("Process.group_leader")
    public static function groupLeader(): Dynamic; // Get group leader pid
    
    @:native("Process.group_leader")
    public static function setGroupLeader(leader: Dynamic, pid: Dynamic): Bool;
}

#end