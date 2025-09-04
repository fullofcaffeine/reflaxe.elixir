package elixir;

#if (macro || reflaxe_runtime)

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
    static function self(): Dynamic; // Returns current node as atom
    
    @:native("alive?")
    static function isAlive(): Bool; // Check if node is alive and distributed
    
    @:native("list")
    static function list(): Array<Dynamic>; // List of connected nodes (atoms)
    
    @:native("list")
    static function listWithType(type: NodeListType): Array<Dynamic>; // List nodes of specific type
    
    // Node connection
    @:native("connect")
    static function connect(node: Dynamic): Bool; // Connect to node, returns true if successful
    
    @:native("disconnect")
    static function disconnect(node: Dynamic): Bool; // Disconnect from node
    
    @:native("ping")
    static function ping(node: Dynamic): String; // Returns :pong or :pang
    
    // Node monitoring
    @:native("monitor")
    static function monitor(node: Dynamic, flag: Bool): Bool; // Monitor node connection
    
    @:native("monitor")
    static function monitorWithOptions(node: Dynamic, flag: Bool, options: Array<Dynamic>): Bool;
    
    // Process spawning
    @:native("spawn")
    static function spawn(node: Dynamic, func: Void -> Void): Dynamic; // Spawn on remote node
    
    @:native("spawn")
    static function spawnModule(node: Dynamic, module: Dynamic, function: String, args: Array<Dynamic>): Dynamic;
    
    @:native("spawn_link")
    static function spawnLink(node: Dynamic, func: Void -> Void): Dynamic;
    
    @:native("spawn_link")
    static function spawnLinkModule(node: Dynamic, module: Dynamic, function: String, args: Array<Dynamic>): Dynamic;
    
    @:native("spawn_monitor")
    static function spawnMonitor(node: Dynamic, func: Void -> Void): {_0: Dynamic, _1: Dynamic}; // {pid, ref}
    
    @:native("spawn_monitor")
    static function spawnMonitorModule(node: Dynamic, module: Dynamic, function: String, args: Array<Dynamic>): {_0: Dynamic, _1: Dynamic};
    
    // Node management
    @:native("start")
    static function start(name: Dynamic, type: NodeType = NodeType.LongName): {_0: String, _1: Dynamic}; // {:ok, pid} | {:error, reason}
    
    @:native("stop")
    static function stop(): String; // :ok | {:error, :not_allowed | :not_found}
    
    @:native("set_cookie")
    static function setCookie(cookie: Dynamic): Bool; // Set node cookie
    
    @:native("set_cookie")
    static function setCookieForNode(node: Dynamic, cookie: Dynamic): Bool;
    
    @:native("get_cookie")
    static function getCookie(): Dynamic; // Get current node cookie
    
    // Helper functions for common operations
    public static inline function nodeName(): String {
        return untyped __elixir__('to_string(Node.self())');
    }
    
    public static inline function isConnected(node: Dynamic): Bool {
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
        return ping(atom) == "pong";
    }
    
    public static inline function allNodes(): Array<String> {
        var nodes = list();
        return untyped __elixir__('Enum.map({0}, &to_string/1)', nodes);
    }
    
    public static inline function hiddenNodes(): Array<Dynamic> {
        return listWithType(NodeListType.Hidden);
    }
    
    public static inline function visibleNodes(): Array<Dynamic> {
        return listWithType(NodeListType.Visible);
    }
    
    public static inline function connectedNodes(): Array<Dynamic> {
        return listWithType(NodeListType.Connected);
    }
    
    public static inline function knownNodes(): Array<Dynamic> {
        return listWithType(NodeListType.Known);
    }
    
    public static inline function rpc<T>(node: Dynamic, module: Dynamic, function: String, args: Array<Dynamic>): T {
        return untyped __elixir__(':rpc.call({0}, {1}, {2}, {3})', node, module, untyped __elixir__('String.to_atom({0})', function), args);
    }
    
    public static inline function asyncCall(node: Dynamic, module: Dynamic, function: String, args: Array<Dynamic>): Dynamic {
        return untyped __elixir__(':rpc.async_call({0}, {1}, {2}, {3})', node, module, untyped __elixir__('String.to_atom({0})', function), args);
    }
    
    public static inline function multiCall(nodes: Array<Dynamic>, module: Dynamic, function: String, args: Array<Dynamic>): {_0: Array<Dynamic>, _1: Array<Dynamic>} {
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
    public static inline function broadcast<T>(module: Dynamic, function: String, args: Array<Dynamic>): Map<Dynamic, T> {
        var nodes = Node.list();
        var results = new Map<Dynamic, T>();
        for (node in nodes) {
            results.set(node, Node.rpc(node, module, function, args));
        }
        return results;
    }
    
    /**
     * Start a named process on a specific node
     */
    public static inline function startOn(node: Dynamic, name: String, module: Dynamic, args: Array<Dynamic>): {_0: String, _1: Dynamic} {
        return Node.rpc(node, untyped __elixir__('GenServer'), "start", [
            {_0: untyped __elixir__(':global'), _1: untyped __elixir__('String.to_atom({0})', name)},
            module,
            args
        ]);
    }
    
    /**
     * Find a process across all nodes
     */
    public static inline function whereis(name: String): Null<{_0: Dynamic, _1: Dynamic}> {
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
    public static inline function registerGlobal(name: String, pid: Dynamic): String {
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