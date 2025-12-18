package phoenix.test;

import elixir.types.Term;

/**
 * Phoenix connection type for HTTP testing.
 * 
 * Represents a Phoenix.Conn struct used in controller and integration tests.
 * Provides type-safe access to HTTP request/response data.
 * 
 * ## Usage
 * 
 * ```haxe
 * import phoenix.test.Conn;
 * import phoenix.test.ConnTest;
 * 
 * @:test
 * function testGetUsers(conn: Conn): Void {
 *     conn = ConnTest.get(conn, "/users");
 *     Assert.equals(200, conn.status);
 *     Assert.contains(conn.resp_body, "Users");
 * }
 * ```
 * 
 * @see https://hexdocs.pm/phoenix/Phoenix.Conn.html
 */
typedef Conn = {
    /** HTTP status code (200, 404, etc.) */
    var status: Int;
    
    /** Response body as string */
    var resp_body: String;
    
    /** Response headers as key-value pairs */
    var resp_headers: Array<{name: String, value: String}>;
    
    /** Request method (GET, POST, etc.) */
    var method: String;
    
    /** Request path */
    var request_path: String;
    
    /** Query parameters */
    var query_params: Map<String, String>;
    
    /** Request parameters (from URL and body) */
    var params: Map<String, Term>;
    
    /** Session data */
    var session: Map<String, Term>;
    
    /** Assigns (controller-level data) */
    var assigns: Map<String, Term>;
    
    /** Flash messages */
    var flash: Map<String, String>;
    
    /** Request cookies */
    var req_cookies: Map<String, String>;
    
    /** Response cookies */
    var resp_cookies: Map<String, Term>;
    
    /** Current user (if authenticated) */
    @:optional var current_user: Term;
    
    /** CSRF token */
    @:optional var csrf_token: String;
    
    /** Request content type */
    @:optional var content_type: String;
    
    /** Request body */
    @:optional var body_params: Map<String, Term>;
    
    /** Whether request was halted */
    var halted: Bool;
    
    /** Request state */
    var state: ConnState;
}

/**
 * Connection state enumeration.
 * Tracks the current processing state of the connection.
 */
enum ConnState {
    /** Connection is being processed */
    Unset;
    
    /** Connection has been sent (response complete) */
    Sent;
    
    /** Connection was halted during processing */
    Halted;
}

/**
 * HTTP status code constants for testing.
 */
class HttpStatus {
    public static inline var OK = 200;
    public static inline var CREATED = 201;
    public static inline var NO_CONTENT = 204;
    public static inline var MOVED_PERMANENTLY = 301;
    public static inline var FOUND = 302;
    public static inline var NOT_MODIFIED = 304;
    public static inline var BAD_REQUEST = 400;
    public static inline var UNAUTHORIZED = 401;
    public static inline var FORBIDDEN = 403;
    public static inline var NOT_FOUND = 404;
    public static inline var METHOD_NOT_ALLOWED = 405;
    public static inline var UNPROCESSABLE_ENTITY = 422;
    public static inline var INTERNAL_SERVER_ERROR = 500;
    public static inline var NOT_IMPLEMENTED = 501;
    public static inline var BAD_GATEWAY = 502;
    public static inline var SERVICE_UNAVAILABLE = 503;
}

/**
 * HTTP method constants for testing.
 */
class HttpMethod {
    public static inline var GET = "GET";
    public static inline var POST = "POST";
    public static inline var PUT = "PUT";
    public static inline var PATCH = "PATCH";
    public static inline var DELETE = "DELETE";
    public static inline var HEAD = "HEAD";
    public static inline var OPTIONS = "OPTIONS";
}
