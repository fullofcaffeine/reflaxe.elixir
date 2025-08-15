package test.support;

import haxe.test.ExUnit.TestCase;
import phoenix.ConnTest;
import phoenix.LiveViewTest;

/**
 * ConnCase provides the foundation for Phoenix LiveView tests.
 * 
 * Following Phoenix patterns, this module sets up the test environment
 * for LiveView integration tests with proper connection handling.
 */
@:exunit
class ConnCase extends TestCase {
    
    /**
     * Setup method called before each test
     * Creates a test connection and sets up the test environment
     */
    override public function setup(context: Dynamic): Dynamic {
        // Setup Ecto sandbox for isolated test data
        DataCase.setupSandbox(context);
        
        // Build test connection
        var conn = ConnTest.buildConn();
        
        return {
            conn: conn,
            endpoint: getEndpoint()
        };
    }
    
    /**
     * Helper function to get the Phoenix endpoint
     */
    private static function getEndpoint(): String {
        return "TodoAppWeb.Endpoint";
    }
    
    /**
     * Helper to create a logged-in user session
     */
    public static function loginUser(conn: Dynamic, user: Dynamic): Dynamic {
        return ConnTest.initTestSession(conn, {
            current_user_id: user.id,
            current_user: user
        });
    }
    
    /**
     * Helper to assert flash messages
     */
    public static function assertFlash(liveView: Dynamic, type: String, message: String): Void {
        LiveViewTest.assertHasFlash(liveView, type, message);
    }
    
    /**
     * Helper to assert page redirection
     */
    public static function assertRedirectedTo(conn: Dynamic, path: String): Void {
        ConnTest.assertRedirectedTo(conn, path);
    }
}