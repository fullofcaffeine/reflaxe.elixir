package plug;

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
abstract Conn<TParams>(Dynamic) from Dynamic to Dynamic {
    
    /**
     * Create typed conn from Dynamic value
     */
    public static function fromDynamic<TParams>(conn: Dynamic): Conn<TParams> {
        return cast conn;
    }
    
    /**
     * Get the underlying Dynamic conn
     */
    public function toDynamic(): Dynamic {
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
        var headers: Dynamic = Reflect.field(this, "req_headers");
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
    public function getBodyParams(): Dynamic {
        return Reflect.field(this, "body_params");
    }
    
    /**
     * Get query parameters
     */
    public function getQueryParams(): Dynamic {
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
    public function getAssigns(): Dynamic {
        return Reflect.field(this, "assigns");
    }
    
    /**
     * Get specific assign value
     */
    public function getAssign(key: String): Dynamic {
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
        var headers: Dynamic = Reflect.field(this, "resp_headers");
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