package elixir;

import elixir.types.Pid;
import elixir.types.Reference;
import elixir.types.ProcessInfo;
import elixir.types.ProcessFlag;
import elixir.types.Priority;
import elixir.types.MessageQueueData;
import elixir.types.Term;
import elixir.types.Atom;

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
    public static function self(): Pid;
    
    @:native("Process.whereis")
    public static function whereis(name: Atom): Null<Pid>;
    
    @:native("Process.pid_from_string")
    public static function pidFromString(string: String): Pid;
    
    // Process spawning
    @:native("Process.spawn")
    public static function spawn(func: Void -> Void): Pid;
    
    @:native("Process.spawn")
    public static function spawnModule(module: String, func: String, args: Array<Term>): Pid;
    
    @:native("Process.spawn_link")
    public static function spawnLink(func: Void -> Void): Pid;
    
    @:native("Process.spawn_link")
    public static function spawnLinkModule(module: String, func: String, args: Array<Term>): Pid;
    
    @:native("Process.spawn_monitor") 
    public static function spawnMonitor(func: Void -> Void): {pid: Pid, ref: Reference};
    
    @:native("Process.spawn_monitor")
    public static function spawnMonitorModule(module: String, func: String, args: Array<Term>): {pid: Pid, ref: Reference};
    
    // Process lifecycle
    @:native("Process.exit")
    public static function exit(pid: Pid, reason: Term): Bool;
    
    @:native("Process.kill")
    public static function kill(pid: Pid, reason: Term): Bool;
    
    @:native("Process.alive?")
    public static function alive(pid: Pid): Bool;
    
    // Process linking and monitoring
    @:native("Process.link")
    public static function link(pid: Pid): Bool;
    
    @:native("Process.unlink")
    public static function unlink(pid: Pid): Bool;
    
    @:native("Process.monitor")
    public static function monitor(pid: Pid): Reference;
    
    @:native("Process.demonitor")
    public static function demonitor(ref: Reference): Bool;
    
    @:native("Process.demonitor")
    public static function demonitorWithOptions(ref: Reference, options: Array<String>): Bool;
    
    // Process communication
    @:native("Process.send")
    public static function send(dest: Pid, message: Term): Term;
    
    @:native("Process.send")
    @:overload(function(dest: Atom, message: Term): Term {})
    public static function sendToName(dest: String, message: Term): Term;
    
    @:native("Process.send")
    public static function sendWithOptions(dest: Pid, message: Term, options: Array<String>): Term;
    
    @:native("Process.send_after")
    public static function sendAfter(dest: Pid, message: Term, time: Int): Reference;
    
    // Process registration
    @:native("Process.register")
    public static function register(pid: Pid, name: Atom): Bool;
    
    @:native("Process.unregister")
    public static function unregister(name: Atom): Bool;
    
    @:native("Process.registered")
    public static function registered(): Array<Atom>; // List all registered names
    
    // Process information
    @:native("Process.info")
    public static function info(pid: Pid): Null<ProcessInfo>; // Process info map
    
    @:native("Process.info")
    public static function infoKey(pid: Pid, key: String): Null<Term>; // Specific info key
    
    @:native("Process.info")
    public static function infoKeys(pid: Pid, keys: Array<String>): Null<ProcessInfo>;
    
    // Process list operations
    @:native("Process.list")
    public static function list(): Array<Pid>; // All process pids
    
    // Process flags with type-safe abstractions
    @:native("Process.flag")
    public static function flag<T>(flag: ProcessFlag, value: T): T;
    
    // Process dictionary with generic key/value types
    @:native("Process.get")
    public static function get<K,V>(): Map<K, V>;
    
    @:native("Process.get")
    public static function getKey<K,V>(key: K): Null<V>;
    
    @:native("Process.get")
    public static function getWithDefault<K,V>(key: K, defaultValue: V): V;
    
    @:native("Process.put")
    public static function put<K,V>(key: K, value: V): Null<V>;
    
    @:native("Process.delete")
    public static function delete<K,V>(key: K): Null<V>;
    
    @:native("Process.get_keys")
    public static function getKeys<K>(): Array<K>;
    
    @:native("Process.get_keys")
    public static function getKeysForValue<K,V>(value: V): Array<K>;
    
    // Process sleeping and timing
    @:native("Process.sleep")
    public static function sleep(timeout: Int): Term; // Returns :ok
    
    // Process hibernation
    @:native("Process.hibernate")
    public static function hibernate(module: String, func: String, args: Array<Term>): Void;
    
    // Process cancellation
    @:native("Process.cancel_timer")
    public static function cancelTimer(ref: Reference): Null<Int>; // Returns remaining time or nil
    
    @:native("Process.read_timer")
    public static function readTimer(ref: Reference): Null<Int>; // Returns remaining time or nil
    
    // Group leader operations
    @:native("Process.group_leader")
    public static function groupLeader(): Pid; // Get group leader pid
    
    @:native("Process.group_leader")
    public static function setGroupLeader(leader: Pid, pid: Pid): Bool;
}

#end
