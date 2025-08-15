package test.support;

import haxe.test.ExUnit.TestCase;
import phoenix.Ecto;

/**
 * DataCase provides the foundation for Ecto schema and data tests.
 * 
 * This module sets up the test database sandbox and provides
 * helpers for testing schemas, changesets, and database operations.
 */
@:exunit
class DataCase extends TestCase {
    
    /**
     * Setup method for data tests
     * Configures the Ecto sandbox for isolated test execution
     */
    override public function setup(context: Dynamic): Dynamic {
        setupSandbox(context);
        return context;
    }
    
    /**
     * Set up Ecto sandbox for test isolation
     * Ensures each test runs in its own database transaction
     */
    public static function setupSandbox(context: Dynamic): Void {
        // Configure Ecto sandbox mode for test isolation
        Ecto.Sandbox.checkout(getRepo());
        
        // Handle async tests by allowing sandbox sharing
        if (isAsyncTest(context)) {
            Ecto.Sandbox.mode(getRepo(), {shared: self()});
        }
    }
    
    /**
     * Get the application repository
     */
    private static function getRepo(): String {
        return "TodoApp.Repo";
    }
    
    /**
     * Check if the current test is async
     */
    private static function isAsyncTest(context: Dynamic): Bool {
        return context.async == true;
    }
    
    /**
     * Helper to create a valid changeset for testing
     */
    public static function validChangeset(module: String, attrs: Dynamic): Dynamic {
        return callStatic(module, "changeset", [struct(), attrs]);
    }
    
    /**
     * Helper to create an invalid changeset for testing
     */
    public static function invalidChangeset(module: String, attrs: Dynamic): Dynamic {
        return callStatic(module, "changeset", [struct(), attrs]);
    }
    
    /**
     * Helper to create a struct instance
     */
    private static function struct(): Dynamic {
        return {}; // Empty struct for testing
    }
    
    /**
     * Helper to call static methods on modules
     */
    private static function callStatic(module: String, method: String, args: Array<Dynamic>): Dynamic {
        // This would be implemented by the Elixir runtime
        return null;
    }
    
    /**
     * Assert that a changeset is valid
     */
    public static function assertValidChangeset(changeset: Dynamic): Void {
        if (!isValidChangeset(changeset)) {
            throw "Expected changeset to be valid, but it has errors: " + getChangesetErrors(changeset);
        }
    }
    
    /**
     * Assert that a changeset is invalid
     */
    public static function assertInvalidChangeset(changeset: Dynamic): Void {
        if (isValidChangeset(changeset)) {
            throw "Expected changeset to be invalid, but it was valid";
        }
    }
    
    /**
     * Check if a changeset is valid
     */
    private static function isValidChangeset(changeset: Dynamic): Bool {
        return changeset.valid == true;
    }
    
    /**
     * Get errors from a changeset
     */
    private static function getChangesetErrors(changeset: Dynamic): String {
        return Std.string(changeset.errors);
    }
}