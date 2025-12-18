package ecto.test;

import elixir.types.Term;

/**
 * Ecto.Adapters.SQL.Sandbox extern definitions for test database isolation.
 * 
 * Provides Haxe extern declarations for Ecto sandbox functions,
 * enabling proper test database isolation and cleanup.
 * 
 * ## Usage
 * 
 * ```haxe
 * import ecto.test.Sandbox;
 * 
 * @:setup
 * function setupDatabase(): Void {
 *     Sandbox.checkout(MyApp.Repo);
 *     // Test runs in isolated transaction
 * }
 * ```
 * 
 * @see https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html
 */
@:native("Ecto.Adapters.SQL.Sandbox")
extern class Sandbox {
    /**
     * Check out a connection for the current process.
     * Creates an isolated database transaction for testing.
     */
    public static function checkout(repo: Term): Void;
    
    /**
     * Check out a connection with specific options.
     */
    public static function checkout(repo: Term, opts: SandboxOptions): Void;
    
    /**
     * Check in the connection for the current process.
     * Rolls back the transaction and returns connection to pool.
     */
    public static function checkin(repo: Term): Void;
    
    /**
     * Check in with specific options.
     */
    public static function checkin(repo: Term, opts: SandboxOptions): Void;
    
    /**
     * Set the sandbox mode for the repository.
     */
    public static function mode(repo: Term, mode: SandboxMode): Void;
    
    /**
     * Allow the current process to use the sandbox connection.
     * Useful for async tests that spawn other processes.
     */
    public static function allow(repo: Term, owner: Term, allowee: Term): Void;
    
    /**
     * Allow multiple processes to use the sandbox connection.
     */
    public static function allow(repo: Term, owner: Term, allowees: Array<Term>): Void;
    
    /**
     * Unallow a process from using the sandbox connection.
     */
    public static function unallow(repo: Term, owner: Term, allowee: Term): Void;
    
    /**
     * Start a supervised sandbox for testing.
     */
    public static function start_supervised(repo: Term): Term;
    
    /**
     * Start supervised with options.
     */
    public static function start_supervised(repo: Term, opts: SandboxOptions): Term;
    
    /**
     * Stop a supervised sandbox.
     */
    public static function stop_supervised(repo: Term): Void;
    
    /**
     * Get the current sandbox mode for the repository.
     */
    public static function get_mode(repo: Term): SandboxMode;
    
    /**
     * Check if repository is in sandbox mode.
     */
    public static function in_sandbox(repo: Term): Bool;
}

/**
 * Sandbox mode configuration.
 */
enum SandboxMode {
    /** Manual mode - checkout/checkin manually */
    Manual;
    
    /** Shared mode - all tests share same connection */
    Shared(options: SandboxSharedOptions);
    
    /** Auto mode - automatic checkout/checkin */
    Auto;
}

/**
 * Options for sandbox shared mode.
 */
typedef SandboxSharedOptions = {
    /** Process that owns the shared connection */
    @:optional var owner: Term;
    
    /** Whether to allow other processes */
    @:optional var allow: Array<Term>;
}

/**
 * Sandbox operation options.
 */
typedef SandboxOptions = {
    /** Timeout for sandbox operations */
    @:optional var timeout: Int;
    
    /** Whether to isolate in transaction */
    @:optional var isolation: SandboxIsolation;
    
    /** Custom sandbox configuration */
    @:optional var sandbox: Bool;
    
    /** Pool timeout */
    @:optional var pool_timeout: Int;
    
    /** Pool size for testing */
    @:optional var pool_size: Int;
}

/**
 * Isolation levels for sandbox.
 */
enum SandboxIsolation {
    /** Read uncommitted */
    ReadUncommitted;
    
    /** Read committed */
    ReadCommitted;
    
    /** Repeatable read */
    RepeatableRead;
    
    /** Serializable */
    Serializable;
}

/**
 * Helper functions for sandbox testing.
 */
class SandboxHelper {
    /**
     * Set up sandbox for a repository with default options.
     * Recommended for most test cases.
     */
    public static function setupDefault(repo: Term): Void {
        Sandbox.mode(repo, Manual);
        Sandbox.checkout(repo);
    }
    
    /**
     * Set up sandbox for async tests.
     * Allows other processes to share the connection.
     */
    public static function setupAsync(repo: Term, processes: Array<Term>): Void {
        Sandbox.mode(repo, Manual);
        Sandbox.checkout(repo);
        
        for (process in processes) {
            Sandbox.allow(repo, getCurrentProcess(), process);
        }
    }
    
    /**
     * Set up shared sandbox for integration tests.
     */
    public static function setupShared(repo: Term): Void {
        var sharedOpts: SandboxSharedOptions = {
            owner: getCurrentProcess()
        };
        Sandbox.mode(repo, Shared(sharedOpts));
    }
    
    /**
     * Clean up sandbox after tests.
     */
    public static function cleanup(repo: Term): Void {
        try {
            Sandbox.checkin(repo);
        } catch (_: haxe.Exception) {
            // Ignore checkin errors - connection might already be returned
        }
    }
    
    /**
     * Get current process PID.
     * Helper function for process management.
     */
    private static function getCurrentProcess(): Term {
        return untyped __elixir__('self()');
    }
    
    /**
     * Check if running in test environment.
     */
    public static function isTestEnv(): Bool {
        return untyped __elixir__('Mix.env() == :test');
    }
    
    /**
     * Ensure sandbox is properly configured for testing.
     */
    public static function ensureTestMode(repo: Term): Void {
        if (!isTestEnv()) {
            throw new haxe.Exception("Sandbox can only be used in test environment");
        }
        
        if (!Sandbox.in_sandbox(repo)) {
            setupDefault(repo);
        }
    }
}
