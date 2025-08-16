package haxe.test.phoenix;

import haxe.test.ExUnit.TestCase;
import ecto.Changeset;
import ecto.test.Sandbox;
import haxe.ds.Option;
import haxe.functional.Result;

using ecto.Changeset.ChangesetTools;

/**
 * Base class for data-layer tests using Ecto.
 * 
 * Provides foundation for testing schemas, changesets, and repository operations
 * with proper database isolation using Ecto sandbox.
 * 
 * ## Usage
 * 
 * ```haxe
 * import haxe.test.phoenix.DataCase;
 * import ecto.Changeset;
 * 
 * @:exunit
 * class UserTest extends DataCase {
 *     @:test
 *     function testUserChangeset(): Void {
 *         var changeset: Changeset<User> = User.changeset(new User(), validAttrs);
 *         assertValidChangeset(changeset);
 *     }
 * }
 * ```
 */
@:exunit
class DataCase extends TestCase {
    /**
     * Repository to use for database operations.
     * Override this in your test class to specify your app's repo.
     */
    public static var repo(default, null): String = "MyApp.Repo";
    
    /**
     * Setup method called before each test.
     * Configures Ecto sandbox for test isolation.
     */
    override public function setup(context: TestContext): TestContext {
        setupSandbox(context);
        return context;
    }
    
    /**
     * Set up Ecto sandbox for test isolation.
     * Ensures each test runs in its own database transaction.
     */
    public static function setupSandbox(context: TestContext): Void {
        // Configure Ecto sandbox mode for test isolation
        Sandbox.checkout(getRepo());
        
        // Handle async tests by allowing sandbox sharing
        if (isAsyncTest(context)) {
            Sandbox.allow(getRepo(), getCurrentProcess(), context.test_process);
        }
    }
    
    /**
     * Cleanup method called after each test.
     * Returns database connection to the pool.
     */
    override public function teardown(context: TestContext): Void {
        Sandbox.cleanup(getRepo());
    }
    
    /**
     * Get the repository module for database operations.
     */
    public static function getRepo(): Dynamic {
        // This would resolve to the actual repository module
        return null;
    }
    
    /**
     * Check if the current test is configured to run asynchronously.
     */
    private static function isAsyncTest(context: TestContext): Bool {
        return context.async == true;
    }
    
    /**
     * Get current process PID for sandbox sharing.
     */
    private static function getCurrentProcess(): Dynamic {
        // This would return self() in Elixir
        return null;
    }
    
    // Changeset assertion helpers
    
    /**
     * Assert that a changeset is valid.
     */
    public static function assertValidChangeset<T>(changeset: Changeset<T>): Void {
        if (!changeset.isValid()) {
            var errors = changeset.getErrorsMap();
            throw 'Expected changeset to be valid, but it has errors: ${errors}';
        }
    }
    
    /**
     * Assert that a changeset is invalid.
     */
    public static function assertInvalidChangeset<T>(changeset: Changeset<T>): Void {
        if (changeset.isValid()) {
            throw "Expected changeset to be invalid, but it was valid";
        }
    }
    
    /**
     * Assert that a changeset has a specific error on a field.
     */
    public static function assertChangesetError<T>(changeset: Changeset<T>, field: String, message: String): Void {
        var fieldErrors = changeset.getFieldErrors(field);
        
        if (!fieldErrors.contains(message)) {
            throw 'Expected changeset to have error "${message}" on field "${field}", but got: ${fieldErrors}';
        }
    }
    
    /**
     * Assert that a changeset does not have errors on a field.
     */
    public static function assertNoChangesetError<T>(changeset: Changeset<T>, field: String): Void {
        if (changeset.hasFieldError(field)) {
            var fieldErrors = changeset.getFieldErrors(field);
            throw 'Expected no errors on field "${field}", but got: ${fieldErrors}';
        }
    }
    
    /**
     * Assert that a repository result is successful.
     */
    public static function assertOkResult<T>(result: ChangesetResult<T>): T {
        return switch(result) {
            case Ok(value): value;
            case Error(changeset): 
                var errors = changeset.getErrorsMap();
                throw 'Expected {:ok, value} result, but got errors: ${errors}';
        };
    }
    
    /**
     * Assert that a repository result is an error.
     */
    public static function assertErrorResult<T>(result: ChangesetResult<T>): Changeset<T> {
        return switch(result) {
            case Ok(value): 
                throw 'Expected {:error, changeset} result, but got: ${value}';
            case Error(changeset): changeset;
        };
    }
    
    /**
     * Assert that an Option contains a value.
     */
    public static function assertSome<T>(option: Option<T>): T {
        return switch(option) {
            case Some(value): value;
            case None: throw "Expected Some(value), but got None";
        };
    }
    
    /**
     * Assert that an Option is None.
     */
    public static function assertNone<T>(option: Option<T>): Void {
        switch(option) {
            case Some(value): throw 'Expected None, but got Some(${value})';
            case None: // OK
        }
    }
    
    // Factory helpers
    
    /**
     * Create a valid changeset for testing.
     * Override in subclasses to provide schema-specific logic.
     */
    public static function validChangeset<T>(schema: Class<T>, attrs: Dynamic): Changeset<T> {
        // This would call the schema's changeset function
        // e.g., User.changeset(struct(), attrs)
        throw "validChangeset must be implemented by subclass";
    }
    
    /**
     * Create an invalid changeset for testing.
     * Override in subclasses to provide schema-specific logic.
     */
    public static function invalidChangeset<T>(schema: Class<T>, attrs: Dynamic): Changeset<T> {
        // This would call the schema's changeset function with invalid data
        // e.g., User.changeset(struct(), invalidAttrs)
        throw "invalidChangeset must be implemented by subclass";
    }
    
    /**
     * Create a struct instance for testing.
     */
    public static function struct<T>(schema: Class<T>): T {
        // This would create a new struct instance
        // e.g., %User{}
        throw "struct must be implemented by subclass";
    }
    
    /**
     * Insert a record into the database for testing.
     */
    public static function insert<T>(changeset: Changeset<T>): Result<T, Changeset<T>> {
        // This would call Repo.insert/1
        throw "insert must be implemented by subclass";
    }
    
    /**
     * Insert a record, raising on error.
     */
    public static function insertOrRaise<T>(changeset: Changeset<T>): T {
        return assertOkResult(insert(changeset));
    }
}

/**
 * Test context type for setup/teardown methods.
 */
typedef TestContext = {
    /** Whether test runs asynchronously */
    @:optional var async: Bool;
    
    /** Test process ID (for async tests) */
    @:optional var test_process: Dynamic;
    
    /** Test module name */
    @:optional var module: String;
    
    /** Test function name */
    @:optional var test: String;
    
    /** Test tags */
    @:optional var tags: Array<String>;
    
    /** Custom test data */
    @:optional var data: Map<String, Dynamic>;
}