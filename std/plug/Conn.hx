package plug;

import elixir.types.Atom;
import elixir.types.Term;

/**
 * Type-safe wrapper for Plug.Conn HTTP connection struct
 * 
 * Provides compile-time type checking for HTTP request/response handling
 * while maintaining runtime compatibility with Phoenix's Plug.Conn.
 * 
 * Usage:
 * ```haxe
 * function show(conn: Conn<UserParams>, params: UserParams): Conn<UserParams> {
 *     var user = getUserById(params.id);
 *     return conn.render("show.html", {user: user});
 * }
 * ```
 */

/**
 * HTTP request methods
 */
enum HttpMethod {
    GET;
    POST;
    PUT;
    PATCH;
    DELETE;
    HEAD;
    OPTIONS;
}

/**
 * HTTP status codes
 */
enum HttpStatus {
    Ok;               // 200
    Created;          // 201
    NoContent;        // 204
    BadRequest;       // 400
    Unauthorized;     // 401
    Forbidden;        // 403
    NotFound;         // 404
    MethodNotAllowed; // 405
    InternalServerError; // 500
    Custom(code: Int);
}

/**
 * Type-safe wrapper for Plug.Conn
 */
abstract Conn<TParams>(Term) from Term to Term {
    
    /**
     * Create typed conn from an arbitrary term value (framework boundary)
     */
    public static function fromDynamic<TParams>(conn: Term): Conn<TParams> {
        return cast conn;
    }
    
    /**
     * Get the underlying term conn
     */
    public function toDynamic(): Term {
        return this;
    }
    
    /**
     * Get request method
     */
    public function getMethod(): HttpMethod {
        var method: String = Reflect.field(this, "method");
        return switch (method) {
            case "GET": GET;
            case "POST": POST;
            case "PUT": PUT;
            case "PATCH": PATCH;
            case "DELETE": DELETE;
            case "HEAD": HEAD;
            case "OPTIONS": OPTIONS;
            default: GET;
        };
    }
    
    /**
     * Get request path
     */
    public function getPath(): String {
        return Reflect.field(this, "request_path");
    }
    
    /**
     * Get query string
     */
    public function getQueryString(): String {
        return Reflect.field(this, "query_string");
    }
    
    /**
     * Get request headers
     */
    public function getHeaders(): Map<String, String> {
        var headers: Term = Reflect.field(this, "req_headers");
        var result = new Map<String, String>();
        for (field in Reflect.fields(headers)) {
            result.set(field, Reflect.field(headers, field));
        }
        return result;
    }
    
    /**
     * Get specific header value
     */
    public function getHeader(name: String): Null<String> {
        var headers = getHeaders();
        return headers.get(name.toLowerCase());
    }
    
    /**
     * Get request body parameters
     */
    public function getBodyParams(): Term {
        return Reflect.field(this, "body_params");
    }
    
    /**
     * Get query parameters
     */
    public function getQueryParams(): Term {
        return Reflect.field(this, "query_params");
    }
    
    /**
     * Get path parameters
     */
    public function getPathParams(): TParams {
        return cast Reflect.field(this, "path_params");
    }
    
    /**
     * Get all parameters (merged)
     */
    public function getParams(): TParams {
        return cast Reflect.field(this, "params");
    }
    
    /**
     * Get assigns
     */
    public function getAssigns(): Term {
        return Reflect.field(this, "assigns");
    }
    
    /**
     * Get specific assign value
     */
    public function getAssign(key: String): Term {
        var assigns = getAssigns();
        return Reflect.field(assigns, key);
    }
    
    /**
     * Check if connection is halted
     */
    public function isHalted(): Bool {
        return Reflect.field(this, "halted");
    }
    
    /**
     * Get response status
     */
    public function getStatus(): Int {
        return Reflect.field(this, "status");
    }
    
    /**
     * Get response headers
     */
    public function getResponseHeaders(): Map<String, String> {
        var headers: Term = Reflect.field(this, "resp_headers");
        var result = new Map<String, String>();
        for (field in Reflect.fields(headers)) {
            result.set(field, Reflect.field(headers, field));
        }
        return result;
    }
    
    /**
     * Get response body
     */
    public function getResponseBody(): String {
        return Reflect.field(this, "resp_body");
    }
    
    // ========================================================================
    // PHOENIX CONTROLLER RESPONSE METHODS
    // ========================================================================
    
    /**
     * ## Why @:extern inline and untyped __elixir__()?
     * 
     * Based on official Haxe documentation, these features work together:
     * 
     * ### @:extern Metadata (or extern keyword)
     * - **Purpose**: Prevents the compiler from generating a field in the output
     * - **With inline**: FORCES inlining (compilation error if impossible)
     * - **Why use it**: We want the __elixir__() code to be inlined at call sites
     * - **Guarantee**: Extern + inline is the ONLY way to guarantee inlining in Haxe
     * 
     * ### inline Keyword
     * - **Purpose**: Function body is inserted directly at call sites
     * - **Benefit**: Zero function call overhead - code is substituted at compile time
     * - **With extern**: Becomes mandatory - must inline or compilation fails
     * 
     * ### untyped __elixir__() Magic Function
     * - **Purpose**: Injects raw Elixir code into the generated output
     * - **Why untyped**: Bypasses Haxe type checking for this specific expression
     * - **$variable syntax**: Variables like $this and $data get substituted
     * - **Benefit**: Full access to Elixir/Phoenix ecosystem without writing externs
     * - **Safety**: We wrap it in typed Haxe methods for compile-time checking
     * 
     * ### Example Compilation
     * 
     * Haxe code:
     * ```haxe
     * conn.json({user: user})
     * ```
     * 
     * Compiles to idiomatic Elixir:
     * ```elixir
     * Phoenix.Controller.json(conn, %{user: user})
     * ```
     * 
     * This gives us the best of both worlds:
     * - Type safety at compile time (Haxe checks types)
     * - Native performance at runtime (direct Elixir calls)
     * - Idiomatic output (looks like hand-written Elixir)
     */
    
    /**
     * Send JSON response - The most common API response method
     * 
     * ## Type Safety Benefits
     * 
     * Traditional Elixir (runtime errors possible):
     * ```elixir
     * json(conn, %{user: user})  # What if user is nil?
     * ```
     * 
     * With Haxe (compile-time safety):
     * ```haxe
     * conn.json({user: user})  // Won't compile if user doesn't exist
     * ```
     * 
     * ## Usage Examples
     * 
     * Simple response:
     * ```haxe
     * return conn.json({success: true, message: "Saved!"});
     * ```
     * 
     * Complex typed response:
     * ```haxe
     * typedef ApiResponse = {
     *     data: Array<User>,
     *     meta: {count: Int, page: Int}
     * }
     * var response: ApiResponse = {
     *     data: users,
     *     meta: {count: users.length, page: 1}
     * };
     * return conn.json(response);
     * ```
     * 
     * @param data Any data structure that can be JSON encoded
     * @return Updated conn with JSON response set
     */
    extern
    public inline function json(data: Term): Conn<TParams> {
        return untyped __elixir__('Phoenix.Controller.json({0}, {1})', this, data);
    }
    
    /**
     * Render HTML template with assigns - Core of Phoenix web apps
     * 
     * ## Why This Matters
     * 
     * Phoenix templates can have runtime errors if assigns are missing.
     * With Haxe, we can type-check template variables at compile time!
     * 
     * ## Examples
     * 
     * Basic rendering:
     * ```haxe
     * return conn.render("index.html", {users: users});
     * ```
     * 
     * Type-safe assigns:
     * ```haxe
     * typedef IndexAssigns = {
     *     users: Array<User>,
     *     current_user: User,
     *     page_title: String
     * }
     * var assigns: IndexAssigns = {
     *     users: getUsers(),
     *     current_user: getCurrentUser(conn),
     *     page_title: "User List"
     * };
     * return conn.render("index.html", assigns);
     * ```
     * 
     * @param template Template name (e.g., "index.html", "show.json")
     * @param assigns Data to pass to the template
     * @return Updated conn with rendered response
     */
    extern
    public inline function render(template: String, ?assigns: Term): Conn<TParams> {
        return if (assigns != null) {
            untyped __elixir__('Phoenix.Controller.render({0}, {1}, {2})', this, template, assigns);
        } else {
            untyped __elixir__('Phoenix.Controller.render({0}, {1})', this, template);
        }
    }
    
    /**
     * Redirect to another route - Type-safe navigation
     * 
     * ## Redirect Types
     * 
     * - `to: "/path"` - Internal path redirect
     * - `external: "https://..."` - External URL redirect  
     * 
     * ## Examples
     * 
     * Simple redirect:
     * ```haxe
     * return conn.redirect("/users");
     * ```
     * 
     * With flash message:
     * ```haxe
     * conn.putFlash("info", "User created successfully!")
     *     .redirect("/users/" + user.id);
     * ```
     * 
     * @param to Path or URL to redirect to
     * @return Updated conn with redirect response
     */
    extern  
    public inline function redirect(to: String): Conn<TParams> {
        return untyped __elixir__('Phoenix.Controller.redirect({0}, to: {1})', this, to);
    }
    
    /**
     * Set HTTP status code - Control response status
     * 
     * @param status HTTP status code (200, 404, 500, etc.)
     * @return Updated conn with status set
     */
    extern
    public inline function putStatus(status: Int): Conn<TParams> {
        return untyped __elixir__('Plug.Conn.put_status({0}, {1})', this, status);
    }
    
    /**
     * Add flash message - User feedback that persists across redirects
     * 
     * Flash messages are shown once then cleared automatically.
     * Perfect for success/error messages after form submissions.
     * 
     * @param kind Flash type ("info", "error", "success", "warning")
     * @param message The message to display
     * @return Updated conn with flash message
     */
    extern
    public inline function putFlash(kind: String, message: String): Conn<TParams> {
        return untyped __elixir__('Phoenix.Controller.put_flash({0}, {1}, {2})', this, kind, message);
    }
    
    /**
     * Assign value for templates - Pass data to views
     * 
     * @param key The assign key
     * @param value The value to assign
     * @return Updated conn with new assign
     */
    extern
    public inline function assign(key: Atom, value: Term): Conn<TParams> {
        return untyped __elixir__('Plug.Conn.assign({0}, {1}, {2})', this, key, value);
    }
    
    /**
     * Send raw response - For custom response types
     * 
     * @param status HTTP status code
     * @param body Response body as string
     * @return Updated conn with response sent
     */
    extern
    public inline function sendResp(status: Int, body: String): Conn<TParams> {
        return untyped __elixir__('Plug.Conn.send_resp({0}, {1}, {2})', this, status, body);
    }
    
    /**
     * Halt the connection - Stop processing the request
     * 
     * Used in plugs/middleware to stop the request pipeline.
     * 
     * @return Halted conn
     */
    extern
    public inline function halt(): Conn<TParams> {
        return untyped __elixir__('Plug.Conn.halt({0})', this);
    }
}

/**
 * Helper functions for HTTP status codes
 */
class HttpStatusTools {
    /**
     * Convert HttpStatus enum to integer
     */
    public static function toInt(status: HttpStatus): Int {
        return switch (status) {
            case Ok: 200;
            case Created: 201;
            case NoContent: 204;
            case BadRequest: 400;
            case Unauthorized: 401;
            case Forbidden: 403;
            case NotFound: 404;
            case MethodNotAllowed: 405;
            case InternalServerError: 500;
            case Custom(code): code;
        };
    }
    
    /**
     * Convert integer to HttpStatus enum
     */
    public static function fromInt(code: Int): HttpStatus {
        return switch (code) {
            case 200: Ok;
            case 201: Created;
            case 204: NoContent;
            case 400: BadRequest;
            case 401: Unauthorized;
            case 403: Forbidden;
            case 404: NotFound;
            case 405: MethodNotAllowed;
            case 500: InternalServerError;
            default: Custom(code);
        };
    }
    
    /**
     * Check if status indicates success
     */
    public static function isSuccess(status: HttpStatus): Bool {
        var code = toInt(status);
        return code >= 200 && code < 300;
    }
    
    /**
     * Check if status indicates client error
     */
    public static function isClientError(status: HttpStatus): Bool {
        var code = toInt(status);
        return code >= 400 && code < 500;
    }
    
    /**
     * Check if status indicates server error
     */
    public static function isServerError(status: HttpStatus): Bool {
        var code = toInt(status);
        return code >= 500 && code < 600;
    }
}
