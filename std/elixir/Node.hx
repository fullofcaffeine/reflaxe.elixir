package elixir;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

/**
 * Node module extern definitions for Elixir standard library
 * Provides type-safe interfaces for distributed Erlang/Elixir node operations
 * 
 * Maps to Elixir's Node module functions with proper type signatures
 * Essential for building distributed, fault-tolerant BEAM applications
 */
@:native("Node")
extern class Node {
    
    // Node information
    @:native("self")
    static function self(): Term; // Returns current node as atom
    
    @:native("alive?")
    static function isAlive(): Bool; // Check if node is alive and distributed
    
    @:native("list")
    static function list(): Array<Term>; // List of connected nodes (atoms)
    
    @:native("list")
    static function listWithType(type: NodeListType): Array<Term>; // List nodes of specific type
    
    // Node connection
    @:native("connect")
    static function connect(node: Term): Bool; // Connect to node, returns true if successful
    
    @:native("disconnect")
    static function disconnect(node: Term): Bool; // Disconnect from node
    
    @:native("ping")
    static function ping(node: Term): Term; // Returns :pong or :pang
    
    // Node monitoring
    @:native("monitor")
    static function monitor(node: Term, flag: Bool): Bool; // Monitor node connection
    
    @:native("monitor")
    static function monitorWithOptions(node: Term, flag: Bool, options: Array<Term>): Bool;
    
    // Process spawning
    @:native("spawn")
    static function spawn(node: Term, func: Void -> Void): Term; // Spawn on remote node
    
    @:native("spawn")
    static function spawnModule(node: Term, module: Term, function: String, args: Array<Term>): Term;
    
    @:native("spawn_link")
    static function spawnLink(node: Term, func: Void -> Void): Term;
    
    @:native("spawn_link")
    static function spawnLinkModule(node: Term, module: Term, function: String, args: Array<Term>): Term;
    
    @:native("spawn_monitor")
    static function spawnMonitor(node: Term, func: Void -> Void): {_0: Term, _1: Term}; // {pid, ref}
    
    @:native("spawn_monitor")
    static function spawnMonitorModule(node: Term, module: Term, function: String, args: Array<Term>): {_0: Term, _1: Term};
    
    // Node management
    @:native("start")
    static function start(name: Term, type: NodeType = NodeType.LongName): {_0: String, _1: Term}; // {:ok, pid} | {:error, reason}
    
    @:native("stop")
    static function stop(): Term; // :ok | {:error, :not_allowed | :not_found}
    
    @:native("set_cookie")
    static function setCookie(cookie: Term): Bool; // Set node cookie
    
    @:native("set_cookie")
    static function setCookieForNode(node: Term, cookie: Term): Bool;
    
    @:native("get_cookie")
    static function getCookie(): Term; // Get current node cookie
    
    // Helper functions for common operations
    public static inline function nodeName(): String {
        return untyped __elixir__('to_string(Node.self())');
    }
    
    public static inline function isConnected(node: Term): Bool {
        var nodes = list();
        return untyped __elixir__('Enum.member?({0}, {1})', nodes, node);
    }
    
    public static inline function connectToNode(nodeName: String): Bool {
        var atom = untyped __elixir__('String.to_atom({0})', nodeName);
        return connect(atom);
    }
    
    public static inline function disconnectFromNode(nodeName: String): Bool {
        var atom = untyped __elixir__('String.to_atom({0})', nodeName);
        return disconnect(atom);
    }
    
    public static inline function pingNode(nodeName: String): Bool {
        var atom = untyped __elixir__('String.to_atom({0})', nodeName);
        return untyped __elixir__('{0} == :pong', ping(atom));
    }
    
    public static inline function allNodes(): Array<String> {
        var nodes = list();
        return untyped __elixir__('Enum.map({0}, &to_string/1)', nodes);
    }
    
    public static inline function hiddenNodes(): Array<Term> {
        return listWithType(NodeListType.Hidden);
    }
    
    public static inline function visibleNodes(): Array<Term> {
        return listWithType(NodeListType.Visible);
    }
    
    public static inline function connectedNodes(): Array<Term> {
        return listWithType(NodeListType.Connected);
    }
    
    public static inline function knownNodes(): Array<Term> {
        return listWithType(NodeListType.Known);
    }
    
    public static inline function rpc<T>(node: Term, module: Term, function: String, args: Array<Term>): T {
        return untyped __elixir__(':rpc.call({0}, {1}, {2}, {3})', node, module, untyped __elixir__('String.to_atom({0})', function), args);
    }
    
    public static inline function asyncCall(node: Term, module: Term, function: String, args: Array<Term>): Term {
        return untyped __elixir__(':rpc.async_call({0}, {1}, {2}, {3})', node, module, untyped __elixir__('String.to_atom({0})', function), args);
    }
    
    public static inline function multiCall(nodes: Array<Term>, module: Term, function: String, args: Array<Term>): {_0: Array<Term>, _1: Array<Term>} {
        return untyped __elixir__(':rpc.multicall({0}, {1}, {2}, {3})', nodes, module, untyped __elixir__('String.to_atom({0})', function), args);
    }
}

/**
 * Node list types for Node.list/1
 */
enum abstract NodeListType(String) to String {
    var Visible = "visible";      // Only visible nodes
    var Hidden = "hidden";        // Only hidden nodes
    var Connected = "connected";  // All connected nodes (visible + hidden)
    var This = "this";            // Only this node
    var Known = "known";          // All known nodes (connected + disconnected)
}

/**
 * Node types for starting nodes
 */
enum abstract NodeType(String) to String {
    var ShortName = "shortname";  // Short node names (node@host)
    var LongName = "longname";    // Long node names (node@host.domain)
    var NoName = "noname";        // No distribution
}

/**
 * Distributed process utilities
 */
class DistributedProcess {
    /**
     * Call a function on all connected nodes
     */
    public static inline function broadcast<T>(module: Term, function: String, args: Array<Term>): Map<Term, T> {
        var nodes = Node.list();
        var results = new Map<Term, T>();
        for (node in nodes) {
            results.set(node, Node.rpc(node, module, function, args));
        }
        return results;
    }
    
    /**
     * Start a named process on a specific node
     */
    public static inline function startOn(node: Term, name: String, module: Term, args: Array<Term>): {_0: String, _1: Term} {
        return Node.rpc(node, untyped __elixir__('GenServer'), "start", [
            {_0: untyped __elixir__(':global'), _1: untyped __elixir__('String.to_atom({0})', name)},
            module,
            args
        ]);
    }
    
    /**
     * Find a process across all nodes
     */
    public static inline function whereis(name: String): Null<{_0: Term, _1: Term}> {
        var atom = untyped __elixir__('String.to_atom({0})', name);
        var pid = untyped __elixir__(':global.whereis_name({0})', atom);
        if (untyped __elixir__('{0} == :undefined', pid)) {
            return null;
        }
        var node = untyped __elixir__('node({0})', pid);
        return {_0: pid, _1: node};
    }
    
    /**
     * Register a process globally across all nodes
     */
    public static inline function registerGlobal(name: String, pid: Term): Term {
        var atom = untyped __elixir__('String.to_atom({0})', name);
        return untyped __elixir__(':global.register_name({0}, {1})', atom, pid);
    }
    
    /**
     * Unregister a global process
     */
    public static inline function unregisterGlobal(name: String): Void {
        var atom = untyped __elixir__('String.to_atom({0})', name);
        untyped __elixir__(':global.unregister_name({0})', atom);
    }
}

#end
