package phoenix.test;

import phoenix.test.Conn;

/**
 * Phoenix.ConnTest extern definitions for HTTP testing.
 * 
 * Provides Haxe extern declarations for Phoenix.ConnTest functions,
 * enabling type-safe HTTP testing with proper Conn types.
 * 
 * ## Usage
 * 
 * ```haxe
 * import phoenix.test.Conn;
 * import phoenix.test.ConnTest;
 * 
 * @:test
 * function testUserIndex(): Void {
 *     var conn = ConnTest.build_conn();
 *     conn = ConnTest.get(conn, "/users");
 *     Assert.equals(200, conn.status);
 * }
 * ```
 * 
 * @see https://hexdocs.pm/phoenix/Phoenix.ConnTest.html
 */
@:native("Phoenix.ConnTest")
extern class ConnTest {
    /**
     * Build a test connection.
     * Creates a fresh Conn struct for testing.
     */
    public static function build_conn(): Conn;
    
    /**
     * Build a connection with custom method and path.
     */
    public static function build_conn(method: String, path: String): Conn;
    
    /**
     * Build a connection with method, path, and params.
     */
    public static function build_conn(method: String, path: String, params: Dynamic): Conn;
    
    /**
     * Make a GET request with parameters.
     */
    @:overload(function(conn: Conn, path: String, params: Dynamic): Conn {})
    public static function get(conn: Conn, path: String): Conn;
    
    /**
     * Make a POST request.
     */
    /**
     * Make a POST request with parameters.
     */
    @:overload(function(conn: Conn, path: String, params: Dynamic): Conn {})
    public static function post(conn: Conn, path: String): Conn;
    
    /**
     * Make a PUT request.
     */
    /**
     * Make a PUT request with parameters.
     */
    @:overload(function(conn: Conn, path: String, params: Dynamic): Conn {})
    public static function put(conn: Conn, path: String): Conn;
    
    /**
     * Make a PATCH request.
     */
    /**
     * Make a PATCH request with parameters.
     */
    @:overload(function(conn: Conn, path: String, params: Dynamic): Conn {})
    public static function patch(conn: Conn, path: String): Conn;
    
    /**
     * Make a DELETE request.
     */
    /**
     * Make a DELETE request with parameters.
     */
    @:overload(function(conn: Conn, path: String, params: Dynamic): Conn {})
    public static function delete(conn: Conn, path: String): Conn;
    
    /**
     * Make a HEAD request.
     */
    /**
     * Make a HEAD request with parameters.
     */
    @:overload(function(conn: Conn, path: String, params: Dynamic): Conn {})
    public static function head(conn: Conn, path: String): Conn;
    
    /**
     * Make an OPTIONS request.
     */
    /**
     * Make an OPTIONS request with parameters.
     */
    @:overload(function(conn: Conn, path: String, params: Dynamic): Conn {})
    public static function options(conn: Conn, path: String): Conn;
    
    /**
     * Initialize test session for the connection.
     */
    public static function init_test_session(conn: Conn, session: Map<String, Dynamic>): Conn;
    
    /**
     * Clear the session data.
     */
    public static function clear_session(conn: Conn): Conn;
    
    /**
     * Add flash message to the connection.
     */
    public static function put_flash(conn: Conn, key: String, message: String): Conn;
    
    /**
     * Set request headers.
     */
    public static function put_req_header(conn: Conn, key: String, value: String): Conn;
    
    /**
     * Delete request header.
     */
    public static function delete_req_header(conn: Conn, key: String): Conn;
    
    /**
     * Set request cookie.
     */
    public static function put_req_cookie(conn: Conn, key: String, value: String): Conn;
    
    /**
     * Delete request cookie.
     */
    public static function delete_req_cookie(conn: Conn, key: String): Conn;
    
    /**
     * Fetch query parameters from the connection.
     */
    public static function fetch_query_params(conn: Conn): Conn;
    
    /**
     * Fetch session data from the connection.
     */
    public static function fetch_session(conn: Conn): Conn;
    
    /**
     * Fetch flash messages from the connection.
     */
    public static function fetch_flash(conn: Conn): Conn;
    
    /**
     * Bypass Phoenix router for direct controller testing.
     */
    public static function bypass_through(conn: Conn, router: String): Conn;
    
    /**
     * Bypass with specific action.
     */
    public static function bypass_through(conn: Conn, router: String, action: String): Conn;
    
    /**
     * Dispatch the connection through the router.
     */
    public static function dispatch(conn: Conn, endpoint: String, method: String, path: String): Conn;
    
    /**
     * Recycle the connection for reuse in tests.
     */
    public static function recycle(conn: Conn): Conn;
    
    /**
     * Ensure the connection has been sent.
     */
    public static function ensure_sent(conn: Conn): Conn;
}
