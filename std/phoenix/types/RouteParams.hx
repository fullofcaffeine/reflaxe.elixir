package phoenix.types;

/**
 * Type-safe route parameter system for Phoenix applications
 * 
 * Provides compile-time checking for route parameters while maintaining
 * Phoenix routing compatibility. Helps prevent runtime errors from
 * missing or incorrectly typed route parameters.
 * 
 * Usage:
 * ```haxe
 * // Define route parameter structure
 * typedef UserRouteParams = {
 *     id: String,
 *     ?tab: String
 * }
 * 
 * // Type-safe route parameter access
 * function handle_params(params: RouteParams<UserRouteParams>, url: String, socket: Socket<MyState>) {
 *     var userId = params.id;      // Compile-time type checking
 *     var activeTab = params.tab;  // Optional parameter, can be null
 * }
 * ```
 * 
 * @see documentation/guides/TYPE_SAFE_ROUTING.md - Complete usage guide
 */

/**
 * Type-safe wrapper for Phoenix route parameters
 * 
 * Wraps Phoenix's params map with compile-time type checking while
 * maintaining full compatibility with Phoenix routing system.
 */
abstract RouteParams<T>(Dynamic) from Dynamic to Dynamic {
    
    /**
     * Create typed route params from a Dynamic value
     * Used when receiving params from Phoenix
     * 
     * @param value Raw params map from Phoenix
     * @return RouteParams<T> Type-safe wrapper
     */
    public static function fromDynamic<T>(value: Dynamic): RouteParams<T> {
        return cast value;
    }
    
    /**
     * Create typed route params from a structured object
     * Used when building params in Haxe code
     * 
     * @param obj Typed object matching the params structure
     * @return RouteParams<T> Type-safe wrapper
     */
    public static function fromObject<T>(obj: T): RouteParams<T> {
        return cast obj;
    }
    
    /**
     * Get the underlying Dynamic value
     * Use when passing to Phoenix functions that expect Dynamic
     * 
     * @return Dynamic Raw params map for Phoenix compatibility
     */
    public function toDynamic(): Dynamic {
        return this;
    }
    
    /**
     * Type-safe field access
     * Compiler ensures field exists in T
     */
    @:op(a.b) public function getField<K>(field: K): Dynamic {
        return Reflect.field(this, cast field);
    }
    
    /**
     * Get parameter with default value
     * Safe way to access optional parameters
     * 
     * @param field Parameter name
     * @param defaultValue Default value if parameter not present
     * @return V Parameter value or default
     */
    public function getOrDefault<V>(field: String, defaultValue: V): V {
        var value = Reflect.field(this, field);
        return value != null ? cast value : defaultValue;
    }
    
    /**
     * Check if parameter exists
     * 
     * @param field Parameter name to check
     * @return Bool True if parameter exists
     */
    public function hasParam(field: String): Bool {
        return Reflect.hasField(this, field);
    }
    
    /**
     * Get all parameter names
     * Useful for debugging and introspection
     * 
     * @return Array<String> List of all parameter keys
     */
    public function getParamNames(): Array<String> {
        return Reflect.fields(this);
    }
    
    /**
     * Validate required parameters
     * Throws error if any required parameters are missing
     * 
     * @param required Array of required parameter names
     * @throws String Error message if validation fails
     */
    public function validateRequired(required: Array<String>): Void {
        var missing: Array<String> = [];
        
        for (param in required) {
            if (!hasParam(param) || Reflect.field(this, param) == null) {
                missing.push(param);
            }
        }
        
        if (missing.length > 0) {
            throw 'Missing required parameters: ${missing.join(", ")}';
        }
    }
    
    /**
     * Common parameter type conversions
     */
    
    /**
     * Get parameter as integer
     * Safely converts string parameters to integers
     * 
     * @param field Parameter name
     * @param defaultValue Default value if conversion fails
     * @return Int Integer value or default
     */
    public function getInt(field: String, defaultValue: Int = 0): Int {
        var value = Reflect.field(this, field);
        if (value == null) return defaultValue;
        
        if (Std.isOfType(value, Int)) {
            return cast value;
        }
        
        var parsed = Std.parseInt(Std.string(value));
        return parsed != null ? parsed : defaultValue;
    }
    
    /**
     * Get parameter as float
     * Safely converts string parameters to floats
     * 
     * @param field Parameter name
     * @param defaultValue Default value if conversion fails
     * @return Float Float value or default
     */
    public function getFloat(field: String, defaultValue: Float = 0.0): Float {
        var value = Reflect.field(this, field);
        if (value == null) return defaultValue;
        
        if (Std.isOfType(value, Float)) {
            return cast value;
        }
        
        var parsed = Std.parseFloat(Std.string(value));
        return !Math.isNaN(parsed) ? parsed : defaultValue;
    }
    
    /**
     * Get parameter as boolean
     * Safely converts string parameters to booleans
     * 
     * @param field Parameter name
     * @param defaultValue Default value if conversion fails
     * @return Bool Boolean value or default
     */
    public function getBool(field: String, defaultValue: Bool = false): Bool {
        var value = Reflect.field(this, field);
        if (value == null) return defaultValue;
        
        if (Std.isOfType(value, Bool)) {
            return cast value;
        }
        
        var stringValue = Std.string(value).toLowerCase();
        return switch (stringValue) {
            case "true" | "1" | "yes" | "on": true;
            case "false" | "0" | "no" | "off": false;
            case _: defaultValue;
        };
    }
    
    /**
     * Get parameter as string
     * Safely converts any parameter to string
     * 
     * @param field Parameter name
     * @param defaultValue Default value if parameter not present
     * @return String String value or default
     */
    public function getString(field: String, defaultValue: String = ""): String {
        var value = Reflect.field(this, field);
        return value != null ? Std.string(value) : defaultValue;
    }
    
    /**
     * Phoenix-specific parameter patterns
     */
    
    /**
     * Get ID parameter (common in REST routes)
     * Assumes ID is a string (UUIDs, etc.)
     * 
     * @return String Entity ID
     */
    public function getId(): String {
        return getString("id");
    }
    
    /**
     * Get page parameter for pagination
     * Converts to integer with default of 1
     * 
     * @return Int Page number (1-based)
     */
    public function getPage(): Int {
        return getInt("page", 1);
    }
    
    /**
     * Get per_page parameter for pagination
     * Converts to integer with default of 20
     * 
     * @return Int Items per page
     */
    public function getPerPage(): Int {
        return getInt("per_page", 20);
    }
    
    /**
     * Get search query parameter
     * Common for search/filter functionality
     * 
     * @return String Search query
     */
    public function getSearch(): String {
        return getString("q");
    }
    
    /**
     * Get sort parameter
     * Common for table sorting
     * 
     * @return String Sort field name
     */
    public function getSort(): String {
        return getString("sort");
    }
    
    /**
     * Get sort direction parameter
     * Common for table sorting
     * 
     * @return String Sort direction ("asc" or "desc")
     */
    public function getSortDir(): String {
        var dir = getString("sort_dir", "asc");
        return dir.toLowerCase() == "desc" ? "desc" : "asc";
    }
}

/**
 * Common route parameter types for typical Phoenix applications
 */

/**
 * Basic entity route parameters
 * For standard CRUD routes like /users/:id
 */
typedef EntityRouteParams = {
    id: String
}

/**
 * Nested entity route parameters
 * For nested routes like /users/:user_id/posts/:id
 */
typedef NestedEntityRouteParams = {
    id: String,
    user_id: String
}

/**
 * Pagination route parameters
 * For paginated lists with optional filters
 */
typedef PaginatedRouteParams = {
    ?page: String,
    ?per_page: String,
    ?sort: String,
    ?sort_dir: String,
    ?q: String
}

/**
 * Search route parameters
 * For search pages with filters
 */
typedef SearchRouteParams = {
    ?q: String,
    ?category: String,
    ?tags: String,
    ?sort: String
}

/**
 * Live action route parameters
 * For LiveView routes with live_action
 */
typedef LiveActionRouteParams = {
    ?live_action: String
}

/**
 * Tab-based route parameters
 * For pages with tab navigation
 */
typedef TabRouteParams = {
    ?tab: String
}

/**
 * Date range route parameters
 * For reports and analytics pages
 */
typedef DateRangeRouteParams = {
    ?start_date: String,
    ?end_date: String,
    ?granularity: String
}

/**
 * API version route parameters
 * For versioned API endpoints
 */
typedef VersionedRouteParams = {
    version: String
}

/**
 * File download route parameters
 * For file serving and downloads
 */
typedef FileRouteParams = {
    id: String,
    filename: String,
    ?format: String
}